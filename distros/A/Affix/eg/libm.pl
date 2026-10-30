use v5.40;
use Affix;
#
say 'sqrtf(36.f) = ' . Affix::wrap( libm, 'sqrtf', [Float] => Float )->(36.0);
say 'pow(2.0, 10.0) = ' . Affix::wrap( libm, 'pow', [ Double, Double ] => Double )->( 2.0, 10.0 );
