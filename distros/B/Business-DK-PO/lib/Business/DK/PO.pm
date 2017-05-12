package Business::DK::PO;

use strict;
use warnings;
use integer;
use Carp qw(croak);
use vars qw($VERSION @EXPORT_OK);
use 5.006;

use base qw(Exporter);

my @controlcifers = qw(2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1);

$VERSION = '0.08';
@EXPORT_OK =
  qw(calculate validate validatePO _argument _content _length _calculate_sum);

use constant CONTROLCODE_LENGTH => 16;
use constant INVOICE_MINLENGTH  => 1;
use constant INVOICE_MAXLENGTH  => 15;
use constant MODULUS_OPERAND    => 10;
use constant SUM_THRESHOLD      => 9;

sub calculate {
    my ( $number, $maxlength, $minlength ) = @_;

    if ( !$minlength ) {
        $minlength = INVOICE_MINLENGTH;
    }

    if ( !$maxlength ) {
        $maxlength = INVOICE_MAXLENGTH;
    }

    if ( !$number ) {
        _argument( $minlength, $maxlength );
    }
    _content($number);
    _length( $number, $minlength, $maxlength );

    my $format = '%0' . $maxlength . 's';
    $number = sprintf "$format", $number;

    my $sum = _calculate_sum($number);

    my $mod         = $sum % MODULUS_OPERAND;
    my $checkciffer = 0;

    $checkciffer = ( MODULUS_OPERAND - $mod );

    return ( $number . $checkciffer );
}

## no critic (RequireArgUnpacking)
sub validatePO {
    return validate(@_);
}

sub validate {
    my $controlnumber = shift;

    if ( !$controlnumber ) {
        _argument(CONTROLCODE_LENGTH);
    }
    _content($controlnumber);
    _length( $controlnumber, CONTROLCODE_LENGTH );

    my $sum = _calculate_sum($controlnumber);

    if ( $sum % MODULUS_OPERAND ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub _argument {
    my ( $length, $maxlen ) = @_;

    if ($maxlen) {
        croak
"function takes an argument of minimum: $length and maximum $maxlen digits";

    }
    elsif ($length) {
        croak "function takes an argument of $length digits";
    }
    else {
        croak "function takes an argument";
    }
}

sub _content {
    my $number = shift;

    if ( $number !~ /^\d*$/ ) {
        croak "argument: $number must only contain digits";
    }
    return 1;
}

sub _length {
    my ( $number, $length, $maxlen ) = @_;

    if ($maxlen) {
        if ( length($number) < $length ) {
            croak "argument: $number has to be $length digits long";

        }
        elsif ( length($number) > $maxlen ) {
            croak "argument: $number must be not more than $maxlen digits long";
        }

    }
    else {
        if ( length($number) != $length ) {
            croak "argument: $number has to be $length digits long";
        }
    }
    return 1;
}

sub _calculate_sum {
    my $number = shift;

    my $sum = 0;
    my @numbers = split( //, $number );

    for ( my $i = 0 ; $i < scalar(@numbers) ; $i++ ) {
        my $tmpsum2 = 0;
        my $tmpsum  = $numbers[$i] * $controlcifers[$i];

        if ( $tmpsum > SUM_THRESHOLD ) {

            #TODO: address this construct
            ## no critic (BuiltinFunctions::ProhibitVoidMap)
            map( { $tmpsum2 += $_ } split( //, $tmpsum ) );
            $tmpsum = $tmpsum2;
        }
        $sum += $tmpsum;
    }

    return $sum;
}

1;

__END__

=pod

=head1 NAME

Business::DK::PO - Danish postal order number validator

=head1 VERSION

This documentation describes version 0.07

=head1 SYNOPSIS

    use Business::DK::PO qw(validate);

    my $rv;
    eval {
        $rv = validate(1234563891234562);
    };

    if ($@) {
        die "Code is not of the expected format - $@";
    }

    if ($rv) {
        print "Code is valid";
    } else {
        print "Code is not valid";
    }


    use Business::DK::PO qw(calculate);

    my $code = calculate(1234);


    #Using with Params::Validate

    use Params::Validate qw(:all);
    use Business::DK::PO qw(validatePO);

    sub check_cpr {
        validate( @_,
        { po =>
            { callbacks =>
                { 'validate_po' => sub { validatePO($_[0]); } } } } );

        print $_[1]." is a valid PO\n";

    }

=head1 DESCRIPTION

The postal orders and postal order codes are used by the danish postal service
B<PostDanmark>.

=head1 SUBROUTINES/METHODS

=head2 validate

The function takes a single argument, a 16 digit postal order code.

The function returns 1 (true) in case of a valid postal order code argument and
0 (false) in case of an invalid postal order code argument.

The validation function goes through the following steps.

Validation of the argument is done using the functions (all described below in
detail):

=over

=item * _argument

=item * _content

=item * _length

=back

If the argument is a valid argument the sum is calculated by B<_calculate_sum>
based on the argument and the controlcifers array.

The sum returned is checked using a modulus caluculation and based on its
validity either 1 or 0 is returned.

=head2 validatePO

A wrapper for L</validate> with a name more suitable for importing, it is less
common and therefor less intrusive.

See L</validate> for details.

=head2 calculate

The function takes a single argument, an integer indicating a unique reference
number you can use to identify an order. Suggestions are invoice number,
order number or similar.

The number provided must be between 1 and 15 digits long, meaning a number
between 1 and 999 trillions.

The function returns a postal order code consisting of the number given as
argument appended with a control cifer to make the code valid (See: b<validate>

The calculation function goes through the following steps.

Validation of the argument is done using the functions (all described below in
detail):

=over

=item * _argument

=item * _content

=item * _length

=back

If the argument is a valid argument the sum is calculated by B<_calculate_sum>
based on the argument and the controlcifers array.

Based on the sum the argument the controlcifer is calculated and appended so
that the argument becomes a valid postal order code.

The calculated and valid code is then returned, left-padded with zeroes to make
it 16 digits long (SEE: validate).

=head1 PRIVATE SUBROUTINES/METHODS

=head2 _argument

This function is called from either B<validate> or B<calculate> if an argument
is not provided.

It dies with an error message indicating the exceptional situation and attempts
to guide the user to providing a sensible input.

The B<_argument> function takes two arguments:

=over

=item * minimum length required of number (mandatory)

=item * maximum length required of number (optional)

=back

The arguments are used in the error message issued with B<die>, since this
method always dies.

=head2 _content

This function validates the content of the argument, it croaks if the argument
is not an integer (consisting of digits only).

=head2 _length

This function validates the length of the argument, it dies if the argument
does not fit wihtin the boundaries specified by the arguments provided:

The B<_length> function takes the following arguments:

=over

=item * number (mandatory), the number to be validated

=item * minimum length required of number (mandatory)

=item * maximum length required of number (optional)

=back

=head2 _calculate_sum

This function takes an integer and calculates the sum bases on the the
controlcifer array.

=head1 EXPORTS

Business::DK::PO exports on request:

=over

=item * L</validate>

=item * L</validatePO>

=item * L</calculate>

=item * L</_argument>

=item * L</_content>

=item * L</_length>

=item * L</_calculate_sum>

=back

=head1 TESTS

Coverage of the test suite is at 100%

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Business/DK/PO.pm    100.0  100.0    n/a  100.0  100.0  100.0  100.0
    Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

Test::Kwalitee passes

Test::Perl::Critic passes at severity 1, brutal, with many policies disabled
though, see F</perlcriticrc>.

=head1 BUGS

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-PO

or by sending mail to

  bug-Business-DK-PO@rt.cpan.org

=head1 SEE ALSO

=over

=item L<http://www.bgbank.dk/bfBlankethaandbog>

=item bin/calculate_po.pl

=item bin/validate_po.pl

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-PO is (C) by Jonas B. Nielsen, (jonasbn) 2006-2014

Business-DK-PO is released under the artistic license

The distribution is licensed under the Artistic License, as specified
by the Artistic file in the standard perl distribution
(http://www.perl.com/language/misc/Artistic.html).

=cut
