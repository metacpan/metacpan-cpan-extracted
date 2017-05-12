use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Overlay qw(overlay overlay_all);
use FindBin;
use lib "$FindBin::Bin/inc";
use Data::Overlay::Test qw(olok dt);

# olok is overlay ok
# dt is dump terse

=for debugging
perl -Ilib -MYAML::XS -MData::Overlay -le 'print "TOP ", Dump ' -e \
    'overlay({a=>2},{a=>{"=defor"=>1}})'
=cut

# =defor
olok({a=>2},{a=>{'=defor'=>1}} => {a=>2});
olok({a=>0},{a=>{'=defor'=>1}} => {a=>0});
olok({a=>''},{a=>{'=or'=>1}} => {a=>1});
olok({a=>undef},{a=>{'=defor'=>1}} => {a=>1});
olok({a=>{b=>2}},{a=>{'=defor'=>1}} => {a=>{b=>2}});

# =or
olok({a=>2},{a=>{'=or'=>1}} => {a=>2});
olok({a=>0},{a=>{'=or'=>1}} => {a=>1});
olok({a=>''},{a=>{'=or'=>1}} => {a=>1});
olok({a=>undef},{a=>{'=or'=>1}} => {a=>1});
olok({a=>{b=>2}},{a=>{'=or'=>1}} => {a=>{b=>2}});

# =defaults
olok({a=>2},{'=defaults'=>{a=>1}} => {a=>2});
olok({a=>0},{'=defaults'=>{a=>1}} => {a=>0});
olok({a=>''},{'=defaults'=>{a=>1}} => {a=>''});
olok({a=>undef},{'=defaults'=>{a=>1}} => {a=>1});
olok({a=>{b=>2}},{'=defaults'=>{a=>1}} => {a=>{b=>2}});
olok({a=>{b=>2}},{'=defaults'=>{c=>1}} => {a=>{b=>2},c=>1});

# =push
olok({a=>[1]},{a=>{'=push'=>2}} => {a=>[1,2]});
olok({a=>[1,2]},{a=>{'=push'=>3}} => {a=>[1,2,3]});
olok({a=>[]},{a=>{'=push'=>1}} => {a=>[1]});
# scalar/non-ARRAY upgrade
olok({a=>1},{a=>{'=push'=>2}} => {a=>[1,2]});
olok({a=>{b=>2}},{a=>{'=push'=>1}} => {a=>[{b=>2},1]});
olok({a=>0},{a=>{'=push'=>1}} => {a=>[0,1]});
olok({a=>''},{a=>{'=push'=>1}} => {a=>['',1]});
olok({a=>undef}, {a=>{'=push'=>1}} => {a=>[undef,1]});
# scalar $old_ds
olok('x', {'=push'=>1} => ['x',1]);
olok('x', {'=push'=>[1,2]} => ['x',1,2]);
# multi-item pushes
olok({a=>[1]},{a=>{'=push'=>[2,3]}} => {a=>[1,2,3]});
olok({a=>[1]},{a=>{'=push'=>[[2,3]]}} => {a=>[1,[2,3]]});
olok({a=>[1]},{a=>{'=push'=>[[2],[3]]}} => {a=>[1,[2],[3]]});

# =push + =defor & =or
olok({a=>[]},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>''},{a=>{'=or'=>[],'=push'=>1}} => {a=>[1]});
olok({a=>undef},{a=>{'=defor'=>[],'=push'=>1}} => {a=>[1]});

# =pop (value doesn't matter)
olok({a=>[1,2]},{a=>{'=pop'=>''}} => {a=>[1]});
olok({a=>[1,2,3]},{a=>{'=pop'=>''}} => {a=>[1,2]});
olok({a=>[1]},{a=>{'=pop'=>'a'}} => {a=>[]});
olok({a=>[0,1]},{a=>{'=pop'=>1}} => {a=>[0]}); # no auto-downgrade
olok({a=>['',1]},{a=>{'=pop'=>1}} => {a=>['']});
olok({a=>[1,'']},{a=>{'=pop'=>1}} => {a=>[1]});
olok({a=>[undef,1]},{a=>{'=pop'=>1}} => {a=>[undef]});
olok({a=>[1,undef]},{a=>{'=pop'=>1}} => {a=>[1]});
# multi-item pops
olok({a=>[1,2,3]},{a=>{'=pop'=>[2,'*']}} => {a=>[1]});
olok({a=>[1,[2,3]]},{a=>{'=pop'=>['*']}} => {a=>[1]});
olok({a=>[1,[2],[3]]},{a=>{'=pop'=>[[2],'*']}} => {a=>[1]});
# pop too far silently leaves []
olok({a=>[1]},{a=>{'=pop'=>[2,'*']}} => {a=>[]});

# =unshift
olok({a=>[1]},{a=>{'=unshift'=>2}} => {a=>[2,1]});
olok({a=>[1,2]},{a=>{'=unshift'=>3}} => {a=>[3,1,2]});
olok({a=>[]},{a=>{'=unshift'=>1}} => {a=>[1]});
# scalar/non-ARRAY upgrade
olok({a=>1},{a=>{'=unshift'=>2}} => {a=>[2,1]});
olok({a=>{b=>2}},{a=>{'=unshift'=>1}} => {a=>[1,{b=>2}]});
olok({a=>0},{a=>{'=unshift'=>1}} => {a=>[1,0]});
olok({a=>''},{a=>{'=unshift'=>1}} => {a=>[1,'']});
olok({a=>undef}, {a=>{'=unshift'=>1}} => {a=>[1,undef]});
# scalar $old_ds
olok('x', {'=unshift'=>1} => [1,'x']);
olok('x', {'=unshift'=>[1,2]} => [1,2,'x']);
# multi-item unshiftes
olok({a=>[1]},{a=>{'=unshift'=>[2,3]}} => {a=>[2,3,1]});
olok({a=>[1]},{a=>{'=unshift'=>[[2,3]]}} => {a=>[[2,3],1]});
olok({a=>[1]},{a=>{'=unshift'=>[[2],[3]]}} => {a=>[[2],[3],1]});

# =unshift + =defor & =or
olok({a=>[]},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>0},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>''},{a=>{'=or'=>[],'=unshift'=>1}} => {a=>[1]});
olok({a=>undef},{a=>{'=defor'=>[],'=unshift'=>1}} => {a=>[1]});

# =shift (value doesn't matter)
olok({a=>[1,2]},{a=>{'=shift'=>''}} => {a=>[2]});
olok({a=>[1,2,3]},{a=>{'=shift'=>''}} => {a=>[2,3]});
olok({a=>[1]},{a=>{'=shift'=>'a'}} => {a=>[]});
olok({a=>[0,1]},{a=>{'=shift'=>1}} => {a=>[1]}); # no auto-downgrade
olok({a=>['',1]},{a=>{'=shift'=>1}} => {a=>[1]});
olok({a=>[1,'']},{a=>{'=shift'=>1}} => {a=>['']});
olok({a=>[undef,1]},{a=>{'=shift'=>1}} => {a=>[1]});
olok({a=>[1,undef]},{a=>{'=shift'=>1}} => {a=>[undef]});
# multi-item shifts
olok({a=>[1,2,3]},{a=>{'=shift'=>[2,'*']}} => {a=>[3]});
olok({a=>[1,[2,3]]},{a=>{'=shift'=>['*']}} => {a=>[[2,3]]});
olok({a=>[[1,2],3]},{a=>{'=shift'=>['*']}} => {a=>[3]});
olok({a=>[1,[2],[3]]},{a=>{'=shift'=>[[2],'*']}} => {a=>[[3]]});
olok({a=>[[1],[2],3]},{a=>{'=shift'=>[[2],'*']}} => {a=>[3]});
# shift too far silently leaves []
olok({a=>[1]},{a=>{'=shift'=>[2,'*']}} => {a=>[]});
olok({a=>[1,2]},{a=>{'=shift'=>[1,2,3]}} => {a=>[]});

# multiple array ops
olok({a=>[1]},{a=>{'=push'=>['pu','sh'], '=unshift'=>['unsh','ift'],
                   '=pop'=>['pop'],      '=shift'=>['shift']}
                } => {a=>['ift',1,'pu']});
olok({a=>[1]},{a=>{'=push'=>['push'], '=unshift'=>['unshift'],
                   '=pop'=>['pop'],   '=shift'=>['shift']}
                } => {a=>[1]});

# =config
# try config (mainly for debugging other tests, like the next)
olok(undef,{'=config' =>
                {
                    conf => { debug => 0, debug_actions => {defaults=>0} },
                    data => {'=defaults' => { a => undef },
                    }
                }
            },
            { a => undef }
            );

# all of the array and basic combining ops
olok(undef,{'=config' =>
                {
                    #conf => { debug => 1, debug_actions => {defaults=>1} },
                    conf => { debug => 0 },
                    data => {
                        '=defaults' => { a => undef },
                        a =>{'=defor'=>0, '=or'=>'or',
                            '=push'=>['pu','sh'], '=unshift'=>['unsh','ift'],
                            '=pop'=>['pop'],      '=shift'=>['shift']}
                    }
                }
            },
            {a=>['ift','or','pu']}
            );

# =run
olok({a=>1},{a=>{'=run'=>{code=>sub{[@_]}}}} => {a=>[1]});
olok({a=>1},{a=>{'=run'=>{code=>sub{[@_]}, args=>[2,3]}}} => {a=>[1,2,3]});
olok({a=>1},{a=>{'=run'=>{code=>sub{"got $_[0]"}}}} => {a=>"got 1"});
# standard last item of list behaviour
olok({a=>1},{a=>{'=run'=>{code=>sub{qw(a b c)}}}} => {a=>'c'});
# run called in scalar context
olok(undef,{'=run'=>{code=>sub{wantarray}}} => '');
olok({a=>1},{a=>{'=run'=>{code=>sub{wantarray}}}} => {a=>''});

# =foreach hash
olok({a=>1},{'=foreach'=>2} => {a=>2});
olok({a=>1},{'=foreach'=>undef} => {a=>undef});
olok({a=>1},{'=foreach'=>0} => {a=>0});
olok({a=>1},{'=foreach'=>{}} => {a=>1});
olok({a=>1,b=>0},{'=foreach'=>2} => {a=>2,b=>2});
olok({a=>1,b=>0},{'=foreach'=>{'=or'=>2}} => {a=>1,b=>2});
# =foreach array
olok([1],{'=foreach'=>2} => [2]);
olok([1],{'=foreach'=>undef} => [undef]);
olok([1],{'=foreach'=>0} => [0]);
olok([1],{'=foreach'=>{}} => [1]);
olok([0,1],{'=foreach'=>2} => [2,2]);
olok([0,1],{'=foreach'=>{'=or'=>2}} => [2,1]);

# =foreach lower level
olok({a=>{c=>[123]}},{a=>{'=foreach'=>{b=>2}}} => {a=>{c=>{b=>2}}});
olok({a=>{c=>{b=>1}}},{a=>{'=foreach'=>{b=>2}}} => {a=>{c=>{b=>2}}});
olok({a=>{c=>{d=>1}}},{a=>{'=foreach'=>{b=>2}}} => {a=>{c=>{b=>2,d=>1}}});

# =seq / all
olok({a=>1},{'=seq'=>[]} => {a=>1});
olok({a=>1},{'=seq'=>[{}]} => {a=>1});
olok({a=>1},{'=seq'=>[{a=>2}]} => {a=>2});
olok({a=>1},{'=seq'=>[{b=>2}]} => {a=>1,b=>2});
olok({a=>1},{'=seq'=>[{a=>2},{a=>3}]} => {a=>3});
olok({a=>undef},{'=seq'=>[{a=>{'=defor'=>0}},{a=>3}]} => {a=>3});
olok({a=>3},{'=seq'=>[{a=>{'=defor'=>0}},{a=>undef}]} => {a=>undef});
olok({a=>undef},{'=seq'=>[{a=>undef},{a=>{'=defor'=>0}}]} => {a=>0});
olok({a=>undef},{'=seq'=>[{a=>3},{a=>{'=defor'=>0}}]} => {a=>3});
olok({a=>undef},{'=seq'=>[{a=>{'=defor'=>0}},{a=>{'=push'=>1}}]} => {a=>[0,1]});
olok({a=>[1]},{'=seq'=>[{a=>{'=pop'=>9}},{a=>{'=push'=>2}}]} => {a=>[2]});
olok({a=>[1]},{'=seq'=>[{a=>{'=push'=>2}},{a=>{'=pop'=>9}}]} => {a=>[1]});

done_testing();
