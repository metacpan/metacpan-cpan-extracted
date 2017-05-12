package Catalyst::Plugin::Assets;

use warnings;
use strict;

=head1 NAME

Catalyst::Plugin::Assets - Manage and minify .css and .js assets in a Catalyst application

=head1 VERSION

Version 0.036

=cut

our $VERSION = '0.036';

=head1 SYNOPSIS

    # In your Catalyst application... 

    use Catalyst qw/-Debug Assets Static::Simple/;
    # Static::Simple is not *required*, but C::P::Assets does not serve files by itself!
    
    # This is all you need. Now your $catalyst object will now have an ->assets method.

    # Sometime during the request ...

    sub some_action : Local {
        my ($self, $catalyst) = @_;
        
        ...

        $catalyst->assets->include("stylesheet.css");

        ...
    }

    # Then, in your .tt (or whatever you're using for view processing):

    <html>
    <head><title>[% title %]</title>

    [% catalyst.assets.export %]

    </head>
    <body>

    ...
    
=head1 DESCRIPTION

Catalyst::Plugin::Assets integrates L<File::Assets> into your Catalyst application. Essentially, it provides a unified way to include .css and .js assets from different parts of your program. When you're done processing a request, you can use $catalyst->assets->export() to generate HTML or $catalyst->assets->exports() to get a list of assets.

C::P::Assets will also handle .css files of different media types properly.

In addition, C::P::Assets includes support for minification via YUI compressor, L<JavaScript::Minifier>, L<CSS::Minifier>, L<JavaScript::Minifier::XS>, and L<CSS::Minifier::XS>

Note that Catalyst::Plugin::Assets does not serve files directly, it will work with Static::Simple or whatever static-file-serving mechanism you're using.

=head2 A brief description of L<File::Assets>

L<File::Assets> is a tool for managing JavaScript and CSS assets in a (web) application. It allows you to "publish" assests in one place after having specified them in different parts of the application (e.g. throughout request and template processing phases).

=head1 USAGE

For usage hints and tips, see L<File::Assets>

=head1 CONFIGURATION

You can configure C::P::Assets by manipulating the $catalyst->config->{'Plugin::Assets'} hash.

Note, in previous versions, the configuration location was $catalyst->config->{assets}

The following settings are available:

    path        # A path to automatically look for assets under (e.g. "/static" or "/assets")

                # This path will be automatically prepended to includes, so that instead of
                # doing ->include("/static/stylesheet.css") you can just do ->include("stylesheet.css")
                

    output_path # The path to output the results of minification under (if any).
                # For example, if output is "built/" (the trailing slash is important), then minified assets will be
                # written to "root/<assets-path>/built/..."


    minify      # '1' to use JavaScript::Minifier and CSS::Minifier for minification
                # 'yuicompressor:<path-to-yuicompressor-jar>' to use YUI Compressor


    stash_var   # The name of the key in the stash that provides the assets object (accessible via $catalyst->stash->{<stash_var}.
                # By default, the <stash_var> is "assets".
                # To disable the setting of the stash variable, set <stash_var> to undef

=head2 Example configuration

Here is an example configuration:

    # Under the configuration below, the assets object will automatically
    # look for assets (.css and .js files) under <home>/root/static/*
    # If it needs to generate a minified asset, it will deposit the generated asset under <home>/root/static/built/*

    # To turn off minification, set minify to 0

    # Finally, the assets object is also available via $catalyst->stash->{assets} (This is actually the default setting)

    __PACKAGE__->config(
        
        name => 'Example',

        'Plugin::Assets' => {

            path => "/static",
            output_path => "built/",
            minify => 1,

            stash_var => "assets", # This is the default setting
        },

    );

    # Later, to include "http://localhost/static/example.css", do:

    $catalyst->assets->include("example.css");

    # To include "http://localhost/static/example.js", do:

    $catalyst->assets->include("example.js");

=cut

use File::Assets;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/_assets/);

=head1 METHODS

=cut

sub setup {
    my $catalyst = shift;
    
    $catalyst->maybe::next::method(@_);
    
    my $config;
    if ($config = $catalyst->config->{'Plugin::Assets'}) {
    }
    elsif ($config = $catalyst->config->{assets}) {
        warn
            "\n*** Setting ${catalyst}->config->{assets} has been deprecated!\n" .
            "*** Please update your configuration to use ${catalyst}->config->{'Plugin::Assets'} instead...\n" .
            "*** I'm copying 'assets' into 'Plugin::Assets' ...\n";
        $catalyst->config->{'Plugin::Assets'} = $config;
    }
    else {
        $config = {};
    }

    
    $config->{stash_var} = "assets" unless exists $config->{stash_var};
}

sub prepare {
    my $self = shift;
    
    my $catalyst = $self->maybe::next::method(@_);

    $catalyst->assets; # Instantiate some new assets to use for this request

    return $catalyst;
}

=head2 assets

Return the L<File::Assets> object that exists throughout the lifetime of the request

=cut

sub assets {
    my $self = shift;
    return $self->{_assets} ||= do {
        my $assets = $self->make_assets;
        my $config = $self->config->{'Plugin::Assets'};
        if (defined (my $stash_var = $config->{stash_var})) {
            $self->stash->{$stash_var} = $assets;
        }
        $assets;
    }
}

sub make_assets {
    my $self = shift;

    my $config = $self->config->{'Plugin::Assets'};
    my $path = $config->{path};
    my $output_path = $config->{output_path} || $config->{output};

    my %assets;
    # Different from previous version, KISS
    if (my $minify = $config->{minify}) {
        if ($minify =~ m/^\s*(?:on|yes|true)\s*$/i) {
            $assets{minify} = 1;
        }
        elsif ($minify =~ m/^\s*(?:off|no|false|0)\s*$/i) {
        }
        elsif (ref $minify eq "") { # yuicompressor:... etc.
            $assets{minify} = $minify;
        }
        else {
            die "Don't understand minify option: $minify";
        }
    }

    my $assets = File::Assets->new(
        base => { uri => $self->uri_for("/"), dir => $self->path_to("root"), path => $path },
        output_path => $output_path,
        %assets,
    );

    if (my $customize = $config->{customize}) {
        $customize->($assets, $self);
    }

    return $assets;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Assets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Assets>

=back

=head1 SEE ALSO

L<File::Assets>

L<Catalyst>

L<http://developer.yahoo.com/yui/compressor/>

L<JavaScript::Minifier::XS>

L<CSS::Minifier::XS>

L<JavaScript::Minifier>

L<CSS::Minifier>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Catalyst::Plugin::Assets
