package Bot::BasicBot::Pluggable::Module::SimpleBlog;

use strict;
use vars qw( $VERSION );
$VERSION = '0.02';

use base qw(Bot::BasicBot::Pluggable::Module::Base);

use Carp;
use Regexp::Common 'RE_URI';
use Time::Piece;

=head1 NAME

Bot::BasicBot::Pluggable::Module::SimpleBlog - A simple URL collector for Bot::BasicBot::Pluggable.

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable;
  use Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite;

  my $bot = Bot::BasicBot::Pluggable->new( ... );
  $bot->load( "SimpleBlog" );

  my $blog_handler = $bot->handler( "SimpleBlog" );

  $blog_handler->set_store(
    Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite
       ->new( "/home/bot/brane.db" )
  );

  $blog_handler->set_blogurl( "http://example.com/simpleblog.cgi" );

  $bot->run;

=head1 DESCRIPTION

A plugin module for L<Bot::BasicBot::Pluggable> to grab, store and
output URLs from IRC channels. It is intentionally simplistic - see
L<Bot::BasicBot::Pluggable::Module::Blog> for a more complicated
chump-like thing.

=head1 IMPORTANT NOTE WHEN UPGRADING FROM PRE-0.02 VERSIONS

I'd made a thinko in version 0.01 in one of the column names in the
table used to store the URLs in the database, so you'll have to delete
your store file and start again. It didn't seem worth automatically
detecting and fixing this since I only released 0.01 yesterday and I
don't expect anyone to have installed it yet.

=head1 METHODS

=over 4

=cut

sub help {
    my $self = shift;
    my $helptext = "Simple URL collector for Bot::BasicBot::Pluggable.  Requires direct addressing.  Usage: 'http://foo.com/ # the foo website'.";
    my $blogurl = $self->{blogurl};
    $helptext .= "  The URLs can be viewed at $blogurl" if $blogurl;
    return $helptext;
}

sub said {
    my ($self, $mess, $pri) = @_;
    return unless $mess->{address} and $pri == 2; # require direct addressing
    my $store = $self->{store}
      or return "Error: no store configured.";

    my $body = $mess->{body};
    my $who  = $mess->{who};
    my $channel = $mess->{channel};

    my ($url, $comment) = split(/\s+\#*\s*/, $body, 2);
    $comment ||= "";
    my $url_re = RE_URI;
    unless ( $url =~ /^$url_re$/ ) {
        ($url, $comment) = ("", $body);
    }

    my $now = localtime;
    my $timestamp = $now->strftime("%Y-%m-%d %H:%M:%S");

    $store->store( timestamp => $timestamp,
                   name      => $who,
                   channel   => $channel,
                   url       => $url,
                   comment   => $comment );

    $self->{Bot}->say( who => $who,
                       channel => "msg",
                       body    => "Stored URL '$url'"
                                 . ($comment ? " and comment '$comment'" : "" )
    );
    return; # nice quiet bot
}

=item B<set_store>

  my $blog_store =
    Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite->new(
      "/home/bot/brane.db" );
  $blog_handler->set_store( $blog_store );

Supply a C<Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::*> object.

=cut

sub set_store {
    my ($self, $store) = @_;
    croak "ERROR: No store specified" unless $store;

    $self->{store} = $store;
    return $self;
}

=item B<set_blogurl>

  $blog_handler->set_blogurl( "http://example.com/simpleblog.cgi" );

Supply the URL for your CGI script to view the stored URLs.

=cut

sub set_blogurl {
    my ($self, $blogurl) = @_;
    croak "ERROR: No blogurl specified" unless $blogurl;
    $self->{blogurl} = $blogurl;
    return $self;
}

=head1 EXAMPLES

  use strict;
  use warnings;
  use Bot::BasicBot::Pluggable;

  my $bot = Bot::BasicBot::Pluggable->new(channels => [ "#test" ],
                                          server   => "irc.example.com",
                                          port     => "6667",
                                          nick     => "bot",
                                          username => "bot",
                                          name     => "bot",
                                         );
  $bot->load( "SimpleBlog" );

  my $blog_handler = $bot->handler( "SimpleBlog" );

  $blog_handler->set_store(
    Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite
       ->new( "/home/bot/brane.db" )
  );

  $blog_handler->set_blogurl( "http://example.com/simpleblog.cgi" );

  $bot->run;

Yes, this is your entire program.

The file supplied as an argument to the constructor of
L<Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite> need
not already exist; it will be created and the correct database schema
set up as necessary.

Talk to the bot on IRC for help:

  17:37 <nou> kakebot: help SimpleBlog
  <kakebot> nou: Simple URL collector for Bot::BasicBot::Pluggable.
      Requires direct addressing.  Usage:
      'http://foo.com/ # the foo website'.  The URLs can be viewed at
      http://example.com/simpleblog.cgi

Get stuff out of the database in your favoured fashion, for example:

  use strict;
  use warnings;
  use CGI;
  use DBI;

  my $sqlite_db = "/home/bot/brane.db";
  my $q = CGI->new;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_db", "", "")
    or die DBI->errstr;

  print $q->header;
  print <<EOF;

  <html>
  <head><title>simpleblogbot</title></head>
  <body><h1 align="center">simpleblogbot</h1>

  EOF

  my $sql = "SELECT timestamp, name, channel, url, comment FROM blogged
             ORDER BY timestamp DESC";
  my $sth = $dbh->prepare($sql) or die $dbh->errstr;
  $sth->execute;
  my ($timestamp, $name, $channel, $url, $comment);

  while ( ($timestamp, $name, $channel, $url, $comment)
                                          = $sth->fetchrow_array ) {
      print "<br><i>$timestamp</i>: <b>$name/$channel</b>: ";
      print "<a href=\"$url\">$url</a> " if $url;
      print $q->escapeHTML($comment) if $comment;
  }

  print "</body></html>\n";

(This will just print everything ever; being more discriminating and
adding prettiness is left as an exercise for people who don't hate
writing CGI scripts.)

At some point there will be
C<Bot::BasicBot::Pluggable::Module::Store::*> methods for retrieving
as well as storing the data. Probably.

=head1 WARNING

Unstable API - L<Bot::BasicBot::Pluggable> is liable to change and
hence so is this.

=head1 BUGS

More tests would be nice.

=head1 SEE ALSO

=over 4

=item * L<Bot::BasicBot::Pluggable>

=item * L<Bot::BasicBot::Pluggable::Module::Blog>

=item * L<Bot::BasicBot::Pluggable::Module::SimpleBlog::Store::SQLite>

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Tom Insam, author of L<Bot::BasicBot::Pluggable>, answered my dumb
questions on how to get it working. Mark Fowler fixed my bad SQL, and
told me off until I agreed to abstract out the storage and retrieval bits.

=cut

1;
