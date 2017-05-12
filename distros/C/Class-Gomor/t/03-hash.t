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

print $new->s1.   "\n";
print $new->a1.   "\n";
print $new->{o1}. "\n";

ok(1);
