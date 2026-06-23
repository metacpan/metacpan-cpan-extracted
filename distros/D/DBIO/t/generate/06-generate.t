use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use DBIO::Generate;

# --- Inline fixture implementing the normalized contract ---
{
  package Test::Gen::Fixture;
  use base 'DBIO::Introspect::Base';

  sub _build_model { {} }

  sub table_keys { [qw/artists cds/] }

  sub table_columns {
    my (undef, $key) = @_;
    return { artists => [qw/id name/], cds => [qw/cdid title artist_id/] }->{$key} // [];
  }

  sub table_columns_info {
    my (undef, $key) = @_;
    return {
      artists => {
        id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
        name => { data_type => 'varchar', size => 100, is_nullable => 0 },
      },
      cds => {
        cdid      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
        title     => { data_type => 'varchar', size => 255, is_nullable => 0 },
        artist_id => { data_type => 'integer', is_nullable => 0 },
      },
    }->{$key} // {};
  }

  sub table_pk_info {
    my (undef, $key) = @_;
    return { artists => [qw/id/], cds => [qw/cdid/] }->{$key} // [];
  }

  sub table_uniq_info { [] }

  sub table_fk_info {
    my (undef, $key) = @_;
    return [] unless $key eq 'cds';
    return [ {
      local_columns  => [qw/artist_id/],
      remote_table   => 'artists',
      remote_schema  => undef,
      remote_columns => [qw/id/],
      attrs          => {},
    } ];
  }

  sub table_is_view { 0 }
  sub result_class_extra_statements { () }
}

my $tmpdir = tempdir(CLEANUP => 1);

my $gen = DBIO::Generate->new(
  schema_class  => 'My::Schema',
  dump_directory => $tmpdir,
  style         => 'vanilla',
  use_namespaces => 1,
  generate_pod   => 0,
);

my $fixture = Test::Gen::Fixture->new(dbh => 'fake');

$gen->dump($fixture);

# Artist class file should exist
my $artist_file = "$tmpdir/My/Schema/Result/Artist.pm";
my $cd_file     = "$tmpdir/My/Schema/Result/Cd.pm";

ok -f $artist_file, 'Artist.pm written';
ok -f $cd_file,     'Cd.pm written';

open my $fh, '<', $artist_file or die $!;
my $artist_code = do { local $/; <$fh> };
close $fh;

like $artist_code, qr/package My::Schema::Result::Artist/, 'Artist package';
like $artist_code, qr/__PACKAGE__->table\('artists'\)/,    'Artist table';
like $artist_code, qr/has_many/,                           'has_many on Artist';

open my $fh2, '<', $cd_file or die $!;
my $cd_code = do { local $/; <$fh2> };
close $fh2;

like $cd_code, qr/package My::Schema::Result::Cd/,      'Cd package';
like $cd_code, qr/belongs_to/,                          'belongs_to on CD';
like $cd_code, qr/My::Schema::Result::Artist/,          'CD refers to Artist class';

done_testing;