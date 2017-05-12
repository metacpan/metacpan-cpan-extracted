package CAD::Drawing::IO::PostScript;
our $VERSION = '0.03';

use CAD::Drawing;
use CAD::Drawing::Defined;
use PostScript::Simple;


use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::IO::PostScript - PostScript output methods

=head1 Description

I would like this module to both load and save PostScript vector
graphics, but I have not yet found a suitable PostScript parsing
package.

=head1 NOTICE

This module should be considered pre-ALPHA and untested.  Some features
rely on the author's hacks to PostScript::Simple, which may or may not
have been incorporated into the CPAN distribution of PostScript::Simple.
For bleeding-edge code, see http://ericwilhelm.homeip.net.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2005-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  CAD::Drawing
  CAD::Drawing::IO
  PostScript::Simple

=cut

########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "ps";

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=head2 check_type

Returns true if $type is "circ" or $filename is a directory containing a
".circ" file.

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	if(defined($type)) {
		($type eq "ps") && return("ps");
		return();
	}
	elsif($filename =~ m/\.e?ps$/) {
		return("ps");
	}
	return();
} # end subroutine check_type definition

########################################################################
=head1 Methods

=head2 load

  load();

=cut
sub load {
	croak("cannot yet load postscript!");
} # end subroutine load definition
########################################################################

=head2 save

  $drw->save($filename, \%opts);

=cut
sub save {
	my $self = shift;
	my($filename, $opt) = @_;
	my %opts;
	my $accuracy = 1; # digits of accuracy with which to bother
	my $sp = 30;
	(ref($opt) eq "HASH") && (%opts = %$opt);
	my $outobj;
	if($filename =~ m/\.eps/) {
		# implies eps fit
		my @ext = $self->OrthExtents($opt);
		my ($x, $y) = map({$_->[1] - $_->[0]} @ext);
		$sp = 0;
		# print "eps will be $x by $y\n";
		my $obj = PostScript::Simple->new(
					eps    => 1,
					xsize  => $x,
					ysize  => $y,
					colour => 1,
					);
		$opts{readymadeobject} = $obj;
	}
	unless($opts{"readymadeobject"} ) {
		$outobj = new PostScript::Simple(
						landscape => 1,
						eps => 0,
						papersize => "Letter",
						colour => 1,
						);
		$outobj->newpage;
	}
	else {
		$outobj = $opts{"readymadeobject"};
	}

	# now can get the size from the object and use it to set the scale of
	# things
	my(@fitsize) = ($$outobj{bbx2}, $$outobj{bby2});
#   print "got size:  @fitsize\n";
 	my(@bound) = ([0,0], [@fitsize]);
	my $drw = $self;  # default is to smash $self
	
	# FIXME: why did I have this here?
	# my $worklist = $drw->select_addr();
	
	unless($opts{"noclone"}) {
		$drw = CAD::Drawing->new;
		# passing original opts allows selective save
		$self->GroupClone($drw, $opt);	
		}
	####################################################################
	# Setup border
	my @border;
	if(ref($opts{"border"}) eq "ARRAY") {
#		@border = ( [@sp] , [$fitsize[0]-$sp[0] , $fitsize[1]-$sp[1] ]);
		@border = @{$opts{"border"}};
		}
	elsif(defined($opts{"border"})) {
		my $num = $opts{"border"};
		@border = ([$num,$num], [-$num,-$num]);
		}
	else {
		@border = ([$sp, $sp], [-$sp, -$sp]);
		}
	####################################################################
	# Perform fit
# 	$outobj->line(0,0, @fitsize);
	my $scaling = $drw->fit_to_bound([@bound], [@border], 
							{"center" =>[$fitsize[0] / 2, $fitsize[1]/2 ] , %opts} );
	####################################################################
	if($opts{show_border} ) {
		$drw->addrec( 
				[ 
					[
					$bound[0][0] + $border[0][0] / 2 , 
					$bound[0][1] + $border[0][1] / 2
					],
					[
					$bound[1][0] + $border[1][0] / 2  , 
					$bound[1][1] + $border[1][1] / 2
					]
				]
			);
	} # end if show border
	# now must draw all of the resultant geometry
	my $filledopt = 0;
	if($opts{"filled"}) {
		# FIXME:  need some way to make this selective?
		$filledopt = $opts{filled};
		}
	my $font_choice = "Helvetica";
	$opts{font} && ($font_choice = $opts{font});
	# NOTE NOTE NOTE NOTE NOTE NOTE:not using $self here!
	my %ps_data = (
		psobj => $outobj,
		font => $font_choice,
		filled => $filledopt,
		accuracy => $accuracy,
		);

	our %ps_functions;
	$drw->outloop(\%ps_functions, \%ps_data);
	$opts{show} && ($drw->show(hang => 1));
	return($outobj->output($filename));
} # end subroutine save definition
########################################################################

=head2 PostScript::Simple::setpscolor

  PostScript::Simple::setpscolor();

=cut
sub PostScript::Simple::setpscolor {
	my $self = shift;
	my($ac_color) = @_;
	my %no = map( { $_ => 1} 0, 7, 256);
	$no{$ac_color} && return();
	my $ps_color = $aci2rgb[$ac_color];
	$self->setcolour(@$ps_color);
} # end subroutine PostScript::Simple::setpscolor definition
########################################################################

our %ps_functions = (
	before => sub {
		my ($obj, $data) = @_;
		my $ps = $data->{psobj};
		$ps->setpscolor($obj->{color});
		defined($obj->{linewidth}) && $ps->setlinewidth($obj->{linewidth});
	},
	after => sub {
		my ($obj, $data) = @_;
		my $ps = $data->{psobj};
		$ps->setpscolor(255);
		defined($obj->{linewidth}) && $ps->setlinewidth(1);
	},
	lines => sub {
		my ($line, $data) = @_;
		my $ps = $data->{psobj};
		my $acc = $data->{accuracy};
		my @pspts = map({@{$line->{pts}[$_]}[0,1]} 0,1);
		$ps->line(map({sprintf("%0.${acc}f", $_)} @pspts));
	},
	plines => sub {
		my ($pline, $data) = @_;
		my $ps = $data->{psobj};
		my $filled = $data->{filled};
		my $acc = $data->{accuracy};
		my @points = map({@{$_}[0,1]} @{$pline->{pts}});
		foreach my $point (@points) {
			$point = sprintf("%0.${acc}f", $point);
		}
		$pline->{closed} && (push(@points, @points[0,1]));
# 		$pline->{closed} && print "closed polyline\n";
# 		print "points:\n\t", join("\n\t", map({join(",", @{$pline->{pts}})}));
		$ps->polygon({filled => $filled}, @points);
	},
	circles => sub {
		my ($circ, $data) = @_;
		my $ps = $data->{psobj};
		my $filled = $data->{filled};
		my $acc = $data->{accuracy};
		my @pt = map({sprintf("%0.${acc}f", $_)} @{$circ->{pt}}[0,1]);
		my $rad = sprintf("%0.${acc}f",  $circ->{rad});
		$ps->circle({filled=>$filled},  @pt, $rad);
	},
	# points are a fake circle:
	points => sub {
		my ($circ, $data) = @_;
		my $ps = $data->{psobj};
		my $filled = $data->{filled};
		my $acc = $data->{accuracy};
		my @pt = map({sprintf("%0.${acc}f", $_)} @{$circ->{pt}}[0,1]);
		# XXX this is SO lame!
		my $rad = 0.01;
		$ps->circle({filled=>$filled},  @pt, $rad);
	},
	arcs => sub {
		my ($arc, $data) = @_;
		my $ps = $data->{psobj};
		my $acc = $data->{accuracy};
		my @pt = map({sprintf("%0.${acc}f", $_)} @{$arc->{pt}}[0,1]);
		my $rad = sprintf("%0.${acc}f",  $arc->{rad});
		my @angs = map({sprintf("%0.0f", $_ * 180 / $pi)} @{$arc->{angs}});
		$ps->arc(@pt, $rad, @angs);
	},
	texts => sub {
		my ($text, $data) = @_;
		my $ps = $data->{psobj};
		my $acc = $data->{accuracy};
		my @pt = map({sprintf("%0.${acc}f", $_)} @{$text->{pt}}[0,1]);
		my $font = $text->{font} ? $text->{font} : $data->{font};
		$ps->setfont($font, $text->{height});
		my @call = (@pt, $text->{string});
		# XXX no rotation support
		my %options;
		if($text->{angle}) {
			$options{rotate} = $text->{angle} * 180 / $pi;
		}
		$text->{align} and ($options{align} = $text->{align});
		$text->{valign} and ($options{valign} = $text->{valign});
		%options and unshift(@call, \%options);
		$ps->text(@call);
	},
);

1;
