package Bible::OBML::Gateway;
# ABSTRACT: Bible Gateway content conversion to Open Bible Markup Language (OBML)

use 5.020;

use exact;
use exact::class;
use Mojo::DOM;
use Mojo::Util qw( encode decode );
use Mojo::File 'path';
use Mojo::URL;
use Mojo::UserAgent;
use Bible::OBML 1.14;
use Bible::Reference 1.05;

our $VERSION = '1.12'; # VERSION

has ua  => sub { return Mojo::UserAgent->new };
has url => sub { return Mojo::URL->new('https://www.biblegateway.com/passage/') };

has translation => 'NIV';
has obml        => undef;
has data        => undef;

has _reference => sub {
    return Bible::Reference->new(
        bible    => 'Protestant',
        acronyms => 1,
        sorting  => 1,
    );
};

has _obml_lib => sub { Bible::OBML->new };
has _body     => undef;
has _dom      => undef;

sub get {
    my ( $self, $book_chapter, $translation ) = @_;
    croak('Book/chapter not defined in call to get()') unless ($book_chapter);
    croak('Verse ranges and partial chapter ranges not supported') if ( $book_chapter =~ /[:-]/ );

    my $url = $self->url->query({
        search  => $book_chapter,
        version => ( $translation // $self->translation ),
    })->to_string;

    my $result = $self->ua->get($url)->result;
    croak(qq{Failed to get "$book_chapter" via "$url"})
        unless ( $result and $result->code == 200 and $result->dom->at('div.dropdown-display-text') );

    return $self->_parse( $result->body, $result->dom );
}

sub _parse {
    my ( $self, $body, $dom ) = @_;

    $self->_body($body);
    $self->_dom( $dom // Mojo::DOM->new($body) );

    ( my $book_chapter = $self->_dom->at('div.dropdown-display-text')->text ) =~ s/:.+$//;

    my $passage = Mojo::DOM->new(
        $self->_dom->at('div.passage-text div.passage-content div:first-child')->to_string
    )->at('div');

    delete $passage->root->attr->{'class'};
    $passage->descendant_nodes->grep( sub { $_->type eq 'comment' } )->each( sub { $_->remove } );

    $passage->descendant_nodes->grep( sub { $_->tag and $_->tag eq 'i' } )->each( sub {
        $_->replace( '^' . $_->content . '^' );
    } );

    my $footnotes;
    if ( my $div_footnotes = $passage->at('div.footnotes') ) {
        $footnotes = {
            map {
                '#' . $_->attr('id') => $self->_reference->clear->in(
                    $_->at('span')->content
                )->as_text
            } $div_footnotes->find('ol li')->each
        };
        $div_footnotes->remove;
    }

    my $crossrefs;
    if ( my $div_crossrefs = $passage->at('div.crossrefs') ) {
        $crossrefs = {
            map {
                '#' . $_->attr('id') => $self->_reference->clear->in(
                    $_->at('a:last-child')->attr('data-bibleref')
                )->refs
            } $div_crossrefs->find('ol li')->each
        };
        $div_crossrefs->remove;
    }

    $passage->descendant_nodes->grep( sub { $_->tag and $_->tag eq 'sup' and $_->attr('class') } )->each( sub {
        if ( $_->attr('class') eq 'footnote' ) {
            $_->replace( '[' . $footnotes->{ $_->attr('data-fn') } . ']' );
        }
        elsif ( $_->attr('class') eq 'crossreference' ) {
            $_->replace( '{' . $crossrefs->{ $_->attr('data-cr') } . '}' );
        }
    } );

    $passage->descendant_nodes->grep( sub { $_->tag and ( $_->tag eq 'h3' or $_->tag eq 'h4' ) } )->each( sub {
        $_->replace( "= " . $_->content . " =\n\n" );
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') =~ /\bchapternum\b/
    } )->each( sub {
        $_->replace('|1| ');
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'sup' and $_->attr('class') and $_->attr('class') =~ /\bversenum\b/
    } )->each( sub {
        $_->replace( '|' . ( ( $_->content =~ /(\d+)/ ) ? $1 : '?' ) . '| ' );
    } );

    $passage->descendant_nodes->grep( sub { $_->tag and $_->tag eq 'p' } )->each( sub {
        $_->replace( $_->content . "\n\n" );
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') eq 'woj'
    } )->each( sub {
        $_->replace( '[*' . $_->content . '*]' );
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') =~ 'text '
    } )->each( sub {
        $_->replace( $_->content );
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'div' and $_->attr('class') and $_->attr('class') =~ 'poetry'
    } )->each( sub {
        $_->descendant_nodes->grep( sub { $_->tag and $_->tag eq 'br' } )->each( sub { $_->replace("\n_") } );

        $_->descendant_nodes->grep( sub {
            $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') eq 'indent-1-breaks'
        } )->each( sub { $_->remove } );

        $_->descendant_nodes->grep( sub {
            $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') eq 'indent-1'
        } )->each( sub { $_->replace( '_' . $_->content ) } );

        $_->replace( '_' . $_->content );
    } );

    my $obml = '~ ' . $book_chapter . " ~\n\n" . $passage->content;

    $obml = $self->_obml_lib->desmartify($obml);

    $obml =~ s/<span.*?>(.*?)<\/span>/$1/sg; # rm <span> tags but keep content
    $obml =~ s|<[^>]*>||sg;                  # rm all remaining HTML

    $obml =~ s/\|1\|(.*?\|1\|)/$1/s; # rm dup verse # if chapter # fails override (ex: John 8)

    $obml =~ s/[ \t]+/ /g;             # turn all whitespace ranges into single spaces
    $obml =~ s/[ ]*\r?[ ]*\n[ ]*/\n/g; # rm spacing around line breaks and fix line breaks
    $obml =~ s/\n{3,}/\n\n/g;          # rm extra blank lines
    $obml =~ s/(?:^\s+|\s+$)//g;       # rm initial or postscript blank lines

    $obml =~ s/^_{2,}/ ' ' x 6 /mge; # set double-indent (ex: Heb 1)
    $obml =~ s/^_/     ' ' x 4 /mge; # set double-indent (ex: Heb 1)

    $obml =~ s/(\{[^\}]+\})(\s*)(\[[^\]]+\])/$3$2$1/g; # reorder crossrefs before footnotes

    # move footnotes, spaces, and crossrefs in front of woj end to after the woj end
    $obml =~ s/((?:(?:\[[^\]]+\])|\s|(?:\{[^\}]+\}))+)\*\]/*$1/g;

    $obml =~ s/\[\*/*/g; # set woj start
    $obml =~ s/\*\]/*/g; # set woj end

    $obml =~ s/([\*^])(\|\d+\|)(\s*)/$2$3$1/g; # fix markings left of verse number (ex: John 8)
    $obml =~ s/=[^=\n]+=\n+(=[^=\n]+=)/$1/mg;  # rm preceeding duplicate header lines

    $self->data( $self->_obml_lib->parse($obml) );
    $self->obml( $self->_obml_lib->render( $self->data ) );

    return $self;
}

sub html {
    my ($self) = @_;
    croak('No result to return HTML for') unless ( $self->_body );
    return $self->_body;
}

sub save {
    my ( $self, $filename ) = @_;
    croak('No filename provided to save to') unless ($filename);
    croak('No result to return HTML for') unless ( $self->_body );
    path($filename)->spurt( $self->_body );
    return $self;
}

sub load {
    my ( $self, $filename ) = @_;
    croak('No filename provided to save to') unless ($filename);
    $self->_parse( decode( 'UTF-8', path($filename)->slurp ) );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::OBML::Gateway - Bible Gateway content conversion to Open Bible Markup Language (OBML)

=head1 VERSION

version 1.12

=for markdown [![test](https://github.com/gryphonshafer/Bible-OBML-Gateway/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bible-OBML-Gateway/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bible-OBML-Gateway/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bible-OBML-Gateway)

=head1 SYNOPSIS

    use Bible::OBML::Gateway;

    my $bg = Bible::OBML::Gateway->new;
    $bg->translation('NIV');

    my $obml = $bg->get( 'Romans 12', 'NIV' )->obml;
    my $data = $bg->get( 'Romans 12' )->data;
    my $html = $bg->get('Romans 12')->html;

    $bg->get( 'Romans 12', 'NIV' )->save('Romans_12_NIV.html');
    say $bg->load('Romans_12_NIV.html')->obml;

=head1 DESCRIPTION

This module consumes Bible Gateway content and converts it to Open Bible Markup
Language (OBML).

=head1 METHODS

The following methods are supported.

=head2 new

Instantiates a new gateway object. You can optionally pass a translation
acronym to be used on subsequent requests.

    my $bg = Bible::OBML::Gateway->new( translation => 'NIV' );

=head2 translation

Get or set the current translation acronym.

    say $bg->translation;
    $bg->translation('NIV');

=head2 get

Gets the raw HTML content for a given chapter represented by book, chapter,
and translation. The book and chapter can be combined with a space. The
translation if provided will override the translation set in the object.

    $bg->get( 'Romans 12', 'NIV' );
    $bg->get('Romans 12');

=head2 obml

Parses the previously C<get()>-ed raw HTML if it hasn't been parsed yet and
returns Open Bible Markup Language (OBML) using L<Bible::OBML>.

    my $obml = $bg->get('Romans 12')->obml;

=head2 data

Parses the previously C<get()>-ed raw HTML if it hasn't been parsed yet and
returns a data structure of content that could be passed into L<Bible::OBML>'s
C<render()> method.

    my $data = $bg->get('Romans 12')->data;

=head2 html

Returns the previously C<get()>-ed raw HTML.

    my $html = $bg->get('Romans 12')->html;

=head2 save

Saves the previously C<get()>-ed raw HTML to a file.

    $bg->get('Romans 12')->save('Romans_12_NIV.html');

=head2 load

Loads raw HTML from a file.

    say $bg->load('Romans_12_NIV.html')->obml;

=head1 SEE ALSO

L<Bible::OBML>, L<Bible::OBML::HTML>, L<Bible::Reference>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bible-OBML-Gateway>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bible::OBML::Gateway>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bible-OBML-Gateway/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bible-OBML-Gateway>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-OBML-Gateway>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-OBML-Gateway.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
