###########################################
###########################################
package Bot::WootOff;
###########################################
###########################################
use strict;
use warnings;
use HTTP::Request::Common qw(GET);
use POE qw(Component::Client::HTTP);
use Log::Log4perl qw(:easy);

our $VERSION = "0.09";

###########################################
sub new {
###########################################
  my($class, %options) = @_;

  my $self = {
    irc_server       => "irc.freenode.net",
    irc_channel      => "#wootoff" . sprintf("%04d", int(rand(1000))),
    irc_nick         => "wootbot",
    http_alias       => "wootoff-ua",
    http_timeout     => 60,
    http_max_retries => 30,
    poll_interval    => 30,
    Alias            => "wootoff-bot",
    spawn            => 1,
    last_msg         => undef,
    %options,
  };

  bless $self, $class;

  $self->{http_agent} = $self->agent() unless defined $self->{http_agent};
  $self->{http_url}   = $self->woot_url() unless defined $self->{http_url};

  # Start it up automatically.
  $self->spawn() if $self->{spawn};

  return $self;
}

###########################################
sub woot_url {
###########################################
    my($self) = @_;

    return "http://www.woot.com";
}

###########################################
sub agent {
###########################################
    my($self) = @_;

    return(__PACKAGE__ . "/" . $VERSION),
}

###########################################
sub spawn {
###########################################
  my($self) = @_;

  $self->{bot} = Bot::WootOff::Glue->new(
    server   => $self->{irc_server},
    channels => [ $self->{irc_channel} ],
    nick     => $self->{irc_nick},
  );

  POE::Component::Client::HTTP->spawn(
    Agent     => $self->{http_agent},
    Alias     => $self->{http_alias},
    Timeout   => $self->{http_timeout},
  );

  my $request = GET( $self->{http_url} );

  our $last_item = "";

  POE::Session->create(
    inline_states => {

      _start => sub {
        # wait at startup for things to settle down
        $poe_kernel->delay('http_start', 10);
      },

      http_start => sub {
        DEBUG "Requesting $self->{http_url}";
        POE::Kernel->post( $self->{http_alias}, 
          'request', 'http_ready', $request);
      },

      http_ready => sub {
        my $retries = 0;

        my $resp= $_[ARG1]->[0];
        if($resp->is_success()) {
          my $text = $resp->content();

          my($item, $price) = $self->html_scrape($text);

          if(! defined $item) {
              my $save_file = "/tmp/woot.html";

              if(open FILE, ">$save_file") {
                  print FILE $text;
                  close FILE;
              } else {
                 LOGWARN "Can't open $save_file ($!)";
              }

              if($self->{http_retries_performed} == 
                 $self->{http_max_retries}) {
                  LOGDIE "Ouch, woot.com changed their HTML, and our ",
                         "scraper failed (saved in $save_file). " ,
                         "Let the module author know!";
              } else {
                  ERROR "Scraper failed to parse HTML, but ",
                        "retrying (", 
                        $self->{http_retries_performed} + 1,
                        "/",
                        $self->{http_max_retries},
                        ")";
                  $self->{http_retries_performed}++;
              }
          }

          $self->{http_retries_performed} = 0;

          if($last_item ne $item) {
              $last_item = $item;
              my $body = "$item $price $self->{http_url}";
              $self->{bot}->say(channel => $self->{irc_channel}, 
                                body    => $body);
              $self->{bot}->{last_msg} = $body;
              INFO "$item \$$price posted to $self->{irc_channel}";
          } else {
              DEBUG "Nothing changed";
          }

        } else {
          if(defined $resp->code()) {
              ERROR "HTTP fetch failed with code: ", $resp->code(),
               " ",
               (defined $resp->message() ? $resp->message() : "");
          }
        }
        $poe_kernel->delay("http_start", $self->{poll_interval} );
      },
    }
  );
}

###########################################
sub scraper_test {
###########################################
    my($self) = @_;

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new();
    $ua->agent( $self->agent() );
    $self->error("");

    my $response = $ua->get( $self->woot_url() );

    if( $response->is_success() ) {
        my $bot = Bot::WootOff->new(spawn => 0);

        my($item, $price) = $bot->html_scrape( $response->content() );
        if(!defined $price) {
            $self->error("Scraper failed -- please notify the author");
            # use Sysadm::Install qw( :all );
            # blurt $response->content(), "test.html";
            return undef;
        } else {
            INFO "Scraper successfully got item and price";
            INFO "Item: [$item] Price: [$price]";
            return($item, $price);
        }
    }

    $self->error("Fetching woot.com page failed: ", $response->message());
    return undef;
}

###########################################
sub error {
###########################################
    my($self, @text) = @_;

    if(scalar @text) {
        $self->{error} = join ' ', @text;
        if(length $self->{error}) {
            ERROR $self->{error};
        }
    }

    return $self->{error};
}

###########################################
sub html_scrape {
###########################################
    my($self, $html) = @_;

      # Finds the item and its price in the woot.com HTML page
    my($item, $price);

    if($html =~ m#class="fn">(.*?)</.*?class="amount">(.*?)</#s) {
        ($item, $price) = ($1, $2);
    } elsif($html =~ m#class="fn">(.*?)</.*?class="price">\$(.*?)</#s) {
        ($item, $price) = ($1, $2);
    } elsif( $html =~ m#<h2>(.*?)</h2>\s+<h3>\$(.*?)</h3>#s) {
          # fall back on legacy format
        ($item, $price) = ($1, $2);
    } elsif($html =~ m#class="title">(.*?)</#) {
          # min/max price ranges
        $item = $1;
        my @prices = ();

        while( $html =~ m#class="price.*?">\$(.*?)</#g) {
            push @prices, $1;
        }

        $price = join " - ", @prices;
    }

    if(defined $item) {
        $item =~ s/\s+/ /g;
        return ($item, $price);
    }

    WARN "Cannot parse woot HTML";
    return undef;
}

###########################################
sub run {
###########################################
    my($self) = @_;

    $self->{bot}->run();
}

###########################################
sub response_handler {
###########################################
  my ($request_packet, $response_packet) = @_[ARG0(), ARG1()];

  my $response_object = $response_packet->[0];

  print $response_object->content();
}

###########################################
###########################################
package Bot::WootOff::Glue;
###########################################
###########################################
use strict;
use warnings;
use Bot::BasicBot;
use base qw( Bot::BasicBot );
use Log::Log4perl qw(:easy);

###########################################
sub said {
###########################################
    my($self, $msg) = @_;

      # If someone says "!woot", repeat the last message
    if($msg->{body} =~ /^!woot/) {
        return $self->{last_msg} if defined $self->{last_msg};
    }

      # remain mum otherwise
    return "";
}

1;

__END__

=head1 NAME

Bot::WootOff - Poll woot.com during a woot-off and notify via IRC

=head1 SYNOPSIS

    use Bot::WootOff;

    my $bot = Bot::WootOff->new(
        server  => "irc.freenode.net",
        channel => "#wootoff",
    );

    $bot->run();

=head1 DESCRIPTION

Bot::WootOff periodically polls woot.com during a woot-off and sends 
messages to in IRC channel to alert the user of new items.

What, you don't know what woot.com is? It's a site that sells one item
a day at a discounted price. Once the item is sold out, the site runs idle
for the rest of the day. But every once in a while, it switches into
a mode called woot-off, where it keeps popping up new items as soon as
the lot of the previous item is sold. This is called a "Woot Off",
and it's something many people are looking forward to, as all items,
and most of all, the legendary "Bag of Crap", can be had a bargain price.
If you think all of this is silly, move on to the next CPAN module! Nice
meeting you! If you're a bargain hunter, continue reading.

If you notice that there's a woot-off going on on woot.com, simply start
your bot via the 'wootbot' script included in this module, like

    wootbot -s irc.freenote.net -c '#wootoff'

or use the perl code in the SYNOPSIS section of this document. The
bot will start up, connect to the IRC server, and log into the channel
specified. It'll start polling woot.com in 30-second intervals until the 
next item in the woot-off will be presented. At this point, it will post
a short item description to the IRC channel to alert the user of the
buying opportunity:

    Trying to connect to server irc.freenode.net
    Trying to connect to '#wootoff0538'
    2009/05/13 23:17:36 Requesting http://www.woot.com
    2009/05/13 23:17:36 Apple 8GB 4th Gen iPod Nano posted to #wootoff0538

The above output can be seen if you start C<wootbot> in verbose mode, using
the C<-v> option. It also prints status messages like

    2009/05/13 23:36:23 Requesting http://www.woot.com
    2009/05/13 23:36:24 Nothing changed
    2009/05/13 23:36:54 Requesting http://www.woot.com
    2009/05/13 23:36:54 Nothing changed

to STDOUT in regular intervals to let the user know what it's doing. When
it posts messages to the IRC channel specified, it will use the nickname
"wootbot" (unless you specify another nickname in the constructor). The 
messages will look like 

    (11:41:29 PM) wootbot: Forever Flashlight  III 4.99 http://www.woot.com
    (11:44:32 PM) wootbot: Deluxe Charades Game 2.99 http://www.woot.com

Each message contains a link to woot.com, which will be displayed by IRC
clients like Pidgin in a clickable format, so that you can reach the 
current offer with a single mouse click.

If someone in the channel says "!woot" then the bot will repeat its last
message. This is helpful if someone just joined the channel and wants
to know what the current item is.

All you have to do to receive these message is use an IRC client like 
Pidgin, connect to the IRC server specified (irc.freenode.net by default),
log into the channel specified (#wootoffxxxx by default, where xxxx is 
a random number so that all of you script kiddies using this module won't
step on other people's toes. Use a specific name like #wootoff to connect to
the actual channel specified), and enjoy the incoming messages. Set up
sounds and you'll be able to do useful work while being interrupted with
the latest bargains.

Extra tip: If your IRC window in Pidgin gets full and you want the visual 
interruption of an empty window being filled, use CTRL-L to clear the
current window.

=head2 Methods

=over 4

=item new()

The constructor takes the following arguments:

    my $bot = Bot::WootOff->new(
      irc_server       => "irc.freenode.net",
      irc_channel      => "#wootoff",
      irc_nick         => "wootbot",
      http_agent       => (__PACKAGE__ . "/" . $VERSION),
      http_alias       => "wootoff-ua",
      http_timeout     => 60,
      http_url         => "http://www.woot.com",
      http_max_retries => 30,
      poll_interval    => 30,
      Alias            => "wootoff-bot",
      spawn            => 1,
    );

Some of these parameters are specific to POE, the framework driving the
bot.

=item run()

This methods starts the bot, which usually runs until the program is
terminated.

=back

=head1 EXAMPLES

  $ wootbot -s irc.freenode.net -c '#wootoff'

=head1 LEGALESE

Copyright 2009-2012 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2009, Mike Schilli <cpan@perlmeister.com>
