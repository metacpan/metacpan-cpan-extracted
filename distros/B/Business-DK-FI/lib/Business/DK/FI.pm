package Business::DK::FI;

use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK);
use Params::Validate qw(validate_pos SCALAR ARRAYREF);
use Readonly;
use base qw(Exporter);
use English qw( -no_match_vars );
use 5.006;

$VERSION   = '0.09';
@EXPORT_OK = qw(validate validateFI generate);

use constant MODULUS_OPERAND => 10;
use constant THRESHOLD       => 10;
use constant DEDUCTION       => 9;
use constant INVALID         => 0;
use constant VALID           => 1;

Readonly::Array my @CONTROLCIFERS   => qw(1 2 1 2 1 2 1 2 1 2 1 2 1 2);
Readonly::Scalar my $CONTROL_LENGTH => scalar @CONTROLCIFERS;

## no critic (NamingConventions::Capitalization)

sub validateFI {
    return validate(shift);
}

sub validate {
    my ($fi_number) = @ARG;

    validate_pos( @ARG, { type => SCALAR, regex => qr/^\d{15}$/xsm } );

    my ($last_digit);
    ( $fi_number, $last_digit )
        = $fi_number =~ m/^(\d{$CONTROL_LENGTH})(\d{1})$/xsm;

    my $sum = _calculate_sum( $fi_number, \@CONTROLCIFERS );
    my $checksum = _calculate_checksum($sum);

    if ( $checksum == $last_digit ) {
        return VALID;
    }
    else {
        return INVALID;
    }
}

sub _calculate_checksum {
    my ($sum) = @ARG;

    validate_pos( @ARG, { type => SCALAR, regex => qr/^\d+$/xsm }, );

    return ( THRESHOLD - ( $sum % MODULUS_OPERAND ) );
}

sub _calculate_sum {
    my ( $number, $CONTROLCIFERS ) = @ARG;

    validate_pos(
        @ARG,
        { type => SCALAR, regex => qr/^\d+$/xsm },
        { type => ARRAYREF },
    );

    my $sum = 0;
    my @numbers = split //smx, $number;

## no critic (ControlStructures::ProhibitCStyleForLoops)
    for ( my $i = 0; $i < scalar @numbers; $i++ ) {
        my $tmp_sum = $numbers[$i] * $CONTROLCIFERS->[$i];

        if ( $tmp_sum >= THRESHOLD ) {
            $sum += ( $tmp_sum - DEDUCTION );
        }
        else {
            $sum += $tmp_sum;
        }
    }
    return $sum;
}

sub generate {
    my ($number) = @ARG;

    #number has to be a positive number between 1 and 99999999999999
    validate_pos(
        @ARG,
        {   type      => SCALAR,
            regex     => qr/^\d+$/,
            callbacks => {
                'higher than 0' => sub { shift() >= 1 },
                'lower than 99999999999999' =>
                    sub { shift() <= 99999999999999 },
            },
        },
    );

    #padding with zeroes up to our maximum length
    my $pattern = '%0' . $CONTROL_LENGTH . 's';
    my $reformatted_number = sprintf $pattern, $number;

    #this call takes care of the check of the product of the above statement
    my $sum = _calculate_sum( $reformatted_number, \@CONTROLCIFERS );
    my $checksum = _calculate_checksum($sum);

    my $finalized_number = $reformatted_number . $checksum;

    return $finalized_number;
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Business-DK-FI.svg)](http://badge.fury.io/pl/Business-DK-FI)
[![Build Status](https://travis-ci.org/jonasbn/bdkfi.svg?branch=master)](https://travis-ci.org/jonasbn/bdkfi)
[![Coverage Status](https://coveralls.io/repos/jonasbn/bdkfi/badge.png)](https://coveralls.io/r/jonasbn/bdkfi)

=end markdown

=head1 NAME

Business::DK::FI - Danish FI number validator

=head1 VERSION

The documentation describes version 0.09

=head1 SYNOPSIS

    use Business::DK::FI qw(validate validateFI generate);

    if (validate('026840149965328')) {
        print "026840149965328 is valid\n";
    }


    my $fi_number = generate(1);

    if ($fi_number eq '000000000000018') {
        print "we have a FI number\n";
    }


=head1 DESCRIPTION

FI numbers are numbers used on GIRO payment forms. These can be used to do
online payments in banks or at in physical banks or post offices.

The module currently only supports FI numbers in the following series:

=over

=item * 71

=item * 75

=back

=head1 SUBROUTINES AND METHODS

=head2 validate

Takes a single argument. 15 digit FI number. Returns true (1) or false (0)
indicating whether the provided parameter adheres to specification.

=head2 validateFI

Less intrusive exported variation of L</validate>. It is actually L</validate>
which is wrapping L</validateFI>.

=head2 generate

Simple FI generation method. Takes an arbitrary number adhering to the following requirements: 

=over

=item * length between 1 and 14

=item * value between 1 and 99999999999999

=back

Returns a valid FI number.

=head2 PRIVATE SUBROUTINES AND METHODS

=head2 _calculate_checksum

This method calculates a checksum, it takes a single number as parameter and returns the calculated checksum.

=head2 _calculate_sum

This method calculates a sum it takes a number and a reference to an array of control cifers. It calculates a single sum based on the number and the control cifer and returns this.

=head1 DIAGNOSTICS

All methods B<die> if their API is not respected. Method calls can with success be wrapped in L<Try::Tiny> or C<eval> blocks.

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment.

=head1 DEPENDENCIES

=over

=item * L<Params::Validate>

=item * L<Readonly>

=item * L<Exporter>

=item * L<English>

=back

=head1 BUGS AND LIMITATIONS

This module has no known bugs or limitations.

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-FI>

=back

or by sending mail to

=over

=item * C<< <bug-Business-DK-FI@rt.cpan.org> >>

=back

=head1 TEST AND QUALITY

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Business/DK/FI.pm    100.0  100.0    n/a  100.0  100.0   34.8  100.0
    ...b/Class/Business/DK/FI.pm   97.6   83.3    n/a  100.0  100.0   65.2   96.9
    Total                          99.1   90.0    n/a  100.0  100.0  100.0   98.7
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 QUALITY AND CODING STANDARD

The code passes L<Perl::Critic> tests at severity 1 (I<brutal>) with a set of policies disabled. please see F<t/perlcriticrc> and the list below:

=over

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>, please
see: L<http://logiclab.jira.com/wiki/display/OPEN/Perl-Critic-Policy-ValuesAndExpressions-ProhibitConstantPragma>

=item * L<Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>, this
is listed in the L</TODO> it requires numerous changes to the distribution POD.

=item * L<Perl::Critic::Policy::NamingConventions::Capitalization>, L</validateFI> is exported both as L</validateFI> and L</validate> and B<FI> is our used acronym
so we try to stick to this

=item * L<Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops>, this
is for the main algorithm, it was easier to do with a B<C-style for loop>

=item * L<Perl::Critic::Policy::Subroutines::RequireArgUnpacking>, this is due to
the way: L<Params::Validate> is used

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers>, we
use long control numbers

=item * L<Perl::Critic:.:Policy::Variables::ProhibitPunctuationVars>

=back

=head1 TODO

Please see the distribution F<TODO> file also and the distribution road map at:
    L<http://logiclab.jira.com/browse/BDKFI#selectedTab=com.atlassian.jira.plugin.system.project%3Aroadmap-panel>

=head1 SEE ALSO

=over

=item * http://www.pbs.dk/

=item * L<Try::Tiny>

=item * L<Business::DK::CVR>

=item * L<Business::DK::CPR>

=item * L<Business::DK::PO>

=item * L<Business::DK::Postalcode>

=item * L<Business::DK::Phonenumber>

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-FI and related is (C) by Jonas B. Nielsen, (jonasbn) 2009-2016

=head1 LICENSE

Business-DK-FI and related is released under the Artistic License 2.0

See the included license file for details

=cut
