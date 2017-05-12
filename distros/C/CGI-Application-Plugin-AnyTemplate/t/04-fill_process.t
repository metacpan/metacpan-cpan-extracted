
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 3;

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

$Expected_Output{'three'}{'__Default__'} = <<'EOF';
--begin--
this space intentionally left blank
b1:
--end--
EOF

$Expected_Output{'three'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'three'}{'__Default__'}
</html>|;

$Expected_Output{'four'}{'__Default__'} = <<'EOF';
--begin--
var1:
var2:
var3:
--end--
EOF

$Expected_Output{'four'}{'Petal'} =
qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
$Expected_Output{'four'}{'__Default__'}
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

        $self->template('one')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
        $self->template('two')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
        $self->template('three')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
        $self->template('four')->config(
            default_type  => $self->param('template_driver'),
            include_paths => 't/tmpl',
        );
    }

    sub simple {
        my $self = shift;

        my $driver = $self->param('template_driver');

        # named config 'one'
        my $expected_output = $Expected_Output{'one'}{$driver}
                           || $Expected_Output{'one'}{'__Default__'};

        my $output = $self->template('one')->fill({
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        });
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "(one) Got expected output for driver: $driver");

        # named config 'two' - same settings
        $output = $self->template('one')->process('simple', {
            'var1' => 'value1',
            'var2' => 'value2',
            'var3' => 'value3',
        });
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "(two) Got expected output for driver: $driver");

        # named config 'three' - same settings, but we don't pass params

        $expected_output = $Expected_Output{'three'}{$driver}
                        || $Expected_Output{'three'}{'__Default__'};

        $output = $self->template('three')->fill('blank');
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "(three) Got expected output for driver: $driver");

        # named config 'four' - but this time we call fill without any args
        $expected_output = $Expected_Output{'four'}{$driver}
                        || $Expected_Output{'four'}{'__Default__'};

        $output = $self->template('four')->fill;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $expected_output, "(four) Got expected output for driver: $driver");

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
