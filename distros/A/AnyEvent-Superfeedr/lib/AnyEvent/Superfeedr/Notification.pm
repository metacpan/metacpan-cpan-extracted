package AnyEvent::Superfeedr::Notification;
use strict;
use warnings;
use XML::Atom::Entry;
use XML::Atom::Feed;
use AnyEvent::Superfeedr();

use Object::Tiny qw{
    http_status
    next_fetch
    feed_uri
    items
    title
    _node_entries
    _atom_entries
};

sub node_entries {
    my $notification = shift;
    my $node_entries = $notification->_node_entries;
    return @$node_entries if $node_entries;

    my @node_entries;
    for my $item (@{ $notification->items }) {
        ## each item as one entry
        my ($node_entry) = $item->nodes;
        push @node_entries, $node_entry;
    }
    $notification->{items} = undef;
    $notification->{_node_entries} = \@node_entries;
    return @node_entries;
}

sub entries {
    my $notification = shift;
    my $atom_entries = $notification->_atom_entries;
    return @$atom_entries if $atom_entries;

    my @atom_entries;
    for my $node_entry ($notification->node_entries) {
        my $str = $node_entry->as_string;
        my $atom_entry = XML::Atom::Entry->new(Stream => \$str);
        push @atom_entries, $atom_entry;
    }
    return @{$notification->{_atom_entries} } = @atom_entries;
}

sub as_atom_feed {
    my $notification = shift;
    my $feed = XML::Atom::Feed->new;
    for ($notification->entries) {
        $feed->add_entry($_);
    }
    return $feed;
}

sub as_xml {
    my $notification = shift;
    my $id = $notification->tagify;
    my $feed_uri = _xml_encode($notification->feed_uri);
    my $title    = _xml_encode($notification->title);
    my $now      = _now_as_w3c();
    my $feed = <<EOX;
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<id>$id</id>
<title>$title</title>
<updated>$now</updated>
<link href="$feed_uri" rel="self" />
EOX
    for my $node_entry ($notification->node_entries) {
        $feed .= $node_entry->as_string;
    }
    $feed .= "</feed>";
    return $feed;
}

sub _now_as_w3c {
    my @time = gmtime;
    sprintf '%4d-%02d-%02dT%02d:%02d:%02dZ',
        $time[5]+1900, $time[4]+1, @time[3,2,1,0];
}

my %enc = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;', '\'' => '&#39;');

sub _xml_encode {
    local $_ = shift;
    s/([&"\'<>])/$enc{$1}/g;
    $_;
}

sub tagify {
    my $notification = shift;

    ## date is based on current time
    my (undef, undef, undef, $mday, $mon, $year) = gmtime();
    $year +=1900;

    ## specific is based on superfeedr's feed:status
    my $specific = $notification->feed_uri || "";
    $specific =~ s{^\w+://}{};
    $specific =~ tr{#}{/};

    return sprintf "tag:%s,%4d-%02d-%02d:%s",
                   $AnyEvent::Superfeedr::SERVICE,
                   $year, $mon, $mday,
                   $specific;
}

1;
