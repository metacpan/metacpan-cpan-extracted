use Test;
BEGIN { plan(tests => 1) }

require Class::Gomor::Hash;
our @ISA = qw(Class::Gomor::Hash);
our @AS = qw(s1);
our @AA = qw(a1);
our @AO = qw(o1);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

my $new = __PACKAGE__->new;
$new->s1('test');
$new->a1([ 'test' ]);
$new->{o1} = 'test';

my $clone = $new->cgClone;
$clone->s1('test2');

print 'new:   '.$new->s1.   "\n";
print 'clone: '.$clone->s1. "\n";
print 'new:   '.$new->a1.   "\n";
print 'new:   '.$new->{o1}. "\n";

ok(1);
