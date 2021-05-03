use Data::Dump;
use aliased 'CXC::Number::Sequence::Linear';
dd Linear->new( min => 5.1,
                max => 8,
                spacing => 1,
                align => [ 0, 0.5 ],
              )->elements;
