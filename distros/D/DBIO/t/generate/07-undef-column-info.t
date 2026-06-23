use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use DBIO::Generate;
use DBIO::Generate::Style::Vanilla;

# Introspectors may hand back column info with present-but-undef optional
# keys (size => undef, default_value => undef). The styles must never emit
# bogus "size => " lines or warn about uninitialized values.

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

# --- Style level: Vanilla guards with defined(), not exists() ---

my $spec = {
  moniker      => 'Artist',
  class        => 'My::Undef::Result::Artist',
  table        => 'artists',
  column_order => [qw/id name/],
  columns      => {
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0,
              size => undef },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
  },
  pk               => [qw/id/],
  uniq             => [],
  relationships    => [],
  extra_statements => [],
  is_view          => 0,
  view_definition  => undef,
  result_base_class => 'DBIO::Core',
  components        => [],
  additional_classes => [],
};

my $code = DBIO::Generate::Style::Vanilla->emit($spec);

unlike $code, qr/size\s*=>\s*(?:,|\n)/, 'no bogus size line for undef size';
like   $code, qr/size => 255/,          'defined size still emitted';

# --- Generate level: spec normalization drops undef-valued keys ---

{
  package Test::Gen::UndefFixture;
  use base 'DBIO::Introspect::Base';

  sub _build_model { {} }
  sub table_keys { [qw/artists/] }
  sub table_columns { [qw/id name/] }

  sub table_columns_info {
    return {
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0,
                size => undef, default_value => undef },
      name => { data_type => 'varchar', size => 100, is_nullable => 0 },
    };
  }

  sub table_pk_info { [qw/id/] }
  sub table_uniq_info { [] }
  sub table_fk_info { [] }
  sub table_is_view { 0 }
  sub result_class_extra_statements { () }
}

my $tmpdir = tempdir(CLEANUP => 1);

my $gen = DBIO::Generate->new(
  schema_class   => 'My::Undef',
  dump_directory => $tmpdir,
  style          => 'vanilla',
  use_namespaces => 1,
  generate_pod   => 0,
  quiet          => 1,
);

$gen->dump(Test::Gen::UndefFixture->new(dbh => 'fake'));

my $artist_file = "$tmpdir/My/Undef/Result/Artist.pm";
ok -f $artist_file, 'Artist.pm written';

open my $fh, '<', $artist_file or die $!;
my $artist_code = do { local $/; <$fh> };
close $fh;

unlike $artist_code, qr/size\s*=>\s*(?:,|\n)/, 'generated code has no bogus size line';
unlike $artist_code, qr/default_value\s*=>\s*(?:,|\n)/, 'no bogus default_value line';
like   $artist_code, qr/size => 100/, 'defined size survives normalization';

is_deeply \@warnings, [], 'no warnings (no uninitialized interpolation)'
  or diag explain \@warnings;

done_testing;
