
use strict;
use Test::More 'no_plan';
use File::Spec;

my $Per_Template_Driver_Tests = 4;

my %Expected_Output;

$Expected_Output{'one'}{'__Default__'} = <<'EOF';
--begin--
gvar1:value1
gvar2:
gvar3:value3
--end--
EOF

$Expected_Output{'one'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'one'}{'__Default__'}
</html>|;

$Expected_Output{'two'}{'__Default__'} = <<'EOF';
--begin--
path_gvar1:value1
path_gvar2:
path_gvar3:value3
--end--
EOF

$Expected_Output{'two'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'two'}{'__Default__'}
</html>|;


{
    package My::Sample::WebApp;
    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::AnyTemplate;

    use vars '@ISA';
    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('start');
        $self->run_modes([qw/start/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
            template_filename_generator => sub {
                return 'some_old_nonsense',
            },
            HTMLTemplate => {
                die_on_bad_params => 0,
            },
            HTMLTemplatePluggable => {
                die_on_bad_params => 0,
            },
            HTMLTemplateExpr => {
                die_on_bad_params => 0,
            },
        );
        $self->template('path_example')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
            template_filename_generator => sub {
                my $self     = shift;
                my $run_mode = $self->get_current_runmode;
                my $module   = ref $self;

                my @segments = split /::/, $module;

                return File::Spec->catfile(@segments, $run_mode);
            },
            HTMLTemplate => {
                die_on_bad_params => 0,
            },
            HTMLTemplatePluggable => {
                die_on_bad_params => 0,
            },
            HTMLTemplateExpr => {
                die_on_bad_params => 0,
            },
        );
    }

    sub start {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{'one'}{$driver}
                           || $Expected_Output{'one'}{'__Default__'};

        my $template = $self->template->load;
        $template->param(
            'var1' => 'value1_xxx',
            'var2' => 'value2_xxx',
            'var3' => 'value3_xxx',
            'var4' => 'value4_xxx',
            'var5' => 'value5_xxx',
            'var6' => 'value6_xxx',
        );

        $template->output;
        $template->clear_params;

        $template->param(
            'var1' => 'value1',
            'var3' => 'value3',
        );

        my $object = $template->object;

        my $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "template object ref: $ref");

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");

        # Example with generator that returns a full path
        $expected_output = $Expected_Output{'two'}{$driver}
                        || $Expected_Output{'two'}{'__Default__'};

        $template = $self->template('path_example')->load;
        $template->param(
            'var1' => 'value1_xxx',
            'var2' => 'value2_xxx',
            'var3' => 'value3_xxx',
            'var4' => 'value4_xxx',
            'var5' => 'value5_xxx',
            'var6' => 'value6_xxx',
        );

        $template->output;
        $template->clear_params;

        $template->param(
            'var1' => 'value1',
            'var3' => 'value3',
        );

        $object = $template->object;

        $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "[path] template object ref: $ref");

        $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "[path] Got expected output for driver: $driver");
        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate')) {
        My::Sample::WebApp->new(PARAMS => {
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
        My::Sample::WebApp->new(PARAMS => {
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
        My::Sample::WebApp->new(PARAMS => {
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
        My::Sample::WebApp->new(PARAMS => {
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
        My::Sample::WebApp->new(PARAMS => {
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

