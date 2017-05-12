package Audio::Filter;
use base 'Audio::Data';

package Audio::Filter::FIR;
use base 'Audio::Filter';

package Audio::Filter::AllPole;
use base 'Audio::Filter';

package Audio::Resonator;
use base 'Audio::Filter::AllPole';

sub new
{
 my $class = shift;
 my $o = $class->SUPER::new(@_);
 $o->data(1.0,0.0,0.0,0.0,0.0);
 return $o;
}

sub setpole
{
 my ($o,$f,$bw,$amp) = @_;
 my $minus_pi_t = - Audio::Data::PI() / $o->rate;
 my $two_pi_t   = -2.0 * $minus_pi_t;
 my $r   = exp($minus_pi_t * $bw);
 $c = -$r*$r;
 $b = $r * cos($two_pi_t * $f) * 2.0;
 $a = 1 - $b - $c;
 $a *= $amp if (@_ > 3);
 my @data = $o->data;
 splice(@data,0,3,$a,$b,$c);
 $o->data(@data);
 return $o;
}

package Audio::AntiResonator;
use base 'Audio::Filter::FIR';

sub new
{
 my $class = shift;
 my $o = $class->SUPER::new(@_);
 $o->data(1.0,0.0,0.0,0.0,0.0);
 return $o;
}

sub setzero
{
 my ($o,$f,$bw,) = @_;
 $o->Audio::Resonator::setpole($f,$bw);
 my @data = $o->data;
 my $a = $data[0] = 1/$data[0];
 my $b = $data[1] *= - $data[0];
 my $c = $data[2] *= - $data[0];
 $o->data(@data);
 return $o;
}

1;
__END__
