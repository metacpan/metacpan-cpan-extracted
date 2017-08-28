use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::AlienEnv;
use Alien::Base::ModuleBuild;
use File::chdir;
use File::Temp ();
use Capture::Tiny qw( capture );
use Path::Tiny qw( path );

my $abmb_root = path('.')->absolute;

my $dir = File::Temp->newdir;
local $CWD = "$dir";
# create an extra directory to the hierarchy
# so that the env.* files will not be created
# in /tmp  (see gh#167)
mkdir 'x';
$CWD = 'x';

my %basic = (
  module_name  => 'My::Test',
  dist_version => '0.01',
  dist_author  => 'Joel Berger',
);

sub output_to_note (&) {
  my $sub = shift;
  my($out, $err) = capture { $sub->() };
  note "[out]\n$out" if $out;
  note "[err]\n$err" if $err;
}

our $mb_class = 'Alien::Base::ModuleBuild';

sub builder {
  my @args = @_;
  my $builder;
  output_to_note { $builder = $mb_class->new( %basic, @args ) };
  $builder;
}

###########################
#  Temporary Directories  #
###########################

subtest 'http + ssl' => sub {

  my $builder = builder(
    alien_repository => {
      protocol => 'https',
      location => 'src',
      c_compiler_required => 0,
    },
  );

  is $builder->build_requires->{'IO::Socket::SSL'},     '1.56', 'SSL ~ IO::Socket::SSL 1.56 or better';
  is $builder->build_requires->{'Net::SSLeay'},         '1.49', 'SSL ~ Net::SSLeay 1.49 or better';

};

subtest 'http + ssl + list ref' => sub {

  my $builder = builder(
    alien_repository => [ {
      protocol => 'https',
      location => 'src',
      c_compiler_required => 0,
    } ],
  );

  is $builder->build_requires->{'IO::Socket::SSL'},     '1.56', 'SSL ~ IO::Socket::SSL 1.56 or better';
  is $builder->build_requires->{'Net::SSLeay'},         '1.49', 'SSL ~ Net::SSLeay 1.49 or better';

};

subtest 'default temp and share' => sub {
  local $CWD = _new_temp();

  my $builder = builder;

  # test the builder function
  isa_ok($builder, 'Alien::Base::ModuleBuild');
  isa_ok($builder, 'Module::Build');

  $builder->alien_init_temp_dir;
  ok( -d '_alien', "Creates _alien dir");
  ok( -d '_share', "Creates _share dir");

  output_to_note { $builder->depends_on('clean') };
  ok( ! -d '_alien', "Removes _alien dir");
  ok( ! -d '_share', "Removes _share dir");
};

subtest 'override temp and share' => sub {
  local $CWD = _new_temp();

  my $builder = builder(
    alien_temp_dir => '_test_temp',
    alien_share_dir => '_test_share',
  );

  $builder->alien_init_temp_dir;
  ok( -d '_test_temp', "Creates _test_temp dir");
  ok( -d '_test_share', "Creates _test_temp dir");

  output_to_note { $builder->depends_on('clean') };
  ok( ! -d '_test_temp', "Removes _test_temp dir");
  ok( ! -d '_test_share', "Removes _test_share dir");
};

subtest 'destdir' => sub {
  skip_all 'TODO on MSWin32' if $^O eq 'MSWin32';

  local $CWD = _new_temp();

  open my $fh, '>', 'build.pl';
  print $fh <<'EOF';
use strict;
use warnings;
use File::Copy qw( copy );

my $cmd = shift;
@ARGV = map { s/DESTDIR/$ENV{DESTDIR}/g; $_ } @ARGV;
print "% $cmd @ARGV\n";
if($cmd eq 'mkdir')    { mkdir shift } 
elsif($cmd eq 'touch') { open my $fh, '>', shift; close $fh; }
elsif($cmd eq 'copy')  { copy shift, shift }
EOF
  close $fh;

  my $destdir = File::Temp->newdir;
  
  mkdir 'src';
  open $fh, '>', 'src/foo.tar.gz';
  binmode $fh;
  print $fh unpack("u", 
              q{M'XL(`%)-#E0``TO+S]=GH#$P,#`P-S55`-*&YJ8&R#0<*!@:F1@8FYB8F1J:} .
              q{M*A@`.>:&#`JFM'88")06ER06`9V2GY.369R.6QTA>:@_X/00`6G`^-=+K<@L} .
              q{L+BFFF1W`\#`S,2$E_HW-S<T9%`QHYB(D,,+C?Q2,@E$P<@$`7EO"E``(````}
            );
  close $fh;
  
  my $builder = builder(
    alien_name => 'foobarbazfakething',
    alien_build_commands => [
      [ $^X, "$CWD/build.pl", 'mkdir', 'bin' ],
      [ $^X, "$CWD/build.pl", 'touch', 'bin/foo' ],
    ],
    alien_install_commands => [
      [ $^X, "$CWD/build.pl", 'mkdir', 'DESTDIR%s/bin' ],
      [ $^X, "$CWD/build.pl", 'copy',  'bin/foo', 'DESTDIR%s/bin/foo' ],
    ],
    alien_repository => {
      protocol => 'local',
      location => 'src',
      c_compiler_required => 0,
    },
    alien_stage_install => 0,
  );

  my $share = $builder->alien_library_destination;
  
  output_to_note { $builder->depends_on('build') };

  $builder->destdir($destdir);  
  is $builder->destdir, $destdir, "destdir accessor";
  
  output_to_note { $builder->depends_on('install') };

  my $foo_script = "$destdir/$share/bin/foo";
  ok -e $foo_script, "script installed in destdir $foo_script";
};

subtest 'alien_bin_requires' => sub {

  my $bin = $abmb_root->child('corpus/alien_base_modulebuild/bin')->stringify;
  
  local $CWD = _new_temp();
  
  note "bin = $bin";

  eval q{
    package Alien::Libfoo;

    our $VERSION = '1.00';
    
    $INC{'Alien/Libfoo.pm'} = __FILE__;

    package Alien::ToolFoo;

    our $VERSION = '0.37';
    
    $INC{'Alien/ToolFoo.pm'} = __FILE__;
    
    sub bin_dir {
      ($bin)
    }
  };

  my $builder = builder(
    alien_name => 'foobarbazfakething',
    build_requires => {
      'Alien::Libfoo' => '1.00',
    },
    alien_bin_requires => {
      'Alien::ToolFoo' => '0.37',
    },
    alien_build_commands => [
      '/bin/true',
    ],
  );

  is $builder->build_requires->{"Alien::MSYS"},     undef, 'no Alien::MSYS';
  is $builder->build_requires->{"Alien::Libfoo"},  '1.00', 'normal build requires';
  is $builder->build_requires->{"Alien::ToolFoo"}, '0.37', 'alien_bin_requires implies a build requires';

  my %status;
  output_to_note { 
    local $CWD;
    my $dir = "_alien/buildroot";
    path($dir)->mkpath({verbose => 0});
    $CWD = $dir;
    %status = $builder->alien_do_system('privateapp');
  };
  ok $status{success}, 'found privateapp in path';
  if($^O eq 'MSWin32') {
    ok -e "_alien/env.cmd", 'cmd shell helper';
    ok -e "_alien/env.bat", 'bat shell helper';
    ok -e "_alien/env.ps1", 'power shell helper';
  } else {
    ok -e "_alien/env.sh", 'bourne shell helper';
    ok -e "_alien/env.csh", 'c shell helper';
  }
};

subtest 'alien_check_built_version' => sub {

  local $CWD = _new_temp();

  open my $fh, '>', 'build.pl';
  print $fh <<'EOF';
exit 0;
EOF
  close $fh;

  mkdir 'src';
  open $fh, '>', 'src/foo.tar.gz';
  binmode $fh;
  print $fh unpack("u", 
    q{M'XL(`)"=)%0``^W1P0K",`P&X)Y]BCQ!36K2GGP8#YL,AH6UBH]OA#%DH)ZJ} .
    q{MB/DNH;30O_W[G+>N,41,(J"3DN#C7``%)A4C$:`N)#F0UL'NSJ4>)HV2QW$H} .
    q{MQ^?GWNW/[UCFC^BU_TLWE2&??+W6)G?H?T3F%_V'=?\<DSC`)FE6_KS_N7O8} .
    q{50_`[SYMOYS'&&/,9-ZR`#EH`"@``}
  );
  close $fh;

  eval q{
    package My::ModuleBuild1;
    
    use base qw( Alien::Base::ModuleBuild );
    
    sub alien_check_built_version {
      open my $fh, '<', 'version.txt';
      my $txt = <$fh>;
      close $fh;
      $txt =~ /version = ([0-9.]+)/ ? $1 : ();
    }
  };
  die $@ if $@;

  local $mb_class = 'My::ModuleBuild1';
  
  my $builder = builder(
    alien_name => 'foobarbazfakething',
    alien_build_commands => [
      [ $^X, "$CWD/build.pl" ],
    ],
    alien_install_commands => [
      [ $^X, "$CWD/build.pl" ],
    ],
    alien_repository => {
      protocol => 'local',
      location => 'src',
      c_compiler_required => 0,
    },
  );
  
  output_to_note { $builder->depends_on('build') };

  is $builder->config_data( 'version' ), '2.3.4', 'version is set correctly';
};

subtest 'multi arg do_system' => sub {

  local $CWD = _new_temp();

  open my $fh, '>', 'build.pl';
  print $fh <<'EOF';
exit($ARGV[0] =~ /^(build|install) it$/ ? 0 : 2);
EOF
  close $fh;

  mkdir 'src';
  open $fh, '>', 'src/foo.tar.gz';
  binmode $fh;
  print $fh unpack("u", 
    q{M'XL(`)"=)%0``^W1P0K",`P&X)Y]BCQ!36K2GGP8#YL,AH6UBH]OA#%DH)ZJ} .
    q{MB/DNH;30O_W[G+>N,41,(J"3DN#C7``%)A4C$:`N)#F0UL'NSJ4>)HV2QW$H} .
    q{MQ^?GWNW/[UCFC^BU_TLWE2&??+W6)G?H?T3F%_V'=?\<DSC`)FE6_KS_N7O8} .
    q{50_`[SYMOYS'&&/,9-ZR`#EH`"@``}
  );
  close $fh;

  eval q{
    package My::ModuleBuild2;
    
    use base qw( Alien::Base::ModuleBuild );
    
    sub alien_check_built_version {
      open my $fh, '<', 'version.txt';
      my $txt = <$fh>;
      close $fh;
      $txt =~ /version = ([0-9.]+)/ ? $1 : ();
    }
  };
  die $@ if $@;

  local $mb_class = 'My::ModuleBuild2';
  
  my $builder = builder(
    alien_name => 'foobarbazfakething',
    alien_build_commands => [
      [ "%x", "$CWD/build.pl", "build it" ],
    ],
    alien_install_commands => [
      [ "%x", "$CWD/build.pl", "install it" ],
    ],
    alien_repository => {
      protocol => 'local',
      location => 'src',
      c_compiler_required => 0,
    },
  );
  
  output_to_note { $builder->depends_on('build') };

  is $builder->config_data( 'version' ), '2.3.4', 'version is set correctly';
};

subtest 'source build requires' => sub {

  local $CWD = _new_temp();

  local $mb_class = do {
    package My::MBBuildRequiresExample1;

    use base qw( Alien::Base::ModuleBuild );

    sub alien_check_installed_version
    {
      return;
    }

    __PACKAGE__;
  };

  subtest 'not installed, not forced' => sub {
    local $Alien::Base::ModuleBuild::Force = 0;
    my $builder = builder( alien_bin_requires => { 'Foo::Bar' => '1.1' } );
    is $builder->build_requires->{"Foo::Bar"}, '1.1', 'Foo::Bar = 1.1';
  };

  subtest 'not installed, forced' => sub {
    local $Alien::Base::ModuleBuild::Force = 1;
    my $builder = builder( alien_bin_requires => { 'Foo::Bar' => '1.1' } );
    is $builder->build_requires->{"Foo::Bar"}, '1.1', 'Foo::Bar = 1.1';
  };

  local $mb_class = do {
    package My::MBBuildRequiresExample2;

    use base qw( Alien::Base::ModuleBuild );

    sub alien_check_installed_version
    {
      return '1.2';
    }

    __PACKAGE__;
  };

  subtest 'installed, not forced' => sub {
    local $Alien::Base::ModuleBuild::Force = 0;
    my $builder = builder( alien_bin_requires => { 'Foo::Bar' => '1.1' } );
    is $builder->build_requires->{"Foo::Bar"}, undef, 'Foo::Bar = undef';
  };

  subtest 'installed, forced' => sub {
    local $Alien::Base::ModuleBuild::Force = 1;
    my $builder = builder( alien_bin_requires => { 'Foo::Bar' => '1.1' } );
    is $builder->build_requires->{"Foo::Bar"}, '1.1', 'Foo::Bar = 1.1';
  };
};

subtest 'system provides' => sub {

  local $CWD = _new_temp();

  local $mb_class = do {
    package My::MBBuildSystemProvidesExample;

    use base qw( Alien::Base::ModuleBuild );

    sub alien_check_installed_version {
      return '1.0';
    }

    __PACKAGE__;
  };

  subtest 'not installed, not forced' => sub {
    local $Alien::Base::ModuleBuild::Force = 0;
    my $builder = builder( alien_provides_cflags => '-DMY_CFLAGS', alien_provides_libs => '-L/my/libs -lmylib' );
    $builder->depends_on('code');
    is $builder->config_data('system_provides')->{Cflags}, '-DMY_CFLAGS',          'cflags';
    is $builder->config_data('system_provides')->{Libs},   '-L/my/libs -lmylib', 'libs';
  };
};

subtest 'alien_env' => sub {

  local $CWD = _new_temp();
  local $ENV{BAZ} = 'baz';

  my $builder = builder(
    alien_helper => {
      myhelper => '"my helper text"',
    },
    alien_env => {
      FOO => 'foo1',
      BAR => '%{myhelper}',
      BAZ => undef,
    },
    alien_build_commands => [],
  );
  
  isa_ok $builder, 'Alien::Base::ModuleBuild';
  my($out, $err, %status) = capture { $builder->alien_do_system([$^X, -e => 'print $ENV{FOO}']) };
  is $status{stdout}, 'foo1', 'env FOO passed to process';
  ($out, $err, %status) = capture { $builder->alien_do_system([$^X, -e => 'print $ENV{BAR}']) };
  is $status{stdout}, 'my helper text', 'alien_env works with helpers';
  ($out, $err, %status) = capture { $builder->alien_do_system([$^X, -e => 'print $ENV{BAZ}||"undef"']) };
  is $status{stdout}, 'undef', 'alien_env works with helpers';
};

subtest 'cmake' => sub {

  subtest 'default' => sub {

    local $CWD = _new_temp();

    my $builder = builder(
      alien_bin_requires => { 'Alien::CMake' => 0 },
      alien_build_commands => [],
    );

    isa_ok $builder, 'Alien::Base::ModuleBuild';
    is $builder->build_requires->{"Alien::CMake"}, '0.07', 'require at least 0.07';
  };

  subtest 'more recent' => sub {

    local $CWD = _new_temp();

    my $builder = builder(
      alien_bin_requires => { 'Alien::CMake' => '0.10' },
      alien_build_commands => [],
    );

    isa_ok $builder, 'Alien::Base::ModuleBuild';
    is $builder->build_requires->{"Alien::CMake"}, '0.10', 'keep 0.10';
  };
  
};

subtest 'install location' => sub {

  local $CWD = _new_temp();

  my $builder = builder();
  my $path = $builder->alien_library_destination;

  # this is not good enough, I really wish I could introspect File::ShareDir, then again, I wouldn't need this test!
  my $path_to_share = "auto/share/dist/My-Test";
  $path_to_share =~ s{\\}{/}g if $^O eq 'MSWin32';
  like $path, qr/\Q$path_to_share\E/, 'path looks good';
};

subtest 'validation' => sub {

  local $CWD = _new_temp();

  my $builder = builder(
    module_name  => 'My::Test::Module',
    dist_version => '1.234.567',
  );

  ok( $builder->alien_validate_repo( {platform => undef} ), "undef validates to true");

  subtest 'windows test' => sub {
    skip_all "Windows test" unless $builder->is_windowsish();
    ok( $builder->alien_validate_repo( {platform => 'Windows'} ), "platform Windows on Windows");
    ok( ! $builder->alien_validate_repo( {platform => 'Unix'} ), "platform Unix on Windows is false");
  };

  subtest 'unix test' => sub {
    skip_all "Unix test" unless $builder->is_unixish();
    ok( $builder->alien_validate_repo( {platform => 'Unix'} ), "platform Unix on Unix");
    ok( ! $builder->alien_validate_repo( {platform => 'Windows'} ), "platform Windows on Unix is false");
  };

  subtest 'need c compiler' => sub {
    skip_all "Needs c compiler" unless $builder->have_c_compiler();
    ok( $builder->alien_validate_repo( {platform => 'src'} ), "platform src");
  };
};

subtest 'basic interpolation' => sub {

  my $builder = builder();

  is( $builder->alien_interpolate('%phello'), $builder->alien_exec_prefix . 'hello', 'prefix interpolation');
  is( $builder->alien_interpolate('%%phello'), '%phello', 'no prefix interpolation with escape');

  my $path = $builder->alien_library_destination;
  is( $builder->alien_interpolate('thing other=%s'), "thing other=$path", 'share_dir interpolation');
  is( $builder->alien_interpolate('thing other=%%s'), 'thing other=%s', 'no share_dir interpolation with escape');

  my $perl = $builder->perl;
  is( $builder->alien_interpolate('%x'), $perl, '%x is current interpreter' );
  unlike( $builder->alien_interpolate('%X'), qr{\\}, 'no backslash in %X' );
};

subtest 'interpolation of version' => sub {

  my $builder = builder();

  subtest 'prior to loading version information' => sub {

    my $warn_count = warns {
      is  ( $builder->alien_interpolate('version=%v'), 'version=%v', 'version prior to setting it' );
    };
    is $warn_count, 1, 'version warning';
  };
  
  subtest 'after loading the version information' => sub {

    my $warn_count = warns {

      my $current_version = $builder->config_data( 'alien_version' ) ;
      my $test_version = time;
      $builder->config_data( 'alien_version', $test_version );
      is( $builder->alien_interpolate('version=%v'), "version=$test_version", 'version after setting it' );
    };
  
    is $warn_count, 0, 'no warnings';

  };

};


subtest 'interpolation of helpers' => sub {

  my $mock = Test2::Mock->new(
    class => 'Alien::foopatcher',
    add => [
      new          => sub { bless 'Alien::foopatcher', {} },
      alien_helper => sub {
        return {
          patch1 => 'join " ", qw(patch1 --binary)',
          patch2 => sub { 'patch2 --binary' },
          double => sub { 2 },
          argument_count2 => sub { scalar @_ },
        },
      }
    ],
  );

  my $builder = builder(
    alien_helper => {
      foo => ' "bar" . "baz" ',
      exception => ' die "abcd" ',
      double => '"1";',
      argument_count1 => 'scalar @_',
    },
    alien_bin_requires => {
      'Alien::foopatcher' => 0,
    },
  ); 

  is( $builder->alien_interpolate("|%{foo}|"), "|barbaz|", "helper" );
  is( $builder->alien_interpolate("|%{foo}|%{foo}|"), "|barbaz|barbaz|", "helper x 2" );
  eval { $builder->alien_interpolate("%{exception}") };
  like $@, qr{abcd}, "exception gets thrown";

  $builder->_alien_bin_require('Alien::foopatcher');
  is( $builder->alien_interpolate("|%{patch1}|"), "|patch1 --binary|", "helper from independent Alien module");
  is( $builder->alien_interpolate("|%{patch2}|"), "|patch2 --binary|", "helper from independent Alien module with code ref");

  eval { $builder->alien_interpolate("%{bogus}") };
  like $@, qr{no such helper: bogus}, "exception thrown with bogus helper";

  is( $builder->alien_interpolate('%{double}'), "1", "MB helper overrides AB helper");

  is( $builder->alien_interpolate('%{argument_count1}'), "0", "argument count is zero (string helper)");
  is( $builder->alien_interpolate('%{argument_count2}'), "0", "argument count is zero (code helper)");

  is( $builder->alien_interpolate('%{pkg_config}'), Alien::Base::PkgConfig->pkg_config_command, "support for %{pkg_config}");
};

subtest 'find lib' => sub {

  my $expected = { 
    lib       => [ 'lib' ], 
    inc       => [ 'include' ],
    lib_files => [ 'mylib' ],
  };

  my $builder = builder();

  $builder->config( so => 'so' );
  $builder->config( ext_lib => '.a' );

  subtest 'dynamic' => sub {

    my $dir = $abmb_root->child('corpus/alien_base_modulebuild__find_lib/dynamic')->stringify;

    subtest 'Find from file structure' => sub {
      local $expected->{lib_files} = [sort qw/mylib onlypostdot onlypredot otherlib prepostdot/];
      my $paths = $builder->alien_find_lib_paths($dir);
      is( $paths, $expected, "found paths from extensions only" ); 

      my $pc = $builder->alien_generate_manual_pkgconfig($dir);
      isa_ok($pc, 'Alien::Base::PkgConfig');

      my $libs = $pc->keyword('Libs');
      note "libs = $libs";

      like( $libs, qr/-lmylib/, "->keyword('Libs') returns mylib" );

      my ($L) = $libs =~ /-L(\S*)/g;
      ok( -d $L,  "->keyword('Libs') finds mylib directory");
      opendir(my $dh, $L);
      my @files = grep { /mylib/ } readdir $dh;
      ok( @files, "->keyword('Libs') finds mylib" );
    };

    subtest 'Find using alien_provides_libs' => sub {
      $builder->alien_provides_libs('-lmylib');
      my $paths = $builder->alien_find_lib_paths($dir);
      is( $paths, $expected, "found paths from provides" ); 

      my $pc = $builder->alien_generate_manual_pkgconfig($dir);
      isa_ok($pc, 'Alien::Base::PkgConfig');

      my $libs = $pc->keyword('Libs');
      note "libs = $libs";

      like( $libs, qr/-lmylib/, "->keyword('Libs') returns mylib" );

      my ($L) = $libs =~ /-L(\S*)/g;
      ok( -d $L,  "->keyword('Libs') finds mylib directory");
      opendir(my $dh, $L);
      my @files = grep { /mylib/ } readdir $dh;
      ok( @files, "->keyword('Libs') finds mylib" );
    };
  };

  subtest 'Find with static libs only' => sub {

    my $dir = $abmb_root->child('corpus/alien_base_modulebuild__find_lib/static')->stringify;

    $builder->alien_provides_libs(undef);
    local $expected->{lib_files} = [sort qw/mylib otherlib/];

    my $paths = $builder->alien_find_lib_paths($dir);
    is( $paths, $expected, "found paths from extensions only" );

    my $pc = $builder->alien_generate_manual_pkgconfig($dir);
    isa_ok($pc, 'Alien::Base::PkgConfig');

    my $libs = $pc->keyword('Libs');
    note "libs = $libs";

    like( $libs, qr/-lmylib/, "->keyword('Libs') returns mylib" );

    my ($L) = $libs =~ /-L(\S*)/g;
    ok( -d $L,  "->keyword('Libs') finds mylib directory");
    opendir(my $dh, $L);
    my @files = grep { /mylib/ } readdir $dh;
    ok( @files, "->keyword('Libs') finds mylib" );
  };

  subtest 'Find with static libs and dynamic dir' => sub {

    my $dir = $abmb_root->child('corpus/alien_base_modulebuild__find_lib/mixed')->stringify;

    local $expected->{lib_files} = [sort qw/mylib otherlib/];

    my $paths = $builder->alien_find_lib_paths($dir);
    is( $paths, $expected, "found paths from extensions only" );
  
    my $pc = $builder->alien_generate_manual_pkgconfig($dir);
    isa_ok($pc, 'Alien::Base::PkgConfig');

    my $libs = $pc->keyword('Libs');
    note "libs = $libs";

    like( $libs, qr/-lmylib/, "->keyword('Libs') returns mylib" );

    my ($L) = $libs =~ /-L(\S*)/g;
    ok( -d $L,  "->keyword('Libs') finds mylib directory");
    opendir(my $dh, $L);
    my @files = grep { /mylib/ } readdir $dh;
    ok( @files, "->keyword('Libs') finds mylib" );

  };
};

$CWD = "$abmb_root";

my $count = 1;
sub _new_temp
{
  my $dir = "xx@{[ $count++ ]}";
  mkdir $dir;
  $dir;
}

done_testing;
