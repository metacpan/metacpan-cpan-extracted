
use strict;
use Test::More;

use CGI::Application;

# The load_tmpl hook changed in CGI::Application between versions 4.0 and 4.01
if (CGI::Application->can('new_hook') and $CGI::Application::VERSION > 4.0) {
    plan 'no_plan';
}
else {
    plan skip_all => 'installed version of CGI::Application does not support the latest load_tmpl hook';
}

my $Per_Template_Driver_Tests = 5;

my %Expected_Output;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
var1:porkpiehat1
var2:porkpiehat2
var3:porkpiehat3
--end--
EOF

my %Extension = (
    HTMLTemplate          => '.html',
    HTMLTemplateExpr      => '.html',
    HTMLTemplatePluggable => '.html',
    TemplateToolkit       => '.tmpl',
    Petal                 => '.xhtml',
);


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
        $self->start_mode('simple_elsewhere');
        $self->run_modes([qw/simple_elsewhere/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
            add_include_paths => 'really_bad_path',
        );
        $self->add_callback('load_tmpl', \&my_load_tmpl1);
        $self->add_callback('load_tmpl', \&my_load_tmpl2);
    }

    sub simple_elsewhere {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load;
        $template->param('var3' => 'porkpiehat3');

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");
        '';
    }

    sub my_load_tmpl1 {
        my ($self, $ht_params, $tmpl_params, $tmpl_file) = @_;

        my $driver = $self->param('template_driver');
        my $extension = $Extension{$driver};

        is($ht_params->{'path'}, 'really_bad_path', '[my_load_tmpl1] path]');

        $ht_params->{'path'} = 'badpath';

        is($tmpl_file, 'simple_elsewhere' . $extension, '[my_load_tmpl1] filename]');

        $tmpl_params->{'var1'} = 'porkpiehat1';

    }
    sub my_load_tmpl2 {
        my ($self, $ht_params, $tmpl_params, $tmpl_file) = @_;

        my $driver = $self->param('template_driver');
        my $extension = $Extension{$driver};

        is($ht_params->{'path'}, 'badpath', '[my_load_tmpl2] path]');

        $ht_params->{'path'} = 't/tmpl_include';

        is($tmpl_file, 'simple_elsewhere' . $extension, '[my_load_tmpl2] filename]');

        $tmpl_params->{'var2'} = 'porkpiehat2';

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
