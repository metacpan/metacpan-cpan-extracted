package Business::DK::Phonenumber;

use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK);
use Carp qw(croak);
use base qw(Exporter);
use 5.008;

$VERSION = '0.10';
@EXPORT_OK
    = qw(validate render generate validate_template TRUE FALSE DK_PREFIX  DEFAULT_TEMPLATE);

use constant TRUE             => 1;
use constant FALSE            => 0;
use constant DK_PREFIX        => '+45';
use constant DIGITS           => 8;
use constant DEFAULT_TEMPLATE => DK_PREFIX . ' %0' . DIGITS . 'd';
use constant SEED             => 99999999;

sub validate {
    my ( $self, $phonenumber ) = @_;

    if ( not ref $self ) {
        $phonenumber = $self;
    }

    $phonenumber =~ s/\s//sxmg;

    if ($phonenumber =~ m{
            \A(
            (?:[+])(?:45)(?:\d{8})| #+4512345678
            (?:45)(?:\d{8})|       #4512345678
            (?:\d{8})              #12345678
            )\z}sgmx
        )
    {
        return TRUE;
    } else {
        return FALSE;
    }
}

sub render {
    my ( $self, $phonenumber, $template ) = @_;

    if ( $self =~ m/\A[\D]+\b/smx and not ref $self ) {
        $self = undef;

    } elsif ( not ref $self ) {
        $template    = $phonenumber;
        $phonenumber = $self;
        $self        = undef;

    } else {

        if ($template) {
            if ( ref $self ) {
                $self->validate_template($template);
            } else {
                Class::Business::DK::Phonenumber::validate_template(
                    $template);
            }
        } else {
            $template = $self->{template} || DEFAULT_TEMPLATE;
        }

        if ( not $phonenumber ) {
            $phonenumber = $self->{phonenumber};
        }
    }

    $phonenumber =~ s/\s//sxmg;

    my @subs = $template =~ m/%(\d)+d/sxmg;

    my $sum        = 0;
    my @phonesplit = ();
    my $phonetmp   = $phonenumber;

    foreach my $sub (@subs) {
        $sum += $sub;
        push @phonesplit, substr $phonetmp, 0, $sub, q{};
    }

    my $output = sprintf $template, @phonesplit;

    return $output;
}

sub generate {
    my ( $self, $amount, $template ) = @_;

    if ( not $amount ) {
        $amount = 1;
    }

    if ( not $template ) {
        $template = DEFAULT_TEMPLATE;
    }

    my %phonenumbers;
    while ( keys %phonenumbers < $amount ) {
        if ( ref $self ) {
            $phonenumbers{ $self->_generate($template) }++;
        } else {
            $phonenumbers{ _generate($template) }++;
        }
    }

    my @phonenumbers = keys %phonenumbers;

    return @phonenumbers;
}

sub _generate {
    my ( $self, $template ) = @_;

    my $random_phone = int rand SEED;
    my $phonenumber = sprintf '%.08d', $random_phone;

    if ( ref $self ) {
        return $self->render( $phonenumber, $template );
    } else {
        $template = $self;

        return render( $phonenumber, $template );
    }
}

sub validate_template {
    my ( $self, $template ) = @_;

    my @digits = $template =~ m/%(\d)+d/sxmg;

    my $sum = 0;
    foreach my $digit (@digits) {
        $sum += $digit;
    }

    if ( $sum == DIGITS ) {
        return TRUE;
    } else {
        return FALSE;
    }
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Business-DK-Phonenumber.svg)](http://badge.fury.io/pl/Business-DK-Phonenumber)
[![Build Status](https://travis-ci.org/jonasbn/bdkphn.svg?branch=master)](https://travis-ci.org/jonasbn/bdkphn)
[![Coverage Status](https://coveralls.io/repos/jonasbn/bdkphn/badge.png?branch=master)](https://coveralls.io/r/jonasbn/bdkphn?branch=master)

=end markdown

=head1 NAME

Business::DK::Phonenumber - Danish telephone number validator/formatter

=head1 VERSION

This documentation describes version 0.10

=head1 SYNOPSIS

    use Business::DK::Phonenumber qw(validate render);

    #Validation
    if (Business::DK::Phonenumber->validate($phonenumber)) { ... }

    #Default format
    print Business::DK::Phonenumber->render($phonenum);
    # +45 12 34 56 78

    #Brief human readable Danish phone number format
    print Business::DK::Phonenumber->render($phonenum, '%08d');
    # 12345678

    #Normal human readable Danish phonenumber format
    print Business::DK::Phonenumber->render($phonenum, '%02d %02d %02d %02d');
    # 12 34 56 78

    #Generation of a single random number
    Business::DK::Phonenumber->generate();

    #Generation of 100 random numbers, using another template
    Business::DK::Phonenumber->generate(100, '%02d %02d %02d %02d');

=head1 DESCRIPTION

This module offers functionality to validate, format and generate Danish
phone numbers.

The validation can recognise telephone numbers is the following formats as
Danish phone numbers.

=over

=item * 12345678

=item * 4512345678

=item * +4512345678

=back

White space characters are ignored.

In addition to validation the module offers generation of valid danish
phone numbers. The purpose of using generated phone number is up to the user, but
the original intent is generation of varied sets of test data.

If you want to use OOP please have a look at:

=over

=item * L<Class::Business::DK::Phonenumber>

=back

If you are using L<Data::FormValidator>

=over

=item * L<Data::FormValidator::Constraints::Business::DK::Phonenumber>

=back

=head1 SUBROUTINES AND METHODS

The following subroutines are to be used in a procedural manner.

=head2 validate($phonenumber)

This subroutine takes a string and validated whether it is a Danish phone number.

Returns 1 (true) or 0 (false), depending on validity.

=head2 render($phonenumber, $template)

Returns a phonenumber rendered according to the template parameter or the
default.

=head2 generate($template, $amount)

This subroutine takes a string representing a phone number template and generates
the amount specified by second argument: amount. If no amount is specified only
a single random phone number is returned.

The subroutine returns an array, no matter what amount is specified.

=head2 _generate($template)

This is the actual generating method used by L</generate>.

It takes a single parameter, a string indicating the template for the formatting
of the phone numbers to be generated.

It returns a single random number representing a Danish phone number formatted
as outlined by the specified template.

=head2 validate_template

This method is used internally to validate template parameters. Please refer to
Perl's sprintf for documentation.

=head1 DIAGNOSTICS

=over

=item * phone number not in recognisable format, the phone number provided to
the constructor is not parsable. Please evaluate what you are attempting to
feed to the constructor.

=item * phone number parameter is mandatory for the constructor, please specify
the phone number parameter to the constructor in order to continue.

=item * template not in recognisable format, the template provided to the
constructor is not in a parsable format, please evaluate what you attempting to
feed to the constructor.

=back

=head1 CONFIGURATION AND ENVIRONMENT

No special configuration or environment is necessary.

=head1 DEPENDENCIES

=over

=item * L<Carp>

=item * L<Exporter>

=back

=head1 INCOMPATIBILITIES

No known incompatibilities at this time.

=head1 BUGS AND LIMITATIONS

No known bugs or limitations at this time.

=head1 TEST AND QUALITY

=over

=item * The L<Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators>
policy has been disabled. We are working with phonenumbers, strings consisting primarily of number, so not special interpretation or calculative behaviour is needed.

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma> policy has been disabled. I like constants.

=item * L<Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint> policy has been disabled for now should be revisited at some point.

=back

=head1 TODO

=over

=item * Please refer to the distribution TODO file

=back

=head1 SEE ALSO

=over

=item L<sprintf>

Business::DK::Phonenumber utilizes sprintf to as templating system for
formatting telephonenumbers. This is a well specified and tested interface
which is easy to use.

=item L<Class::Business::DK::Phonenumber>

An OOP approach to regarding a Danish phone number as an object

=item L<Data::FormValidator::Constraints::Business::DK::Phonenumber>

Wrapper for integrating with L<Data::FormValidator>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Phonenumber>

or by sending mail to

bug-Business-DK-Phonenumber@rt.cpan.org

=head1 MOTIVATION

I have been working in Telco for a long time. So validation and formatting of
telephone numbers is something I have seen at lot of. This module is an attempt
to sort of consolidate the numerous different regular expression solutions
I have seen scattered over large code bases.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-Phonenumber and related is (C) by Jonas B. Nielsen, (jonasbn) 2008-2014

=head1 LICENSE

Business-DK-Phonenumber and related is released under the Artistic License 2.0

=cut
