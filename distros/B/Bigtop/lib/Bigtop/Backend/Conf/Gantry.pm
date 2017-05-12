package Bigtop::Backend::Conf::Gantry;

use strict;

use Bigtop::Backend::Conf;
use Bigtop;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/AppName.gantry.conf'
                => 'Your config info for immediate use with Gantry::Conf' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'instance',
          label   => 'Conf Instance',
          descr   => 'Your Gantry::Conf instance',
          type    => 'text' },

        { keyword => 'conffile',
          label   => 'Conf File',
          descr   => 'Your master conf file [use a full path]',
          type    => 'text' },

        { keyword => 'gen_root',
          label   => 'Generate Root Path',
          descr   => q!used to make a default root on request, !
                        .   q!now you get defaults by defaul!,
          type    => 'deprecated' },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },
        
    ];
}

sub gen_Conf {
    my $class        = shift;
    my $base_dir     = shift;
    my $tree         = shift;

    my $conf_content = $class->output_conf( $tree, $base_dir );

    my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $app_name     = $tree->get_appname();
    $app_name        =~ s/::/-/g;

    # write gantry incude 
    my $include_file    = File::Spec->catfile(
            $docs_dir,
            "app.gantry.conf"
    );

    Bigtop::write_file( $include_file, "Include $app_name.gantry.conf\n" );
    
    # write gantry conf 
    my $conf_file    = File::Spec->catfile(
            $docs_dir,
            "$app_name.gantry.conf"
    );

    Bigtop::write_file( $conf_file, $conf_content );
}

sub output_conf {
    my $class    = shift;
    my $tree     = shift;
    my $base_dir = shift;

    my $app_config_blocks = $tree->get_app_configs();
    my $bigtop_config     = $tree->get_config->{Conf};
    my $instance          = $bigtop_config->{instance} || 'missing_instance';

    my $controller_configs = $tree->get_controller_configs();

    # first find the base location
    my $location_output = $tree->walk_postorder(
            'output_base_location_gantry'
    );
    my $location        = $location_output->[0] || '';

    # now build the intances including their <GantryLocation> blocks
    my @instances;

    foreach my $conf_type ( @{ $tree->get_app_config_types } ) {
        my $locations        = $tree->walk_postorder(
                'output_glocations_gantry',
                {
                    location  => $location,
                    configs   => $app_config_blocks,
                    conf_type => $conf_type,
                    controller_configs => $controller_configs,
                    base_dir  => $base_dir,
                }
        );
        my $name = $instance;
        $name   .= "_$conf_type" unless $conf_type eq 'base';
        s/^/    /gms for @{ $locations };  # apply an indent
        push @instances, { name => $name, locations => $locations };
    }

    return Bigtop::Backend::Conf::Gantry::conf_file(
        {
            instances        => \@instances,
        }
    );
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK conf_file %]
[% FOREACH instance IN instances %]
<instance [% instance.name %]>
[% FOREACH line IN instance.locations %]
[% line %]
[% END %][%# end of foreach line in locations %]
</instance>

[% END %]
[% END %]

[% BLOCK all_locations %]
[% FOREACH config IN configs %][% config %][% END %]
[% FOREACH literal IN literals %][% literal %][% END %]
[% FOREACH child_piece IN child_output %][% child_piece %][% END %]
[% END %][%# all_locations %]

[% BLOCK config %]
[% IF indent %]    [% END %][% var %] [% value %]

[% END %]

[% BLOCK sub_locations %]
<GantryLocation [% loc %]>
[% FOREACH config IN loc_configs %]
[% config %][% END %]
[% IF literal %][% literal %][% END %]
</GantryLocation>
[% END %]
EO_TT_BLOCKS

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
            TT                  => $template_text,
            POST_CHOMP          => 1,
            TRIM_LEADING_SPACE  => 0,
            TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

package # application
    application;
use strict; use warnings;

sub output_glocations_gantry {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $location     = $data->{ location } || '/';

    # handle set vars at root location
    my $configs  = $self->walk_postorder(
            'output_configs_gantry', $data
    );
    my $literals = $self->walk_postorder( 'output_top_level_literal_gantry' );

    my $output   = Bigtop::Backend::Conf::Gantry::all_locations(
        {
            root_loc     => $location,
            configs      => $configs,
            literals     => $literals,
            child_output => $child_output,
        }
    );

    return [ $output ];
}

package # app_statement
    app_statement;
use strict; use warnings;

sub output_base_location_gantry {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

package # app_config_block
    app_config_block;
use strict; use warnings;

use Cwd;

sub output_configs_gantry {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $conf_type    = $data->{ conf_type };
    my $configs      = $data->{ configs };
    my $own_type     = $self->{__TYPE__} || 'base';

    return unless $child_output;
    return unless $own_type eq $conf_type;

    my $output;
    my %config_set_for;

    my $gen_root = 1;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::Gantry::config(
            {
                var   => $config->{__KEYWORD__},
                value => $config->{__ARGS__},
            }
        );
        $config_set_for{ $config->{__KEYWORD__} }++;

        $gen_root = 0 if ( $config->{__KEYWORD__} eq 'root' );
    }

    if ( $gen_root ) {
        my $templates = File::Spec->catdir( qw( html templates ) );

        if ( $conf_type =~ /^CGI|CGI$/i ) {
            my $cwd  = getcwd();
            my $html = File::Spec->catdir( $cwd, $data->{ base_dir }, 'html' );
            $templates = File::Spec->catdir( $html, 'templates' );

            $output .= Bigtop::Backend::Conf::Gantry::config(
                {
                    var   => 'root',
                    value => "$html:$templates",
                }
            );
        }
        else {
            $output .= Bigtop::Backend::Conf::Gantry::config(
                {
                    var   => 'root',
                    value => "html:$templates",
                }
            );
        }
        $config_set_for{ root }++;
    }

    # fill in omitted keys from the base block
    BASE_KEY:
    foreach my $base_key ( keys %{ $configs->{ base } } ) {
        next BASE_KEY if $config_set_for{ $base_key };

        $output .= Bigtop::Backend::Conf::Gantry::config(
            {
                var   => $base_key,
                value => $configs->{ base }{ $base_key },
            }
        );
    }

    return [ $output ];
}

package # app_config_statement
    app_config_statement;
use strict; use warnings;

sub output_configs_gantry {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ {
            __KEYWORD__ => $self->{__KEYWORD__},
            __ARGS__    => $output_vals
    } ];
}

# literal_block
package # literal_block
    literal_block;
use strict; use warnings;

sub output_top_level_literal_gantry {
    my $self = shift;

    return $self->make_output( 'Conf' );
}

# controller_block
package # controller_block
    controller_block;
use strict; use warnings;

sub output_glocations_gantry {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $location     = $data->{ location };

    return if $self->is_base_controller;

    my %child_loc    = @{ $child_output };

    if ( keys %child_loc != 1 ) {
        die "Error: controller '" . $self->get_name()
            . "' must have one location or rel_location statement.\n";
    }

    my $app          = $self->{__PARENT__}{__PARENT__}{__PARENT__};
    my $full_name    = $app->get_name() . '::' . $self->get_name();

    my $loc_configs  = $self->walk_postorder(
            'output_glocation_configs_gantry', $data
    );

    my $literals     = $self->walk_postorder(
                            'output_glocation_literal_gantry'
                       );

    my $child_location;

    if ( defined $child_loc{rel_location} ) {
        $child_location = "$location/$child_loc{rel_location}";
    }
    else { # must be location
        $child_location = $child_loc{location};
    }

    return unless ( @{ $loc_configs } or @{ $literals } );

    my $output = Bigtop::Backend::Conf::Gantry::sub_locations(
        {
            loc          => $child_location,
            literal      => join( "\n", @{ $literals } ),
            handler      => $full_name,
            loc_configs  => $loc_configs,
        }
    );

    return [ $output ];
}

package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_glocations_gantry {
    my $self         = shift;

    if ( $self->{__KEYWORD__} eq 'rel_location' ) {
        return [ rel_location => $self->{__ARGS__}->get_first_arg() ];
    }
    elsif ( $self->{__KEYWORD__} eq 'location' ) {
        return [ location => $self->{__ARGS__}->get_first_arg() ];
    }
    else {
        return;
    }
}

package # controller_config_block
    controller_config_block;
use strict; use warnings;

sub output_glocation_configs_gantry {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $controller   = $self->get_controller_name();
    my $conf_type    = $data->{ conf_type };
    my $configs      = $data->{ controller_configs }{ $controller };
    my $own_type     = $self->{__TYPE__} || 'base';

    return unless $child_output;
    return unless $own_type eq $conf_type;

    my $output;
    my %config_set_for;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::Gantry::config(
            {
                var    => $config->{__KEYWORD__},
                value  => $config->{__ARGS__},
                indent => 1,
            }
        );
        $config_set_for{ $config->{__KEYWORD__} }++;
    }

    # fill in omitted keys from the base block
    CONTROLLER_BASE_KEY:
    foreach my $base_key ( keys %{ $configs->{ base } } ) {
        next CONTROLLER_BASE_KEY if $config_set_for{ $base_key };

        $output .= Bigtop::Backend::Conf::Gantry::config(
            {
                var   => $base_key,
                value => $configs->{ base }{ $base_key },
                indent => 1,
            }
        );
    }

    return [ $output ];
}

package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

sub output_glocation_configs_gantry {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ {
            __KEYWORD__ => $self->{__KEYWORD__},
            __ARGS__    => $output_vals
    } ];
}

# controller_literal_block
package # controller_literal_block
    controller_literal_block;
use strict; use warnings;

sub output_glocation_literal_gantry {
    my $self = shift;

    return $self->make_output( 'GantryLocation' );
}

1;

=head1 NAME

Bigtop::Backend::Conf::Gantry - makes Config::Gantry conf files

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        Conf Gantry { instance name; }
    }

and there are controllers in your app section, this module will generate
docs/httpd.conf when you type:

    bigtop app.bigtop Conf

or

    bigtop app.bigtop all

You can then directly Include this conf in your system httpd.conf or in one
of its virtual hosts.

=head1 DESCRIPTION

This is a Bigtop backend which generates gantry.conf files.  These
have the format of Config::General.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::Conf
for a list of allowed keywords (think app and controller level 'location'
and controller level 'rel_location' statements).

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    instance
    template

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: app.conf in Config::General
format, suitable for immediate use with Gantry::Conf in /etc/gantry.d or
its equivalent on your system.

=item gen_Conf

Called by Bigtop::Parser to get me to do my thing.

=item output_conf

What I call on the various AST packages to do my thing.

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2006 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
