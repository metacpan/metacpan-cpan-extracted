
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

my %Expected_Output;

$Expected_Output{'one'}{'__Default__'} = <<'EOF';
--begin--
var1:value1
var2:value2
var3:value3
--end--
EOF

$Expected_Output{'one'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'one'}{'__Default__'}
</html>|;

$Expected_Output{'two'}{'__Default__'} = <<'EOF';
--begin--
b1:bork1
b2:bork2
b3:bork3
--end--
EOF

$Expected_Output{'two'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'two'}{'__Default__'}
</html>|;

my %Template = (
    HTMLTemplateExpr      => 'simple.html',
    HTMLTemplate          => 'simple.html',
    HTMLTemplatePluggable => 'simple.html',
    Petal                 => 'simple.xhtml',
    TemplateToolkit       => 'simple.tmpl',
);



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
        $self->start_mode('runmode');
        $self->run_modes([qw/runmode/]);

        $self->template('one')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
            auto_add_template_extension => 0,
        );
        $self->template('two')->config(
            include_paths => 't/tmpl',
            auto_add_template_extension => 1,
            TemplateToolkit => {
                template_extension => '.bork',
            },
            HTMLTemplate => {
                template_extension => '.bork',
            },
            HTMLTemplatePluggable => {
                template_extension => '.bork',
            },
            HTMLTemplateExpr => {
                template_extension => '.ext_HTMLTemplate',
            },
            Petal => {
                template_extension => '.bork',
            },
        );
    }

    sub runmode {
        my $self = shift;

        my $driver = $self->param('template_driver');

        # named config 'one'
        my $expected_output = $Expected_Output{'one'}{$driver}
                           || $Expected_Output{'one'}{'__Default__'};

        my $template = $self->template('one')->load($Template{$driver});

        $template->param(
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");

        # named config 'two'
        $expected_output = $Expected_Output{'two'}{$driver}
                           || $Expected_Output{'two'}{'__Default__'};

        $template = $self->template('two')->load(
            type => $self->param('template_driver'),
            file => 'test',
            TemplateToolkit => {
                template_extension => '.ext_TemplateToolkit',
            },
            HTMLTemplate => {
                template_extension => '.ext_HTMLTemplate',
            },
            HTMLTemplateExpr => {
            },
            HTMLTemplatePluggable => {
                template_extension => '.ext_HTMLTemplate',
            },
            Petal => {
                template_extension => '.ext_Petal',
            },

        );

        $template->param(
            'var1' => 'bork1',
            'var2' => 'bork2',
            'var3' => 'bork3',
        );

        $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");

        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate')) {
        WebApp->new(PARAMS => { template_driver => 'HTMLTemplate' })->run;
    }
    else {
        skip "HTML::Template not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('HTMLTemplateExpr')) {
        WebApp->new(PARAMS => { template_driver => 'HTMLTemplateExpr' })->run;
    }
    else {
        skip "HTML::Template::Expr not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('TemplateToolkit')) {
        WebApp->new(PARAMS => { template_driver => 'TemplateToolkit' })->run;
    }
    else {
        skip "Template::Toolkit not installed", $Per_Template_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('Petal')) {
        WebApp->new(PARAMS => { template_driver => 'Petal' })->run;
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
