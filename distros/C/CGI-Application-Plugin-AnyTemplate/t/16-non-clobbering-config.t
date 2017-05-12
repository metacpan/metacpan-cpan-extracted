
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

my %AT_Config = (
    default_type                => 'TemplateToolkit',
    include_paths               => 't/tmpl',
    auto_add_template_extension => 0,
);

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
        $self->start_mode('test_template');
        $self->run_modes([qw/test_template/]);
        $self->template->config(\%AT_Config);
    }

    sub test_template {
        my $self = shift;

        my $template;
        $template = $self->template->load;
        ok(!$@, "template loaded okay") or die "error loading template: $@\n";

        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate') and test_driver_prereqs('TemplateToolkit')) {
        WebApp->new->run;
        WebApp->new->run;
    }
    else {
        skip "HTML::Template or Template::Toolkit not installed", $Per_Template_Driver_Tests;
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
