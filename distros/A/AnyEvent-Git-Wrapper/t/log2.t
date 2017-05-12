use strict;
use warnings;
use Test::More;
BEGIN { $^O eq 'MSWin32' ? eval q{ use Event; 1 } || q{ use EV } : eval q{ use EV } }
use AnyEvent;
use AnyEvent::Git::Wrapper;
use File::Temp qw( tempdir );
use Sort::Versions;

my $dir = tempdir( CLEANUP => 1 );

my $git = AnyEvent::Git::Wrapper->new( $dir );

my $version = $git->version(AE::cv)->recv;
if ( versioncmp( $git->version(AE::cv)->recv , '1.5.0') eq -1 ) {
  plan skip_all =>
    "Git prior to v1.5.0 doesn't support 'config' subcmd which we need for this test."
}

$git->init; # 'git init' also added in v1.5.0 so we're safe

$git->config( 'user.name'  , 'Test User'        );
$git->config( 'user.email' , 'test@example.com' );

# make sure git isn't munging our content so we have consistent hashes
$git->config( 'core.autocrlf' , 'false' );
$git->config( 'core.safecrlf' , 'false' );

do {
  open my $fh, '>', "$dir/foo.txt";
  print $fh "hi there";
  close $fh;
};

$git->add('foo.txt');
$git->commit({ message => 'first commit' });

do {
  open my $fh, '>>', "$dir/foo.txt";
  print $fh "and again";
  close $fh;
};

$git->add('foo.txt');
$git->commit({ message => 'second commit' });


my @expected = $git->log;

do {
  my $cv = $git->log(AE::cv);
  my @log = $cv->recv;
  is_deeply \@log, \@expected;
};

do {
  my @log;
  my $cv = $git->log(sub { push @log, @_ }, AE::cv);
  $cv->recv;
  is_deeply \@log, \@expected;
};

done_testing;
