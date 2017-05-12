package App::RoboBot::Plugin::Parser::XML;
$App::RoboBot::Plugin::Parser::XML::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use HTML::TreeBuilder::XPath;

extends 'App::RoboBot::Plugin';

=head1 parser.xml

Exports a selection of functions for dealing with XML (and similar; e.g. XHTML)
data.

=cut

has '+name' => (
    default => 'Parser::XML',
);

has '+description' => (
    default => 'Provides a selection of functions for dealing with XML data.',
);

=head2 xpath

=head3 Description

Performs an XPath query against the given document body.

=head3 Usage

<xpath query> <document string>

=head3 Examples

    :emphasize-lines: 2-4

    (xpath "//div[@id='main']/div[@class='post']/h2/a/text()" (http-get "http://kottke.org/"))
    ("The colors of friendship"
     "The adjective word order we all follow without realizing it"
     "Gene Wilder, master of the comedic pause" ...)

=cut

has '+commands' => (
    default => sub {{
        'xpath' => { method      => 'xml_xpath',
                     description => 'Performs an XPath query against the given document body.',
                     usage       => '<xpath query> <document string>',
                     example     => '"//div[@id=\'main\']/div[@class=\'post\']/h2/a/text()" (http-get "http://kottke.org/")',
                     result      => '"The colors of friendship" "The adjective word order we all follow without realizing it" ...' },
    }},
);

sub xml_xpath {
    my ($self, $message, $command, $rpl, $query, $document) = @_;

    unless (defined $query && defined $document && length($query) > 0 && length($document) > 0) {
        $message->response->raise('Must provide both an XPath query and a document to search.');
        return;
    }

    my $tree = HTML::TreeBuilder::XPath->new;
    my @res;

    eval {
        $tree->parse($document);
        $tree->eof;

        foreach my $match ($tree->findvalues($query)) {
            push(@res, "$match");
        }
    };

    if ($@) {
        my $err = $@;
        $message->response->push('Could not perform the requested XPath query: %s', $err);
        return;
    }

    return @res;
}

__PACKAGE__->meta->make_immutable;

1;
