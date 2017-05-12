#!/usr/bin/perl

# This test tests that the arguments are correctly
# passed from CAP::FiF to H::FiF
# To do this we create a mock H::FiF object

use strict;
use Test::More 'no_plan';
$ENV{'CGI_APP_RETURN_ONLY'} = 1;

my $FiF_Fill_Args;

{

    # Create a dummy HTML::FillInForm object by
    # loading it and then clobbering its new and fill methods with
    # methods of our own

    use HTML::FillInForm;

    package HTML::FillInForm;
    no warnings;

    sub new {
        my $class = shift;
        return bless {};
    }

    sub fill {
        my $self = shift;
        $FiF_Fill_Args = \@_;
    }

}

{
    package Dummy_Param;
    sub new {
        my $class = shift;
        my %data = @_;
        return bless \%data, $class;
    }

    sub param {
        my $self = shift;
        if (@_) {
            return unless exists $self->{$_[0]};
            return $self->{$_[0]};
        }
        else {
            return keys %$self;
        }
    }
}


{
    package WebApp;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::FillInForm qw/fill_form/;

    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->run_modes(['start']);
    }

    sub start {
        my $self = shift;

        my $html = 'test html';
        my (%fif_params);

        $self->mode_param('rm_bar') ;
        $self->query->param('rm_bar' => 'bubba');

        # Test filling with hashref (\%data)
        my %data = (
            'data_var1' => 'value1',
            'data_var2' => 'value2',
        );
        my %options = (
            'dopt1' => 'doptvalue1',
            'dopt2' => 'doptvalue2',
        );

        $self->fill_form(\$html, \%data, %options);
        %fif_params = @$FiF_Fill_Args;

        my $fdat          = delete $fif_params{'fdat'};
        my $ignore_fields = delete $fif_params{'ignore_fields'};

        ok(eq_hash($fdat, \%data),                        '[data] fdat');
        ok(eq_array($ignore_fields, ['rm_bar']),          '[obj] ignore_fields ');
        is(delete $fif_params{'scalarref'}, \$html,       '[data] scalarref');
        is(delete $fif_params{'dopt1'},     'doptvalue1', '[data] dopt1');
        is(delete $fif_params{'dopt2'},     'doptvalue2', '[data] dopt2');
        ok(!keys  %fif_params,                            '[data] no params unaccounted for');


        # Same, but use a reference to the reference of the input $html
        %data = (
            'data_var1' => 'value1',
            'data_var2' => 'value2',
        );
        %options = (
            'dopt1' => 'doptvalue1',
            'dopt2' => 'doptvalue2',
        );

        my $html_ref = \$html;
        $self->fill_form(\$html_ref, \%data, %options);
        %fif_params = @$FiF_Fill_Args;

        $fdat          = delete $fif_params{'fdat'};
        $ignore_fields = delete $fif_params{'ignore_fields'};

        ok(eq_hash($fdat, \%data),                        '[data (html ref)] fdat');
        ok(eq_array($ignore_fields, ['rm_bar']),          '[obj (html ref)] ignore_fields ');
        is(delete $fif_params{'scalarref'}, \$html,       '[data (html ref)] scalarref');
        is(delete $fif_params{'dopt1'},     'doptvalue1', '[data (html ref)] dopt1');
        is(delete $fif_params{'dopt2'},     'doptvalue2', '[data (html ref)] dopt2');
        ok(!keys  %fif_params,                            '[data (html ref)] no params unaccounted for');



        # Test filling with object ($param_obj)
        my $param_obj = Dummy_Param->new(
            'param_var1'  => 'value1',
            'param_var2'  => 'value2',
            'param_var3'  => 'value3',
        );
        %options = (
            'popt1' => 'poptvalue1',
            'popt2' => 'poptvalue2',
        );


        $self->fill_form(\$html, $param_obj, %options);
        %fif_params = @$FiF_Fill_Args;

        my $fobject    = delete $fif_params{'fobject'};
        $ignore_fields = delete $fif_params{'ignore_fields'};
        $fobject       = $fobject->[0] if ref $fobject eq 'ARRAY';

        is(delete $fif_params{'scalarref'}, \$html,       '[obj] scalarref');
        is($fobject,                        $param_obj,   '[obj] fobj');
        ok(eq_array($ignore_fields, ['rm_bar']),          '[obj] ignore_fields ');
        is(delete $fif_params{'popt1'},     'poptvalue1', '[obj] popt1');
        is(delete $fif_params{'popt2'},     'poptvalue2', '[obj] popt2');
        ok(!keys  %fif_params,                            '[obj] no params unaccounted for');


        # Test filling with a list (mixed data and objects)
        my $param_obj1 = Dummy_Param->new(
            'param_varA1'  => 'valueA1',
            'param_varA2'  => 'valueA2',
            'param_varA3'  => 'valueA3',
        );
        my $param_obj2 = Dummy_Param->new(
            'param_varB1'  => 'valueB1',
            'param_varB2'  => 'valueB2',
            'param_varB3'  => 'valueB3',
        );
        my $param_obj3 = Dummy_Param->new(
            'param_varA1'  => 'valueC1x',
            'param_varC1'  => 'valueC1',
            'param_varC2'  => 'valueC2',
            'param_varC3'  => 'valueC3',
        );
        my %data1 = (
            'data_varB1' => 'valueA1x',
            'data_varA1' => 'valueA1',
            'data_varA2' => 'valueA2',
        );
        my %data2 = (
            'data_varB1' => 'valueB1',
            'data_varB2' => 'valueB2',
        );

        %options = (
            'lopt1' => 'loptvalue1',
            'lopt2' => 'loptvalue2',
        );

        $self->fill_form(\$html, [$param_obj3, \%data2, \%data2, $param_obj1, $param_obj2, \%data1], %options);
        %fif_params = @$FiF_Fill_Args;

        $fobject       = delete $fif_params{'fobject'};
        $fdat          = delete $fif_params{'fdat'};
        $ignore_fields = delete $fif_params{'ignore_fields'};

        ok(eq_array($fobject, [$param_obj3, $param_obj1, $param_obj2]), '[list] fobject list');
        ok(eq_hash($fdat,  {%data2, %data1}),             '[list] fdat merged hash');
        ok(eq_array($ignore_fields, ['rm_bar']),          '[obj] ignore_fields ');

        is(delete $fif_params{'scalarref'}, \$html,       '[list] scalarref');
        is(delete $fif_params{'lopt1'},     'loptvalue1', '[list] lopt1');
        is(delete $fif_params{'lopt2'},     'loptvalue2', '[list] lopt2');
        ok(!keys  %fif_params,                            '[list] no params unaccounted for');


        # Test filling with no data sources - should default to query, but
        # not override the run mode param ('rm_foo')
        $self->mode_param('rm_foo') ;
        $self->query->param('rm_foo' => 'bubbles');
        $self->fill_form(\$html);
        %fif_params = @$FiF_Fill_Args;

        $fobject          = delete $fif_params{'fobject'};
        $fdat             = delete $fif_params{'fdat'};
        $ignore_fields    = delete $fif_params{'ignore_fields'};

        ok(eq_array($fobject,       $self->query),        '[none] fobject is query');
        ok(eq_array($ignore_fields, ['rm_foo']),          '[none] ignore_fields');

        is(delete $fif_params{'scalarref'},     \$html,   '[none] scalarref');
        ok(!keys  %fif_params,                            '[none] no params unaccounted for');

    }

}


WebApp->new->run;


