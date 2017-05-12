package Data::Feed::Atom::Entry;
use Any::Moose;
use Data::Feed::Web::Content;
use XML::Atom::Entry;

has entry => (
    is => 'rw',
    isa => 'XML::Atom::Entry',
    required => 1,
    lazy_build => 1,
    handles => [
        qw(title updated)
    ]
);

# Apply after has entry, so that title() and updated() are respected
with 'Data::Feed::Web::Entry';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_entry { return XML::Atom::Entry->new() }

sub link {
    my $entry = shift;
    if (@_) {
        return $entry->entry->add_link({ rel => 'alternate', href => $_[0],
                                    type => 'text/html', });
    } else {
        foreach my $link ($entry->entry->link) {
            if (defined $link && ! defined $link->rel || $link->rel eq 'alternate' ) {
                return $link->href;
            }
        }
    }
    return ();
}

sub links {
    my $entry = shift;
    return $entry->entry->link;
}

sub summary {
    my $entry = shift;
    if (@_) {
        $entry->entry->summary(
            (Scalar::Util::blessed($_[0]) || '') eq 'Data:::Feed::Web::Content' ?
                $_[0]->body : $_[0]
        );
    } else {
        Data::Feed::Web::Content->new( type => 'html',
                                   body => $entry->entry->summary || '' );
    }
}

sub content {
    my $entry = shift;
    if (@_) {
        my %param;
        if (Scalar::Util::blessed $_[0] && $_[0]->isa('Data::Feed::Web::Content')) {
            %param = (Body => $_[0]->body);
        } else {
            %param = (Body => $_[0]);
        }
        $entry->entry->content(XML::Atom::Content->new(%param, Version => 1.0));
    } else {
        my $c = $entry->entry->content;

        # map Atom types to MIME types
        my $type = $c ? $c->type : 'text';
        if ($type) {
            $type = 'text/html'  if $type eq 'xhtml' || $type eq 'html';
            $type = 'text/plain' if $type eq 'text';
        }

        Data::Feed::Web::Content->new( type => $type,
                                   body => $c ? $c->body : '' );
    }
}

sub category {
    my $entry = shift;
    my $ns = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
    if (@_) {
        $entry->entry->add_category({ term => $_[0] });
    } else {
        my $category = $entry->entry->category;
        $category ? ($category->label || $category->term) : $entry->entry->get($ns, 'subject');
    }
}

sub author {
    my $entry = shift;
    if (@_ && $_[0]) {
        my $person = XML::Atom::Person->new(Namespace => $entry->entry->ns, Version => 1.0);
        $person->name($_[0]);
        $entry->entry->author($person);
    } else {
        $entry->entry->author ? $entry->entry->author->name : undef;
    }
}

sub id { shift->entry->id(@_) }

sub issued {
    my $entry = shift;
    if (@_) {
        $entry->entry->issued(DateTime::Format::W3CDTF->format_datetime($_[0])) if $_[0];
    } else {
        Data::Feed->parse_datetime($entry->entry->issued);
    }
}

sub modified {
    my $entry = shift;
    if (@_) {
        $entry->entry->modified(DateTime::Format::W3CDTF->format_datetime($_[0])) if $_[0];
    } else {
        Data::Feed->parse_w3cdtf_date($entry->entry->modified);
    }
}

sub enclosures {
    my $self = shift;

    die if @_;

    my @enclosures;
    for my $link ( grep { defined $_->rel && $_->rel eq 'enclosure' } $self->entry->link ) {
        my $enclosure = Data::Feed::Web::Enclosure->new(
            url => $link->href,
        );
        $enclosure->length($link->length) if $link->length;
        $enclosure->type($link->type) if $link->type;
        push @enclosures, $enclosure;
    }

    @enclosures;
}

sub extract_node_values {
    my ($self, $tagname, $namespace) = @_;
    $tagname = "$namespace:$tagname" if $namespace;
    my @elements = map { $_->textContent }
        $self->entry->{elem}->getElementsByTagName( $tagname );
    return @elements;
}

1;

__END__

=head1 NAME

Data::Feed::Atom::Entry - An Atom Entry

=head1 METHODS

=head2 author

=head2 category

=head2 content

=head2 enclosures

=head2 id

=head2 issued

=head2 link

=head2 modified

=head2 summary

=head2 title

=head2 @values = extract_node_values( $tagname, $namespace )

Attempts to extract value(s) of a random child node specified by the $tagname and $namespace

=cut

