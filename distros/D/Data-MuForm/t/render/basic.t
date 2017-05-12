use strict;
use warnings;
use Test::More;
use Data::MuForm::Test;


{
    {
        package Test::Form;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has '+name' => ( default => 'test_text' );
        has_field 'foo';
        has_field 'bar';
        has_field 'fix' => ( 'ra.layout' => 'lbl_wrele_err', 'ra.ewa.class' => 'fixfield' );
        has_field 'save' => ( type => 'Submit' );

    }
    my $form = Test::Form->new;
    ok( $form, 'form built' );
    $form->process;
    my $rendered = $form->render;
    my $expected =
    '<form id="test_text" method="post">
      <div>
        <label for="foo">Foo</label>
        <input type="text" name="foo" id="foo" value="" />
      </div>
      <div>
        <label for="bar">Bar</label>
        <input type="text" name="bar" id="bar" value="" />
      </div>
      <div>
        <label for="fix">Fix</label>
        <div class="fixfield">
          <input type="text" name="fix" id="fix" value="" />
        </div>
      </div>
      <input type="submit" name="save" id="save" value="Save" />
    </form>';
    is_html($rendered, $expected, 'simple form renders ok' );
}

{
    {
        package Test::Form::Compound;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has '+name' => ( default => 'test_compound' );
        has_field 'my_comp' => ( type => 'Compound', label => 'My Compound' );
        has_field 'my_comp.one';
        has_field 'my_comp.two';
    }

    my $form = Test::Form::Compound->new;
    ok( $form, 'form built' );
    $form->process;

    my $rendered = $form->render;
    my $expected =
    '<form id="test_compound" method="post">
       <div>
         <label for="my_comp">My Compound</label>
         <div>
          <label for="my_comp.one">One</label>
          <input id="my_comp.one" name="my_comp.one" type="text" value="" />
        </div>
        <div>
          <label for="my_comp.two">Two</label>
          <input id="my_comp.two" name="my_comp.two" type="text" value="" />
        </div>
      </div>
    </form>';
    is_html( $rendered, $expected, 'got expected rendering for compound' );
}

{
    {
        package Test::Form::Repeatable;
        use Moo;
        use Data::MuForm::Meta;
        extends 'Data::MuForm';

        has '+name' => ( default => 'test_rep' );
        has_field 'my_rep' => ( type => 'Repeatable', label => 'My Repeatable' );
        has_field 'my_rep.one';
        has_field 'my_rep.two';
    }

    my $form = Test::Form::Repeatable->new;
    $form->process;
    my $rendered = $form->render;
    # by default, repeatable instances are wrapped, with the class
    # 'hfh-repinst'
    my $expected =
    '<form id="test_rep" method="post">
      <div>
        <label for="my_rep">My Repeatable</label>
        <div class="repinst">
          <div>
            <label for="my_rep.0.one">One</label>
            <input id="my_rep.0.one" name="my_rep.0.one" type="text" value="" />
          </div>
          <div>
            <label for="my_rep.0.two">Two</label>
            <input id="my_rep.0.two" name="my_rep.0.two" type="text" value="" />
          </div>
        </div>
      </div>
    </form>';
    is_html( $rendered, $expected, 'got expected rendering for repeatable');
}

done_testing;
