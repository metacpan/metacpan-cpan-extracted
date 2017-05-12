
use strict;
use Test::More 'no_plan';

my $Per_Template_Driver_Tests = 2;

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
        $self->run_modes([qw/simple/]);

        $self->template('project')->config(      # defaults to storage in MyProject
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );

        $self->template('cgiapp')->config(
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
            TemplateToolkit => {
                storage_class => 'CGI::Application',
            },
        );
        $self->template('none')->config(
            type           => 'TemplateToolkit',
            TemplateToolkit => {
                object_caching => 0,
            },
            include_paths  => 't/tmpl',
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
        $self->run_modes([qw/simple/]);

        $self->template('project')->config(      # defaults to storage in MyProject
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );
        $self->template('cgiapp')->config(
            type          => 'TemplateToolkit',
            TemplateToolkit => {
                storage_class => 'CGI::Application',
            },
            include_paths => 't/tmpl',
        );
        $self->template('none')->config(
            type           => 'TemplateToolkit',
            TemplateToolkit => {
                object_caching => 0,
            },
            include_paths  => 't/tmpl',
        );
    }
}

{
    package WebApp1;

    use vars '@ISA';
    @ISA = ('MyProject');

    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub setup {
        my $self = shift;
        $self->SUPER::setup(@_);
        $self->template('app')->config(           # defaults to storage in WebApp1
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );

        $self->template('alpha')->config(         # defaults to storage in WebApp1
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );
        $self->template('beta')->config(          # defaults to storage in WebApp1
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );

    }

    sub simple {
        my $self = shift;

        my ($template, $obj1, $obj2);

        $template = $self->template('app')->load;
        $Objects{WebApp1}{'app_obj'} = $template->object;

        $template = $self->template('project')->load;
        $Objects{WebApp1}{'project_obj'} = $template->object;

        $template = $self->template('cgiapp')->load;
        $Objects{WebApp1}{'cgiapp_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{WebApp1}{'none1_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{WebApp1}{'none2_obj'} = $template->object;

        $template = $self->template('alpha')->load;
        $Objects{WebApp1}{'alpha'} = $template->object;

        $template = $self->template('beta')->load;
        $Objects{WebApp1}{'beta'} = $template->object;

        '';
    }
}

{
    package WebApp2;

    use vars '@ISA';
    @ISA = ('MyProject');

    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub setup {                                  # defaults to storage in WebApp2
        my $self = shift;
        $self->SUPER::setup(@_);
        $self->template('app')->config(
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );
    }
    sub simple {
        my $self = shift;

        my ($template, $obj1, $obj2);

        $template = $self->template('app')->load;
        $Objects{WebApp2}{'app_obj'} = $template->object;

        $template = $self->template('project')->load;
        $Objects{WebApp2}{'project_obj'} = $template->object;

        $template = $self->template('cgiapp')->load;
        $Objects{WebApp2}{'cgiapp_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{WebApp2}{'none1_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{WebApp2}{'none2_obj'} = $template->object;

        '';
    }
}

{
    package OthApp;

    use vars '@ISA';
    @ISA = ('OtherProject');

    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);

        $self->template('app')->config(          # defaults to storage in OthApp
            type          => 'TemplateToolkit',
            include_paths => 't/tmpl',
        );
        $self->template('project')->config(
            type          => 'TemplateToolkit',
            TemplateToolkit => {
                storage_class => 'OtherProject',
            },
            include_paths => 't/tmpl',
        );
        $self->template('cgiapp')->config(
            type          => 'TemplateToolkit',
            TemplateToolkit => {
                storage_class => 'CGI::Application',
            },
            include_paths => 't/tmpl',
        );
        $self->template('none')->config(
            type           => 'TemplateToolkit',
            TemplateToolkit => {
                object_caching => 0,
            },
            include_paths  => 't/tmpl',
        );
    }

    sub simple {
        my $self = shift;

        my ($template, $obj1, $obj2);

        $template = $self->template('app')->load;
        $Objects{OthApp}{'app_obj'} = $template->object;

        $template = $self->template('project')->load;
        $Objects{OthApp}{'project_obj'} = $template->object;

        $template = $self->template('cgiapp')->load;
        $Objects{OthApp}{'cgiapp_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{OthApp}{'none1_obj'} = $template->object;

        $template = $self->template('none')->load;
        $Objects{OthApp}{'none2_obj'} = $template->object;

        '';
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
        WebApp1->new->run;
        WebApp2->new->run;
        OthApp->new->run;

        # When app is used for storage, all objects should be different
        isnt($Objects{'WebApp1'}{'app_obj'}, $Objects{'WebApp2'}{'app_obj'}, "[app obj] WebApp1 != WebApp2");
        isnt($Objects{'OthApp'}{'app_obj'},  $Objects{'WebApp1'}{'app_obj'}, "[app obj] OthApp  != WebApp1");

        # When project is used for storage, objects for classes derived from MyProject should be identical
        is($Objects{'WebApp1'}{'project_obj'},  $Objects{'WebApp2'}{'project_obj'}, "[project obj] WebApp1 == WebApp2");
        isnt($Objects{'OthApp'}{'project_obj'}, $Objects{'WebApp1'}{'project_obj'}, "[project obj] OthApp  != WebApp1");

        # When cgiapp is used for storage, all objects should be identical
        is($Objects{'WebApp1'}{'cgiapp_obj'},  $Objects{'WebApp2'}{'cgiapp_obj'}, "[cgiapp obj] WebApp1 == WebApp2");
        is($Objects{'OthApp'}{'cgiapp_obj'},   $Objects{'WebApp1'}{'cgiapp_obj'}, "[cgiapp obj] OthApp  == WebApp1");

        # When no storage is used, all objects should be different, even those loaded by the same app
        isnt($Objects{'WebApp1'}{'none1_obj'},  $Objects{'WebApp1'}{'none2_obj'}, "[none obj] WebApp1 (none1) != WebApp1 (none2)");
        isnt($Objects{'WebApp1'}{'none1_obj'},  $Objects{'WebApp2'}{'none1_obj'}, "[none obj] WebApp1 (none1) != WebApp2 (none1)");
        isnt($Objects{'WebApp2'}{'none1_obj'},  $Objects{'WebApp2'}{'none2_obj'}, "[none obj] WebApp2 (none1) != WebApp2 (none2)");
        isnt($Objects{'OthApp'}{'none1_obj'},   $Objects{'WebApp2'}{'none2_obj'}, "[none obj] OthApp (none1)  != WebApp2 (none2)");
        isnt($Objects{'OthApp'}{'none1_obj'},   $Objects{'OthApp'}{'none2_obj'},  "[none obj] OthApp (none1)  != OthApp (none2)");

        # Two template objects using the same storage class, but different
        # names should be different objects
        isnt($Objects{'WebApp1'}{'alpha'},  $Objects{'WebApp1'}{'beta'}, "WebApp1 (alpha) != WebApp1 (beta)");


    }
    else {
        skip "Template::Toolkit not installed", 11;
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
