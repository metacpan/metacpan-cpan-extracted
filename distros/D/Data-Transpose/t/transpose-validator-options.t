use strict;
use warnings;
use Test::More tests => 7;
use Data::Transpose::Validator;
use Data::Dumper;


sub create_schema  {
    my %schema = (
                  first => {
                            required => 1
                           },
                  second => {
                             required => 1
                            },
                  third => {
                            required => 1
                           },
                  fourth => {
                             required => 0
                            },
                  fifth => {
                            required => 0
                           },
                  sixth => {
                            required => 0
                           },
                 );
    return %schema
};

sub get_form {
    my $form = {
                first => 1,
                second => 2,
                third => 3,
               };
    return $form;
};


my $dtv = Data::Transpose::Validator->new(missing => "pass");



my $form = get_form();


$dtv->prepare(create_schema());
my $clean = $dtv->transpose($form);

is_deeply ($clean, $form, "Input and output match");

$dtv = Data::Transpose::Validator->new(missing => "undefine");
$dtv->prepare(create_schema());
$form = get_form();
$clean = $dtv->transpose($form);

foreach (qw/fourth fifth sixth/) {
    $form->{$_} = undef;
}

is_deeply ($clean, $form, "Input and output match with undefs");

$dtv = Data::Transpose::Validator->new(missing => "empty");
$dtv->prepare(create_schema());
$form = get_form();
$clean = $dtv->transpose($form);

foreach (qw/fourth fifth sixth/) {
    $form->{$_} = "";
}

is_deeply ($clean, $form, "Input and output match with empty strings");

print "Testing the C<unknown> option\n";
print "unknown => skip\n";

$dtv = Data::Transpose::Validator->new(unknown => "skip");
$dtv->prepare(create_schema());
$form = get_form();
# insert a new field
$form->{bogus} = 1;
# process
$clean = $dtv->transpose($form);
# remove to do the matching
delete $form->{bogus};
is_deeply($clean, $form, "Unknown values are skipped");


print "unknown => pass\n";

$dtv = Data::Transpose::Validator->new(unknown => "pass");
$dtv->prepare(create_schema());
$form = get_form();
# insert a new field
$form->{bogus} = 1;
# process
$clean = $dtv->transpose($form);
# and bogus is present
is_deeply($clean, $form, "Unknown values are passed");


print "unknown => fail\n";

$dtv = Data::Transpose::Validator->new(unknown => "fail");
$dtv->prepare(create_schema());
undef $clean;
$form = get_form();
# insert a new field
$form->{bogus} = 1;
# process
eval {
    $clean = $dtv->transpose($form);
};
ok($@, "Transpose failed $@");
ok(!$clean, "Transpose returned nothing");


# and bogus is present
# is_deeply($clean, $form, "Unknown values are skipped");


