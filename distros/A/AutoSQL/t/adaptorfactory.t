use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests => 3}

use AutoSQL::AdaptorFactory;

use ContactSchema;
my $schema = ContactSchema->new;
my $factory = AutoSQL::AdaptorFactory->new(
    -schema => $schema
);

$AutoCode::Root::DEBUG=1;
use DBTestharness;
my $harness=DBTestHarness->new(
    -user => 'root',
    -drop_during_destroy=> 0
);

$harness->create_test_db;
$harness->import_tables($schema);

my $dba = $factory->get_adaptor_instance(
    -dbcontext => $harness
);


my $person_module = $factory->make_module('Person');
my $first_name = 'foooo_';
my $last_name='barr lah';

my $person = $person_module->new(
    -first_name => $first_name,
    -last_name => $last_name,
);

$dba->get_object_adaptor('Person')->store($person);
print $person->dbID ."\n";

my $new_person = $dba->get_object_adaptor('Person')->fetch_by_dbID($person->dbID);

ok $new_person->first_name, $first_name;
ok $new_person->last_name, $last_name;

my $email_package = $factory->make_module('Email');
my $email = $email_package->new(
    -address => 'foo@bar'
);

my $email_adaptor=$dba->get_object_adaptor('Email');
$email_adaptor->store($email, {-person_id=>1});

my $fetched_email=$email_adaptor->fetch_by_dbID($email->dbID);
ok $email->address, $fetched_email->address;

