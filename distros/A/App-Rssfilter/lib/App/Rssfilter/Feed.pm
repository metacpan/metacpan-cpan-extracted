use strict;
use warnings;

# ABSTRACT: Get the latest or previous version of an RSS feed


package App::Rssfilter::Feed;
{
  $App::Rssfilter::Feed::VERSION = '0.07';
}

use Moo;
with 'App::Rssfilter::Logger';
use Method::Signatures;



has name => (
    is => 'ro',
    required => 1,
);


has url => (
    is => 'ro',
    required => 1,
);


has rules => (
    is => 'ro',
    default => sub { [] },
);


has user_agent => (
    is => 'ro',
    default => sub { use Mojo::UserAgent; Mojo::UserAgent->new },
);


has storage => (
    is => 'lazy',
    default => method {
        use App::Rssfilter::Feed::Storage;
        App::Rssfilter::Feed::Storage->new(
            name  => $self->name,
        );
    },
);

method BUILDARGS( %options ) {
    if( 1 == keys %options ) {
        @options{ 'name', 'url' } = each %options;
        delete $options{ $options{ name } };
    }
    return { %options };
}


method add_rule( $rule, @rule_options ) {
    use Scalar::Util qw< blessed >;
    if ( ! blessed( $rule ) or ! $rule->isa( 'App::Rssfilter::Rule' ) ) {
        unshift @rule_options, $rule; # restore original @_
        use App::Rssfilter::Rule;
        $rule = App::Rssfilter::Rule->new( @rule_options );
    }

    push @{ $self->rules }, $rule;
    return $self;
}


method update( ArrayRef :$rules = [], :$storage = $self->storage ) {
    $storage = $storage->set_name( $self->name );
    my $old = $storage->load_existing;

    my $headers = {};
    if( defined( my $last_modified = $storage->last_modified ) ) {
        $self->logger->debug( "last update was $last_modified" );
        ${ $headers }{ 'If-Modified-Since' } = $last_modified;
    }

    my $latest = $self->user_agent->get(
        $self->url,
        $headers
    );

    my @rules = @{ $rules };
    push @rules, @{ $self->rules };

    if ( 200 == $latest->res->code ) {
        $self->logger->debug( 'found a newer feed!' );
        $self->logger->debug( 'filtering '. $self->name );
        my $new = $latest->res->dom;
        for my $rule ( @rules ) {
            $self->logger->debugf( 'applying %s => %s to new feed', $rule->condition_name, $rule->action_name ) if $self->logger->is_debug;
            $rule->constrain( $new );
        }
        $storage->save_feed( $new );
    }

    if ( defined $old ) {
        $self->logger->debug( 'collecting guids from old feed' );
        for my $rule ( @rules ) {
            $rule->constrain( $old );
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Feed - Get the latest or previous version of an RSS feed

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::Rssfilter::Feed;

    my $feed = App::Rssfilter::Feed->new( filename => 'http://get.your.files/here.rss' );
    # shorthand for
    $feed = App::Rssfilter::Feed->new(
        name => 'filename',
        url  => 'http://get.your.files/here.rss',
    );

    my $rule = App::RssFilter::Rule->new( 
        condition => 'A Matcher',
        action    => 'A Filter',
    );
    $feed->add_rule( $rule );

    $feed->add_rule(
        condition => 'Another Matcher',
        action    => 'Another Filter',
    );

    $feed->update;

    ### or with App::Rssfilter::Group

    use App::Rssfilter::Group;
    my $group = App::RssFilter::Group->new( 'Tubular' );
    $group->add_feed( RadName => 'http://r.a.d.i.c.al/feed.rss' );
    # shorthand for
    $group->add_feed(
        App::Rssfilter::Feed->new(
            RadName => 'http://r.a.d.i.c.al/feed.rss'
        )
    );
    $group->update;

=head1 DESCRIPTION

This module fetches the latest version of an RSS feed from a URL and constrains it with its list of L<rules|App::Rssfilter::Rule>.

It consumes the L<App::Rssfilter::Logger> role.

=head1 ATTRIBUTES

=head2 logger

This is a object used for logging. It defaults to a L<Log::Any> object. It is provided by the L<App::Rssfilter::Logger> role.

=head2 name

This is the name of the feed to use when storing it, and is required. This will be used by the default C<storage> as the filename to store the feed under.

=head2 url

This is the URL to fetch the latest feed content from, and is required.

=head2 rules

This is the arrayref of L<rules|App::Rssfilter::Rule> which will constrain newly-fetched feeds. It defaults to an empty arrayref.

=head2 user_agent

This is a L<Mojo::UserAgent> to use to fetch this feed's C<url>. It defaults to a new L<Mojo::UserAgent>.

=head2 storage

This is the L<App::Rssfilter::Feed::Storage> to store newly-fetched iRSS documents, or retrieve the previously-fetched version. It defaults to a new L<App::Rssfilter::Feed::Storage>, with its name set to this feed's name.

=head1 METHODS

=head2 add_rule

    $feed->add_rule( $rule )->add_rule( %rule_parameters );

Adds the C<$rule> (or creates a new L<App::RssFilter::Rule> from the passed parameters) to the rules.

=head2 update

    $feed->update( rules => $rules, storage => $storage );

This method will:

=over 4

=item *

download the RSS feed from the URL, if it is newer than the previously-saved version

=item *

apply the rules to the new RSS feed

=item *

save the new RSS feed

=item *

apply the rules to the old RSS feed

=back

The old feed has rules applied to it so that any group-wide rules will always see all of the latest items, even if a feed does not have a newer version available. 

The parameters are optional. C<$rules> should be an arryref of additional rules to be added to the feed's C<rules> for this update only. C<$storage> should be an L<App::Rssfilter::Feed::Storage> that will used instead of this feed's C<storage> to load/save RSS doucments.

=head1 SEE ALSO

=over 4

=item *

L<App::RssFilter::Feed::Storage>

=item *

L<App::RssFilter::Group>

=item *

L<App::RssFilter::Rule>

=item *

L<App::RssFilter>

=back

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
