package Class::Param::Compound;

use strict;
use warnings;
use base 'Class::Param::Base';

use Params::Validate qw[];

sub new {
    my $class  = ref $_[0] ? ref shift : shift;
    my $params = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            (
                {
                    type     => Params::Validate::OBJECT,
                    isa      => 'Class::Param::Base',
                    optional => 0
                }
            ) x @_
        ],
        called  => "$class\::new"
    );

    return bless( $params, $class );
}

sub params {
    return wantarray ? @{ $_[0] } : [ @{ $_[0] } ];
}

sub get {
    my ( $self, $name ) = @_;

    my @values = ();

    foreach my $param ( $self->params ) {

        next unless $param->has($name);

        my $value = $param->get($name);

        if ( ref $value eq 'ARRAY' ) {
            push @values, @{ $value };
        }
        else {
            push @values, $value;
        }
    }

    return @values > 1 ? \@values : $values[0];
}

sub set {
    my ( $self, $name, $value ) = @_;

    foreach my $param ( $self->params ) {
        $param->set( $name => $value );
    }

    return 1;
}

sub clear {
    my $self = shift;

    foreach my $param ( $self->params ) {
        $param->clear;
    }

    return 1;
}

sub remove {
    my ( $self, $name ) = @_;

    my @removed = ();

    foreach my $param ( $self->params ) {

        my $value = $param->remove($name);

        if ( ref $value eq 'ARRAY' ) {
            push @removed, @{ $value };
        }
        else {
            push @removed, $value;
        }
    }

    return @removed > 1 ? \@removed : $removed[0];
}

sub names {
    my $self = shift;

    my %seen  = ();
    my @names = ();

    foreach my $param ( $self->params ) {
        push @names, $param->names;
    }

    return grep { $seen{$_}++ == 0 } @names;
}

1;

__END__

=head1 NAME

Class::Param::Compound - Class Param Compound Class

=head1 SYNOPSIS

    $param = Class::Param::Compound->new(@params);

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
