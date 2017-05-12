package Bigtop::Backend::Conf::General;

use Bigtop::Backend::Conf;
use Bigtop;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/AppName.conf'
                => 'Your config info in Config::General format' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

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

    my $conf_content = $class->output_conf( $tree );

    my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $app_name     = $tree->get_appname();
    $app_name        =~ s/::/-/g;
    my $conf_file    = File::Spec->catfile( $docs_dir, "$app_name.conf" );

    Bigtop::write_file( $conf_file, $conf_content );
}

sub output_conf {
    my $class = shift;
    my $tree  = shift;

    # first find the base location
    my $location_output = $tree->walk_postorder(
            'output_base_location_general'
    );
    my $location        = $location_output->[0] || '';

    # now build the <GantryLocation> blocks
    my $locations        = $tree->walk_postorder(
            'output_gantry_locations_general',
            {
                location => $location,
            }
    );

    return Bigtop::Backend::Conf::General::conf_file(
        {
            locations        => $locations,
        }
    );
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK conf_file %]
[% FOREACH line IN locations %]
[% line %]
[% END %][%# end of foreach line in locations %]
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

sub output_gantry_locations_general {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $location     = $data->{ location } || '/';

    # handle set vars at root location
    my $config   = $self->walk_postorder( 'output_conf_general' );
    my $literals = $self->walk_postorder( 'output_top_level_literal_general' );

    my $output   = Bigtop::Backend::Conf::General::all_locations(
        {
            root_loc     => $location,
            configs      => $config,
            literals     => $literals,
            child_output => $child_output,
        }
    );

    return [ $output ];
}

# app_statement
package # app_statement
    app_statement;
use strict; use warnings;

sub output_base_location_general {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

# app_config_block
package # app_config_block
    app_config_block;
use strict; use warnings;

sub output_conf_general {
    my $self         = shift;
    my $child_output = shift;

    return unless $child_output;

    my $output;
    my $gen_root = 1;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::General::config(
            {
                var   => $config->{__KEYWORD__},
                value => $config->{__ARGS__},
            }
        );

        $gen_root = 0 if ( $config->{__KEYWORD__} eq 'root' );
    }

    if ( $gen_root ) {
        $output .= Bigtop::Backend::Conf::General::config(
            {
                var   => 'root',
                value => 'html:html/templates',
            }
        );
    }

    return [ $output ];
}

# app_config_statement
package # app_config_statement
    app_config_statement;
use strict; use warnings;

sub output_conf_general {
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

sub output_top_level_literal_general {
    my $self = shift;

    return $self->make_output( 'Conf' );
}

# controller_block
package # controller_block
    controller_block;
use strict; use warnings;

sub output_gantry_locations_general {
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

    my $loc_configs
            = $self->walk_postorder( 'output_glocation_configs_general' );

    my $literals     = $self->walk_postorder(
                            'output_glocation_literal_general'
                       );

    my $child_location;

    if ( defined $child_loc{rel_location} ) {
        $child_location = "$location/$child_loc{rel_location}";
    }
    else { # must be location
        $child_location = $child_loc{location};
    }

    return unless ( @{ $loc_configs } );

    my $output = Bigtop::Backend::Conf::General::sub_locations(
        {
            loc          => $child_location,
            literal      => join( "\n", @{ $literals } ),
            handler      => $full_name,
            loc_configs  => $loc_configs,
        }
    );

    return [ $output ];
}

# controller_statement
package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_gantry_locations_general {
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

# controller_config_block
package # controller_config_block
    controller_config_block;
use strict; use warnings;

sub output_glocation_configs_general {
    my $self         = shift;
    my $child_output = shift;

    return unless $child_output;

    my $output;

    foreach my $config ( @{ $child_output } ) {
        $output .= Bigtop::Backend::Conf::General::config(
            {
                var    => $config->{__KEYWORD__},
                value  => $config->{__ARGS__},
                indent => 1,
            }
        );
    }

    return [ $output ];
}

# controller_config_statement
package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

sub output_glocation_configs_general {
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

sub output_glocation_literal_general {
    my $self = shift;

    return $self->make_output( 'GantryLocation' );
}

1;

=head1 NAME

Bigtop::Backend::Conf::General - makes Config::General conf files

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        Conf General {}
    }

and there are controllers in your app section, this module will generate
docs/httpd.conf when you type:

    bigtop app.bigtop Conf

or

    bigtop app.bigtop all

You can then directly Include this conf in your system httpd.conf or in one
of its virtual hosts.

=head1 DESCRIPTION

This is a Bigtop backend which generates conf files.  These
have the format of Config::General.  While you could use these with
Gantry::Conf the Conf Gantry backend provides more directl help for that
case.

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
    template

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: app.conf in Config::General
format, suitable for use with Gantry::Conf.

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

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
