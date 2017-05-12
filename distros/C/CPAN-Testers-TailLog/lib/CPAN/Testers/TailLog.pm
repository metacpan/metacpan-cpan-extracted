use 5.006;    # our
use strict;
use warnings;

package CPAN::Testers::TailLog;

our $VERSION  = '0.001001';
our $DISTNAME = 'CPAN-Testers-TailLog';

# ABSTRACT: Extract recent test statuses from metabase log

# AUTHORITY

sub new {
    my $buildargs = { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] };
    my $class = ref $_[0] ? ref $_[0] : $_[0];
    my $self = bless $buildargs, $class;
    $self->_check_cache_file if exists $self->{cache_file};
    $self->_check_url        if exists $self->{url};
    $self;
}

sub cache_file {
    $_[0]->{cache_file} = $_[0]->_build_cache_file
      unless exists $_[0]->{cache_file};
    $_[0]->{cache_file};
}

sub get_all {

    # If this fails, we just parse what we parsed last time
    # Actually, not sure if mirror is atomic or not.
    # Mirror is used here also to get automatic if-modified behaviour
    $_[0]->_ua->mirror( $_[0]->url, $_[0]->cache_file );

    # So if the connection goes away and HTTP::Tiny fubars,
    # we just pretend things are fine for now.
    # mostly, because deciding how to handle error cases hurt
    # my tiny brain

    require Path::Tiny;
    my (@lines) =
      Path::Tiny::path( $_[0]->cache_file )->lines_utf8( { chomp => 1 } );

    # Skip prelude
    shift @lines while @lines and $lines[0] !~ /\A\s*\[/;
    [ map { $_[0]->_parse_line($_) } @lines ];
}

sub get_iter {
    my $self    = $_[0];
    my $fetched = 0;
    my $handle;
    my $done;
    return sub {
        return undef if $done;
        $fetched ||= do {
            $self->_ua->mirror( $self->url, $self->cache_file );
            1;
        };
        defined $handle or $handle = do {
            require Path::Tiny;
            $handle = Path::Tiny::path( $self->cache_file )->openr_utf8;
        };
        while ( my $line = <$handle> ) {
            next if $line !~ /\A\s*\[/;
            chomp $line;
            return $self->_parse_line($line);
        }
        $done = 1;
        return undef;
    };
}

sub url {
    $_[0]->{url} = $_[0]->_build_url unless exists $_[0]->{url};
    $_[0]->{url};
}

# -- private ] --

sub _parse_line {
    my %record;
    @record{
        qw( submitted reporter grade filename platform perl_version uuid accepted )
      } = (
        $_[1] =~ qr{
      \A
      \s*
      \[ (.*? ) \] # submitted
      \s*
      \[ (.*? ) \] # reported
      \s*
      \[ (.*? ) \] # grade
      \s*
      \[ (.*?) \] # filename
      \s*
      \[ (.*?) \] # platform
      \s*
      \[ (.*?) \] # perl_version
      \s*
      \[ (.*?) \] # uuid
      \s*
      \[ (.*?) \] # accepted
    }x
      );
    require CPAN::Testers::TailLog::Result;
    CPAN::Testers::TailLog::Result->new( \%record );
}

sub _ua {
    $_[0]->{_ua} = $_[0]->_build_ua unless exists $_[0]->{_ua};
    $_[0]->{_ua};
}

# -- builders ] --
sub _build_cache_file {
    require File::Temp;
    my $temp = File::Temp->new(
        TEMPLATE => $DISTNAME . '-XXXXX',
        TMPDIR   => 1,
        SUFFIX   => '.txt',
        EXLOCK   => 0,
    );
    $_[0]->{_tempfile} = $temp;
    require Path::Tiny;

    # Touching tempfiles required to get useful if-modified behaviour
    Path::Tiny::path( $temp->filename )->touch( time - ( 7 * 24 * 60 * 60 ) );
    $temp->filename;
}

sub _build_ua {
    require HTTP::Tiny;
    HTTP::Tiny->new( agent => ( $DISTNAME . '/' . $VERSION ), );
}

sub _build_url {
    'http://metabase.cpantesters.org/tail/log.txt';
}

# -- checkers ] --
sub _check_cache_file {
    require Path::Tiny;
    my $path = Path::Tiny::path( $_[0]->{cache_file} );
    my $dir  = $path->parent;
    die "cache_file: Directory for $path not accessible: $?"
      unless -e $dir
      and -d $dir
      and -r $dir;
    if ( not -e $path ) {

        # Path doesn't exist, test creating it
        # Hope touch dies if it can't be written
        $path->touch( time - ( 7 * 24 * 60 * 60 ) );
    }
    return if -e $path and not -d $path and -w $path;
    die "cache_file: $path exists but is unwriteable";
}

sub _check_url {
    die "url: Missing protocol in $_[0]->{url}" if $_[0]->{url} !~ qr{://};
    die "url: Unknown protocol in $_[0]->{url}"
      if $_[0]->{url} !~ qr{\Ahttps?://};
}

1;

=head1 NAME

CPAN-Testers-TailLog - Extract recent test statuses from metabase log

=head1 SYNOPSIS

  use CPAN::Testers::TailLog;

  my $tailer = CPAN::Testers::TailLog->new();
  my $results = $tailer->get_all();
  for my $item ( @{ $results } ) {
    printf "%s: %s\n", $item->grade, $item->filename;
  }

=head1 DESCRIPTION

B<CPAN::Testers::TailLog> is a simple interface to the C<Metabase> C<tail.log>
located at C<http://metabase.cpantesters.org/tail/log.txt>

This module simply wraps the required HTTP Request mechanics, some persistent
caching glue for performance, and a trivial parsing layer to provide an object
oriented view of the log.

=head1 METHODS

=head2 new

Creates an object for fetching results.

  my $tailer = CPAN::Testers::TailLog->new(
    %options
  );

=head3 new:cache_file

  ->new( cache_file => "/path/to/file" )

If not specified, defaults to a C<File::Temp> file.

This is good enough for in-memory persistence, so for code that is long lived
setting this is not really necessary.

However, if you want a regularly exiting process, like a cron job, you'll
probably want to set this to a writeable path.

This will ensure you save redundant bandwidth if you sync too quickly, as the
C<mtime> will be used for C<If-Modified-Since>.

Your C<get_all> calls will still look the same, but they'll be a little faster,
you'll eat a little less bandwidth, and stress the remote server a little less.

=head3 new:url

  ->new( url => "http://path/to/tail.log" )

If not specified, uses the default URL,

  http://metabase.cpantesters.org/tail/log.txt

Its not likely you'll have a use for this, but it may turn out useful for
debugging, or maybe somebody out there as an equivalent private server with
this log.

=head2 cache_file

Accessor for configured cache file path

  my $path = $tailer->cache_file

=head2 get_all

Fetches the most recent data possible as an C<ArrayRef> of
L<CPAN::Testers::TailLog::Result>

  my $arrayref = $tailer->get_all();

Note that an arrayref will be returned regardless of what happens. It helps to
assume the result is just a dumb transfer.

Though keep in mind non-C<ArrayRef>s may be returned in error conditions
(Undecided).

Calling this multiple times will be efficient using C<If-Modified-Since>
headers where applicable.

Though even if nothing has changed, you'll get a full copy of the last state.

If you want an "only what's changed since last time we checked, see F<examples>

=head2 get_iter

Returns a lazy C<CodeRef> that returns one L<CPAN::Testers::TailLog::Result> at
a time.

  my $iter = $tailer->get_iter();
  while ( my $item = $iter->() ) {
      printf "%s %s\n", $item->grade, $item->filename;
  }

As with C<get_all>, present design is mostly "dumb state transfer", so all this
really serves is a possible programming convenience. However, optimisations may
be applied here in future so that C<< $iter->() >> pulls items off the wire as
they arrive, saving you some traffic if you terminate early.

Presently, an early termination only saves you a little disk IO, extra regex
parses and shaves a few object creations.

=head2 url

Accessor for configured log URL.

  my $url = $tailer->url;

=head1 SEE ALSO

=over 4

=item * L<P5U::Command::cttail>

Some of the logic of this module shares similarity with the contents of that
module, however, that module is designed as a standalone application that
simply shows the current status with some filtration options.

It is not however designed for re-use.

My objective is different, and I want to write a daemon that periodically polls
for new records, and creates a local database ( Similar to what likely happens
inside C<fast-matrix.cpantesters.org> ) of reports for quick searching, and I
figure this sort of logic can also be useful for somebody who wants a
C<desktop-notification-on-failure> monitor.

Some of the logic was cribbed from this and reduced to be closer to verbatim.

=item * L<fast-matrix tail-log-to-json|https://github.com/eserte/cpan-testers-matrix/blob/master/bin/tail-log-to-json.pl>

C<CPAN::Testers::TailLog> contains similar logic to this script as well, again,
prioritizing for simplicity and re-use.

Any specific mangling with C<distinfo> is left to the consumer.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

