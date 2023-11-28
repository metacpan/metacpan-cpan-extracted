package Dancer2::Plugin::LiteBlog;

=head1 NAME

Dancer2::Plugin::LiteBlog - A minimalist, file-based blog engine for Dancer2. 

=head1 DESCRIPTION

This Dancer2 plugin provides a lightweight blogging engine. Instead of relying
on a database, it utilizes flat files, primarily markdown and YAML, to store and
manage content. Through this plugin, Dancer2 applications can seamlessly
integrate a blog without the overhead of database management.

=head1 SYNOPSIS

First, you need to scaffold Liteblog's assets in your Dancer2 application directory:

   $ liteblog-scaffold . 

Then, in your Dancer2 PSGI startup script:

   # in your app.psgi 
   use Dancer2;
   use Dancer2::Plugin::LiteBlog;
   liteblog_init();

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

use strict;
use warnings;
use File::Spec;
use Carp 'croak';
use Time::HiRes qw(gettimeofday tv_interval);

use Dancer2::Plugin;

=head1 METHODS

=head2 BUILD 

At build time, sets up essential configurations for the plugin and initializes
the default routes.

Template::Toolkit is forced (all scaffolded views are designed to be TT views). 
Similarly, views tags are forced to TT's defaults: '[%' and '%]'.

A C<before_template> hook is registered to populate tokens such as settings read 
from the liteblog config (C<liteblog> entry in Dancer2's config) or the widgets 
elements (see L<Dancer2::Plugin::LiteBlog::Widget>).

A default C<GET /> route is defined and handles the landing page of the liteblog 
site.

=cut

sub BUILD {
    my $plugin = shift;

    $plugin->dsl->info("LiteBlog Init: forcing template_toolkit with '[%', '%]'");
    $plugin->app->config->{template} = 'template_toolkit';
    $plugin->app->config->{engines}->{template}->{template_toolkit} = {
        start_tag => '[%',
        end_tag   => '%]',
    };

    # Start the timer before each request
    $plugin->app->add_hook( Dancer2::Core::Hook->new(
        name => 'before',
        code => sub {
            $plugin->dsl->var(request_start_time => [gettimeofday]);
        }
    ));

    # Prepare default template tokens with appropriate resources.
    $plugin->app->add_hook( Dancer2::Core::Hook->new(
        name => 'before_template',
        code => sub {
            my $tokens = shift;
            my $liteblog = $plugin->dsl->config->{'liteblog'};
            
            if ($liteblog->{show_render_time}) {
                my $start_time = $plugin->dsl->vars->{'request_start_time'};
                my $end_time = [gettimeofday];
                my $elapsed = tv_interval($start_time, $end_time);
                $tokens->{render_time} = int($elapsed * 1000); # in ms.
                $tokens->{render_time} = 'less than a' if ($tokens->{render_time} == 0);
                $tokens->{render_time} .= ' ms.';
            }

            foreach my $k (keys %{ _default_tokens() }) {
                $tokens->{$k} = _default_tokens()->{$k};
            }

            # build Google fonts source if any defined in settings
            if ($liteblog->{google_fonts}) {
                my $gfonts = $liteblog->{google_fonts};
                if (ref($gfonts) ne 'ARRAY') {
                    $plugin->dsl->warning("google_fonts should be an array, ignoring");
                }
                else {
                    my $gfont_str = join('&', map { "family=${_}:wght\@400;700" } @$gfonts) . '&display=swap';
                    $tokens->{google_fonts} = $gfont_str;
                }
            }

            return $tokens;
        }
    ));

    $plugin->dsl->info("LiteBlog Init: registering route GET /");
    $plugin->app->add_route(
        method => 'get',
        regexp => '/',
        code   => sub {
            $plugin->dsl->info("in the index route");
            return $plugin->dsl->template(
                'liteblog/index', {}, { layout => 'liteblog' }
            );
        });
}

sub _init_default {
    my ($liteblog) = @_;

    $liteblog->{base_url} //= $ENV{HTTP_HOST} // 'http://set.base_url.in.config';
    $liteblog->{base_url} =~ s/\/$//; # remove trailing '/'

    $liteblog->{tags} ||= [];
    $liteblog->{footer} //= $liteblog->{title};
    $liteblog->{show_render_time} //= 0;
    $liteblog->{google_fonts} //= [qw(Lato Roboto Merriweather Open+Sans)];

    return $liteblog;
}

sub _init_favicon_token {
    my ($tokens, $k, $liteblog) = @_;

    if ($k eq 'favicon') {
        my $favicon = $liteblog->{$k};
        my $mime;
        if ($favicon =~ /\.ico$/) {
            $mime = 'image/x-icon'; 
        }
        elsif ($favicon =~ /\.png$/) {
            $mime = 'image/png'; 
        }
        elsif ($favicon =~/\.jpe?g$/) {
            $mime = 'image/jpeg'; 
        }
        else {
            return 0;
        }
        $tokens->{favicon}   = $favicon;
        $tokens->{mime_icon} = $mime;
        return 1;
    }
    return 0;
}

sub _init_footer_token {
    my ($tokens, $k, $liteblog) = @_;

    if ($k eq 'footer') {
        $tokens->{footer}   = $liteblog->{$k};
        $tokens->{footer}  .= ' &middot; Built with <a href="https://metacpan.org/pod/Dancer2::Plugin::LiteBlog">Liteblog</a>' 
            unless $liteblog->{no_liteblog_footer};
        return 1;
    }
    return 0;
}


=head2 liteblog_init

A Liteblog app must call this keyword right after having C<use>'ed Dancer2::Plugin::Liteblog.
This allows to declare widget-specific routes (defined in the Widget's classes) once the 
config is fully read by Dancer2 (which is not the case at BUILD time).

This method also initializes all default tokens that will be passed to template
calls.

=cut

my $_default_tokens = {};
sub _default_tokens { $_default_tokens }

sub liteblog_init {
    my ($plugin) = @_;
    $plugin->dsl->info("Liteblog init");

    my $liteblog = $plugin->dsl->config->{'liteblog'};
    my $widgets = _load_widgets($plugin, $liteblog);

    # init default tokens once for all
    my $tokens = {};
    $liteblog = _init_default($liteblog);

    # all config entry of Liteblog is exposed in the tokens
    foreach my $k (keys %$liteblog) {
        $plugin->dsl->info("setting token '$k'");
        _init_favicon_token($tokens, $k, $liteblog) and next;
        _init_footer_token($tokens, $k, $liteblog) and next;
        $tokens->{$k} = $liteblog->{$k};
    }
    $tokens->{tags} = join(', ', @{ $liteblog->{tags} });

    # Populate the loaded widgets in the tokens 
    $tokens->{widgets} = $widgets;
    $tokens->{no_widgets} = scalar(@$widgets) == 0;

    # set a default title, if unset
    $tokens->{title} = $liteblog->{'title'} || "A Great Liteblog Site" 
    if !defined $tokens->{title};

    # Set the navigation elements for the nav bar
    my $navigation = $liteblog->{navigation};
    $tokens->{navigation} = $navigation if defined $navigation;
    $_default_tokens = $tokens;

    # implement the declared routes of all registered widgets 
    foreach my $widget (@{ $widgets }) {
        my $w = $widget->{instance};
        $plugin->dsl->info("Widget '".$widget->{name}."' registered");
        next if ! $w->has_routes;

        $plugin->dsl->info("Widget '".$widget->{name}."' has routes to declare");
        $w->declare_routes($plugin, $widget);
    }
}

=head2 render_client_error($message)

Immediatly exits from the current route handler and render a 404
page with Liteblog's default templates.

=cut

sub render_client_error {
    my ($plugin, $message) = @_;
    
    # log the error
    $plugin->dsl->error('['.ref($plugin).
        "] Client Error: $message");

    $plugin->dsl->status('not_found');
    $plugin->dsl->template('liteblog/single-page', 
        {
            page_title => "Page Not Found",
            content => $message
        },
        {layout => 'liteblog'});
}

plugin_keywords 'liteblog_init';


# Private subs 

# Loads all widgets and initializes them. Each widget is responsible for a
# specific function or display within the blog. They are associated to stylesheets
# in public/css/liteblog/widgets/$widget.css and views in
# views/liteblog/$widget.
sub _load_widgets {
    my ($plugin, $liteblog) = @_;

    # Load all widgets and initialize them 
    my @widgets;
    my $id = 1;
    foreach my $w (@{ $liteblog->{widgets} }) {
        my $elements = [];
        my $widget;
        
        my $class = 'Dancer2::Plugin::LiteBlog::'.ucfirst($w->{name});
        $plugin->dsl->info("Initializing widget: $class");

        my $module;
        eval {
            $module = File::Spec->catfile(split /::/, $class) . '.pm';
            require $module;
        };
        if ($@) {
            $plugin->dsl->error("Unable to import '$module': $@");
            next;
        }
        else {
            $plugin->dsl->info("Widget '$module' successfully imported");
        }

        eval { 
            $widget = $class->new( 
                    root   => $plugin->dsl->config->{'appdir'}, 
                    dancer => $plugin->dsl,
                    %{$w->{params}}
                );
        };
        
        if ($@) {
            $plugin->dsl->error("Unable to initialized widget '".
            $w->{name}."' : $@");
            next;
        }
        else {
            $plugin->dsl->info("Widget '$class' successfully initialized");
        }

        $elements = $widget->elements;

        if (scalar(@$elements)) {
            push @widgets, { 
                id => $id++,
                name => $w->{name}, 
                %{$w->{params}},
                view => $w->{name}.'.tt',
                instance => $widget,
                elements => $elements,
            };
        }
    }
    return \@widgets;
}


1; # End of Dancer2::Plugin::LiteBlog

=head1 AUTHOR

Alexis Sukrieh, C<< <sukria at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-liteblog at
rt.cpan.org>, or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-LiteBlog>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::LiteBlog

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-LiteBlog>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Dancer2-Plugin-LiteBlog>

=item * Search CPAN

L<https://metacpan.org/release/Dancer2-Plugin-LiteBlog>

=item * GitHub Official Repository

L<https://github.com/sukria/Dancer2-Plugin-LiteBlog>

=item * The Author's personal site, built with Liteblog

L<https://alexissukrieh.com>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Alexis Sukrieh.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
