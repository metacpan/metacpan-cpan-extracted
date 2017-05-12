use Test::More;
use strict;

my @urls = (
'http://www.example.com/?bc_fields=bc_id%2Cbc_ts%2Cbc_fields&bc_id=cb77bb221a5cae1592489f51ee24006c2a1ee3c5&bc_sig=Y9s3bV%2BEpQl%2F6e7uqsoGRvUleqk%3D%3A0u80L0bpNkaRut3TfDuvuJt6OeI%3D&bc_ts=1121997143',
'http://www.example.com/?bc_email=ask%40develooper.com&bc_fields=bc_id%2Cbc_email%2Cbc_username%2Cbc_name%2Cbc_ts%2Cbc_fields&bc_id=cb77bb221a5cae1592489f51ee24006c2a1ee3c5&bc_name=Ask+Bjørn+Hansen&bc_sig=1T3KAgbdbz05utyO4cP16Kug4xo%3D%3Avm6Rp5bwRK5DYfozf5Crdmsh0HY%3D&bc_ts=1122022689&bc_username=ask'
);

plan tests => 4 + 1*@urls;

use_ok('Authen::Bitcard', 'load module');
ok(my $bc = Authen::Bitcard->new( bitcard_url => 'http://test.bitcard.org/' ), "new");
ok($bc->token('731f1d4110b4d03d6c65cd8df408c2'), 'token');
$bc->version(3);
$bc->key_cache(sub { &__bitcard_key });
ok($bc->skip_expiry_check(1), 'skip_expiry_check');
# $bc->info_required('email,username,name');

for my $url (@urls) {
  my $url = URI->new($url);
  my %form = $url->query_form;
  ok(my $data = $bc->verify(\%form), 'verify');
}



sub __bitcard_key {
 my $data ='p=11996369463481565292523121140449531889825095982121983761936827865954801073413849839236052880545722284106237673100457431775834799856485806364388478204231543
g=11079984797594333311123894730450538747563758095776837999552541421517868087145325620603225047995061886285778482662140484776140447470922327545853855737935682
q=1325099124387589349068596816147033244974696025417
pub_key=8544831415282596138360036915566670162338109712662730782097481290631305162711704659417023332347142944863751759764390118340330011853246719351387417817211195';

use Math::BigInt;
chomp $data;
my $key = {};
for my $f (split /\s+/, $data) {
    my($k, $v) = split /=/, $f, 2;
    $key->{$k} = Math::BigInt->new($v);
}
$key;
}