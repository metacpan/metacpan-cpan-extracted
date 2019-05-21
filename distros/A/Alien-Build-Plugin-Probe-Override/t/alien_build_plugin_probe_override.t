use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Probe::Override;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

@INC = map { path($_)->absolute->stringify } @INC;

alien_rc q{

  preload 'Probe::Override';
  
  Alien::Build->log('here');
  
  sub override
  {
    return 'default';
  }

  1;

};

subtest 'compiles okay' => sub {

  alienfile_ok q{
    use alienfile;
  };

};

subtest 'override with "default"' => sub {

  subtest 'system' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'system' };
    };

    alien_install_type_is 'system';

  };

  subtest 'share' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
    };
      
    alien_install_type_is 'share';

  };

};

my $tmp = tempdir( CLEANUP => 1 );
  
subtest 'override with "system"' => sub {

  my $override_class;
  my $mock = Test2::Mock->new(
    class => 'Alien::Build::rc',
    override => [
      override => sub {
        ($override_class) = @_;
        'system';
      },
    ],
  );
  
  subtest 'system' => sub {

    undef $override_class;

    alienfile_ok stage => "$tmp/Alien-libfoo1", prefix => "$tmp/Alien-libfoo1", source => q{
      use alienfile;
      probe sub { 'system' };
    };
    alien_install_type_is 'system';
    is $override_class, 'Alien-libfoo1';

  };

  subtest 'share' => sub {

    undef $override_class;

    my $build = alienfile_ok stage => "$tmp/Alien-libfoo1", prefix => "$tmp/Alien-libfoo1", source => q{
      use alienfile;
      probe sub { 'share' };
    };

    eval { $build->probe };
    like $@, qr/requested system install not available/;

    is $override_class, 'Alien-libfoo1';

  };
    
};

subtest 'override with "share"' => sub {

  my $override_class;
  my $mock = Test2::Mock->new(
    class => 'Alien::Build::rc',
    override => [
      override => sub {
        ($override_class) = @_;
        'share';
      },
    ],
  );
  
  subtest 'system' => sub {

    undef $override_class;

    alienfile_ok stage => "$tmp/Alien-libfoo1", prefix => "$tmp/Alien-libfoo1", source => q{
      use alienfile;
      probe sub { 'system' };
    };
    alien_install_type_is 'share';
    is $override_class, 'Alien-libfoo1';

  };

  subtest 'share' => sub {

    undef $override_class;

    alienfile_ok stage => "$tmp/Alien-libfoo1", prefix => "$tmp/Alien-libfoo1", source => q{
      use alienfile;
      probe sub { 'share' };
    };
    alien_install_type_is 'share';
    is $override_class, 'Alien-libfoo1';

  };

};

done_testing
