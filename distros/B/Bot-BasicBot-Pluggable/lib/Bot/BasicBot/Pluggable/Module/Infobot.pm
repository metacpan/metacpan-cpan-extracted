package Bot::BasicBot::Pluggable::Module::Infobot;
$Bot::BasicBot::Pluggable::Module::Infobot::VERSION = '1.20';
use strict;
use warnings;
use base qw(Bot::BasicBot::Pluggable::Module);

use Data::Dumper;
use LWP::UserAgent ();
use URI;

# this one is a complete bugger to build
eval { require XML::Feed };
our $HAS_XML_FEED = $@ ? 0 : 1;
use constant PROT => "ibprot_";
use constant INFO => "infobot_";

sub init {
    my $self = shift;
    $self->config(
        {
            user_allow_searching  => 0,
            user_min_length       => 3,
            user_max_length       => 25,
            user_num_results      => 20,
            user_passive_answer   => 0,
            user_passive_learn    => 0,
            user_require_question => 1,
            user_http_timeout     => 10,
            user_rss_items        => 5,
            user_stopwords =>
              "here|how|it|something|that|this|what|when|where|which|who|why",
            user_unknown_responses =>
"Dunno.|I give up.|I have no idea.|No clue. Sorry.|Search me, bub.|Sorry, I don't know.",
            db_version => "1",
        }
    );

    # record what we've asked other bots.
    $self->{remote_infobot} = {};
}

sub help {
    return
"An infobot. See http://search.mcpan.org/perldoc?Bot::BasicBot::Pluggable::Module::Infobot.";
}

sub told {
    my ( $self, $mess ) = @_;
    local $self->{mess} = $mess;
    my $body = $mess->{body};
    return unless defined $body;

    # looks like an infobot reply.
    if ( $body =~ s/^:INFOBOT:REPLY (\S+) (.*)$// ) {
        return $self->infobot_reply( $1, $2, $mess );
    }

    # direct commands must be addressed.
    return unless $mess->{address};

    # forget a particular factoid.
    if ( $body =~ /^forget\s+(.*)$/i ) {
	unless ($self->protection_status($mess, $1)) {
	    return $self->delete_factoid($1)
		? "I forgot about $1."
		: "I don't know anything about $1.";
	}
    }

    # ask another bot for facts.
    if ( $body =~ /^ask\s+(\S+)\s+about\s+(.*)$/i ) {
        $self->ask_factoid( $2, $1, $mess );
        return "I'll ask $1 about $2.";
    }

    # tell someone else about a factoid
    if ( $body =~ /^tell\s+(\S+)\s+about\s+(.*)$/i ) {
        $self->tell_factoid( $2, $1, $mess );
        return "Told $1 about $2.";
    }

    # search for a particular factoid.
    if ( $body =~ /^search\s+for\s+(.*)$/i ) {
        return "privmsg only, please" unless ( $mess->{channel} eq "msg" );
        return "searching disabled" unless $self->get("user_allow_searching");
        my @results = $self->search_factoid( split( /\s+/, $1 ) );
        unless (@results) { return "I don't know anything about $1."; }
        $#results = $self->get("user_num_results") - 1
          unless $#results < $self->get("user_num_results");
        return "I know about: " . join( ", ", map { "'$_'" } @results ) . ".";
    }

    if ($self->authed( $mess->{who} )) {
	# protect a particular factoid.
	if ( $body =~ /^protect\s+(.*)$/i ) {
	    return $self->protect_factoid($1)
		? "Protected $1."
		: "Already protected.";
	}

	# unprotect a particular factoid.
	if ( $body =~ /^unprotect\s+(.*)$/i ) {
	    return $self->unprotect_factoid($1)
		? "Unprotected $1."
		: "Was not protected";
	}
    }
}

sub fallback {
    my ( $self, $mess ) = @_;
    local $self->{mess} = $mess;
    my $body = $mess->{body} || "";

    my $is_priv = !defined $mess->{channel} || $mess->{channel} eq 'msg';

    # request starts with "my", so we'll look for
    # a valid factoid for "$mess->{who}'s $object".
    $body =~ s/^my /$mess->{who}'s /;

    my %stopwords =
      map { lc($_) => 1 }
      split( /\s*[\s,\|]\s*/, $self->get("user_stopwords") );

    # checks to see if something starts
    #     <word> (is|are)
    # and then removes if if <word> is a stopword
    # this means that we treat "what is foo?" as "foo?"
    if ( $body =~ /^(.*?)\s+(is|are)\s+(.*)$/i ) {
        $body =~ s/^(.*?)\s+(is|are)\s+//i if $stopwords{$1};
    }

  # answer a factoid. this is a crazy check which ensures we will ONLY answer
  # a factoid if a) there is, or isn't, a question mark, b) we have, or haven't,
  # been addressed, c) the factoid is bigger and smaller than our requirements,
  # and d) that it doesn't look like a to-be-learned factoid (which is important
  # if the user has disabled the requiring of the question mark for answering.)
    my $readdress = $mess->{channel} ne 'msg' && $body =~ s/\s+@\s+(\S+)[.]?\s*$// ? $1 : '';
    my $body_regexp =
      $self->get("user_require_question") && !$is_priv ? qr/\?+$/ : qr/[.!?]*$/;
    if (    $body =~ s/$body_regexp//
        and ( $mess->{address} or $self->get("user_passive_answer") )
        and length($body) >= $self->get("user_min_length")
        and length($body) <= $self->get("user_max_length")
        and $body !~ /^(.*?)\s+(is|are)\s+(.*)$/i )
    {

        # get the factoid and type of relationship
        my ( $is_are, $factoid, $literal ) = $self->get_factoid($body);
        if ( !$literal && $factoid && $factoid =~ /\|/ ) {
            my @f = split /\|/, $factoid;
            $factoid = $f[ int( rand( scalar @f ) ) ];
        }

        # no factoid?
        unless ($factoid) {
            my @unknowns = split( /\|/, $self->get("user_unknown_responses") );
            my $unknown = $unknowns[ int( rand( scalar(@unknowns) ) ) - 1 ];
            return $mess->{address} ? $unknown : undef;
        }

        # variable substitution.
        $factoid =~ s/\$who/$mess->{who}/g;

        # emote?
        if ( $factoid =~ s/^<action>\s*//i ) {
            $self->bot->emote(
                {
                    who     => $readdress || $mess->{who},
                    channel => $mess->{channel},
                    body    => $factoid
                }
            );
            return 1;

            # replying with, or without a noun? hmMmMmmm?!
        }
        elsif ($literal) {
            $body =~ s!^literal\s+!!;
	    $factoid = "$body =${is_are}= $factoid";
        }
        else {
            $factoid = $factoid =~ s/^<reply>\s*//i
              ? $factoid
              : "$body $is_are $factoid";
        }
	if ($readdress) {
	    my %hash = %$mess;
	    $hash{who} = $readdress;
	    $self->reply(\%hash, $factoid);
	    return 1;
	}
	return $factoid;
    }

    # the only thing left is learning factoids. are we
    # addressed or are we willing to learn passively?
    # does it even look like a factoid?
    return unless ( $mess->{address} or $self->get("user_passive_learn") );
    return
      unless ( $body =~ /^(.*?)\s+(is)\s+(.*)$/i
        or $body =~ /^(.*?)\s+(are)\s+(.*)$/i );
    my ( $object, $is_are, $description ) = ( $1, $2, $3 );
    my $literal = ( $object =~ s!^literal\s+!! );

    # allow corrections and additions.
    my ( $nick, $replace, $also ) = ( $self->bot->nick, 0, 0 );
    $replace = 1 if ( $object =~ s/no,?\s+//i );    # no, $object is $fact.
    $replace = 1
      if ( $replace and $object =~ s/^\s*$nick,?\s*//i )
      ;    # no, $bot, $object is $fact.
    $also = 1 if ( $description =~ s/^also\s+//i );    # $object is also $fact.

    # ignore short, long, and stopword'd factoids.
    return if length($object) < $self->get("user_min_length");
    return if length($object) > $self->get("user_max_length");
    foreach ( keys %stopwords ) { return if $object =~ /^$_\b/; }

    # if we're replacing things, remove the factoid first.
    # $also check supports "no, $bot, $object is also $fact".
    if ( $replace and !$also ) {
	unless ($self->protection_status($mess, $object)) {
	    $self->delete_factoid($object);
	}
    }

    # get any current factoid there might be.
    my ( $type, $current ) = $self->get_factoid($object);

    # we can't add without explicit instruction,
    # but shouldn't warn if this is passive.
    if ( $current and !$also and $mess->{address} ) {
        return "... but $object $type $current ...";
    }
    elsif ( $current and !$also and !$mess->{address} ) {
        return;
    }

    unless ( $self->protection_status($mess, $object) ) {
	# add this factoid. this comment is absolutely useless. excelsior.
	$self->add_factoid( $object, $is_are, split( /\s+or\s+/, $description ) );

	# return an ack if we were addressed only
	return $mess->{address} ? "Okay." : 1;
    }
}

sub get_factoid {
    my ( $self, $object ) = @_;

    my $literal = ( $object =~ s!^literal\s+!! );

    # get a list of factoid hashes
    my ( $is_are, @factoids ) = $self->get_raw_factoids($object);

    return unless @factoids;

    #print STDERR Dumper(@factoids);

    # simple is a list of the 'simple' factoids, a is b, etc. These are just
    # joined together. Alternates are factoids that are an alternative to
    # the simple factoids, they will randomly be displayed _instead_.
    my ( @simple, @alternatives );

    for (@factoids) {
        next if $_->{text} =~ m!^\s*$!;
        if ( $_->{alternate} || $_->{alt} ) {
            push @alternatives, $_->{text};
        }
        else {
            push @simple, $_->{text};
        }
    }

    if ($literal) {
        my $return .= join " =or= ", ( @simple, map { "|$_" } @alternatives );
        return ( $is_are, $return, 1 );
    }

    #print STDERR Dumper(@alternatives);

    # the simple list is one of the alternatives
    unshift( @alternatives, join( " or ", @simple ) ) if @simple;

    # pick an option at random
    srand();
    my $factoid = $alternatives[ rand(@alternatives) ];

    #print STDERR "$factoid\n";
    # if there are any RSS directives, get the feed.
    # TODO - this could be done in a more general way, with plugins
    # TODO - this blocks. Bad. you can knock the bot off channel by
    # giving it an RSS feed that'll take a very long time to return.
    $factoid =~
      s/<(?:rss|atom|feed|xml)\s*=\s*\"?([^>\"]+)\"?>/$self->parseFeed($1)/ieg;

    return ( $is_are, $factoid, 0 );
}

# for a given key, return the raw hashes that are in the store for this
# factoid.
sub get_raw_factoids {
    my ( $self, $object ) = @_;
    my $raw = $self->get( INFO . lc($object) )
      or return ();

    #print STDERR Dumper($raw);
    my ( $is_are, @factoids );

    if ( ref($raw) ) {

        # it's a deep structure
        $is_are = $raw->{is_are};
        @factoids = map {
	    ref $_ && /DBM::Deep::Hash/ ? +{ %$_ } : $_
	} @{ $raw->{factoids} || [] };

    }
    else {

        # old-style tab seperated thing
        my @strings;
        ( $is_are, @strings ) = split( /\t/, $raw );
        for my $text (@strings) {
            my $alt = ( $text =~ s/^\|\s*// ? 1 : 0 );
            push @factoids, { alternate => $alt, text => $text };
        }
    }

    return ( $is_are, @factoids );
}

sub add_factoid {
    my ( $self, $object, $is_are, @factoids ) = @_;

    # get the current list, if any
    my ( $current_is_are, @current ) = $self->get_raw_factoids($object);

    # if there's already an is_are set, use it.
    $is_are = $current_is_are if ($current_is_are);
    $is_are ||= "is";    # defaults

    # add these factoids to the list, trimming trailing space after |
    for (@factoids) {
        my $alt = s/^\|\s*// ? 1 : 0;
        push @current,
          {
            alternate => $alt,
            text      => $_,
          };
    }

    my $set = {
        is_are   => $is_are,
        factoids => \@current,
    };

    # put the list back into the store.
    $self->set( INFO . lc($object), $set );

    return 1;
}

sub protection_status {
    my $self = shift;
    my ($mess, $object) = @_;
    $self->get( PROT . lc($object) ) && !$self->authed( $mess->{who} )
}

sub delete_factoid {
    my ( $self, $object ) = @_;
    my $key = INFO . lc($object);
    if ( $self->get($key) ) {
        $self->unset( INFO . lc($object) );
        return 1;
    }
    else {
        return 0;
    }
}

sub protect_factoid {
    my ( $self, $object ) = @_;
    my $key = PROT . lc($object);
    unless ( $self->get($key) ) {
        $self->set( $key, 1 );
        return 1;
    }
    else {
        return 0;
    }
}

sub unprotect_factoid {
    my ( $self, $object ) = @_;
    my $key = PROT . lc($object);
    if ( $self->get($key) ) {
        $self->unset( $key );
        return 1;
    }
    else {
        return 0;
    }
}

sub ask_factoid {
    my ( $self, $object, $ask, $mess ) = @_;

    # unique ID to reference this in future
    my $id = "<" . int( rand(100000) ) . ">";

    # store the message, so we can reply in context later
    $self->{remote_infobot}{$id} = $mess;

    # ask, using an infobot protocol, the thing we've been told to ask.
    # this will hopefully result in a reply coming back later.
    $self->bot->say(
        who     => $ask,
        channel => 'msg',
        body    => ":INFOBOT:QUERY $id $object"
    );
}

sub tell_factoid {
    my ( $self, $object, $tell, $mess ) = @_;

    my ( $is_are, $factoid ) = $self->get_factoid($object);
    my $from = $mess->{who};

    $self->bot->say(
        who     => $tell,
        channel => 'msg',
        body    => "$from wanted you to know: $object $is_are $factoid"
    );
}

sub search_factoid {
    my ( $self, @terms ) = @_;
    my @keys;
    for (@terms) {
        push @keys,
          map { my $term = $_; $term =~ s/^${\(INFO)}// ? $term : () }
          $self->store_keys(
            limit => $self->get("user_num_results"),
            res   => ["$_"]
          );
    }
    return @keys;
}

sub parseFeed {
    my ( $self, $url ) = @_;

    my @items;
    eval {
        my $ua = LWP::UserAgent->new();
        $ua->timeout( $self->get('user_http_timeout') );
        $ua->env_proxy;
        my $feed;
        my $response = $ua->get($url);
        if ( $response->is_success ) {
            $feed = XML::Feed->parse( \$response->content() )
              or die XML::Feed->errstr . "\n";
        }
        else {
            die $response->status_line() . "\n";
        }
        my @entries   = $feed->entries();
        my $max_items = $self->get('user_rss_items');
        if ( $max_items and $max_items < @entries ) {
            splice( @entries, $max_items );
        }
        @items = map { $_->title } @entries;
    };
    if ($@) {
        chomp $@;
        return "<< Error parsing RSS from $url: $@ >>";
    }

    my $ret;
    foreach my $title (@items) {
        $title =~ s/\s+/ /;
        $title =~ s/\n//g;
        $title =~ s/\s+$//;
        $title =~ s/^\s+//;
        $ret .= "${title}; ";
    }
    $ret =~ s/\s*;\s*$//;
    return ( $ret =~ m/^<(reply|action)>/ ? $ret : "<reply>$ret" );
}

# We've been replied to by an infobot.
sub infobot_reply {
    my ( $self, $id, $return, $mess ) = @_;

    # get the message that caused the ask initially, so we can reply to it
    # if there wasn't one, just give up.
    my $infobot_data = $self->{remote_infobot}{$id} or return 1;

    # this is the string that the other infobot returned to us.
    my ( $object, $db, $factoid ) = ( $return =~ /^(.*) =(\w+)=> (.*)$/ );

    $self->set_factoid( $mess->{who}, $object, $db, $factoid );

    # reply to the original request saying 'we got it'
    $self->bot->say(
        channel => $infobot_data->{channel},
        who     => $infobot_data->{who},
        body    => "Learnt about $object from $mess->{who}",
    );

    return 1;

}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Infobot - infobot clone redone in B::B::P.

=head1 VERSION

version 1.20

=head1 SYNOPSIS

Does infobot things - basically remembers and returns factoids. Will ask
another infobot about factoids that it doesn't know about, if you want. Due
to persistent heckling from the peanut gallery, does things pretty much
exactly like the classic infobot, even when they're not necessarily that
useful (for example, saying "Okay." rather than "OK, water is wet."). Further
infobot backwards compatibility is available through additional packages
such as L<Bot::BasicBot::Pluggable::Module::Foldoc>.

=head1 IRC USAGE

The following examples assume you're running Infobot with its defaults settings,
which require the bot to be addressed before learning factoids or answering
queries. Modify these settings with the Vars below.

  <user> bot: water is wet.
   <bot> user: okay.
  <user> bot: water?
   <bot> user: water is wet.
  <user> bot: water is also blue.
   <bot> user: okay.
  <user> bot: water?
   <bot> user: water is wet or blue.
  <user> bot: no, water is translucent.
   <bot> user: okay.
  <user> bot: water?
   <bot> user: water is translucent.
  <user> bot: forget water.
   <bot> user: I forgot about water.
  <user> bot: water?
   <bot> user: No clue. Sorry.

A fact that begins with "<reply>" will have the "<noun> is" stripped:

  <user> bot: what happen is <reply>somebody set us up the bomb.
   <bot> user: okay.
  <user> bot: what happen?
   <bot> user: somebody set us up the bomb.

A fact that begins "<action>" will be emoted as a response:

  <user> bot: be funny is <action>dances silly.
   <bot> user: okay.
  <user> bot: be funny?
    * bot dances silly.

Pipes ("|") indicate different possible answers, picked at random:

  <user> bot: dice is one|two|three|four|five|six
   <bot> user: okay.
  <user> bot: dice?
   <bot> user: two.
  <user> bot: dice?
   <bot> user: four.
  
You can also use RSS feeds as a response:

  <user> bot: jerakeen.org is <rss="http://jerakeen.org/rss">.
   <bot> user: okay.
  <user> bot: jerakeen.org?
   <bot> user: jerakeen.org is <item>; <item>; etc....

You can also ask the bot to learn a factoid from another bot, as follows:

  <user> bot: ask bot2 about fact.
   <bot> user: asking bot2 about fact...
  <user> bot: fact?
   <bot> user: fact is very boring.

Finally, you can privmsg the bot to search for particular facts:

  <user> search for options.
   <bot> I know about 'options indexes', 'charsetoptions override', etc....

=head1 METHODS



=head1 VARS

=over 4

=item min_length

Defaults to 3; the minimum length a factoid, or inquiry, must be before recognizing it.

=item max_length

Defaults to 25; the maximum length a factoid, or inquiry, can be before ignoring it.

=item num_results

Defaults to 20; the number of facts to return for "search for <term>" privmsg.

=item passive_answer

Defaults to 0; when enabled, the bot will answer factoids without being addressed.

=item passive_learn

Defaults to 0; when enabled, the bot will learn factoids without being addressed.

=item require_question

Defaults to 1; determines whether the bot requires a question mark before 
responding to a factoid. When enabled, the question mark is required (ie. "water?").
When disabled, the question mark is entirely optional (ie. "water" would also
produce a response).

=item stopwords

A comma-, space-, or pipe- separated list of words the bot should not learn or
answer. This prevents such insanity as the learning of "where is the store?" and
"how is your mother?" The default list of stopwords contains "here", "how", "it",
"something", "that", "this", "what", "when", "where", "which", "who" and "why").

=item unknown_responses

A pipe-separated list of responses the bot will randomly choose from when it
doesn't know the answer to a question. The default list of response contains
"Dunno.", "I give up.", "I have no idea.", "No clue. Sorry.", "Search me, bub.",
and "Sorry, I don't know."

=item allow_searching

Defaults to 0. 

Searching on large factoid lists is ... problematic.

=item http_timeout

Time in seconds for an http request to timeout. When this value is
set to a very high value, a slow site can disconnect a bot by
blocking it. Defaults to 10.

=item rss_items

Maximal numbers of items returns when using RSS feeds. Defaults to 5.

=back

=head1 BUGS

"is also" doesn't work on <reply>s (ie. "<bot> cheetahs! or <reply>monkies.")

"is also" doesn't work on <action>s (same as the previous bug, hobo.)

The pipe syntax for random replies doesn't actually work. At all. Um.

We should probably make a "choose_random_response" function.

"<bot>?" fails, due to removal of <bot> name from $mess->body.

"ask" syntax doesn't work in a private message.

The tab stops are set to 2, not 4. OHMYGOD.

If a "search" fails, the bot doesn't tell you.

"search" is case-sensitive.

If Title module is loaded, <rss> factoids don't work cos of told/fallback.

=head1 REQUIREMENTS

URI

L<LWP::Simple>

L<XML::Feed>

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
