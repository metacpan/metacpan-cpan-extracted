package Bot::BasicBot::Pluggable::Module::TwitterWatch;

use strict;
use base 'Bot::BasicBot::Pluggable::Module';
use Net::Twitter::Lite;
use HTML::Entities;

our $VERSION = '0.02';

=head1 NAME

Bot::BasicBot::Pluggable::Module::TwitterWatch - report new tweets matching given search patterns

=head1 DESCRIPTION

Watches Twitter for tweets matching given search patterns, and reports them.


=head1 SYNOPSIS

Load the module as with any other Bot::BasicBot::Pluggable module, then tell it
what to monitor - use these commands within a channel:

  !twitterwatch search term here
  !twitterunwatch search term here
  !twittersearches
  !twitterignore username

Each channel has its own just of searches stored.

=cut

sub said {
    my ($self, $mess, $pri) = @_;
    return unless $pri == 2;

    my $message;
    if (my($command, $params) = $mess->{body} =~ /^!(twitter\w+) (.+)/i) {
        # We need to know what channel we're talking about, so if this was a
        # direct message, complain:
        if ($mess->{channel} eq 'msg') {
            return "Use the command in which the search results should appear";
        }

        $params = lc $params;
        $params =~ s/\s+$//;
        my $searches = $self->get('twitter_searches') || {};
        $searches->{ lc $mess->{channel} } ||= {};
        my $chansearches = $searches->{ lc $mess->{channel} };

        if (lc $command eq 'twitterwatch') {
            $chansearches->{$params} = 0;
            $message =  "OK, now watching for '$params'";
        } elsif (lc $command eq 'twitterunwatch') {
            if (exists $chansearches->{$params}) {
                delete $chansearches->{$params};
                $message = "OK, no longer watching for '$params'";
            } else {
                $message = "I wasn't watching for '$params'.";
            }
        } elsif (lc $command eq 'twittersearches') {
            $message = "Currently watching for: "
                . join ',', map { qq["$_"] } keys %$chansearches;
        } elsif (lc $command eq 'twitterignore') {
            my $ignore = $self->get('twitter_ignore') || {};
            $ignore->{$params}++;
            $message = "OK, ignoring tweets from '$params'";
        }

   
    $self->set('twitter_searches', $searches);

    return $message;
    }
}

# Tick is called automatically every 5 seconds
sub tick {
    my $self = shift;
    my $seconds_between_checks = $self->get('twitter_search_wait') || 60 * 3;
    return if time - $self->get('twitter_last_searched') 
        < $seconds_between_checks;

    # OK, time to do the searches:
    my $twitter = Net::Twitter::Lite->new;
    my $searches = $self->get('twitter_searches') || {};
    my $ignore   = $self->get('twitter_ignore')   || {};

    for my $channel (keys %$searches) {
        my %results;
        for my $searchterm (keys %{ $searches->{$channel} }) {
            my $last_id = $searches->{$channel}{$searchterm} || 0;
            warn "Searching for '$searchterm' after $last_id on behalf of $channel";
            my $results = $twitter->search({
                q        => $searchterm,
                since_id => $last_id,
            }) or return;

            # Only process the results if we had a previous max ID; if not, this
            # must be a newly-added search term, so don't spam the channel with
            # all the initial matches, just find new ones from now on
            if ($last_id) {
                my %tweets_from_user;
                for my $result (
                    grep { $_->{id} > $last_id } @{ $results->{results} }
                ) {
                    if ($ignore->{lc $result->{from_user}}) {
                        warn "Ignoring tweet from $result->{from_user} :"
                            . $result->{text};
                        return;
                    }

                    # Retweets can be a bit spammy at times, so skip them:
                    next if $result->{text} =~ /^RT/;

                    next if ++$tweets_from_user{$result->{from_user}} > 3;
                    
                    # See whether this is a newly-created spam account:
                    my $user_details = $twitter->lookup_users(
                        { screen_name => $result->{from_user} }
                    );
                    $user_details = $user_details->[0]
                        or next;
                    if ($user_details->{statuses_count} < 40) {
                        warn "Ignoring new spam account $result->{from_user}";
                        next;
                    }
                    
                    # Results are stored in a hash keyed on ID, so tweets that
                    # match more than one search only appear once
                    $results{ $result->{id} } = $result;

                }
            }

            # Remember the ID of the highest match for this search, so we know
            # where to start from next time
            $searches->{$channel}{$searchterm} = $results->{max_id};
        }


        # Right, now go through the results for the searches for this channel
        # and assemble the messages we're going to send.
        my @results;
        for my $tweetid (reverse sort keys %results) {
            my $result = $results{$tweetid};
            push @results, sprintf 'Twitter: @%s: "%s"',
                $result->{from_user}, 
                HTML::Entities::decode_entities($result->{text});
        }



        # TODO: probably check if we found too many results to sensibly relay
        for my $result (@results) {
            $self->say(channel => $channel, body => $result);
        }
    }
    
    $self->set('twitter_last_searched', time);
    $self->set('twitter_searches', $searches);
            
}



=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-twitterwatch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-TwitterWatch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::TwitterWatch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-TwitterWatch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-TwitterWatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-TwitterWatch>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-TwitterWatch/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::TwitterWatch
