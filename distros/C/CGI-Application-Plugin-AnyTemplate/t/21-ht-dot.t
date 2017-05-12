
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

my %Expected_Output;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
var1:here(-arg1-)
var2:here(-arg2-)
var3:here(-arg3-)
--end--
EOF

{
    package Something;
    sub new { return bless {} }
    sub somehow {
        my $self = shift;
        return "here(-@_-)";
    }
}


{
    package WebApp;
    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::AnyTemplate;

    use vars '@ISA';
    @ISA = ('CGI::Application');

    sub setup {
        require HTML::Template::Pluggable;
        import HTML::Template::Pluggable;
        require HTML::Template::Plugin::Dot;
        import HTML::Template::Plugin::Dot;
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);
        $self->template->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }


    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load('htdot');
        my $sumptin  = Something->new;

        $template->param(
            'sumptin' => $sumptin,
        );
        my $object = $template->object;

        my $ref = $self->param('template_engine_class');
        is(ref $object, $ref, "template object ref: $ref");

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "Got expected output for driver: $driver");
        '';
    }
}


SKIP: {
    if (test_driver_prereqs('HTMLTemplate') and test_driver_prereqs('HTMLTemplatePluggable')) {
        WebApp->new(PARAMS => {
            template_driver       => 'HTMLTemplatePluggable',
            template_engine_class => 'HTML::Template::Pluggable',
        })->run;
    }
    else {
        skip "HTML::Template or HTML::Template::Pluggable not installed", $Per_Template_Driver_Tests;
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
