
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 4;

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
        $self->start_mode('embed_start');
        $self->run_modes([qw/
            embed_start
            embed_non_existent_runmode_sub
        /]);
        $self->template->config(
            # default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
            HTMLTemplate => {
                die_on_bad_params => 0,
            },
            HTMLTemplateExpr => {
                die_on_bad_params  => 0,
                template_extension => '.html_expr',
            },
        );
    }

    sub embed_start {
        my $self = shift;

        my $driver = $self->param('template_driver');

        my $template = $self->template->load(
            'embed_error1',
        );

        my $output;


        eval {
            $output = $template->output;
        };

        ok($@, "Caught embed to non existent runmode");
        # like($@, qr/embed_non_existent_runmode.*listed/, "Caught embed to non existent runmode (error message ok)");
        # Changed because we currently can't trap and report errors in embed_direct
        like($@, qr/embed_non_existent_runmode/, "Caught embed to non existent runmode (error message ok)");

        $template = $self->template->load(
            'embed_error2',
        );

        eval {
            $output = $template->output;
        };

        ok($@, "Caught embed to non existent runmode sub ");
        like($@, qr/embed_non_existent_runmode.*sub/, "Caught embed to non existent runmode sub (error message ok)");


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

