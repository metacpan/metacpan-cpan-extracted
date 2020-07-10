package Bible::OBML::Gateway;
# ABSTRACT: Bible Gateway content conversion to Open Bible Markup Language (OBML)

use 5.016;

use exact;
use exact::class;
use Mojo::DOM;
use Mojo::File;
use Mojo::URL;
use Mojo::UserAgent;
use Bible::OBML;
use Bible::Reference 1.02;

our $VERSION = '1.05'; # VERSION

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
        unless ( $result and $result->code == 200 and $result->dom->at('h1.bcv') );

    return $self->_parse( $result->body, $result->dom );
}

sub _parse {
    my ( $self, $body, $dom ) = @_;

    $self->_body($body);
    $self->_dom( $dom // Mojo::DOM->new($body) );

    ( my $book_chapter = $self->_dom->at('h1.bcv')->text ) =~ s/:.+$//;

    my $passage = Mojo::DOM->new(
        $self->_dom->at('div.passage-bible div.passage-content div:first-child')->to_string
    )->at('div');

    delete $passage->root->attr->{'class'};
    $passage->at('h1')->remove;
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
        $_->tag and $_->tag eq 'span' and $_->attr('class') and $_->attr('class') eq 'chapternum'
    } )->each( sub {
        $_->replace('|1|');
    } );

    $passage->descendant_nodes->grep( sub {
        $_->tag and $_->tag eq 'sup' and $_->attr('class') and $_->attr('class') eq 'versenum'
    } )->each( sub {
        $_->replace( '|' . ( ( $_->content =~ /(\d+)/ ) ? $1 : '?' ) . '|' );
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

    my $obml = '~' . $book_chapter . "~\n\n" . $passage->content;

    $obml =~ s/^[ ]*_{2,}/ ' ' x 6 /msge;
    $obml =~ s/^[ ]*_/ ' ' x 4 /msge;
    $obml =~ s/(\{[^\}]+\})(\s*)(\[[^\]]+\])/$3$2$1/g;
    $obml =~ s/\[\*(\|\d+\|)/$1*/g;
    $obml =~ s/((?:(?:\[[^\]]+\])|\s|(?:\{[^\}]+\}))+)\*\]/*$1/g;
    $obml =~ s/\[\*/*/g;
    $obml =~ s/\*\]/*/g;
    $obml =~ s/=[^=\n]+=\n+(=[^=\n]+=)/$1/msg;
    $obml =~ s/<span.*?>(.*?)<\/span>/$1/msg;
    $obml =~ s/(\*[^\*\{\[]+)(\s*\{[^\}]*\}\s*|\s*\[[^\]]*\]\s*)/$1*$2*/msg;

    utf8::decode($obml);
    $obml = $self->_obml_lib->desmartify($obml);
    utf8::encode($obml);

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
    Mojo::File->new($filename)->spurt( $self->_body );
    return $self;
}

sub load {
    my ( $self, $filename ) = @_;
    croak('No filename provided to save to') unless ($filename);
    $self->_parse( Mojo::File->new($filename)->slurp );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::OBML::Gateway - Bible Gateway content conversion to Open Bible Markup Language (OBML)

=head1 VERSION

version 1.05

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bible-OBML-Gateway.svg)](https://travis-ci.org/gryphonshafer/Bible-OBML-Gateway)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bible-OBML-Gateway/badge.png)](https://coveralls.io/r/gryphonshafer/Bible-OBML-Gateway)

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

L<Travis CI|https://travis-ci.org/gryphonshafer/Bible-OBML-Gateway>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bible-OBML-Gateway>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-OBML-Gateway>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-OBML-Gateway.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
