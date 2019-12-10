package App::ZofCMS::Plugin::Syntax::Highlight::HTML;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

require File::Spec;
use Syntax::Highlight::HTML;

sub new { return bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{highlight_html};

    my %highlights = %{ delete $template->{highlight_html} };

    my $code_before = exists $template->{highlight_before}
                    ? delete $template->{highlight_before}
                    : '';

    my $code_after  = exists $template->{highlight_after}
                    ? delete $template->{highlight_after}
                    : '';

    my $highlighter = Syntax::Highlight::HTML->new(
        nnn     => ( defined $highlights{nnn} ? $highlights{nnn} : 0 ),
        pre     => ( defined $highlights{pre} ? $highlights{pre} : 1 ),
    );

    keys %highlights;
    while ( my ( $tag, $code ) = each %highlights ) {
        if ( ref $code eq 'SCALAR' ) {
            $code = $self->_load_code_from_file(
                $config->conf->{data_store},
                $$code,
            );
        }
        elsif ( ref $code eq 'CODE' ) {
            $code = $code->($template, $query, $config);
        }

        $template->{t}{$tag}
        = $code_before . $highlighter->parse( $code ) . $code_after;
    }

    return 1;
}

sub _load_code_from_file {
    my ( $self, $data_dir, $filename ) = @_;
    my $code_file = File::Spec->catfile( $data_dir, $filename );

    open my $fh, '<', $code_file
        or return "Failed to open $code_file [$!]";

    my $code = do { local $/; <$fh>; };
    close $fh;

    return $code;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Syntax::Highlight::HTML - provide HTML code snippets on your site

=head1 SYNOPSIS

In ZofCMS template:

    {
        body        => \'index.tmpl',
        highlight_html => {
            foohtml => '<div class="bar">beer</div>',
            bar     => sub { return '<div class="bar">beer</div>' },
            beer    => \ 'filename.of.the.file.with.HTML.in.datastore.dir',
        },
        plugins     => [ qw/Syntax::Highlight::HTML/ ],
    }

In L<HTML::Template> template:

    <tmpl_var name="foohtml">
    <tmpl_var name="bar">
    <tmpl_var name="beer">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to include
HTML (HyperText Markup Lanugage) code snippets with syntax
highlights on your pages.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 USED FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    {
        plugins => [ qw/Syntax::Highlight::HTML/ ],
    }

First and obvious is that you'd want to include the plugin in the list
of C<plugins> to run.

=head2 C<highlight_html>

    {
        highlight_html => {
            foohtml => '<div class="bar">beer</div>',
            bar     => sub { return '<div class="bar">beer</div>' },
            beer    => \ 'filename.of.the.file.with.HTML.in.datastore.dir',
        },
    }

The C<highlight_html> is the heart key of the plugin. It takes a hashref
as a value. The keys of this hashref except for two special keys described
below are the name of C<< <tmpl_var name=""> >> tags in your
L<HTML::Template> template into which to stuff the syntax-highlighted
code. The value of those keys can be either a scalar, subref or a scalarref.
They are interpreted by the plugin as follows:

=head3 scalar

    highlight_html => {
        foohtml => '<div class="bar">beer</div>'
    }

When the value of the key is a scalar it will be interpreted as HTML code
to be highlighted. This will do it for short snippets.

=head3 scalarref

    highlight_html => {
        beer    => \ 'filename.of.the.file.with.HTML.in.datastore.dir',
    },

When the value is a scalarref it will be interpreted as the name of
a I<file> in the C<data_store> dir. That file will be read and its contents
will be understood as HTML code to be highlighted. If an error occured
during opening of the file, your C<< <tmpl_var name=""> >> tag allocated
for this entry will be populated with an error message.

=head3 subref

    highlight_html => {
        bar     => sub { return '<div class="bar">beer</div>' },
    },

When the value is a subref, it will be executed and its return value will
be taken as HTML code to highlight. The C<@_> of that sub when called
will contain the following: C<< $template, $query, $config >> where
C<$template> is a hashref of your ZofCMS template, C<$query> is a hashref
of the parameter query whether it's a POST or a GET request, and
C<$config> is the L<App::ZofCMS::Config> object.

=head3 SPECIAL KEYS IN C<highlight_html>

    highlight_html => {
        nnn => 1,
        pre => 0,
    },

There are two special keys, namely C<nnn> and C<pre>, in
L<highlight_html> hashref. Their values will affect the resulting
highlighted HTML code.

=head4 C<nnn>

    highlight_html => {
        nnn => 1,
    }

Instructs the highlighter to activate line numbering.
B<Default value>: C<0> (disabled).

=head4 C<pre>

    highlight_html => {
        nnn => 0,
    }

Instructs the highlighter to surround result by <pre>...</pre> tags.
B<Default value>: C<1> (enabled).

=head2 C<highlight_before>

    {
        highlight_before => '<div class="highlights">',
    }

Takes a scalar as a value. When specified, every highlighted HTML code
will be prefixed with whatever you specify here.

=head2 C<highlight_after>

    {
        highlight_after => '</div>',
    }

Takes a scalar as a value. When specified, every highlighted HTML code
will be postfixed with whatever you specify here.

=head1 GENERATED CODE

Given C<< '<foo class="bar">beer</foo>' >> as input plugin will generate
the following code:

    <pre>
        <span class="h-ab">&lt;</span><span class="h-tag">foo</span>
        <span class="h-attr">class</span>=<span class="h-attv">"bar</span>"
        <span class="h-ab">&gt;</span>beer<span class="h-ab">&lt;/</span>
        <span class="h-tag">foo</span><span class="h-ab">&gt;</span>
    </pre>

Now you'd use CSS to highlight specific parts of HTML syntax.
Here are the classes that you can define in your stylesheet (list
shamelessly stolen from L<Syntax::Highlight::HTML> documentation):

=over 4

=item *

C<.h-decl> - for a markup declaration; in a HTML document, the only
markup declaration is the C<DOCTYPE>, like:
C<< <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"> >>

=item *

C<.h-pi> - for a process instruction like C<< <?html ...> >>
or C<< <?xml ...?> >>

=item *

C<.h-com> - for a comment, C<< <!-- ... --> >>

=item *

C<.h-ab> - for the characters C<< '<' >> and C<< '>' >> as tag delimiters

=item *

C<.h-tag> - for the tag name of an element

=item *

C<.h-attr> - for the attribute name

=item *

C<.h-attv> - for the attribute value

=item *

C<.h-ent> - for any entities: C<&eacute;> C<&#171;>

=item *

C<.h-lno> - for the line numbers

=back

=head1 SAMPLE CSS CODE FOR HIGHLIGHTING

Sebastien Aperghis-Tramoni, the author of L<Syntax::Highlight::HTML>,
was kind enough to provide sample CSS code defining the look of each
element of HTML syntax. It is presented below:

    .h-decl { color: #336699; font-style: italic; }   /* doctype declaration  */
    .h-pi   { color: #336699;                     }   /* process instruction  */
    .h-com  { color: #338833; font-style: italic; }   /* comment              */
    .h-ab   { color: #000000; font-weight: bold;  }   /* angles as tag delim. */
    .h-tag  { color: #993399; font-weight: bold;  }   /* tag name             */
    .h-attr { color: #000000; font-weight: bold;  }   /* attribute name       */
    .h-attv { color: #333399;                     }   /* attribute value      */
    .h-ent  { color: #cc3333;                     }   /* entity               */

    .h-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */

=head1 PREREQUISITES

Despite the ZofCMS design this module uses L<Syntax::Highlight::HTML>
which in turn uses L<HTML::Parser> which needs a C compiler to install.

This module requires L<Syntax::Highlight::HTML> and L<File::Spec> (the
later is part of the core)

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