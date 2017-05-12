package BBS::Perm::Plugin::IP;

use warnings;
use strict;
use Carp;
use Encode;
use Regexp::Common qw/net/;
use IP::QQWry;
use Gtk2;
use Glib qw/TRUE FALSE/;
use Encode;

my $qqwry = IP::QQWry->new;

sub new {
    my ( $class, %opt ) = @_;
    $qqwry->set_db( $opt{qqwry} ) if $opt{qqwry};
    my $widget = $opt{widget} || Gtk2::Statusbar->new;
    my $id     = $widget->get_context_id('ip');
    my $self   = { ip => {} };
    $self->{widget}    = $widget;
    $self->{_id}       = $id;
    $self->{_encoding} = $opt{encoding} || 'gbk';
    $self->{_length}   = $opt{length} || 80;
    bless $self, ref $class || $class;
}

sub add {
    my ( $self, $input ) = @_;
    $input =~ s/\*/1/g;
    return if defined $self->{ip}{$input};

    my @info;
    if ( @info = $qqwry->query($input) ) {
        $self->{ip}{$input} = [@info];
    }
    else {
        $self->{ip}{$input} = [];
    }
}

sub remove {
    my ( $self, $ip ) = @_;
    delete $self->{ip}{$ip};
}

sub ip {
    my $self = shift;
    return $self->{ip};
}

sub clear {
    shift->{ip} = {};
}

sub show {
    my $self = shift;
    my $show = q{};

    if ( $self->ip ) {
        for ( sort keys %{ $self->ip } ) {
            my $info =
              decode( $self->{_encoding}, join '',
                grep { $_ } @{ $self->ip->{$_} } )
              || q{};
            $show .= $_ . ': ' . $info . "; ";
        }

        my $length = $self->{_length};
        $show = sprintf( "%${length}s", $show );
    }
    $self->widget->pop( $self->_id );
    $self->widget->push( $self->_id, $show );
    return TRUE;
}

sub AUTOLOAD {
    no strict 'refs';
    our $AUTOLOAD;
    if ( $AUTOLOAD =~ /.*::(.*)/ ) {
        my $element = $1;
        *$AUTOLOAD = sub { return shift->{$element} };
        goto &$AUTOLOAD;
    }
}

sub DESTROY { }

1;

__END__

=head1 NAME

BBS::Perm::Plugin::IP - render IP infomation for BBS::Perm

=head1 SYNOPSIS

    use BBS::Perm::Plugin::IP;
    my $ip = BBS::Perm::Plugin::IP->new( qqwry => '/opt/QQWry.Dat' );
    $ip->add('166.111.166.111');
    my $statusbar = $ip->widget;

=head1 DESCRIPTION

BBS::Perm::Plugin::IP is a plugin of BBS::Perm for IP infomation.
It's used to extract IPv4 address and get some information about the IP.
Its widget is a Gtk2::Statusbar object, which is used to show the infomation.

=head1 INTERFACE

=over 4

=item new( encoding => $encoding, widget => $widget, qqwry => $path )

create a new BBS::Perm::Plugin::IP object.

$encoding is your QQWry.Dat's encoding, default is 'gbk';

$widget is a Gtk2::Statusbar object, default is a new one.

$path is your QQWry.Dat's path.

=item ip

get a arrayref referred to a list of IP information in our object.
each element of the list is a arrayref which is [ $ip, $base, $ext ].
see L<IP::QQWry> for the meaning of $base and $ext.

=item add($ip)

add $ip's infomation to our object.

=item remove($ip)

remove $ip's information from our object

=item show

Get a presentation of all the IP information our object has.

=item clear

clear all the IP information in our object.

=item widget

return out object's widget, which is a Gtk2::Statusbar object.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, sunnavy C<< <sunnavy@gmail.com> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

