use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'start_time' => ( type => 'Time' );
    has_field 'end_time' => ( type => 'Time' );

}

my $form = MyApp::Form::Test->new;
ok( $form );

$form->process( params => { start_time => '17:30', end_time => '19:00' } );
ok( $form->validated, 'form validated' );

done_testing;
