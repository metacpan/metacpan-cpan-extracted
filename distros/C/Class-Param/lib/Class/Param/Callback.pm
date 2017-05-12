package Class::Param::Callback;

use strict;
use warnings;
use base 'Class::Param::Base';

use Params::Validate qw[];

BEGIN {

    my @required = qw[ get set names remove ];
    my @optional = qw[ add clear count has param scan as_hash ];
    my $spec     = { };

    foreach my $method ( @required, @optional ) {

        no strict 'refs';

        *$method = sub {
             my $self = shift;
             my $code = $self->{$method} || Class::Param::Base->can($method);
             return $self->$code(@_);
        };
    }

    foreach my $required ( @required ) {

        $spec->{ $required } = {
            type     => Params::Validate::CODEREF,
            optional => 0
        };
    }

    foreach my $optional ( @optional ) {

        $spec->{ $optional } = {
            type     => Params::Validate::CODEREF,
            optional => 1
        };
    }

    *new = sub {
        my $class = ref $_[0] ? ref shift : shift;
        my $self  = Params::Validate::validate_with(
            params  => \@_,
            spec    => $spec,
            called  => "$class\::new"
        );

        return bless( $self, $class );
    };
}

1;

__END__

=head1 NAME

Class::Param::Callback - Param instance with callbacks

=head1 SYNOPSIS

    %store  = ();
    $param = Class::Param::Callback->new(
        get    => sub { return $store{ $_[1] }         },
        set    => sub { return $store{ $_[1] } = $_[2] },
        has    => sub { return exists $store{ $_[1] }  },
        names  => sub { return keys %store             },
        remove => sub { return delete $store{ $_[1] }  }
    );

=head1 DESCRIPTION

Construct a params instance using callbacks.

=head1 METHODS

=over 4

=item new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item get

    get => sub {
        my ( $self, $name ) = @_;
        return $hash{ $name };
    }

Required.

=item set

    set => sub {
        my ( $self, $name, $value ) = @_;
        return $hash{ $name } = $value;
    }

Required.

=item names

    names => sub {
        my ( $self ) = @_;
        return keys %hash;
    }

Required.

=item remove

    remove => sub {
        my ( $self, $name ) = @_;
        return delete $hash{ $name };
    }

Required.

=item clear

    clear => sub {
        my ( $self ) = @_;
        return %hash = ();
    }

Optional.

=item count

    count => sub {
        my ( $self ) = @_;
        return scalar keys %hash;
    }

Optional.

=item has

    has => sub {
        my ( $self, $name ) = @_;
        return exists $hash{ $name };
    }

Optional.

=item param

    param => sub { }

Optional. See L<Class::Param::Base> for expected behavior.

=item add

    add => sub { }

Optional. See L<Class::Param::Base> for expected behavior.

=item scan

    scan => sub { }

Optional. See L<Class::Param::Base> for expected behavior.

=item as_hash

    param => sub { }

Optional. See L<Class::Param::Base> for expected behavior.

=back

=back

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
