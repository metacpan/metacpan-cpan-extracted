package App::ZofCMS::Plugin::BreadCrumbs;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use HTML::Template;
use File::Spec::Functions (qw/catfile splitdir/);

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $bread_conf = delete $template->{breadcrumbs};
    $bread_conf = delete $config->conf->{breadcrumbs}
        unless defined $bread_conf;

    return
        if ref $bread_conf eq 'HASH'
            and not keys %$bread_conf;

    %$bread_conf = (
        key     => 'title',

        %{ $bread_conf || {} },
    );

    my @crumbs;
    my $templates_dir = $config->conf->{templates};
    my @dirs = splitdir $query->{dir};

    pop @dirs
        if $dirs[-1] eq '';

    for ( 0 .. $#dirs ) {
        push @crumbs, [
            catfile( $templates_dir, @dirs[0..$_], 'index.tmpl' ),
            catfile( @dirs[0..$_], 'index' ),
        ];
    }
    unless ( $query->{page} eq 'index' ) {
        push @crumbs, [
            catfile( $templates_dir, $query->{dir}, $query->{page} . '.tmpl' ),
            catfile( @$query{ qw/dir page/ } ),
        ];
    }

    my %no_crumb_pages = map { $_ => 1 }
        @{ $bread_conf->{no_pages} || [] };

    @crumbs = map $self->_parse_crumb( $bread_conf, $_ ),
        grep { not exists $no_crumb_pages{ $_->[1] } }
            @crumbs;

    my $last_crumb = pop @crumbs;

    my $html_template = HTML::Template->new_scalar_ref(
        $bread_conf->{span}
        ? \ $self->_span_template
        : \ $self->_list_template
    );

    $html_template->param(
        crumbs      => \@crumbs,
        last_text   => $last_crumb->{text},
    );
    $template->{t}{breadcrumbs} = $html_template->output;
    return 1;
}

sub _parse_crumb {
    my ( $self, $bread_conf ) = splice @_, 0, 2;
    my ( $file, $link ) = @{ $_[0] };

    my $template = do $file
        or return ();

    my $link_text = $template->{ $bread_conf->{key} };

    $link_text = ''
        unless defined $link_text;

    if ( $bread_conf->{text_re} ) {
        ( $link_text ) = $link_text =~ /$bread_conf->{text_re}/;
    }

    if ( $bread_conf->{change} ) {
        keys %{ $bread_conf->{change} };
        while ( my ( $re, $text ) = each %{ $bread_conf->{change} } ) {
            if ( $link_text =~ /$re/ ) {
                $link_text = $text;
            }
        }
    }

    if ( $bread_conf->{replace} ) {
        keys %{ $bread_conf->{replace} };
        while ( my ( $re, $sub ) = each %{ $bread_conf->{replace} } ) {
            $link_text =~ s/$re/$sub/g;
        }
    }

    return {
        link    => $bread_conf->{direct} ? $link : "/index.pl?page=$link",
        text    => $link_text,
    };
}

sub _span_template {
    return <<'END_TEMPLATE';
<span class="breadcrumbs">[<tmpl_loop name="crumbs"><a href="<tmpl_var name="link">"><tmpl_var name="text"></a></tmpl_loop><span class="last_brumb"><tmpl_var name="last_text"></span>]</span>
END_TEMPLATE
}

sub _list_template {
    return <<'END_TEMPLATE';
<ul class="breadcrumbs"><tmpl_loop name="crumbs">
    <li><a href="<tmpl_var name="link">"><tmpl_var name="text"></a></li></tmpl_loop>
    <li class="last_crumb"><tmpl_var name="last_text"></li>
</ul>
END_TEMPLATE
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::BreadCrumbs - add "breadcrumbs" navigation to your sites

=head1 SYNOPSIS

In your ZofCMS template:

    plugins => [ qw/BreadCrumbs/ ]

In your L<HTML::Template> template:

    <tmpl_var name="breadcrumbs">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to add
a "breadcrumbs" (L<http://en.wikipedia.org/wiki/Breadcrumb_(navigation)>)
to your pages.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 HOW DOES IT WORK

The plugin automagically generates breadcrumb links, if your sites are
relatively simple and pages are in good hierarchy the plugin will do
the Right Thing(tm) most of the time. The links for breadcrumbs are
determined as follows. If the page is not called C<index> then the
C<index> page in the current "directory" will be added to the breadcrumbs,
the "path" will be broken down to pieces and C<index> page in each piece
will be added to the breadcrumbs. B<Note:> the examples below assume
that the C<no_pages> argument was not specified:

    # page
    index.pl?page=/foo/bar/baz

    # crumbs
    /index => /foo/index => /foo/bar/index => /foo/bar/baz


    # page
    index.pl?page=/foo/bar/beer/index

    # crumbs
    /index => /foo/index/ => /foo/bar/index => /foo/bar/beer/index

=head1 FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/BreadCrumbs/ ]

First and obvious you need to add C<BreadCrumbs> to the list of plugins
to execute. Just this will already make the plugin execute, i.e. having
the C<breadcrumbs> key (see below) is not necessary.

=head2 C<breadcrumbs>

    breadcrumbs => {}, # disable the plugin

    # lots of options
    breadcrumbs => {
        direct      => 1,
        span        => 1,
        no_pages => [ '/comments' ],
        key         => 'page_title',
        text_re     => qr/([^-]+)/,
        change      => {
            qr/foo/ => 'foos',
            qr/bar/ => 'bars',
        },
        replace     => {
            qr/foo/ => 'foos',
            qr/bar/ => 'bars',
        },
    },

The C<breadcrumbs> first-level ZofCMS template key controls the behaviour
of the plugin. Can be specified as the first-level key in Main Config File, but unlike many
other plugins the hashref keys do NOT merge; i.e. if you set the key in both files, the value
in ZofCMS Template will take precedence. The key takes a hashref as a value.
Do B<NOT> specify this key if you wish to use all the
defaults, as specifying an I<empty hashref> as a value will B<disable> the
plugin for that given page. Possible keys/values of that hashref are as
follows:

=head3 C<direct>

    { direct => 1 },

B<Optional>. Takes either true or false values. When set to a B<false> value
the breadcrumb links will all be of form C</index.pl?page=/index>. When
set to a B<true> value the links will be of form C</index> which is
useful when you are making your URIs with something like C<mod_rewrite>.
B<Defaults to:> false

=head3 C<span>

    { span => 1 },

B<Optional>. The C<span> key takes either true
or false values. When set to a true value, the plugin will
generate C<< <span> >> based breadcrumbs. When set to a false value, the
plugin will generate C<< <ul> >> based breadcrumbs. B<Default to:> false.

=head3 C<no_pages>

    { no_pages => [ '/comments', '/index' ], }

B<Optional>. Takes an arrayref as a value. Each element of that array
must be a C<dir> + C<page> (as described in I<Note on page and dir query
parameters> in L<App::ZofCMS::Config>). If a certain element of that
array matches the page in the breadcrumbs being generated it will be
removed from the breadcrumbs. In other words, if you specify
C<< no_pages => [ '/index' ] >> the "index" page of the "root"
directory will not show up in the breadcrumbs. B<By default> is not
specified.

=head3 C<key>

    { key => 'title', }

B<Optional>. When walking up the "tree" of pages plugin will open ZofCMS
templates for those pages and use the C<key> key's value as the text
for the link. Only first-level keys are supported. B<Defaults to:>
C<title>

=head3 C<text_re>

    { text_re => qr/([^-]+)/ }

B<Optional>. Takes a regex (C<qr//>) as a value which must contain
a capturing set of parentheses. When specified will run the regex on the
value of C<key> (see above) key's value and whatever was captured in the
capturing parentheses will be used for the text of the link. B<By default>
is not specified.

=head3 C<change>

    change => {
        qr/foo/ => 'foos',
        qr/bar/ => 'bars',
    },

B<Optional>. Takes a hashref as a value. The keys of that hashref are
regexen (C<qr//>) and the values are the text with which the B<entire>
text of the link will be replaced if that particular regex matches. In other
words, if you specify C<< change => { qr/foo/ => 'foo' } >> and your
link text is C<lots and lots of foos> it will turn into just C<foo>.
B<By default> is not specified.

=head3 C<replace>

    replace => {
        qr/foo/ => 'foos',
        qr/bar/ => 'bars',
    },

B<Optional>. Same as C<change> key described above, except C<replace> will
B<replace the matching part> with the text provided as a value. In other
words, if you specify C<< replace => { qr/foo/ => 'BAR' } >> and your
link text is C<lots and lots of foos> it will turn into
C<lots and lots of BARs>. B<By default> is not specified.

=head1 HTML::Template TEMPLATE VARIABLES

    <tmpl_var name="breadcrumbs">

The plugin set one key - C<breadcrumbs> - in C<{t}> special key which
means that you can stick C<< <tmpl_var name="breadcrumbs"> >> in any
of your L<HTML::Template> templates and this is where the breadcrumbs
will be placed.

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