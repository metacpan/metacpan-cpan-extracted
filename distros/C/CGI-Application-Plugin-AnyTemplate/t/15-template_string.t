
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 4;

my %Expected_Output;
my %Template_String;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
string_var1:value1
string_var2:value2
string_var3:value3
--end--
EOF

$Expected_Output{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'__Default__'}
</html>|;

$Template_String{'HTMLTemplatePluggable'} = $Template_String{'HTMLTemplate'} = $Template_String{'HTMLTemplateExpr'} = <<EOF;
--begin--
string_var1:<!-- TMPL_VAR NAME=var1 -->
string_var2:<!-- TMPL_VAR NAME=var2 -->
string_var3:<!-- TMPL_VAR NAME=var3 -->
--end--
EOF

$Template_String{'TemplateToolkit'} = <<EOF;
--begin--
string_var1:[% var1 %]
string_var2:[% var2 %]
string_var3:[% var3 %]
--end--
EOF

$Template_String{'Petal'} = <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html xmlns:tal="http://purl.org/petal/1.0/">
--begin--
string_var1:<span tal:replace="var1">var1</span>
string_var2:<span tal:replace="var2">var2</span>
string_var3:<span tal:replace="var3">var3</span>
--end--
</html>
EOF


{
    package WebApp;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');

    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
        );
    }

    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $string = $Template_String{$driver};

        my %params = (
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );

        my $template = $self->template->load(
            string   =>   \$string,
        );
        $template->param(%params);

        my $object = $template->object;

        my $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "template object ref: $ref");

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "[load(string => \\\$string)] Got expected output for driver: $driver");

        $template = $self->template->load(\$string);
        $template->param(%params);

        $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "[load(\\\$string)] Got expected output for driver: $driver");

        $output = $self->template->fill(\$string, \%params);

        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "[fill(\\\$string, \\%params)] Got expected output for driver: $driver");


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
    skip "Petal doesn't support loading templates from strings", $Per_Template_Driver_Tests;
    if (test_driver_prereqs('Petal')) {
        WebApp->new(PARAMS => {
            template_driver            => 'Petal',
            template_engine_class      => 'Petal',
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
