use Test2::V0 -no_srand => 1;
use Alien::Libarchive;

# this test doesn't look too closely at what the compat layer
# is returning.  it mostly makes sure that it doesn't blow up.

subtest 'main' => sub {

  subtest 'scalar' => sub {

    note "cflags: ", scalar Alien::Libarchive->cflags;
    note "libs:   ", scalar Alien::Libarchive->libs;
    note "dlls:   ", scalar Alien::Libarchive->dlls;

    ok 1;

  };

  subtest 'list' => sub {

    note "cflags: ", $_ for Alien::Libarchive->cflags;
    note "libs:   ", $_ for Alien::Libarchive->libs;
    note "dlls:   ", $_ for Alien::Libarchive->dlls;

    ok 1;
  };

};

subtest 'version' => sub {

  my $version = Alien::Libarchive->version;
  ok $version;
  note "version = $version";

};

subtest 'install_type' => sub {

  my $type = Alien::Libarchive->install_type;

  like $type, qr/^(share|system)$/;

};

subtest 'pkg_config_dir' => sub {

  my $dir = Alien::Libarchive->pkg_config_dir;

  ok $dir;

  note "dir = $dir";

};

subtest 'pkg_config_name' => sub {

  is(
    Alien::Libarchive->pkg_config_name,
    'libarchive',
   );

};

subtest '_macro_list' => sub {

  skip_all 'macros on linux only' unless $^O eq 'linux';

  my @macros = Alien::Libarchive->_macro_list;

  ok(@macros > 0, 'at least one macro');

  note join ' ', @macros;

};

done_testing;
