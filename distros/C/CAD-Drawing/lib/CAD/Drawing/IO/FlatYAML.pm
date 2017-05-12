package CAD::Drawing::IO::FlatYAML;
our $VERSION = '0.01';

use CAD::Drawing;
use CAD::Drawing::Defined;

use warnings;
use strict;
use Carp;

my $dbg = 0;

=pod

=head1 NAME

CAD::Drawing::IO::FlatYAML - Fast distributed YAML file methods.

=head1 DESCRIPTION

This module is a first attempt at creating a "reference implementation"
of the specification for the first generation hub format of the
uber-converter project.  See
http://ericwilhelm.homeip.net/uber-converter/ for more information about
this specification.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.

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

The command-line type specification for this module is 'ysplit'.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "ysplit";
our $can_load_type = $can_save_type;
our $is_inherited = 1;

=head2 check_type

Returns true if $type is "ysplit" or $filename is a directory (need a tag?)

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	if(defined($type)) {
		($type eq "ysplit") && return("ysplit");
		return();
	}
	elsif((-d $filename) && (0)) { # FIXME: this needs something
		return("ysplit");
	}
	elsif(($filename =~ s/^ysplit://) and (-d $filename)) {
		return("ysplit");
	}
	return();
} # end subroutine check_type definition
########################################################################

=head1 Load/Save Methods

Concept here is to strip data down to the absolute bare minumum in an
effort to find a generic and extensible incarnation of same.

=cut
########################################################################
our %type_translate = (
	arcs    => 'arc',
	plines  => 'polyline',
	circles => 'circle',
	points  => 'point',
	texts   => 'text',
	lines   => 'line',
	);
our %key_translate = (
	pt   => 'point',
	pts  => 'points',
	rad  => 'radius',
	angs => 'angles',
	);
our %key_ok = map({$_ => 1} qw(
	closed
	color
	linetype
	height
	string
	angle
	));
our %key_skip = map({$_ => 1} qw(
	addr
	));
# not sure about this (our addr->{id} has nothing to do with the yaml id)
our %key_missing = map({$_ => 1} qw(
	id
	));
# always using internal keys
our %key_out_mod = (
	color => sub {
			my $c = shift;
			($c == 256) and return("#bylayer");
			return($aci2hex[$c]);
			},
	);
# always using external keys
our %key_in_mod = (
	);

=head2 save

Saves data into $toplevel_directory into a file for each id.

  save($drw, $toplevel_directory, \%options);

Requires that the directory exists and is empty (?)

Selective saves not yet supported.

Needs a clear_all_like => $regex option.

=cut
sub save{
	my $dbg = 0;
	my $self = shift;
	$dbg && print "here\n";
	my ($dir, $opt) = @_;
	(-d $dir) or die "no $dir\n";
	$dir =~ s#/*$#/#;
	my @exists = glob($dir . "*") and die "EXISTING DATA IN $dir\n  ";
	my %data = (
		dir => $dir,
		);
	$dbg && print "saving out $dir\n";
	my $count = 0; # turns into filename...
	foreach my $layer (keys(%{$self->{g}})) {
		foreach my $ent (keys(%{$self->{g}{$layer}})) {
			foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
				my %addr = (
					"layer" => $layer,
					"type"  => $ent,
					"id"    => $id,
					);
				my $obj = $self->getobj(\%addr);
				my $type = $type_translate{$ent};
				defined($type) or die "no such type $ent\n";
				my %yobj = (
					layer => $layer,
					type  => $type,
					ID    => $count, # NOTE THIS!
					);
				foreach my $key (keys(%$obj)) {
					my $alt_key = $key;
					if($key_ok{$key}) {
						# unchanged
						}
					elsif($alt_key = $key_translate{$key}) {
						# different
						}
					elsif($key_skip{$key}) {
						next;
						}
					else {
						warn("$key not found in transforms!\n");
						next;
					}
					my $val = $obj->{$key};
					if($key_out_mod{$key}) {
						$val = $key_out_mod{$key}->($val);
						# die "get $val from $obj->{$key} for $key\n";
					}
					$yobj{$alt_key} = $val;
				}
				# sorry, no zero-padding here (does the spec allow it?)
				my $filename = $dir . $count . ".yml";
				YAML::DumpFile($filename, \%yobj);
				$count++;
			}
		}
	}

	return($count);
} # end subroutine save definition
########################################################################

=head2 load

  load($drw, $toplevel_directory, \%options);

%options may include selective-load arguments

=cut
sub load{
	my $self = shift;
	my ($dir, $opts) = @_;
	$dir =~ s/^ysplit://;
	(-d $dir) or croak("no such directory: $dir\n");
	my %opt;
	(ref($opts) eq "HASH") && (%opt = %$opts);
	my @layers;
	my ($s, $n) = check_select(\%opt);
	# this has to get the list of all files,
	# go through them,
		# check select/not for layer, color, etc



} # end subroutine load definition
########################################################################

=head1 Naming Functions

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

=head2 keymap_in

Remaps keys (and possibly data) into the input version.

  ($key, $value) = keymap_in($key, $value);

=cut
sub keymap_in {
} # end subroutine keymap_in definition
########################################################################

=head2 keymap_out

Remaps keys (and possibly data) into the output version.

  ($key, $value) = keymap_out($key, $value);

=cut
sub keymap_out {
	my ($k, $v) = @_;
	unless($key_translate{$k}) {
		warn("no translate for $k\n");
		return($k, $v);
	}
	return($key_translate{$k}, $v);
} # end subroutine keymap_out definition
########################################################################


=head1 Inherited Methods

=head2 clear_flatyml

Removes items from the flat directory $dir.

Defaults to removing all.

  $drw->clear_flatyml($dir, \%options);

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
sub clear_flatyml {
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
	die "needs work";
	# must we read-in every file to get properties associated with ID's etc?
	# XXX none of this is correct:
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

} # end subroutine clear_flatyml definition
########################################################################



1;
