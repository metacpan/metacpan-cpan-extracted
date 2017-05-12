package Chess::Games::DotCom;

use 5.006001;
use strict;
use warnings;

use Data::Dumper;
use HTML::Entities;
use HTML::TreeBuilder;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Chess::Games::DotCom ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	game_of_day puzzle_of_day
);

our $VERSION = '1.2';

our $home = 'http://www.chessgames.com';
my  $tb   = HTML::TreeBuilder->new;

# Preloaded methods go here.

my $ua;

sub _init_ua
{
    require LWP;
    require LWP::UserAgent;
    require HTTP::Status;
    require HTTP::Date;
    $ua = new LWP::UserAgent;  # we create a global UserAgent object
    my $ver = $LWP::VERSION = $LWP::VERSION;  # avoid warning
    $ua->agent("Mozilla/5.001 (windows; U; NT4.0; en-us) Gecko/25250101");
    $ua->env_proxy;
}

  
sub _get
{
    my $url = shift;
    my $ret;

    _init_ua() unless $ua;
    if (@_ && $url !~ /^\w+:/) 
      {
	  # non-absolute redirect from &_trivial_http_get
	  my($host, $port, $path) = @_;
	  require URI;
	  $url = URI->new_abs($url, "http://$host:$port$path");
      }
    my $request = HTTP::Request->new
      (GET => $url,
       
      );
    my $response = $ua->request($request);
    return $response->is_success ? $response->content : undef;
}

sub pgn_url {

  my $gid = shift;

  "http://www.chessgames.com/perl/nph-chesspgndownload?gid=$gid"
}

sub game_of_day {

    my $outfile = shift || "game_of_day.pgn";

    # retrieve http://www.chessgames.com

    my $html = get $home;

    # parse the page

    $tb->parse($html);

    my $god; # god == Game of the Day

    # make it so that text nodes are changed into nodes with tags
    # just like any other HTML aspect.
    # then they can be searched with look_down
    $tb->objectify_text;

    # Find the place in the HTML where Game of the Day is
    my $G = $tb->look_down
      (
       '_tag' => '~text',
       text   => 'Game of the Day'
      );

    my $table = $G->look_up
      (
       '_tag' => 'table',
      );

    my @tr = $table->look_down('_tag' => 'tr');

    my $god_tr = $tr[1];

    my $a = $god_tr->look_down('_tag' => 'a');

    # lets get the URL of the game
    my $game_url  = $a->attr('href');
    my ($game_id) = $game_url =~ m/(\d+)/;

    # let's get the game, faking out the web spider filter in the process:
    my $pgn       = _get pgn_url $game_id;

    # let's save it to disk
    open F, ">$outfile" or die "error opening $outfile for writing: $!";
    print F $pgn;
    close(F)
}

sub puzzle_of_day {

    my $outfile = shift || "puzzle_of_day.pgn";

#    warn $outfile;


    # retrieve http://www.chessgames.com

    my $html = get $home;

    # parse the page

    $tb->parse($html);

    my $pod; # god == Game of the Day

    # make it so that text nodes are changed into nodes with tags
    # just like any other HTML aspect.
    # then they can be searched with look_down
    $tb->objectify_text;

    # Find the place in the HTML where Game of the Day is
    my $G = $tb->look_down
      (
       '_tag' => '~text',
       text   => 'See game for solution.'
      );

#    warn $G->as_HTML;

    # find _all_ tr in the lineage of the found node... I don't know a 
    # way to limit the search
    my $table = $G->look_up
      (
       '_tag' => 'table',
      );


    my $winner = $table->look_down
      (
       '_tag' => '~text',
       'text' => qr/^\d+/
      );
       

    my $winner_content = $winner->attr('text');

    decode_entities($winner_content);

#    die $winner_content;

    my $A = $table->look_down
      (
       '_tag' => 'a',
      );


#    $A->dump;

    my $game_url = $A->attr('href');

    my ($game_id) = $game_url =~ m/(\d+)/;
  

    # let's get the game, faking out the web spider filter in the process:
    my $pgn       = _get pgn_url $game_id;

    $pgn =~ s!PlyCount.+\]!PlyCount \"$winner_content\"\]!;

#    die $pgn;

   # let's save it to disk
    open F, ">$outfile" or die "error opening $outfile for writing: $!";
    print F $pgn;
    close(F)
    
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Chess::Games::DotCom - API for accessing chessgames.com

=head1 SYNOPSIS

  shell> perl -MChess::Games::DotCom -e  game_of_day
  shell> perl -MChess::Games::DotCom -e 'game_of_day("myfile.pgn")'

  shell> perl -MChess::Games::DotCom -e  puzzle_of_day
  shell> perl -MChess::Games::DotCom -e 'puzzle_of_day("myfile.pgn")'

=head1 ABSTRACT

Download games from chessgames.com.

A script in scripts suitable for invocation from cron is included.

=head1 API

=head2 game_of_day [ $filename ]

Downloads the game of the day. If C<$filename> is not specified, then
it downloads it to C<game_of_day.pgn>.

=head2 puzzle_of_day [ $filename ]

Downloads the puzzle of the day. If C<$filename> is not specified, then
it downloads it to C<puzzle_of_day.pgn>.

=head2 EXPORT

C<game_of_day>
C<puzzle_of_day>

=head1 NEW FEATURES

=head2 in 0.09

Realized that I parsed out the wrong thing and parsed out something like:

   12. ...?

instead.

Stored this in plycount instead.

=head2 in 0.08

For C<puzzle_of_day()>,
parsed out "$color to move and win" and stored in the PlyCount header of
PGN so that I could see where the puzzle began.

Too see an example of a log of auto-downloaded games, visit:

http://princepawn.perlmonk.org/chess/pgn/montreux.html

=head2 in 0.07

Added a sample cron file for daily automatic retrieval of puzzle of day.

Added Log::Agent logging to sample retrieval script

=head2 in 0.06

C<puzzle_of_day> was added


=head1 TODO

Download other daily game parts of the site

=head1 RESOURCES

The Perl Chess Mailing List:

  http://www.yahoogroups.com/group/perl-chess

=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>


=head1 INSTALLATION

You must have the following installed:

=over 4

=item 1 URI

=item 2 Bundle::LWP

=item 3 HTML::Tree

=back

=head2 Optional

For the script in the C<scripts> directory, you also need:

=over 4

=item 4 File::Butler

=item 5 File::Temp

=item 6 Log::Agent

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by T. M. Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
