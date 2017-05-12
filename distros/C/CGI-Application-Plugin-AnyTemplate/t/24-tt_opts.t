
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

my %Expected_Output;

$Expected_Output{'wrapper'} = qq{wrapper-begin
--begin--
var1:value1
var2:value2
var3:value3
--end--

wrapper-end};

$Expected_Output{'no_wrapper'} = <<'EOF';
--begin--
var1:value1
var2:value2
var3:value3
--end--
EOF


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

        $self->template('no_wrapper')->config( # for templates not requiring wrapper
          type          => 'TemplateToolkit',
          include_paths => 't/tmpl',
        );

        $self->template('wrapper')->config( # default AnyTemplate config
          type => 'TemplateToolkit',
          include_paths   => 't/tmpl',
          TemplateToolkit => {
            WRAPPER => 'wrapper.tmpl',
          },
        );
    }

    sub simple {
        my $self = shift;

        # named config 'wrapper'
        my $expected_output = $Expected_Output{'wrapper'};

        my $output = $self->template('wrapper')->fill({
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        });
        $output = $$output if ref $output eq 'SCALAR';
        is($output, $expected_output, "(wrapper) Got expected output");


        # named config 'no_wrapper'
        $expected_output = $Expected_Output{'no_wrapper'};

        $output = $self->template('no_wrapper')->fill({
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        });
        $output = $$output if ref $output eq 'SCALAR';
        is($output, $expected_output, "(no_wrapper) Got expected output");
        '';
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
