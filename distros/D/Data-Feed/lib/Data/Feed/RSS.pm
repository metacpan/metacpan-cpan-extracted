
package Data::Feed::RSS;
use Any::Moose;
use Data::Feed::Parser::RSS;
use Data::Feed::RSS::Entry;
use DateTime::Format::Mail;

with 'Data::Feed::Web::Feed';

has feed => (
    is => 'rw',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_feed {
    return $Data::Feed::Parser::RSS::PARSER_CLASS->new( version => '2.0');
}

sub format { 'RSS ' . $_[0]->feed->{version} }

## The following elements are the same in all versions of RSS.
sub title       { shift->feed->channel('title', @_) }
sub link        { shift->feed->channel('link', @_) }
sub description { shift->feed->channel('description', @_) }
sub tagline     { shift->feed->channel('description', @_) }
sub icon        { shift->feed->channel('atom:icon', @_) }
sub as_xml      { shift->feed->as_string }

## This is RSS 2.0 only--what's the equivalent in RSS 1.0?
sub copyright   { shift->feed->channel('copyright', @_) }

# This is also RSS 2.0 only.
sub base        {
    my $f = shift->feed;
    if (my $m = $f->can('base')) {
        return $f->$m(@_);
    }

    if (@_) {
        $f->{'xml:base'} = shift;
    }
    return $f->{'xml:base'};
}

## The following all work transparently in any RSS version.
sub language {
    my $feed = shift->feed;

    if (@_) {
        $feed->channel('language', $_[0]);
        $feed->channel->{dc}{language} = $_[0];
    }
    else {
        $feed->channel('language') ||
        $feed->channel->{dc}{language};
    }
}

sub generator {
    my $feed = shift->feed;

    if (@_) {
        $feed->channel('generator', $_[0]);
        $feed->channel->{'http://webns.net/mvcb/'}{generatorAgent} =
            $_[0];
    }
    else {
        $feed->channel('generator') ||
        $feed->channel->{'http://webns.net/mvcb/'}{generatorAgent};
    }
}

sub author {
    my $feed = shift->feed;

    if (@_) {
        $feed->channel('webMaster', $_[0]);
        $feed->channel->{dc}{creator} = $_[0];
    }
    else {
        $feed->channel('webMaster') ||
        $feed->channel->{dc}{creator};
    }
}

sub modified {
    my $feed = shift->feed;

    if (@_) {
        $feed->channel('pubDate',
            DateTime::Format::Mail->format_datetime($_[0]));
        ## XML::RSS is so weird... if I set this, it will try to use
        ## the value for the lastBuildDate, which I don't want--because
        ## this date is formatted for an RSS 1.0 feed. So it's commented out.
        #$rss->channel->{dc}{date} =
        #    DateTime::Format::W3CDTF->format_datetime($_[0]);
    } else {
        return Data::Feed->parse_mail_date($feed->channel('pubDate'))
            || Data::Feed->parse_w3cdtf_date($feed->channel->{dc}{date});
    }
}

sub entries {
    my $feed = $_[0]->feed;
    my @entries;
    for my $item (@{ $feed->{items} }) {
        push @entries, Data::Feed::RSS::Entry->new( entry => $item );
    }
    @entries;
}

sub add_entry {
    my $feed = shift->feed;
    for my $entry (@_) {
        $feed->add_item(%{ $entry->entry });
    }
}

1;

__END__

=head1 NAME

Data::Feed::RSS - RSS Feed

=head1 METHODS

=head2 add_entry

=head2 author

=head2 as_xml

=head2 copyright

=head2 description

=head2 entries

=head2 format

=head2 generator

=head2 language

=head2 link

=head2 modified

=head2 tagline

=head2 title

=head2 icon

=head2 base

=cut

