Co-workers often ask me, what is faster. This or this?

Of course you can benchmark the real speed, 
but theoretically you can look at the optrees and predict what will be faster.

E.g. accessing hash keys directly:  
    $h->{k}           helem rv2hv rv2sv
vs a reference to the value:
    $v = \$h->{k}     rv2sv padsv

If this is in a tight loop, and you want to change a lot of hash elems, 
the answer will be interesting.

    $ alias p=perl
    $ p -MO=Concise -e'$h={1=>0}; $h->{1}++; print $h->{1}'
vs
    $ p -MO=Concise -e'$h={1=>0};my $x=\$h->{1}; $$x++; print $h->{1}, $$x'
    
1st variant directly: (helem rv2hv rv2sv)
    
    p  <@> leave[t1] vKP/REFC ->(end)
    1     <0> enter ->2
    2     <;> nextstate(main 1 -e:1) v ->3
    9     <2> sassign vKS/2 ->a
    7        <1> srefgen sK/1 ->8
    -           <1> ex-list lKRM ->7
    6              <@> anonhash sKRM/1 ->7
    3                 <0> pushmark s ->4
    4                 <$> const(IV 1) s ->5
    5                 <$> const(IV 0) s ->6
    -        <1> ex-rv2sv sKRM*/1 ->9
    8           <$> gvsv(*h) s ->9
    a     <;> nextstate(main 1 -e:1) v ->b
    g     <1> preinc[t2] vK/1 ->h
    f        <2> helem sKRM/2 ->g
    d           <1> rv2hv[t1] sKR/1 ->e
    c              <1> rv2sv sKM/DREFHV,1 ->d
    b                 <$> gv(*h) s ->c
    e           <$> const(IV 1) s ->f
    h     <;> nextstate(main 1 -e:1) v ->i
    o     <@> print vK ->p
    i        <0> pushmark s ->j
    n        <2> helem sK/2 ->o
    l           <1> rv2hv[t3] sKR/1 ->m
    k              <1> rv2sv sKM/DREFHV,1 ->l
    j                 <$> gv(*h) s ->k
    m           <$> const(IV 1) s ->n
    
    
2nd variant by ref: (rv2sv padsv)
    
    x  <@> leave[$x:1,end] vKP/REFC ->(end)
    1     <0> enter ->2
    2     <;> nextstate(main 1 -e:1) v ->3
    9     <2> sassign vKS/2 ->a
    7        <1> srefgen sK/1 ->8
    -           <1> ex-list lKRM ->7
    6              <@> anonhash sKRM/1 ->7
    3                 <0> pushmark s ->4
    4                 <$> const(IV 1) s ->5
    5                 <$> const(IV 0) s ->6
    -        <1> ex-rv2sv sKRM*/1 ->9
    8           <$> gvsv(*h) s ->9
    a     <;> nextstate(main 1 -e:1) v ->b
    i     <2> sassign vKS/2 ->j
    g        <1> srefgen sK/1 ->h
    -           <1> ex-list lKRM ->g
    f              <2> helem sKRM/2 ->g
    d                 <1> rv2hv[t2] sKR/1 ->e
    c                    <1> rv2sv sKM/DREFHV,1 ->d
    b                       <$> gv(*h) s ->c
    e                 <$> const(IV 1) s ->f
    h        <0> padsv[$x:1,end] sRM*/LVINTRO ->i
    j     <;> nextstate(main 2 -e:1) v ->k
    m     <1> preinc[t3] vK/1 ->n
    l        <1> rv2sv sKRM/1 ->m
    k           <0> padsv[$x:1,end] sM/96 ->l
    n     <;> nextstate(main 2 -e:1) v ->o
    w     <@> print vK ->x
    o        <0> pushmark s ->p
    t        <2> helem sK/2 ->u
    r           <1> rv2hv[t4] sKR/1 ->s
    q              <1> rv2sv sKM/DREFHV,1 ->r
    p                 <$> gv(*h) s ->q
    s           <$> const(IV 1) s ->t
    v        <1> rv2sv sK/1 ->w
    u           <0> padsv[$x:1,end] s ->v

This leads to the idea of writing a B or Devel module, like B::Speed, or Devel::Speed, similar to B::Stats or Devel::Size, which will apply a costmodel to each op, for its run-time costs, and return a number, how fast will this be at run-time.
Or just an option for B::Stats, which counts the ops at compile-,end- and run-time.

Every compiler optimization step needs to know about the costs for each op, 
so it could be useful for B::CC.
The numbers can be taken from profiled code, or dtrace probes.

    p -MB::Stats -e'$h={1=>0}; $h->{1}++; print $h->{1}'
vs  
    p -MB::Stats -e'$h={1=>0};my $x=\$h->{1}; $$x++; print $$x'

