package Catalyst::Model::XML::Feed;

use warnings;
use strict;

use base qw(Catalyst::Model Class::Accessor);
use Carp;
use XML::Feed;
use MRO::Compat;
use URI;
use Catalyst::Model::XML::Feed::Item;

__PACKAGE__->mk_accessors(qw|ttl feeds|);

=head1 NAME

Catalyst::Model::XML::Feed - Use RSS/Atom feeds as a Catalyst Model

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

In your own model:

     package MyApp::Model::Feeds;
     use base qw(Catalyst::Model::XML::Feed);
     
Then from elsewhere in your application:
 
     $c->model('Feeds')->register('delicious', 'http://del.icio.us/rss');
     $c->model('Feeds')->register('http://blog.jrock.us/');
  
     my @feeds     = $c->model('Feeds')->get_all_feeds;
     my $delicious = $c->model('Feeds')->get('delicious');

You can also pre-register feeds from your config file:

     ---
     Model::Feeds:
       feeds:
         - uri: http://blog.jrock.us/
         - uri: http://search.cpan.org/
         - title: delicious
           uri: http://del.icio.us/rss/

See CONFIGURATION below for details.

=head1 DESCRIPTION

Catalyst::Model::XML::Feed allows you to use XML feeds in your
Catalyst application.  To use a feed, you need to register it with
the C<register> method.

Once a feed is registered, it's automatically cached for you.

=head1 CONFIGURATION

Configuration is accepted via the standard Catalyst method:

    $c->config->{Model::Feeds}->{key} = $value;

Valid keys include:

=over 4

=item ttl 

Time To Live, in seconds, for each feed.  If a feed is older than this
value, it is refreshed from its source.  Defaults to 3600 seconds, 1 hour.

=item feeds

An arrayref of hashes containing feeds to preload.  The hash is
required to contain a key called "uri" or "location", specifing the
URL of the feed to load.  It may optinally contain "name" or "title",
if you wish to override the feed's own title.

=back

Example config in MyApp.yml (assuming you call your feed model
C<Feeds>):

     Model::Feeds:
       feeds:
         - uri: http://blog.jrock.us/
         - title: delicious
           location: http://del.icio.us/rss/
       ttl: 1337

=head1 METHODS

=head2 new

Creates a new instance.  Called for you by Catalyst.  If your config
file contains invalid feeds the feed will be refetched when the feed
content is accessed. This allows your Catalyst app to start even in
the case of an external outage of an RSS feed.

=cut

sub new {
    my $self = shift;
    $self = $self->next::method(@_);
    my @in_feeds = eval { @{$self->feeds} };
    $self->feeds({});

    $self->ttl($self->ttl || 3600);
    foreach my $feed (@in_feeds) {
        my $name = $feed->{name} || $feed->{title};
        my $uri  = $feed->{uri}  || $feed->{location};
        #my $c = $_[0];
        if($name){
            #$c->log->debug("registering XML feed $uri as $name") if $c;
            $self->register($name, $uri);
        }
        else {
            #$c->log->debug("registering XML feed $uri") if $c;
            my @names = $self->register($uri);
            my $name = join q{,},@names;
            #$c->log->debug("feed(s) at $uri created as $name") if $c;
        }
    }

    return $self;
}

=head2 register($uri_of_feed)

Registers a feed with the Model.  If C<$uri_of_feed> points to a feed,
the feed is added under its own name.  If $C<$uri_of_feed> points to
an HTML or XHTML document containing C<< <link> >> tags pointing to
feeds, all feeds are added by using their URIs as their names.

Returns a list of the names of the feeds that were added.

Warns if the C<$uri_of_feeds> doesn't contain a feed
or links to feeds, or it cannot be fetched.

=head2 register($name, $uri_of_feed)

Registers a feed with the Model.  If C<$name> is already registered,
the old feed at C<$name> is forgotten and replaced with the new feed
at C<$uri_of_feed>.  The C<title> of the feed is replaced with
C<$name>.

Warns if C<$uri_of_feed> isn't an XML feed (or doesn't
contain a C<link> to one).  

Throws an exception if the C<$uri_of_feed> links to multiple feeds.

=cut

sub register {
    my $self = shift;
    my ($arg1, $arg2) = @_;

    my $name;
    my $uri;

    if($arg2){
        # get only one feed
        $name = $arg1;
        $uri  = URI->new($arg2);
        my $feed;
        eval {
            $feed = XML::Feed->parse($uri)
                or die XML::Feed->errstr;
        };
        if($@){
            my @feeds = XML::Feed->find_feeds($arg2);
            if(@feeds > 1){
                croak "$arg2 points to too many feeds";
            }
            if(!@feeds){
                carp "$arg2 does not reference any feeds";
		# register $uri as it is, but without the feed, in hope that it comes online later.
            } else {
		$uri = shift @feeds;
	    }
        }

        return $self->_add_uri($uri, $name);
    }
    else {
        $uri = URI->new($arg1);
        my @feed_uris = XML::Feed->find_feeds($uri);
        croak "$arg1 does not reference any feeds" if !@feed_uris;

        my @added;
        foreach my $uri (@feed_uris){
            $uri = URI->new($uri);
            my $name = $self->_add_uri($uri);
            push @added, $name if $name;
        }
        return @added;
    }
}

sub _add_uri {
    my $self = shift;
    my $uri  = shift;
    my $name = shift;
    my $feed;

    eval {
        $feed = XML::Feed->parse($uri)
            or die XML::Feed->errstr;
    };
    if (my $err = $@) {
        carp "Failed to parse feed $uri: $@";
	my $key = $name || $uri;
	# Create feed item without the parsed content then
	$self->feeds->{$key} = Catalyst::Model::XML::Feed::Item->new(undef, $uri);
	return $key;
    }
    $feed->title($name) if $name;
    my $obj  = Catalyst::Model::XML::Feed::Item->new($feed, $uri);
    $name ||= $uri;

    $self->feeds->{$name} = $obj;
    return $name;
}

=head2 names

Returns the names of all registered feeds.

=cut

sub names {
    return keys %{$_[0]->feeds};
}

=head2 get_all_feeds

Returns a list of all registered feeds.  The elements are
C<XML::Feed> objects.

=cut

sub get_all_feeds {
    my $self  = shift;
    my @names = $self->names;
    my @feeds;
    foreach my $name (@names){
        my $feed = $self->get($name);
        push @feeds, $feed;
    }
    return @feeds;
}

=head2 get($name)

Returns the C<XML::Feed> object that corresponds to C<$name>.  Throws
an exception if there is no feed that's named C<$name>.

=cut

sub get {
    my $self = shift;
    my $name = shift;
    my $feed = $self->feeds->{$name};
    croak "No feed named $name" if !ref $feed;

    # refresh the feed if it's too old or if previous fetch failed
    if((time - $feed->updated > $self->ttl) or !defined($feed->feed)) {
        $self->_refresh($name);
	# must update the ref after the refresh for this run of the sub to return the fresh info.
	$feed = $self->feeds->{$name};
    }

    return $feed->feed;
}

=head2 refresh([$name])

Forces the feed C<$name> to be refreshed from the source. If C<$name>
is omitted, refreshes all registered feeds.

=cut

sub refresh {
    my $self = shift;
    my $name = shift;

    if($name){
        $self->_refresh($name);
    }
    else {
        foreach my $name (keys %{$self->feeds}){
            $self->_refresh($name);
        }
    }

    return;
}

sub _refresh {
    my $self = shift;
    my $name = shift;
    my $feed = $self->feeds->{$name};
    croak "No feed named $name" if !ref $feed;

    my $uri  = $feed->uri;
    return $self->_add_uri($uri, $name);
}

=head1 DIAGNOSTICS

=head2 %s does not reference any feeds

The URI you passed to C<register> was not a feed, or did not
C<link> to any feeds.

=head2 %s points to too many feeds

The URI you passed to C<register> referenced more than one feed.  If
you want to register all the feeds, use the one argument form of
C<register> instead of the two argument form.

=head2 No feed named %s

The feed that you requested does not exist.  Try registering it first.

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-xml-feed at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-XML-Feed>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::XML::Feed

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-XML-Feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-XML-Feed>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-XML-Feed>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-XML-Feed>

=back

=head1 SEE ALSO

L<XML::Feed> and L<XML::Feed::Entry>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Model::XML::Feed
