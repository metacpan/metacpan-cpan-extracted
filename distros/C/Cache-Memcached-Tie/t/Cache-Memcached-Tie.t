use Test::More;
use lib 't';
use Memd;
use Cache::Memcached::Tie;
use Memd;
my $memd = \%Memd::memd;
if ( !$Memd::error) {
    diag("Connected to " . scalar @Memd::addr
         . " memcached servers, lowest version $Memd::version_str");
    plan tests => 4;
    pass('connected');
    $memd->{ 'test1' } = 'value1';
    is $memd->{'test1'}, 'value1';
    (@$memd{ 'a' .. 'z' }) = (1 .. 26);
    is_deeply [ @$memd{ 'a'.. 'e' }], [ 1 .. 5 ];
    delete $memd->{'test1'};
    ok ! $memd->{'test1'};
} else {
    plan skip_all => $Memd::error;
}
