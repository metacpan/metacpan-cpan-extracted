use Test::More;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (Digest::MD5) not installed"
  unless eval {
               require Digest::MD5;
              };

plan tests => 33;

my $package = 'Apache::Session::Generate::MD5';
use_ok $package;

#my $origdir = getcwd;
#my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
#chdir( $tempdir );

my $session = {};

Apache::Session::Generate::MD5::generate($session);

ok exists($session->{data}->{_session_id}), 'session id created';

ok keys(%{$session->{data}}) == 1, 'just one key in the data hashref';

like $session->{data}->{_session_id}, qr/^[0-9a-fA-F]{32}$/, 'id looks like hex';

my $old_id = $session->{data}->{_session_id};

Apache::Session::Generate::MD5::generate($session);

isnt $old_id, $session->{data}->{_session_id}, 'old session id does not match new one';

for my $length (5 .. 32) {
    $session->{args}->{IDLength} = $length;
    
    Apache::Session::Generate::MD5::generate($session);

    like $session->{data}->{_session_id}, qr/^[0-9a-fA-F]{$length}$/,
         "id is $length chars long";
}

#chdir( $origdir );
