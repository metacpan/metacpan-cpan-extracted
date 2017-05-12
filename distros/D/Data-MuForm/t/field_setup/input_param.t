use strict;
use warnings;
use Test::More;

{
    package Test::InputParam;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'base_name' => (
        type => 'Text',
        required => 1,
        input_param=> 'input_name',
    );
}

my $form1 = Test::InputParam->new;
ok( $form1, 'Created Form' );
$form1->process( params=> { input_name => 'This is a mapped input' } );
ok( $form1->validated, 'got good result' );
ok( !$form1->has_errors, 'No errors' );

$form1->process( params => { input_name => '' } );
ok( $form1->ran_validation, 'ran validation' );
ok( ! $form1->validated, 'not validated' );
ok( $form1->has_errors, 'errors for required' );


# This used to work differently in FH. The params here
# are essentially empty (because 'base_name' isn't valid for
# submitting for that field). Text fields don't force validation
# when no existing param, so it seems correct that the 'base_name'
# field isn't processed (just like it would if no param in other
# circumstances).. However, it was wrong that 'validated'
# succeeded. Fixed by unsetting ->submitted if no actual input keys.
my $form2 = Test::InputParam->new;
ok( $form2, 'Created Form' );
my %params2 = ( base_name => 'This is a mapped input' );
$form2->process(params=>\%params2);
ok( ! $form2->validated, 'got correct failing result' );
ok( ! $form2->has_errors, 'No errors' );

done_testing;
