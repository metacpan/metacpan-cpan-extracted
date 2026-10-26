package App::Actions::Access;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Readonly;
use Sub::Identify qw(get_code_info);

our $VERSION = '0.002.1';

# A routine whose name starts with this is private to its package.
Readonly::Scalar my $PRIVATE => qr/\A_[A-Za-z0-9]\w*\z/;

=encoding utf-8

=head1 NAME

App::Actions::Access - list the private routines of a package for Sub::Private

=head1 SYNOPSIS

	package App::Actions::Example;

	use Sub::Private ();
	use Sub::Protected ();
	use App::Actions::Access;

	sub run { my $self = shift; return $self->_step }
	sub _step { ... }
	sub _runner { ... }    # protected: subclasses may call it

	# At the end of the file, once every routine above is compiled.
	BEGIN {
		Sub::Protected->import('_runner');
		local $Sub::Private::config{mode} = 'enforce';
		Sub::Private->import(@{ App::Actions::Access->private_names(__PACKAGE__, '_runner') });
	}

See which routines would be made private:

	use App::Actions::Access;
	use App::Actions::Runner;

	my $names = App::Actions::Access->private_names('App::Actions::Runner');
	print join("\n", @{$names}), "\n";

Leave some names out:

	my $names = App::Actions::Access->private_names(__PACKAGE__, '_runner', '_docker');

=head1 DESCRIPTION

In Perl, a routine whose name starts with C<_> is private by convention
only: any code can still call it.  L<Sub::Private> makes the rule real.  In
C<enforce> mode, a call to a private routine from outside its own package
dies.

There is a catch.  L<Sub::Private>'s mode is one setting for the whole
program.  If one module set it to C<enforce> for good, every module loaded
after it would be switched too, even modules that did not ask for it.

So this distribution never changes the setting for good.  Each module, at
the end of its file, sets the mode with C<local> for just one call to
L<Sub::Private>, and gives that call the list of its private routines.  This
module makes that list.  Because the list is made from the code, a private
routine added later is protected automatically; nobody has to remember to
add it to a list.

=head1 METHODS

=head2 private_names

Lists the routines of a package whose names start with an underscore, which
the package itself defined (not ones it imported), less the ones named as
exceptions.

=head3 ARGUMENTS

=over 4

=item * C<$package> - the package whose routines are listed.

=item * C<@except> - optional; names to leave out, such as the protected
routines a subclass may call.

=back

=head3 RETURNS

A sorted array reference of names.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $names = App::Actions::Access->private_names('App::Actions::Runner');
	print "@$names\n";    # _build_base_env _check_environment ...

=head3 API SPECIFICATION

=head4 INPUT

	{
		package => { type => 'string', matches => qr/\A\w+(?:::\w+)*\z/ },
		except  => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| A package name is required| No package, or not a name    | Pass __PACKAGE__            |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub private_names {
	my (undef, $package, @except) = @_;

	# Called from a BEGIN block with a literal, so a bad name is a mistake
	# in this distribution and is reported in plain English.
	croak 'A package name is required'
		unless defined $package && $package =~ /\A\w+(?:::\w+)*\z/;

	my %skip = map { $_ => 1 } @except;
	my $stash = do { no strict 'refs'; \%{"${package}::"} };

	my @names;
	for my $name (sort keys %{$stash}) {
		next if $skip{$name} || $name !~ $PRIVATE;

		# A glob may hold only a scalar or a hash of that name.
		my $code = do { no strict 'refs'; defined &{"${package}::$name"} ? \&{"${package}::$name"} : undef };
		next unless $code;

		# A routine imported from another package belongs to that package,
		# which decides for itself whether it is private.
		my ($owner) = get_code_info($code);
		push @names, $name if defined $owner && $owner eq $package;
	}

	return \@names;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The listing has to run after the routines are compiled, which is
why the C<BEGIN> block goes at the end of the file.  A routine compiled
after it (by a string C<eval>, say) is not protected.

=item * Privacy is checked on every call, by walking C<caller>, so a private
routine costs more to call than a public one.  None of this distribution's
private routines is called in a tight loop.

=item * The check is bypassed under a test harness (C<HARNESS_ACTIVE>), which
is how the white-box tests reach the private routines.  Run a test file
without the harness to see the checks in force.

=item * A private routine handed to another package as a code reference is
checked when that package calls it, and fails.  Hand over a closure that
calls it instead.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Call it at the end of the file.>  It sees only the routines that
are already compiled.  Put the C<BEGIN> block after the last C<sub>.

=item * B<Always use C<local> for the mode.>  Write C<local
$Sub::Private::config{mode} = 'enforce';> inside the C<BEGIN> block.
Without C<local>, every module loaded later is enforced too.

=item * B<Leave out protected routines.>  A routine that a subclass may
call must be passed in C<@except> (and given to L<Sub::Protected>), or the
subclass's calls will die.

=item * B<Names starting with two underscores are not listed.>  C<__foo>
does not match; only C<_> followed by a letter or digit does.

=item * B<Imported routines are not listed.>  A routine imported from
another module belongs to that module.

=item * B<Once Sub::Private has wrapped them, they are not listed either.>
The wrapper belongs to L<Sub::Private>, so asking about a module that has
already run its C<BEGIN> block (for example C<App::Actions::Util>, once it
is loaded) returns an empty list.  Ask before the C<import>, as the
C<BEGIN> block does.

=item * B<Tests run with the checks off.>  Under C<prove>,
C<HARNESS_ACTIVE> is set and the checks are bypassed.  Run
C<perl -Ilib t/file.t> (without C<prove>) to test with them on.

=back

=head1 ENCODING

Package and routine names must be ASCII word characters (letters, digits
and C<_>, separated by C<::>).  A package name with other characters is
refused with C<A package name is required>.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞState> means the routine changes
nothing, and C<ΔState> means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

=head2 private_names

	┌─ PrivateNames ────────────────────────────────────
	│ package? : PACKAGE
	│ except?  : ℙ NAME
	│ names!   : seq NAME
	├───────────────────────────────────────────────────
	│ ran names! = { n : dom stash(package?) |
	│     n matches /\A_[A-Za-z0-9]\w*\z/ ∧ defined(code(package?, n)) ∧
	│     owner(code(package?, n)) = package? } ∖ except?
	│ names! is sorted
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The module keeps no state.  This is how one package's private routines
become protected while the file is loaded:

	 perl loads Package.pm
	          |
	          v
	+--------------------+  each "sub _name { }" is compiled; at this
	| COMPILING ROUTINES |  point any code may call _name
	+--------------------+
	          |
	          | final BEGIN block runs
	          v
	+--------------------+  private_names(__PACKAGE__, @except):
	| LISTING            |  own routines matching _[A-Za-z0-9]\w*,
	+--------------------+  minus @except, sorted
	          |
	          | local mode = 'enforce'; Sub::Private->import(@names)
	          v
	+--------------------+  calls from outside the package die;
	| ENFORCED           |  calls from inside work;
	+--------------------+  protected names: Sub::Protected rules
	          |
	          | BEGIN block ends: the "local" mode is restored,
	          v so later packages are not affected
	+--------------------+
	| OTHER PACKAGES     |  unchanged
	| LOAD AS BEFORE     |
	+--------------------+

	Under a test harness (HARNESS_ACTIVE) the ENFORCED checks are bypassed.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
