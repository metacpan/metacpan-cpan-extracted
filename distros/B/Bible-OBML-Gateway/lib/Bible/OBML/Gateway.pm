package Bible::OBML::Gateway;
# ABSTRACT: Bible Gateway content conversion to Open Bible Markup Language

use 5.020;

use exact;
use exact::class;
use Bible::OBML;
use Bible::Reference;
use Mojo::DOM;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Util 'html_unescape';

our $VERSION = '2.02'; # VERSION

has translation => 'NIV';
has url         => Mojo::URL->new('https://www.biblegateway.com/passage/');
has ua          => sub {
    my $ua = Mojo::UserAgent->new( max_redirects => 3 );
    $ua->transactor->name( __PACKAGE__ . '/' . ( __PACKAGE__->VERSION // '2.0' ) );
    return $ua;
};
has reference => Bible::Reference->new(
    bible   => 'Protestant',
    sorting => 1,
);

sub translations ($self) {
    my $translations;

    $self->ua->get( $self->url )->result->dom->find('select.search-dropdown option')->each( sub {
        my $class = $_->attr('class') || '';

        if ( $class eq 'lang' ) {
            my @language = $_->text =~ /\-{3}(.+)\s\(([^\)]+)\)\-{3}/;
            push( @$translations, {
                language => $language[0],
                acronym  => $language[1],
            } );
        }
        elsif ( not $class ) {
            my @translation = $_->text =~ /\s*(.+)\s\(([^\)]+)\)/;
            push( @{ $translations->[-1]{translations} }, {
                translation => $translation[0],
                acronym     => $translation[1],
            } );
        }
    } );

    return $translations;
}

sub structure ( $self, $translation = $self->translation ) {
    return $self->ua->get(
        $self->url->clone->path( $self->url->path . 'bcv/' )->query( { version => $translation } )
    )->result->json->{data}[0];
}

sub _retag ( $tag, $retag ) {
    $tag->tag($retag);
    delete $tag->attr->{$_} for ( keys %{ $tag->attr } );
}

sub fetch ( $self, $reference, $translation = $self->translation ) {
    my $runs = $self->reference->acronyms(0)->clear->in($reference)->as_runs;
    croak(
        '"' . ( $reference // '(undef)' ) . '" not understood as a single chapter or single run of verses'
    ) if ( @$runs != 1 or $runs->[0] !~ /\w\s*\d/ );

    return $self->ua->get(
        $self->url->query( {
            version => $translation,
            search  => $runs->[0],
        } )
    )->result->body;
}

sub parse ( $self, $html ) {
    my $dom = Mojo::DOM->new( $html // '' );

    my $ref_display = $dom->at('div.dropdown-display-text');
    croak('source appears to be invalid; check your inputs') unless ( $ref_display and $ref_display->text );
    my $reference = $ref_display->text;

    my $block = $dom->at('div.passage-text div.passage-content div:first-child');

    $block->descendant_nodes->grep( sub { $_->type eq 'comment' } )->each('remove');
    $block
        ->find('.il-text, hidden, hr, .translation-note, span.inline-note, a.full-chap-link')
        ->each('remove');
    $block->find('.std-text')->each('strip');

    $block->find('i, .italic, .trans-change, .idiom, .catch-word')->each( sub { _retag( $_, 'i' ) } );
    $block->find('.woj')->each( sub { _retag( $_, 'woj' ) } );
    $block->find('.divine-name, .small-caps')->each( sub { _retag( $_, 'small_caps' ) } );

    my $footnotes = $block->at('div.footnotes');
    if ($footnotes) {
        $footnotes->remove;
        $footnotes = {
            map {
                '#' . $_->attr('id') => $self->reference->acronyms(1)->clear->in(
                    $_->at('span')->content
                )->as_text
            } $footnotes->find('ol li')->each
        };
    }

    my $crossrefs = $block->at('div.crossrefs');
    if ($crossrefs) {
        $crossrefs->remove;
        $crossrefs = {
            map {
                '#' . $_->attr('id') => $self->reference->acronyms(1)->clear->in(
                    $_->at('a:last-child')->attr('data-bibleref')
                )->refs
            } $crossrefs->find('ol li')->each
        };
    }

    $block->find('sup.crossreference, sup.footnote')->each( sub {
        if ( $_->attr('class') eq 'footnote' ) {
            $_->replace( '<footnote>' . $footnotes->{ $_->attr('data-fn') } . '</footnote>' );
        }
        elsif ( $_->attr('class') eq 'crossreference' ) {
            $_->replace( '<crossref>' . $crossrefs->{ $_->attr('data-cr') } . '</crossref>' );
        }
    } );

    _retag( $block, 'obml' );
    $block->child_nodes->first->prepend( $block->new_tag( 'reference', $reference ) );

    $block->find('h3')->each( sub { _retag( $_, 'header' ) } );
    $block->find('h4')->each( sub { _retag( $_, 'header_alt' ) } );

    $block->find('.chapternum')->each( sub {
        _retag( $_, 'verse_number' );
        $_->content(1);
    } );
    $block->find('.versenum')->each( sub {
        _retag( $_, 'verse_number' );
        my ($verse_number) = $_->content =~ /(\d+)/;
        $_->content($verse_number);
    } );

    $block->find('span.text')->each( sub { _retag( $_, 'text' ) } );

    $block->find('table')->each( sub {
        $_->find('tr')->each( sub {
            $_->find('th')->each('remove');
            unless ( $_->child_nodes->size ) {
                $_->strip;
            }
            else {
                $_->replace( join( '',
                    '<text>',
                    $_->find('td text')->map('content')->join(', '),
                    (
                        ( $_->find('td text')->map('text')->last =~ /\W$/ ) ? ''  :
                        ( $_->following_nodes->size                       ) ? '; ' : '.'
                    ),
                    ( ( $_->following_nodes->size ) ? '</text> ' : '</text>' ),
                ) );
            }
        } );

        $_->tag('div');
        $_->content( '<p>' . $_->content . '</p>' );
    } );

    $block->find( join( ', ', map { '.left-' . $_ } 1 .. 9 ) )->each( sub {
        my ($left) = $_->attr('class') =~ /\bleft\-(\d+)/;
        $_->find('text')->each( sub { $_->attr( indent => $left ) } );
        $_->strip;
    } );

    $block->find('div.poetry')->each( sub { $_->attr( class => 'indent-1' ) } );

    $block->find( join( ', ', map { '.indent-' . $_ } 1 .. 9 ) )->each( sub {
        my ($indent) = $_->attr('class') =~ /\bindent\-(\d+)/;
        $_->find('text')->each( sub {
            $indent += $_->attr('indent') || 0;
            $_->attr( indent => $indent );
        } );
        $_->strip;
    } );

    $block->find( join( ', ', map { '.indent-' . $_ . '-breaks' } 1 .. 5 ) )->each('remove');

    $block->find('text[indent]')->each( sub {
        my $level = $_->attr('indent');
        _retag( $_, 'indent' );
        $_->attr( level => $level );
    } );
    $block->find('text')->each('strip');

    $block->find('indent + indent')->each( sub {
        if ( $_->previous->attr('level') eq $_->attr('level') ) {
            $_->previous->append_content( ' ' . $_->content );
            $_->remove;
        }
    } );

    $block->find('p')->each( sub { _retag( $_, 'p' ) } );
    $block->find('div, span')->each('strip');

    return html_unescape( $block->to_string );
}

sub get ( $self, $reference, $translation = $self->translation ) {
    return Bible::OBML->new->html( $self->parse( $self->fetch( $reference, $translation ) ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::OBML::Gateway - Bible Gateway content conversion to Open Bible Markup Language

=head1 VERSION

version 2.02

=for markdown [![test](https://github.com/gryphonshafer/Bible-OBML-Gateway/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bible-OBML-Gateway/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bible-OBML-Gateway/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bible-OBML-Gateway)

=head1 SYNOPSIS

    use Bible::OBML::Gateway;

    my $bg = Bible::OBML::Gateway->new;
    $bg->translation('NIV');

    my $obml_obj = $bg->get( 'Romans 12' );
    print $bg->get( 'Romans 12', 'NASB' )->obml, "\n";

    my $translations = $bg->translations;
    my $structure    = $bg->structure('NASB');

=head1 DESCRIPTION

This module consumes Bible Gateway content and returns useful data-bearing
objects or data structures. In the common case, it will accept a Bible reference
and return a L<Bible::OBML> object loaded with parsed content.

=head1 METHODS

The following methods are supported.

=head2 new

Instantiates a new gateway object. You can optionally pass a translation
acronym to be used on subsequent requests.

    my $bg = Bible::OBML::Gateway->new( translation => 'NIV' );

=head2 get

This method requires a text input containing a Bible reference that can be
understood as a single chapter or single, unbroken run of verses. For example,
"Romans 12" or "Ro 12:13-17" are acceptable, but "Romans 12:13-17, 19" is not.

You can optionally also provide an overriding translation. If not specified,
the object's translation (set via the C<translation> attribute) will be used.

The method will get the raw HTML content from Bible Gateway, parse it, and
return a L<Bible::OBML> object loaded with the data.

    my $obml_obj = $bg->get( 'Romans 12' );
    print $bg->get( 'Romans 12', 'NASB' )->obml, "\n";

Internally, all this method does is call C<fetch>, pass that output to C<parse>,
and then load output that into a new L<Bible::OBML> object.

=head2 fetch

If all you want to do is fetch the HTML from Bible Gateway, you can use this
method. It uses the same signature as C<get> and returns the returned raw HTML.

=head2 parse

This method requires source HTML like what you might get from a C<fetch> call,
which it will then parse and return a special sort of HTML that can be loaded
directly into a L<Bible::OBML> object via it's C<html> method. (See
L<Bible::OBML> for more information.)

=head2 translations

This method will return a data structure consisting of data describing available
translations on Bible Gateway per spoken language. It returns an arrayref
containing a hashref per language. Each hashref contains an arrayref of
translations, each represented by a hashref.

    my $translations = $bg->translations;

This a simplified example of the data structure:

    [
        {
            acronym      => 'EN',
            language     => 'English',
            translations => [
                {
                    acronym     => 'NIV',
                    translation => 'New International Version',
                },
            ],
        },
    ]

=head2 structure

This method will return a data structure consisting of data describing the
structure of a given translation of the Bible from Bible Gateway. It can
optionally be provided an overriding translation. If not specified, the object's
translation (set via the C<translation> attribute) will be used. The data
structure returned is an arrayref of hashrefs, each representing a book.

    my $structure = $bg->structure('NASB');

This a simplified example of the data structure:

    [
        {
            testament    =>  'NT',
            display      =>  '2 John',
            osis         =>  '2John',
            intro        =>  0,
            num_chapters =>  1,
            chapters     =>  [
                {
                    chapter => 1,
                    type    => 'heading',
                    content => [
                        "Walk According to His Commandments",
                    ],
                },
            ],
        }
    ]

=head1 ATTRIBUTES

Attributes can be set in a call to C<new> or explicitly as a get/set method.

    my $bg = Bible::OBML::Gateway->new( translation => 'NIV' );
    $bg->translation('NIV');
    say $bg->translation;

=head2 translation

Get or set the current translation acronym. The default if not explicitly set
will be "NIV".

    say $bg->translation;
    $bg->translation('NIV');

=head2 url

This provides access to the base URL, contained within a L<Mojo::URL> object.

    $bg->url( Mojo::URL->new('https://www.biblegateway.com/passage/') );

=head2 ua

This provides access to the L<Mojo::UserAgent> user agent.

    $bg->ua->transactor->name("Your Application's Name");

=head2 reference

This provides access to the L<Bible::Reference> object used to parse and
canonicalize Bible references.

    $bg->reference->bible('Catholic');

Depending on which translation you C<get> from Bible Gateway, you may need to
alter the C<bible> setting of C<reference>, as in the example immediately above.
By default, C<bible> is set to "Protestant".

=head1 SEE ALSO

L<Bible::OBML>, L<Bible::Reference>, L<Mojo::URL>, L<Mojo::UserAgent>.

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

This software is Copyright (c) 2017-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
