package Dancer2::Plugin::Showterm;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Replay terminal typescript captures
$Dancer2::Plugin::Showterm::VERSION = '0.0.2';

use strict;
use warnings;

use File::ShareDir::Tarball;
use Path::Tiny;

use Dancer2::Plugin;

use Moo;

has assets_dir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        path(
            $_->config->{assets_dir} 
                || File::ShareDir::Tarball::dist_dir('Dancer-Plugin-Showterm') 
        );
    },
);

has stylesheet => (
    is => 'ro',
    default => sub {
        $_[0]->config->{stylesheet};
    },
);

sub BUILD {
    my $self = shift;

    $self->app->add_route(
        method => 'get',
        regexp => qr/.*\.showterm/,
        code => sub {
            my $app = shift;
            ( my $file = $app->request->path ) =~ s/\.showterm$/\.typescript/;
            my $template = $self->assets_dir->child('showterm.html')->slurp;
            $template =~ s/__FILE__/$file/g;

            $template =~ s[(?=</head>)][
                <link rel="stylesheet" href="$_" />
            ] for grep { $_ } $self->stylesheet;

            $template;
        }
    );
    $self->app->add_route(
        method => 'get',
        regexp => qr/\/showterm\/(.*)/,
        code => sub {
            my $app = shift;
            my( $path ) = $app->request->splat;
            $app->send_file(
                $self->assets_dir->child($path), system_path => 1
            );
        }
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Showterm - Replay terminal typescript captures

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

In F<config.yml>:

    plugins:
        Showterm:
            stylesheet: /my_showterm.css

In your app:

    package MyApp;
    use Dancer2;

    use Dancer2::Plugin::Showterm;

    ...

=head1 DESCRIPTION

This plugin is a L<Dancer2> port of the wonderful L<http://showterm.io>, which allows
terminal screen captures taken via the UNIX tool L<script|http://man7.org/linux/man-pages/man1/script.1.html> to be 
replayed in the browser. 

The plugin will intercept any request for files with a F<.showterm> extension and will generate an
html page that will be able to replay the same file, but with the F<.typescript> extension.

In other words, if you put the file F<mysession.typescript> in the F<public> folder of the app, then the
url F</mysession.showterm> will display its webified version. The webified version can also be embedded in other 
pages via iframes:

        <iframe src="/mysession.showterm" 
                width="660" height="360" style="border: 1px solid #444">
        </iframe>

=head1 CAPTURING THE ACTION

The cli capture is done using the UNIX utility c<script>. 
The plugin assumes that the captured screen is 80 columns by 24 rows.

    $ script -ttiming
    ... everything you do here will be recorded ...
    ^D  
    $ echo '---' | cat - timing >> typescript
    $ mv typescript /path/to/dancer/app/public/myscreen.typescript

Note that the C<typescript> file the plugin uses is the concatenation of the
original produced typescript with its timing file, separated with a type dash 
on a single line.

=head1 ADDED ROUTES

=head2 /showterm/*

The plugin adds the javascript and stylesheets assets required by the 
webified typescript under F</showterm>.  Those are bundled with the plugin as shared tarball.
If you want to see where this tarball is on your filesystem, you can do

    use Dancer2;
    use Dancer2::Plugin::Showterm;

    app->find_plugin('Dancer2::Plugin::Showterm')->assets_dir;

or

    $ perl -MFile::ShareDir=dist_dir -E'say dist_dir("Dancer-Plugin-Showterm")'

=head2 *.showterm

Any request for a file with the extension F<.showterm> will be served the showterm
page, using the same uri with its extension changed to F<.typescript> as the script to play.

=head1 CONFIGURATION

    plugins:
        Showterm:
            stylesheet: /my_showterm.css

=head2 stylesheet

If provided, will be added to the showterm page.

=head1 SEE ALSO

=over

=item L<http://showterm.io> - the original service

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
