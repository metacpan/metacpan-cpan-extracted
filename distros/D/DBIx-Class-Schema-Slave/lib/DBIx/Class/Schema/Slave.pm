package DBIx::Class::Schema::Slave;

use strict;
use warnings;
use base qw/ DBIx::Class /;
use Clone qw//;

our $VERSION = '0.02400';

__PACKAGE__->mk_classdata( slave_moniker => '::Slave' );
__PACKAGE__->mk_classdata('slave_schema');
__PACKAGE__->mk_classdata('slave_connect_info' => [] );

## TODO remove next major release
sub slave_connection {
    my $self = shift;
    warn "DBIx::Class::Schema::Slave::slave_connection is changed to " .
        "DBIx::Clas::Schema::Slave::slave_schema. " .
        "This message will be removed next major release.";
    return $self->slave_schema;
}

## TODO remove next major release
sub connect_slave {
    my $self = shift;
    warn "DBIx::Class::Schema::Slave::connect_slave was changed to " .
        "DBIx::Class::Schema::Slave::slave_connect. " .
        "This message will be removed next major release.";
    return $self->slave_connect( @_ );
}

=head1 NAME

DBIx::Class::Schema::Slave - L<DBIx::Class::Schema> for slave B<(EXPERIMENTAL)>

=head1 CAUTION

DIBx::Class::Schema::Slave is B<EXPERIMENTAL> and B<DO NOT> use.
Please check L<DBIx::Class::Storage::DBI::Replicated> or L<DBIx::Class::Storage::DBI::Replication>.
DBIx::Class::Schema::Slave will be deleted.

=head1 SYNOPSIS

  # In your MyApp::Schema (DBIx::Class::Schema based)
  package MyApp::Schema;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->load_components( qw/ Schema::Slave / );
  __PACKAGE__->slave_moniker('::Slave');
  __PACKAGE__->slave_connect_info( [
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      ...,
  ] );

  # As it is now, DBIx::Class::Schema::Slave works out with DBIx::Class::Schema::Loader.
  # If you use DBIx::Class::Schema::Loader based MyApp::Schema, maybe it is just like below.

  # In your MyApp::Schema (DBIx::Class::Schema::Loader based)
  package MyApp::Schema;

  use base 'DBIx::Class::Schema::Loader';

  __PACKAGE__->load_components( qw/ Schema::Slave / );
  __PACKAGE__->slave_moniker('::Slave');
  __PACKAGE__->slave_connect_info( [
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      ...,
  ] );
  __PACKAGE__->loader_options(
      relationships => 1,
      components    => [ qw/
          ...
          ...
          ...
          Row::Slave # DO NOT forget to specify
          Core
      / ],
  );

  # Somewhere in your code
  use MyApp::Schema;

  # First, connect to master
  my $schema = MyApp::Schema->connect( @master_connect_info );

  # Retrieving from master
  my $master = $schema->resultset('Track')->find( $id );

  # Retrieving from slave
  my $slave = $schema->resultset('Track::Slave')->find( $id );

See L<DBIx::Class::Schema>.

=head1 DESCRIPTION

DBIx::Class::Schema::Slave is L<DBIx::Class::Schema> for slave.
DBIx::Class::Schema::Slave creates C<result_source> classes for slave automatically,
and connects slave datasources as you like (or at rondom).
You can retrieve rows from either master or slave in the same way L<DBIx::Class::Schema> provies
but you can neither add nor remove rows from slave.

=head1 SETTIN UP DBIx::Class::Schema::Slave

=head2 Setting it up manually

First, load DBIx::Class::Schema::Slave as component in your MyApp::Schema.

  # In your MyApp::Schema
  package MyApp::Schema;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->load_components( qw/ Schema::Slave / );

Set L</slave_moniker> as you like. If you do not specify, C<::Slave> is set.

  __PACKAGE__->slave_moniker('::Slave');

Set L</slave_connect_info> as C<ARRAYREF> of C<ARRAYREF>.

  __PACKAGE__->slave_connect_info( [
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      ...,
  ] );

Next, you have MyApp::Schema::Artist, MyApp::Schema::Album, MyApp::Schema::Track, load these C<result_source> classes.

  __PACKAGE__->load_classes( qw/ Artist Album Track / );

In running L</register_source>, DBIx::Class::Schema::Slave creates slave C<result_source> classes
MyApp::Schema::Artist::Slave, MyApp::Schema::Album::Slave and MyApp::Schema::Track::Slave automatically.
If you set C<::MySlave> to L</slave_moniker>, it creates
MyApp::Schema::Artist::MySlave, MyApp::Schema::Album::MySlave and MyApp::Schema::Track::MySlave.

  # MyApp::Schema::Artist wouldn't be loaded
  # MyApp::Schema::Artist::Slave wouldn't be created
  __PACKAGE__->load_classes( qw/ Album Track / );

I recommend every C<result_source> classes to be loaded.

  # Every result_source classes are loaded
  __PACKAGE__->load_classes;

Next, load L<DBIx::Class::Row::Slave> as component in your C<result_source> classes.

  # In your MyApp::Schema::Artist;
  package MyApp::Schema::Artist;

  use base 'DBIx::Class';

  __PACKEAGE__->load_components( qw/ ... Row::Slave Core / );

=head2 Using L<DBIx::Class::Schema::Loader>

As it is now, DBIx::Class::Schema::Slave B<WORKS OUT> with L<DBIx::Class::Schema::Loader>.
First, load DBIx::Class::Schema::Slave as component in your MyApp::Schema.

  # In your MyApp::Schema
  package MyApp::Schema;

  use base 'DBIx::Class::Schema::Loader';

  __PACKAGE__->load_components( qw/ Schema::Slave / );

Set L</slave_moniker> as you like. If you do not specify, C<::Slave> is set.

  __PACKAGE__->slave_moniker('::Slave');

Set L</slave_connect_info> as C<ARRAYREF> of C<ARRAYREF>.

  __PACKAGE__->slave_connect_info( [
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'user', 'passsword', { ... } ],
      ...,
  ] );

Call L<DBIx::Class::Schema::Loader/loader_options>. B<DO NOT> forget to specify L<DBIx::Class::Row::Slave> as component.

  __PACKAGE__->loader_options(
      relationships => 1,
      components    => [ qw/
          ...
          Row::Slave # DO NOT forget to load
          Core
      / ],
  );

=head2 Connecting (Create Schema instance)

To connect your Schema, provive C<connect_info> not for slave but for master.

  my $schema = MyApp::Schema->connect( @master_connect_info );

=head2 Retrieving

Retrieving from master, you don't have to care about anything.

  my $album_master     = $schema->resultset('Album')->find( $id );
  my $itr_album_master = $schema->resultset('Album')->search( { ... }, { ... } );

Retrieving from slave, set slave moniker to L</resultset>.

  my $track_slave     = $schema->resultset('Album::Slave')->find( $id );
  my $itr_track_slave = $schema->resultset('Album::Slave')->search( { ... }, { ... } );

=head2 Adding and removing rows

You can either create a new row or remove some rows from master. But you can neither create a new row nor remove some rows from slave.

  # These complete normally
  my $track = $schema->resultset('Track')->create( {
      created_on  => $dt->now || undef,
      modified_on => $dt->now || undef,
      album_id    => $album->id || undef,
      title       => $title || undef,
      time        => $time || undef,
  } );
  $track->title('WORLD\'S END SUPERNOVA');
  $track->update;
  $track->delete;

  # You got an error!
  # DBIx::Class::ResultSet::create(): Can't insert via result source "Track::Slave". This is slave connection.
  my $track = $schema->resultset('Track::Slave')->create( {
      created_on  => $dt->now || undef,
      modified_on => $dt->now || undef,
      album_id    => $album->id || undef,
      title       => $title || undef,
      time        => $time || undef,
  } );

  $track->title('TEAM ROCK');
  # You got an error!
  # DBIx::Class::Row::Slave::update(): Can't update via result source "Track::Slave". This is slave connection.
  $track->update;

  # And, you got an error!
  # DBIx::Class::Row::Slave::delete(): Can't delete via result source "Track::Slave". This is slave connection.
  $track->delete;

B<DO NOT> call L<DBIx::Class::ResultSet/"update_all">, L<DBIx::Class::ResultSet/"delete_all">, L<DBIx::Class::ResultSet/"populate"> and L<DBIx::Class::ResultSet/"update_or_create"> via slave C<result_source>s.
Also you B<SHOULD NOT> call L<DBIx::Class::ResultSet/"find_or_new">, L<DBIx::Class::ResultSet/"find_or_create"> via slave C<result_source>s.

=head1 CLASS DATA

=head2 slave_moniker

Moniker suffix for slave. C<::Slave> default.

  # In your MyApp::Schema
  __PACKAGE__->slave_moniker('::Slave');

B<IMPORTANT:>
If you have already MyApp::Schema::Artist::Slave, B<DO NOT> set C<::Slave> to C<slave_moniker>.
Set C<::SlaveFor> or something else.

=head2 slave_connect_info

C<connect_info>s C<ARRAYREF> of C<ARRAYREF> for slave.

  # In your MyApp::Schema
  __PACKAGE__->slave_connect_info( [
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      [ 'dbi:mysql:database:hostname=host', 'username', 'passsword', { ... } ],
      ...,
  ] );

=head2 slave_schema

Schema for slave. You can get this by L</slave>.

=head1 METHODS

=head2 register_source

=over 4

=item Arguments: $moniker, $result_source

=item Return Value: none

=back

Registers the L<DBIx::Class::ResultSource> in the schema with the given moniker
and re-maps C<class_mappings> and C<source_registrations>.

  # Re-mapped class_mappings
  class_mappings => {
      MyApp::Schema::Artist        => 'Artist',
      MyApp::Schema::Artist::Slave => 'Artist::Slave',
      MyApp::Schema::Album         => 'Album',
      MyApp::Schema::Album::Slave  => 'Album::Slave',
      MyApp::Schema::Track         => 'Track',
      MyApp::Schema::Track::Slave  => 'Track::Slave',
  }

  # Re-mapped source_registrations
  source_registrations => {
      MyApp::Schema::Artist => {
          bless( {
              ...,
              ...,
              ...,
          }, DBIx::Class::ResultSource::Table )
      },
      MyApp::Schema::Artist::Slave => {
          bless( {
              ...,
              ...,
              ...,
          }, DBIx::Class::ResultSource::Table )
      },
      ...,
      ...,
      ...,
      MyApp::Schema::Track::Slave => {
          bless( {
              ...,
              ...,
              ...,
          }, DBIx::Class::ResultSource::Table )
      },
  }

See L<DBIx::Class::Schema/"register_source">.

=cut

sub register_source {
    my ( $self, $moniker, $source ) = @_;

    unless ( $self->is_slave( $moniker ) ) {
        my $s_moniker = $moniker . $self->slave_moniker;
        my $s_source  = $source->new( $self->_clone_source( $source ) );
        $self->next::method( $s_moniker, $s_source );
    }

    $self->next::method( $moniker, $source );
}

sub _clone_source {
    my ( $self, $source ) = @_;

    my $s_moniker = $self->slave_moniker;
    my $c_source  = Clone::clone( $source );
    $self->_slave_relationships( $c_source );

    if ( ref $self ) {
        no strict 'refs';
        no warnings 'redefine';
        local *Class::C3::reinitialize = sub {};
        my $s_result_class = $c_source->result_class . $s_moniker;
        ## Set VERSION to create pseudo namespace.
        local ${"${s_result_class}::VERSION"} ||= 1;
        $self->inject_base( $s_result_class => $source->result_class );
        $c_source->result_class( $s_result_class );
    }

    return $c_source;
}

sub _slave_relationships {
    my ( $self, $source ) = @_;

    my $s_moniker = $self->slave_moniker;
    my %rels = %{$source->_relationships};
    return unless %rels;

    foreach my $rel ( keys %rels ) {
        $rels{$rel}->{source} = $rels{$rel}->{source} . $s_moniker
            unless $self->is_slave( $rels{$rel}->{source} );
        $rels{$rel}->{class} = $rels{$rel}->{class} . $s_moniker
            unless $self->is_slave( $rels{$rel}->{class} );
    }

    $source->_relationships( \%rels );
}

=head2 resultset

=over 4

=item Arguments: $moniker

=item Return Value: $result_set

=back

If C<$moniker> is slave moniker, this method returns C<$result_set> for slave.
See L<DBIx::Class::Schema/"resultset">.

  my $master_rs = $schema->resultset('Artist');
  my $slave_rs  = $schema->resultset('Artist::Slave');

=cut

sub resultset {
    my ( $self, $moniker ) = @_;

    if ( $self->is_slave( $moniker ) ) {
        ## connect slave
        if ( $self->slave ) {
            ## TODO re-select per not ->resultset('Foo::Slave'), but request.
            $self->slave->storage->connect_info( $self->_select_connect_info );
        } else {
            $self->slave_connect( @{$self->_select_connect_info} );
        }
        ## TODO more tidily
        $self->slave->storage->debug( $self->storage->debug );
        $self->slave->storage->debugobj( $self->storage->debugobj );
        $self->slave->next::method( $moniker );
    } else {
        ## connect master
        $self->next::method( $moniker );
    }
}

=head2 sources

=over 4

=item Argunemts: none

=item Return Value: @sources

=back

This method returns the sorted alphabetically source monikers of all source registrations on this schema.
See L<DBIx::Class::Schema/"sources">.

  # Returns all sources including slave sources
  my @all_sources = $schema->sources;

=cut

sub sources {
    my $self = shift;

    $self->next::method( @_ );
    return sort( { $b cmp $a } keys( %{$self->source_registrations} ) );
}

=head2 master_sources

=over 4

=item Argunemts: none

=item Return Value: @sources

=back

This method returns the sorted alphabetically master source monikers of all source registrations on this schema.

  my @master_sources = $schema->master_sources;

=cut

sub master_sources { grep { !$_[0]->is_slave( $_ ) } $_[0]->sources }

=head2 slave_sources

=over 4

=item Argunemts: none

=item Return Value: @sources

=back

This method returns the sorted alphabetically slave source monikers of all source registrations on this schema.

  my @slave_sources = $schema->slave_sources;

=cut

sub slave_sources { grep { $_[0]->is_slave( $_ ) } $_[0]->sources }

=head2 slave_connect

=over 4

=item Arguments: @info

=item Return Value: $slave_schema

=back

This method creates slave connection, and store it in C<slave_schema>. You can get this by L</slave>.
Usualy, you don't have to call it directry.

=cut

sub slave_connect { $_[0]->slave_schema( shift->connect( @_ ) ) }

=head2 slave

Getter for L</slave_schema>. You can get schema for slave if it stored in L</slave_schema>.

  my $slave_schema = $schema->slave;

=cut

sub slave { shift->slave_connection }

=head2 select_connect_info

=over 4

=item Argunemts: none

=item Return Value: $connect_info

=back

You can define this method in your schema class as you like. This method has to return C<$connect_info> as C<ARRAYREF>.
If L</select_connect_info> returns C<undef>, undef value or not C<ARRAYREF>, L</_select_connect_info> will be called,
and return C<$connect_info> at random from L</slave_connect_info>.

  # In your MyApp::Schame
  sub select_connect_info {
      my $self = shift;

      my @connect_info = @{$self->slave_connect_info};
      my $connect_info;
      # Some algorithm to select connect_info here

      return $connect_info;
  }

=cut

sub select_connect_info {}

=head2 is_slave

=over 4

=item Arguments: $string

=item Return Value: 1 or 0

=back

This method returns 1 if C<$string> (moniker, class name and so on) is slave stuff, otherwise returns 0.

  __PACKAGE__->slave_moniker('::Slave');

  # Returns 0
  $self->is_slave('Artist');

  # Returns 1
  $self->is_slave('Artist::Slave');

  # Returns 1
  $self->is_slave('MyApp::Model::DBIC::MyApp::Artist::Slave');

  __PACKAGE__->slave_moniker('::SlaveFor');

  # Returns 0
  $self->is_slave('Artist');

  # Returns 1
  $self->is_slave('Artist::SlaveFor');

  # Returns 1
  $self->is_slave('MyApp::Model::DBIC::MyApp::Artist::SlaveFor');

=cut

sub is_slave {
    my ( $self, $string ) = @_;

    my $match = $self->slave_moniker;
    return $string =~ m/$match$/o ? 1 : 0;
}

=head1 INTERNAL METHOD

=head2 _select_connect_info

=over 4

=item Return Value: $connect_info

=back

Internal method. This method returns C<$connect_info> for slave as C<ARRAYREF>.
Usually, you don't have to call it directry.
If you select C<$connect_info> as you like, define L</select_connect_info> in your schema class.
See L</select_connect_info> for more information.

=cut

sub _select_connect_info {
    my $self = shift;

    my $info = ( $self->can('select_connect_info')
                 && $self->select_connect_info
                 && ref $self->select_connect_info eq 'ARRAY' )
        ? $self->select_connect_info
        : $self->slave_connect_info->[ rand @{$self->slave_connect_info} ];

#    warn "Select slave_connect_info $info";
    return $info;
}

# sub _dbd_multi {
#     my $self = shift;

#     my @connect_info  = @{$self->slave_connect_info};
#     my $dbd_multi_opt = ref $connect_info[-1] eq 'HASH' ?
#         pop @connect_info : {};
#     $dbd_multi_opt->{limit_dialect} = $self->storage->sql_maker->limit_dialect
#         unless defined $dbd_multi_opt->{limit_dialect};

#     @connect_info = map {
#         my $dsn = ref $_->[0] ? $_->[0] : $_;
#         my $pri = ( ref $_->[-1] && $_->[-1]->{priority} ) ?
#             $_->[-1]->{priority} : 10;
#         $pri => $dsn;
#     } @connect_info;

#     return [ 'dbi:Multi:', undef, undef,
#             { dsns => \@connect_info, %$dbd_multi_opt } ];
# }

=head1 AUTHOR

travail C<travail@cabane.no-ip.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
