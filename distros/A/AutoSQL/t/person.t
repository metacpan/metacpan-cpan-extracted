use strict;
BEGIN{
    use lib 'lib', 't/lib';
    use Test;
    plan tests => 8;
}
use Class::Inspector;

use DBTestHarness;

use ContactSchema;
my $schema=ContactSchema->new;
use AutoSQL::AdaptorFactory;
my $factory = AutoSQL::AdaptorFactory->new(-schema=>$schema);

#use JuguangWeb::Contact::Person;
$AutoCode::Root::debug=0;
my ($person_module, $email_module, $nric_module)=
map{$factory->make_module($_)}qw(Person Email NRIC);

# $person_module='JuguangWeb::Contact::Person';
my $first_name='foo';
my $last_name='bar';
my @emails=(
    $email_module->new(-address=>'foo@bar.com', -purpose=>'office'),
    $email_module->new(-address=>'foo.bar@yahoo.com')
);
my @aliases=qw(foob foobar barbar1);
my $nric = $nric_module->new(
    -no => '1234',
    -issued_date => '2000-01-01'
);
my $person = $person_module->new(
    -first_name => $first_name,
    -last_name => $last_name,
    -emails => \@emails,
    -aliases => \@aliases,
    -nric => $nric
);

ok $person->first_name, $first_name;
ok $person->last_name, $last_name;
print "Emails :\t". join("\t", map{$_->address}$person->get_emails), "\n";
print "Aliases :\t". join("\t", $person->get_aliases) ."\n";
sub db_test{
    my $harness=DBTestHarness->new(
        -user => 'root',
        -create_db => 1,
        -schema => $schema,
        -drop_during_destroy => 0
    );
    my $db=$factory->get_adaptor_instance(
        -dbcontext=>$harness
    );

    my $personAdaptor=$db->get_object_adaptor('Person');

    $personAdaptor->store($person);
    
    my $fetched_person = $personAdaptor->fetch_by_dbID($person->dbID);

    ok $fetched_person->first_name, $first_name;
    ok $fetched_person->last_name, $last_name;
    ok $fetched_person->dbID , $person->dbID;
    print $fetched_person->dbID ."\n";
    ok scalar($fetched_person->get_aliases), 3;
    my $fetched_nric=$fetched_person->nric;
    print $fetched_nric->issued_date ."\n";
    ok_nric($fetched_nric, '1234');
    my @fetched_emails=$fetched_person->get_emails;
    
    ok scalar(@fetched_emails), 2;
#    $personAdaptor->remove_by_dbID($person->dbid);
#    $personAdaptor->remove_all;
    print "Testing only_fetch\n";
    print join("\n", @{Class::Inspector->functions(ref($personAdaptor))}) ."\n"; 
    my $fn=$personAdaptor->only_fetch_first_name_by_dbID($fetched_person->dbID);
    print $fn;
}

sub ok_nric {
    my ($nric, $no, $issued_date)=@_;
    ok $nric->no, $no;
}

sub ok_email {
    my ($email, $address)=@_;
    ok $email->address, $address;
}
&db_test;

