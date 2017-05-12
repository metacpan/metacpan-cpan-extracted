package Ambrosia::Utils::Container;
use strict;
use warnings;

use Data::Dumper;

use Ambrosia::Meta;
class
{
    private => [qw/__data/]
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->__data ||= {};
}

sub TIEHASH { $_[1]; }
sub STORE    { }
sub FETCH    { $_[0]->__data->{$_[1]} }
sub FIRSTKEY { each %{$_[0]->__data}; }
sub NEXTKEY  { each %{$_[0]->__data} }
sub EXISTS   { exists $_[0]->__data->{$_[1]} }
sub DELETE   { } #delete $_[0]->__data->{$_[1]} }
sub CLEAR    { } #$_[0]->__data = {} }
sub SCALAR   { scalar %{$_[0]->__data} }
sub DESTROY  { untie $_[0]; }

sub put
{
    my $self = shift;

    my @keys = ();
    while( @_ && (my $key = shift) )
    {
        push @keys, $key;
        my $value = shift;
        next if CORE::exists $self->__data->{$key} && defined $self->__data->{$key};
        $self->__data->{$key} = $value;
    }

    return wantarray ? (map { $_ => $self->__data->{$_} } @keys) : join ',', @{$self->__data}{@keys};
}

sub set
{
    my $self = shift;

    my @keys = ();
    while( @_ && (my $key = shift) )
    {
        push @keys, $key;
        my $value = shift;
        $self->__data->{$key} = $value;
    }

    return wantarray
        ? (map { $_ => $self->__data->{$_} } @keys)
        : join ',', grep defined $_, @{$self->__data}{@keys};
}

sub get
{
    return $_[0]->__data->{$_[1]};
}

sub exists
{
    return CORE::exists $_[0]->__data->{$_[1]};
}

sub dump
{
    return $_[0]->string_dump;
}

sub remove
{
    my $self = shift;
    return CORE::delete $self->__data->{$_[0]} if $_[0];
    return undef;
}

sub delete
{
    my $self = shift;
    if ( my $key = shift )
    {
        $self->__data->{$key} = undef;
        CORE::delete $self->__data->{$key}
    }
}

sub clear
{
    $_[0]->__data = {};
}

sub size
{
    scalar keys %{$_[0]->__data};
}

sub list
{
    return keys %{$_[0]->__data};
}

sub clone
{
    my $self = shift;

    if ( @_ )
    {#deep clone
        return $self->clone(1);
    }
    else
    {
        my $obj = $self->new;
        $obj->__data = { map { $_ => $self->__data->{$_} } keys %{$self->__data} };
        return $obj;
    }
}

sub as_hash
{
    my $self = shift;

    if ( @_ )
    {
        return $self->SUPER::as_hash(1)->{__data};
    }
    return { map { $_ => $self->__data->{$_} } keys %{$self->__data} };
}

sub info
{
    my $self = shift;
    return join "\n", map { my $d = $self->__data->{$_}; $_ . '=' . ( ref $d || $d ) } keys %{$self->__data};
}

sub info_dump
{
    my $self = shift;
    return join "\n", map { my $d = $self->__data->{$_}; $_ . '=' . ( ref $d ? Dumper($d) : $d ) } keys %{$self->__data};
}

1;

package deferred;

use Ambrosia::error::Exceptions;

use overload
    '%{}' => \&as_hash,
    '@{}' => \&__as_array,
    '${}' => \&__as_scalar,
    '&{}' => \&__as_func,
    '*{}' => \&__as_glob,
    '==' => \&__as_bool,
    'bool'=> \&__as_bool,
    '""'  => \&__as_string,
    '0+'  => \&__as_number,
    'fallback' => 1
    ;

sub call(&)
{
    return bless {code => $_[0]}, 'deferred';
}

sub as_hash
{
    return $_[0] if caller eq __PACKAGE__;
    local $@;
    unless ( exists $_[0]->{value} )
    {
        my $h = $_[0]->{code}->();
        if ( ref $h eq 'HASH' )
        {
            $_[0]->{value} = $h;
        }
        elsif( ref $h && eval{$h->can('as_hash')})
        {
            $_[0]->{value} = $h->as_hash();
        }
    }
    elsif ( eval{$_[0]->{value}->can('as_hash')} )
    {
        $_[0]->{value} = $_[0]->{value}->as_hash();
    }
    return $_[0]->{value};
}

sub __as_any
{
    unless ( exists $_[0]->{value} )
    {
        $_[0]->{value} = $_[0]->{code}->();
    }
    return $_[0]->{value};
}

sub __as_array
{
    goto &__as_any;
}

sub __as_scalar
{
    goto &__as_any;
    #unless ( exists $_[0]->{scalar} )
    #{
    #    $_[0]->{scalar} = '' . $_[0]->{code}->();
    #}
    #return $_[0]->{scalar};
}

sub __as_func
{
    goto &__as_any;
}

sub __as_glob
{
    goto &__as_any;
}

sub __as_bool
{
    goto &__as_any;
    #unless ( exists $_[0]->{bool} )
    #{
    #    $_[0]->{bool} = '' . $_[0]->{code}->();
    #}
    #return $_[0]->{bool};
}

sub __as_string
{
#warn join ' ', grep $_, caller(0);
#warn join ' ', grep $_, caller(1);
#warn join ' ', grep $_, caller(2);
#warn join ' ', grep $_, caller(3);
#warn join ' ', grep $_, caller(4);
#warn join ' ', grep $_, caller(5);

    goto &__as_any;
    #unless ( exists $_[0]->{string} )
    #{
    #    $_[0]->{string} = '' . $_[0]->{code}->();
    #}
    #return $_[0]->{string};
}

sub __as_number
{
    goto &__as_any;
}

sub ref
{
    my $self = shift;
    return CORE::ref $self->__as_any();
}

sub AUTOLOAD
{
    my $self = shift;
    my @param = @_;

    my $type = CORE::ref($self) or return;
    my ($func) = our $AUTOLOAD =~ /(\w+)$/
        or throw Ambrosia::error::Exception 'Error: cannot resolve AUTOLOAD: ' . $AUTOLOAD;
warn "AUTOLOAD: $func\n";
    my $p = $self->__as_any;

    if( CORE::ref($p) && eval {$p->can($func)} )
    {
        return $p->$func(@param );
    }
    else
    {
        throw Ambrosia::error::Exception 'Error: cannot resolve: ' . $AUTOLOAD;
    }
}

sub DESTROY
{
    #warn "DESTROY: @_\n";
}

1;
#so you can get acquainted with this code

__END__

=head1 NAME

Ambrosia::Utils::Container - storage container for named data.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Utils::Container> is storage container for named data.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
