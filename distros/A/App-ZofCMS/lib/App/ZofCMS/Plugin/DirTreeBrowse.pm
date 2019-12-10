package App::ZofCMS::Plugin::DirTreeBrowse;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use File::Glob (qw/bsd_glob/);
use HTML::Template;

sub _key { 'plug_dir_tree' }
sub _defaults { qw(q_name dir_tree   t_prefix  dir_tree_ ) }
sub _do {
    my ( $self, $conf, $template, $query ) = @_;

    my $path = $query->{ $conf->{q_name} };

    defined $path
        or $path = $conf->{start};

    $path =~ s{^\s*/|\.\.}{}g;

    my $back_link = $path;
    $back_link =~ s{/[^/]*$}{};

    my $list = $self->_get_file_list( $path );
    if ( $conf->{re} ) {
        @$list = grep $_->{path} =~ /$conf->{re}/, @$list;
    }

    my $display_path = $path;
    $display_path =~ s|^\Q$conf->{start}\E/?||;

    if ( $conf->{display_path_separator} ) {
        $display_path =~ s|/|$conf->{display_path_separator}|g;
    }

    my $t_p = $conf->{t_prefix};
    $template->{t}{$t_p . 'path'} = $display_path;

    if ( defined $conf->{auto_html} ) {
        my $t = HTML::Template->new_scalar_ref( \ _get_template() );
        for ( @$list ) {
            $_->{page} = $query->{dir} . $query->{page};
            $_->{q_name} = $conf->{q_name};
        }
        $t->param(
            q_name        => $conf->{q_name},
            page          => $query->{dir} . $query->{page},
            class         => $conf->{auto_html},
            dir_tree_list => $list,
            ( $back_link eq $path ? () : ( dir_tree_back => $back_link ) ),
        );
        $template->{t}{$t_p . 'auto'} = $t->output;
    }
    else {
        $template->{t}{$t_p . 'list'} = $list;
        unless ( $back_link eq $path  ) {
            $template->{t}{$t_p . 'back'} = $back_link;
        }
    }
}

sub _get_file_list {
    my ( $self, $path ) = @_;

    my @path = grep { defined and length } split '/', $path;
    my $glob = join '/', @path;
    $glob .= '/*';

    my @files = map +{
        name    => (split '/')[-1],
        path    => $_,
        (
            -f $_ ? ( is_file => 1 ) : ()
        )
    }, bsd_glob $glob;

    return \@files;
}

sub _get_template {
    return <<'END';
    <ul class="<tmpl_var name='class'>">
        <tmpl_if name="dir_tree_back"><li><a href="/index.pl?page=<tmpl_var name='page'>&<tmpl_var name='q_name'>=<tmpl_var escape='html' name='dir_tree_back'>">UP</a></li></tmpl_if>
    <tmpl_loop name='dir_tree_list'>
        <li>
            <tmpl_if name="is_file">
            <a target="_blank" href="/<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            <tmpl_else>
            <a href="/index.pl?page=<tmpl_var name='page'>&<tmpl_var name='q_name'>=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            </tmpl_if>
        </li>
    </tmpl_loop>
    </ul>
END
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::DirTreeBrowse - plugin to display browseable directory tree

=head1 SYNOPSIS

=head2 SIMPLE VARIANT

In your Main Config file or ZofCMS Template:

    plugins     => [ qw/DirTreeBrowse/ ],
    plug_dir_tree => {
        auto_html => 1,
        start     => 'pics',
    },

In you L<HTML::Template> template:

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>
    <tmpl_var name='dir_tree_auto'>

=head2 MORE FLEXIBLE VARIANT

In your Main Config file or ZofCMS Template:

    plugins     => [ qw/DirTreeBrowse/ ],
    plug_dir_tree => {
        start     => 'pics',
    },

In your L<HTML::Template> template:

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>

    <ul>
        <tmpl_if name="dir_tree_back">
            <li><a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='dir_tree_back'>">UP</a></li>
        </tmpl_if>
    <tmpl_loop name='dir_tree_list'>
        <li>
            <tmpl_if name="is_file">
            <a href="/<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            <tmpl_else>
            <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            </tmpl_if>
        </li>
    </tmpl_loop>
    </ul>

=head1 DESCRIPTION

The module is an L<App::ZofCMS> plugin that provides means to display a browseable directory
three (list of files and other dirs).

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/DirTreeBrowse/ ],

First and foremost, you'd obviously would want to add the plugin into the list of plugins
to execute.

=head2 C<plug_dir_tree>

    plug_dir_tree => {
        start                  => 'pics',
        auto_html              => 'ul_class',
        re                     => qr/[.]jpg$/,
        q_name                 => 'dir_tree',
        t_prefix               => 'dir_tree_',
        display_path_separator => '/',
    }

    plug_dir_tree => sub {
        my ( $t, $q, $config ) = @_;
        return {
            start                  => 'pics',
            auto_html              => 'ul_class',
            re                     => qr/[.]jpg$/,
            q_name                 => 'dir_tree',
            t_prefix               => 'dir_tree_',
            display_path_separator => '/',
        };
    }

The C<plug_dir_tree> takes a hashref or subref as a value and can be set in either Main Config file or
ZofCMS Template file. Keys that are set in both Main Config file and ZofCMS Template file
will get their values from ZofCMS Template file. If subref is specified,
its return value will be assigned to C<plug_dir_tree> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object.
Possible keys/values of C<plug_dir_tree>
hashref are as follows:

=head3 C<start>

    plug_dir_tree => {
        start => 'pics',
    },

B<Mandatory>. Specifies the starting directory of the directory three you wish to browse. The
directory is relative to your C<index.pl> file and must be web-accessible.

=head3 C<auto_html>

    plug_dir_tree => {
        start       => 'pics',
        auto_html   => 'ul_class',
    },

B<Optional>. When set to a C<defined> value will cause the
plugin to generate directory tree HTML automatically, the value then will become the
classname for the C<< <ul> >> element that holds the list of files/dirs. See SYNOPSIS and
HTML::Template VARIABLES sectons for more details. B<Note:> the plugin does not append
current query to links, so if you wish to add something to the query parameters

=head3 C<re>

    plug_dir_tree => {
        start => 'pics',
        re    => qr/[.]jpg$/,
    }

B<Optional>. Takes a regex (C<qr//>) as a value. When specified only the files matching
this regex will be in the list. Note that file and its path will be matched, e.g.
C<pics/old_pics/foo.jpg>

=head3 C<q_name>

    plug_dir_tree => {
        start  => 'pics',
        q_name => 'dir_tree',
    }

B<Optional>. The plugin uses one query parameter to reference its position in the directory
tree. The C<q_name> key specifies the name of that query parameter. Unless you are using
the C<auto_html> option, make sure that your links include this query parameter along
with C<< <tmpl_var name="path"> >>. In other words, if your C<q_name> is set to C<dir_tree>
you'd make your links:
C<< <a href="/index.pl?page=/page_with_this_plugin&dir_tree=<tmpl_var escape='html' name='path'>"> >>. B<Defaults to:> C<dir_tree>

=head3 C<t_prefix>

    plug_dir_tree => {
        start    => 'pics',
        t_prefix => 'dir_tree_',
    }

B<Optional>. The C<t_prefix> specifies the prefix to use for several keys that plugin creates
in C<{t}> ZofCMS Template special key. See C<HTML::Template VARIABLES> section below for
details. B<Defaults to:> C<dir_tree_> (note the trailing underscore (C<_>))

=head3 C<display_path_separator>

    plug_dir_tree => {
        start                  => 'pics',
        display_path_separator => '/',
    }

B<Optional>. One of the C<{t}> keys generated by the plugin will contain the current
path in the directory tree. If C<display_path_separator> is specified, every C</> character
in that current path will be replaced by whatever C<display_path_separator> is set to.
B<By default> is not specified.

=head1 HTML::Template VARIABLES

The samples below assume that the plugin is run with all of its optional arguments set to
defaults.

=head2 When C<auto_html> is turned on

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>
    <tmpl_var name='dir_tree_auto'>

=head3 C<dir_tree_path>

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>

The C<< <tmpl_var name='dir_three_path'> >> variable will contain the current path in the
directory tree.

=head3 C<dir_tree_auto>

    <tmpl_var name='dir_tree_auto'>

The C<< <tmpl_var name='dir_tree_auto'> >> is available when C<auto_html> option is turned
on in the plugin. The generated HTML code would be pretty much as the C<MORE FLEXIBLE VARIANT>
section in C<SYNOPSIS> demonstrates.

=head2 When C<auto_html> is turned off

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>
    <ul>
        <tmpl_if name="dir_tree_back">
            <li><a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='dir_tree_back'>">UP</a></li>
        </tmpl_if>
    <tmpl_loop name='dir_tree_list'>
        <li>
            <tmpl_if name="is_file">
            <a href="/<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            <tmpl_else>
            <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            </tmpl_if>
        </li>
    </tmpl_loop>
    </ul>

=head3 C<dir_tree_path>

    <p>We are at: <tmpl_var escape='html' name='dir_tree_path'></p>

The C<< <tmpl_var name='dir_three_path'> >> variable will contain the current path in the
directory tree.

=head3 C<dir_tree_back>

    <tmpl_if name="dir_tree_back">
        <li><a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='dir_tree_back'>">UP</a></li>
    </tmpl_if>

The C<dir_tree_back> will be available when the user browsed to some directory inside the
C<start> directory. It will contain the path to the parent directory so the user could
traverse up the tree.

=head3 C<dir_tree_list>

    <tmpl_loop name='dir_tree_list'>
        <li>
            <tmpl_if name="is_file">
            <a href="/<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            <tmpl_else>
            <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
            </tmpl_if>
        </li>
    </tmpl_loop>

The C<dir_tree_list> will contain data structure suitable for C<< <tmpl_loop name=""> >>. Each
item of that loop would be an individual file or a directory. The variables that
are available in that loop are as follows:

=head4 C<is_file>

    <tmpl_if name="is_file">
        <a target="_blank" href="/<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
    <tmpl_else>
        <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>
    </tmpl_if>

The C<is_file> will be set whenever the item is a file (as opposed to being a directory).
As the example above shows, you'd use this variable as a C<< <tmpl_if name=""> >> to adjust
your links to open the file instead of trying to make the plugin "browse" that file as
a directory.

=head4 C<path>

    <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>

The C<path> variable will contain the path to the directory/file (including the name
of that directory/file) starting from the C<start> directory. You'd want to include that
as a value of C<q_name> query parameter so the user could traverse the dirs.

=head4 C<name>

    <a href="/index.pl?page=/&dir_tree=<tmpl_var escape='html' name='path'>"><tmpl_var escape='html' name='name'></a>

The C<name> variable will contain just the name of the file/directory without it's path. You'd
want to use this for for displaying the names of the files/dirs to the user.

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