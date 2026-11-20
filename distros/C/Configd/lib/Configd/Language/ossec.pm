package Configd::Language::ossec;
$Configd::Language::ossec::VERSION = '0.007';
#ABSTRACT: ossec.conf, which is one XML file that every daemon of OSSEC reads, with no directory beside it.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use XML::LibXML ();

use parent qw{Configd::Language};


sub files {
    return ( { path => '/var/ossec/etc/ossec.conf', mode => 0o660, owner => 'root:ossec' } );
}

sub units {
    return ('ossec.service');
}

sub reloads {
    return 0;
}

# The sections that appear once, each with the children that are lists.  Every
# other section is a list of blocks.
my %SINGLE = (
    global    => { map { $_ => 1 } qw{white_list email_to} },
    rules     => { map { $_ => 1 } qw{include list decoder} },
    syscheck  => { map { $_ => 1 } qw{directories ignore nodiff registry_ignore windows_registry} },
    rootcheck => { map { $_ => 1 } qw{system_audit windows_audit windows_apps windows_malware} },
    alerts    => {},
    client    => {},
);


sub accumulates {
    my ( $self, $key ) = @_;

    my ( $section, $child ) = sections($key);
    return $SINGLE{$section}         ? 0 : 1 unless defined $child;
    return $SINGLE{$section}{$child} ? 1 : 0;
}


sub separator {
    return "\n";
}


sub items {
    my ( $self, $key, $value ) = @_;
    return () unless defined $value;
    return map { $_->{text} } elements($value);
}


sub parse {
    my ( $self, $text ) = @_;

    my @directives;
    foreach my $root ( elements($text) ) {
        die "<$root->{name}> is not <ossec_config>, which is the root of ossec.conf.\n" unless $root->{name} eq 'ossec_config';
        foreach my $section ( children( $root->{node} ) ) {
            if ( !$SINGLE{ $section->{name} } ) {
                push @directives, { key => $section->{name}, value => $section->{empty} ? q{} : $section->{text} };
                next;
            }
            foreach my $child ( children( $section->{node} ) ) {
                push @directives, { key => "$section->{name}/$child->{name}", value => $child->{empty} ? q{} : $child->{text} };
            }
        }
    }
    return \@directives;
}


sub emit {
    my ( $self, $directives ) = @_;

    my ( @order, %items );
    foreach my $directive (@$directives) {
        my ($section) = sections( $directive->{key} );
        push @order,                $section unless $items{$section};
        push @{ $items{$section} }, $self->accumulates( $directive->{key} ) ? $self->items( $directive->{key}, $directive->{value} ) : grep { length } $directive->{value};
    }

    my $doc  = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $root = $doc->createElement('ossec_config');
    $doc->setDocumentElement($root);
    foreach my $section (@order) {
        my @items = @{ $items{$section} };
        next unless @items;
        my $parent = $root;
        if ( $SINGLE{$section} ) {
            $parent = $doc->createElement($section);
            $root->appendChild($parent);
        }
        foreach my $item (@items) {
            $parent->appendChild( $doc->importNode($_) ) for map { $_->{node} } elements($item);
        }
    }
    return $root->toString(1) . "\n";
}


sub header {
    my ( $self, $file ) = @_;

    # An XML comment cannot hold two hyphens in a row.
    my $text = $self->SUPER::header($file) =~ s/^#[ ]?//gmr =~ s/-{2,}/-/gr;
    return "<!--\n$text-->\n";
}


sub sections {
    my ($key) = @_;

    my $slash = index( $key, q{/} );
    return ($key) if $slash < 0;
    return ( substr( $key, 0, $slash ), substr( $key, $slash + 1 ) );
}


# No network, no entities and no DTD: a fragment is configuration, not a
# document that may fetch others.
my $PARSER = XML::LibXML->new( no_network => 1, expand_entities => 0, load_ext_dtd => 0 );

# The code of libxml2 for two hyphens inside a comment, and how many of them one
# file may have.
my $HYPHENS_IN_COMMENT = 80;
my $MOST_HYPHENS       = 1000;

sub elements {
    my ($xml) = @_;
    return () unless defined $xml && $xml =~ m/\S/;
    return children( document($xml)->documentElement );
}


sub document {
    my ($xml) = @_;

    # One line before the text, so that a line of libxml2 is one past a line of
    # the text, and a column is a column.
    my @lines = split( "\n", $xml =~ s/\A\s*<\?xml[^>]*\?>//r, -1 );
    foreach ( 0 .. $MOST_HYPHENS ) {
        my $doc = eval { $PARSER->load_xml( string => join( "\n", '<configd>', @lines, '</configd>' ) ) };
        return $doc if $doc;

        my @errors;
        for ( my $error = $@; ref $error; $error = $error->_prev ) { unshift @errors, $error }
        die 'Cannot read the XML: ' . ( ref $@ ? $@->message : $@ ) =~ s/\s+\z//r . "\n" if !@errors || grep { $_->code != $HYPHENS_IN_COMMENT } @errors;

        my ($first) = @errors;
        my $hyphens = hyphens( \@lines, $first->line - 2, $first->column );
        die 'Cannot read the XML: ' . $first->message =~ s/\s+\z//r . "\n" unless defined $hyphens;
        substr( $lines[ $first->line - 2 ], $hyphens, 2, '- -' );
    }
    die "Cannot read the XML: more than $MOST_HYPHENS comments with two hyphens in them\n";
}


sub hyphens {
    my ( $lines, $line, $column ) = @_;
    return if $line < 0 || $line > $#$lines;

    my $text = $lines->[$line];
    my $at   = index( $text, '--', ( $column // 1 ) > 2 ? $column - 2 : 0 );
    while ( $at >= 0 ) {
        my $opens  = $at >= 2 && substr( $text, $at - 2, 2 ) eq '<!';
        my $closes = substr( $text, $at + 2, 1 ) eq '>';
        return $at unless $opens || $closes;
        $at = index( $text, '--', $at + 1 );
    }
    return;
}


sub children {
    my ($node) = @_;

    my @elements;
    foreach my $child ( $node->childNodes ) {
        my $type = $child->nodeType;
        if ( $type == XML::LibXML::XML_TEXT_NODE() || $type == XML::LibXML::XML_CDATA_SECTION_NODE() ) {
            die "Text outside of an element: '" . substr( $child->data =~ s/\A\s+//r, 0, 40 ) . "'\n" if $child->data =~ m/\S/;
            next;
        }
        next unless $type == XML::LibXML::XML_ELEMENT_NODE();

        my $element = tidy( $child->cloneNode(1) );
        push @elements, {
            name  => $element->nodeName,
            node  => $element,
            text  => $element->toString(0),
            empty => !$element->hasChildNodes && !$element->hasAttributes,
        };
    }
    return @elements;
}


sub tidy {
    my ($node) = @_;

    foreach my $child ( $node->childNodes ) {
        my $type = $child->nodeType;
        if ( $type == XML::LibXML::XML_COMMENT_NODE() || $type == XML::LibXML::XML_PI_NODE() || ( $type == XML::LibXML::XML_TEXT_NODE() && $child->data !~ m/\S/ ) ) {
            $node->removeChild($child);
            next;
        }
        tidy($child) if $type == XML::LibXML::XML_ELEMENT_NODE();
    }
    return $node;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Language::ossec - ossec.conf, which is one XML file that every daemon of OSSEC reads, with no directory beside it.

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Configd();

    Configd->adopt('ossec');
    Configd->build('ossec');

=head1 DESCRIPTION

Every daemon of OSSEC reads F</var/ossec/etc/ossec.conf>, and nothing else.  Its
one include is for rule files, inside C<< <rules> >>.  So the file becomes
generated, and a fragment is a file of its own.

A fragment is XML in the form of F<ossec.conf> itself:

    <ossec_config>
      <global>
        <email_notification>no</email_notification>
      </global>
      <localfile/>
      <remote>
        <connection>syslog</connection>
        <port>10514</port>
      </remote>
    </ossec_config>

=head2 How the file is merged

The file is a root element C<< <ossec_config> >> holding sections, and the
sections are of two kinds.

A section that appears once, such as C<< <global> >>, is a set of settings.
Each child element is a directive, keyed by the section and its own name, as
C<global/email_notification>, and the later fragment wins.  Some children are
lists, such as each C<< <include> >> of C<< <rules> >> and each
C<< <white_list> >> of C<< <global> >>: each fragment adds to them, in the
order that they were first seen, so the rule files of the package keep their
order and the includes of a fragment come after them.

A section that can appear many times, such as C<< <localfile> >> or
C<< <remote> >>, is a list of whole blocks, and each fragment adds blocks to it.
So is a section that this language does not know, so that nothing in it is lost.

Two blocks or children that say the same thing are one, so a fragment can repeat
what is already there.  An empty element clears its list, as an empty value
does in every language: an empty C<< <localfile/> >> drops every
C<< <localfile> >> of the fragments before it, and anything after it adds to
nothing.  The package's example configuration is the case: it watches log
files that a distribution does not have, and whitelists addresses of the
network of its author.

Comments are left out of the generated file, as in every language.

=head2 What it reads, and with what

L<XML::LibXML>, the one module here that is not in core perl.  The rest of
configd runs on core perl alone, because it stands between a service and its
start.  This language needs a real parser, and only a guest that installs
OSSEC has F<ossec.conf> to adopt, so the same install brings the parser:
F<libxml-libxml-perl> on Debian and Ubuntu, F<perl-XML-LibXML> on the
distributions of Red Hat.  F<metamerge.yml> declares it.

The file is read inside an element of its own, because the package writes more
than one C<< <ossec_config> >> in it, and a document has one root.  The parser
fetches nothing from the network and expands no entity.  The package also
writes two hyphens inside a comment, which XML forbids and OSSEC reads, and
C<document> below says what is done about that.

=head1 NAME

Configd::Language::ossec - ossec.conf, which is one XML file that every daemon
of OSSEC reads, with no directory beside it.

=head1 METHODS

=head2 files()

F</var/ossec/etc/ossec.conf>, 0660 root:ossec as the package ships it, if it has
to be created.

=head2 units()

C<ossec.service>.  The package ships an init script, and systemd generates the
unit from it.  A drop-in applies to a generated unit as to any other.

=head2 reloads()

False.  C<ossec-control> has no reload, so a change wants a restart.

=head2 accumulates($key)

True for a section that can appear many times, and for a child that is a list,
as L</How the file is merged> says.

=head2 separator($key)

A line break, between the elements of a list.

=head2 @items = $language->items($key, $value)

The elements in C<$value>, each as one line of XML.

=head2 parse($text)

The directives of a fragment, as L</How the file is merged> says.  Dies on text
that it cannot read, or on a root element other than C<< <ossec_config> >>.

=head2 emit($directives)

One C<< <ossec_config> >> holding every section, in the order that each was
first seen, with the children of a section that appears once together in it,
written by L<XML::LibXML> with one element to a line.

=head2 header($file)

The header of every language, as an XML comment.

=head1 FUNCTIONS

=head2 ($section, $child) = sections($key)

The section of a directive's key, and the child, or undef for a key that names a
whole section.

=head2 @elements = elements($xml)

The elements at the top level of C<$xml>, in order, each a hashref of C<name>,
C<node>, the element with its comments and the space between its tags taken
out, C<text>, that element as one line of XML, and C<empty>, true for an
element with no content and no attributes.  Dies on XML that does not parse,
and on text outside an element.

=head2 $doc = document($xml)

C<$xml> parsed inside an element of its own, because the package writes more
than one C<< <ossec_config> >> in the file, and a document has one root.  A
declaration at the start, C<< <?xml ...?> >>, is left out, because XML allows
it only at the start of a document.

XML forbids two hyphens inside a comment, and the package writes them, as in
C<< <!-- Frequency that syscheck is executed -- default every 20 hours --> >>.
OSSEC reads a comment up to the next C<< --> >>.  So where libxml2 reports
those two hyphens and nothing else, this puts a space between them at the line
and column that libxml2 gives, and parses again.  The comment is dropped from
the merge either way, and C<00-original> keeps the file as it was.  Dies on any
other error.

=head2 $offset = hyphens(\@lines, $line, $column)

Where in line C<$line> of C<@lines>, counted from 0, the two hyphens are that
libxml2 reports at C<$column>, counted from 1: the first two at or after that
column that neither start C<< <!-- >> nor end with C<< --> >>.  Undef when there
are none, so that the error goes to the caller as it was.

=head2 @elements = children($node)

The child elements of C<$node>, as C<elements> gives them.  Dies on text
beside them that is not space.

=head2 $node = tidy($node)

C<$node> with its comments, processing instructions and text that is only
space taken out, at every depth.  The space between tags is for people, and two
blocks that differ in it are the same block.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
