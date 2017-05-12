use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'bar';
    has_field 'duh' => ( trim => \&my_trim );
    sub my_trim {
        my $string = shift;
        $string = uc($string);
        return $string;
    }
    has_field 'doh' => ( trim => sub { uc(shift) } )

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = {
    foo => '  myfoo ',
    bar => "\nbar\n",
    duh => 'falalal',
    doh => 'mememe',
};

$form->process( params => $params );
is( $form->field('foo')->value, 'myfoo', 'correct trimmed foo' );
is( $form->field('bar')->value, 'bar', 'correct trimmed bar' );
is( $form->field('duh')->value, 'FALALAL', 'correct trimmed duh' );
is( $form->field('doh')->value, 'MEMEME', 'correct trimmed doh' );

done_testing;
