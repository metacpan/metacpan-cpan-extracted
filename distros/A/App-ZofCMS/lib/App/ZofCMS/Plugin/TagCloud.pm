package App::ZofCMS::Plugin::TagCloud;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use HTML::Template;
use List::Util (qw/shuffle/);

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my %conf = (
        id          => 'zofcms_tag_cloud',
        class       => 'zofcms_tag_cloud',
        unit        => '%',
        uri_prefix  => '',
        shuffle     => 0,
        fg          => '#00d',
        bg          => 'transparent',
        fg_hover    => '#66f',
        bg_hover    => 'transparent',
        fg_visited  => '#333',
        bg_visited  => 'transparent',
        %{ delete $config->conf->{plug_tag_cloud} || {} },
        %{ delete $template->{plug_tag_cloud}     || {} },
    );

    return
        unless keys %conf;

    my @tags = @{ delete $conf{tags} };
    if ( not ref $tags[0] ) {
        @tags = map [ splice @tags, 0, 3 ], 0..$#tags/3;
    }

    if ( $conf{shuffle} ) {
        @tags = shuffle @tags;
    }

    my $t = $self->_tag_template;
    $t->param(
        id => $conf{id},
        tags => [
            map +{
                tag     => $_->[0],
                href    => $conf{uri_prefix} . $_->[1],
                class   => do {
                    my $x = $conf{class} . $_->[2];
                    $x =~ s/[^\w-]/_/g;
                    $x;
                },
            }, @tags
        ],
    );

    $template->{t}{tag_cloud} = $t->output;
    $template->{t}{tag_cloud_css} = $self->_make_css( \@tags, \%conf );
}

sub _make_css {
    my ( $self, $tags, $conf ) = @_;
    my @sizes = sort { $a <=> $b } map $_->[2], @$tags;
    my $t = $self->_css_template;
    $t->param(
        tags => [
            map +{
                class       => $conf->{class},
                class_num   => do { my $x = $_; $x =~ s/[^\w-]/_/g; $x; },
                num         => $_,
                unit        => $conf->{unit},
            }, @sizes
        ],
        map +( $_ => $conf->{ $_ } ),
            qw/id fg bg fg_hover bg_hover fg_visited bg_visited/,
    );
    return $t->output;
}

sub _css_template {
    return HTML::Template->new_scalar_ref( \ <<'END'
    #<tmpl_var name="id"> li {
        display: inline;
    }
        #<tmpl_var name="id"> a {
            color: <tmpl_var name="fg">;
            background: <tmpl_var name="bg">;
        }
        #<tmpl_var name="id"> a:visited {
            color: <tmpl_var name="fg_visited">;
            background: <tmpl_var name="bg_visited">;
        }
        #<tmpl_var name="id"> a:hover {
            color: <tmpl_var name="fg_hover">;
            background: <tmpl_var name="bg_hover">;
        }
        <tmpl_loop name="tags">.<tmpl_var name="class"><tmpl_var name="class_num"> { font-size: <tmpl_var name="num"><tmpl_var name="unit">; }
        </tmpl_loop>
END
    );
}

sub _tag_template {
    return HTML::Template->new_scalar_ref( \ <<'END'
<ul id="<tmpl_var escape="html" name="id">"><tmpl_loop name="tags">
    <li class="<tmpl_var escape="html" name="class">"><a href="<tmpl_var escape="html" name="href">"><tmpl_var escape="html" name="tag"></a></li></tmpl_loop>
</ul>
END
    );
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::TagCloud - generate "tag clouds"

=head1 SYNOPSIS

In your ZofCMS template or main config file:

    plug_tag_cloud => {
        unit => 'em',
        tags => [ qw(
                foo /foo 2
                bar /bar 1
                ber /ber 3
            )
        ],
    }

In your L<HTML::Template> template:

    <style type="text/css">
        <tmpl_var name="tag_cloud_css">
    </style>

    <tmpl_var name="tag_cloud">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>; it generates "tag clouds" (bunch of different-sized
links).

This documentation assumes you have read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 ZofCMS TEMPLATE/MAIN CONFIG FILE KEYS

    plug_tag_cloud => {
        id          => 'tag_cloud_container',
        class       => 'tag_cloud_tag',
        unit        => 'em',
        shuffle     => 1,
        uri_prefix  => 'http://site.com/',
        fg          => '#00d',
        bg          => 'transparent',
        fg_hover    => '#66f',
        bg_hover    => 'transparent',
        fg_visited  => '#333',
        bg_visited  => 'transparent',
        tags => [ qw(
                foo /foo 2
                bar /bar 1
                ber /ber 3
            )
        ],
    }

Plugin gets its data through C<plug_tag_cloud> first-level key in either ZofCMS template
or main config file. Specifying this key in ZofCMS template will completely override whatever
you set under that key in main config file.

The key takes a hashref as a value. Possible keys/values of that hashref are as follows:

=head2 C<tags>

    tags => [ qw(
            foo /foo 2
            bar /bar 1
            ber /ber 3
        )
    ],

    # or

    tags => [
        [ qw(foo /foo 2) ],
        [ qw(bar /bar 1) ],
        [ qw(ber /ber 3) ],
    ],

B<Mandatory>.
The C<tags> key takes an arrayref as a value. Elements of that arrayref can be either
either plain strings or arrayrefs. You cannot mix the two. If elements are plain strings
they will be converted internally into the "arrayref form" by grouping by three
(see examples above, they are equivalent).

The elements of the inner arrayrefs are as follows: B<first element> is the text for the
link in the tag cloud. B<Second element> is the URI to which the tag points.
B<Third element> is the "weight" of the tag, the larger the number the larger the tag will be.
The third element actually also serves for the C<font-size> value in the CSS code generated
by the plugin.

=head2 C<id>

    id => 'tag_cloud_container',

B<Optional>.
The C<id> key takes a string as a value. This sting will be used for the C<id=""> attribute
of the tag cloud C<< <ul> >> element. B<Defaults to:> C<zofcms_tag_cloud>

=head2 C<class>

    class => 'tag_cloud_tag',

B<Optional>.
The C<class> key takes a string as a value. This sting will be used to generate class names
for cloud tags. B<Defaults to:> C<zofcms_tag_cloud>

=head2 C<unit>

    unit => 'em',

B<Optional>.
The C<unit> key takes a string as a value. This string must be a valid CSS unit for
C<font-size> property. Whatever you pass in here will be directly used in the generated
CSS code and the number for that unit will be taken from the "weight" of the cloud tag
(see C<tags> key above). B<Defaults to:> C<%>

=head2 C<shuffle>

    shuffle => 1,

B<Optional>.
Takes either true or false value. When set to a true value the elements of your tag cloud
will be shuffled each and every time. B<Default to:> C<0>

=head2 C<uri_prefix>

    uri_prefix  => 'http://site.com/',

B<Optional>.
The C<uri_prefix> takes a string as a value. This string will be prepended to all of the
URIs to which your tags are pointing. B<Defaults to:> empty string.

=head2 C<fg>

    fg => '#00d',

B<Optional>.
Specifies the color to use for foreground on C<< <a href=""> >> elements;
will be directly used for C<color> property in
generated CSS code. B<Defaults to:> C<#00d>.

=head2 C<bg>

    bg => 'transparent',

B<Optional>.
Specifies the color to use for background on C<< <a href=""> >> elements;
will be directly used for C<background> property in
generated CSS code. B<Defaults to:> C<transparent>.

=head2 C<fg_hover>

    fg_hover => '#66f',

B<Optional>.
Same as C<fg> except this one is used for C<:hover> pseudo-selector. B<Defaults to:> C<#66f>

=head2 C<bg_hover>

    bg_hover => 'transparent',

B<Optional>.
Same as C<bg> except this one is used for C<:hover> pseudo-selector. B<Defaults to:>
C<transparent>

=head2 C<fg_visited>

    fg_visited  => '#333',

B<Optional>.
Same as C<fg> except this one is used for C<:visited> pseudo-selector. B<Defaults to:> C<#333>

=head2 C<bg_visited>

B<Optional>.
Same as C<bg> except this one is used for C<:visited> pseudo-selector. B<Defaults to:>
C<transparent>

=head1 HTML::Template TEMPLATE VARIABLES

The plugin will stuff two keys into C<{t}> special key in your ZofCMS templates. This means
that you can use them in your L<HTML::Template> templates.

=head2 C<tag_cloud>

    <tmpl_var name="tag_cloud">

This one will contain the HTML code for your tag cloud.

=head2 C<tag_cloud_css>

    <style type="text/css">
        <tmpl_var name="tag_cloud">
    </style>

This one will contain the CSS code for your tag cloud. You obviously don't have to use this
one and instead code your own CSS.

=head1 EXAMPLE OF GENERATED HTML CODE

    <ul id="tag_cloud">
        <li class="tag_cloud_tag3"><a href="http://site.com/ber">ber</a></li>
        <li class="tag_cloud_tag2"><a href="http://site.com/foo">foo</a></li>
        <li class="tag_cloud_tag1"><a href="http://site.com/bar">bar</a></li>
    </ul>

=head1 EXAMPLE OF GENERATED CSS CODE

    #tag_cloud li {
        display: inline;
    }
        #tag_cloud a {
            color: #f00;
            background: #00f;
        }
        #tag_cloud a:visited {
            color: #000;
            background: transparent;
        }
        #tag_cloud a:hover {
            color: #FFf;
            background: transparent;
        }
        .tag_cloud_tag1 { font-size: 1em; }
        .tag_cloud_tag2 { font-size: 2em; }
        .tag_cloud_tag3 { font-size: 3em; }

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