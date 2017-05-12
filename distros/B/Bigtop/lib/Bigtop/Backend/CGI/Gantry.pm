package Bigtop::Backend::CGI::Gantry;

use strict;

use Bigtop;
use Bigtop::Backend::CGI;
use Inline;

sub what_do_you_make {
    return [
        [ 'app.cgi'    => 'CGI or FastCGI dispatching script' ],
        [ 'app.server' => 'Stand alone Gantry::Server [optional]' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'fast_cgi',
          label   => 'FastCGI',
          descr   => 'Make the script for use with FastCGI',
          type    => 'boolean' },

        { keyword => 'gantry_conf',
          label   => 'Use Gantry::Conf',
          descr   => 'check here if you use the Conf Gantry backend',
          type    => 'boolean', },

        { keyword => 'with_server',
          label   => 'Build Server',
          descr   => 'Turns on stand alone Gantry::Server generation',
          type    => 'boolean' },

        { keyword => 'server_port',
          label   => 'Server Port',
          descr   => 'Specifies the port for stand alone server '
                        .   '[ignored unless Build Server is checked]',
          type    => 'text' },

        { keyword => 'gen_root',
          label   => 'Generate Root Path',
          descr   => q!used to make a default root on request, !
                        .   q!now you get defaults by defaul!,
          type    => 'deprecated' },

        { keyword => 'flex_db',
          label   => 'Database Flexibility',
          descr   => 'Adds command line args to stand alone server to '
                        .   'allow easy DBD switching',
          type    => 'boolean',
          default => 'false', },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },

    ];
}

sub gen_CGI {
    my $class        = shift;
    my $base_dir     = shift;
    my $tree         = shift;

    my $configs      = $tree->get_app_configs();
    my $fast_cgi     = $tree->get_config->{CGI}{fast_cgi} || 0;
    my $gantry_conf  = $tree->get_config->{CGI}{gantry_conf} || 0;

    my %cgi_conf_types;

    CGI_ONLY_CHECK:
    foreach my $conf_type ( keys %{ $configs } ) {
        $cgi_conf_types{ $conf_type } = 1 if ( $conf_type =~ /^CGI|CGI$/i );
    }

    my $there_is_a_cgi = keys %cgi_conf_types;

    CONF_TYPE:
    foreach my $conf_type ( keys %{ $configs } ) {
        my $content      = $class->output_cgi(
            {
                tree      => $tree,
                configs   => $configs,
                conf_type => $conf_type,
                fast_cgi  => $fast_cgi,
                base_dir  => $base_dir,
            }
        );

        my $write_cgi   = 1;
        my $file_type   = ( $conf_type eq 'base' ) ? '' : "$conf_type.";
        my $server_type = $file_type;

        if ( $there_is_a_cgi ) {
            $file_type = $conf_type;
            $write_cgi = 0 if ( $file_type !~ s/^CGI|CGI$// );
        }

        my $cgi_file  = File::Spec->catfile(
                $base_dir, "app.${file_type}cgi"
        );

        Bigtop::write_file( $cgi_file, $content->{ cgi } ) if $write_cgi;

        chmod 0755, $cgi_file;

        if ( $tree->get_config->{CGI}{with_server} ) {
            next CONF_TYPE if ( $gantry_conf and $conf_type ne 'base' );

            my $server_file  = File::Spec->catfile(
                    $base_dir,
                    "app.${server_type}server"
            );

            Bigtop::write_file( $server_file, $content->{ server } );

            chmod 0755, $server_file;
        }
    }
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_BLOCKS';
[% BLOCK cgi_script %]
#![% perl_path +%]
use strict;

[% literal %]

use CGI::Carp qw( fatalsToBrowser );

use [% app_name %] qw{
    -Engine=CGI
    -TemplateEngine=[% template_engine +%]
[% IF plugins %]    -PluginNamespace=[% app_name +%]
    [% plugins +%]
[% END %]
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
[% END %][%# end of block cgi_script %]

[% BLOCK stand_alone_server %]
#![% perl_path +%]
use strict;

[% literal %]

use lib qw( lib );

use [% app_name %] qw{
    -Engine=CGI
    -TemplateEngine=[% template_engine +%]
    Static
[% IF plugins %]    -PluginNamespace=[% app_name +%]
    [% plugins +%]
[% END %]
};

[% IF flex_db %]
use Getopt::Long;
[% END %]
use Gantry::Server;
use Gantry::Engine::CGI;

[% IF flex_db %]
use Gantry::Conf;

my $dbd;
my $dbuser;
my $dbpass;
my $dbname;

my $conf_instance = '[% instance %]';
my $conf_type;
my $conf_file     = 'docs/app.gantry.conf';

GetOptions(
    'dbd|d=s'      => \$dbd,
    'dbuser|u=s'   => \$dbuser,
    'dbpass|p=s'   => \$dbpass,
    'dbname|n=s'   => \$dbname,
    'instance|i=s' => \$conf_instance,
    'type|t=s'     => \$conf_type,
    'file|f=s'     => \$conf_file,
    'help|h'       => \&usage,
);

if ( $conf_type and $conf_type ne 'base' ) {
    $conf_instance = "[% instance %]_$conf_type";
}

my $config = Gantry::Conf->retrieve(
    {
        instance    => $conf_instance,
        config_file => $conf_file,
    }
);

if ( $dbd or $dbname ) {
    $dbd ||= 'SQLite';
    $config->{ dbconn } = "dbi:$dbd:dbname=$dbname";
}

$config->{ dbuser } = $dbuser if $dbuser;
$config->{ dbpass } = $dbpass if $dbpass;

my $cgi = Gantry::Engine::CGI->new( {
    config => $config,
[% locs %]
} );
[% ELSE %]

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );
[% END %]

my $port = shift || [% port || 8080 %];

my $server = Gantry::Server->new( $port );
$server->set_engine_object( $cgi );

print STDERR "Available urls:\n";
foreach my $url ( sort keys %{ $cgi->{ locations } } ) {
    print STDERR "  http://localhost:${port}$url\n";
}
print STDERR "\n";

$server->run();

[% IF flex_db %]
sub usage {
    print << 'EO_HELP';
usage: app.server [options] [port]
    port defaults to [% port || 8080 +%]

    options:
    -h  --help     prints this message and quits
    -i  --instance name of a Gantry::Conf instance
                   defaults to [% instance +%]
    -t  --type     type of one Bigtop config block
                   defaults to the unnamed block
    -f  --file     master Gantry::Conf file
                   defaults to docs/app.gantry.conf

    options which override Gantry::Conf values:
    -d  --dbd      DBD module name (e.g. Pg, mysql, etc)
    -n  --dbname   name of database
    -u  --dbuser   database user name
    -p  --dbpass   dbuser's database password

Note that -i and -t are incompatible.  The former fully specifies an
instance name for Gantry::Conf.  The later specifies the config type
suffix of an instance name.  If you use both, -t takes precedence.

-d defaults to SQLite.

EO_HELP

    exit 0;
}

=head1 NAME

app.server - A generated server for the [% app_name %] app

=head1 SYNOPSIS

    usage: app.server [options] [port]

port defaults to 8080

=head1 DESCRIPTION

This is a Gantry::Server based stand alone server for the [% app_name +%]
app.  It was built to use the [% instance %] Gantry::Conf instance in the
docs directory.

To override the database connection information in your conf file,
see L<Changing Databases without Changing Conf> below.

To change instances or master conf files, use these
flags (they all require values):

=over 4

=item --instance (or -i)

(Incompatible with --type)

The full name of your conf instance, defaults to [% instance %].

=item --type (or -t)

(Incompatible with --instance)

Use this if you use named config blocks in your Bigtop file.  Use the
name of the config block as the value for --type.  This will build the
corresponding instance name as [% instance %]_TYPE, where TYPE is the value
of this flag.

If you don't neither --instance nor --type, the instance you get will
be [% instance %].

=item --file (or -f)

The name of your master Gantry::Conf file, defaults to docs/app.gantry.conf.

=back

=head1 Changing Databases without Changing Conf

You may use the following flags to control database connections.  If you
supply these flags, they will take precedence over your Gantry::Conf instance.
All of them require values.

=over 4

=item --dbd (or -d)

The name of your DBD module (like SQLite, Pg, or mysql).  If you use
dbname, this defaults to SQLite.

=item --dbname (or -n)

The name of your database.

=item --dbuser (or -u)

Your database user name.

=item --dbpass (or -p)

Your database password.

=back

=cut
[% END %][%# end of if flex_db %]
[% END %][%# end of stand_alone_server %]

[% BLOCK fast_cgi_script %]
#![% perl_path +%]
use strict;

use FCGI;
use CGI::Carp qw( fatalsToBrowser );

use [% app_name %] qw{
    -Engine=CGI
    -TemplateEngine=[% template_engine +%]
[% IF plugins %]    -PluginNamespace=[% app_name +%]
    [% plugins +%]
[% END %]
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
[% config %]
[% locs %]
} );

my $request = FCGI::Request();

while ( $request->Accept() >= 0 ) {

    $cgi->dispatch();

    if ( $cgi->{config}{debug} ) {
        foreach ( sort { $a cmp $b } keys %ENV ) {
            print "$_ $ENV{$_}<br />\n";
        }
    }
}
[% END %][%# end of block fast_cgi_script %]

[% BLOCK application_loc %]
    locations => {
        '[% location %]' => '[% name %]',
[% body %]
    },
[% END %][%# end of block application_loc %]

[% BLOCK application_config %]
    config => {
[% body +%]
    },
[% END %][%# end of block application_config %]

[% BLOCK controller_block_loc %]
[% IF rel_loc %]
        '[% app_location %]/[% rel_loc %]' => '[% full_name %]',
[% ELSE %]
        '[% abs_loc %]' => '[% full_name %]',
[% END %][%# end of if rel_loc %]
[% END %]

[% BLOCK config_body %]
[% FOREACH config IN configs %]
[% IF config.value.match( '^\d+$' ) %]
        [% config.name %] => [% config.value %],
[% ELSE %]
        [% config.name %] => '[% config.value %]',
[% END %][%# end of if %]
[% END %][%# end of foreach %]
[% END %][%# end of block config %]

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

sub output_cgi {
    my $class     = shift;
    my $opts      = shift;
    my $tree      = $opts->{ tree };
    my $fast_cgi  = $opts->{ fast_cgi };
    my $conf_type = $opts->{ conf_type };
    my $configs   = $opts->{ configs };

    # first find the base location
    my $location_output = $tree->walk_postorder( 'output_location' );
    my $location        = $location_output->[0] || ''; # default to host root

    $location           =~ s{/+$}{};

    # now build the config and locations hashes
    my $config;
    my $stand_alone_config;
    my $locations = $tree->walk_postorder( 'output_cgi_locations', $location );
    my $literals  = $tree->walk_postorder( 'output_literal' );
    my $app_name  = $tree->get_appname();

    my $literal   = join "\n", @{ $literals };

    my $backend_block     = $tree->get_config->{CGI};

    my $gconf = $backend_block->{ gantry_conf };
    my $instance;
    my $conffile;

    if ( $gconf ) {
        my $gantry_conf_block = $tree->get_config->{ Conf };
        $instance             = $gantry_conf_block->{ instance };
        $conffile             = $gantry_conf_block->{ conffile };
    }

    $instance ||= $backend_block->{ instance };
    $conffile ||= $backend_block->{ conffile };

    if ( $instance ) {
        $instance .= "_$conf_type" unless $conf_type eq 'base';
        my $conffile_text = '';
        if ( $conffile ) {
            $conffile_text = ' ' x 8
                . "GantryConfFile => '$conffile',";
        }
        $config = 
"    config => {
        GantryConfInstance => '$instance',
$conffile_text
    },
";
        if ( $backend_block->{ flex_db } ) {
           $stand_alone_config =
'    config => {
        GantryConfInstance => $conf_instance,
        GantryConfFile => $conf_file,
    },' . "\n";
        }
        else {
            $stand_alone_config = $config;
        }
    }
    else {
        my $config_output = $tree->walk_postorder(
            'output_config',
            {
                backend_block => $backend_block,
                conf_type     => $conf_type,
                configs       => $configs,
                base_dir      => $opts->{ base_dir },
            }
        );

        my %configs = @{ $config_output };

        $config             = $configs{ cgi_config };
        $stand_alone_config = $configs{ stand_along_config };
    }

    if ( $backend_block->{ flex_db } and not $instance ) {
        die "Use of flex_db now requires Conf Gantry backend and "
            .   "gantry_conf statement.\n";
    }

    my $port;
    $port = $backend_block->{server_port}
            if ( defined $backend_block->{server_port} );

    my $cgi_output;
    my $perl_path = $^X;

    if ( $fast_cgi ) {
        $cgi_output = Bigtop::Backend::CGI::Gantry::fast_cgi_script(
            {
                config   => $config,
                locs     => join( '', @{ $locations } ),
                app_name => $app_name,
                literal  => $literal,
                %{ $tree->get_config() },  # Go Fish! (think template_engine)
                perl_path => $perl_path,
            }
        );
    }
    else {
        $cgi_output = Bigtop::Backend::CGI::Gantry::cgi_script(
            {
                config   => $config,
                locs     => join( '', @{ $locations } ),
                app_name => $app_name,
                literal  => $literal,
                %{ $tree->get_config() },  # Go Fish! (think template_engine)
                perl_path => $perl_path,
            }
        );
    }

    my $server_output = Bigtop::Backend::CGI::Gantry::stand_alone_server(
        {
            config   => $stand_alone_config,
            locs     => join( '', @{ $locations } ),
            app_name => $app_name,
            literal  => $literal,
            port     => $port,
            flex_db  => $backend_block->{ flex_db },
            %{ $tree->get_config() },  # Go Fish! (think template_engine)
            perl_path => $perl_path,
            instance  => $instance,
        }
    );

    return { cgi => $cgi_output, server => $server_output };
}

package # application
    application;
use strict; use warnings;

use Cwd;

sub output_config {
    my $self          = shift;
    my $child_output  = shift;
    my $data          = shift;
    my $backend_block = $data->{ backend_block };

    # see if there is already a root variable
    my $gen_root = 1;
    CONFIG_VAR:
    foreach my $var ( @{ $child_output } ) {
        $var =~ /^\s+(\S+)/;
        my $var_name = $1;
        if ( $var_name eq 'root' ) {
            $gen_root = 0;
            last CONFIG_VAR;
        }
    }

    # if no root, make one no questions asked
    if ( $gen_root ) {
        my $templates = File::Spec->catdir( qw( html templates ) );

        if ( $data->{ conf_type } =~ /^CGI|CGI$/ ) {
            my $cwd = getcwd();
            my $html = File::Spec->catdir( $cwd, $data->{ base_dir }, 'html' );
            $templates = File::Spec->catdir( $html, 'templates' );

            push @{ $child_output }, "        root => '$html:$templates',";
        }
        else {
            push @{ $child_output }, "        root => 'html:$templates',";
        }
    }

    my $output = Bigtop::Backend::CGI::Gantry::application_config(
        {
            body => join "\n", @{ $child_output },
        }
    );

    my @stand_alone_output = @{ $child_output };
    if ( $backend_block->{ flex_db } ) {
        @stand_alone_output = grep !
                                 /^\s*GantryConfInstance|^\s*GantryConfFile|/,
                                 @{ $child_output };
        unshift @stand_alone_output,
            ' ' x 8 . q!GantryConfInstance => $conf_instance,!,
            ' ' x 8 . q!GantryConfFile => $conf_file,!;
    }

    my $extra_output = Bigtop::Backend::CGI::Gantry::application_config(
        {
            body => join "\n", @stand_alone_output,
        }
    );

    return [ cgi_config => $output, stand_along_config => $extra_output ];
}

sub output_cgi_locations {
    my $self         = shift;
    my $child_output = shift;
    my $location     = shift || '/';

    my $output = Bigtop::Backend::CGI::Gantry::application_loc(
        {
            location => $location,
            name     => $self->get_name(),
            body     => join '', @{ $child_output },
        }
    );

    return [ $output ];
}

package # app_statement
    app_statement;
use strict; use warnings;

package # app_config_block
    app_config_block;
use strict; use warnings;

sub output_config {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $conf_type    = $data->{ conf_type };
    my $configs      = $data->{ configs };

    return unless $child_output;

    my $my_type      = $self->{__TYPE__} || 'base';

    return unless $my_type eq $conf_type;

    if ( $my_type ne 'base' ) {

        my %config_set_for;

        # see what conf was in the named block
        foreach my $conf_item ( @{ $child_output } ) {
            my $var = $conf_item->{ name };

            $config_set_for{ $var }++;
        }

        # fill in omitted keys from the base block
        BASE_KEY:
        foreach my $base_key ( keys %{ $configs->{ base } } ) {
            next BASE_KEY if $config_set_for{ $base_key };

            push @{ $child_output }, {
                 name  => $base_key,
                 value => $configs->{ base }{ $base_key }
            };
        }
    }

    my $output = Bigtop::Backend::CGI::Gantry::config_body(
        {
            configs             => $child_output,
        }
    );

    my @output = split /\n/, $output;

    return \@output;
}

package # app_config_statement
    app_config_statement;
use strict; use warnings;

sub output_config {
    my $self         = shift;

    my $output_vals = $self->{__ARGS__}->get_args();

    return [ { name => $self->{__KEYWORD__}, value => $output_vals } ];
}

package # controller_block
    controller_block;
use strict; use warnings;

sub output_cgi_locations {
    my $self         = shift;
    my $child_output = shift;
    my $location     = shift;

    return if $self->is_base_controller();

    my %child_loc    = @{ $child_output };

    if ( keys %child_loc != 1 ) {
        die "Error: controller '" . $self->get_name()
            . "' must have one location or rel_location statement.\n";
    }

    my $app          = $self->{__PARENT__}{__PARENT__}{__PARENT__};
    my $full_name    = $app->get_name() . '::' . $self->get_name();

    my $output = Bigtop::Backend::CGI::Gantry::controller_block_loc(
        {
            full_name     => $full_name,
            rel_loc       => $child_loc{rel_location},
            abs_loc       => $child_loc{location},
            app_location  => $location,
        }
    );

    return [ $output ];
}

# controller_statement

package # controller_statement
    controller_statement;
use strict; use warnings;

sub output_cgi_locations {
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

package # literal_block
    literal_block;
use strict; use warnings;

sub output_literal {
    my $self = shift;

    return $self->make_output( 'PerlTop' );
}

1;

=head1 NAME

Bigtop::CGI::Backend::Gantry - CGI dispatch script generator for the Gantry framework

=head1 SYNOPSIS

If your bigtop file includes:

    config {
        CGI Gantry {
            # optional statements:
                # to get a stand alone server:
                    with_server 1;
                # to use FastCGI instead of regular CGI:
                    fast_cgi 1;
        }
    }

and there are controllers in your app section, this module will generate
app.cgi when you type:

    bigtop app.bigtop CGI

or

    bigtop app.bigtop all

You can then directly point your httpd.conf directly to the generated
app.cgi.

=head1 DESCRIPTION

This is a Bigtop backend which generates cgi dispatching scripts for Gantry
supported apps.

=head1 KEYWORDS

This module does not register any keywords.  See Bigtop::CGI
for a list of allowed keywords (think app and controller level 'location'
and controller level 'rel_location' statements).

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

        no_gen
        fast_cgi
        with_server
        server_port
        flex_db
        gantry_conf
        template

        instance
        conffile

Note that instance and conffile are now deprecated in favor of setting
gantry_conf to true, which draws the values from the Conf Gantry backend.
You may still use them if you like, but that may change in the future.

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: app.server and app.cgi.

=item gen_CGI

Called by Bigtop::Parser to get me to do my thing.

=item output_cgi

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
