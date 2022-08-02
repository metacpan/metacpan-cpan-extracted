use Data::Dump;
use aliased 'CXC::Number::Sequence::Ratio';
dd Ratio->new(
    soft_min => 2,
    max      => 20,
    ratio    => 1.1,
    w0       => -1
)->elements;
