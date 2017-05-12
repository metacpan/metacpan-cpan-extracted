package Apache::Session::Browseable::Store::Redis;

use strict;
use Redis;

our $VERSION = '1.2.2';

sub new {
    my ( $class, $session ) = @_;
    my $self;

    # Manage undef encoding
    $session->{args}->{encoding} = undef
      if (  $session->{args}->{encoding}
        and $session->{args}->{encoding} eq "undef" );

    $self->{cache} = Redis->new( %{ $session->{args} } );

    # Manage database
    $self->{cache}->select( $session->{args}->{database} )
      if defined $session->{args}->{database};

    bless $self, $class;
}

sub insert {
    my ( $self, $session ) = @_;
    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    my $id = $session->{data}->{_session_id};
    $self->{cache}->set( $id, $session->{serialized} );
    foreach my $i (@$index) {
        my $t;
        next unless ( $t = $session->{data}->{$i} );
        $self->{cache}->sadd( "${i}_$t", $id );
    }
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
    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];

    my $id = $session->{data}->{_session_id};
    foreach my $i (@$index) {
        my $t;
        next unless ( $t = $session->{data}->{$i} );
        eval { $self->{cache}->srem( "${i}_$t", $id ); };
    }
    $self->{cache}->del($id);
}

1;
__END__

=pod

=head1 NAME

Apache::Session::Browseable::Store::Redis - An implementation of
Apache::Session::Store

=head1 SYNOPSIS

 use Apache::Session::Browseable::Redis;
 
 tie %hash, 'Apache::Session::Browseable::Redis', $id, {
    # optional: default to localhost
    server => '127.0.0.1:6379',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session::Browseable. It uses the
Redis storage system

=head1 AUTHOR

This module was written by Xavier Guimard <x.guimard@free.fr>

=head1 SEE ALSO

L<Apache::Session::Browseable>, L<Apache::Session::NoSQL>, L<Apache::Session>

