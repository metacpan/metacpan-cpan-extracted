use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);
use FindBin;
use lib "$FindBin::Bin/inc";
use Data::Overlay::Test qw(olok olallok dt);

# olok is overlay ok
# olllok is overlay_all ok, last param is result
# dt is dump terse

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=default"=>1}})'
=cut

# no change with empty overlay
olok({},undef, undef);
olok({},{} => {});
olok(undef,{} => undef);
# action test, but answers the "how do I overlay an empty hash?"
olok(undef,{'=overwrite'=>{}} => {});
olok({a=>1},{} => {a=>1});
olok({},{a=>1} => {a=>1});
olok({},{a=>1},{a=>1} => {a=>1});
olok({a=>{b=>2}},{} => {a=>{b=>2}});
olok({},{a=>{b=>2}} => {a=>{b=>2}});

# overlay_all
olallok({},{},{} => {});
olallok({},{a=>1},{a=>1} => {a=>1});
olallok({},{a=>1},{a=>2} => {a=>2});
olallok({},{a=>1},{a=>{b=>2}} => {a=>{b=>2}});
olallok({},{a=>1},{b=>2} => {a=>1,b=>2});

# hash changes
olok({a=>1},{a=>2} => {a=>2});
olok({a=>1},{b=>2} => {a=>1,b=>2});

# overlay overwrites (diff types)
olok({a=>{b=>2}},{a=>1} => {a=>1});
olok({a=>1},{a=>{b=>2}} => {a=>{b=>2}});

# lower level
olok({a=>{c=>[123]}},{a=>{b=>2}} => {a=>{b=>2,c=>[123]}});
olok({a=>{c=>[123]}},{a=>{b=>{d=>2}}} => {a=>{b=>{d=>2},c=>[123]}});
# should be the same [123]

# TODO check memory match (empty overlay?)

### compose checks
#cmp_deeply(compose({},{} => {},"{} <+> {} = {}");

done_testing();
