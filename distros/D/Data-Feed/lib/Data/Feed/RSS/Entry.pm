
package Data::Feed::RSS::Entry;
use Any::Moose;
use Carp ();
use Data::Feed::Web::Content;
use DateTime::Format::Mail;
use DateTime::Format::W3CDTF;
use Scalar::Util ();

has entry => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
    lazy_build => 1,
);

# Apply after has entry, so that title() and updated() are respected
with 'Data::Feed::Web::Entry';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_entry {
    return {}
}

sub title {
    my ($self, @args) = @_;
    my $item = $self->entry;
    return @args ? $item->{title} = $args[0] : $item->{title};
}

sub link {
    my $item = shift->entry;
    if (@_) {
        $item->{link} = $_[0];
        ## For RSS 2.0 output from XML::RSS. Sigh.
        $item->{permaLink} = $_[0];
    }
    else {
        $item->{link} || $item->{guid};
    }
}

sub links {
    my $item = shift->entry;
    return ( $item->{link} );
}

sub summary {
    my $item = shift->entry;

    if (@_) {
        $item->{description} = 
            (Scalar::Util::blessed($_[0]) || '') eq 'Data::Feed::Web::Content' ?
            $_[0]->body : $_[0];
        ## Because of the logic below, we need to add some dummy content,
        ## so that we'll properly recognize the description we enter as
        ## the summary.
        if (!$item->{content}{encoded} &&
            !$item->{'http://www.w3.org/1999/xhtml'}{body}) {
            $item->{content}{encoded} = ' ';
        }
    }
    else {
        ## Some RSS feeds use <description> for a summary, and some use it
        ## for the full content. Pretty gross. We don't want to return the
        ## full content if the caller expects a summary, so the heuristic is:
        ## if the <entry> contains both a <description> and one of the elements
        ## typically used for the full content, use <description> as summary.
        my $txt = '';
        if ($item->{description} &&
            ($item->{content}{encoded} ||
             $item->{'http://www.w3.org/1999/xhtml'}{body})) {
            $txt = $item->{description};
        }

        Data::Feed::Web::Content->new(
            type => 'text/html',
            body => defined $txt ? $txt : '',
        );
    }
}

sub content {
    my $item    = shift->entry;

    if (@_) {
        my $c = (Scalar::Util::blessed($_[0]) || '') eq 'Data::Feed::Web::Content' ? $_[0]->body : $_[0];
        $item->{content}{encoded} = $c;
    }
    else {
        my $body =
            $item->{content}{encoded} ||
            $item->{'http://www.w3.org/1999/xhtml'}{body} ||
            $item->{description};
        Data::Feed::Web::Content->new(
            type => 'text/html',
            body => defined $body ? $body : '',
        );
    }
}

sub category {
    my $item = shift->entry;
    if (@_) {
        $item->{category} = $item->{dc}{subject} = $_[0];
    }
    else {
        $item->{category} || $item->{dc}{subject};
    }
}

sub author {
    my $item = shift->entry;
    if (@_) {
        $item->{author} = $item->{dc}{creator} = $_[0];
    }
    else {
        $item->{author} || $item->{dc}{creator};
    }
}

## XML::RSS doesn't give us access to the rdf:about for the <item>,
## so we have to fall back to the <link> element in RSS 1.0 feeds.
sub id {
    my $item = shift->entry;

    if (@_) {
        $item->{guid} = $_[0];
    }
    else {
        $item->{guid} || $item->{link};
    }
}

sub issued {
    my $self = shift;
    my $item = $self->entry;

    if (@_) {
        $item->{dc}{date} = DateTime::Format::W3CDTF->format_datetime($_[0]);
        $item->{pubDate} = DateTime::Format::Mail->format_datetime($_[0]);
    }

    return Data::Feed->parse_mail_date($item->{pubDate})
        || Data::Feed->parse_w3cdtf_date($item->{dc}{date} || $item->{dcterms}{date});
}

sub modified {
    my $self = shift;
    my $item = $self->entry;

    if (@_) {
        $item->{dcterms}{modified} =
            DateTime::Format::W3CDTF->format_datetime($_[0]);
    }

    return Data::Feed->parse_w3cdtf_date(
        $item->{dcterms}{modified} || $item->{atom}{updated}
    );
    return ();
}

sub enclosures {
    my $self = shift;

    { no warnings 'once';
        Carp::confess("Cannot handle enclosures when used with XML::RSS")
            if $Data::Feed::Parser::RSS::PARSER_CLASS eq 'XML::RSS';
    }

    { # XXX - We don't support creating enclosures (yet)
        Carp::confess("Cannot handle creation of enclosures (yet)") if @_;
    }

    my @enclosures;
    for my $enclosure ($self->__enclosures) {
        delete $enclosure->{length} unless $enclosure->{length};
        delete $enclosure->{type} unless $enclosure->{type};
        push @enclosures, Data::Feed::Web::Enclosure->new(
            %$enclosure
        );
    }
    for my $content ($self->media_contents) {
        delete $content->{length} unless $content->{length};
        push @enclosures, Data::Feed::Web::Enclosure->new(
            %$content
        );
    }

    return @enclosures;
}

sub media_contents {
    my $item = shift->entry;

    my $media_ns = "http://search.yahoo.com/mrss";
    my $content  = $item->{$media_ns}->{content};

    return () unless $content;
    return ref $content eq 'ARRAY' ?
        @$content :
        $content
    ;
}

sub extract_node_values {
    my ($self, $tagname, $namespace) = @_;
    my $item = $self->entry;
    my $result = $item->{ $namespace }->{$tagname};
    return ref $result eq 'ARRAY' ? @$result : ($result);
}

sub __enclosures {
    my $item = shift->entry;

    return () unless $item->{enclosure};
    return ref $item->{enclosure} eq 'ARRAY' ?
        @{ $item->{enclosure} } :
        $item->{enclosure}
    ;
}

1;

__END__

=head1 NAME

Data::Feed::RSS::Entry - An RSS Entry

=head1 METHODS

=head2 author

=head2 category

=head2 content

=head2 enclosures

=head2 id

=head2 issued

=head2 link

=head2 media_contents

If the RSS is a MediaRSS, returns a list of media associated with the entry.

=head2 modified

=head2 summary

=head2 title

=head2 @values = extract_node_values( $tagname, $namespace )

Attempts to extract value(s) of a random child node specified by the $tagname and $namespace

=cut
