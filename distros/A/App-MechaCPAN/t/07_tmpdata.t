use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
local $App::MechaCPAN::PROJ_DIR = $tmpdir;
chdir $tmpdir;
my $dir = cwd;

my $test_filename  = 'v0.24.zip';
my $test_url       = "https://github.com/p5sagit/Try-Tiny/archive/$test_filename";
my $type           = join( '', map { ( 'a' .. 'z' )[ int rand 26 ] } ( 1 .. 4 ) );
my $humane_pattern = qr{ mecha_ .*? [.] [\d_]* [.] [^.]* }xms;
my $type_pattern   = qr{ mecha_$type [.] [\d_]* [.] X* }xms;
my $log_pattern    = qr{ mecha_log [.] [\d_]* [.] }xms;

like( App::MechaCPAN::humane_tmpname($type), qr/^$type_pattern$/, 'Humane name is maintained' );

# Test log names
{
  my $log_line;
  local *App::MechaCPAN::info = sub { $log_line = shift };
  App::MechaCPAN::_setup_log($tmpdir);
  isnt( $log_line, undef, 'Logging tells you where it will log to' );
  like( $log_line, $log_pattern, 'Logging to an approriate file name' );
}

# Test temp downloads
{
  my $where  = App::MechaCPAN::fetch_file($test_url);
  my $where2 = "$where";

  is( $where, $where2, 'Download file sanity check' );
  isa_ok( $where, 'File::Temp' );
  is( -e $where, 1, 'Was able to download file correctly' );
  like( $where, qr{^ $tmpdir /local/tmp/ $humane_pattern $}xms, 'Downloaded tmp file is humane' );
  like( $where, qr{ \Q$test_filename\E }xms, 'Downloaded tmp file includes original filename' );

  undef $where;
  is( -e $where2, undef, q{Undef'ing $where removes the file} );
}

# Test relative directory downloads
{
  my $where = App::MechaCPAN::fetch_file( $test_url => 'pkg/' );
  my $where2 = "$where";

  is( $where,     $where2, 'Download file sanity check' );
  is( ref $where, '',      'Downloaded file is not a File::Temp' );
  is( -e $where,  1,       'Was able to download file correctly' );
  like( $where, qr{ $tmpdir /local/pkg/ $test_filename }xms, 'Downloaded tmp file is not humane' );

  undef $where;
  is( -e $where2, 1, q{Undef'ing $where does not removes the file} );
  unlink $where2;
}

# Test relative file downloads
{
  my $where = App::MechaCPAN::fetch_file( $test_url => "pkg/$test_filename" );
  my $where2 = "$where";

  is( $where,     $where2, 'Download file sanity check' );
  is( ref $where, '',      'Downloaded file is not a File::Temp' );
  is( -e $where,  1,       'Was able to download file correctly' );
  like( $where, qr{ $tmpdir /local/pkg/ $test_filename }xms, 'Downloaded tmp file is not humane' );

  undef $where;
  is( -e $where2, 1, q{Undef'ing $where does not removes the file} );
  unlink $where2;
}

# Test absolute file downloads
{
  my $where = App::MechaCPAN::fetch_file( $test_url => "$tmpdir/local/pkg/$test_filename" );
  my $where2 = "$where";

  is( $where,     $where2, 'Download file sanity check' );
  is( ref $where, '',      'Downloaded file is not a File::Temp' );
  is( -e $where,  1,       'Was able to download file correctly' );
  like( $where, qr{ $tmpdir /local/pkg/ $test_filename }xms, 'Downloaded tmp file is not humane' );

  undef $where;
  is( -e $where2, 1, q{Undef'ing $where does not removes the file} );
  unlink $where2;
}

# Test slurp downloads
{
  my $slurp  = '';
  my $url    = 'http://www.cpan.org/src/5.0/perl-5.12.5.tar.gz.md5.txt';
  my $where  = App::MechaCPAN::fetch_file( $url => \$slurp );
  my $where2 = "$where";

  is( $where, $where2, 'Download file sanity check' );
  isa_ok( $where, 'File::Temp' );
  is( -e $where, 1, 'Was able to download file correctly' );
  like( $where, qr{ $tmpdir /local/tmp/ $humane_pattern }xms, 'Downloaded tmp file was humane' );
  isnt( $slurp, '', 'Slurpped data to string' );

  my $slurp2 = "$slurp";
  undef $where;
  is( -e $where2, undef, q{Undef'ing $where removes the file} );
  isnt( $slurp, '', 'Slupped data stayed after file removal' );
  is( $slurp, $slurp2, 'Slurpped data was unaffected by undef of file' );
}

# Test slurp simple
{
  is_deeply( [ glob("$tmpdir/local/tmp/*") ], [], 'No files in tmp directory before slurp' );
  my $slurp = '';
  my $url   = 'http://www.cpan.org/src/5.0/perl-5.12.5.tar.gz.md5.txt';
  App::MechaCPAN::fetch_file( $url => \$slurp );

  isnt( $slurp, '', 'Slurpped data to string' );
  is_deeply( [ glob("$tmpdir/local/tmp/*") ], [], 'No evidence was found in tmp' );
}

chdir $pwd;

done_testing;
