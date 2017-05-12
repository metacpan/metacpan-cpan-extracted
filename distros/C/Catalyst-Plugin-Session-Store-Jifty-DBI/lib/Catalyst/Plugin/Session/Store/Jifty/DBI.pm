package Catalyst::Plugin::Session::Store::Jifty::DBI;

use strict;
use warnings;
use base qw( Catalyst::Plugin::Session::Store );
use Storable qw( nfreeze thaw );
use MIME::Base64;
use Catalyst::Exception;
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.03';

sub setup_session {
  my $c = shift;

  $c->maybe::next::method(@_);

  unless ( $c->_session_plugin_config->{moniker} ) {
    Catalyst::Exception->throw(
      "Session::Store::Jifty::DBI: 'moniker' is missing"
    );
  }
  $c->_session_plugin_config->{moniker_collection}
    ||= $c->_session_plugin_config->{moniker} . 'Collection';

  my %column = %{ $c->_session_plugin_config->{columns} || {} };
  unless ( $column{id} && $column{session_data} && $column{expires} ) {
    $column{id}           ||= 'session_id';
    $column{session_data} ||= 'session_data';
    $column{expires}      ||= 'expires';
    $c->_session_plugin_config->{columns} = \%column;
  }
}

sub get_session_data {
  my ($c, $key) = @_;

  my $moniker = $c->_session_plugin_config->{moniker};
  my %column  = %{ $c->_session_plugin_config->{columns} };

  my $record = $c->model($moniker);
  if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
    $key = "session:$sid";
    $record->load_by_cols( $column{id} => $key );
    return $record->_value( $column{expires} );
  }
  else {
    $record->load_by_cols( $column{id} => $key );
    my $data = $record->_value( $column{session_data} );
    return ( $c->_session_plugin_config->{use_custom_serialization} )
      ? $data
      : thaw( decode_base64( $data ) );
  }
  return;
}

sub store_session_data {
  my ($c, $key, $data) = @_;

  my $moniker = $c->_session_plugin_config->{moniker};
  my %column  = %{ $c->_session_plugin_config->{columns} };

  my $record = $c->model($moniker);
  if ( my ($sid) = $key =~ /^expires:(.*)/ ) {
    $key = "session:$sid";
    $record->load_by_cols( $column{id} => $key );
    if ( $record->id ) {
      $record->_set(
        column => $column{expires},
        value  => $c->session_expires,
      );
    }
  }
  else {
    unless ( $c->_session_plugin_config->{use_custom_serialization} ) {
      $data = encode_base64( nfreeze( $data ) );
    }

    my $expires = ( $key =~ /^(?:session|flash):/ )
                ? $c->session_expires
                : undef;

    $record->load_by_cols( $column{id} => $key );
    if ( $record->id ) {
      $c->model($moniker)->_handle->begin_transaction;
      eval {
        $record->_set(
          column => $column{session_data},
          value  => $data,
        );
        $record->_set(
          column => $column{expires},
          value  => $expires,
        );
      };
      $@ ? $c->model($moniker)->_handle->rollback
         : $c->model($moniker)->_handle->commit;
    }
    else {
      $record->create(
        $column{id}           => $key,
        $column{session_data} => $data,
        $column{expires}      => $expires,
      );
    }
  }
  return;
}

sub delete_session_data {
  my ($c, $key) = @_;

  return if $key =~ /^expires:/;

  my $moniker = $c->_session_plugin_config->{moniker};
  my %column  = %{ $c->_session_plugin_config->{columns} };

  my $record = $c->model($moniker);
  $record->load_by_cols( $column{id} => $key );
  $record->delete;
}

sub delete_expired_sessions {
  my $c = shift;

  # XXX: this must be much better to do with simple_query

  my $moniker = $c->_session_plugin_config->{moniker_collection};
  my %column  = %{ $c->_session_plugin_config->{columns} };

  my $collection = $c->model($moniker);
  $collection->limit(
    column   => $column{expires},
    value    => undef,
    operator => 'IS NOT',
  );
  $collection->limit(
    column   => $column{expires},
    value    => time(),
    operator => '<',
  );

  while( my $record = $collection->next ) {
    $record->delete;
  }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::Jifty::DBI - Store your session with Jifty::DBI

=head1 SYNOPSIS

  # prepare a table like this.
  # note that we use "session_id" instead of simple "id",
  # as "id" is usually reserved as serial by Jifty::DBI
  # (which is configurable but changing this is not recommended).
  package MyApp::Schema::Session;
  use Jifty::DBI::Schema;
  use Jifty::DBI::Record schema {
    column session_id
      => type is 'char(72)', is mandatory, is distinct, is indexed;
    column session_data => type is 'text';
    column expires      => type is 'integer';
  };

  # and a model
  package MyApp::Model::DB;
  use base qw( Catalyst::Model::Jifty::DBI );
  __PACKAGE__->config->{schema_base} = 'MyApp::Schema';

  # and your app.
  MyApp->config('Plugin::Session' => {
    expires => 3600,
    moniker => 'DB::Session',
  });

  # then in an action
  $c->session->[foo} = 'bar'; # will be saved

=head1 DESCRIPTION

This storage module will store session data in a database using a Jifty::DBI model.

=head1 CONFIGURATION

These parameters are placed in the configuration hash under the C<session> key.

=head2 expires

The C<expires> column in your table will be set with the expiration value. Note that no automatic cleanup is done. You can use C<delete_expired_session> method with L<Catalyst::Plugin::Scheduler>, but most probably you may want to implement your own cleanup script with raw L<Jifty::DBI> (or L<Catalyst::Model::Jifty::DBI>) for speed and stability.

=head2 moniker

specify the moniker to access your session table (to get a session record) via $c->model(). This configuration is mandatory. If you dare, you also can set C<moniker_collection> to specify the moniker to get a collection of session records (but you usually don't need this).

=head2 columns

by default, this module uses the column names shown above, but if you want to change some of these, you can give this a hash reference like this:

  MyApp->config('Plugin::Session' => {
    expires => 3600,
    moniker => 'DB::Session',
    columns => {
      id           => 'sid',
      session_data => 'body',
      expires      => 'until',
    },
  });

=head2 use_custom_serialization

If you want to use L<Jifty::DBI::Filter>s to serialize/deserialize session data, set this to true. This may be handy when you want to use other Jifty::DBI's features like validation.

=head1 METHODS

=head2 get_session_data

=head2 store_session_data

=head2 delete_session_data

=head2 delete_expired_sessions

=head2 setup_session

These are implementations of the required methods for a store. See L<Catalyst::Plugin::Session::Store>.

=head1 SEE ALSO

L<Catalyst::Plugin::Session>,
L<Catalyst::Plugin::Session::Store::DBI>,
L<Catalyst::Plugin::Session::Store::DOD>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
