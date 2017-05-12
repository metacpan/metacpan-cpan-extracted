# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################


use Test;
BEGIN { plan tests => 12 };
use Bit::FlipFlop;
msg ('Loading module');
ok(1); # If we made it this far, we're ok.

#########################


msg ('Creating a flip flop');
my $ff = Bit::FlipFlop->new(set => sub{/start/}, 
                            reset => sub{/stop/});

ok(ref($ff),'Bit::FlipFlop'); # made an object

my $fff = Bit::FlipFlop->new(set => sub{/start/},
                             reset => sub{/stop/},
                             simultaneous_edges=>0);

my %tr;

while (<DATA>) {
  my $ddr  = /start/ ..  /stop/;
  my $dddr = /start/ ... /stop/;
  $ff->test; $fff->test;

# .. state switching
  $tr{ddr} .= $_ if $ddr;
  $tr{ffr} .= $_ if $ff->state;

# ... state switching
  $tr{dddr} .= $_ if $dddr;
  $tr{fffr} .= $_ if $fff->state;

# .. lead edge
  $tr{ddl} .= $_ if $ddr==1;
  $tr{ffl} .= $_ if $ff->lead_edge;

# ... lead edge
  $tr{dddl} .= $_ if $dddr==1;
  $tr{fffl} .= $_ if $fff->lead_edge;

# .. trail edge
  $tr{ddt} .= $_ if $ddr=~/E/;
  $tr{fft} .= $_ if $ff->trail_edge;

# ... trail edge
  $tr{dddt} .= $_ if $dddr=~/E/;
  $tr{ffft} .= $_ if $fff->trail_edge;

# .. series
  $tr{dds} .= +$ddr;
  $tr{ffs} .= $ff->series;

# ... series
  $tr{ddds} .= +$dddr;
  $tr{fffs} .= $fff->series;

# .. next_test
  $tr{ddn} .= $ddr&&$ddr!~/E/?'reset':'set';
  $tr{ffn} .= $ff->next_test;

# ... next_test
  $tr{dddn} .= $dddr&&$dddr!~/E/?'reset':'set';
  $tr{fffn} .= $fff->next_test;

}

msg('.. state switching');
ok($tr{ffr},$tr{ddr});

msg('... state switching');
ok($tr{fffr},$tr{dddr});

msg('.. leading edge');
ok($tr{ffl},$tr{ddl});

msg('... leading edge');
ok($tr{fffl},$tr{dddl});

msg('.. trailing edge');
ok($tr{fft},$tr{ddt});

msg('... trailing edge');
ok($tr{ffft},$tr{dddt});

msg('.. series');
ok($tr{ffs},$tr{dds});

msg('... series');
ok($tr{fffs},$tr{ddds});

msg('.. next_test');
ok($tr{ffn},$tr{ddn});

msg('... next_test');
ok($tr{fffn},$tr{dddn});

# end of tests
#############

sub msg {
  printf '%22s : ',$_[0];
}


__DATA__
1  outside
2  start
3  inside
4  stop
5  outside
6  start inside stop 
7  outside or in?
8  stop (... only)
9  start
10 inside
11 stop
