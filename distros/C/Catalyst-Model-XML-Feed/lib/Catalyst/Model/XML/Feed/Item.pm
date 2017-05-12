#!/usr/bin/perl
# Item.pm
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package Catalyst::Model::XML::Feed::Item;
use strict;
use warnings;

sub new {
    my ($class, $feed, $uri) = @_;
    my $self =
      { _feed    => $feed,
        _uri     => $uri,
        _updated => time,
      };

    bless $self, $class;
    return $self;
}

sub feed {
    my $self = shift;
    return $self->{_feed};
}

sub uri {
    my $self = shift;
    return $self->{_uri};
}

sub updated {
    my $self = shift;
    return $self->{_updated};
}

1;
__END__

=head1 NAME

Catalyst::Model::XML::Feed::Item - stores some extra information about
each XML feed.

=head1 SYNOPSIS

   $feed{$name} = Catalyst::Model::XML::Feed::Item->new($feed, $uri);
   $feed{$name}->uri;
   $feed{$name}->updated;
   $feed{$name}->feed;

=head1 METHODS

=head2 new($feed, $uri)

Creates an instance.

=head2 uri

Returns the original URI of the feed.

=head2 updated

Returns the time when the Item was created.

=head2 feed

Returns the feed.

=cut
