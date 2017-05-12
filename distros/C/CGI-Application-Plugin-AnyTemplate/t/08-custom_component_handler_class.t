
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 1;

my %Expected_Output;

$Expected_Output{'__Default__'} = <<'EOF';
--begin--
outer_var1:outer_value1
--begin inner1--
one:none
two:none
three:none
four:none
outer_var1:outer_fish1
zzz:p1a
zzz:p2a
zzz:p1b
zzz:p2b
--begin inner2--
one:p1a
two:literal1a
three:p2a
four:literal2a
outer_var1:outer_fish1
outer_var2:outer_fish2
outer_var3:outer_fish3
inner1_var1:inner1_fish1
inner1_var2:inner1_fish2
inner1_var3:inner1_fish3
inner2_var1:inner2_fish1
inner2_var2:inner2_fish2
inner2_var3:inner2_fish3
--end inner2--
outer_var2:outer_fish2
--begin inner2--
one:p1b
two:literal1b
three:p2b
four:literal2b
outer_var1:outer_fish1
outer_var2:outer_fish2
outer_var3:outer_fish3
inner1_var1:inner1_fish1
inner1_var2:inner1_fish2
inner1_var3:inner1_fish3
inner2_var1:inner2_fish1
inner2_var2:inner2_fish2
inner2_var3:inner2_fish3
--end inner2--
outer_var3:outer_fish3
inner1_var1:inner1_fish1
inner1_var2:inner1_fish2
inner1_var3:inner1_fish3
--end inner1--
outer_var2:outer_value2
outer_var3:outer_value3
--end--
EOF

$Expected_Output{'Petal'}
    = qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">\n$Expected_Output{'__Default__'}|;

{
    package MyComponentHandler;
    use base 'CGI::Application::Plugin::AnyTemplate::ComponentHandler';

    sub embed {
        my $self = shift;
        my $output = $self->SUPER::embed(@_);
        $output =~ s/value/fish/g;
        return $output;
    }
    sub embed_direct {
        my $self = shift;
        my $output = $self->SUPER::embed_direct(@_);
        if (ref $output) {
            $$output =~ s/value/fish/g;
        }
        else {
            $output =~ s/value/fish/g;
        }
        return $output;
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
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('embed_outer');
        $self->run_modes([qw/
            embed_outer
            embed_inner1
            embed_inner2
        /]);
        $self->template->config(
            default_type            => $self->param('template_driver'),
            component_handler_class => 'MyComponentHandler',

            HTMLTemplate => {
                die_on_bad_params => 0,
            },
            HTMLTemplateExpr => {
                die_on_bad_params  => 0,
                template_extension => '.html_expr',
            },
            HTMLTemplatePluggable => {
                die_on_bad_params  => 0,
                template_extension => '.html_pluggable',
            },
        );
    }

    sub embed_outer {
        my $self = shift;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load(
            include_paths    => ['t/tmpl', 't/tmpl_include'],
        );
        $template->param(
            'outer_var1'    => 'outer_value1',
            'outer_var2'    => 'outer_value2',
            'outer_var3'    => 'outer_value3',
        );
        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        # Remove span tags and spurious newlines from Petal output
        if ($self->param('template_driver') eq 'Petal') {
            $output =~ s|\n?</?span>||g;
        }

        is($output, $expected_output, "Got expected output for driver: $driver");
        '';
    }

    sub embed_inner1 {
        my $self            = shift;
        my $parent_template = shift;
        my @params          = @_;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load(
            add_include_paths    => ['t/tmpl', 't/tmpl_include'],
        );
        $template->param(
            $parent_template->get_param_hash,
            'one'         => ($params[0] || 'none'),
            'two'         => ($params[1] || 'none'),
            'three'       => ($params[2] || 'none'),
            'four'        => ($params[3] || 'none'),
            'param1a'     => 'p1a',
            'param1b'     => 'p1b',
            'param2a'     => 'p2a',
            'param2b'     => 'p2b',
            'inner1_var1' => 'inner1_value1',
            'inner1_var2' => 'inner1_value2',
            'inner1_var3' => 'inner1_value3',
        );
        return $template->output;
    }
    sub embed_inner2 {
        my $self            = shift;
        my $parent_template = shift;
        my @params          = @_;

        my $driver = $self->param('template_driver');
        my $expected_output = $Expected_Output{$driver}
                           || $Expected_Output{'__Default__'};

        my $template = $self->template->load(
            include_paths    => ['t/tmpl_include'],
        );
        $template->param(
            $parent_template->get_param_hash,
            'one'         => ($params[0] || 'none'),
            'two'         => ($params[1] || 'none'),
            'three'       => ($params[2] || 'none'),
            'four'        => ($params[3] || 'none'),
            'inner2_var1' => 'inner2_value1',
            'inner2_var2' => 'inner2_value2',
            'inner2_var3' => 'inner2_value3',
        );
        return $template->output;
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
