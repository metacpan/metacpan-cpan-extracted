use Test2::V0 -no_srand => 1;
use App::supertouch;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

my $dir = tempdir( CLEANUP => 1 );
note "dir = $dir";

subtest 'canon path' => sub {
  my $path = path( $dir, 'foo', 'bar', 'baz.txt' );
  note "+ supertouch @{[ $path->canonpath ]}";
  App::supertouch->main( $path->canonpath );
  ok -f $path;
};

subtest 'unix path' => sub {
  my $path = path( $dir, 'roger', 'ramjet', 'foo.txt' );
  note "+ supertouch @{[ $path->stringify ]}";
  App::supertouch->main( $path->stringify );
  ok -f $path;
};

subtest 'dir' => sub {
  my $path = path( $dir, 'xor', 'roger', 'ramjet', 'foo' );
  note "+ supertouch @{[ $path->stringify ]}/";
  App::supertouch->main( $path->stringify . "/");
  ok -d $path;
};

done_testing;
