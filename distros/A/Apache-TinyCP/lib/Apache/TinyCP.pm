package Apache::TinyCP;
use warnings;
use strict;

our $VERSION = "1.01";

use Apache::Constants qw(:common :response);

use Cache::File;
use Template;
use Text::KwikiFormatish;
use POSIX qw(strftime);

=head1 NAME

Apache::TinyCP - a tiny content provider to put up content really quickly

=head1 SYNOPSIS

In your Apache configuration:

    PerlModule Apache::TinyCP
    
    <Location />
        SetHandler  perl-script
        PerlHandler Apache::TinyCP

        DirectoryIndex HomePage

        PerlSetVar  ContentDir       /home/www/content
        PerlSetVar  TemplateDir      /home/www/templates
        PerlSetVar  CacheDir         /home/www/var/contentcache
        PerlSetVar  ModTimeFormat    %d.%b.%y
    </Location>

In your C<ContentDir> directory, a file named F<HomePage>, along with other
content files:

    Hello, world! *This* is the HomePage!
    
    Here's a link to AnotherPage.
    
    See [=Text::KwikiFormatish] for more info on the default formatter

In your C<TemplateDir> directory, a file named F<layout>:

    <html>
        <head>
            <title>My Site - [% title %]</title>
        </head>
        <body>
            <h1>[% title %]</h1>
            <hr/>
            [% content %]
            <hr/>
            <p>Last modified: [% modtime %]</p>
        </body>
    </html>

=head1 DESCRIPTION

This module is a very simple handler that takes files from F<ContentDir>,
formats them somehow, and stamps on a header and footer using the template file
F<template> in F<TemplateDir>. The default formatter is L<Text::KwikiFormatish>
    and the end result is somewhat of a pseudo-wiki web site. It was created
because I enjoyed the ease and functionality of Kwiki text for creating
content, but wanted something like a single-user wiki.

To set this up, create the three directories and set them as C<TemplateDir>,
C<ContentDir> and C<CacheDir> in the Apache configuration, like in
L<"SYNOPSIS">. 

By default the content files located in F<ContentDir> are formatted with
L<Text::KwikiFormatish> and cached with L<Cache::File>, which uses the path
specified at F<CacheDir> to store cache files. The default templating system is
L<Template::Toolkit>. The handler uses the F<layout> template wrapper in
C<TemplateDir>. The tags C<[% content %]>, C<[% title %]> and C<[% modified %]>
are replaced by the formatted content, the filename, and the formatted
modification date (respectively).

You could probably do this by writing a formatting handler and filtering that
through L<Apache::Template>, though I'm not sure how the caching would work.
You might also want to check out L<Apache::Sandwich>. If any of these ways
works for you, more power to ya.

My goal was to have all my content files in one place (not F<htdocs>) as well
as use wiki text for the rapid creation of content for my site.

=head1 EXTENDING

=head2 Changing the Formatter

Say you wanted to write your pages in POD instead of Kwikish text. You would
create a custom package, override the C<format_content()> method and use that
as your PerlHandler. In your Apache configuration:

    <Perl>
        use Pod::Simple::HTML ();
        
        package Local::TinyCP;
        use base qw( Apache::TinyCP );
        
        sub format_content {
            my ( $self, $data, $r ) = @_;
            my $output;
            
            my $parser = Pod::Simple::HTML->new;
            $parser->output_string( \$output );
            $parser->parse_string_document( $data );
            
            return $output;
        }
    </Perl>
    
    <Location />
        ...
        PerlHandler Local::TinyCP
        ...
    </Location>

=head2 Futher Customization

Here are all of the methods you can override. All methods are passed C<$self>,
the name of the package, as the first argument and sometimes C<$r>, the
L<Apache> request object.

=over 4

=cut

# package global to ensure only one cache object per interpreter
our $CACHE;

=item * get_filename( $self, $r )

Returns the absolute path to the content file. 

=cut

sub get_filename {
    my ( $self, $r ) = @_;

    # simply use the ContentDir directive as the basedir
    my $uri = $r->uri;
    for ($uri) {
        s#^/+##;              # leading slash
        s#[^[:print:]]##g;    # unprintables
        s#\.\./##g;           # dots, for /../../..
    }
    return $r->dir_config('ContentDir') . "/$uri";
}

=item * get_content( $self, $filename, $r )

Returns the formatted content to be inserted into the C<[% content %]> template
variable. By default, this formats with L<Text::KwikiFormatish> and caches the
formatted content using L<Cache::File>.

=cut

sub get_content {
    my ( $self, $filename, $r ) = @_;

    # ensure single instance of cache
    unless ( defined $CACHE ) {

        # no cache object? create our cache object
        $CACHE = Cache::File->new(
            cache_root      => $r->dir_config('CacheDir'),
            default_expires => '100 days',
        );

        # augh! no cache object?!!
        unless ($CACHE) {
            $r->log_reason( "Couldn't create cache object", $filename );
            return;
        }
    }

    # try to get cached content if we can, make up arbitrary cache keys
    my $content;
    my $cache_key = $filename . '|' . ( stat $filename )[9];
    unless ( $content = $CACHE->get($cache_key) ) {

        # okay, no cached content.
        # start by getting the file's contents
        my $data;
        if ( open( FH, '<' . $filename ) ) {
            $data = join( '', <FH> );
            close FH;
        }
        else {
            $r->log_reason( "Couldn't open file: $!", $filename );
            return;
        }

        #$r->log_error("*** Caching $cache_key");

        # format it
        $content = $self->format_content( $data, $r );

        # save it to the cache as the uri plus the timestamp
        $CACHE->set( $cache_key, $content );
    }

    return $content;
}

=item * format_content( $self, $data, $r )

Return the formatted version of C<$data>, the contents of the content file.

This method is only used by C<L<get_content>>. If you override
C<L<get_content>>, you will not need to override this method.

=cut

sub format_content {
    my ( $self, $data, $r ) = @_;
    return Text::KwikiFormatish::format($data);
}

=item * print_content( $self, $content, $r )

Print the given C<$content> to STDOUT. By default this method wraps the content
in a template, and provides two extra variables: C<[% title %]>, the name of
the document without a leading slash, and C<[% modtime %]>, the modification
time of the document. The modification time format is configurable -- see
L<"SYNOPSIS">.

=cut

sub print_content {
    my ( $self, $content, $r ) = @_;

    # setup title to be passed
    my $title = $r->uri;
    $title =~ s#^/##;

    # create a template toolkit object, use TemplateDir as basedir
    my $tt = Template->new(
        {   INCLUDE_PATH => $r->dir_config('TemplateDir'),
            RECURSION    => 1,
            WRAPPER      => 'layout',
        }
    );

    # no object? must be a Template::Toolkit error
    unless ($tt) {
        $r->log_error("Template::new() error: $Template::ERROR");
        return;
    }

    # go ahead and print the content!
    unless (
        $tt->process(
            \$content,
            {   title    => $title,
                modified => $r->pnotes('modified'),
            }
        )
        )
    {
        $r->log_error( "Template content error: " . $tt->error );
        return;
    }

    # everything was okay!
    # "this is the EVERYTHING'S OKAY alarm!"
    return 1;
}

=item * get_content_type( $self )

Return the content type returned. Default is C<text/html>.

This method is only used by C<L<print_content>>. If you override
C<L<print_content>>, you will not need to override this method.

=cut

sub get_content_type {'text/html'}

=item * handler( $self, $r )

mod_per1 handler method. You do not need to override this method unless you
want to change the core logic.

=cut

sub handler ($$) {
    my ( $self, $r ) = @_;

    # lookup what file we're looking for, return declined
    # if we can't find the page, or forbidden if not -r
    my $filename = $self->get_filename($r)
        or return SERVER_ERROR;

    unless ( -e $filename ) {
        return DECLINED;
    }
    unless ( -r $filename ) {
        $r->log_reason( "File exists but not readable", $filename );
        return FORBIDDEN;
    }

    # get the modification time, put in $r->pnotes('modified')
    if ( -e $filename ) {
        $r->pnotes(
            modified => strftime(
                ( $r->dir_config('ModTimeFormat') || '%F' ),
                localtime( ( stat $filename )[9] )
            )
        );
    }

    # get the formatted content
    my $content = $self->get_content( $filename, $r )
        or return SERVER_ERROR;

    # print the formatted content
    $r->send_http_header( $self->get_content_type );
    return $self->print_content( $content, $r ) ? OK: SERVER_ERROR;
}

=back

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 SEE ALSO

L<Cache::File>, L<Template>, L<Text::KwikiFormatish>

=head1 LICENSE

This is free software. You may use it and redistribute it under the same terms
as Perl itself.

=cut

74;

