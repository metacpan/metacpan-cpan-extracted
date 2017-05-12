#!perl

# this tests the wantarray options

use strict;
use warnings;

use App::Genpass;
use Test::More tests => 6;

my $app            = App::Genpass->new;
my $password       = $app->generate(1);
my @passwords      = $app->generate(1);
my @many_passwords = $app->generate(10);
my $many_passwords = $app->generate(10);

is( ref \$password,       'SCALAR', 'single generate - scalar'   );
is( ref \@passwords,      'ARRAY',  'single generate - array'    );
is( ref \@many_passwords, 'ARRAY',  'multiple generate - array'  );
is( ref $many_passwords,  'ARRAY',  'multiple generate - scalar' );

cmp_ok( scalar @passwords,      '==',  1, 'only 1 item in single array'     );
cmp_ok( scalar @many_passwords, '==', 10, 'only 10 items in multiple array' );
