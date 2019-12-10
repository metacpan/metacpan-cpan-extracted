
package App::ZofCMS::Template;

use strict;
use warnings;

our $VERSION = '1.001008'; # VERSION

use HTML::Template;

require File::Spec;
use Carp;


sub new {
    my $class = shift;
    my $config = shift;
    my $self = bless {}, $class;
    $self->config( $config );
    $self->conf( $config->conf );
    $self->query( $config->query );

    return $self;
}

sub load {
    my $self = shift;

    my $conf = $self->conf;
    my $query = $self->query;

    my $template_file = File::Spec->catfile(
        $conf->{templates},
        $query->{dir},
        $query->{page} . $conf->{zcms_template_extension},
    );

    my $template = do $template_file
        or croak "Failed to load template file [$template_file] ($!) ($@)";

    return $self->template( $template );
}

sub prepare_defaults {
    my $self = shift;

    my $template = $self->template;
    my $conf = $self->conf;
    my $query = $self->query;

    my $dir_defaults = $conf->{dir_defaults}{ $query->{dir} } || {};

    %$template = ( %$dir_defaults, %$template );
    %$template = ( %{ $conf->{template_defaults} || {} }, %$template );

    %{ $template->{conf} } = (
        %{ $conf->{template_defaults}{conf} || {} },
        %{ $dir_defaults->{conf} || {} },
        %{ $template->{conf} || {} },
    );

    %{ $template->{t} } = (
        %{ $conf->{template_defaults}{t} || {} },
        %{ $dir_defaults->{t} || {} },
        %{ $template->{t} || {} },
    );

    %{ $template->{d} } = (
        %{ $conf->{template_defaults}{d} || {} },
        %{ $dir_defaults->{d} || {} },
        %{ $template->{d} || {} },
    );

    my @plug_keys = map /(\d+)/, grep /^plugins\d+$/,
        keys %$template,
        keys %{ $conf->{template_defaults} || {} },
        keys %$dir_defaults;

    my %unique_plug_keys;
    @unique_plug_keys{ @plug_keys } = ();
    @plug_keys = sort { $a <=> $b } keys %unique_plug_keys;

    unshift @plug_keys, ''; # add this for 'plugins' key that doesn't have a number
    $self->unique_plug_keys( \@plug_keys );

    for ( @plug_keys ) {
        $template->{ "plugins$_" }  = $self->sort_plugins(
            ( $conf->{template_defaults}{ "plugins$_" } || [] ),
            ( $dir_defaults->{ "plugins$_" } || [] ),
            ( $template->{ "plugins$_" } || [] ),
        );
    }
}

sub assemble {
    my $self = shift;

    my $template = $self->template;
    my $conf = $self->conf;
    my $query = $self->query;

    my $html_template = HTML::Template->new(
        filename => File::Spec->catfile(
            $conf->{data_store},
            $template->{conf}{base},
        ),
        die_on_bad_params => $template->{conf}{die_on_bad_params} || 0,
    );

    my $data_store = $conf->{data_store};

    $self->_exec_plugins;

    $html_template->param( %{ $template->{t} } );

    while ( my ($key, $value) = each %$template ) {
        next
            if $key eq 'conf'
                or $key eq 't'
                or $key eq 'plugins'
                or $key eq 'd';

        if ( ref $value eq 'SCALAR' ) {
            my $file = File::Spec->catfile( $data_store, $$value );
            if ( substr( $file, -5) eq '.tmpl' ) {
                my $sub_html_template
                = HTML::Template->new(
                    filename => $file,
                    die_on_bad_params
                    => $template->{conf}{die_on_bad_params} || 0,
                );

                $sub_html_template->param( %{ $template->{t} } );

                $html_template->param( $key => $sub_html_template->output );
            }
            else {
                open my $fh, '<', $file
                   or croak "Failed to open file [$file] for reading ($!)";

                $html_template->param( $key => do { local $/; <$fh>; } );
                close $fh;
            }
        }
        else {
            $html_template->param( $key => $value );
        }
    }

    return $self->html_template( $html_template );
}

sub execute_before {
    return shift->_execute('before');
}
sub execute {
    return shift->_execute;
}

sub _execute {
    my $self = shift;
    my $is_before = shift;
    my $template = $self->template;
    my $conf = $self->conf;
    my $query = $self->query;

    my $conf_key = $is_before ? 'exec_before' : 'exec';

    if ( ref $template->{conf}{ $conf_key } eq 'CODE' ) {
        return $template->{conf}{ $conf_key }->(
            $query,
            $self->template,
            $self->config,
            $self->html_template,
        );
    }
    elsif ( defined $template->{conf}{ $conf_key }
        and length $template->{conf}{ $conf_key }
    ) {
        my $package = 'App::ZofCMS::Execs::' . $template->{conf}{ $conf_key };
        eval "use $package;";
        $@ and croak "Failed to use() module specified by the template "
            . "[$package] Error: $@";

        return $package->new->execute(
            $query,
            $self->template,
            $self->config,
            $self->html_template,
        );
    }

    return 1;
}


sub _exec_plugins {
    my $self = shift;
    my $template = $self->template;
    my $query    = $self->query;
    my $config   = $self->config;

    for my $plug_key ( @{ $self->unique_plug_keys } ) {
        for ( @{ $template->{ "plugins$plug_key" } || [] } ) {
            my $plugin = "App::ZofCMS::Plugin::$_";
            eval "use $plugin";
            $@ and croak "Failed to use() plugin $plugin: $@";
            $plugin->new->process( $template, $query, $config );
        }
    }

    return;
}

sub sort_plugins {
    my $self = shift;
    my ( $conf_plugins, $dir_defaults_plugins, $template_plugins, ) = @_;

    for my $plugs (
        $template_plugins , $dir_defaults_plugins, $conf_plugins
    ) {

        for ( @$plugs ) {

            unless ( ref ) {
                $_ = { name => $_,  priority => 10000, };
                next;
            }

            if (ref eq 'HASH' and 1 == keys %$_) {
                my ($name, $priority) = %$_;
                @{ $_={} }{ qw/name priority/ } = ($name, $priority);
            }
        }
    }

    my $r  = [
        map $_->{name},
        sort {
            $a->{priority}
            <=>
            $b->{priority}
        }
        $self->uniq_plugins(
            @$template_plugins,
            @$dir_defaults_plugins,
            @$conf_plugins,
        )
    ];
    return $r;
}

sub uniq_plugins {
    my $self = shift;
    my %h;
    return map { $h{ $_->{name} }++ == 0 ? $_ : () } @_;
}


sub html_template {
    my $self = shift;
    if ( @_ ) {
        $self->{ html_template } = shift;
    }
    return $self->{ html_template };
}


sub template {
    my $self = shift;
    if ( @_ ) {
        $self->{ template } = shift;
    }
    return $self->{ template };
}


sub query {
    my $self = shift;
    if ( @_ ) {
        $self->{ query } = shift;
    }
    return $self->{ query };
}


sub config {
    my $self = shift;
    if ( @_ ) {
        $self->{ config } = shift;
    }
    return $self->{ config };
}


sub conf {
    my $self = shift;
    if ( @_ ) {
        $self->{ conf } = shift;
    }
    return $self->{ conf };
}


sub unique_plug_keys {
    my $self = shift;
    if ( @_ ) {
        $self->{UNIQUE_PLUG_KEYS} = shift;
    }
    return $self->{UNIQUE_PLUG_KEYS};
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Template - "core" part of ZofCMS - web-framework/templating system

=head1 SYNOPSIS

Sample ZofCMS template named 'foo.tmpl' in "templates" directory
(see L<App::ZofCMS::Config>):

    {
        body => \'foo.tmpl',
        t   => {
            time => scalar(localtime),
        },
        conf    => {
            base    => 'base.tmpl',
        },
    }

Sample 'base.tmpl' file located in "data store" directory

    Base template
    [ <tmpl name="body"> ]
    In brakets you'll see the output of "body =&amp; \'foo.tmpl'" from
    ZofCMS template

Sample 'foo.tmpl' file in "data store" directory referenced by C<body>
key in the ZofCMS template above.

    Current time: <tmpl_var name="time">

Now if the user to access http://example.com/index.pl?page=foo they would
see the following:

    Base template
    [ Current time: Sat Jul 26 21:08:26 2008 ]
    In brakets you'll see the output of "body => \'foo.tmpl'" from
    ZofCMS template

=head1 DESCRIPTION

This module is used internally by L<App::ZofCMS> and this documentation
explains how ZofCMS templates work. B<This documentation assumes you have
read> L<App::ZofCMS::Config>.

If you wish to make changes to this module, please contact the author.

=head1 STARTING WITH THE BASICS

ZofCMS template is a hashref. Same as the config file, it's loaded with
C<do()>, thus you can do perlish stuff in it.

The "first level" keys in this hashref can take a scalar, or a scalar
reference. The exception are special keys which are described below.

The "first level" keys' values will be stuffed into
<tmpl_var name="name_of_the_first_level_key"> inside your B<base> template
(which is explained in the description of C<conf> special key).
If the key's value is a scalar, that scalar
will be directly inserted into <tmpl_var>. If the value is a scalar
reference it's taken as a filename inside your "data storage" directory.
The file will be read and its contents will be placed into <tmpl_var>
unless the filename ends with C<.tmpl>. If
filename ends with C<.tmpl> it will be treated as L<HTML::Template>
file, the keys in the special key C<t> (see L<SPECIAL KEYS> section below)
will be inserted into it, then the ->output() method will be called on it
and that output will then by inserted into <tmpl_var> in your base template.

Some plugins may take their input via "first level" keys. However, sane
plugins will delete those keys from the ZofCMS template hashref when they
are called.

=head1 SPECIAL KEYS

There are (currently) four special "first level" keys in ZofCMS template
hashref. They will NOT be stuffed into <tmpl_var>s in the base template.
Some plugins may take their input via "first level" keys, make sure to
read the documentation for any plugins you are using.

=head2 C<t>

    {
        t => {
            current_time => scalar(localtime),
        },
    }

The special key C<t> (read B<t>emplate) takes a hashref as a value which
contains keys/values which will
be inserted into C<tmpl_*> variables inside B<both>, your "base" template
(see below) and any L<HTML::Template> files loaded via "first level" keys.
Most plugins will populate this hashref when they are executed.

=head2 C<d>

    {
        d => {
            current_time => scalar(localtime),
        },
    }

The special key C<d> (read B<d>ata) is exactly the same as C<t> key except
none of its keys/values will be interpolated into any templates. The
purpose of this key is to pass around data between the templates and
plugins. Currently, I did not find this key useful, however, it is there
if you need it. Eventually, plugins may use this key as a clean method
of input (as in, they don't have to delete anything from ZofCMS template
hashref).

=head2 C<plugins>

    {
        plugins => [
            qw/DBI QueryToTemplate/, # these are set to priority 10000
            { TOC => 100 }, # this one has specific priority of 100
            { Plugin => 1000 }, # this one got priority of 1000
        ],
        plugins2 => [ # this is a second level of plugins, allows to run same plugins twice
            qw/Foo Bar Baz/
        ],
    }

Special key C<plugins> takes an B<arrayref> as a value. Can be postfixed by a number to
create several levels of plugin sets to run (allows to execute same plugins several times).
The higher the number the later that plugin set will execute.
Elements of this
arrayref can be either scalars or hashrefs. If the element is a scalar
it will be treated as the name of the plugin to load/execute; in this
case the "priority" of the plugin is set to 10000. If the element is a
hashref, the key of that hashref will be treated as the name of the
plugin to load and the value will be treated as the value for plugin's
"priority".

The "priority" of the plugin determines in what sequence it will be
executed among other plugins. Priority can be a negative number, the larger
the priority, the later the plugin will be executed. Plugins with the
same priority number are executed in non-specified order.

B<Note:> do B<NOT> use the C<App::ZofCMS::Plugin::> part of the plugin's
module name, in other words, if you have installed
L<App::ZofCMS::Plugin::QueryToTemplate> plugin, to use it you would
specify C<< plugins => [ 'QueryToTemplate' ] >>

=head2 C<conf>

    {
        conf => {
            base        => 'base.tmpl',
            exec_before => sub {
                my ( $query, $template, $config, $base ) = @_;
                $query->{foo} = 'bar'
                    unless $query->{foo} eq 'baz';

                $template->{t} = localtime;
            },
            exec => sub {
                my ( $query, $template, $config, $base ) = @_;
            },
            die_on_bad_params => 1,
        },
    }

The C<conf> key (read B<conf>iguration) is a special key. It's value
is a hashref keys of which are also special.

=head3 C<base>

    conf => { base => 'base.tmpl', }

The C<base> key in C<conf> hashref specifies the "base" template to use.
This is the "base" template mentioned above in the description of
"first level" keys of ZofCMS template hashref.
The value of C<base> key must be a scalar containing a filename of the
L<HTML::Template> located in "data store" directory. Normally, this would
be an L<HTML::Template> template used for your entire site. Of course, this
can be set in the C<template_defaults> key in your config file.

B<NOTE: the base is a (probably the only) mandatory key which MUST be
present in your ZofCMS templates (setting it in template_defaults qualifies
as such)>

=head3 C<die_on_bad_params>

    conf => {
        die_on_bad_params => 1,
    }

Takes either true or false values, defaults to a false value. As ZofCMS
matured, especially with the invention of plugins like
L<App::ZofCMS::Plugin::QueryToTemplate>, use of this option became very
limited. What it basically does (when set to a true value) is make
your application die every time ZofCMS tries to set a non-existent
C<tmpl_var> in your L<HTML::Template> templates.

=head3 C<exec_before>

    conf => {
        exec_before => sub {
            my ( $query, $template, $config, $base ) = @_;
            $query->{foo} = 'bar'
                unless $query->{foo} eq 'baz';

            $template->{t} = localtime;
        },
    },

   # OR

   conf => {
        exec_before => 'ModuleName',
   }

The C<exec_before> key in C<conf> hashref specifies which code to run before
ZofCMS template is processed. The value can be either a subref or a
scalar. If a scalar is specified as a value it must be a module name which
is located in C<$core_directory/App/ZofCMS/Execs/>. In other words, if
C<exec_before> is set to 'ModuleName', ZofCMS will run
C<$core_directory/App/ZofCMS/Execs/ModuleName.pm>. The ModuleName.pm
must have two subs: C<sub new { bless {}, shift}> and C<sub execute {}>.
Yes, it must be object oriented... don't ask why. What's given to new()
may be changed in the future.

If the value of C<exec_before> is a subref it will get the following in
its C<@_> (in that order):

    $query_ref -- a hashref of query parameters, keys are names
                  of the parameters and values are the values.

    $ZofCMS_template -- ZofCMS template hashref. In exec_before,
                       you can change anything here, including values
                       for "first level" keys.

    $config_object -- App::ZofCMS::Config object

    $base  -- HTML::Template object which is loaded with the template
              specified by conf => { base => }

If the value of C<exec_before> is a scalar with the name of the module,
the C<@_> of C<sub execute {}> will look the same except the first
element will be $self (i.e. the object)

The return value of C<exec_before> code is disregarded.

=head3 C<exec>

    conf => {
        exec => sub {
            my ( $query, $template, $config, $base ) = @_;
            $query->{foo} = 'bar'
                unless $query->{foo} eq 'baz';

            $template->{t} = localtime;
        },
    },

   # OR

   conf => {
        exec => 'ModuleName',
   }

The C<exec> key follows the same principles as C<exec_before> with two
exceptions. First, it's called after the template is processed and
plugins are executed, meaning setting anything in {t} will have no effect.
Second, returning a false value will restart processing of the template
from the very beginning. Possibility here is changing query parameters.

=head1 NOTE ON C<exec_before> AND C<exec> keys

They were implemented before the plugin system was in place. Currently
I find little use for either of them. They will stay as possibilities
in ZofCMS but I encourage you to write plugins instead.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
