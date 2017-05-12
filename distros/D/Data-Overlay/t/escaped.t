use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);
use FindBin;
use lib "$FindBin::Bin/inc";
use Data::Overlay::Test qw(olok olallok dt);

# olok is overlay ok
# olallok is overlay_all ok (last param is result)
# dt is dump terse

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=default"=>1}})'
=cut

# escaping "=" in overlay
olok({'=a'=>{'=c'=>[123]}}, {'==a'=>{'==b'=>2}}
                => {'=a'=>{'=b'=>2,'=c'=>[123]}});
olok({'=a'=>{'=c'=>[123]}}, {'==a'=>{'==b'=>{'==d'=>2}}}
                => {'=a'=>{'=b'=>{'=d'=>2},'=c'=>[123]}});
olallok({},{a=>1},{a=>{b=>2}} => {a=>{b=>2}});

# TODO check memory match (empty overlay?)

### compose checks
#cmp_deeply(compose({},{} => {},"{} <+> {} = {}");

done_testing();
