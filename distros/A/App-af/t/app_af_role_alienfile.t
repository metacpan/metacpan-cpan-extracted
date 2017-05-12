use Test2::Bundle::Extended;
use lib 'corpus/lib';
use lib 't/lib';
use MyTest;
use Test::Exit;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

@INC = map { ref $_ ? $_ : path($_)->absolute->stringify } @INC;

package App::af::frooble {

  use Moose;
  with 'App::af';
  with 'App::af::role::alienfile';
  
  sub main {}

};

subtest 'default' => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  
  alienfile q{
    use alienfile;
    meta_prop->{one} = 'default';
  };
  
  my $build = App::af::frooble->new->build;
  
  is($build->meta_prop->{one}, 'default');

};

subtest '-f path' => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  
  alienfile q{
    use alienfile;
    meta_prop->{one} = 'with -f path';
  }, 'foo.alienfile';
  
  my $build = App::af::frooble->new(-f => 'foo.alienfile')->build;
  
  is($build->meta_prop->{one}, 'with -f path');

};

subtest '--file path' => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  
  alienfile q{
    use alienfile;
    meta_prop->{one} = 'with --file path';
  }, 'foo.alienfile';
  
  my $build = App::af::frooble->new('--file' => 'foo.alienfile')->build;
  
  is($build->meta_prop->{one}, 'with --file path');

};

subtest '-c Alien::foo' => sub {
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $build = App::af::frooble->new(-c => 'Alien::foo')->build;

  is($build->meta_prop->{one}, 'from class');
};

subtest '--class Alien::foo' => sub {
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $build = App::af::frooble->new('--class' => 'Alien::foo')->build;

  is($build->meta_prop->{one}, 'from class');
};

subtest '-c foo' => sub {
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $build = App::af::frooble->new(-c => 'foo')->build;

  is($build->meta_prop->{one}, 'from class');
};

subtest '--class foo' => sub {
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $build = App::af::frooble->new('--class' => 'foo')->build;

  is($build->meta_prop->{one}, 'from class');
};

done_testing;
