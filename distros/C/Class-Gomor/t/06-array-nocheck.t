use Test;
BEGIN { plan(tests => 1) }

require Class::Gomor::Array;
$Class::Gomor::NoCheck++;
print $Class::Gomor::NoCheck."\n";
our @ISA = qw(Class::Gomor::Array);
our @AS = qw(s1);
our @AA = qw(a1);
our @AO = qw(o1);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

my $new = __PACKAGE__->new(
   s1 => 'testS1a',
   a1 => [ 'testA1s' ],
);
#$new->s1('testS1');
#$new->a1([ 'testA1' ]);
no strict 'refs';
$new->[$new->cgGetIndice('o1')] = 'testO1';

print "@{[$new->s1]}\n";
print "@{[$new->a1]}\n";
print $new->[$new->cgGetIndice('o1')]. "\n";

ok(1);
