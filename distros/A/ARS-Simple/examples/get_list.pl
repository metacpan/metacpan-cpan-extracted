use strict;
use warnings FATAL => 'all';
use ARS::Simple;
use Data::Dumper;

# Get the Entry-Id of all User form records

my $ars = ARS::Simple->new({
        server   => 'dev_machine',
        user     => 'greg',
        password => 'password',
        });

my $eids = $ars->get_list({ form => 'User', query => '1=1', });

print Dumper($eids), "\n";

