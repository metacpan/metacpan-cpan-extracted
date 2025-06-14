package Bible::OBML;
# ABSTRACT: Open Bible Markup Language parser and renderer

use 5.022;

use exact;
use exact::class;
use Mojo::DOM;
use Mojo::Util 'html_unescape';
use Text::Wrap 'wrap';
use Bible::Reference;

$Text::Wrap::unexpand = 0;

our $VERSION = '2.10'; # VERSION

has _load             => sub { {} };
has indent_width      => 4;
has reference_acronym => 0;
has fnxref_acronym    => 1;
has wrap_at           => 80;
has reference         => sub {
    Bible::Reference->new(
        bible                 => 'Protestant',
        sorting               => 1,
        require_chapter_match => 1,
        require_book_ucfirst  => 1,
    );
};

sub __ocd_tree ($node) {
    my $new_node;

    if ( 'tag' eq shift @$node ) {
        $new_node->{tag} = shift @$node;

        my $attr = shift @$node;
        $new_node->{attr} = $attr if (%$attr);

        shift @$node;

        my $children = [ grep { defined } map { __ocd_tree($_) } @$node ];
        $new_node->{children} = $children if (@$children);
    }
    else {
        $new_node->{text} = $node->[0] if ( $node->[0] ne "\n\n" );
    }

    return $new_node;
}

sub __html_tree ($node) {
    if ( $node->{tag} ) {
        if ( $node->{children} ) {
            my $attr = ( $node->{attr} )
                ? ' ' . join( ' ', map { $_ . '="' . $node->{attr}{$_} . '"' } keys %{ $node->{attr} } )
                : '';

            return join( '',
                '<', $node->{tag}, $attr, '>',
                (
                    ( $node->{children} )
                        ? ( map { __html_tree($_) } @{ $node->{children} } )
                        : ()
                ),
                '</', $node->{tag}, '>',
            );
        }
        else {
            return '<' . $node->{tag} . '>';
        }
    }
    else {
        return $node->{text};
    }
}

sub __cleanup_html ($html) {
    # spacing cleanup
    $html =~ s/\s+/ /g;
    $html =~ s/(?:^\s+|\s+$)//mg;
    $html =~ s/^[ ]+//mg;

    # protect against inadvertent OBML
    $html =~ s/~/-/g;
    $html =~ s/`/'/g;
    $html =~ s/\|//g;
    $html =~ s/\\/ /g;
    $html =~ s/\*//g;
    $html =~ s/\{/(/g;
    $html =~ s/\}/)/g;
    $html =~ s/\[/(/g;
    $html =~ s/\]/)/g;

    $html =~ s|<p>|\n\n<p>|g;
    $html =~ s|<sub_header>|\n\n<sub_header>|g;
    $html =~ s|<header>|\n\n<header>|g;
    $html =~ s|<br>\s*|<br>\n|g;
    $html =~ s|[ ]+</p>|</p>|g;
    $html =~ s|[ ]+</obml>|</obml>|;

    # trim spaces at line ends
    $html =~ s/[ ]+$//mg;

    return $html;
}

sub __clean_html_to_data ($clean_html) {
    return __ocd_tree( Mojo::DOM->new($clean_html)->at('obml')->tree );
}

sub __data_to_clean_html ($data) {
    return __cleanup_html( __html_tree($data) );
}

sub _clean_html_to_obml ( $self, $html ) {
    my $dom = Mojo::DOM->new($html);

    # append a trailing <br> inside any <p> with a <br> for later wrapping reasons
    $dom->find('p')->grep( sub { $_->find('br')->size } )->each( sub { $_->append_content('<br>') } );

    my $obml = html_unescape( $dom->to_string );

    # de-XML
    $obml =~ s|</?obml>||g;
    $obml =~ s|</p>| </p>|g;
    $obml =~ s|</?p>||g;
    $obml =~ s|</?woj>|\*|g;
    $obml =~ s|</?i>|\^|g;
    $obml =~ s|</?small_caps>|\\|g;
    $obml =~ s|<reference>\s*|~ |g;
    $obml =~ s|\s*</reference>| ~|g;
    $obml =~ s!<verse_number>\s*!|!g;
    $obml =~ s!\s*</verse_number>!| !g;
    $obml =~ s|<sub_header>\s*|== |g;
    $obml =~ s|\s*</sub_header>| ==|g;
    $obml =~ s|<header>\s*|= |g;
    $obml =~ s|\s*</header>| =|g;
    $obml =~ s|<crossref>\s*|\{|g;
    $obml =~ s|\s*</crossref>|\}|g;
    $obml =~ s|<footnote>\s*|\[|g;
    $obml =~ s|\s*</footnote>|\]|g;
    $obml =~ s|^<indent level="(\d+)">| ' ' x ( $self->indent_width * $1 ) |mge;
    $obml =~ s|<indent level="\d+">||g;
    $obml =~ s|</indent>||g;

    if ( $self->wrap_at ) {
        # wrap lines that don't end in <br>
        $obml = join( "\n", map {
            unless ( s|<br>|| ) {
                s/^(\s+)//;
                my $header = $1 || '';
                $Text::Wrap::columns = $self->wrap_at - length($header);
                wrap( $header, $header, $_ );
            }
            else {
                $_;
            }
        } split( /\n/, $obml ) ) . "\n";
    }
    $obml =~ s|<br>||g;
    $obml =~ s|[ ]+$||mg;
    $obml =~ s/\n{3,}/\n\n/g;
    $obml =~ s/^[ ]([^ ])/$1/mg;

    chomp $obml;
    return $obml;
}

sub _obml_to_clean_html ( $self, $obml ) {
    # spacing cleanup
    $obml =~ s/\r?\n/\n/g;
    $obml =~ s/\t/    /g;
    $obml =~ s/\n[ \t]+\n/\n\n/mg;
    $obml =~ s/^\n+//g;
    $obml =~ /^(\s+)/;
    $obml =~ s/^$1//mg if ($1);
    $obml =~ s/\s+$//g;

    # remove comments
    $obml =~ s/^\s*#.*?(?>\r?\n)//msg;

    # "unwrap" wrapped lines
    my @obml;
    for my $line ( split( /\n/, $obml ) ) {
        if ( not @obml or not length $line or not length $obml[-1] ) {
            push( @obml, $line );
        }
        else {
            my ($last_line_indent) = $obml[-1] =~ /^([ ]*)/;
            my ($this_line_indent) = $line     =~ /^([ ]*)/;

            if ( length $last_line_indent == 0 and length $this_line_indent == 0 ) {
                $line =~ s/^[ ]+//;
                $obml[-1] .= ' ' . $line;
            }
            else {
                push( @obml, $line );
            }
        }
    }
    $obml = join( "\n", @obml );

    $obml =~ s|~+[ ]*([^~]+?)[ ]*~+|<reference>$1</reference>|g;
    $obml =~ s|={2,}[ ]*([^=]+?)[ ]*={2,}|<sub_header>$1</sub_header>|g;
    $obml =~ s|=[ ]*([^=]+?)[ ]*=|<header>$1</header>|g;

    $obml =~ s|^([ ]+)(\S.*)$|
        '<indent level="'
        . int( ( length($1) + $self->indent_width * 0.5 ) / $self->indent_width )
        . '">'
        . $2
        . '</indent>'
    |mge;

    $obml =~ s|(\S)(?=\n\S)|$1<br>|g;

    $obml =~ s`(?:^|(?<=\n\n))(?!<(?:reference|sub_header|header)\b)`<p>`g;
    $obml =~ s`(?:$|(?=\n\n))`</p>`g;
    $obml =~ s`(?<=</reference>)</p>``g;
    $obml =~ s`(?<=</sub_header>)</p>``g;
    $obml =~ s`(?<=</header>)</p>``g;

    $obml =~ s!\|(\d+)\|\s*!<verse_number>$1</verse_number>!g;

    $obml =~ s|\*([^\*]+)\*|<woj>$1</woj>|g;
    $obml =~ s|\^([^\^]+)\^|<i>$1</i>|g;
    $obml =~ s|\\([^\\]+)\\|<small_caps>$1</small_caps>|g;

    $obml =~ s|\{|<crossref>|g;
    $obml =~ s|\}|</crossref>|g;

    $obml =~ s|\[|<footnote>|g;
    $obml =~ s|\]|</footnote>|g;

    return "<obml>$obml</obml>";
}

sub _accessor ( $self, $input = undef ) {
    my $want = ( split( '::', ( caller(1) )[3] ) )[-1];

    if ($input) {
        if ( ref $input ) {
            my $data_refs_ocd;
            $data_refs_ocd = sub ($node) {
                if (
                    $node->{tag} and $node->{children} and
                    ( $node->{tag} eq 'crossref' or $node->{tag} eq 'footnote' )
                ) {
                    for ( grep { $_->{text} } @{ $node->{children} } ) {
                        $_->{text} = $self->reference->acronyms(
                            $self->fnxref_acronym
                        )->clear->in( $_->{text} )->as_text;
                    }
                }
                if ( $node->{children} ) {
                    $data_refs_ocd->($_) for ( @{ $node->{children} } );
                }
                return;
            };
            $data_refs_ocd->($input);

            my $reference = ( grep { $_->{tag} eq 'reference' } @{ $input->{children} } )[0]{children}[0];
            my $runs      = $self->reference->acronyms(
                $self->reference_acronym
            )->clear->in( $reference->{text} )->as_runs;

            $reference->{text} = $runs->[0];
        }
        else {
            my $ref_ocd = sub ( $text, $acronyms ) {
                return $self->reference->acronyms($acronyms)->clear->in($text)->as_text;
            };

            $input =~ s!
                ((?:<(?:footnote|crossref)>|\{|\[)\s*.+?\s*(?:</(?:footnote|crossref)>|\}|\]))
            !
                $ref_ocd->( $1, $self->fnxref_acronym )
            !gex;

            $input =~ s!
                ((?:<reference>|~)\s*.+?\s*(?:</reference>|~))
            !
                $ref_ocd->( $1, $self->reference_acronym )
            !gex;
        }

        return $self->_load({ $want => $input });
    }

    return $self->_load->{data} if ( $want eq 'data' and $self->_load->{data} );

    unless ( $self->_load->{canonical}{$want} ) {
        if ( $self->_load->{html} ) {
            $self->_load->{clean_html} //= __cleanup_html( $self->_load->{html} );

            if ( $want eq 'obml' ) {
                $self->_load->{canonical}{obml} = $self->_clean_html_to_obml( $self->_load->{clean_html} );
            }
            elsif ( $want eq 'data' or $want eq 'html' ) {
                $self->_load->{data} = __clean_html_to_data( $self->_load->{clean_html} );

                $self->_load->{canonical}{html} = __data_to_clean_html( $self->_load->{data} )
                    if ( $want eq 'html' );
            }
        }
        elsif ( $self->_load->{data} ) {
            $self->_load->{canonical}{html} = __data_to_clean_html( $self->_load->{data} );

            $self->_load->{canonical}{obml} = $self->_clean_html_to_obml( $self->_load->{canonical}{html} )
                if ( $want eq 'obml' );
        }
        elsif ( $self->_load->{obml} ) {
            $self->_load->{canonical}{html} = $self->_obml_to_clean_html( $self->_load->{obml} );

            if ( $want eq 'obml' ) {
                $self->_load->{canonical}{obml} = $self->_clean_html_to_obml(
                    $self->_load->{canonical}{html}
                );
            }
            elsif ( $want eq 'data' ) {
                $self->_load->{data} = __clean_html_to_data( $self->_load->{canonical}{html} );
            }
        }
    }

    return ( $want eq 'data' ) ? $self->_load->{$want} : $self->_load->{canonical}{$want};
}

sub data { shift->_accessor(@_) }
sub html { shift->_accessor(@_) }
sub obml { shift->_accessor(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::OBML - Open Bible Markup Language parser and renderer

=head1 VERSION

version 2.10

=for markdown [![test](https://github.com/gryphonshafer/Bible-OBML/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bible-OBML/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bible-OBML/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bible-OBML)

=for test_synopsis my(
    $obml_text_content, $data_structure, $skip_wrapping, $skip_smartify,
    $content, $smart_content, $input_file, $output_file, $filename,
);

=head1 SYNOPSIS

    use Bible::OBML;
    my $bo = Bible::OBML->new;

    use Bible::OBML::Gateway;
    my $gw   = Bible::OBML::Gateway->new;
    my $html = $gw->parse( $gw->fetch( 'Romans 12', 'NIV' ) );

    my $obml  = $bo->html($html)->obml;
    my $data  = $bo->obml($obml)->data;
    my $obml2 = $bo->data($data)->obml;

=head1 DESCRIPTION

This module provides methods that support parsing and rendering Open Bible
Markup Language (OBML). OBML is a text markup way to represent Bible content,
one whole text file per chapter. The goal or purpose of OBML is similar to
Markdown in that it provides a human-readable text file allowing for simple and
direct editing of content while maintaining context, footnotes,
cross-references, "red text", and other basic formatting.

=head2 Open Bible Markup Language (OBML)

OBML makes the assumption that content will exist in one text file per chapter
and content mark-up will conform to the following specification (where "..."
represents textual content):

    ~ ... ~   --> material reference
    = ... =   --> header
    == ... == --> sub-header
    |...|     --> verse number
    {...}     --> cross-references
    [...]     --> footnotes
    *...*     --> red text
    ^...^     --> italic
    \...\     --> small-caps
    spaces    --> indenting
    # ...     --> line comments
                  (if "#" is the first non-whitespace character on the line)

HTML-like markup can be used throughout the content for additional markup not
defined by the above specification. When OBML is parsed, such markup is ignored
and passed through, treated like any other content of the verse.

An example of OBML follows, with several verses missing so as to save space:

    ~ Mark 1 ~

    = John the Baptist Prepares the Way{Mt 3:1, 11; Lk 3:2, 16} =

    |1| The beginning of the good news about Jesus the Messiah,[Or ^Jesus Christ.^
    ^Messiah^ (He) and ^Christ^ (Greek) both mean ^Anointed One.^] the Son of
    God,[Some manuscripts do not have ^the SS of God.^]{Mt 4:3} |2| as it is
    written in Isaiah the prophet:

        “I will send my messenger ahead of you,
            who will prepare your way”[Ml 3:1]{Ml 3:1; Mt 11:10; Lk 7:27}—
        |3| “a voice of one calling in the wilderness,
        ‘Prepare the way for the \Lord\,
            make straight paths for him.’”[Is 40:3]{Is 40:3; Joh 1:23}

    |4| And so John the Baptist{Mt 3:1} appeared in the wilderness, preaching a
    baptism of repentance{Mk 1:8; Joh 1:26, 33; Ac 1:5, 22; 11:16; 13:24; 18:25;
    19:3-4} for the forgiveness of sins.{Lk 1:77}

    # cut verses 5-13 to save space

    = Jesus Announces the Good News{Mt 4:18, 22; Lk 5:2, 11; Joh 1:35, 42} =

    |14| After John{Mt 3:1} was put in prison, Jesus went into Galilee,{Mt 4:12}
    proclaiming the good news of God.{Mt 4:23} *|15| “The time has come,”{Ro 5:6;
    Ga 4:4; Ep 1:10}* he said. *“The kingdom of God has come near. Repent and
    believe{Joh 3:15} the good news!”{Ac 20:21}*

Typically, one might load OBML and render it into HTML-like output or a data
structure.

    my $html = Bible::OBML->new->obml($obml)->html;
    my $data = Bible::OBML->new->obml($obml)->data;

=head1 METHODS

=head2 obml

This method accepts OBML as input or if no input is provided outputs OBML
converted from previous input.

    my $object = Bible::OBML->new->obml($obml);
    say $object->obml;

=head2 html

This method accepts a specific form of HTML-like input or if no input is
provided outputs this HTML-like content converted from previous input.

    my $object = Bible::OBML->new->html($html);
    say $object->html;

HTML-like content might look something like this:

    <obml>
        <reference>Mark 1</reference>
        <header>
            John the Baptist Prepares the Way
            <crossref>Mt 3:1, 11; Lk 3:2, 16</crossref>
        </header>
        <p>
            <verse_number>1</verse_number>
            The beginning of the good news about Jesus the Messiah,
            <footnote>
                Or <i>Jesus Christ.</i> <i>Messiah</i> (He) and <i>Christ</i>
                (Greek) both mean <i>Anointed One.</i>
            </footnote> the Son of God...
        </p>
    </obml>

=head2 data

This method accepts OBML as input or if no input is provided outputs OBML
converted from previous input.

    my $object = Bible::OBML->new->data($data);
    use DDP;
    p $object->data;

This data might look something like this:

    {
        tag      => 'obml',
        children => [
            {
                tag      => 'reference',
                children => [ { text => 'John 1' } ],
            },
            {
                tag      => 'p',
                children => [
                    {
                        tag      => 'verse_number',
                        children => [ { text => '1' } ],
                    },
                    { text => 'In the beginning' },
                    {
                        tag      => 'crossref',
                        children => [ { text => 'Ge 1:1' } ],
                    },
                    { text => ' was...' },
                ],
            },
        ],
    };

=head1 ATTRIBUTES

Attributes can be set in a call to C<new> or explicitly as a get/set method.

    my $bo = Bible::OBML->new( indent_width => 4, reference_acronym => 0 );
    $bo->indent_width(4);
    say $bo->reference_acronym;

=head2 indent_width

This attribute is an integer representing the number of spaces that will be
considered a single level of indentation. It's set to a default of 4 spaces.

=head2 reference_acronym

By default, references in "reference" sections will be canonicalized to non-
acronym form; however, you can change that by setting the value of this accessor
to a true value.

=head2 fnxref_acronym

By default, references in all non-"reference" sections (i.e. cross-references
and some footnotes) will be canonicalized to acronym form; however, you can
change that by setting the value of this accessor to a false value.

=head2 wrap_at

By default, lines of OBML that are not indented will be wrapped at 80
characters. You can adjust this point with this attribute. If set to a false
value, no wrapping will take place.

=head1 SEE ALSO

L<Bible::OBML::Gateway>, L<Bible::Reference>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bible-OBML>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bible::OBML>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bible-OBML/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bible-OBML>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-OBML>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-OBML.html>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
