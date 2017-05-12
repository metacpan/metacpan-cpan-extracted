#!/usr/bin/perl

use strict;
use Test::More 'no_plan';

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

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

        $self->mode_param('rm_foo') ;
        $self->query->param('rm_foo' => 'bubba');

        my $blank_form = qq{
            <form>
            <input name="data_var1"   value="">
            <input name="data_var2"   value="">
            <input name="param_var1"  value="">
            <input name="param_var2"  value="">
            <input name="param_var3"  value="">
            <input name="data_varA1"  value="">
            <input name="data_varA2"  value="">
            <input name="data_varB1"  value="">
            <input name="data_varB2"  value="">
            <input name="param_varA1" value="">
            <input name="param_varA2" value="">
            <input name="param_varA3" value="">
            <input name="param_varB1" value="">
            <input name="param_varB2" value="">
            <input name="param_varB3" value="">
            <input name="param_varC1" value="">
            <input name="param_varC2" value="">
            <input name="param_varC3" value="">
            <input name="rm_foo" value="original_rm">
            </form>
        };


        my %blank_form_data = map { $_ => "" } qw(
            data_var1
            data_var2
            param_var1
            param_var2
            param_var3
            data_varA1
            data_varA2
            data_varB1
            data_varB2
            param_varA1
            param_varA2
            param_varA3
            param_varB1
            param_varB2
            param_varB3
            param_varC1
            param_varC2
            param_varC3
        );
        $blank_form_data{'rm_foo'} = 'original_rm';

        # Test filling with hashref (\%data)
        my %data = (
            'data_var1' => 'value1',
            'data_var2' => 'value2',
        );

        my $html = $blank_form;

        my $output = $self->fill_form(\$html, \%data);

        my %form_data = (
            %blank_form_data,
            data_var1   => 'value1',
            data_var2   => 'value2',
        );

        form_data_ok($output, %form_data,  '[data] form data ok');

        # Test filling with object ($param_obj)
        my $param_obj = Dummy_Param->new(
            'param_var1'  => 'value1',
            'param_var2'  => 'value2',
            'param_var3'  => 'value3',
            'rm_foo'      => 'bubbles',
        );

        $html = $blank_form;
        $output = $self->fill_form(\$html, $param_obj);

        %form_data = (
            %blank_form_data,
            param_var1   => 'value1',
            param_var2   => 'value2',
            param_var3   => 'value3',
            rm_foo       => 'original_rm',
        );
        form_data_ok($output, %form_data,  '[obj] form data ok');

        # Test filling with a list (mixed data and objects)

        my $param_obj1 = Dummy_Param->new(
            'param_varA1'  => 'pvalueA1',
            'param_varA2'  => 'pvalueA2',
            'param_varA3'  => 'pvalueA3',
            'rm_foo'       => 'bubbles',
        );
        my $param_obj2 = Dummy_Param->new(
            'param_varA1'  => 'pvalueB1x',
            'param_varB1'  => 'pvalueB1',
            'param_varB2'  => 'pvalueB2',
            'param_varB3'  => 'pvalueB3',
            'rm_foo'       => 'bubbles2',
        );
        my $param_obj3 = Dummy_Param->new(
            'param_varC1'  => 'pvalueC1',
            'param_varC2'  => 'pvalueC2',
            'param_varC3'  => 'pvalueCB3',
            'rm_foo'       => 'bubbles3',
        );
        my %data1 = (
            'data_varB1' => 'dvalueA1x',
            'data_varA1' => 'dvalueA1',
            'data_varA2' => 'dvalueA2',
            'rm_foo'     => 'bubbles4',
        );
        my %data2 = (
            'data_varB1' => 'dvalue1',
            'data_varB2' => 'dvalue2',
            'rm_foo'     => 'bubbles5',
        );

        $html = $blank_form;
        $output = $self->fill_form(\$html, [$param_obj3, \%data2, \%data2, $param_obj1, $param_obj2, \%data1]);

        %form_data = (
            %blank_form_data,
            'param_varC1'  => 'pvalueC1',
            'param_varC2'  => 'pvalueC2',
            'param_varC3'  => 'pvalueCB3',
            'param_varA1'  => 'pvalueA1',
            'param_varA2'  => 'pvalueA2',
            'param_varA3'  => 'pvalueA3',
            'param_varB1'  => 'pvalueB1',
            'param_varB2'  => 'pvalueB2',
            'param_varB3'  => 'pvalueB3',
            'param_varA1'  => 'pvalueB1x',
            'data_varB1' => 'dvalue1',
            'data_varB2' => 'dvalue2',
            'data_varA1' => 'dvalueA1',
            'data_varA2' => 'dvalueA2',
            'data_varB1' => 'dvalueA1x',
            rm_foo       => 'original_rm',
        );
        SKIP:
        {
            skip "Installed HTML::FillInForm does not support ignore fields with fdat - upgrade to version 1.04", 1 if $HTML::FillInForm::VERSION < 1.04;
            form_data_ok($output, %form_data,  '[list] form data ok');
        }

        # Test filling with no data sources - should default to query, but
        # not override the run mode param ('rm_foo')

        $self->mode_param('rm_foo') ;
        $self->query->param('rm_foo'     => 'bubbles');
        $self->query->param('param_var1' => 'query_value1');

        $output = $self->fill_form(\$html);

        %form_data = (
            %blank_form_data,
            'rm_foo'      => 'original_rm',
            'param_var1'  => 'query_value1',
        );
        form_data_ok($output, %form_data,  '[none] form data ok');


    }
    sub form_data_ok {
        my $label = pop;
        my ($string_ref, %data) = @_;

        my @unmatched;
        my %matched;
        foreach my $name (keys %data) {
            if ($$string_ref =~ /name=("|')$name\1\s+value=("|')$data{$name}\2/
            or  $$string_ref =~ /value=("|')$data{$name}\1\s+name=("|')$name\2/) {
                $matched{$name} = $data{$name};
            }
            else {
                push @unmatched, $name;
            }
        }

        if (eq_hash(\%data, \%matched)) {
            ok(1, $label);
            return 1;
        }
        else {
            ok(0, $label);

            # Print out some diagnostics
            print STDERR "form output:\n$$string_ref;\n";
            if (@unmatched) {
                print STDERR "Unmatched keys: \n";
                foreach my $key (@unmatched) {
                    print STDERR "\t$key - expected: $data{$key}\n";
                }
                print STDERR "\n";
            }
            return;
        }

    }

}


WebApp->new->run;



