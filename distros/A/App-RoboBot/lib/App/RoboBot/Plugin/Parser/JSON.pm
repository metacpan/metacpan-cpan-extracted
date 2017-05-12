package App::RoboBot::Plugin::Parser::JSON;
$App::RoboBot::Plugin::Parser::JSON::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use JSON;
use JSON::Path;

extends 'App::RoboBot::Plugin';

=head1 parser.json

Exports a selection of functions for dealing with JSON structures.

=cut

has '+name' => (
    default => 'Parser::JSON',
);

has '+description' => (
    default => 'Provides a selection of functions for dealing with JSON structures.',
);

=head2 jq

=head3 Description

Performs a JSONPath query (similar in concept to XPath)  against the given
JSON document. JSONPath is described at http://goessner.net/articles/JsonPath/.

=head3 Usage

<jsonpath query> <document string>

=head3 Examples

    :emphasize-lines: 2

    (jq "$.name" "{\"name\": \"Robert\", \"age\": 70 }")
    "Robert"

=cut

has '+commands' => (
    default => sub {{
        'jq' => { method      => 'json_jq',
                  description => 'Performs an JSONPath query against the given JSON document.',
                  usage       => '<jsonpath query> <document string>',
                  example     => '"$.name" "{\"name\": \"Robert\", \"age\": 70 }"',
                  result      => '"Robert"' },
    }},
);

sub json_jq {
    my ($self, $message, $command, $rpl, $query, $document) = @_;

    unless (defined $query && defined $document && length($query) > 0 && length($document) > 0) {
        $message->response->raise('Must provide both an XPath query and a document to search.');
        return;
    }

    my @res;

    eval {
        my $json = decode_json($document);
        my $path = JSON::Path->new($query);

        foreach my $match ($path->values($json)) {
            push(@res, $match);
        }
    };

    if ($@) {
        my $err = $@;
        $message->response->push('Could not perform the requested JSONPath query: %s', $err);
        return;
    }

    return @res;
}

__PACKAGE__->meta->make_immutable;

1;
