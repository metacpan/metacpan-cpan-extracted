package Apache::Session::Browseable::Store::Redis;

use strict;

our $VERSION = '1.3.18';

our $redis;
our %reused_connections;

BEGIN {
    $redis = 'Redis::Fast';
    eval 'use Redis::Fast';
    if ($@) {
        require Redis;
        $redis = 'Redis';
    }
}

sub new {
    my ( $class, $session ) = @_;
    my $self;

    $self->{cache} = $class->_getRedis( $session->{args} );

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
        my $t = $session->{data}->{$i};
        next unless ( defined($t) and ( length($t) > 0 ) );
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

sub _getRedis {
    my $class = shift;
    my $args  = shift;
    my $redisObj;

    # Manage undef encoding
    $args->{encoding} = undef
      if (  $args->{encoding}
        and $args->{encoding} eq "undef" );

    # If sentinels is not given as an array ref, try to parse
    # a comma delimited list instead
    if ( $args->{sentinels}
        and ref $args->{sentinels} ne 'ARRAY' )
    {
        $args->{sentinels} =
          [ split /[,\s]+/, $args->{sentinels} ];
    }

    if (    $args->{reuse}
        and $reused_connections{ $args->{reuse} } )
    {
        $redisObj = $reused_connections{ $args->{reuse} };
    }
    else {
        $redisObj = $redis->new( %{$args} );
        if ( $args->{reuse} ) {
            $reused_connections{ $args->{reuse} } = $redisObj;
        }
    }

    # Manage database
    $redisObj->select( $args->{database} )
      if defined $args->{database};
    return $redisObj;
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

=head1 SEE ALSO

L<Apache::Session::Browseable>, L<Apache::Session::NoSQL>, L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
