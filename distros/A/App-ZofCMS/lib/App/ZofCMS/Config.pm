package App::ZofCMS::Config;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use CGI qw/:standard Vars/;
use Carp;

require File::Spec;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->cgi( CGI->new );
    $self->query( $self->_prepare_query );

    return $self;
}

sub load {
    my ( $self, $conf_file, $no_page_check ) = @_;


    my $conf = do $conf_file
        or croak "Failed to load config file ($!) ($@)";

    defined $conf->{zcms_template_extension}
        or $conf->{zcms_template_extension} = '.tmpl';

    unless ( $no_page_check ) {
        my $query = $self->query;
        my $is_valid_page = $self->_is_valid_page(
            $query,
            $conf,
        );

        unless ( $is_valid_page ) {
            @$query{ qw/page dir/ } = qw|404 /|;
        }
    }

    return $self->conf( $conf );
}

sub _is_valid_page {
    my ( $self, $query, $conf ) = @_;

    my ( $ext, $templates_dir, $valid_pages )
    = @$conf{ qw/zcms_template_extension templates valid_pages/ };

    unless ( ref $valid_pages eq 'HASH' ) {
        croak "Config file error: valid_pages must be a hashref";
    }

    for ( @{ $valid_pages->{pages} || [] } ) {
        return 1
            if $_ eq $query->{dir} . $query->{page};
    }

    for ( @{ $valid_pages->{dirs} || [] } ) {
        return 1
            if $_ eq $query->{dir}
                and -e File::Spec->catfile( $templates_dir, $query->{dir}, $query->{page} . $ext);
    }

    return 0;
}

sub _prepare_query {
    my $self = shift;

    my %query = Vars();

    unless ( defined $query{page} and length $query{page} ) {
        $query{page} = 'index';
    }

    if ( $query{page} =~ m|/| ) {
        ( $query{dir}, $query{page} ) = $query{page} =~ m|(.*/)([^/]*)$|;
    }

    unless ( defined $query{page} and length $query{page} ) {
        $query{page} = 'index';
    }

    unless ( defined $query{dir} and length $query{dir} ) {
        $query{dir} = '/';
    }

    $query{dir} =~ s/\Q..//g;

    $query{dir} = "/$query{dir}"
        unless substr($query{dir}, 0, 1) eq '/';

    $query{dir} .= '/'
        unless substr($query{dir}, -1) eq '/';

    return \%query;
}

sub cgi {
    my $self = shift;
    if ( @_ ) {
        $self->{ cgi } = shift;
    }
    return $self->{ cgi };
}


sub query {
    my $self = shift;
    if ( @_ ) {
        $self->{ query } = shift;
    }
    return $self->{ query };
}


sub conf {
    my $self = shift;
    if ( @_ ) {
        $self->{ conf } = shift;
    }
    return $self->{ conf };
}



1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Config - "core" part of ZofCMS - web-framework/templating system

=head1 SYNOPSIS

This module is part of "core" of ZofCMS web-framework/templating system.
Please read L<App::ZofCMS> if you haven't done so already. The module is
not to be used as a standalone module, thus no synopsys is provided.

=head1 ZofCMS CONFIGURATION FILE

    # sample contents of config.txt ZofCMS configuration file
    {
        data_store      => '../zcms_site/data',
        templates       => '../zcms_site/templates',
        valid_pages => {
            pages   => [
                '/index',
                '/foo/bar/baz',
            ],
            dirs    => [
                '/',
                '/tools/',
                '/tools/ZofCMS/',
            ],
        },
        template_defaults => {
            t   => {
                top => '<a class="back_to_top" href="#">back to top</a>',
            },
            conf    => {
                base    => 'base.tmpl',
            },
            plugins => [ qw/TOC Breadcrumbs/ ],
        },
        dir_defaults => {
            '/' => {
                t => {
                    current_dir => '/',
                }
            },
            '/foos/' => {
                t => {
                    current_dir => '/foos/',
                },
            },
        },
        zcms_template_extension => '.tmpl',
    };

ZofCMS config file is just a text file which contains a perl hashref. Note:
the config file will be loaded with C<do>, thus it's perfectly fine to
do something perlish in the config file before having a hashref as the last
thing in the file; that includes the ability to do something like this:

    {
        template_defaults => {
            t => {
                current_time => scalar(localtime),
            },
        },
    }

The config file specifies which pages are "valid" pages for displaying.
Specifies where is your "data" storage (i.e. your <HTML::Template> files)
and your "templates" storage (i.e. your ZofCMS templates). Besides that,
in the config file you can specify some of the default parameters which will
be included in your ZofCMS templates unless you override them (from the
templates). Extra keys in the config files may be introduced by some
plugins (e.g L<App::ZofCMS::Plugin::DBI>). Currently, the following keys
have meaning for ZofCMS core:

=head2 C<data_store>

    {
        data_store => '../zcms_site/data',
    }

The C<data_store> key specifies the directory (relative you C<index.pl>)
with your "data", i.e. the L<HTML::Template> files which you can reference
from ZofCMS templates. More on this in L<App::ZofCMS::Template> documentation

=head2 C<templates>

    {
        templates => '../zcms_site/templates',
    }

Alike C<data_store>, C<templates> key points to the directory where you
keep your ZofCMS template files which are explained in
L<App::ZofCMS::Template> documentation. B<Note:> the value of this key is
refered to as "templates dir" in the documentation below.

=head2 C<valid_pages>

    {
        valid_pages => {
            pages   => [
                '/index',
                '/foo/bar/baz',
            ],
            dirs    => [
                '/',
                '/tools/',
                '/tools/ZofCMS/',
            ],
        },
    }

The C<valid_pages> specify which particular pages are available on your
site. If the page provided to C<index.pl> via C<page> and (optionally)
C<dir> parameter does not match C<valid_page> the user will be presented
with a 404 - Not Found page. The C<valid_pages> value is a hashref with
two keys each of which takes an arrayref as an argument; they are explained
a little further below, but first:

=head3 Note on C<page> and C<dir> query parameters

Which page to display in ZofCMS is determined by two query parameters:
C<page> and C<dir>. They are calculated in the following passion:

If C<page> query parameter is not specified it will default to
'index', if C<dir> query parameter is not specified it will default to
C</>. If C<page> query parameter contains a slash (C</>) the C<page>
will be split and the part containing the slash will B<overwrite> anything
that you've set to the C<dir> query parameter. In other words these two
mean the same thing: C<index.pl?page=foo/bar>  C<index.pl?page=bar&dir=foo>.
In fact, the C<index.pl?page=foo/bar> will be transformed into
C<index.pl?page=bar&dir=/foo/> by App::ZofCMS::Config module, note how
the leading and ending slash was appended to the C<dir> automatically.

B<Note:> personally I use Apache's C<mod_rewrite> to "fix" the query,
in other words, the example above the URI can look like
C<http://example.com/foo/bar>

=head3 C<pages>

    pages   => [
        '/index',
        '/foo/bar/baz',
    ],

The C<pages> key's arrayref contains valid pages, listed one by one.
If we would to take site http://example.com/ running on ZofCMS as an
example, and would specify only
C<< pages => [ '/index', '/foo/bar/baz', ] >> in the config file and would
not specify the C<dirs> key (see below) then the only pages accessible
on the site would be C<http://example.com/> and
C<http://example.com/index.pl?page=foo/bar/baz>. Of course,
C<http://example.com/index.pl?page=index&dir=/> is the same as
C<http://example.com/>, see B<Note on page and dir query parameters>
above.

The way the check on C<pages> is done is:
C<$dir_param . $page_param eq $some_page_in_pages_arrayref>. If all of
pages from C<pages> arrayref failed then the check against C<dirs> is done.

=head3 C<dirs>

    dirs => [
        '/',
        '/tools/',
        '/tools/ZofCMS/',
    ],

The check for valid pages using C<dirs> arrayref is a bit different and
serves as a shortcut of some sort. What is done with the elements in
C<dirs> arrayref is ZofCMS makes a path and a filename in the following
form: $templates_dir (see above) + $dir_param (query parameter C<dir>)
+ $page_param (query parameter C<page>) + C<'.tmpl'> then it checks
if that file exists; if it doesn't - user is presented with 404.

Let's make this information into an example. Let's assume that you have set
your "templates dir" to
C<../zcms_site/templates/>, you didn't set anything for C<pages> key in
C<valid_pages> in your configuration file but you've set
C<< dirs => [ '/tools/' ] >> for C<valid_pages>. On top of all that,
you have created a file C<../zcms_site/templates/tools/stuff.tmpl> which
is the only file in that directory.
If user would go to C<http://example.com/index.pl?page=tools/stuff>,
ZofCMS would interpret C<../zcms_site/templates/tools/stuff.tmpl> template
and display a page, any other pages would give him a 404.

B<Note:> directories specified in C<dirs> arrayref are not recursable, i.e.
specifying C<< dirs => [ '/' ] >>  enable pages in '/tools/'. Later, a
special flag to indicate recursing may be implemented.

=head2 C<template_defaults>

    {
        template_defaults => {
            foo => 'bar',
            t   => {
                top => 'blah',
            },
            d   => {
                foo => 'bar',
            }
            conf    => {
                base    => 'base.tmpl',
            },
            plugins => [ qw/TOC Breadcrumbs/ ],
        },
    }

These are the "defaults" for all of ZofCMS templates of your ZofCMS site.
In other words (refering to the example above) if you don't set key C<foo>
in any of your ZofCMS templates, it will take on its default value C<bar>.

The exception are special keys (which are described in
L<App::ZofCMS::Template>): C<t>, C<d>, C<conf> and C<plugins>, their
B<contents> will act as defaults. In other words, (again refering to the
sample above) if you set C<< t => { foo => 'bar' } >> in your ZofCMS
template, the result will be as if you have set
C<< t => { foo => 'bar', top => 'blah' } >>. Same applies for special keys
C<d>, C<conf> and C<plugins>.

B<Note>: as you will read later, C<plugins> key takes an arrayref, keys of
which may be scalars or hashrefs containing priority numbers. If you
add the same plugin in the template itself and C<template_defaults>, plugin
will be executed only once. If you add the same plugin with different
priority numbers, the priority number set in the template itself will be
used.

=head2 C<dir_defaults>

        dir_defaults => {
            '/' => {
                t => {
                    current_dir => '/',
                }
            },
            '/foos/' => {
                t => {
                    current_dir => '/foos/',
                },
            },
        }

The C<dir_defaults> key functions exactly the same as C<template_defaults>
(see above) with one exception, it's directory-specific. Once again, it
takes a hashref as a value, the keys of that hashref are directories for
which you want to apply the defaults specified as values, which are hashrefs
identical to C<template_defaults>.

By "directory" is meant the C<dir> query parameter that is calculated
as is described in section B<Note on page and dir query parameters>
above.

B<Note:> when specifying the "directory keys", make sure to have the leading
and ending slash (or just one slash if it's a "root" directory),
because that's what the C<dir> query parameter looks like after being
processed.

=head2 C<zcms_template_extension>

    { zcms_template_extension => '.tmpl', }

B<Optional>. The C<zcms_template_extension> key takes a string as an argument. This string
represents the extensions for your ZofCMS Template files. B<Defaults to:> C<.tmpl>

=head1 METHODS

The methods described below can be used either by plugins (see
L<App::ZofCMS::Plugin> or by code
specified in C<exec_before> and C<exec> keys in ZofCMS template, this
is described in L<App::ZofCMS::Template>

=head2 C<cgi>

    my $cgi = $config->cgi;

Takes no arguments, returns a L<CGI> object which is created during
loading of your main config file.

=head2 C<query>

    my $query = $config->query;

    $config->query( { new => 'query', param => 'value' } );

Takes an optional argument which must be a hashref. The keys of this
hashref will appear as if they are query parameters and the values will
appear as if they are values of those parameters by any
plugins/exec_before/exec code which processes query after your call.
Returns a hashref keys of which represent query parameters and values
are obviously values of those parameters. B<Note:> this hashref
is created from L<CGI>'s C<Vars()> function. Refer to L<CGI> documentation
if something doesn't look right.

=head2 C<conf>

    my $conf = $config->conf;
    $config->conf( { data_store => '../zcms_site/data' } );

Returns the hashref of your main config file. Takes one optional argument
which is a hashref, it will be appear as if it was loaded from your
main config file -- bad idea to set it like this, in my opinion.

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