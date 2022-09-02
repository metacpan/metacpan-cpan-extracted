use Test2::V0 -no_srand => 1;
use Alien::Build::MB;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use File::chdir;
use lib 'corpus/lib';
use Data::Dumper;
use Capture::Tiny qw( capture_merged );

delete $ENV{$_} for qw( ALIEN_BUILD_PRELOAD ALIEN_BUILD_POSTLOAD ALIEN_INSTALL_TYPE );
$ENV{ALIEN_BUILD_RC} = '-';

@INC = map { ref($_) ? $_ : path($_)->absolute->stringify } @INC;

sub alienfile
{
  my($str) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  path('alienfile')->spew($str);
  return;
}

subtest 'share' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );

    plugin 'Test::Mock',
      probe    => 'share',
      download => {
        'foo-1.00.tar.gz' => 'testdata',
      },
      extract  => 1;

    configure { requires 'Foo' => '2.01' };
    probe sub { 'share' };
    share {
      requires 'Bar' => '0.01';

      # TODO: remove this when newer version of AB is required
      # workaround so this works in old and new
      # versions of AB
      after download => sub {
        my($build) = @_;
        my $tarball = Path::Tiny->new('foo-1.00.tar.gz')->absolute->stringify;
        $build->install_prop->{download_detail}->{$tarball}->{digest} ||= [ FAKE => 'deadbeaf' ];
        $build->install_prop->{download_detail}->{$tarball}->{protocol} ||= 'file';
      };

      # TODO: remove this when newer version of AB is required
      meta->register_hook(check_digest => sub { 1 });

      build sub {
        my($build) = @_;
        $build->install_prop->{did_the_install} = 1;
      };
    };
    sys   {
      requires 'Baz' => '0.02'
    };
  };

  my $abmb = Alien::Build::MB->new(
    module_name  => 'Alien::Foo',
    dist_version => '1.00',
  );

  isa_ok $abmb, 'Alien::Build::MB';
  isa_ok $abmb, 'Module::Build';
  is( $abmb->dist_name, 'Alien-Foo', 'dist name');

  is($INC{'Foo.pm'}, T(), 'Foo.pm is loaded' );
  is($INC{'Bar.pm'}, F(), 'Bar.pm is not loaded' );
  is($INC{'Baz.pm'}, F(), 'Baz.pm is not loaded' );

  ok(-d "_alien", "_alien directory created");
  ok(-f "_alien/state.json", "state file created");

  is( $abmb->dynamic_config, T(), "is dynamic" );

  subtest 'configure' => sub {

    my $build = $abmb->alien_build(1);

    isa_ok $build, 'Alien::Build';

    is($build->runtime_prop->{install_type}, 'share', 'type = share');
    is($build->runtime_prop->{prefix}, T(), "runtime prefix");
    is($build->runtime_prop->{perl_module_version}, '1.00', 'perl_module_version is set');
    note $build->runtime_prop->{prefix};

    my $stage = path($build->install_prop->{stage})->relative($CWD);
    is($stage->stringify, "blib/lib/auto/share/dist/Alien-Foo", "stage dir");

    is(
      $abmb->configure_requires,
      hash {
        field 'Module::Build' => T();
        field 'Alien::Build::MB' => T();
        field 'Foo' => '2.01';
        etc;
      },
      'configure requires are set'
    );

    is(
      $abmb->build_requires,
      hash {
        field 'Module::Build' => T();
        field 'Alien::Build::MB' => T();
        field 'Bar' => '0.01';
        etc;
      },
      'build requires are set',
    );
  };

  subtest 'download' => sub {

    note scalar capture_merged { $abmb->ACTION_alien_download };

    is($INC{'Foo.pm'}, T(), 'Foo.pm is loaded' );
    is($INC{'Bar.pm'}, T(), 'Bar.pm is loaded' );
    is($INC{'Baz.pm'}, F(), 'Baz.pm is not loaded' );

    my $build = $abmb->alien_build(1);

    my $download = path($build->install_prop->{download});

    is($download->slurp, 'testdata', 'fake tar faile has content');

  };

  subtest 'build' => sub {
    my($out, $error) = capture_merged {
      eval { $abmb->ACTION_alien_build };
      $@;
    };

    is($error, '', 'build did not error ') || do {
      diag Dumper($abmb->alien_build);
      return;
    };

    my $build = $abmb->alien_build(1);
    is $build->install_prop->{did_the_install}, T();
    ok -f "blib/lib/Alien/Foo/Install/Files.pm", "created Alien::Foo::Install::Files";

    local $INC{'Alien/Foo.pm'} = __FILE__;

    eval { require './blib/lib/Alien/Foo/Install/Files.pm' };
    is "$@", "", "Alien::Foo::Install::Files compiles okay";

    my $mock = mock 'Alien::Foo' => (
      add => [
        Inline => sub {
          { x => 'y', args => [@_] };
        },
      ],
    );

    is(
      Alien::Foo::Install::Files->Inline(1,2,3,4,5,6),
      hash {
        field x => 'y';
        field args => [ 'Alien::Foo', 1,2,3,4,5,6 ];
        end;
      },
      'called Alien::Foo->Inline',
    );

  };

};

subtest 'system' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );

    configure { requires 'Foo' => '2.01' };
    probe sub { 'system' };
    sys   {
      requires 'Baz' => '0.02';
      gather sub {
        my($build) = @_;
        $build->install_prop->{did_the_gather} = 1;
      };
    };
  };

  my $abmb = Alien::Build::MB->new(
    module_name  => 'Alien::Foo',
    dist_version => '1.00',
  );

  subtest 'configure' => sub {

    isa_ok $abmb, 'Alien::Build::MB';
    isa_ok $abmb, 'Module::Build';

    is($INC{'Foo.pm'}, T(), 'Foo.pm is loaded' );
    is($INC{'Baz.pm'}, F(), 'Baz.pm is not loaded' );

    is(
      $abmb->configure_requires,
      hash {
        field 'Module::Build' => T();
        field 'Alien::Build::MB' => T();
        field 'Foo' => '2.01';
        etc;
      },
      'configure requires are set'
    );

    is(
      $abmb->build_requires,
      hash {
        field 'Module::Build' => T();
        field 'Alien::Build::MB' => T();
        field 'Baz' => '0.02';
        etc;
      },
      'build requires are set',
    );

    my $build = $abmb->alien_build(1);
    isa_ok $build, 'Alien::Build';
    is($build->runtime_prop->{install_type}, 'system', 'type = system');

  };

  subtest 'build' => sub {
    note scalar capture_merged { $abmb->ACTION_alien_build };
    my $build = $abmb->alien_build(1);
    is($build->install_prop->{did_the_gather}, T());
  };
};

subtest 'test' => sub {

  skip_all 'test requires Alien::Build 1.14 or better'
    unless eval { require Alien::Build; Alien::Build->VERSION('1.14') };

  subtest 'good' => sub {

    local $CWD = tempdir( CLEANUP => 1 );

    alienfile q{
      use alienfile;
      probe sub { 'system' };
      sys {
        test sub { log("the test") };
      };
    };

    my $abmb = Alien::Build::MB->new(
      module_name  => 'Alien::Foo',
      dist_version => '1.00',
    );

    # AB should take care of this for us
    ok( $abmb->configure_requires->{'Alien::Build'} >= '1.14', 'need at least 1.14 of Alien::Build' );

    note scalar capture_merged { $abmb->ACTION_alien_build };

    my($out, $err) = capture_merged {
      eval { $abmb->ACTION_alien_test };
      $@;
    };

    is $err, '';

  };

  subtest 'bad' => sub {

    local $CWD = tempdir( CLEANUP => 1 );

    alienfile q{
      use alienfile;
      probe sub { 'system' };
      sys {
        test sub { log("the test"); die 'bogus92' };
      };
    };

    my $abmb = Alien::Build::MB->new(
      module_name  => 'Alien::Foo',
      dist_version => '1.00',
    );

    # AB should take care of this for us
    ok( $abmb->configure_requires->{'Alien::Build'} >= '1.14', 'need at least 1.14 of Alien::Build' );
    ok( $abmb->configure_requires->{'Alien::Build::MB'} >= 0.05, 'need at least 0.05 of Alien::Build::MB' );

    note scalar capture_merged { $abmb->ACTION_alien_build };

    my($out, $err) = capture_merged {
      eval { $abmb->ACTION_alien_test };
      $@;
    };

    like $err, qr/bogus92/;

  };

};

done_testing;
