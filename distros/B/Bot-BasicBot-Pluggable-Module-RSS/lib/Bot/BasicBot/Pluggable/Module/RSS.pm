package Bot::BasicBot::Pluggable::Module::RSS;

use warnings;
use strict;
use POE;
use POE::Component::RSSAggregator;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use String::Format;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.02';

sub init {
    my $self = shift;
    $self->config(
        {
            feeds                    => {},
            user_delay               => 600,
            user_init_headlines_seen => 1,
            user_debug               => 0,
            user_tmpdir              => File::Spec->tmpdir(),
            user_format              => 'RSS: %h <%u>'
        }
    );
    $self->{feeds} = $self->get('feeds');

    POE::Session->create(
        inline_states => {
            _start      => \&init_session,
            handle_feed => \&handle_feed,
        },
        args => [$self],
    );

}

sub init_session {
    my ( $kernel, $heap, $session, $module ) = @_[ KERNEL, HEAP, SESSION, ARG0 ];
    $heap->{module} = $module;
    $heap->{rssagg} = POE::Component::RSSAggregator->new(
        alias    => 'rssagg',
        debug    => $module->get('debug'),
        callback => $session->postback("handle_feed"),
        tmpdir   => $module->get('tmpdir'),
    );
    foreach my $uri ( keys %{ $module->{feeds} } ) {
        $kernel->call( 'rssagg', 'add_feed', $module->new_feed($uri) );
    }
}

sub new_feed {
    my ( $self, $uri ) = @_;
    my $name = md5_hex($uri);	
    return {
        url                 => $uri,
        name                => $name,
        delay               => $self->get('delay'),
        init_headlines_seen => $self->get('init_headlines_seen'),
    };
}

sub handle_feed {
    my ( $kernel, $feed, $heap ) = ( $_[KERNEL], $_[ARG1]->[0], $_[HEAP] );
    my $module   = $heap->{module};
    my $uri      = $feed->url();
    my $feeds    = $module->get('feeds');
    my @channels = keys %{ $feeds->{$uri} };
    for my $headline ( $feed->late_breaking_news ) {
        my %formats = (
            h => $headline->headline(),
            u => $headline->url(),
            d => $headline->description(),
        );
        my $user_format = $module->get('user_format');
        foreach my $channel (@channels) {
            $module->tell( $channel, stringf( $user_format, %formats ) );
        }
    }
}

sub told {
	my ($self,$message) = @_;
	# Only act if we are addressed
	if ($message->{address}) {
		my $body    = $message->{body};
		my $channel = $message->{channel};

		if ($channel eq 'msg') {
			$channel = $message->{who}
		}

		my @cmds = split(' ',$body);
		if ($cmds[0] eq 'rss') {
			my %actions = (
				add    => sub { return $self->add_feed( $channel, @_ ) },
				list   => sub { return $self->list_feeds($channel); },
				remove => sub { return $self->remove_feed( $channel, @_ ) },
			);
			if (!defined($actions{$cmds[1]})) {
				return $self->help();
			}
			my $reply = $actions{$cmds[1]}->(@cmds[2,-1]) ;
			return $reply;
		}
	}
}

sub add_feed {
	my ($self,$channel,$uri) = @_;
	if ($uri and ! $self->{feeds}->{$uri}->{$channel}) {
    		POE::Kernel->call( 'rssagg', 'add_feed', $self->new_feed($uri));
		$self->{feeds}->{$uri}->{$channel} = 1;
		$self->set('feeds', $self->{feeds});
		return "Ok.";
	}
	return "Did you forget the uri or was this channel already added?";
}

sub remove_feed {
	my ($self,$channel,$uri) = @_;
	if ( $self->{feeds}->{$uri}->{$channel} ) {
		delete $self->{feeds}->{$uri}->{$channel};
		$self->set('feeds', keys %{$self->{feeds}});
		## We remove the feed from poco if it's the last
		if (!keys %{$self->{feeds}->{$uri}}) {
			my $name = md5_hex($uri);
    			POE::Kernel->call( 'rssagg', 'remove_feed', $name );
			delete $self->{feeds}->{$uri};
		}
		return "Ok.";
	} else {
		return "Mhh, i don't even know about that url";
	}
}

sub list_feeds {
	my ($self,$channel) = @_;
	my $reply;
	for my $uri (keys %{$self->{feeds}}) {
		if ($self->{feeds}->{$uri}->{$channel} ) {
			$reply .= "$uri\n" ;
		}
	}
	if ($reply) {
		return $reply;
	} else {
		return 'Nobody added rss feeds to me yet.';
	}
}

sub help {
	return "rss [add uri|remove|list]";
}

1; # End of Bot::BasicBot::Pluggable::Module::RSS

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::RSS - RSS feed aggregator for your bot

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    !load RSS
    rss add http://search.cpan.org/uploads.rdf
    rss list
    rss remove http://search.cpan.org/uploads.rdf

=head1 DESCRIPTION

This module enables your bot to monitor various RSS feeds for new
headlines and post these to your channels. Every channel has it's
own list of rss feeds, but in case two channels subscribed to the
same rss feeds, it's only checked once and the bot posts changes
to both channels.  Although this module does not block your bot due
the non-blocking interface of L<POE::Component::RSSAggregator>,
adding a lot of fast changing rss feeds will result in sluggish
behaviour.

=head1 VARIABLES

=head2 tmpdir

Directory to keep a cached feed (using Storable) to keep persistance
between instances. This defaults to the first writable directory
from a list of possible temporary directories as provided by
L<File::Spec>.

=head2 debug

Turn debuging on console on. Off by default

=head2 user_init_headlines_seen

Mark all headlines as seen from the intial fetch, and only report
new headlines that appear from that point forward. This defaults
to true.

Changing this variable will not modify any existing feeds.

=head2 user_delay

Number of seconds between updates (defaults to 600).

Changing this variable will not modify any existing feeds.

=head2 user_format

The string defined by user_format will be formated in a printf like
fashion. The actually formatting is done by L<String::Format>. The
formats 'n', 't', and '%' are defined to be a newline, tab, and
'%'. The default format is 'RSS: %h <%u>'.

=over 4

=item %h

The rss headline/title.

=item %u

The rss link/url. URI->canonical is called to attempt to normalize the URL

=item %d

The description of the RSS headline.

=back

=head1 LIMITATIONS

In the moment this module is only able to parse rss feeds and will
throw a lot of warnings at you when you try to add an atom feed as
the underlying wokrhorse of L<POE::Component::RSSAggregator> just
support this one format.

=head1 TODO

The testuite is almost not existing as i'm not yet sure how to
reliable test POE code. I'll have to look into that.

=head1 AUTHOR

Mario Domgoergen, C<< <dom at math.uni-bonn.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::RSS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-RSS>

=back


=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>, L<POE::Component::RSSAggregator>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


