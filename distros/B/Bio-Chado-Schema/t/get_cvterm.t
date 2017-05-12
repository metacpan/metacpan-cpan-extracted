use strict;
use warnings;
use FindBin;

use Test::More tests => 5;
use Test::Exception;

use lib "$FindBin::RealBin/lib";
use Bio::Chado::Schema::Test;

my $schema = Bio::Chado::Schema::Test->init_schema();
isa_ok( $schema, 'DBIx::Class::Schema' );

is $schema->get_cvterm('nonexistent:thingy'), undef, 'got undef for nonexistent cvterm';

throws_ok {
    $schema->get_cvterm_or_die('nonexistent','thing')
} qr/nonexistent thing not found/i, 'get_cvterm_or_die dies for nonexistent cvterm';


my $cvterm = $schema->resultset('Cv::Cvterm')
             ->create_with({
                 name => 'tester',
                 cv   => 'testing cv',
                 db   => 'fake db',
                 dbxref => 'fake accession',
             });

is $schema->get_cvterm('testing cv:tester')->name, 'tester', 'got the cvterm';
is $schema->get_cvterm_or_die('testing cv','tester')->name, 'tester', 'got the cvterm here also';
