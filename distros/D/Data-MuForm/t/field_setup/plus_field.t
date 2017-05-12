use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';

    with 'MyApp::Form::Role::Factors';

    has_field '+bar_one' => ( accessor => 'dimension_value_ids' );
    has_field '+bar_two' => ( accessor => 'factor_value_ids' );
}


{
    package MyApp::Form::Role::Factors;
    use Moo::Role;
    use Data::MuForm::Meta;

    has_field bar_one => ( type => 'Repeatable', required => 0 );
    has_field 'bar_one.contains' => ( type => 'Integer' );
    has_field bar_two => ( type => 'Repeatable', required => 0 );
    has_field 'bar_two.contains' => ( type => 'Integer' );
}

my $form = MyApp::Form::Test->new;
ok( $form );
is( $form->field('bar_one')->type, 'Repeatable', 'right type' );

done_testing;
