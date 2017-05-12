
use strict;
use Test::More;

eval { require Exporter::Renaming; };

if ($@) {
    plan 'skip_all' => "Exporter::Renaming not installed"
}
else {
    plan 'no_plan';
}


eval <<'TEST';
my $Expected_Output = <<'EOF';
--begin--
var1:value1
var2:value2
var3:value3
--end--
EOF

{
    package WebApp;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');

    use Exporter::Renaming;
    use Test::More;
    use CGI::Application::Plugin::AnyTemplate Renaming => [ 'template' => 'xxxx' ];

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);

        $self->xxxx->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }

    sub simple {
        my $self = shift;

        my $expected_output = $Expected_Output;

        my $template = $self->xxxx->load;
        $template->param(
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        );
        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output");
        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate')) {
        WebApp->new(PARAMS => { template_driver => 'HTMLTemplate' })->run;
    }
    else {
        skip "HTML::Template not installed", 1;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'CGI::Application::Plugin::AnyTemplate::Driver::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    my @required_modules = $driver_module->required_modules;

    eval "require $_;" for @required_modules;

    if ($@) {
        return;
    }
    return 1;
}
TEST

