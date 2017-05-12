use strict;
use warnings;
use Test::More;

    # A 'transform_input_to_value' method changes the format of the value used by validation
    # A 'transform_value_to_fif' method changes the format of the fill-in-form string

    #    These two are "conveniences" for munging data passed in and out of a form
    #    The same effect could be achieved by modifying the value in the init_values or model
    #        before passing it in, and modifying it once returned, so it's primarily
    #        useful for database rows.
    #
    # A 'transform_value_to_fif' method changes the 'value' retrieved from a default source
    #     (default, init_values, model)
    # A 'transform_value_after_validation'  method changes the format of the value available after validation


# transform_input_to_value
{
  {
      package MyApp::Form::Test1;
      use Moo;
      use Data::MuForm::Meta;
      extends 'Data::MuForm';

      has_field 'foo' => (
          type => 'Text',
          transform_input_to_value => sub { 'foo transformed' },
      );
      has_field 'bar' => (
          type => 'Text',
          transform_input_to_value => *transform_bar,
      );
      sub transform_bar { 'bar transformed' }

  }

  my $form = MyApp::Form::Test1->new;
  ok( $form );

  my $params = { foo => 'foo', bar => 'bar' };
  $form->process( params => $params );

  is ( $form->field('foo')->value, 'foo transformed', 'foo value was transformed' );
  is ( $form->field('bar')->value, 'bar transformed', 'bar value was transformed' );
}

# transform_param_to_input
{
  {
      package MyApp::Form::Test2;
      use Moo;
      use Data::MuForm::Meta;
      extends 'Data::MuForm';

      has_field 'foo' => (
          type => 'Text',
          transform_param_to_input => sub { 'foo transformed' },
      );
      has_field 'bar' => (
          type => 'Text',
          transform_param_to_input => *transform_bar,
      );
      sub transform_bar { 'bar transformed' }

  }

  my $form = MyApp::Form::Test2->new;
  ok( $form );

  my $params = { foo => 'foo', bar => 'bar' };
  $form->process( params => $params );

  is ( $form->field('foo')->value, 'foo transformed', 'foo value was transformed' );
  is ( $form->field('foo')->fif, 'foo transformed', 'foo fif was transformed' );

  is ( $form->field('bar')->value, 'bar transformed', 'bar value was transformed' );
  is ( $form->field('bar')->fif, 'bar transformed', 'bar fif was transformed' );
}

# transform_default_to_value
{
  {
      package MyApp::Form::Test3;
      use Moo;
      use Data::MuForm::Meta;
      extends 'Data::MuForm';

      has_field 'foo' => (
          type => 'Text',
          transform_default_to_value => sub { 'foo transformed' },
      );
      has_field 'bar' => (
          type => 'Text',
          transform_default_to_value => *transform_bar,
      );
      sub transform_bar { 'bar transformed' }

  }

  my $form = MyApp::Form::Test3->new;
  ok( $form );

  my $params = { foo => 'foo', bar => 'bar' };
  $form->process( params => {}, init_values => { foo => 'foo', bar => 'bar' } );

  is ( $form->field('foo')->value, 'foo transformed', 'foo value was transformed' );
  is ( $form->field('foo')->fif, 'foo transformed', 'foo fif was transformed' );

  is ( $form->field('bar')->value, 'bar transformed', 'bar value was transformed' );
  is ( $form->field('bar')->fif, 'bar transformed', 'bar fif was transformed' );
}

# transform_value_after_validate
{
  {
      package MyApp::Form::Test4;
      use Moo;
      use Data::MuForm::Meta;
      extends 'Data::MuForm';

      has_field 'foo' => (
          type => 'Text',
          transform_value_after_validate => sub { 'foo transformed' },
      );
      has_field 'bar' => (
          type => 'Text',
          transform_value_after_validate => *transform_bar,
      );
      sub transform_bar { 'bar transformed' }

  }

  my $form = MyApp::Form::Test4->new;
  ok( $form );

  my $params = { foo => 'foo', bar => 'bar' };
  $form->process( params => $params );

  is ( $form->field('foo')->value, 'foo transformed', 'foo value was transformed' );
  is ( $form->field('foo')->fif, 'foo', 'foo fif was not transformed' );

  is ( $form->field('bar')->value, 'bar transformed', 'bar value was transformed' );
  is ( $form->field('bar')->fif, 'bar', 'bar fif was not transformed' );
}

{
    # plain field with no inflation or deflation
    {
        package Test::Form1;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo';
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'fromparams';
        }
    }
    my $form = Test::Form1->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, $init_obj, 'fif matches init_values' );
    is_deeply( $form->value, $init_obj, 'value matches init_values' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, $params, 'value matches params' );
}

{
    # field with only 'transform_input_to_value'
    {
        package Test::Form2;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_input_to_value => *inflate_foo );
        sub inflate_foo { 'inflatedfoo' }
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'inflatedfoo';
        }
    }

    my $form = Test::Form2->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, $init_obj, 'fif matches init_values' );
    is_deeply( $form->value, $init_obj, 'value matches init_values' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, { foo => 'inflatedfoo' }, 'value is inflated' );
}

{
    # field with 'transform_value_to_fif'
    {
        package Test::Form3;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_value_to_fif => *deflate_foo );
        sub deflate_foo { 'deflatedfoo' }
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'fromparams';
        }
    }
    my $form = Test::Form3->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, { foo => 'deflatedfoo' }, 'fif is deflated foo' );
    is_deeply( $form->value, { foo => 'initialfoo' }, 'value is initial foo' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, $params, 'value matches params' );
}


{
    # field with 'transform_input_to_value' and 'transform_value_to_fif'
    {
        package Test::Form5;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_input_to_value => *inflate_foo, transform_value_to_fif => *deflate_foo );
        sub inflate_foo { 'inflatedfoo' }
        sub deflate_foo { 'deflatedfoo' }
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'inflatedfoo';
        }
    }

    my $form = Test::Form5->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, { foo => 'deflatedfoo' }, 'fif is deflated' );
    is_deeply( $form->value, $init_obj, 'value is initial' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, { foo => 'inflatedfoo' }, 'value is inflated' );
}

{
    # field with only 'transform_default_to_value'
    {
        package Test::Form6;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_default_to_value => sub { 'infl_def_foo' } );
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'fromparams';
        }
    }
    my $form = Test::Form6->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, { foo => 'infl_def_foo' }, 'fif matches inflate_default' );
    is_deeply( $form->value, { foo => 'infl_def_foo' }, 'value matches init_values' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, $params, 'value matches params' );
}


{
    # field with only a 'transform_value_after_validate' method
    {
        package Test::Form7;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_value_after_validate => sub { 'defl_val_foo' } );
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'fromparams';
        }
    }
    my $form = Test::Form7->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, $init_obj, 'fif matches init_values' );
    is_deeply( $form->value, $init_obj, 'value matches init_values' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, { foo => 'defl_val_foo' }, 'value is deflated by deflate_value' );
}


{
    # field with 'transform_default_to_value' and a 'transform_value_after_validate' method
    {
        package Test::Form8;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has_field 'foo' => ( transform_default_to_value => sub { 'infl_def_foo' },
                             transform_value_after_validate => sub { 'defl_val_foo' } );
        sub validate_foo {
            my ( $self, $field ) = @_;
            $self->add_error unless $field->value eq 'fromparams';
        }
    }
    my $form = Test::Form8->new;
    my $init_obj = { foo => 'initialfoo' };
    my $params = { foo => 'fromparams' };
    $form->process( init_values => $init_obj, params => {} );
    is_deeply( $form->fif, { foo => 'infl_def_foo' }, 'fif matches init_values' );
    is_deeply( $form->value, { foo => 'infl_def_foo' }, 'value matches init_values' );
    $form->process( init_values => $init_obj, params => $params );
    ok( $form->validated, 'form validated' );
    is_deeply( $form->fif, $params, 'fif matches params' );
    is_deeply( $form->value, { foo => 'defl_val_foo' }, 'value from deflate_value' );
}

done_testing;
