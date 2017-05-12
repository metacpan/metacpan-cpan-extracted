
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

my %Expected_Output;

$Expected_Output{'associate'}{'__Default__'} = <<'EOF';
--begin--
var1:query_value1
var2:value2
var3:query_value3
--end--
EOF

$Expected_Output{'associate'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'associate'}{'__Default__'}
</html>|;

$Expected_Output{'non_associate'}{'__Default__'} = <<'EOF';
--begin--
var1:
var2:value2
var3:
--end--
EOF

$Expected_Output{'non_associate'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'non_associate'}{'__Default__'}
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
        $self->template('associate')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',

            HTMLTemplate => {
                associate_query => 1,
            },
            HTMLTemplateExpr => {
                associate_query => 1,
            },
            HTMLTemplatePluggable => {
                associate_query => 1,
            },
            TemplateToolkit => {
                emulate_associate_query => 1,
            },
            Petal => {
                emulate_associate_query => 1,
            },
        );
        $self->template('non_associate')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }

    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');

        my $expected_output_associate = $Expected_Output{'associate'}{$driver}
                           || $Expected_Output{'associate'}{'__Default__'};

        my $expected_output_non_associate = $Expected_Output{'non_associate'}{$driver}
                           || $Expected_Output{'non_associate'}{'__Default__'};


        $self->query->param('var1' => 'query_value1');
        $self->query->param('var2' => 'query_value2');
        $self->query->param('var3' => 'query_value3');

        my $template = $self->template('associate')->load;

        $template->param(
            'var2' => 'value2',
        );

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output_associate, "Got expected output (using associated query) for driver: $driver");

        $template = $self->template('non_associate')->load;

        $template->param(
            'var2' => 'value2',
        );

        $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output_non_associate, "Got expected output (not associated with query) for driver: $driver");

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
