package Business::DK::CVR;

use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK);
use Carp qw(croak);
use Params::Validate qw(validate_pos SCALAR OBJECT ARRAYREF );
use Readonly;
use 5.008; #5.8.0

use base qw(Exporter);

$VERSION   = '0.09';
@EXPORT_OK = qw(validate validateCVR generate _calculate_sum);

use constant MODULUS_OPERAND => 11;
use constant MAX_CVRS        => 9090908;
use constant VALID           => 1;
use constant INVALID         => 0;

Readonly my @controlcifers => qw(2 7 6 5 4 3 2 1);

sub validateCVR {
    return validate(shift);
}

sub validate {
    my ($controlnumber) = @_;

    validate_pos( @_, { type => SCALAR, regex => qr/^\d{8}$/ } );

    my $sum = _calculate_sum( $controlnumber, \@controlcifers );

    if ( $sum % MODULUS_OPERAND ) {
        return INVALID;
    } else {
        return VALID;
    }
}

sub _calculate_sum {
    my ( $number, $controlcifers ) = @_;

    validate_pos( @_,
        { type => SCALAR, regex => qr/^\d+$/ },
        { type => ARRAYREF },
    );

    my $sum = 0;
    my @numbers = split //smx, $number;

    for ( my $i = 0; $i < scalar @numbers; $i++ ) {
        $sum += $numbers[$i] * $controlcifers->[$i];
    }
    return $sum;
}

sub generate {
    my @array = validate_pos( @_,
        { type => OBJECT | SCALAR, optional => 1 },
        { type => SCALAR, optional => 1, default => 1 },
        { type => SCALAR, optional => 1, default => 1 },
    );

    my ( $self, $amount, $seed ) = @array;

    if ( defined $self and $self =~ m/\d+/ ) {
        $seed   = $amount;
        $amount = $self;
    }

    my @cvrs;
    my $cvr;

    if ( $amount > MAX_CVRS ) {
        croak 'The amount requested exceeds the maximum possible valid CVRs ('
            . MAX_CVRS . ')';
    }

    my $count = $amount;
    while ($count) {
        $cvr = sprintf '%08d', $seed;
        if ( validate($cvr) ) {
            push @cvrs, $cvr;
            $count--;
        }
        $seed++;
    }

    if (wantarray) {
        return @cvrs;
    } else {
        if ( $amount == 1 ) {
            return $cvr;
        } else {
            return \@cvrs;
        }
    }
}

1;

__END__

=pod

=head1 NAME

Business::DK::CVR - Danish CVR (VAT Registration) code generator/validator

=head1 VERSION

This documentation describes version 0.09 of Business::DK::CVR

=head1 SYNOPSIS

    use Business::DK::CVR qw(validate);

    my $rv;
    eval { $rv = validate(27355021); };

    if ($@) {
        die "Code is not of the expected format - $@";
    }

    if ($rv) {
        print "Code is valid";
    } else {
        print "Code is not valid";
    }

    #Using with Params::Validate
    #See also examples/
    
    use Params::Validate qw(:all);
    use Business::DK::CVR qw(validateCVR);
    
    eval {
        check_cvr(cvr => 27355021);
    };
    
    if ($@) {
        print "CVR is not valid - $@\n";
    }
    
    eval {
        check_cvr(cvr => 27355020);
    };
    
    if ($@) {
        print "CVR is not valid - $@\n";
    }
    
    sub check_cvr {
        validate( @_,
        { cvr =>
            { callbacks =>
                { 'validate_cvr' => sub { validateCVR($_[0]); } } } } );
        
        print "$_[0] is a valid CVR\n";
    
    }

=head1 DESCRIPTION

CVR is a company registration number used in conjuction with VAT handling in
Denmark.

If you want to use this module with L<Data::FormValidator> please check:
L<Data::FormValidator::Constraints::Business::DK::CVR>

=head1 SUBROUTINES AND METHODS

=head2 validate

The function takes a single argument, a 10 digit CVR number. 

The function returns 1 (true) in case of a valid CVR number argument and  0 
(false) in case of an invalid CVR number argument.

If the argument is a valid argument the sum is calculated by B<_calculate_sum>
based on the argument and the controlcifers array.

The sum returned is checked using a modulus caluculation and based on its
validity either 1 or 0 is returned.

=head2 validateCVR

Better name for export. This is just a wrapper for L</validate>

=head2 generate

Generate is a function which generates valid CVR numbers, it is by no means
an authority, since CVRs are generated and distributed by danish tax
authorities, but it can be used to generate example CVRs for testing and so on.

=head1 PRIVATE FUNCTIONS

=head2 _calculate_sum

This function takes an integer and calculates the sum bases on the the 
controlcifer array.

=head1 EXPORTS

Business::DK::CVR exports on request:

=over

=item L</validate>

=item L</generate>

=item L</_calculate_sum>

=back

=head1 DIAGNOSTICS

=over

=item * The amount requested exceeds the maximum possible valid CVRs 9090908

The number of valid CVRs are limited, so if the user requests a number of CVRs
to be generated which exceeds the upper limit, this error is instantiated.
See: L</generate>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment to run.

=head1 DEPENDENCIES

=over

=item * L<Params::Validate>

=item * L<Exporter>

=item * L<Carp>

=item * L<Scalar::Util>

=item * L<Class::InsideOut>

=item * L<English>

=item * L<Params::Validate>

=item * L<Readonly>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The module has no known bugs or limitations.

=head1 TEST AND QUALITY

Coverage of the test suite is at 100%

=head1 TODO

=over

=item * Get the generate method thorougly tested

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CVR

or by sending mail to

  bug-Business-DK-CVR@rt.cpan.org

=head1 SEE ALSO

=over

=item L<http://www.cvr.dk/>

=item L<Business::DK::PO>

=item L<Business::DK::CPR>

=item L<http://search.cpan.org/dist/Algorithm-CheckDigits>

=item L<http://search.cpan.org/~mamawe/Algorithm-CheckDigits-0.38/CheckDigits/M11_008.pm>

=item L<Data::FormValidator::Constraints::Business::DK::CVR>

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-CVR is (C) by Jonas B. Nielsen, (jonasbn) 2006-2014

=head1 LICENSE

Business-DK-CVR is released under the artistic license

The distribution is licensed under the Artistic License, as specified
by the Artistic file in the standard perl distribution
(http://www.perl.com/language/misc/Artistic.html).

=cut
