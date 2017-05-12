package Class::Param;

use strict;
use warnings;
use base 'Class::Param::Base';

our $VERSION = 0.1;

use Params::Validate qw[];

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my ( $hash ) = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            {
                type      => Params::Validate::HASHREF,
                default   => {},
                optional  => 1
            }
        ],
        called  => "$class\::new"
    );

    return bless( \$hash, $class );
}

sub get {
    my ( $self, $name ) = @_;
    return $$self->{$name};
}

sub set {
    my ( $self, $name, $value ) = @_;
    $$self->{$name} = $value;
    return 1;
}

sub has {
    my ( $self, $name ) = @_;
    return exists $$self->{$name};
}

sub count {
    my $self = shift;
    return scalar keys %{ $$self };
}

sub clear {
    my $self = shift;
    %{ $$self } = ();
    return 1;
}

sub remove {
    my ( $self, $name ) = @_;
    return delete $$self->{$name};
}

sub names {
    my $self = shift;
    return keys %{ $$self };
}

1;

__END__

=head1 NAME

Class::Param - Param Class

=head1 SYNOPSIS

    use Class::Param;
    use Class::Param::Encoding;
    use Class::Param::Tie;

    $param = Class::Param->new( { smiley => "\xE2\x98\xBA" } );
    $param = Class::Param::Encoding->new( $param, 'UTF-8' );

    if ( $param->get('smiley') eq "\x{263A}" ) {
        # true
    }

    $param = Class::Param::Tie->new($param);

    if ( $param->{smiley} eq "\x{263A}" ) {
        # true
    }

    # ..

    package MyClass;

    sub param {
        my $self  = shift;
        my $param = $self->{param} ||= Class::Param->new;

        if ( @_ == 0 && ! wantarray ) {
            return $param;
        }
        else {
            return $param->param(@_);
        }
    }

    # Somewhere else

    $object = MyClass->new;

    @names  = $object->param;
    @names  = $object->param->names;
    $value  = $object->param('name');
    $value  = $object->param->get('name');

=head1 DESCRIPTION

Provides several classes to work with CGI.pm style params.

=head1 METHODS

=over 4

=item new

    $param = Class::Param->new;
    $param = Class::Param->new( \%params );

=item param

    # get
    @names   = $param->param;
    $value   = $param->param($name);
    @values  = $param->param($name);

    # set
    $param->param( $name => $value   );
    $param->param( $name => @values  );

    # remove
    $param->param( $name => undef    );

=item get

    $value = $param->get($name);

=item set

    $param->set( $name => $value );

=item add

    $param->add( $name => $value  );
    $param->add( $name => @values );

Append value to name.

=item has

    $boolean = $param->has($name);

Returns true if param has name.

=item count

    $count = $param->count;

Returns the number of total params.

=item names

    @names = $param->names;

Returns a list of all names in param.

=item clear

    $param->clear;

Clears all params.

=item remove

    $removed = $param->remove($name);

Remove name from param. Returns the removed value.

=item scan

    $param->scan( sub {
        my ( $name, @values ) = @_;
    });

Applies a callback which will be called for each param.

=item as_hash

    %hash = $param->as_hash;
    $hash = $param->as_hash;

Returns params as a hash.

=back

=head1 SEE ASLO

L<Class::Param::Base>.

L<Class::Param::Callback>.

L<Class::Param::Compound>.

L<Class::Param::Decorator>.

L<Class::Param::Encoding>.

L<Class::Param::Ordered>.

L<Class::Param::Tie>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
