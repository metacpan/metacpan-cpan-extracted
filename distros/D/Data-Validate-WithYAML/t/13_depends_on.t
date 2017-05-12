#!perl 

use strict;
use Test::More tests => 10;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test5.yml',
);


my @data = (
    { pass3 => { admin => "superuser", success => 1 } },
    { pass3 => { admin => "root", success => 0 } },
    { pass3 => { admin => "administrator", success => 0 } },
    { password123 => { admin => "superuser", success => 1 } },
    { password123 => { admin => "root", success => 0 } },
    { password123 => { admin => "administrator", success => 1 } },
    { password12345678 => { admin => "administrator", success => 1 } },
    { password12345678 => { admin => "root", success => 1 } },
    { password12345678 => { admin => "superuser", success => 1 } },
);

for my $entity ( @data ) {
    my ($pwd) = keys %{$entity};
    my $check = $entity->{$pwd}->{success} ? {} : { password => 'Password is too short' };
    my $admin = $entity->{$pwd}->{admin};
    
    my %errors = $validator->validate(
        'step1',
        age2     => 20,
        admin    => $admin,
        password => $pwd,
    );
    
    is_deeply \%errors, $check, "Check $admin -> $pwd";
}
