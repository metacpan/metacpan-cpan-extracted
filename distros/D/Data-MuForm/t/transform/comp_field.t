use strict;
use warnings;
use Test::More;

# This demonstrates a field that comes in as a single string from
# defaults/init_values/model, and is split up into multiple subfields,
# then is flattened again into a string.
#

{
    package Test::Field;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm::Field::Compound';

    has_field 'one';
    has_field 'two';
    has_field 'three';
    has '+transform_default_to_value' => ( default => sub { *default_to_value } );
    has '+transform_value_after_validate' => ( default => sub { *value_after_validate } );

    sub default_to_value {
        my ( $self, $value ) = @_;
        my %hash = split(/-/, $value);
        return \%hash;
    }
    sub value_after_validate {
        my ( $self, $value ) = @_;
        my $string = 'one-' . $value->{one};
        $string .= '-two-' . $value->{two};
        $string .= '-three-' . $value->{three};
        return $string;
    }
}
{
    package Test::Deflate;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => '+Test::Field' );
    has_field 'bar';
    sub validate_foo {
        my ( $self, $field ) = @_;
        my $value = $field->value;
        unless ( ref $value eq 'HASH' ) {
            $self->add_error('wrong value');
        }
    }
}

my $form = Test::Deflate->new;
ok( $form, 'form builds' );
my $init_values = { foo => 'one-1-two-2-three-3', bar => 'xxyyzz' };
$form->process( init_values => $init_values, params => {} );
is_deeply( $form->value, { foo => { one => 1, two => 2, three => 3 },
        bar => 'xxyyzz' }, 'value is correct?' );
is_deeply( $form->fif, { 'foo.one' => 1, 'foo.two' => 2, 'foo.three' => 3, bar => 'xxyyzz' },
    'fif is correct' );

my $fif =  { bar => 'aabbcc', 'foo.one' => 'x', 'foo.two' => 'xx', 'foo.three' => 'xxx' };
$form->process( params => $fif );
ok( $form->validated, 'form validated' );
is_deeply( $form->value, { bar => 'aabbcc', foo => 'one-x-two-xx-three-xxx' }, 'right value' );
is_deeply( $form->fif, $fif, 'right fif' );
is( $form->field('foo.one')->fif, 'x', 'correct fif' );
is( $form->field('foo')->value, 'one-x-two-xx-three-xxx', 'right value for foo field' );

{
    package Test::RepDeflate;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Repeatable' );
    has_field 'foo.contains' => ( type => '+Test::Field' );
    has_field 'bar';
    sub validate_foo {
        my ( $self, $field ) = @_;
        my $value = $field->value;
        unless ( ref $value eq 'ARRAY' ) {
            $self->add_error('wrong value');
        }
    }
}

$form = Test::RepDeflate->new;
$init_values = { foo => ['one-1-two-2-three-3', 'one-10-two-11-three-12'], bar => 'xxyyzz' };
$form->process( init_values => $init_values, params => {} );
is_deeply( $form->value, { foo => [ { one => 1, two => 2, three => 3 }, { one => 10, two => 11, three => 12 } ],
        bar => 'xxyyzz' }, 'value is correct?' );
is_deeply( $form->fif, { 'foo.0.one' => 1, 'foo.0.two' => 2, 'foo.0.three' => 3,
             'foo.1.one' => 10, 'foo.1.two' => 11, 'foo.1.three' => 12, bar => 'xxyyzz' },
    'fif is correct' );

done_testing;
