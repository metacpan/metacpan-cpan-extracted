
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 10;

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

my %Extension = (
    HTMLTemplate          => '.html',
    HTMLTemplateExpr      => '.html',
    HTMLTemplatePluggable => '.html',
    TemplateToolkit       => '.tmpl',
    Petal                 => '.xhtml',
);

{
    package WebApp;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');
    use Test::More;
    use CGI::Application::Plugin::AnyTemplate qw/:load_tmpl/;

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple_elsewhere');
        $self->run_modes([qw/simple_elsewhere/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }

    sub simple_elsewhere {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $extension = $Extension{$driver};

        unless ($self->param('path_added_via_new')) {;
            $self->tmpl_path('t/tmpl_include');
        }

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
        $output = $$output if ref $output eq 'SCALAR';


        is($output, $expected_output, "Got expected output for driver: $driver");

        ok($extension, "extension for driver: $driver");

        $template = $self->load_tmpl(
            'simple' . $extension
        );

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
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");


        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate')) {
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplate',
            template_engine_class => 'HTML::Template',
        })->run;
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplate',
            template_engine_class => 'HTML::Template',
            path_added_via_new    => 1,
        },
        TMPL_PATH             => 't/tmpl_include',
        )->run;
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
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplateExpr',
            template_engine_class => 'HTML::Template::Expr',
            path_added_via_new    => 1,
        },
        TMPL_PATH             => 't/tmpl_include',
        )->run;
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
        WebApp->new(PARAMS => {
            template_driver       => 'TemplateToolkit',
            template_engine_class => 'Template',
            path_added_via_new    => 1,
        },
        TMPL_PATH             => 't/tmpl_include',
        )->run;
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
        WebApp->new(PARAMS => {
            template_driver       => 'Petal',
            template_engine_class => 'Petal',
            path_added_via_new    => 1,
        },
        TMPL_PATH             => 't/tmpl_include',
        )->run;
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
