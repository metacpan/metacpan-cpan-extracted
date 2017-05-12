# $Id: SpellCheck.pm,v 1.5 2005/01/27 00:45:38 nachbaur Exp $

package Apache::AxKit::Language::SpellCheck;

use base Apache::AxKit::Language;
use strict;

use AxKit;
use Apache;
use Apache::Request;
use Apache::AxKit::Language;
use Apache::AxKit::Provider;
use Text::Aspell;
use Cwd;

our $VERSION = 0.03;
our $NS = 'http://axkit.org/2004/07/17-spell-check#';

sub stylesheet_exists () { 0; }

sub handler {
    my $class = shift;
    my ($r, $xml_provider, undef, $last_in_chain) = @_;
    
    #
    # Create and init the speller object
    my $spell = new Text::Aspell;
    $spell->set_option('sug-mode', 'fast');
    $spell->set_option('lang', $r->dir_config("AxSpellLanguage") || 'en_US');
    my $max_suggestion = $r->dir_config("AxSpellSuggestions") || 3;

    #
    # Process the list of elements we need to skip
    my %skip_elements = ();
    foreach my $element (split(/\s+/, $r->dir_config("AxSpellSkipElements") )) {
        if ($element !~ /^(?:\{(.*?)\})?([\w\d\-\_]+)$/) {
            die "The element \"$element\" is invalid in AxSpellSkipElements";
        }
        my $ns   = $1;
        my $node = $2;
        $skip_elements{$ns}->{$node} = 1;
    }

    #
    # Load the DOM object
    my $dom = $r->pnotes('dom_tree');
    unless ($dom) {
        my $xmlstring = $r->pnotes('xml_string');
        my $parser = XML::LibXML->new();
        $parser->expand_entities(1);
        $dom = $parser->parse_string($xmlstring, $r->uri());
    }

    #
    # Find the root node
    my $root = $dom->documentElement();
    $root->setNamespace($NS, 'sp', 0);

    #
    # Iterate through all the text nodes
    foreach my $text_node ($root->findnodes('//text()')) {

        #
        # Skip if our parent is in the exclude list
        my $parent = $text_node->parentNode;
        if ($skip_elements{$parent->namespaceURI}->{$parent->localname}) {
            #warn "Skipping " . $text_node->data . " due to parent " . $parent->nodeName . "\n";
            next;
        }

        my @nodes = ();
        my $pre_text = undef;
        my $changed = 0;

        #
        # Loop through the words in this text ndoe
        foreach my $word (split(/\b/, $text_node->data)) {

            #
            # Skip empty strings and non-spellable words
            next unless defined $word;
            unless ($word =~ /^\p{L}+$/i) {
                $pre_text .= $word;
                next;
            }

            #
            # Check the word against the spellchecker
            if ($spell->check($word)) {
                $pre_text .= $word;
            }
            
            #
            # The word isn't spelled right, add elements
            else {
                $changed++;

                #
                # Add an initial text node if the unspelled word is somewhere in the middle
                push @nodes, XML::LibXML::Text->new($pre_text) if (length($pre_text));
                $pre_text = undef;

                #
                # Add the root element for this spelling block
                my $element = $dom->createElementNS($NS, "incorrect");

                #
                # Iterate and add our suggestions
                my $counter = 0;
                if ($max_suggestion) {
                    foreach my $suggestion ($spell->suggest($word)) {
                        #
                        # Add the suggestion element
                        my $suggest_node = $dom->createElementNS($NS, "suggestion");
                        $suggest_node->appendText($suggestion);
                        $element->appendChild($suggest_node);
                        last if (++$counter > $max_suggestion);
                    }
                }

                #
                # Add the element for the current, misspelled word
                my $word_node = $dom->createElementNS($NS, "word");
                $word_node->appendText($word);
                $element->appendChild($word_node);
                push @nodes, $element;
            }
        }

        #
        # Wrap up any text thats left over as a text node
        push @nodes, XML::LibXML::Text->new($pre_text) if (length($pre_text));

        #
        # If nothing's changed, don't bother changing the DOM
        next unless ($changed);

        my $parent = $text_node->parentNode;

        #
        # If we have multiple nodes to add, add them
        if ($#nodes > 0) {
            #
            # Replace the current text with the first node we have
            my $first_node = shift(@nodes);
            $parent->replaceChild($first_node, $text_node);

            #
            # Iterate through the additional nodes, and append them to
            # the previously-added node
            my $previous_node = $first_node;
            foreach my $node (@nodes) {
                $parent->insertAfter($node, $previous_node);
                $previous_node = $node;
            }
        }
        
        #
        # Since there's only one element to replace, just swap it out; its simpler
        else {
            $parent->replaceChild($nodes[0], $text_node);
        }
    }

    #
    # Return the current dom document
    delete $r->pnotes()->{'xml_string'};
    $r->pnotes('dom_tree', $dom);
    
    return Apache::Constants::OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Language::SpellCheck - XML Text Spell Checker 

=head1 SYNOPSIS

    AxAddStyleMap text/x-spell-check Apache::AxKit::Language::SpellCheck

    Alias /spell/ /path/to/docroot
    <Location /spell/>
        SetHandler axkit
        AxResetProcessors
        AxAddProcessor text/x-spell-check NULL
    </Location>

    SetHandler axkit
    AxAddProcessor text/xsl           /stylesheets/scrub-xml.xsl
    AxAddProcessor text/x-spell-check NULL
    AxAddProcessor text/xsl           /stylesheets/display-html.xsl

=head1 DESCRIPTION

This language module processes an incoming XML document, either loaded
from disk or returned from the previous pipeline stage, and processes
its text nodes with L<Text::Aspell>.  It injects additional XML elements
in the document representing which words are incorrectly spelled, and optionally
offers spelling suggestions.

The XML elements injected into the source document appear similar to the following,
though without the exta whitespace.

  <sp:incorrect xmlns:sp="http://axkit.org/2004/07/17-spell-check#">
      <sp:suggestion>CASS</sp:suggestion>
      <sp:suggestion>CUSS</sp:suggestion>
      <sp:word>CSS</sp:word>
  </sp:incorrect>

=head1 OPTIONS

The following options can be used to change the default behavior of this language module:

=head2 AxSpellLanguage

  PerlSetVar AxSpellLanguage fr

Use this directive to change the language you wish to use when checking spelling.
Defaults to "en_US".

=head2 AxSpellSuggestions

  PerlSetVar AxSpellSuggestions 5

Indicates the maximum number of spelling suggestions to return.  This defaults to 3.  If
set to 0, then no suggestions are ever returned.

=head2 AxSpellSkipElements

  PerlSetVar AxSpellSkipElements "h1 title {http://www.w3.org/1999/02/22-rdf-syntax-ns#}RDF"

Informs the spell checking processor to skip any text contained within the specified XML elements.
If you need to specify a namespace URI for an element, then prefix the element's local name with
the namespace URI, enclosed in curly-braces "{}".

=head1 BUGS

=over 4

=item *

Doesn't process attribute text

=item *

Has no facility for specifying alternate spelling databases

=back

=head1 SEE ALSO

L<AxKit>, L<Text::Aspell>

=cut
