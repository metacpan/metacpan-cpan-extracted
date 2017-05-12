use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package MyApp::Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'name';
    has_field 'media.caption';
    has_field 'media.alt_text';
}

dies_ok( sub { my $form = MyApp::Test::Form->new; }, 'form with missing compound does not build' );

done_testing;
