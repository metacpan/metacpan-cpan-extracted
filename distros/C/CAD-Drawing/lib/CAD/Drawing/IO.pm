package CAD::Drawing::IO;
our $VERSION = '0.26';

#use CAD::Drawing;
use CAD::Drawing::Defined;

use Storable;

# value set within BEGIN block:
my $plgindbg = $CAD::Drawing::IO::plgindbg;


use warnings;
use strict;
use Carp;
########################################################################
=pod

=head1 NAME

CAD::Drawing::IO - I/O methods for the CAD::Drawing module

=head1 Description

This module provides the load() and save() functions for CAD::Drawing
and provides a point of flow-control to deal with the inheritance and
other trickiness of having multiple formats handled through a single
module.

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

=over

=item L<CAD::Drawing|CAD::Drawing>

The frontend.

=back

=head2 Builtin Backends

The following modules are included in the main distribution.

=over

=item L<CAD::Drawing::IO::Circ|CAD::Drawing::IO::Circ>

=item L<CAD::Drawing::IO::Compressed|CAD::Drawing::IO::Compressed>

=item L<CAD::Drawing::IO::FlatYAML|CAD::Drawing::IO::FlatYAML>

=item L<CAD::Drawing::IO::Split|CAD::Drawing::IO::Split>

=back

=head2 External Backends

=over

=item L<CAD::Drawing::IO::OpenDWG|CAD::Drawing::IO::OpenDWG>

DWG/DXF handling using the OpenDWG toolkit.

=item L<CAD::Drawing::IO::PostScript|CAD::Drawing::IO::PostScript>

Postscript output.

=item L<CAD::Drawing::IO::Image|CAD::Drawing::IO::Image>

Image::Magick based output.

=item L<CAD::Drawing::IO::PgDB|CAD::Drawing::IO::PgDB>

PostgreSQL connected drawing database.

=item L<CAD::Drawing::IO::Tk|CAD::Drawing::IO::Tk>

Tk::WorldCanvas popup viewer -- not exactly an input/output backend, but
it uses much of the same facility because it is primarily just output to
a display.

=back

=cut
########################################################################

=head1 front-end Input and output methods

The functions load() and save() are responsible for determining the
filetype (with forced types available via $options{type}.)  These then
call the appropriate <Package>::load() or <Package>::save() functions.

See the Plug-In Architecture section for details on how to add support
for additional filetypes.

Beginning with version 0.26, a string-based type specification is
available by using $filename = "$type:filename".  While this prevents
you from saving files with colons in the names, an explicit type passed
in the options will allow it.  This gives the added bonus that your
program's users may directly control the output type simply by giving a
<type>:<file> argument on the command line (if that is where you get
your filenames.)

=head2 save

Saves a file to disk.  See the save<type> functions in this file and the
other filetype functions in the CAD::Drawing::IO::<type> modules.

See each save<type> function for available options for that type.

While you may call the save<type> function directly (if you include the
module), it is recommended that you stick to the single point of
interface provided here so that your code does not become overwhelmingly
infected with hard-coded filetypes.

Note that this method also implements forking.  If $options{forkokay} is
true, save() will return the pid of the child process to the parent
process and setup the child to exit after saving (with currently no way
for the child to give a return value to the parent (but (-e $filename)
might work for you).)

  $drw->save($filename, \%options);

=cut
sub save {
	my $self = shift;
	my ( $filename, $opt) = @_;
	my $type = $$opt{type};
	if($$opt{forkokay}) {
		$SIG{CHLD} = 'IGNORE';
		my $kidpid;
		if($kidpid = fork) {
			return($kidpid);
		}
		defined($kidpid) or die "cannot fork $!\n";
		$$opt{forkokay} = 0;
		$self->diskaction("save", $filename, $type, $opt);
		exit;
	}
	return($self->diskaction("save", $filename, $type, $opt));
} # end subroutine save definition
########################################################################

=head2 load

Loads a file from disk.  See the load<type> functions in this file and
the other filetype functions in the CAD::Drawing::IO::<type> modules.

See each load<type> function for available options for that type.

In most cases %options may contain the selection methods available via
the CAD::Drawing::check_select() function.

While you may call the load<type> function directly (if you include the
module), it is recommended that you stick to the single point of
interface provided here.

  $drw->load($filename, \%options);

=cut
sub load {
	my $self = shift;
	my ($filename, $opt) = @_;
	my $type = $$opt{type};
	return($self->diskaction("load", $filename, $type, $opt));
} # end subroutine load definition
########################################################################

=head2 can_load

Returns true if the plugins think they can load this filename (no
test-loading is done, only verification of the type.)

  $drw->can_load($filename);

=cut
sub can_load {
	my $self = shift;
	my ($filename, $opt) = @_;
	my $type = $$opt{type};
	return($self->diskaction("check", $filename, $type));
} # end subroutine can_load definition
########################################################################

=head1 Plug-In Architecture

Plug-ins are modules which are under the CAD::Drawing::IO::*
namespace.  This namespace is searched at compile time, and any modules
found are require()d inside of an eval() block (see BEGIN.)  Compile
failure in any one of these modules will be printed to STDERR, but will
not halt the running program.

Each plug-in is responsible for declaring one or all of the following
variables:

  our $can_save_type = "type";
  our $can_load_type = "type (or another type)";
  our $is_inherited = 1; # or 0 (or undef())

If a package claims to be able to load or save a type, then it must
contain the functions load() or save() (respectively.)  Package which
declare $is_inherited as a true value will become methods of the
CAD::Drawing class (though their load() and save() functions will not
be visible due to their location in the inheritance tree.)

=head2 BEGIN

The BEGIN block implements the module path searching (looking only in
directories of @INC which contain a "CAD/Drawing/IO/" directory.)

For each plug-in which is found, code references are saved for later
use by the diskaction() function.

=cut
BEGIN {
	use File::Find;
	my %found;
	our %handlers;
	our %check_type;
	our @ISA;
	our $plgindbg = 0;
	use strict;
	foreach my $inc (@INC) {
		# (if it starts with CAD/Drawing/IO/, then we are good)
		my $look = "$inc/CAD/Drawing/IO/";
		(-d "$look") || next;
#        print "looking in $look\n";

		# I suppose deeper nested namespaces are allowed
		find(sub {
			($_ =~ m/\.pm$/) or return;
			my $mod = $File::Find::name;
			$mod =~ s#^$inc/+##;
			$mod =~ s#/+#::#g;
			$mod =~ s/\.pm//;
			$found{$mod} and return;
			$found{$mod}++;
			# print "$File::Find::name\n";
			# print "mod: $mod\n";
		}, $look );
	}
	foreach my $mod (keys(%found)) {
		# see if they are usable
		$plgindbg && print "checking $mod\n";
		if(eval("require " . $mod)) {
			my $useful;
			foreach my $action qw(load save) {
				my $type = eval(
					'$' . $mod . '::can_' . $action . '_type'
					);
				$type or next;
				$handlers{$action}{$type} and next;
				$useful++;
				$handlers{$action}{$type} = $mod . '::' . $action;
				$check_type{$type} = $mod . '::check_type';
				$plgindbg and
					print "$action ($type) claimed by $mod\n";
				$plgindbg and
					print "(found $handlers{$action}{$type})\n";
			}
			if(eval('$' . $mod . '::is_inherited')) {
				push(@ISA, $mod);
				$useful++;
			}
			$plgindbg and ($useful and print "using $mod\n");
		}
		else {
			$@ and warn("warning:\n$@ for $mod\n\n");
		}
	} # end foreach $mod
} # end BEGIN
########################################################################

=head2 diskaction

This function is for internal use, intended to consolidate the type
selection and calling of load/save methods.

  $drw->diskaction("load|save", $filename, $type, \%options);

For each plug-in package which was located in the BEGIN block, the
function <Package>::check_type() will be called, and must return a true
value for the package to be used for $action.

=cut
sub diskaction {
	my $self = shift;
	my ($action, $filename, $type, $opt) = @_;
	my %opts;
	(ref($opt) eq "HASH") && (%opts = %$opt);
	($action =~ m/save|load|check/) or 
		croak("Cannot access disk with action:  $action\n");
	$filename or
		croak("Cannot $action without filename\n");

	# Hopefully this is fixed:  if type is passed explicitly, we were
	# still strolling through the list to determine which module to
	# call.  New strategy is to try using the explicit type first.
	
    ####################################################################
	# choose filetype:
	my %handlers = %CAD::Drawing::IO::handlers;
	my $og_fn = $filename;
	unless(defined($type)) {
		$plgindbg and
			print "type was undefined, trying split(/:/, \$file)\n";
		my ($t, $n) = split(/:/, $filename, 2);
		if(defined($n)) {
			$plgindbg and print "got type: $t and name $n\n";
			$filename = $n;
			$type = $t;
		}
	}
	# now we may have an explicit type (so backends should not be
	# allowed to claim solely on extension)
	if(defined($type) and ($action ne "check")) {
		if(my $call = $handlers{$action}{$type}) {
			no strict 'refs';
			$plgindbg and print "quickly trying $call (for $type / $action)\n";
			return($call->($self, $filename, {%opts, type => $type}));
		}
		else {
			warn("explicit type '$type' bypassed...\n  ", 
				"exhaustive checks now");
			$filename = $og_fn;
			undef($type);
			$plgindbg and warn("name now $filename\n");
		}
	}
	my %check = %CAD::Drawing::IO::check_type;
	my $check_only = ($action eq "check");
	$check_only and ($action = "load");
	foreach my $mod (keys(%{$handlers{$action}})) {
		$plgindbg && print "checking $mod ($check{$mod})\n";
		no strict 'refs';
		my $real_type = $check{$mod}($filename, $type);
		# check must return true
		$real_type || next;
		# if we just want to know if it can be loaded, the answer is:
		$check_only and return(1);
		# XXX it would be good to have a real_filename here (so we could
		# do a -e on it when in check_only mode)
		my $call = $handlers{$action}{$mod};
		$plgindbg && print "trying $call\n";
		return($call->($self, $filename, {%opts, type => $real_type}));
	}
	# FIXME: # maybe the fallback is a Storable or YAML file?
	$check_only and return(0);
	croak("could not $action $filename as type: $type");
} # end subroutine diskaction definition
########################################################################

=head1 Utility Functions

These are simply inherited by the CAD::Drawing module for your direct
usage.

=head2 outloop

Crazy new experimental output method.  Each entity supported by the
format should have a key to a function in %functions, which is expected
to accept the following input data:

  $functions{$ent_type}->($obj, \%data);

The %data hash is passed verbatim to each function.

  $count = $drw->outloop(\%functions, \%data);

In addition to each of the $ent_type keys, functions for the keys
'before' and 'after' may also be defined.  These (if they are defined)
will be called before and after each entity, with the same arguments as
the $ent_type functions.

=cut
sub outloop {
	my $self = shift;
	my ($funcs, $data) = @_;
	my %functions = %$funcs;
	# we should ignore data here
	my $count = 0;
	foreach my $layer (keys(%{$self->{g}})) {
		foreach my $ent (keys(%{$self->{g}{$layer}})) {
			if($functions{$ent}) {
				foreach my $id (keys(%{$self->{g}{$layer}{$ent}})) {
					my %addr = (
						"layer" => $layer,
						"type"  => $ent,
						"id"    => $id,
						);
					my $obj = $self->getobj(\%addr);
					$functions{before} && ($functions{before}->($obj, $data));
					$functions{$ent}->($obj, $data);
					$functions{after} && ($functions{after}->($obj, $data));
					$count++;
				}
			}
			else {
				carp("not supporting type: $ent");
			}
			
		}
	}
	return($count);
} # end subroutine outloop definition
########################################################################

=head2 is_persistent

Returns 1 if $filename points to a persistent (directory / db) drawing.

  $drw->is_persistent($filename);

=cut
sub is_persistent {
	my $self = shift;
	my $filename = shift;
	# XXX punting here:
	($filename =~ m/^split:/) and return(1);
	# FIXME backends really need to answer this
	return(0);
} # end subroutine is_persistent definition
########################################################################


1;
