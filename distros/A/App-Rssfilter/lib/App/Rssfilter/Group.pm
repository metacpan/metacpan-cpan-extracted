# ABSTRACT: associate one or more rules with more than one feed

use strict;
use warnings;


package App::Rssfilter::Group;
{
  $App::Rssfilter::Group::VERSION = '0.07';
}
use Moo;
with 'App::Rssfilter::Logger';
with 'App::Rssfilter::FromHash';
with 'App::Rssfilter::FromYaml';
use Method::Signatures;

method BUILDARGS( @options ) {
    if( 1 == @options ) {
        unshift @options, 'name';
    }
    return { @options };
}


method update( ArrayRef :$rules = [], :$storage = $self->storage ) {
    my $child_storage = $storage->path_push( $self->name );
    my @rules = map { @{ $_ } } $rules, $self->rules;
    $self->logger->debugf( 'filtering feeds in %s', $self->name );
    $_->update( rules => \@rules, storage => $child_storage ) for @{ $self->groups };
    $_->update( rules => \@rules, storage => $child_storage ) for @{ $self->feeds };
}



has name => (
    is => 'ro',
    default => sub { '.' },
);


has storage => (
    is => 'ro',
    default => method { App::Rssfilter::Feed::Storage->new },
);


has groups => (
    is => 'ro',
    default => sub { [] },
);


method add_group( $app_rssfilter_group, @group_options ) {
    use Scalar::Util qw< blessed >;
    if ( ! blessed( $app_rssfilter_group ) or ! $app_rssfilter_group->isa( 'App::Rssfilter::Group' ) ) {
        unshift @group_options, $app_rssfilter_group; # restore original @_
        $app_rssfilter_group = App::Rssfilter::Group->new( @group_options );
    }

    push @{ $self->groups }, $app_rssfilter_group;
    return $self;
}


method group( $name ) {
    use List::Util qw< first >;
    first { $_->name eq $name } reverse @{ $self->groups };
}


has rules => (
    is => 'ro',
    default => sub { [] },
);


method add_rule( $app_rssfilter_rule, @rule_options ) {
    use Scalar::Util qw< blessed >;
    if ( ! blessed( $app_rssfilter_rule ) or ! $app_rssfilter_rule->isa( 'App::Rssfilter::Rule' ) ) {
        unshift @rule_options, $app_rssfilter_rule; # restore original @_
        use App::Rssfilter::Rule;
        $app_rssfilter_rule = App::Rssfilter::Rule->new( @rule_options );
    }

    push @{ $self->rules }, $app_rssfilter_rule;
    return $self;
}


has feeds => (
    is => 'ro',
    default => sub { [] },
);


method add_feed( $app_rssfilter_feed, @feed_options ) {
    use Scalar::Util qw< blessed >;
    if ( ! blessed( $app_rssfilter_feed ) or ! $app_rssfilter_feed->isa( 'App::Rssfilter::Feed' ) ) {
        unshift @feed_options, $app_rssfilter_feed; # restore original @_
        use App::Rssfilter::Feed;
        $app_rssfilter_feed = App::Rssfilter::Feed->new( @feed_options );
    }

    push @{ $self->feeds }, $app_rssfilter_feed;
    return $app_rssfilter_feed;
}


method feed( $name ) {
    use List::Util qw< first >;
    first { $_->name eq $name } reverse @{ $self->feeds };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Group - associate one or more rules with more than one feed

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::RssFilter::Group;

    my $news_group = App::Rssfilter::Group->new( 'news' );
    # shorthand for
    $news_group = App::Rssfilter::Group( name => 'news' );

    $news_group->add_group( 'USA' );
    # shorthand for
    $news_group->add_group(
        App::Rssfilter::Group->new(
            name => 'USA',
        )
    );
    my $uk_news_group = $news_group->add_group( name => 'UK' );

    $uk_news_group->add_rule( 'Category[Politics]' => 'MarkTitle' );
    # shorthand for
    $uk_news_group->add_rule(
        App::Rssfilter::Rule->new(
            condition => 'Category[Politics]',
            action    => 'MarkTitle',
        )
    );

    my $dupe_rule = $news_group->group( 'USA' )->add_rule( condition => 'Duplicate', action => 'DeleteItem' );
    $uk_news_group->add_rule( $dupe_rule );

    $news_group->group( 'USA' )->add_feed( WashPost => 'http://feeds.washingtonpost.com/rss/national' );
    # shorthand for
    $news_group->group( 'USA' )->add_feed(
        App::Rssfilter::Feed->new(
            name => 'WashPost',
            url  => 'http://feeds.washingtonpost.com/rss/national',
       )
    );
    $news_group->group( 'USA' )->add_feed( name => 'NYTimes', url => 'http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml' );

    $uk_news_group->add_feed( $news_group->group( 'USA' )->feed( 'WashPost' ) );

    $news_group->update;

=head1 DESCRIPTION

This module groups together feeds so that the same rules will be used to constrain them.

It consumes the L<App::Rssfilter::Logger> role.

Use a group to:

=over 4

=item *

allow rules which retain state (e.g. L<Duplicates|App::Rssfilter::Match::Duplicates>) to constrain over multiple feeds

=item *

apply the same rules configuration to multiple feeds

=back

=head1 ATTRIBUTES

=head2 logger

This is a object used for logging; it defaults to a L<Log::Any> object. It is provided by the L<App::Rssfilter::Logger> role.

=head2 name

This is the name of the group. Group names are used when storing a feed so that feeds from the same group are kept together. The default value is '.' (a single period).

=head2 storage

This is a feed storage object for feeds to use when they are updated. The default value is a fresh instance of L<App::Rssfilter::Feed::Storage>. See L</update> for details on when the default value is used.

=head2 groups

This is an arrayref of subgroups attatched to this group.

=head2 rules

This is an arrayref of rules to apply to the feeds in this group (and subgroups).

=head2 feeds

This is an arrayref of feeds.

=head1 METHODS

=head2 update

    $group->update( rules => $rules, storage => $storage );

Recursively calls C<update> on the feeds and subgroups of this group.

C<$rules> is an arrayref of additional rules to constrain the feed and groups, in addition to the group's current list of rules.

C<$storage> is the feed storage object that feeds and subgroups will use to store their updated contents. If not specified, groups will use their default C<storage>. The group's C<name> is appended to the current path of C<$storage> before being passed to feeds and subgroups.

=head2 add_group

    $group = $group->add_group( $app_rssfilter_group | %group_options );

Adds C<$app_rssfilter_group> (or creates a new App::RssFilter::Group instance from the C<%group_options>) to the list of subgroups for this group. Returns this group (for chaining).

=head2 group

    my $subgroup = $group->group( $name );

Returns the last subgroup added to this group whose name is C<$name>, or C<undef> if no matching group.

=head2 add_rule

    $group = $group->add_rule( $app_rssfilter_rule | %rule_options )

Adds C<$app_rssfilter_rule> (or creates a new App::RssFilter::Rule instance from the C<%rule_options>) to the list of rules for this group. Returns this group (for chaining).

=head2 add_feed

    $group = $group->add_feed( $app_rssfilter_feed | %feed_options );

Adds C<$app_rssfilter_feed> (or creates a new App::RssFilter::Feed instance from the C<%feed_options>) to the list of feeds for this group. Returns this group (for chaining).

=head2 feed

    my $feed = $group->feed( $name );

Returns the last feed added to this group whose name is C<$name>, or C<undef> if no matching feed.

=head2 from_hash

    my $group = App::Rssfilter::Group::from_hash( %config );

Returns a new instance of this class with the feeds, rules, and subgroups specifed in C<%config>. This method is provided by L<App::Rssfilter::FromHash/from_hash>, which has additional documentation & examples.

=head2 from_yaml

    my $group = App::Rssfilter::Group::from_yaml( $yaml_config );

Returns a new instance of this class with the feeds, rules, and subgroups specifed in C<$yaml_config>. This method is provided by L<App::Rssfilter::FromYaml/from_yaml>, which has additional documentation & examples.

=head1 SEE ALSO

=over 4

=item *

L<App::RssFilter::Rule>

=item *

L<App::RssFilter::Feed>

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
