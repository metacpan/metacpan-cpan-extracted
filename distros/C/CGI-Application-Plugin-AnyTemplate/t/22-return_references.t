
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 6;

my %Expected_Output;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
var1:value1
var2:value2
var3:value3
--end--
EOF

$Expected_Output{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'__Default__'}
</html>|;

{
    package WebApp;
    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::AnyTemplate;

    use vars '@ISA';
    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }

    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load;
        $template->param(
            'var1' => 'value1_xxx',
            'var2' => 'value2_xxx',
            'var3' => 'value3_xxx',
            'var4' => 'value4_xxx',
            'var5' => 'value5_xxx',
            'var6' => 'value6_xxx',
        );
        $template->clear_params;

        $template->param(
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );

        my $object = $template->object;

        my $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "template object ref: $ref");

        my $output = $template->output;
        is(ref $output, 'SCALAR', "output returns reference by default");
        is($$output, $expected_output, "Got expected output for driver: $driver");


        # Now turning off return_references
        $template = $self->template->load('return_references' => undef);
        $template->param(
            'var1' => 'value1_xxx',
            'var2' => 'value2_xxx',
            'var3' => 'value3_xxx',
            'var4' => 'value4_xxx',
            'var5' => 'value5_xxx',
            'var6' => 'value6_xxx',
        );
        $template->clear_params;

        $template->param(
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );

        $object = $template->object;

        $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "template object ref: $ref");

        $output = $template->output;
        ok(!ref $output, "return_references off: output returns string");
        is($output, $expected_output, "return_references off: Got expected output for driver: $driver");
        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate')) {
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplate',
            template_engine_class => 'HTML::Template',
        })->run;
    }
    else {
        skip "HTML::Template not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('HTMLTemplateExpr')) {
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplateExpr',
            template_engine_class => 'HTML::Template::Expr',
        })->run;
    }
    else {
        skip "HTML::Template::Expr not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('TemplateToolkit')) {
        WebApp->new(PARAMS => {
            template_driver       => 'TemplateToolkit',
            template_engine_class => 'Template',
        })->run;
    }
    else {
        skip "Template::Toolkit not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('Petal')) {
        WebApp->new(PARAMS => {
            template_driver       => 'Petal',
            template_engine_class => 'Petal',
        })->run;
    }
    else {
        skip "Petal not installed", $Per_Template_Driver_Tests;
    }
}

SKIP: {
    if (test_driver_prereqs('HTMLTemplatePluggable')) {
        require HTML::Template::Plugin::Dot;
        import HTML::Template::Plugin::Dot;
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplatePluggable',
            template_engine_class => 'HTML::Template::Pluggable',
        })->run;
    }
    else {
        skip "HTML::Template::Pluggable not installed", $Per_Template_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'CGI::Application::Plugin::AnyTemplate::Driver::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    my @required_modules = $driver_module->required_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
