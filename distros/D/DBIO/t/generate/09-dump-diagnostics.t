use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use DBIO::Generate;

# Codeberg #15: an introspection run that silently yields nothing
# reached the user as a successful "Done." with no files. dump() must say so
# out loud, and the files it does write must not drag empty directories along.

{
  package Test::Gen::Empty;
  use base 'DBIO::Introspect::Base';
  sub _build_model { {} }
  sub table_keys        { [] }
  sub table_columns     { [] }
  sub table_columns_info { {} }
  sub table_pk_info     { [] }
  sub table_uniq_info   { [] }
  sub table_fk_info     { [] }
  sub table_is_view     { 0 }
  sub view_definition   { undef }
  sub result_class_extra_statements { () }
}

{
  package Test::Gen::OneTable;
  use base 'Test::Gen::Empty';
  sub table_keys        { [qw/artists/] }
  sub table_columns     { [qw/id name/] }
  sub table_columns_info {
    return {
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'varchar', size => 100, is_nullable => 0 },
    };
  }
  sub table_pk_info { [qw/id/] }
}

sub warnings_from {
  my ($gen, $introspect) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $gen->dump($introspect);
  return @warnings;
}

sub generator {
  my (%args) = @_;
  return DBIO::Generate->new(
    schema_class   => 'My::Schema',
    dump_directory => tempdir(CLEANUP => 1),
    style          => 'vanilla',
    generate_pod   => 0,
    %args,
  );
}

# --- an introspector that finds nothing must not be silent ---

{
  my @warnings = warnings_from(generator(), Test::Gen::Empty->new(dbh => 'fake'));
  my ($empty) = grep { /no tables/i } @warnings;

  ok $empty, 'dump() warns when the introspector reports no tables at all'
    or diag "warnings: @warnings";
  like $empty, qr/Test::Gen::Empty/,
    'the warning names the introspector, so a broken driver path is traceable';
  like $empty, qr/no Result classes written/,
    'the warning states the consequence -- nothing was written';
}

# --- but it stays a warning: an empty database is legitimate, not fatal ---

{
  my $gen = generator();
  my $lived = eval {
    local $SIG{__WARN__} = sub {};
    $gen->dump(Test::Gen::Empty->new(dbh => 'fake'));
    1;
  };
  ok $lived, 'an empty schema warns but does not die' or diag $@;
}

# --- quiet is honoured ---

{
  my @warnings = warnings_from(generator(quiet => 1), Test::Gen::Empty->new(dbh => 'fake'));
  is_deeply \@warnings, [], 'quiet => 1 suppresses the empty-schema warning';
}

# --- filtering everything away is a different diagnosis ---

{
  my @warnings = warnings_from(
    generator(exclude => qr/artists/),
    Test::Gen::OneTable->new(dbh => 'fake'),
  );
  my ($filtered) = grep { /filtered out/ } @warnings;

  ok $filtered, 'dump() warns when constraint/exclude removed every table'
    or diag "warnings: @warnings";
  like $filtered, qr/\b1\b/,
    'the warning reports how many tables were introspected, so the user can '
      . 'tell a bad filter from a bad connection';
  unlike $filtered, qr/reported no tables/,
    'a filtered-away schema is not misreported as an empty database';
}

# --- writing a class must not create a directory named after the class ---

{
  my $dir = tempdir(CLEANUP => 1);
  my $gen = DBIO::Generate->new(
    schema_class   => 'My::Schema',
    dump_directory => $dir,
    style          => 'vanilla',
    generate_pod   => 0,
    quiet          => 1,
  );
  $gen->dump(Test::Gen::OneTable->new(dbh => 'fake'));

  ok -f "$dir/My/Schema/Result/Artist.pm", 'Artist.pm written';
  ok !-e "$dir/My/Schema/Result/Artist",
    'no empty Artist/ directory left beside Artist.pm';

  my @stray;
  my $walk;
  $walk = sub {
    my ($path) = @_;
    opendir my $dh, $path or return;
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $e (@entries) {
      next unless -d "$path/$e";
      push @stray, "$path/$e" unless @{[ glob("$path/$e/*") ]};
      $walk->("$path/$e");
    }
  };
  $walk->($dir);
  is_deeply \@stray, [], 'dump left no empty directories anywhere under the dump root'
    or diag "empty dirs: @stray";
}

done_testing;
