package App::ZofCMS::Plugin::Syntax::Highlight::CSS;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

require File::Spec;
use Syntax::Highlight::CSS;

sub new { return bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{highlight_css};

    my %highlights = %{ delete $template->{highlight_css} };

    my $code_before = exists $template->{highlight_css_before}
                    ? delete $template->{highlight_css_before}
                    : '';

    my $code_after  = exists $template->{highlight_css_after}
                    ? delete $template->{highlight_css_after}
                    : '';

    my $highlighter = Syntax::Highlight::CSS->new(
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

App::ZofCMS::Plugin::Syntax::Highlight::CSS - provide syntax highlighted CSS code snippets on your site

=head1 SYNOPSIS

In ZofCMS template:

    {
        body        => \'index.tmpl',
        highlight_css => {
            foocss => '* { margin: 0; padding: 0; }',
            bar     => sub { return '* { margin: 0; padding: 0; }' },
            beer    => \ 'filename.of.the.file.with.CSS.in.datastore.dir',
        },
        plugins     => [ qw/Syntax::Highlight::CSS/ ],
    }

In L<HTML::Template> template:

    <tmpl_var name="foocss">
    <tmpl_var name="bar">
    <tmpl_var name="beer">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to include
CSS (Cascading Style Sheets) code snippets with syntax
highlights on your pages.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 USED FIRST-LEVEL ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    {
        plugins => [ qw/Syntax::Highlight::CSS/ ],
    }

First and obvious is that you'd want to include the plugin in the list
of C<plugins> to run.

=head2 C<highlight_css>

    {
        highlight_css => {
            foocss  => '* { margin: 0; padding: 0; }',
            bar     => sub { return '* { margin: 0; padding: 0; }' },
            beer    => \ 'filename.of.the.file.with.CSS.in.datastore.dir',
        },
    }

The C<highlight_css> is the heart key of the plugin. It takes a hashref
as a value. The keys of this hashref except for two special keys described
below are the name of C<< <tmpl_var name=""> >> tags in your
L<HTML::Template> template into which to stuff the syntax-highlighted
code. The value of those keys can be either a scalar, subref or a scalarref.
They are interpreted by the plugin as follows:

=head3 scalar

    highlight_css => {
        foocss => '* { margin: 0; padding: 0; }'
    }

When the value of the key is a scalar it will be interpreted as CSS code
to be highlighted. This will do it for short snippets.

=head3 scalarref

    highlight_css => {
        beer    => \ 'filename.of.the.file.with.CSS.in.datastore.dir',
    },

When the value is a scalarref it will be interpreted as the name of
a I<file> in the C<data_store> dir. That file will be read and its contents
will be understood as CSS code to be highlighted. If an error occured
during opening of the file, your C<< <tmpl_var name=""> >> tag allocated
for this entry will be populated with an error message.

=head3 subref

    highlight_css => {
        bar     => sub { return '* { margin: 0; padding: 0; }' },
    },

When the value is a subref, it will be executed and its return value will
be taken as CSS code to highlight. The C<@_> of that sub when called
will contain the following: C<< $template, $query, $config >> where
C<$template> is a hashref of your ZofCMS template, C<$query> is a hashref
of the parameter query whether it's a POST or a GET request, and
C<$config> is the L<App::ZofCMS::Config> object.

=head3 SPECIAL KEYS IN C<highlight_css>

    highlight_css => {
        nnn => 1,
        pre => 0,
    },

There are two special keys, namely C<nnn> and C<pre>, in
L<highlight_css> hashref. Their values will affect the resulting
highlighted CSS code.

=head4 C<nnn>

    highlight_css => {
        nnn => 1,
    }

Instructs the highlighter to activate line numbering.
B<Default value>: C<0> (disabled).

=head4 C<pre>

    highlight_css => {
        nnn => 0,
    }

Instructs the highlighter to surround result by <pre>...</pre> tags.
B<Default value>: C<1> (enabled).

=head2 C<highlight_css_before>

    {
        highlight_css_before => '<div class="my-highlights">',
    }

Takes a scalar as a value. When specified, every highlighted CSS code
will be prefixed with whatever you specify here.

=head2 C<highlight_css_after>

    {
        highlight_after => '</div>',
    }

Takes a scalar as a value. When specified, every highlighted CSS code
will be postfixed with whatever you specify here.

=head1 GENERATED CODE

Given C<'* { margin: 0; padding: 0; }'> as input plugin will generate
the following code (line-breaks were edited):

    <pre class="css-code">
        <span class="ch-sel">*</span> {
        <span class="ch-p">margin</span>:
        <span class="ch-v">0</span>;
        <span class="ch-p">padding</span>:
        <span class="ch-v">0</span>; }
    </pre>

Now you'd use CSS to highlight specific parts of CSS syntax.
Here are the classes that you can define in your stylesheet:

=over 6

=item *

C<css-code> - this is actually the class name that will be set on the
C<< <pre>> >> element if you have that option turned on.

=item *

C<ch-sel> - Selectors

=item *

C<ch-com> - Comments

=item *

C<ch-p> - Properties

=item *

C<ch-v> - Values

=item *

C<ch-ps> - Pseudo-selectors and pseudo-elements

=item *

C<ch-at> - At-rules

=item *

C<ch-n> - The line numbers inserted when C<nnn> key is set to a true value

=back


=head1 SAMPLE CSS CODE FOR HIGHLIGHTING

    .css-code {
        font-family: 'DejaVu Sans Mono Book', monospace;
        color: #000;
        background: #fff;
    }
        .ch-sel, .ch-p, .ch-v, .ch-ps, .ch-at {
            font-weight: bold;
        }
        .ch-sel { color: #007; } /* Selectors */
        .ch-com {                /* Comments */
            font-style: italic;
            color: #777;
        }
        .ch-p {                  /* Properties */
            font-weight: bold;
            color: #000;
        }
        .ch-v {                  /* Values */
            font-weight: bold;
            color: #880;
        }
        .ch-ps {                /* Pseudo-selectors and Pseudo-elements */
            font-weight: bold;
            color: #11F;
        }
        .ch-at {                /* At-rules */
            font-weight: bold;
            color: #955;
        }
        .ch-n {
            color: #888;
        }

=head1 PREREQUISITES

This plugin requires L<Syntax::Highlight::CSS>. You can use
C<zofcms_helper> script to locally place it into ZofCMS "core" directory:

    zofcms_helper --nocore --core your_sites_core --cpan Syntax::Hightlight::CSS

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