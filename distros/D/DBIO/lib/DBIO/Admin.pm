package DBIO::Admin;
# ABSTRACT: Lightweight schema administration helper for DBIO

use strict;
use warnings;

use Carp ();
use JSON::MaybeXS;
use Try::Tiny;
use Scalar::Util 'blessed';
use namespace::clean;


sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;

  for my $attr (qw/schema_class resultset config_stanza sql_dir sql_type
                   version preversion config_file mode/) {
    $self->{$attr} = $args{$attr} if exists $args{$attr};
  }

  for my $attr (qw/force quiet _confirm trace/) {
    $self->{$attr} = $args{$attr} ? 1 : 0 if exists $args{$attr};
  }

  for my $attr (qw/where set attrs/) {
    $self->{$attr} = _coerce_hashref($args{$attr}) if exists $args{$attr};
  }

  if (exists $args{connect_info}) {
    $self->{connect_info} = _coerce_connect_info($args{connect_info});
  }

  if (exists $args{config}) {
    $self->{config} = _coerce_hashref($args{config});
  }

  if (exists $args{schema}) {
    $self->{schema} = $args{schema};
  }

  if ($self->{schema_class}) {
    _require_module($self->{schema_class});
  }

  $self->{mode} ||= 'auto';

  return $self;
}

sub schema_class { $_[0]->{schema_class} }
sub config_stanza { $_[0]->{config_stanza} }
sub sql_dir { $_[0]->{sql_dir} }
sub sql_type { $_[0]->{sql_type} }
sub config_file { $_[0]->{config_file} }

sub resultset {
  if (@_ > 1) {
    $_[0]->{resultset} = $_[1];
    return $_[0];
  }
  return $_[0]->{resultset};
}

sub version {
  if (@_ > 1) {
    $_[0]->{version} = $_[1];
    return $_[0];
  }
  return $_[0]->{version};
}

sub preversion {
  if (@_ > 1) {
    $_[0]->{preversion} = $_[1];
    return $_[0];
  }
  return $_[0]->{preversion};
}

sub force {
  if (@_ > 1) {
    $_[0]->{force} = $_[1];
    return $_[0];
  }
  return $_[0]->{force};
}

sub quiet {
  if (@_ > 1) {
    $_[0]->{quiet} = $_[1];
    return $_[0];
  }
  return $_[0]->{quiet};
}

sub mode {
  if (@_ > 1) {
    $_[0]->{mode} = $_[1];
    return $_[0];
  }
  return $_[0]->{mode};
}

sub where {
  if (@_ > 1) {
    $_[0]->{where} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{where};
}

sub set {
  if (@_ > 1) {
    $_[0]->{set} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{set};
}

sub attrs {
  if (@_ > 1) {
    $_[0]->{attrs} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{attrs};
}

sub trace {
  my ($self, @args) = @_;
  if (@args) {
    $self->{trace} = $args[0] ? 1 : 0;
    $self->schema->storage->debug($self->{trace});
    return $self;
  }
  return $self->{trace};
}

sub schema {
  my ($self) = @_;
  $self->{schema} ||= $self->_build_schema;
  return $self->{schema};
}

sub _build_schema {
  my ($self)  = @_;

  my $connect_info = $self->connect_info;
  $self->_assert_driver_modules_available($connect_info);

  my @connect = _normalized_connect_info($connect_info);
  $connect[3] ||= {};
  $connect[3]{ignore_version} = 1;

  my $schema = $self->schema_class->connect(@connect);
  $schema->storage->debug(1) if $self->{trace};
  return $schema;
}

sub connect_info {
  my ($self) = @_;
  $self->{connect_info} ||= $self->_build_connect_info;
  return $self->{connect_info};
}

sub _build_connect_info {
  my ($self) = @_;
  return $self->_find_stanza($self->config, $self->config_stanza);
}

sub config {
  my ($self) = @_;
  $self->{config} ||= $self->_build_config;
  return $self->{config};
}

sub _build_config {
  my ($self) = @_;

  _require_module('Config::Any', 'Config::Any is required to parse --config files');
  my $cfg = Config::Any->load_files({
    files => [$self->config_file],
    use_ext => 1,
    flatten_to_hash => 1,
  });

  $cfg = $cfg->{$self->config_file};
  return $cfg;
}

sub create {
  my ($self, $sqlt_type, $sqlt_args, $preversion) = @_;

  $preversion ||= $self->preversion;
  $sqlt_type ||= $self->sql_type;

  my $schema = $self->schema;
  Carp::croak('create requires sql_dir') unless $self->sql_dir;

  if (!-d $self->sql_dir) {
    require File::Path;
    File::Path::mkpath($self->sql_dir);
  }

  $schema->create_ddl_dir(
    $sqlt_type,
    (defined $schema->schema_version ? $schema->schema_version : ''),
    $self->sql_dir,
    $preversion,
    $sqlt_args,
  );
}

sub upgrade {
  my ($self) = @_;
  my $mode = lc($self->mode || 'auto');
  Carp::croak("Unsupported mode '$mode' (expected auto|native|legacy)")
    unless $mode =~ /\A(?:auto|native|legacy)\z/;

  if ($mode ne 'legacy') {
    my $native = $self->_upgrade_native;
    return $native if defined $native;
    Carp::croak('No native upgrade path available for this schema/driver')
      if $mode eq 'native';
  }

  return $self->_upgrade_legacy;
}

sub _upgrade_native {
  my ($self) = @_;
  my $schema = $self->schema;

  # PostgreSQL-native upgrade path from DBIO-PostgreSQL
  if ($schema->can('pg_deploy')) {
    _require_module('DBIO::PostgreSQL::Deploy',
      'Native PostgreSQL upgrade requires DBIO-PostgreSQL (install DBIO::PostgreSQL)');
    my $deploy = $schema->pg_deploy;
    return $deploy->upgrade;
  }

  return undef;
}

sub _upgrade_legacy {
  my ($self) = @_;
  my $schema = $self->schema;

  Carp::croak('Legacy upgrade requires a schema with an upgrade() method')
    unless $schema->can('upgrade');

  if ($self->sql_dir && $schema->can('upgrade_directory')) {
    $schema->upgrade_directory($self->sql_dir);
  }

  return $schema->upgrade;
}

sub install {
  my ($self, $version) = @_;

  my $schema = $self->schema;
  Carp::croak('install requires a schema with an install() method')
    unless $schema->can('install');

  $version ||= $self->version;

  if (!$schema->can('get_db_version') || !$schema->get_db_version) {
    print "Going to install schema version\n" if !$self->quiet;
    my $ret = $schema->install($version);
    print "return is $ret\n" if !$self->quiet;
    return $ret;
  }

  if ($schema->can('get_db_version') && $schema->get_db_version && $self->force) {
    Carp::carp("Forcing install may not be a good idea");
    if ($self->_confirm) {
      Carp::croak('Schema does not support forced install version overwrite')
        unless $schema->can('_set_db_version');
      $schema->_set_db_version({ version => $version });
    }
    return 1;
  }

  Carp::croak("Schema already has a version. Try upgrade instead.");
}

sub deploy {
  my ($self, $args) = @_;
  return $self->schema->deploy($args, $self->sql_dir);
}

sub insert {
  my ($self, $rs, $set) = @_;

  $rs ||= $self->resultset;
  $set ||= $self->set;
  Carp::croak('insert requires --resultset/--class and --set') unless $rs && $set;

  my $resultset = $self->schema->resultset($rs);
  my $obj = $resultset->new_result($set)->insert;
  print ''.ref($resultset).' ID: '.join(',', $obj->id)."\n" if !$self->quiet;
  return $obj;
}

sub update {
  my ($self, $rs, $set, $where) = @_;

  $rs ||= $self->resultset;
  $set ||= $self->set;
  $where ||= $self->where || {};
  Carp::croak('update requires --resultset/--class and --set') unless $rs && $set;

  my $resultset = $self->schema->resultset($rs)->search($where);
  if (!$self->quiet) {
    my $count = eval { $resultset->count };
    if (defined $count && !$@) {
      print "This action will modify $count ".ref($resultset)." records.\n";
    }
    else {
      print "This action will modify matching ".ref($resultset)." records.\n";
    }
  }

  return 0 unless $self->force || $self->_confirm;
  return $resultset->update_all($set);
}

sub delete {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset;
  $where ||= $self->where || {};
  $attrs ||= $self->attrs || {};
  Carp::croak('delete requires --resultset/--class') unless $rs;

  my $resultset = $self->schema->resultset($rs)->search($where, $attrs);
  if (!$self->quiet) {
    my $count = eval { $resultset->count };
    if (defined $count && !$@) {
      print "This action will delete $count ".ref($resultset)." records.\n";
    }
    else {
      print "This action will delete matching ".ref($resultset)." records.\n";
    }
  }

  return 0 unless $self->force || $self->_confirm;
  return $resultset->delete_all;
}

sub select {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset;
  $where ||= $self->where || {};
  $attrs ||= $self->attrs || {};
  Carp::croak('select requires --resultset/--class') unless $rs;

  my $resultset = $self->schema->resultset($rs)->search($where, $attrs);
  my @columns = $resultset->result_source->columns;
  my @data = ( [ @columns ] );

  while (my $row = $resultset->next) {
    push @data, [ map { $row->get_column($_) } @columns ];
  }

  return \@data;
}

sub _confirm {
  my ($self) = @_;
  return 1 if $self->{_confirm};
  print "Are you sure you want to do this? (type YES to confirm)\n";
  my $response = <STDIN>;
  return ($response||'') =~ /^YES/;
}

sub _find_stanza {
  my ($self, $cfg, $stanza) = @_;
  Carp::croak('config_stanza is required when using config/config_file')
    unless defined $stanza && length $stanza;

  my @path = split /::/, $stanza;
  while (my $path = shift @path) {
    if (exists $cfg->{$path}) {
      $cfg = $cfg->{$path};
    }
    else {
      Carp::croak("Could not find $stanza in config ($path does not exist)");
    }
  }
  $cfg = $cfg->{connect_info} if ref($cfg) eq 'HASH' && exists $cfg->{connect_info};
  return $cfg;
}

sub _assert_driver_modules_available {
  my ($self, $connect_info) = @_;
  my $driver = _dbi_driver_name($connect_info) || return;

  my %driver_to_modules = (
    pg        => [qw/DBIO::PostgreSQL DBIO::PostgreSQL::Storage/],
    postgresql=> [qw/DBIO::PostgreSQL DBIO::PostgreSQL::Storage/],
    sqlite    => [qw/DBIO::SQLite DBIO::SQLite::Storage/],
    mysql     => [qw/DBIO::MySQL DBIO::MySQL::Storage/],
    mariadb   => [qw/DBIO::MySQL DBIO::MySQL::MariaDB DBIO::MySQL::Storage/],
    oracle    => [qw/DBIO::Oracle DBIO::Oracle::Storage/],
    db2       => [qw/DBIO::DB2 DBIO::DB2::Storage/],
    informix  => [qw/DBIO::Informix DBIO::Informix::Storage/],
    firebird  => [qw/DBIO::Firebird DBIO::Firebird::Storage/],
    sybase    => [qw/DBIO::Sybase DBIO::Sybase::Storage/],
    mssql     => [qw/DBIO::MSSQL DBIO::MSSQL::Storage/],
  );

  my $candidates = $driver_to_modules{ lc $driver } || return;

  for my $mod (@$candidates) {
    return 1 if eval "require $mod; 1";
  }

  Carp::croak(
    "No DBIO driver module available for DSN driver '$driver'. "
    . "Install one of: " . join(', ', @$candidates)
  );
}

sub _dbi_driver_name {
  my ($connect_info) = @_;
  my $dsn;

  if (ref $connect_info eq 'ARRAY') {
    $dsn = $connect_info->[0];
  }
  elsif (ref $connect_info eq 'HASH') {
    $dsn = $connect_info->{dsn};
  }

  return unless defined $dsn && !ref($dsn);
  return $1 if $dsn =~ /\Adbi:([^:;]+)/i;
  return;
}

sub _coerce_hashref {
  my ($val) = @_;
  return $val if ref $val;
  return _json_to_data($val) if defined $val;
  return $val;
}

sub _coerce_connect_info {
  my ($val) = @_;
  return [$val] if ref $val eq 'HASH';
  return $val if ref $val eq 'ARRAY';
  return _json_to_data($val) if defined $val;
  return $val;
}

sub _normalized_connect_info {
  my ($connect_info) = @_;

  if (ref $connect_info eq 'HASH') {
    my %h = %$connect_info;
    my $dsn = delete $h{dsn};
    my $user = delete($h{user}) // '';
    my $pass = delete($h{password}) // '';
    return ($dsn, $user, $pass, \%h);
  }

  if (ref $connect_info eq 'ARRAY') {
    return @$connect_info;
  }

  Carp::croak('connect_info must resolve to an arrayref or hashref');
}

sub _json_to_data {
  my ($json_str) = @_;
  my $json = _build_json_decoder();
  return $json->decode($json_str);
}

sub _build_json_decoder {
  return eval {
    JSON::MaybeXS->new(
      allow_barekey     => 1,
      allow_singlequote => 1,
      relaxed           => 1,
    );
  } || JSON::MaybeXS->new(relaxed => 1);
}

sub _require_module {
  my ($module, $hint) = @_;
  (my $file = "$module.pm") =~ s{::}{/}g;
  return 1 if eval { require $file; 1 };

  my $err = $@ || "Unable to load $module";
  Carp::croak($hint ? "$hint ($err)" : $err);
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Admin - Lightweight schema administration helper for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  use DBIO::Admin;

  my $admin = DBIO::Admin->new(
    schema_class => 'MyApp::Schema',
    connect_info => ['dbi:Pg:dbname=myapp', 'user', 'pass', {}],
    mode => 'auto',
  );

  $admin->deploy;
  $admin->upgrade;

=head1 DESCRIPTION

Administrative helper used by L<dbioadmin>.

Supported operations:

=over 4

=item * C<create> (DDL file generation)

=item * C<upgrade> (native driver upgrade where available, otherwise legacy versioned upgrade)

=item * C<install> (legacy schema-version install)

=item * C<deploy>

=item * C<select>, C<insert>, C<update>, C<delete>

=back

=head1 SEE ALSO

L<dbioadmin>, L<DBIO::Schema>

=head1 MODES

C<mode> controls how C<upgrade> is executed:

=over 4

=item * C<auto> (default): native when available, otherwise legacy

=item * C<native>: require native driver upgrader support

=item * C<legacy>: require C<DBIO::Schema::Versioned>-style upgrade path

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
