package App::FileSync::Platform;

# Deliberately dependency-free, and loaded first by every module that uses
# Sub::Private: the end-of-scope hook implementation has to be chosen before
# anything loads B::Hooks::EndOfScope, and Sub::Private loads it at compile time.

use strict;
use warnings;

use version; our $VERSION = version->declare('0.001.2');

=encoding utf8

=head1 NAME

App::FileSync::Platform - choose platform workarounds before other modules load

=head1 SYNOPSIS

	use App::FileSync::Platform;	# first, before Sub::Private or Log::Abstraction

=head1 DESCRIPTION

B::Hooks::EndOfScope 0.28 releases its XS scope hook with an access violation
(0xC0000005) on Perl 5.42 for Windows, after a command has done its work but
before the interpreter exits, so a run that synced everything would still exit
nonzero.  Its plain-Perl hook does not fault.  The implementation is fixed when
B::Hooks::EndOfScope first loads, so this module makes the choice in a BEGIN
block and is the first thing every App::FileSync module loads.

=head1 FUNCTIONS

=head2 wants_plain_end_of_scope_hook

Purpose: decide whether an interpreter needs the plain-Perl end-of-scope hook.

Args: C<$os> (as C<$^O>), C<$version> (as C<$]>).

Returns: 1 for MSWin32 with a 5.42.x interpreter, otherwise 0.

Side Effects: none.

Usage:

	App::FileSync::Platform::wants_plain_end_of_scope_hook('MSWin32', 5.042003);	# 1

=head3 EXAMPLE

	print App::FileSync::Platform::wants_plain_end_of_scope_hook($^O, $]) ? "PP\n" : "XS\n";

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'os',      type => 'string', optional => 1 },
		{ name => 'version', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	wants : OS × VERSION → 𝔹
	wants(os, v) ⇔ os = MSWin32 ∧ v ∈ ℚ ∧ 5.042 ≤ v < 5.043

=cut

sub wants_plain_end_of_scope_hook {
	my ($os, $version) = @_;

	# 5.42.x only: later releases may not share the fault, and forcing an
	# implementation a later B::Hooks::EndOfScope no longer ships would refuse
	# to load.
	return (defined $os && $os eq 'MSWin32'
		&& defined $version && $version =~ /\A[0-9.]+\z/
		&& $version >= 5.042 && $version < 5.043) ? 1 : 0;
}

=head2 use_plain_end_of_scope_hook

Purpose: select the plain-Perl hook for an interpreter that needs it.

Args: C<$os>, C<$version>, as for L</wants_plain_end_of_scope_hook>.

Returns: 1 when the environment variable was set, 0 when it was left alone.

Side Effects: may set C<$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION}> to C<PP>.  An
implementation already named in the environment always wins.

Usage:

	App::FileSync::Platform::use_plain_end_of_scope_hook($^O, $]);

=head3 EXAMPLE

	local $ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION};
	App::FileSync::Platform::use_plain_end_of_scope_hook('MSWin32', 5.042003);
	print "$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION}\n";	# PP

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'os',      type => 'string', optional => 1 },
		{ name => 'version', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	ΔENV
	os? : OS ; v? : VERSION ; r! : 𝔹
	r! ⇔ B_HOOKS ∉ dom ENV ∧ wants(os?, v?)
	r! ⇒ ENV' = ENV ⊕ {B_HOOKS ↦ PP}
	¬r! ⇒ ENV' = ENV

=cut

sub use_plain_end_of_scope_hook {
	my ($os, $version) = @_;

	my $set = (!defined $ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION}
		&& wants_plain_end_of_scope_hook($os, $version)) ? 1 : 0;
	$ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION} = 'PP' if $set;

	return $set;
}

BEGIN {
	use_plain_end_of_scope_hook($^O, $]);
}

1;

__END__

=head1 LIMITATIONS

The choice only helps when this module is loaded before B::Hooks::EndOfScope.
Code outside this distribution that loads namespace::clean, Sub::Private or
Log::Abstraction first gets whichever implementation was already chosen.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
