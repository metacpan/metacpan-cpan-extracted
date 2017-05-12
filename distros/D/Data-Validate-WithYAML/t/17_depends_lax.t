#!perl 

use strict;
use Test::More;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test8.yml',
);


my @data = (
    { success => 1, data => { admin => "dummy" } },
    { success => 1, data => { admin => "administrator", password => "123456" } }, 
    { success => 0, data => { admin => "administrator" } },
    { success => 1, data => { password => "12355" } }, 
);

for my $entity ( @data ) {
    my $check = $entity->{success} ? {} : { password => 'Password is too short' };
    my $data  = $entity->{data};
    
    my %errors = $validator->validate( 'step1', %{$data} );
   
    my $name = join " :: ", %{$data};
    is_deeply \%errors, $check, $name;
}

done_testing();
