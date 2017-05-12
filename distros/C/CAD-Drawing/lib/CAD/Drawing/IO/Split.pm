package CAD::Drawing::IO::Split;
our $VERSION = '0.02';

use CAD::Drawing;
use CAD::Drawing::Defined;

use warnings;
use strict;
use Carp;

my $dbg = 0;

=pod

=head1 NAME

CAD::Drawing::IO::Split - Fast distributed text file methods.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
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

=cut
########################################################################

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "split";
our $can_load_type = $can_save_type;
our $is_inherited = 1;

=head2 check_type

Returns true if $type is "split" or $filename is a directory (need a tag?)

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	if(defined($type)) {
		($type eq "split") && return("split");
		return();
	}
	elsif((-d $filename) && (0)) { # FIXME: this needs something
		return("split");
	}
	elsif(($filename =~ s/^split://) and (-d $filename)) {
		return("split");
	}
	return();
} # end subroutine check_type definition
########################################################################

=head1 Load/Save Methods

Concept here is to strip data down to the absolute bare minumum in an
effort to find a generic and extensible incarnation of same.

=cut
########################################################################
our %save_functions = (
	plines => sub {
		my ($pline, $data) = @_;
		# note the danger here (loading dwg into existing will
		# create compounding buildup
		my $filename = _sp_filename($pline, $data);
		open(PL, ">$filename") or croak();
		print PL join(":", map({join(",", @$_)} @{$pline->{pts}})), "\n";
		print PL "$pline->{color}\n";
		close(PL);
	}, # end plines sub
	lines => sub {
		my ($line, $data) = @_;
		$dbg && print "a line!\n";
		my $filename = _sp_filename($line, $data);
		open(LN, ">$filename") or croak();
		print LN join(":", map({join(",", @$_)} @{$line->{pts}})), "\n";
		print LN "$line->{color}\n";
		close(LN);
	},
	points => sub {
		my ($point, $data) = @_;
		# print "a point\n";
		my $filename = _sp_filename($point, $data);
		open(PT, ">$filename") or croak();
		print PT join(",", @{$point->{pt}}), "\n";
		print PT "$point->{color}\n";
		close(PT);
	}, # end points sub
	circles => sub {
		my ($circ, $data) = @_;
		my $filename = _sp_filename($circ, $data);
		open(CI, ">$filename") or croak();
		$dbg && print "saving @{$circ->{pt}}\n$circ->{rad}\n$circ->{color}\n";
		print CI join(",", @{$circ->{pt}}), "\n";
		print CI "$circ->{rad}\n";
		print CI "$circ->{color}\n";
		close(CI);
	}, # end circs sub

); # end %save_functions
########################################################################

=head2 save

Saves data into $toplevel_directory under a directory for each layer,
each type, and a file for each id.

  save($drw, $toplevel_directory, \%options);

Requires that the directory already exists.

Selective saves not yet supported.

Unfortunately, the file-formats are rather primitive and the code needs
refactoring.  These are nowhere near stable, so don't expect version
compatibility yet!

Needs a clear_all_like => $regex option.

=cut
sub save{
	my $dbg = 0;
	my $self = shift;
	$dbg && print "here\n";
	my ($dir, $opt) = @_;
	$dir =~ s/^split://;
	(-d $dir) or die "no $dir\n";
	my %data = (
		dir => $dir,
		);
	$dbg && print "saving out $dir\n";
	$self->outloop(\%save_functions, \%data);
} # end subroutine save definition
########################################################################

our %load_functions = (
	plines => sub {
		my ($self, $file, $info) = @_;
		open(PL, $file) or croak();
		chomp(my $pts = <PL>);
		chomp(my $color = <PL>);
		close(PL);
		$dbg && print "points: $pts\ncolor:$color\n";
		my @pts = map({[split(/,/, $_)]} split(/:/, $pts));
		$self->addpolygon(\@pts, {%$info, color => $color});
	},
	lines => sub {
		my ($self, $file, $info) = @_;
		open(LN, $file) or croak();
		chomp(my $pts = <LN>);
		chomp(my $color = <LN>);
		close(LN);
		$dbg && print "points: $pts\ncolor:$color\n";
		my @pts = map({[split(/,/, $_)]} split(/:/, $pts));
		$self->addline(\@pts, {%$info, color => $color});
	},
	points => sub {
		my ($self, $file, $info) = @_;
		open(PT, $file) or croak();
		chomp(my $pt = <PT>);
		chomp(my $co = <PT>);
		close(PT);
		$self->addpoint([split(/,/, $pt)], {%$info, color => $co});
	},
	circles => sub {
		my ($self, $file, $info) = @_;
		open(CI, $file) or croak();
		chomp(my $pt = <CI>);
		chomp(my $rad = <CI>);
		chomp(my $co = <CI>);
		close(CI);
		$self->addcircle([split(/,/, $pt)], $rad, {%$info, color => $co});
	},
);

=head2 load

  load($drw, $toplevel_directory, \%options);

%options may include selective-load arguments

=cut
sub load{
	my $self = shift;
	my ($dir, $opts) = @_;
	$dir =~ s/^split://;
	(-d $dir) or croak("no such directory: $dir\n");
	my %opt;
	(ref($opts) eq "HASH") && (%opt = %$opts);
	my @layers;
	my ($s, $n) = check_select(\%opt);
	if($s->{l}) {
		@layers = grep({$s->{l}{$_}} _dir_list($dir));
	}
	else {
		@layers = _dir_list($dir);
	}
	foreach my $layer (@layers) {
		my %info = (layer => $layer);
		foreach my $type (keys(%load_functions)) {
			$s->{t} && ($s->{t}{$type} || next);
			$n->{t} && ($n->{t}{$type} && next);
			my $path = join("/", $dir, $layer, $type);
			(-d $path) || next;
			$info{type} = $type;
			my @ids = _dir_list($path);
			foreach my $id (@ids) {
				$info{id} = $id;
				my $filename = $path . "/" . $id;
				# hmm.  slipping select color / select linetype in here
				# is tricky
				$load_functions{$type}->($self, $filename, {%info});
			}
		} # end foreach $type
	} # end foreach $layer


} # end subroutine load definition
########################################################################

=head1 Naming Functions

=cut

=head2 _dir_list

  @list = _dir_list($dir);

=cut
sub _dir_list {
	my $dir = shift;
	opendir(DIR, $dir);
	my @list = grep(! /^\.+$/, readdir(DIR));
	closedir(DIR);
	# print "listed @list\n";exit;
	return(@list);
} # end subroutine _dir_list definition
########################################################################

=head2 _sp_filename

Creates nested directories which are required to save %obj and returns the filename which should be saved into.

  _sp_filename(\%obj, \%data);

=cut
sub _sp_filename {
	my ($obj, $data) = @_;
	my @dirs = (
		$data->{dir}, 
		$obj->{addr}{layer},
		$obj->{addr}{type},
		);
	my $filename;
	foreach my $dir (@dirs) {
		$filename .=  $dir . "/";
		if(-d $filename) {
			$dbg && print "$filename exists\n";
			next;
		}
		(-e $filename) and
			croak("$filename exists, but is not a directory");
		$dbg && print "making $filename\n";
		mkdir($filename);
	}
	$filename .= $obj->{addr}{id};
	$dbg && print "filename to be $filename\n";#exit;
	return($filename);
} # end subroutine _sp_filename definition
########################################################################

=head1 Inherited Methods

=cut

=head2 clear_dir

Removes layers (and items) from the split directory $dir.

Defaults to removing all.

  $drw->clear_dir($dir, \%options);

=over

=item Available options:

  like    => qr/regex/,  # if regex matches layer name
  not_like => qr/regex/,  # negative of above (compounded)

=item check_select() options:

%options is passed through CAD::Drawing::Defined::check_select(), so the selections returned by it will be utilized here.

  select_layers => \@layer_list,
  select_types => \@types_list,

Returns the number of items removed or undef() if $dir does not exist.

=back

=cut
sub clear_dir {
	my $self = shift;
	my ($dir, $opts) = @_;
	$dir =~ s#/*$#/#;
	my %opt;
	(ref($opts) eq "HASH") && (%opt = %$opts);
	my $like = $opt{like};
	my $notlike = $opt{not_like};
	my ($s, $n) = check_select(\%opt);
	(-d $dir) or return();
	my @kill_layers = _dir_list($dir);
	if($like) {
		(ref($like) eq "Regexp") or 
			croak("$like is not a regex");
		@kill_layers = grep(/$like/, @kill_layers);
		$dbg && print "now ", scalar(@kill_layers), "\n";
	}
	if($notlike) {
		(ref($notlike) eq "Regexp") or 
			croak("$notlike is not a regex");
		@kill_layers = grep(! /$notlike/, @kill_layers);
		$dbg && print "now ", scalar(@kill_layers), "\n";
	}
	my $count;
	foreach my $layer (@kill_layers) {
		$s->{l} && ($s->{l}{$layer} || next);
		$n->{l} && ($n->{l}{$layer} && next);
		my $ldir = $dir . $layer . "/";
		my @types = _dir_list($ldir);
		$dbg && print "removing $layer\n";
		my $tfail = 0;
		foreach my $type (@types) {
			$s->{t} && ($s->{t}{$type} || next);
			$n->{t} && ($n->{t}{$type} && next);
			$dbg && print "$type\n";
			my $tdir = $ldir . $type . "/";
			my @items = _dir_list($tdir);
			$dbg && print "items: @items\n";
			my $ifail = 0;
			foreach my $item (@items) {
				my $file = $tdir . $item;
				if(unlink($file)) {
					$count ++;
				}
				else {
					carp("unlink failed on $file");
					$ifail++;
				}
			}
			unless($ifail) {
				unless(rmdir($tdir)) {
					carp("rmdir failed on $tdir");
					$tfail++;
				}
			}
		} # end foreach $type
		unless($tfail) {
			unless(rmdir($ldir)) {
				carp("rmdir failed on $ldir");
			}
		}
	}

	return($count);

} # end subroutine clear_dir definition
########################################################################



1;
