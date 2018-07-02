package Assert::Refute;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.1201';

=head1 NAME

Assert::Refute - Unified testing and assertion tool

=head1 DESCRIPTION

This module adds L<Test::More>-like code snippets
to your production code, without turning the whole application
into a giant testing script.

This can be though of as a lightweight design-by-contract form.

New testing conditions may be added quite easily,
working exactly the same in both production environment and test scripts.

=head1 SYNOPSIS

The following code will issue a warning if required conditions are not met:

    use Assert::Refute qw( :all ), { on_fail => 'carp' };

    my ($foo, $bar, $baz);

    # .......
    # Big and hard to test chunk of code here
    # .......

    try_refute {
        like $foo, qr/f?o?r?m?a?t/, "Format as expected";
        can_ok $bar, qw( do_this do_that frobnicate ),
            "Duck-typing an object";
        cmp_ok $baz, ">", 0, "baz is positive";
    };

As the chunk-of-code is being rewritten into a proper function,
the L</try_refute> block may serve as both a safety net
and a prototype of a future unit test.

The same may be written without polluting the calling package's namespace:

    use Assert::Refute;

    my $report = try_refute {
        my $report = shift;
        $report->is( $foo, 42, "Meaning of life" );
        $report->like( $bar, qr/f?o?r?m?a?t?/, "Text as expected" );
    };

For well-written and well-tested code the use cases may be more subtle.
Still some invariants may be worth a runtime check just in case.

The consequences of both passing and failing assertion block
can be fine-tuned, as in:

    use Assert::Refute {
        on_fail => 'croak',
        on_pass => sub { my $report = shift; $logger->debug(...); },
    };

See L</EXPORT> and L</configure> below.
See also L<Assert::Refute::Report> for the underlying object-oriented interface.

=head1 EXPORT

Per-package configuration parameters can be passed as hash refs in
use statement. Anything that is I<not> hash is passed to L<Exporter> module:

    use Assert::Refute { on_fail => 'croak' }, "try_refute";

Or more generally
(this actually dies because C<foo> and C<bar> parameters are not expected):

    use Assert::Refute { foo => 42 }, "refute", "contract", { bar => 137 };

Valid configuration parameters are (see L</configure> below):

=over

=item * on_pass => skip|carp|croak - what to do when conditions are met.
The default is skip, i.e. do nothing.

=item * on_fail => skip|carp|croak - what to do when conditions are I<not> met.
The default is carp (issue a warning and continue on, even with wrong data).

=item * driver => class - specify an L<Assert::Refute::Report> subclass
to actually execute the tests, if you need to.

=back

All of the below functions are exported by default.

    use Assert::Refute;

as well as

    use Assert::Refute qw(:core);

would only export C<contract>, C<refute>,
C<contract_is>, C<subcontract>, and C<current_contract> functions.

Also for convenience some basic assumptions mirroring the L<Test::More> suite
are exportable via C<:all> export tag.

    use Assert::Refute qw(:all);

would export the following testing primitives:

C<is>, C<isnt>, C<ok>, C<use_ok>, C<require_ok>, C<cmp_ok>,
C<like>, C<unlike>, C<can_ok>, C<isa_ok>, C<new_ok>,
C<contract_is>, C<subcontract>, C<is_deeply>, C<note>, C<diag>.

See L<Assert::Refute::T::Basic> for more.

This distribution also bundles some extra conditions:

=over

=item * L<Assert::Refute::T::Array> - inspect list structure;

=item * L<Assert::Refute::T::Errors> - verify exceptions and warnings;

=item * L<Assert::Refute::T::Hash> - inspect hash keys and values;

=item * L<Assert::Refute::T::Numeric> - make sure numbers fit certain intervals;

=back

Those need to be C<use>d explicitly.

=cut

use Carp;
use Exporter;

use Assert::Refute::Contract;
use Assert::Refute::Build qw(current_contract);
use Assert::Refute::T::Basic;

my @basic = (
    @Assert::Refute::T::Basic::EXPORT, 'plan'
);
my @core  = qw(
    contract refute_these try_refute
    refute subcontract contract_is current_contract
);

our @ISA = qw(Exporter);
our @EXPORT = @core;
our @EXPORT_OK = @basic;

our %EXPORT_TAGS = (
    basic => \@basic,
    core  => \@core,
    all   => [@core, @basic],
);

our $DRIVER;
our %CALLER_CONF;

sub import {
    my $class = shift;
    my (%conf, @exp, $need_conf);
    foreach (@_) {
        if (ref $_ eq 'HASH') {
            %conf = (%conf, %$_);
            $need_conf++;
        } elsif (!ref $_ and $_ eq '{}') {
            # TODO 0.15 remove together with auto-carp
            $need_conf++; # allow for -MAssert::Refute={}
        } elsif (!ref $_) {
            push @exp, $_;
        } else {
            croak "Unexpected argument in Assert::Refute->import: ".ref $_;
        };
    };

    $class->configure( \%conf, scalar caller ) if $need_conf;
    $class->export_to_level(1, undef, @exp);
};

my %known_callback = (
    skip => '',
    carp => sub {
        my $report = shift;
        carp $report->get_tap
            .($report->is_passing ? "Contract passed" : "Contract failed");
    },
    croak => sub {
        my $report = shift;
        croak $report->get_tap
            .($report->is_passing ? "Contract passed" : "Contract failed");
    },
);
my %default_conf = (
    on_fail => 'skip',
    on_pass => 'skip',
);

=head2 try_refute { ... }

Refute several conditions, warn or die if they fail,
as requested during C<use> of this module.
The coderef shall accept one argument, the contract execution object
(likely a L<Assert::Refute::Report>, see C<need_object> above).

More arguments MAY be added in the future.
Return value is ignored.
A contract report object is returned instead.

This is basically what one expects from a module in C<Assert::*> namespace.

=head2 refute_these

B<[DEPRECATED]> Same as above.

It will stay available (with a warning) until as least 0.15.

=cut

sub try_refute(&;@) { ## no critic # need prototype
    my ( $block, @arg ) = @_;

    # Should a missing config even happen? Ok, play defensively...
    my $conf = $CALLER_CONF{+caller};
    if( !$conf ) {
        carp "try_refute(): Usage without explicit configure() is DEPRECATED, assuming { on_fail => 'carp' }";
        $conf = __PACKAGE__->configure( { on_fail => 'carp' }, scalar caller );
    };

    # This is generally a ripoff of A::R::Contract->apply
    my $report = $conf->{driver}->new->do_run($block);

    # perform whatever action is needed
    my $callback = $conf->{ $report->is_passing ? "on_pass" : "on_fail" };
    $callback->($report) if $callback;

    return $report;
};

sub refute_these (&;@) { ## no critic # need prototype
    carp "refute_these { ... } is DEPRECATED, use try_refute{ ... } instead";
    goto \&try_refute; ## no critic
}

=head2 plan tests => n

Plan exactly C<n> refutations.

The contract will fail unconditionally if plan is not fullfilled.

C<plan> can only be called before executing any checks.

=cut

sub plan(@) { ## no critic
    current_contract->plan( @_ );
};

=head2 refute( $condition, $message )

Test one condition in scope of the current contract.

The test passes if the C<$condition> is I<false>, and fails otherwise.
C<$condition> is then assumed to be the I<reason> of failure.
You can think of it as C<ok> and C<diag> combined.

As a special case, an C<\@arrayref> condition will be unfolded into multiple
C<diag> lines, for instance

    refute [ $answer, "isn't", 42 ], "life, universe, and everything";

Returns true for a passing test and false for a failing one.
Dies if no contract is being executed as the time.

=cut

sub refute ($$) { ## no critic
    current_contract()->refute(@_);
};

=head2 contract { ... }

Create a contract specification object for future use:

    use Assert::Refute qw(:all);

    my $spec = contract {
        my ($foo, $bar) = @_;
        is $foo, 42, "Life";
        like $bar, qr/b.*a.*r/, "Regex";
    };

    # later
    my $report = $spec->apply( 42, "bard" );
    $report->get_count;  # 2
    $report->is_passing; # true
    $report->get_tap;    # printable summary *as if* it was Test::More

The same may be written as

    my $spec = contract {
        my ($report, @args) = @_;
        $report->is( ... );
        $report->like( ... );
    } need_object => 1;

The C<need_object> form may be preferable if one doesn't want to pollute the
main namespace with test functions (C<is>, C<ok>, C<like> etc)
and instead intends to use object-oriented interface.

Other options are TBD.

Note that contract does B<not> validate anything by itself,
it just creates a read-only L<Assert::Refute::Contract>
object sitting there and waiting for an C<apply> call.

The C<apply> call returns a L<Assert::Refute::Report> object containing
results of specific execution.

This is much like C<prepare> / C<execute> works in L<DBI>.

See L<Assert::Refute::Contract> for the underlying object-oriented interface.

=cut

sub contract (&@) { ## no critic
    my ($todo, %opt) = @_;

    # TODO check
    $opt{code} = $todo;
    return Assert::Refute::Contract->new( %opt );
};

=head2 subcontract( "Message" => $contract, @arguments )

Execute a previously defined contract and fail loudly if it fails.

B<[NOTE]> that the message comes first, unlike in C<refute> or other
test conditions, and is I<required>.

A I<contract> may be an L<Assert::Refute::Contract> object
or just a subroutine accepting an L<Assert::Refute::Report> as first argument.

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

Returns the L<Assert::Refute::Report> object being worked on.
Dies if no contract is being executed at the time.

This is actually a clone of L<Assert::Refute::Build/current_contract>.

=head1 STATIC METHODS

Use these methods to configure Assert::Refute globally.
There's of course always purely object-oriented L<Assert::Refute::Contract>
for even more fine-grained control.

=head2 configure

    Assert::Refute->configure( \%options );
    Assert::Refute->configure( \%options, "My::Package");

Set per-caller package configuration values for given package.
C<configure> is called implicitly by C<use Assert::Refute { ... }>
if hash parameter(s) are present.

These are adhered to by L</try_refute>, mostly.

Available %options include:

=over

=item * on_pass - callback to execute if tests pass (default: C<skip>)

=item * on_fail - callback to execute if tests fail (default: C<carp>,
but not just C<Carp::carp> - see below).

=item * driver - use that class instead of L<Assert::Refute::Report>
as execution report.

=back

The callbacks MUST be either
a C<CODEREF> accepting L<Assert::Refute::Report> object,
or one of predefined strings:

=over

=item * skip - do nothing;

=item * carp - warn the stringified report;

=item * croak - die with stringified report as error message;

=back

Returns the resulting config (with default values added,etc).

=cut

my %conf_known;
$conf_known{$_}++ for qw( on_pass on_fail driver );

sub configure {
    my ($class, $conf, $caller) = @_;

    croak "Usage: $class->configure( \\%hash, \$target )"
        unless ref $conf eq 'HASH';

    my @extra = grep { !$conf_known{$_} } keys %$conf;
    croak "$class->configure: unknown parameters (@extra)"
        if @extra;

    # configure whoever called us by default
    $caller ||= scalar caller;

    $conf = { %default_conf, %$conf };
    $conf->{on_fail} = _coerce_cb($conf->{on_fail});
    $conf->{on_pass} = _coerce_cb($conf->{on_pass});

    # Load driver
    if( $conf->{driver} ) {
        my $mod = "$conf->{driver}.pm";
        $mod =~ s#::#/#g;
        require $mod;
        croak "$conf->{driver} is not Assert::Refute::Report, cannot use as driver"
            unless $conf->{driver}->isa('Assert::Refute::Report');
    } else {
        $conf->{driver} = 'Assert::Refute::Report'; # this works for sure
    };

    $CALLER_CONF{$caller} = $conf;
};

=head2 get_config

Returns configuration from above, initializing with defaults if needed.

=cut

sub get_config {
    my ($class, $caller) = @_;

    $caller ||= scalar caller;
    return $CALLER_CONF{$caller} ||= $class->configure({}, $caller);
};

sub _coerce_cb {
    my $sub = shift;

    $sub = defined $known_callback{$sub} ? $known_callback{$sub} : $sub;
    return unless $sub;
    croak "Bad callback $sub"
        unless ref $sub and UNIVERSAL::isa( $sub, 'CODE' );
    return $sub;
};

=head1 EXTENDING THE SUITE

Although building wrappers around C<refute> call is easy enough,
specialized tool exists for doing that.

Use L<Assert::Refute::Build> to define new I<checks> as
both prototyped exportable functions and their counterpart methods
in L<Assert::Refute::Report>.
These functions will perform absolutely the same
under control of C<try_refute>, C<contract>, and L<Test::More>:

    package My::Prime;

    use Assert::Refute::Build;
    use parent qw(Exporter);

    build_refute is_prime => sub {
        my $n = shift;
        return "Not a natural number: $n" unless $n =~ /^\d+$/;
        return "$n is not prime" if $n <= 1;
        for (my $i = 2; $i*$i <= $n; $i++) {
            return "$i divides $n" unless $n % $i;
        };
        return '';
    }, args => 1, export => 1;

Much later:

    use My::Prime;

    is_prime 101, "101 is prime";
    is_prime 42, "Life is simple"; # not true

Note that the implementation C<sub {...}> only cares about its arguments,
and doesn't do anything except returning a value.
Suddenly it's a L<pure function|https://en.wikipedia.org/wiki/Pure_function>!

Yet the exact reason for $n not being a prime will be reflected in test output.

One can also subclass L<Assert::Refute::Report>
to create new I<drivers>, for instance,
to register failed/passed tests in a unit-testing framework of choice
or generate warnings/exceptions when conditions are not met.

That's how L<Test::More> integration is done -
see L<Assert::Refute::Driver::More>.

=head1 PERFORMANCE

Unlike some other assertion modules, C<Assert::Refute> does not provide
an easy way to optimize itself out.

Use L<Keyword::DEVELOPMENT> if needed, or just define a DEBUG constant and
append an C<if DEBUG;> statement to C<try_refute{ ... }> blocks.

That said, refute is reasonably fast.
Special care is taken to minimize the CPU usage by I<passing> contracts.

The C<example/00-benchmark.pl> file in this distribution is capable of
verifying around 4000 contracts of 100 statements each in just under a second
on my 4500 C<BOGOMIPS> laptop.
Your mileage may vary!

=head1 WHY REFUTE

Communicating a passing test normally requires 1 bit of information:
everything went as planned.
For failing test, however, as much information as possible is desired.

Thus C<refute($condition, $message)> stands for an inverted assertion.
If $condition is B<false>, it is regarded as a B<success>.
If it is B<true>, however, it is considered to be the B<reason>
for a failing test.

This is similar to how Unix programs set their exit code,
or to Perl's own C<$@> variable,
or to the I<falsifiability> concept in science.

A C<subcontract> is a result of multiple checks,
combined into a single refutation.
It will succeed silently, yet spell out details if it doesn't pass.

These primitives can serve as building blocks for arbitrarily complex
assertions, tests, and validations.

=head1 BUGS

This module is still under heavy development.
See C<TODO> file in this distribution for an approximate roadmap.

New features are marked as B<[EXPERIMENTAL]>.
Features that are to be removed will
stay B<[DEPRECATED]> (with a corresponding warning) for at least 5 releases,
unless such deprecation is extremely cumbersome.

Test coverage is maintained at >90%, but who knows what lurks in the other 10%.

See L<https://github.com/dallaylaen/assert-refute-perl/issues>
to browse old bugs or report new ones.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Assert::Refute

You can also look for information at:

=over

=item * First and foremost, use
L<Github|https://github.com/dallaylaen/assert-refute-perl/>!

=item * C<RT>: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Assert-Refute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Assert-Refute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Assert-Refute>

=item * Search CPAN

L<https://metacpan.org/pod/Assert::Refute>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Thanks to L<Alexander Kuklev|https://github.com/akuklev>
for C<try_refute> function name as well as a lot of feedback.

=item * This L<rant|https://www.perlmonks.org/?node_id=1122667>
by C<Daniel Dragan> inspired me to actually start working
on the first incarnation of this project.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

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
