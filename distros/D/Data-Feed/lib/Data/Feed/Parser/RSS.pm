
package Data::Feed::Parser::RSS;
use Any::Moose;
use Data::Feed;
use Data::Feed::RSS;
use Carp();

our $PARSER_CLASS;

BEGIN {
    my @candidates = $ENV{DATA_FEED_RSS_PARSERS} ?
        split(/\s+/, $ENV{DATA_FEED_RSS_PARSERS}) :
        qw(XML::RSS::LibXML XML::RSS);

    foreach my $module (@candidates) {
        eval { Any::Moose::load_class($module) };
        warn if &Data::Feed::DEBUG && $@;
        next if $@;

        $PARSER_CLASS = $module;
        last;
    }

    if (! $PARSER_CLASS) {
        Carp::confess("Cannot find suitable parser class from @candidates");
    }
}

with 'Data::Feed::Parser';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub parse {
    my ($self, $xmlref) = @_;

    my $rss = $PARSER_CLASS->new();
    $rss->parse($$xmlref);

    return Data::Feed::RSS->new(feed => $rss);
}

1;

__END__

=head1 NAME

Data::Feed::Parser::RSS - Data::Feed RSS Parser

=head1 DESCRIPTION

Attempts to parse the given scalar reference (which should contain a valid
RSS xml), using either XML::RSS::LibXML or XML::RSS (whichever one that is
found first will be used)

As of this writing, XML::RSS has some limitations (particularly with enclosures)
so, it is best to stick with XML::RSS::LibXML as long as you have libxml2
and XML::LibXML installed in your system.

=head1 METHODS

=head2 parse

=cut