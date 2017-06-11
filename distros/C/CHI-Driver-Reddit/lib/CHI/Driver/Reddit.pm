package CHI::Driver::Reddit;
use Moo;
extends 'CHI::Driver';

our $VERSION = 0.02;

sub BUILD {
  my ($self, $args) = @_;

  die 'requires username, password and subreddit arguments'
   unless 3 == grep { $_ } map { $args->{$_} } qw/username password subreddit/;

  $ENV{reddit_username}  = $args->{username};
  $ENV{reddit_password}  = $args->{password};
  $ENV{reddit_subreddit} = $args->{subreddit};

  require Cache::Reddit;
}

sub store { Cache::Reddit::set($_[1]) }

sub fetch { Cache::Reddit::get($_[1]) }

sub clear { Cache::Reddit::remove($_[1]) }

1;
=encoding utf8

=head1 NAME

CHI::Driver::Reddit - use Reddit as a cache!

=head1 SYNOPSIS

    use CHI;
    my $cache = CHI->new(
      subreddit => 'somesubreddit', # the subreddit to post to
      username  => 'foo',           # reddit username
      password  => 'barbarbar',     # reddit password
      driver    => 'Reddit',
    );
    ...

=head1 DESCRIPTION

See L<Cache::Reddit> and L<CHI> for details.

=head1 AUTHOR

David Farrell

=head1 LICENSE

Two Clause FreeBSD, see LICENSE

E<copy> 2017, David Farrell

=cut
