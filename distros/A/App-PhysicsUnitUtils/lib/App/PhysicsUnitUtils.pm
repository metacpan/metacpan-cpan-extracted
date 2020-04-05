package App::PhysicsUnitUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-04'; # DATE
our $DIST = 'App-PhysicsUnitUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{convert_unit} = {
    v => 1.1,
    summary => 'Convert a physical quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        quantity => {
            # schema => 'physical::quantity*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        to_unit => {
            schema => 'physical::unit',
            pos => 1,
        },
    },
    examples => [
        {args=>{quantity=>'m/s'}, summary=>'Show all possible conversions for speed'},
        {args=>{quantity=>'40 m/s', to_unit=>'kph'}, summary=>'Convert from meters/sec to kilometers/hour'},
    ],
};
sub convert_unit {
    require Physics::Unit;

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @units;
        # XXX make it more efficient
        for my $u (Physics::Unit::ListUnits()) {
            push @units, $u if $quantity->type eq (Physics::Unit::GetUnit($u)->type // '');
        }

        my @rows;
        for my $u (@units) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

1;
# ABSTRACT: Utilities related to Physics::Unit

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PhysicsUnitUtils - Utilities related to Physics::Unit

=head1 VERSION

This document describes version 0.002 of App::PhysicsUnitUtils (from Perl distribution App-PhysicsUnitUtils), released on 2020-04-04.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-unit>

=back

=head1 FUNCTIONS


=head2 convert_unit

Usage:

 convert_unit(%args) -> [status, msg, payload, meta]

Convert a physical quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions for speed:

 convert_unit(quantity => "m/s");

Result:

 [
   { amount => 3.33564095198152e-09, unit => "c" },
   { amount => 3.28083989501312, unit => "fps" },
   { amount => 3600000000000, unit => "knot" },
   { amount => 3600000000000, unit => "knots" },
   { amount => 3.6, unit => "kph" },
   { amount => 0.001, unit => "kps" },
   { amount => 2.2369362920544, unit => "mph" },
   { amount => 1, unit => "mps" },
   { amount => 3.33564095198152e-09, unit => "speed-of-light" },
 ]

=item * Convert from metersE<sol>sec to kilometersE<sol>hour:

 convert_unit(quantity => "40 m/s", to_unit => "kph"); # -> 144

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

=item * B<to_unit> => I<physical::unit>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PhysicsUnitUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PhysicsUnitUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PhysicsUnitUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Physics::Unit>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
