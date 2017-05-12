use strict;
use warnings;

use Test::More;
use Data::Dumper;

my $tests = [
 [ {'foreign.group_id' => 'self.global_role_id'},'global_role_id'],
 [ {'foreign.group_id' => 'global_role_id'},'global_role_id'],
 [ {'foreign.group_id' => 'foreign.group_id','foreign.group_id' => 'global_role_id'},'global_role_id'],
];

sub fields {
    my $cond = shift;
    
    #my @conditions = %{$cond};
    
    my @self_fields = map { /(\w+)$/; $1 } grep { /^(self\.|)(\w+)$/ } %{$cond};
    print '@self_fields: ',Dumper(@self_fields),"\n";
    return $self_fields[0]; 
}

for my $test (@$tests) {
  is(fields($test->[0]),$test->[1]);    
}

done_testing;
