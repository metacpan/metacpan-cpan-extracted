#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test;

    plan skip_all => 'Data::FormValidator not installed'
        unless eval 'require Data::FormValidator';

    plan tests => 10;
};

use Data::FormValidator::Constraints qw(:closures);
my $schema = DBIC::Test->init_schema;
my $row;

my $profile = {
	field_filters => { 
    	name => [qw/ ucfirst /],
 	},
	required 	=> [qw/ name /],
	optional 	=> [qw/ email /],
	constraint_methods => {
        email => email(),
    },
};

DBIC::Test::Schema::Test->validation_module("Data::FormValidator");
DBIC::Test::Schema::Test->validation_profile($profile);
Class::C3->reinitialize();

$row = eval{  $schema->resultset('Test')->create({email => 'test@test.org'}) };
isa_ok $@, 'Data::FormValidator::Results', 'required fields missing';

$row = eval{ $schema->resultset('Test')->create({name => 'test', email => 'qwerty'}) };
isa_ok $@, 'Data::FormValidator::Results', 'invalid email address not accepted';

$row = eval{ $schema->resultset('Test')->create({name => 'test', email => 'test@test.org'}) };
is $row->email, 'test@test.org', 'valid data accepted';

DBIC::Test::Schema::Test->validation_filter(1);
Class::C3->reinitialize();
$row = eval{ $schema->resultset('Test')->create({name => 'test', email => 'test@test.org'}) };
is $row->name, 'Test', 'filters applied';

DBIC::Test::Schema::Test->validation_filter(0);
Class::C3->reinitialize();
$row = eval{ $schema->resultset('Test')->create({name => 'test', email => 'test@test.org'}) };
is $row->name, 'test', 'no filters applied';


SKIP: {
    skip 'DateTime not installed', 5 unless eval 'require DateTime';

    ## Create a profile that checks to make sure the email is unique in the database
   
    my $dt = DateTime->new(year=>2007);
    my $test_time = $dt->epoch;

    my $profile = sub {
        my $result = shift @_;
        return {
            required => [qw/email createts/],
            field_filters => {
                createts => sub {
                    ## We assume that stuff comes in epoch (seconds from 1970)
                    return DateTime->from_epoch( epoch => shift );
                },
            },
            constraint_methods => {
                email => sub {
                    my ($dvf, $value) = @_;
                    $dvf->name_this('email_not_unique');
                    return $result->result_source->resultset->find({email=>$value}) ? 0 : 1;
                },
            },
        };
    };

    ## Reset the profile
    DBIC::Test::Schema::Test->validation_profile($profile);
    DBIC::Test::Schema::Test->validation_filter(1);
    Class::C3->reinitialize();

    ## Create a new row with a new email.

    my $new_email_rs =  $schema->resultset('Test')->create({name => 'testA', email => 'testaa@test.org', 'createts'=> $test_time});
    is $new_email_rs->email, 'testaa@test.org', 'Created a unique Email Address';

    my $bad_rs = eval{ $schema->resultset('Test')->create({name => 'testA', email => 'testaa@test.org', 'createts'=> $test_time}) };
    isa_ok $@, 'Data::FormValidator::Results', 'Failed as expected';

    my @bad_fields  = $@->invalid;
    my $errs_msgs   = $@->invalid;

    ok($bad_fields[0] eq 'email', 'Invalid Field correctly identified');
    ok($errs_msgs->{email}->[0] eq 'email_not_unique', 'Invalid Field Message Found');
    ok($new_email_rs->createts->epoch == $test_time, "Correctly filtered inflated object");
};