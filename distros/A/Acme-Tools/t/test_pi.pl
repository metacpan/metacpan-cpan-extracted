use Acme::Tools;
print "$Acme::Tools::PI\n";
my $pi=bigf($PI);
my $pi_big=bigf(repl(<<'',qr/\s/));
      3.1415926535897932384626433832795028841971693993751058209749445923078
        164062862089986280348253421170679821480865132823066470938446095505822317
        253594081284811174502841027019385211055596446229489549303819644288109756
        659334461284756482337867831652712019091456485669234603486104543266482133
        936072602491412737245870066063155881748815209209628292540917153643678925
        903600113305305488204665213841469519415116094330572703657595919530921861
        173819326117931051185480744623799627495673518857527248912279381830119491
        298336733624406566430860213949463952247371907021798609437027705392171762
        931767523846748184676694051320005681271452635608277857713427577896091736
        371787214684409012249534301465495853710507922796892589235420199561121290
        219608640344181598136297747713099605187072113499999983729780499510597317
        328160963185950244594553469083026425223082533446850352619311881710100031
        378387528865875332083814206171776691473035982534904287554687311595628638
        823537875937519577818577805321712268066130019278766111959092164201989380
        952572010654858632788659361533818279682303019520353018529689957736225994
        138912497217752834791315155748572424541506959508295331168617278558890750
        983817546374649393192550604009277016711390098488240128583616035637076601
        047101819429555961989467678374494482553797747268471040475346462080466842
        590694912933136770289891521047521620569660240580381501935112533824300355
        876402474964732639141992726042699227967823547816360093417216412199245863
        150302861829745557067498385054945885869269956909272107975093029553211653
        449872027559602364806654991198818347977535663698074265425278625518184175
        746728909777727938000816470600161452491921732172147723501414419735685481


pi_bin();

sub pi_1 { #  pi = 4 sigma(0..inf) -1^k/(2k+1)
  for my $n (map 10**$_,1..18){
    my($start,$sum,$one,$e)=(time_fp(),0,bigf(-1),0);
    $sum+=($one*=-1)/(2*$_+1) for 0..$n;
    my $mypi=4*$sum;
    printf "%7d: ".("%30.25f" x 5)."  %5.2fs\n",
      $n,
      $mypi,
      $pi-$mypi,
      $pi-($mypi - 1/$n**1),
      $pi-($mypi - 1/$n**1 + 1/$n**2),
      $pi-($mypi - 1/$n**1 + 1/$n**2 - 0.75/$n**3),
      time_fp()-$start;
  }
}

sub pi_2 { # pi^2/6 = 1/1**2 + 1/2**2 + 1/3**2 + 1/4**2 ...
  for my $n (map 10**$_,0..8){
    my($start,$sum)=(time_fp(),0);
    $sum+=1/$_**2 for 1..$n;
    my $mypi=sqrt(6*$sum);
    printf "%9d: ".("%30.25f" x 2)."  %5.2fs\n",  $n, $mypi, $pi-$mypi, time_fp()-$start;
  }
}

sub pi_3 { # dart and pythagoras
    for my $n (map 10**$_,0..8){
	my($start,$s)=(time_fp(),0);
	for(1..$n){
	    my($x,$y)=(rand(),rand()); #throw dart
	    ++$s if sqrt($x*$x + $y*$y) < 1;
	}
	my $mypi=4*$s/$n;
	printf "%9d: %30.25f  %30.25f  %5.2fs\n", $n, $mypi, $pi-$mypi, time_fp()-$start;
    }
}

#use Math::BigFloat lib=>"GMP";# if !$INC{'Math/BigFloat.pm'};
sub pi_4 { # ramaputramama...
    #use Math::BigFloat ':constant';
    my @fak; $fak[$_]=$_?$fak[$_-1]*$_:bigf(1) for 0..1000; #die join("\n",@fak)."\n";
    bigscale(1000); #hm
    my $pi_bigger=Math::BigFloat->bpi(1000);
    for my $n (30..50){
	my($start,$s)=(time_fp(),bigf(0));
	for my $k (0..$n) {
	    my $kf=bigf($k);
	    $s+=  $fak[$k*4] / $fak[$k]**4
		* (1103 + 26390*$kf) / 396**($kf*4)
	}
	$s*=2*sqrt(bigf(2))/9801;
	my $mypi=1/$s;
	printf "%9d: %30.25f  %30.25f  %g %5.2fs\n", $n, $mypi, $pi_bigger-$mypi, $pi_bigger-$mypi, time_fp()-$start;
    }
}

sub pi_approx {
    my($min,$imp)=(9e9,0); $|=1;
    for my $n (1..1e7){
	my $x=int($pi*$n);
	print "$n\r" if $n%1000==0;
	for($x..$x+1){
	    my $mypi=$_/$n;
	    my $diff=abs($pi-$mypi);
	    next unless $diff<$min and $imp=$min/$diff and $min=$diff and $imp>1.1;
	    printf "%9d / %-9d  %20.15f  %20.15f  %g      improvement: %g\n", $_, $n, $mypi, $diff, $diff, $imp;
	}
    }
}

sub pi_bin_old {
    bigscale(1000); #hm
    for my $n (1..100){
	my $start=time_fp();
	my $sum=0;
	for my $i (map bigf($_),0..$n){
	    $sum += 1/16**$i * ( 4/(8*$i+1) - 2/(8*$i+4) - 1/(8*$i+5) - 1/(8*$i+6) );
	}
	my $mypi=$sum;
	my $diff=$pi_big-$mypi;
	#next unless $diff<$min and $imp=$min/$diff and $min=$diff and $imp>1.1;
	printf "%9d:  %30.25f  %30.25f  %g  %5.2f\n", $n, $mypi, $diff, $diff, time_fp()-$start;
    }
}

sub pi_bin { # http://www.experimentalmath.info/bbp-codes/bbp-alg.pdf
    bigscale(500); #hm
    my $start=time_fp();
    my $mypi=0;
    for my $i (map bigf($_), 0..300){
	$mypi += 1/16**$i * ( 4/(8*$i+1) - 2/(8*$i+4) - 1/(8*$i+5) - 1/(8*$i+6) );  #from Ferguson's PSLQ algorithm
	next if $i%10;
	my $diff=$pi_big-$mypi;
	printf "%9d:  %30.25f  %30.25f  %g  %5.2f\n", $i, $mypi, $diff, $diff, time_fp()-$start;
    }
}

__END__
@fak https://en.wikipedia.org/wiki/Factorial
Visste du at den matematiske formelen for volumet til en pizza med tykkelse a og radius z er pi z z a?
Did you know that the volume of a pizza with thickness a and radius z is pi z z a?

wget https://gmplib.org/download/misc/gmp-chudnovsky.c
sudo apt-get install libgmpv4-dev
gcc -s -Wall  -o gmp-chudnovsky gmp-chudnovsky.c -lgmp -lm

wget http://beej.us/blog/data/pi-chudnovsky-gmp/chudnovsky_c.txt; mv chudnovsky_c.txt chudnovsky.c
gcc -O2 -Wall -o chudnovsky chudnovsky.c -lgmp
time ./chudnovsky 1000     #3.141592.......... 1000 decimals in 0.004s, 10000 in 0.22s, 100000 in 42s

wget http://www.angio.net/pi/digits/pi1000000.txt
time perl -nle'print $-[0]." ".($+[0]-$-[0])." ".substr($_,$-[0],$+[0]-$-[0]) while /(\d)\1\1\1\1\1+/g' pi1000000.txt #pos of 6+ consec same decs

