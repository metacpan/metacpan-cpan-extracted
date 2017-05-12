package Class::Business::DK::Phonenumber;

use strict;
use warnings;
use vars qw($VERSION);
use Carp qw(croak);
use Business::DK::Phonenumber
    qw(validate render validate_template DEFAULT_TEMPLATE DK_PREFIX TRUE FALSE);

$VERSION = '0.10';

## no critic (ValuesAndExpressions::ProhibitEmptyQuotes, ValuesAndExpressions::ProhibitInterpolationOfLiterals)
use overload "" => \&render;

sub new {
    my ( $class, $params ) = @_;

    my $self = bless {
        phonenumber => 0,
        template    => DEFAULT_TEMPLATE,
        prefix      => DK_PREFIX,
        },
        $class || ref $class;

    if ( $params->{phonenumber} ) {
        $self->phonenumber( $params->{phonenumber} )
            or croak
            "phonenumber >$params->{phonenumber}< not in recognisable format";
    } else {
        croak 'phonenumber parameter is mandatory';
    }

    if ( $params->{template} ) {
        $self->template( $params->{template} )
            or croak
            "template >$params->{template}< not in recognisable format";
    }

    $self->{prefix} = $params->{prefix};

    return $self;
}

sub phonenumber {
    my ( $self, $phonenumber, $template ) = @_;

    if ($phonenumber) {

        my $tmp_phonenumber = $self->{phonenumber};

        if ( validate($phonenumber) ) {
            $self->{phonenumber} = $phonenumber;

            if ( $self->template($template) ) {
                return TRUE;
            } else {
                $self->{phonenumber} = $tmp_phonenumber;

                croak "template >$template< not in recognisable format";
            }

            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        if ($template) {
            if ( $self->validate_template($template) ) {
                return $self->render( undef, $template );
            } else {
                croak "template >$template< not in recognisable format";
            }
        } else {
            return $self->render();
        }
    }
}

sub template {
    my ( $self, $template ) = @_;

    if ($template) {
        if ( $self->validate_template($template) ) {
            $self->{template} = $template;
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        return $self->{template};
    }
}

1;

__END__

=pod

=head1 NAME

Class::Business::DK::Phonenumber - class to model, validate and format Danish telephonenumbers

=head1 VERSION

This documentation describes version 0.10

=head1 SYNOPSIS

    use Class::Business::DK::Phonenumber;

    #Constructor
    my $phonenumber = Class::Business::DK::Phonenumber->new('+45 12345678');

    #Brief human readable Danish phonenumber format with international prefix
    print $phonenumber->render('%02d %02d %02d %02d');

    #a brief form validating a stripping everything
    my $phonenum =
        Class::Business::DK::Phonenumber->new('+45 12 34 56 78')->render('%d8');
    # 12345678

    #for MSISDN like representation with protocol prefix
    my $phonenum =
        Class::Business::DK::Phonenumber->new('+45 12 34 56 78')->render('GSM%d10');
    # GSM4512345678

    #for dialing Denmark with international country prefix and international
    #calling code for calling outside Denmark 00
    my $phonenum =
        Class::Business::DK::Phonenumber->new('12 34 56 78')->render('00%d10');
    # 004512345678

=head1 DESCRIPTION

This module offers functionality to validate, format and generate Danish
phonenumbers using object-oriented programming.

Please see:

=over

=item * L<Business::DK::Phonenumber> for a procedural interface

=item * L<Data::FormValidator::Constraints::Business::DK::Phonenumber> for an
integration with L<Data::FormValidator>

=back

The contructor can recognise telephone numbers is the following formats as
Danish phonenumbers.

=over

=item * 12345678

=item * 4512345678

=item * +4512345678

=back

White space characters are ignored. See also L</phonenumber>.

=head1 SUBROUTINES AND METHODS

=head2 new({ phonenumber => $phonenumber, template => $template })

For valid phone number formatting please refer to L</phonenumber>.

=head2 phonenumber($phonenumber, $template)

This is accessor to the phonenumber attribute.

Provided with a valid phone number parameter the object's phone number attribute
is set.

If the accessor is not provided with a phonenumber parameter, the one defined is
in the object is returned.

See also: L<Business::DK::Phonenumber/validate>, which is used internally to
validate the phonenumber parameter.

Valid phone numbers have to abide to the following formatting:

=over

=item * +<international prefix><8 digit phonenumber>

=item * <international prefix><8 digit phonenumber>

=item * <8 digit phonenumber>

=back

The prefixed plus sign and space used as separator are optional as are the
international dialing code.

The phone number can be formatted in anyway separated using whitespace
characters.

=head2 template($template)

This is accessor to the template attribute.

Provided with a valid template parameter the object's template attribute
is set.

If the accessor is not provided with a template parameter, the one defined is in
the object is returned.

See also: L<Business::DK::Phonenumber/validate_template>, which is used
internally to validate the template parameter.

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

=item * L<Business::DK::Phonenumber>

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

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Phonenumber

or by sending mail to

bug-Business-DK-Phonenumber@rt.cpan.org

=head1 MOTIVATION

I have been working in Telco for a long time. So validation and formatting of
telephone numbers is something I have seen at lot of. This module is an attempt
to sort of consolidate the numerous different regular expression solutions
I have seen scathered over large code bases.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-Phonenumber and related is (C) by Jonas B. Nielsen, (jonasbn) 2008-2014

=head1 LICENSE

Business-DK-Phonenumber and related is released under the Artistic License 2.0

=cut
