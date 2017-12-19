package Assert::Refute;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0305;

=head1 NAME

Assert::Refute - unified assertion and testing tool

=head1 DESCRIPTION

This module adds L<Test::More>-like code snippets called I<contracts>
to your production code, without turning the whole application
into a giant testing script.

Each contract is compiled once and executed multiple times,
generating reports objects that can be queried to be successful
or printed out as TAP if needed.

=head1 SYNOPSIS

    use Assert::Refute;

    my $spec = contract {
        my ($foo, $bar) = @_;
        is $foo, 42, "Life";
        like $bar, qr/b.*a.*r/, "Regex";
    };

    # later
    my $report = $spec->apply( 42, "bard" );
    $report->count;      # 2
    $report->is_passing; # true
    $report->as_tap;     # printable summary *as if* it was Test::More

=head1 REFUTATIONS AND CONTRACTS

C<refute($condition, $message)> stands for an inverted assertion.
If $condition is B<false>, it is regarded as a B<success>.
If it is B<true>, however, it is considered to be the B<reason>
for a failing test.

This is similar to how Unix programs set their exit code,
or to Perl's own C<$@> variable,
or to the I<falsifiability> concept in science.

A C<contract{ ... }> is as block of code containing various assumptions
about its input.
An execution of such block is considered successful if I<none>
of these assumptions were refuted.

A C<subcontract> is an execution of previously defined contract
in scope of the current one, succeeding silently, but failing loudly.

These three primitives can serve as building blocks for arbitrarily complex
assertions, tests, and validations.

=head1 EXPORT

All of the below functions are exported by default,
as well as some basic assumptions mirroring the L<Test::More> suite.

    use Assert::Refute qw(:core);

would only export C<contract>, C<refute>,
C<contract_is>, C<subcontract>, and C<current_contract> functions.

    use Assert::Refute qw(:basic);

would export the following testing primitives:

C<is>, C<isnt>, C<ok>, C<use_ok>, C<require_ok>, C<cmp_ok>,
C<like>, C<unlike>, C<can_ok>, C<isa_ok>, C<new_ok>,
C<contract_is>, C<subcontract>, C<is_deeply>, C<note>, C<diag>.

See L<Assert::Refute::T::Basic> for more.

Use L<Assert::Refute::Contract> if you insist on no exports and purely
object-oriented interface.

=cut

use Carp;
use Exporter;

use Assert::Refute::Contract;
use Assert::Refute::Build qw(current_contract);
use Assert::Refute::T::Basic;

my @basic = (
    @Assert::Refute::T::Basic::EXPORT,
);
my @core  = qw( contract current_contract refute subcontract contract_is );

our @ISA = qw(Exporter);
our @EXPORT = (@core, @basic);

our %EXPORT_TAGS = (
    basic => \@basic,
    core  => \@core,
);

=head2 contract { ... }

Create a contract specification object for future use.
The form is either

    my $spec = contract {
        my @args = @_;
        # ... work on input
        refute $condition, $message;
    };

or

    my $spec = contract {
        my ($contract, @args) = @_;
        # ... work on input
        $contract->refute( $condition, $message );
    } need_object => 1;

The C<need_object> form may be preferable if one doesn't want to pollute the
main namespace with test functions (C<is>, C<ok>, C<like> etc)
and instead intends to use object-oriented interface.

Other options are TBD.

Note that contract does B<not> validate anything by itself,
it just creates a read-only L<Assert::Refute::Contract>
object sitting there and waiting for an C<apply> call.

The C<apply> call returns a L<Assert::Refute::Exec> object containing
results of specific execution.

This is much like C<prepare> / C<execute> works in L<DBI>.

=cut

sub contract (&@) { ## no critic
    my ($todo, %opt) = @_;

    # TODO check
    $opt{code} = $todo;
    return Assert::Refute::Contract->new( %opt );
};

=head2 refute( $condition, $message )

Test a condition using the current contract.
If no contract is being executed, dies.

The test passes if the $condition is I<false>,
and fails otherwise.

=cut

sub refute ($$) { ## no critic
    current_contract()->refute(@_);
};

=head2 subcontract( "Message" => $contract, @arguments )

Execute a previously defined contract and fail loudly if it fails.

B<[NOTE]> that the message comes first, unlike in C<refute> or other
test conditions, and is I<required>.

For instance, one could apply a previously defined validation to a
structure member:

    my $valid_email = contract {
        my $email = shift;
        # ... define your checks here
    };

    my $valid_user = contract {
        my $user = shift;
        is ref $user, 'HASH'
            or die "Bail out - not a hash";
        like $user->{id}, qr/^\d+$/, "id is a number";
        subcontract "Check e-mail" => $valid_email, $user->{email};
    };

    # much later
    $valid_user->apply( $form_input );

Or pass a definition as I<argument> to be applied to specific structure parts
(think I<higher-order functions>, like C<map> or C<grep>).

    my $array_of_foo = contract {
        my ($is_foo, $ref) = @_;

        foreach (@$ref) {
            subcontract "Element check", $is_foo, $_;
        };
    };

    $array_of_foo->apply( $valid_user, \@user_list );

=cut

sub subcontract($$@) { ## no critic
    current_contract()->subcontract( @_ );
};

=head2 current_contract

Returns the L<Assert::Refute::Exec> object being worked on.
Dies if no contract is being executed at the time.

This is actually a clone of L<Assert::Refute::Build/current_contract>.

=head1 EXTENDING THE SUITE

Although building wrappers around C<refute> call is easy enough,
specialized tool exists for doing that.

Use L<Assert::Refute::Build> to define new I<checks> as
both prototyped exportable functions and their counterpart methods
in L<Assert::Refute::Exec>.

Subclass L<Assert::Refute::Exec> to create new I<drivers>, for instance,
to register failed/passed tests in your unit-testing framework of choice
or generate warnings/exceptions like a normal assertion tool does.

=head1 BUGS

This module is still under development.

Test coverage is maintained at ~80%, but who knows what lurks in the other 20%.

See L<https://github.com/dallaylaen/assert-refute-perl/issues>
to browse old bugs or report new ones.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Assert::Refute

You can also look for information at:

=over

=item * First and foremost, use Github!

=item * C<RT>: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Assert-Refute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Assert-Refute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Assert-Refute>

=item * Search CPAN

L<http://search.cpan.org/dist/Assert-Refute/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Konstantin S. Uvarin. C<< <khedin at gmail.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Assert::Refute
