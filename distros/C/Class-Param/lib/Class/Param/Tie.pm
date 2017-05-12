package Class::Param::Tie;

use strict;
use warnings;
use base 'Class::Param::Decorator';

sub initialize {
    my ( $instance, $decorated ) = @_;

    my $class = ref($instance);
    my $self  = {};

    tie( %{ $self }, 'Class::Param::Tie::Param', $decorated );

    return bless( $self, $class );
}

sub decorated { return tied( %{ shift() } )->decorated (@_) }
sub add       { return shift->decorated->add           (@_) }
sub count     { return shift->decorated->count         (@_) }
sub param     { return shift->decorated->param         (@_) }
sub scan      { return shift->decorated->scan          (@_) }
sub as_hash   { return shift->decorated->as_hash       (@_) }

package Class::Param::Tie::Param;

use strict;
use warnings;
use base 'Class::Param::Decorator';

sub iterator {
    return $_[0]->[1] ||= [];
}

sub TIEHASH {
    return shift->new(@_);
}

sub FETCH {
    my ( $self, $name ) = @_;
    return $self->decorated->get($name);
}

sub STORE {
    my ( $self, $name, $value ) = @_;
    return $self->decorated->set( $name, $value );
}

sub DELETE {
    my ( $self, $name ) = @_;
    return $self->decorated->remove($name);
}

sub EXISTS {
    my ( $self, $name ) = @_;
    return $self->decorated->has($name);
}

sub SCALAR {
    my ( $self ) = @_;
    return $self->decorated->count;
}

sub FIRSTKEY {
    my ( $self ) = @_;
    @{ $self->iterator } = $self->decorated->names;
    return shift @{ $self->iterator };
}

sub NEXTKEY {
    my ( $self, $last ) = @_;
    return shift @{ $self->iterator };
}

1;

__END__

=head1 NAME

Class::Param::Tie - Provides a tied hash interface

=head1 SYNOPSIS

    $param = Class::Param::Tie->new( $param );

    @names = keys %$param;
    $value = $param->{$name};

    @names = $param->names;
    $value = $param->get($name);

=head1 DESCRIPTION

Provides a tied hash interface.

=head1 METHODS

=over 4

=item new

Constructor. Takes one argument, a instance of L<Class::Param::Base>.

=back

The rest of the API is the same as L<Class::Param>.

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
