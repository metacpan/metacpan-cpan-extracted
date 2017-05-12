#!/usr/bin/perl -Tw

=head1 NAME

movie.pl - A sample script to link actors through movies

=head1 DESCRIPTION

This sample script takes a database full of actors and movies,
and creates the necessary framework for C<Algorithm::SixDegrees>
to link the actors through the movies.

The data source (and thus the script) expects the last name first.
In other words, you can play "Six Degrees of Bacon, Kevin" with this.

=head1 FINDING ACTORS

If an actor is not found, the script searches the data source, using
the input as the starting string.  If it finds only one match, it
uses that instead.  For example, in my data source, Johnny Carson
is actually represented as 'Carson, Johnny (I)'.  But since he's the
only one (there's no 'Carson, Johnny (II)'), the script will use that
instead.  On the other hand, 'Smith, Will' gives the following note:

  No match for 'Smith, Will'.  Did you mean:
        'Smith, Will (I)' (career: 1992-2005)
        'Smith, Willetta' (career: 1953-1954)
        'Smith, William 'Smitty'' (career: 1990)
	... (omittance for brevity) ...
        'Smith, Willis S.' (career: 1920)

Also, the script is not smart enough to figure out similar people.
That is, in my data source, Charlie Chaplin is actually listed as
'Chaplin, Charles'; this sample will not know the two are the same.

=cut

use warnings;
use strict;
use vars qw/$dbh $actorsth $moviesth $dbhit $th/;
use Algorithm::SixDegrees;

eval "use DBI"; die "Can't run sample: DBI not installed:\n$@" if $@;
eval "use Time::HiRes"; $th = $@ ? 0 : 1;

print 'Enter a source actor (L,F): ';
my $actor1 = <STDIN>;
$actor1 =~ s/^\s*(.*?)\s*$/$1/ || die 'regex did not match';
print 'Enter a destination actor: ';
my $actor2 = <STDIN>;
$actor2 =~ s/^\s*(.*?)\s*$/$1/ || die 'regex did not match';

die 'Need two actors' unless $actor1 && $actor2;

&db_connect;

$actor1 = &suggest_actor($actor1);
$actor2 = &suggest_actor($actor2);

$dbhit = 0;
my $sd = Algorithm::SixDegrees->new;
$sd->data_source( movies => \&movie_actors );
$sd->data_source( actors => \&actor_movies );
$dbhit = 0; # reset the database hit counter, used in the two subs
my $start = &time;
my @chain = $sd->make_link('actors',$actor1,$actor2);
my $end = &time;

if(scalar(@chain)) {
	print join (' -> ',@chain), "\n";
} else {
	my $err = $Algorithm::SixDegrees::ERROR;
	print $err ? "Error: $err\n" : "No chain found.\n";
}

my $format = $th ? '%0.2f' : '%0d';

printf "%5d database hits in $format second%s\n",$dbhit,($end-$start),(sprintf($format,$end-$start)==1?'':'s');
exit(0);

# returns either int or floating time depending on if Time::HiRes is installed
sub time {
	return $th ? Time::HiRes::time() : time;
}

# Connects to the db and prepares the SQL for quick execution
sub db_connect {
	$dbh = DBI->connect('DBI:mysql:database=movact','movact','movact');
	$actorsth = $dbh->prepare('SELECT movie FROM movact WHERE actor = ?');
	$moviesth = $dbh->prepare('SELECT actor FROM movact WHERE movie = ?');
}

# Returns the actors in a given movie.
sub movie_actors {
	$dbhit++;
	$moviesth->execute($_[0]) or die 'Problem: ' . $moviesth->errstr . "\n";
	my $results = $moviesth->fetchall_arrayref;
	return map { $_->[0] } @{$results};
}

# Returns the movies a given actor has starred in.
sub actor_movies {
	$dbhit++;
	$actorsth->execute($_[0]) or die 'Problem: ' . $actorsth->errstr . "\n";
	my $results = $actorsth->fetchall_arrayref;
	return map { $_->[0] } @{$results};
}

# Tries looking for an actor if they're not in the database as given
sub suggest_actor {
	my $actor = shift;
	return $actor if (scalar(&actor_movies($actor)));
	my $sth = $dbh->prepare('SELECT actor, min(year), max(year) FROM movact WHERE actor LIKE ? GROUP BY actor')
		or die 'sql prepare error';
	$sth->execute("$actor\%") or die 'sql execution error';
	my $results = $sth->fetchall_arrayref;
	$sth->finish;
	if (scalar(@{$results}) < 1) {
		print "No suggestions for '$actor'\n";
		exit(0);
	} elsif (scalar(@{$results}) == 1) {
		my $new = $results->[0][0];
		print "Using '$new' instead of '$actor'\n";
		return $new;
	} 

	print "No match for '$actor'.  Did you mean:\n";
	foreach my $result (@{$results}) {
		print "\t'", $result->[0], "' (career: " . $result->[1];
		print '-' . $result->[2] if ($result->[1] != $result->[2]);
		print ")\n";
	};
	exit(0);
}

=head1 MAKING A DATA SOURCE

A sample data source is at L<ftp://ftp.funet.fi/pub/mirrors/ftp.imdb.com/pub/>
I grabbed the F<actors.list.gz> and the F<actresses.list.gz> files from there.

I created a MySQL database table and some indexes:

  create database movact;
  grant all privileges on movact.* to movact identified by 'movact';
  use movact;
  create table movact ( actor varchar(128), movie varchar(128), year int );
  create index movact_actor on movact ( actor );
  create index movact_movie on movact ( movie );

(You may want to make the indexes after the data load instead of before.)

I then trimmed the data source down to remove the header and footer,
followed by this Perl script on both data files to load them into the database:

  #!/usr/bin/perl

  use DBI;

  my $dbh = DBI->connect('DBI:mysql:database=movact','movact','movact',{AutoCommit=>1});
  my $sth = $dbh->prepare('INSERT INTO movact (movie, actor, year) VALUES (?,?,?)');
  die unless $sth;

  while (<>) {
      chomp;
      my ($a, $t) = split(/\t+/,$_,2);
      $actor = $a if ($a !~ /^\s*$/ && $a ne $actor);
      next unless $t;
      next if $t =~ /\((TV|V|VG)\)/; # No TV movies / video-only movies / video games
      next if $t =~ /^"/; # No TV series
      $t =~ s/(\(((?:18|19|20)\d\d|\?\?\?\?)(?:\/(\w+))?\)).*/$1/;
      $y = $2 || 1000; # Sets the year to 1000 if it's not present
      $y = 1000 if $y !~ /^\d+$/; # Turns year ???? into year 1000
      die $sth->errstr unless $sth->execute($t,$actor,$y);
  }

  $sth->finish;
  $dbh->disconnect;
  exit(0);

The database is thus prepared.

=cut

