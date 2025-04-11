package Apache::Session::Browseable::Redis;

use strict;

use Apache::Session;
use Apache::Session::Browseable::Store::Redis;
use Apache::Session::Generate::SHA256;
use Apache::Session::Lock::Null;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::_common;

our $VERSION = '1.3.15';
our @ISA     = qw(Apache::Session);

our $redis = $Apache::Session::Browseable::Store::Redis::redis;

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Browseable::Store::Redis $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

sub unserialize {
    my $session = shift;
    my $tmp     = { serialized => $session };
    Apache::Session::Serialize::JSON::unserialize($tmp);
    return $tmp->{data};
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;

    my %res = ();
    if ( $class->isIndexed( $args, $selectField ) ) {

        my $redisObj = $class->_getRedis($args);
        my @keys     = $redisObj->smembers("${selectField}_$value");
        foreach my $k (@keys) {
            next unless ($k);
            my $tmp = $redisObj->get($k);
            next unless ($tmp);
            eval {
                $tmp = unserialize($tmp);
                if (@fields) {
                    $res{$k}->{$_} = $tmp->{$_} foreach (@fields);
                }
                else {
                    $res{$k} = $tmp;
                }
            };
            if ($@) {
                print STDERR "Error in session $k: $@\n";
                delete $res{$k};
            }
        }
    }
    else {
        $class->get_key_from_all_sessions(
            $args,
            sub {
                my $entry = shift;
                my $id    = shift;
                return undef
                  unless ( defined $entry->{$selectField}
                    and $entry->{$selectField} eq $value );
                if (@fields) {
                    $res{$id}->{$_} = $entry->{$_} foreach (@fields);
                }
                else {
                    $res{$id} = $entry;
                }
                undef;
            }
        );
    }
    return \%res;
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    my %res;
    if ( $class->isIndexed( $args, $selectField ) ) {
        my $redisObj = $class->_getRedis($args);
        my $cursor   = 0;
        do {
            my ( $new_cursor, $sets ) =
              $redisObj->scan( $cursor, MATCH => "${selectField}_$value" );
            foreach my $set (@$sets) {
                next unless $redisObj->type($set) eq 'set';
                my @keys = $redisObj->smembers($set);
                foreach my $k (@keys) {
                    my $v = $redisObj->get($k);
                    next unless $v;
                    my $tmp = unserialize($v);
                    if ($tmp) {
                        $res{$k} = $class->extractFields( $tmp, @fields );
                    }
                }
            }
            $cursor = $new_cursor;
        } while ( $cursor != 0 );
    }
    else {
        $value = quotemeta($value);
        $value =~ s/\\\*/\.\*/g;
        $value = qr/^$value$/;
        $class->get_key_from_all_sessions(
            $args,
            sub {
                my ( $entry, $id ) = @_;
                return undef unless ( $entry->{$selectField} =~ $value );
                $res{$id} = $class->extractFields( $entry, @fields );
                undef;
            }
        );
    }
    return \%res;
}

sub deleteIfLowerThan {
    my ( $class, $args, $rule ) = @_;
    my @toDelete;
    my %seen;
    if ( $rule->{or} ) {
        foreach ( keys %{ $rule->{or} } ) {
            push @toDelete,
              grep { !$seen{$_}++ }
              $class->filterIfLowerThan( $args, $_, $rule->{or}->{$_} );
        }
    }
    elsif ( $rule->{and} ) {
        foreach ( keys %{ $rule->{and} } ) {
            @toDelete =
              grep { !$seen{$_}++ }
              $class->filterIfLowerThan( $args, $_, $rule->{and}->{$_},
                @toDelete );
        }
    }
    if (@toDelete) {
        my $redisObj = $class->_getRedis($args);
        if ( $rule->{not} ) {
            foreach ( keys %{ $rule->{not} } ) {
                my $keep = $class->searchOn( $args, $_, $rule->{not}->{$_} );
                foreach my $k ( keys %$keep ) {
                    @toDelete = grep { $_ ne $k } @toDelete;
                }
            }
        }
        $redisObj->del($_) foreach (@toDelete);
    }
}

sub filterIfLowerThan {
    my ( $class, $args, $field, $value, @keys ) = @_;
    my @res;
    my $redisObj = $class->_getRedis($args);
    if ( $class->isIndexed( $args, $field ) ) {
        my $cursor = 0;
        do {
            my ( $new_cursor, $sets ) =
              $redisObj->scan( $cursor, MATCH => "${field}_*" );
            foreach my $set (@$sets) {
                next unless $redisObj->type($set) eq 'set';
                my $v = $set;
                $v =~ s/^\Q$field\E_//;
                next if int($v) >= $value;
                my @nk = $redisObj->smembers($set);
                if (@keys) {
                    push @res, map {
                        my $t = $_;
                        grep { $_ eq $t } @keys ? $t : ()
                    } @nk;
                }
                else {
                    push @res, @nk;
                }
            }
            $cursor = $new_cursor;
        } while ( $cursor != 0 );
    }
    else {
        unless (@keys) {
            $class->get_key_from_all_sessions(
                $args,
                sub {
                    my ( $v, $k ) = @_;
                    push @res, $k
                      if defined( $v->{$field} )
                      and $v->{$field} < $value;
                    undef;
                }
            );
        }
        foreach my $k (@keys) {
            eval {
                my $v = $redisObj->get($k);
                next unless $v;
                $v = unserialize($v);
                push @res, $k
                  if defined( $v->{$field} )
                  and $v->{$field} < $value;
            };
        }
    }
    return @res;
}

sub extractFields {
    my ( $class, $entry, @fields ) = @_;
    my $res;
    if (@fields) {
        $res->{$_} = $entry->{$_} foreach (@fields);
    }
    else {
        $res = $entry;
    }
    return $res;
}

sub isIndexed {
    my ( $class, $args, $field ) = @_;
    my $indexes =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    return grep { $_ eq $field } @$indexes;
}

sub isLlngKey {
    my ( $class, $args, $name ) = @_;
    my $expr = $args->{keysRe} || '^[0-9a-f]{32,}$';
    return ( $name =~ /$expr/o );
}

sub get_key_from_all_sessions {
    my ( $class, $args, $data ) = @_;
    my %res;

    my $redisObj = $class->_getRedis($args);
    my $cursor   = 0;
    do {
        my ( $new_cursor, $keys ) = $redisObj->scan($cursor);
        foreach my $k (@$keys) {

            # Keep only our keys
            next unless $class->isLlngKey( $args, $k );

            # Don't scan sets,...
            next unless $redisObj->type($k) eq 'string';
            eval {
                my $v = $redisObj->get($k);
                next unless $v;
                my $tmp = unserialize($v);
                if ( ref($data) eq 'CODE' ) {
                    $tmp = &$data( $tmp, $k );
                    $res{$k} = $tmp if ( defined($tmp) );
                }
                elsif ($data) {
                    $data = [$data] unless ( ref($data) );
                    $res{$k}->{$_} = $tmp->{$_} foreach (@$data);
                }
                else {
                    $res{$k} = $tmp;
                }
            };
            if ($@) {
                print STDERR "Error in session $k: $@\n";

                # Don't delete, it may own to another app
                #delete $res{$k};
            }
        }
        $cursor = $new_cursor;
    } while ( $cursor != 0 );
    return \%res;
}

sub _getRedis {
    my $class = shift;
    my $args  = shift;

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

    my $redisObj = $redis->new( %{$args} );

    # Manage database
    $redisObj->select( $args->{database} )
      if defined $args->{database};
    return $redisObj;
}

1;
__END__

=head1 NAME

Apache::Session::Browseable::Redis - Add index and search methods to
Apache::Session::Redis

=head1 SYNOPSIS

  use Apache::Session::Browseable::Redis;

  my $args = {
       server => '127.0.0.1:6379',

       # Select database (optional)
       #database => 0,

       # Choose your browseable fields
       Index          => 'uid mail',
  };
  
  # Use it like Apache::Session
  my %session;
  tie %session, 'Apache::Session::Browseable::Redis', $id, $args;
  $session{uid} = 'me';
  $session{mail} = 'me@me.com';
  $session{unindexedField} = 'zz';
  untie %session;
  
  # Apache::Session::Browseable add some global class methods
  #
  # 1) search on a field (indexed or not)
  my $hash = Apache::Session::Browseable::Redis->searchOn( $args, 'uid', 'me' );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{mail} . "\n";
  }

  # 2) Parse all sessions
  # a. get all sessions
  my $hash = Apache::Session::Browseable::Redis->get_key_from_all_sessions($args);

  # b. get some fields from all sessions
  my $hash = Apache::Session::Browseable::Redis->get_key_from_all_sessions($args, 'uid', 'mail')

  # c. execute something with datas from each session :
  #    Example : get uid and mail if mail domain is
  my $hash = Apache::Session::Browseable::Redis->get_key_from_all_sessions(
              $args,
              sub {
                 my ( $session, $id ) = @_;
                 if ( $session->{mail} =~ /mydomain.com$/ ) {
                     return { $session->{uid}, $session->{mail} };
                 }
              }
  );
  foreach my $id (keys %$hash) {
    print $id . ":" . $hash->{$id}->{uid} . "=>" . $hash->{$id}->{mail} . "\n";
  }

=head1 DESCRIPTION

Apache::Session::browseable provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

This module use either L<Redis::Fast> or L<Redis>.

=head1 SEE ALSO

L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
