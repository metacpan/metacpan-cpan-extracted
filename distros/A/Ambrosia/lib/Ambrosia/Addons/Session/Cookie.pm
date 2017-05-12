package Ambrosia::Addons::Session::Cookie;
use strict;
use warnings;
use Carp;

use CGI::Cookie;

use Ambrosia::Utils::Container;
use Ambrosia::core::Object;

use Ambrosia::Meta;

class sealed
{
    public  => [qw/expires path/],
    private => [qw/__cookie/]
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init( @_ );
    my @cookie = fetch CGI::Cookie;
    $self->__cookie = scalar @cookie && @cookie % 2 == 0 ? {@cookie} : {};
    $self->path ||= '/';
}

sub getSessionName
{
    return 'cookie';
}

sub getSessionValue
{
    my $self = shift;
    return [ values %{$self->__cookie} ];
}

sub addItem
{
    my $self = shift;
    my $key = shift;
    my $value = shift;

    $self->__cookie->{$key} = new CGI::Cookie(
                            -name    => $key,
                            -value   => (ref $value ? new Ambrosia::Utils::Container(__data => {$key => $value})->dump : $value),
                            -expires => $self->expires,
                            -path    => $self->path
                        );
}

sub getItem
{
    my $self = shift;
    my $name = shift;

    if ( ref $self->__cookie->{$name} )
    {
        my $v = $self->__cookie->{$name}->value;
        if ( $v )
        {
            my $val = undef;
            eval
            {
                if ( my $c = Ambrosia::core::Object::string_restore($v) )
                {
                    $val = $c->get($name);
                }
            };
            if ( $@ )
            {
                carp('cookieValue: ', $@);
            }
            return $val;
        }
        else
        {
            return $v;
        }
    }
    return undef;
}

sub deleteItem
{
    delete $_[0]->__cookie->{$_[1]};
}

sub hasData
{
    return scalar keys %{$_[0]->__cookie};
}

1;

__END__

=head1 NAME

Ambrosia::Addons::Session::Cookie - 

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::Addons::Session::Cookie;

=head1 DESCRIPTION

C<Ambrosia::Addons::Session::Cookie> .

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
