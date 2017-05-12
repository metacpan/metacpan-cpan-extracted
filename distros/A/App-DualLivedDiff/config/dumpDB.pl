#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use DBM::Deep;
use File::Path ();
use File::Spec;
use Digest::MD5 'md5_base64';

sub usage {
  warn "$_[0]\n" if defined $_[0];
  warn <<HERE;
Usage: $0 [--verbose] DBFILE
Usage: $0 DBFILE DistOrModuleRegex
Usage: $0 --html DBFILE
HERE
  exit(1);
}

my ($verbose, $toHTML);
GetOptions(
  'h|help' => \&usage,
  'v|verbose' => \$verbose,
  'h|html' => \$toHTML,
);

my $datafile = shift @ARGV;
usage("File does not exist") if not defined $datafile or not -f $datafile;
my $regex = shift @ARGV;
$regex = qr/$regex/ if defined $regex;

my $db = DBM::Deep->new($datafile);
if ($toHTML) {
  to_html($db);
}
elsif (defined $regex) {
  my %dists = 
    map {($_ => 1)}
    grep { /$regex/ }
    (keys %$db);
    #(keys %$db, (map {$_->{module}} values %$db));

  die "Multiple results selected: \n" . join("\n", keys %dists) . "\n"
    if keys(%dists) > 1;
  die "No results selected\n" if not keys %dists;

  my @dists = keys %dists;
  my $dist = $db->{$dists[0]};
  print $dist->{diff};
}
elsif ($verbose) {
  print Dumper $db;
}
else {
  foreach my $k (keys %$db) {
    my $s = $db->{$k}{status};
    print "$k - $s\n";
  }
}

sub to_html {
  my $db = shift;

  my $dir = 'dld-html';
  die "Directory '$dir' exists!" if -d $dir;

  File::Path::mkpath("dld-html");

  open my $ifh, '>', File::Spec->catdir($dir, "index.html") or die $!;
  print $ifh <<'HERE';
<html>
<head><title>dualLivedDiff</title></head>
<body>
<p>
This list of differences corresponds to a subset of the distributions (modules)
that are both in core and on CPAN as separate distributions. If you maintain one of these so-called
<i>dual-lived</i> modules, feel free to contact Steffen Mueller at his CPAN.org mail address to get your module
included in the list. It would help if you include a YAML file mapping file such
as those accessible below under the <i>cfg</i> links.
</p>
<p>
Data generated with <a href="http://search.cpan.org/dist/App-DualLivedDiff">App::DualLivedDiff</a>. It is not
currently updated automatically. If you want to help and have a server with access to git and the ability to add a cron job, feel
free to get in touch.
</p>
<p>
Additional notes:
</p>
<ul>
<li>
Please note that developer releases are not picked up from CPAN.
</li>
<li>
The paths given are the paths in core perl (blead).
</li>
<li>
The diffs are from CPAN to core perl.
</li>
<li>
The additional diff options used are -N and -w (include new files in diff, ignore whitespace).
</li>
</ul>
<hr/>
<table cellspacing="2" cellpadding="3" border="0">
<tr>
<th>CPAN Author</th><th>Distname</th><th>Status</th><th>Diff</th><th>Length</th><th>Date of Diff</th><th>File Mapping</th>
</tr>
HERE

  foreach my $distname (
        map {$_->[0]}
        sort {$a->[1] cmp $b->[1]}
        map {my $n = $_; s/^[^\/]*\///;[$n, $_]}
        keys %$db
  ) {
    my $dist = $db->{$distname};
    my $status = $dist->{status};
    my $diff = $dist->{diff};
    my $date = localtime($dist->{date});

    my $diffLink = '-';
    my $bgcolor = '#66FF66';
    my $filename = md5_base64($distname) . ".txt";
    $filename =~ s/[\/:]//g;
    if ($status !~ /^ok/i) {
      open my $fh, '>', File::Spec->catfile($dir, $filename) or die $!;
      print $fh $diff;
      close $fh;
      $bgcolor = '#FF6666';
      $diffLink = "<a href=\"$filename\">Diff</a>";
    }

    my $configFilename = "config-$filename";
    $configFilename =~ s/\.[^.]*$/\.cfg/;
    my $configLink = "<a href=\"$configFilename\">cfg</a>";
    open my $cfh, '>', File::Spec->catfile($dir, $configFilename) or die $!;
    print $cfh $dist->{config};
    close $cfh;

    # highlight the actual dist name
    my $html_distname = $distname;
    $html_distname =~ s{
      ^([^\/]+)
      \/  (.*)
      (
        -[\d_\.]+
        \. (?:zip | tar\.(?:gz|bz2))
      )$
    }{<b>$2<\/b>$3}x;
    my $author = $1;

    my $diffLen = defined($diff) ? length($diff) : 0;
    print $ifh <<HERE;
<tr bgcolor="$bgcolor">
<td>$author</td>
<td>$html_distname</td><td>$status</td><td>$diffLink</td><td align="right">$diffLen</td><td>$date</td><td>$configLink</td>
</tr>
HERE

  }
  
  print $ifh <<'HERE';
</table>
</body>
</html>
HERE
  close $ifh;
}


