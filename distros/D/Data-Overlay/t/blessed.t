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

# blessed references are opaque
my $obj1 = bless({a=>1},'A');
my $obj2 = bless({a=>2},'B');
olok({a=>1},$obj2 => $obj2);
olok($obj1,{a=>2} => {a=>2});
olok($obj1,$obj2 => $obj2);
olok({a=>1},{a=>$obj2} => {a=>$obj2});
olok({a=>$obj1},{a=>2} => {a=>2});
olok({a=>$obj1},{a=>$obj2} => {a=>$obj2});
olok({a=>[$obj1]},{a=>{'=push'=>$obj2}} => {a=>[$obj1,$obj2]});

# TODO overloading ignored

# overlay overwrites (diff types)
olok({a=>{b=>2}},{a=>1} => {a=>1});
olok({a=>1},{a=>{b=>2}} => {a=>{b=>2}});

done_testing();
