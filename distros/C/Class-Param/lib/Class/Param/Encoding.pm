package Class::Param::Encoding;

use strict;
use warnings;
use base 'Class::Param::Decorator';

use Encode           qw[];
use Params::Validate qw[];

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my ( $decorated, $encoding ) = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            {
                type      => Params::Validate::OBJECT,
                isa       => 'Class::Param::Base',
                optional  => 0
            },
            {
                type      => Params::Validate::SCALAR,
                default   => 'UTF-8',
                optional  => 1,
                callbacks => {
                    'valid Encode encoding' => sub {
                        return Encode::find_encoding( $_[0] );
                    }
                }
            }
        ],
        called  => "$class\::new"
    );

    return bless( [ $decorated, Encode::find_encoding($encoding) ], $class );
}

sub encoding { return $_[0]->[1] }

sub get {
    my ( $self, $name ) = @_;

    my @values = ();

    foreach my $value ( $self->decorated->param($name) ) {

        if ( ref $value || Encode::is_utf8($value) ) {
            push @values, $value;
        }
        else {
            push @values, $self->encoding->decode( $value, Encode::FB_CROAK );
        }
    }

    return @values > 1 ? \@values : $values[0];
}

1;

__END__

=head1 NAME

Class::Param::Encoding - Class Param Encoding Class

=head1 SYNOPSIS

    $param = Class::Param->new( smiley => "\xE2\x98\xBA" );
    $param = Class::Param::Encoding->new( $param );

    if ( $param->get('smiley') eq "\x{263A}" ) {
        # true
    }

=head1 DESCRIPTION

A decorator that decodes param values on the fly.

=head1 METHODS

=over 4

=item new ( $param [, $encoding ] )

Constructor. Takes two arguments, first should be a instance of L<Class::Param::Base>
and second should be valid L<Encode> encoding name, defaults to C<UTF-8>.

=back

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
