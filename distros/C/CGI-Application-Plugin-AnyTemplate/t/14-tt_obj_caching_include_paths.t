
use strict;
use Test::More 'no_plan';

my %Expected_Output;

$Expected_Output{'path1'} = <<'EOF';
--begin--
outer_var1:outer_value1
--begin inner--
inner_var1:inner_value1
inner_var2:inner_value2
inner_var3:inner_value3
--end inner--
outer_var2:outer_value2
--end--
EOF

$Expected_Output{'path2'} = <<'EOF';
--begin--
outer_var1:outer_value1
--begin inner_path2--
inner_path2_var1:inner_value1
inner_path2_var2:inner_value2
inner_path2_var3:inner_value3
--end inner_path2--
outer_var2:outer_value2
--end--
EOF


my %Objects;

{
    package MyProject;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/
            simple
            cache_incl_paths_inner
        /]);

        $self->template('project')->config(      # defaults to storage in MyProject
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );
    }
}
{
    package OtherProject;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/
            simple
            cache_incl_paths_inner
        /]);

        $self->template('project')->config(      # defaults to storage in MyProject
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
            TemplateToolkit => {
                object_caching => 0,
            },
        );
    }
}

{
    package WebApp;
    use vars '@ISA';
    @ISA = ('MyProject');
    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub simple {
        my $self = shift;

        my $template = $self->template('project')->load(
            file              => 'cache_incl_paths_outer',
        );

        $template->param(
            'outer_var1' => 'outer_value1',
            'outer_var2' => 'outer_value2',
            'inner_var1' => 'inner_value1',
            'inner_var2' => 'inner_value2',
            'inner_var3' => 'inner_value3',
        );

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $Expected_Output{'path1'}, 'include files (path 1)');

        '';
    }
    sub cache_incl_paths_inner {
        my ($self, $parent_template) = @_;

        my $template = $self->template('project')->load(
            file              => 'cache_incl_paths_inner',
            add_include_paths => 't/tmpl_include',
        );
        $template->param($parent_template->get_param_hash);
        return $template->output;
    }
}

{
    package OthApp;
    use vars '@ISA';
    @ISA = ('OtherProject');
    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub simple {
        my $self = shift;

        my $template = $self->template('project')->load(
            file          => 'cache_incl_paths_outer',
        );
        $template->param(
            'outer_var1' => 'outer_value1',
            'outer_var2' => 'outer_value2',
            'inner_var1' => 'inner_value1',
            'inner_var2' => 'inner_value2',
            'inner_var3' => 'inner_value3',
        );

        my $output = $template->output;
        $output = $$output if ref $output eq 'SCALAR';

        is($output, $Expected_Output{'path2'}, 'include files (path 2)');
        '';
    }
    sub cache_incl_paths_inner {
        my ($self, $parent_template) = @_;

        my $template = $self->template('project')->load(
            file              => 'cache_incl_paths_inner',
            include_paths => [ 't/tmpl', 't/tmpl_include2' ],
        );
        $template->param($parent_template->get_param_hash);
        return $template->output;
    }
}


# Currently, you are not prevented from storing in a class you aren't a descendent of.
# Is this a bad idea?
# {
#     package BadApp;
#     use base 'OtherProject';
#     use Test::More;
#     use CGI::Application::Plugin::AnyTemplate;
#
#     sub setup {
#         my $self = shift;
#         $self->header_type('none');
#         $self->start_mode('simple');
#         $self->run_modes([qw/simple/]);
#
#         $self->template('project')->config(
#             type          => 'TemplateToolkit',
#             TemplateToolkit => {
#                 storage_class => 'BadBadBad',
#             },
#             include_paths => 't/tmpl',
#         );
#     }
# }

SKIP: {
    if (test_driver_prereqs('TemplateToolkit')) {
        WebApp->new->run;
        OthApp->new->run;
    }
    else {
        skip "Template::Toolkit not installed", 2;
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
