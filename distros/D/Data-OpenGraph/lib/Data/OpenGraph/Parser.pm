package Data::OpenGraph::Parser;
use strict;
use HTML::Parser;

sub new {
    my $class = shift;
    my $parser = HTML::Parser->new(
        api_version => 3,
        start_h => [ sub {
            my ($self, $tag, $attr) = @_;

            return unless $tag eq 'meta';

            my $prop = $attr->{property};
            my $content = $attr->{content};
            return unless $prop && $content;
            return unless $prop =~ s/^og://;

            $self->{properties}->{$prop} = $content;
        }, "self, tagname, attr" ],
    );
    return bless { parser => $parser }, $class;
}

sub parse_string {
    my ($self, $string) = @_;

    my %properties;
    my $parser = $self->{parser};
    local $parser->{properties} = \%properties;
    $parser->parse($string);
    $parser->eof;

    return \%properties;
}

1;
