
use strict;
use Test::More;

use CGI::Application;

if (CGI::Application->can('new_hook')) {
    plan 'no_plan';
}
else {
    plan skip_all => 'installed version of CGI::Application does not support hooks';
}


my $Per_Template_Driver_Tests = 1;

my %Expected_Output;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
fish1----alueVay1
fish2----alueVay2
fish3----alueVay3
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
            HTMLTemplate => {
                die_on_bad_params => 0,
            },
            HTMLTemplateExpr => {
                die_on_bad_params => 0,
            },
            HTMLTemplatePluggable => {
                die_on_bad_params => 0,
            },
        );
        $self->add_callback('template_pre_process', \&my_tmpl_pre1);
        $self->add_callback('template_pre_process', \&my_tmpl_pre2);
        $self->add_callback('template_post_process', \&my_tmpl_post1);
        $self->add_callback('template_post_process', \&my_tmpl_post2);
    }

    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load;
        $template->param(
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );
        $template->param('replacement1' => 'fish');
        $template->param('replacement2' => '----');

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");
        '';
    }

    sub my_tmpl_pre1 {
        my ($self, $template) = @_;
        my $params = $template->get_param_hash;
        foreach my $param (keys %$params) {
            my $value = $template->param($param);
            $value =~ s/value/aluevay/g;

            $template->param($param, $value);
        }

    }
    sub my_tmpl_pre2 {
        my ($self, $template) = @_;
        my $params = $template->get_param_hash;
        foreach my $param (keys %$params) {
            my $value = $template->param($param);
            $value =~ s/v/V/g;

            $template->param($param, $value);
        }

    }

    sub my_tmpl_post1 {
        my ($self, $template, $text) = @_;
        my $replacement = $template->param('replacement1');
        $$text =~ s/var/$replacement/g;
    }
    sub my_tmpl_post2 {
        my ($self, $template, $text) = @_;
        my $replacement = $template->param('replacement2');
        $$text =~ s/:/$replacement/g;
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
