package Apache::Session::Store::NoSQL::Redis;

use strict;
use Redis;

our $VERSION = '0.1';

sub new {
    my ( $class, $session ) = @_;
    my $self;

    $self->{cache} = Redis->new( %{ $session->{args} } );

    bless $self, $class;
}

sub insert {
    my ( $self, $session ) = @_;
    $self->{cache}
      ->set( $session->{data}->{_session_id}, $session->{serialized} );
}

*update = *insert;

sub materialize {
    my ( $self, $session ) = @_;
    $session->{serialized} =
      $self->{cache}->get( $session->{data}->{_session_id} )
      or die 'Object does not exist in data store.';
}

sub remove {
    my ( $self, $session ) = @_;
    $self->{cache}->del( $session->{data}->{_session_id} );
}

1;
__END__

=pod

=head1 NAME

Apache::Session::Store::NoSQL::Redis - An implementation of Apache::Session::Store

=head1 SYNOPSIS

 use Apache::Session::Redis;
 
 tie %hash, 'Apache::Session::Redis', $id, {
    # optional: default to localhost
    server => '127.0.0.1:6379',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session::NoSQL. It uses the Redis
storage system

=head1 AUTHOR

This module was written by Xavier Guimard E<lt>x.guimard@free.frE<gt>

=head1 SEE ALSO

L<Apache::Session::NoSQL>, L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Thomas Chemineau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
