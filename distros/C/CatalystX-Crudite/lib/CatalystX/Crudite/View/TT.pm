package CatalystX::Crudite::View::TT;
use Moose;
use namespace::autoclean;
use Web::Library;
use File::ShareDir qw(dist_dir);
use CatalystX::Crudite::Util qw(merge_configs);
extends 'Catalyst::View::TT';

sub config_template_view {
    my ($class, %args) = @_;
    my %config = (
        INCLUDE_PATH => [ dist_dir('CatalystX-Crudite') . '/templates' ],

        # PRE_PROCESS is an array ref so the user can extend with Data::Nested
        PRE_PROCESS        => ['crudite_config'],
        ENCODING           => 'utf-8',
        TEMPLATE_EXTENSION => '.tt',
        render_die         => 1,
        expose_methods     => [qw(uri web_library)],
    );
    my $merged_config = merge_configs(\%config, \%args);
    $class->config(%$merged_config);
}

sub uri {

    # So you can write
    #
    #    [% uri('User', 'edit', 'user.id') %]
    #
    # instead of
    #
    #     [% c.uri_for(c.controller('User').action_for('edit'), [ user.id ]) %]
    my ($self, $c, $controller_name, $action_name, @args) = @_;
    $c->uri_for($c->controller($controller_name)->action_for($action_name),
        \@args);
}

# So you can write:
#
# <head>
#     ...
#     [% web_library.css_link_tags_for('Bootstrap', 'jQuery') %]
# </head>
# <body>
#     ...
#     [% web_library.script_tags_for('Bootstrap', 'jQuery') %]
# </body>
sub web_library { Web::Library->instance }
1;
