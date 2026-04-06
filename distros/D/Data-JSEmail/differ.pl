#!/usr/bin/perl -w

use 5.020;
use lib 'lib';
use Data::JSEmail;
use JSON::XS;
use Data::Dumper;
use Encode;
use List::Util qw(max);
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

my $emailid = shift;

my $j = JSON::XS->new->utf8->canonical;

opendir(DH, "dev/data");
my @files;
while (readdir(DH)) {
  next unless m/(.*)\.json/;
  push @files, $1;
}
closedir(DH);

$/ = undef;

for my $file (sort @files) {
  next if ($emailid and $emailid ne $file);
  open(FH, "dev/data/$file.eml");
  my $edata = <FH>;
  close(FH);
  open(FH, "dev/data/$file.json");
  my $jdata = <FH>;
  close(FH);
  my $j = $j->decode(Encode::encode_utf8($jdata));
  my $e = Data::JSEmail::parse($edata);
  for my $key (sort keys %$e) {
    next unless exists $j->{$key}; # not fetched!
    next if $key eq 'id'; # skippable keys
    next if $key eq 'threadId'; # skippable keys
    next if $key eq 'blobId'; # skippable keys
    next if $key eq 'bodyValues'; # NOT REQUESTED, COME BACK TO ME
    next if $key eq 'preview'; # NOT REQUESTED, COME BACK TO ME
    my $x = $j->{$key};
    my $y = $e->{$key};
    if ($key eq 'subject') {
      $x = _cleanheader($x);
      $y = _cleanheader($y);
    }
    valeq("$file $key", $x, $y);
  }
  if ($emailid) {
    say Data::JSEmail::make($e);
  }
#  last;
}

sub valeq {
  my ($prefix, $x, $y) = @_;

  if (ref($x) eq 'ARRAY') {
    unless (ref($y) eq 'ARRAY') {
      my $xe = $j->encode([$x]);
      my $ye = $j->encode([$y]);
      say "MISMATCH $prefix: $xe => $ye";
      return;
    }
    my $max = max($#$x, $#$y);
    for (0..$max) {
      valeq("$prefix\[$_\]", $x->[$_], $y->[$_]);
    }
    return;
  }

  if (ref($x) eq 'HASH') {
    unless (ref($y) eq 'HASH') {
      my $xe = $j->encode([$x]);
      my $ye = $j->encode([$y]);
      say "MISMATCH $prefix: $xe => $ye";
      return;
    }
    my %all = (%$x, %$y);
    for my $key (sort keys %all) {
      next if $key eq 'blobId'; # skippable keys
      next if $key eq 'size'; # charset magic XXX
      my $vx = $x->{$key};
      my $vy = $y->{$key};
      if ($key eq 'value') {
        $vx = _cleanheader($vx);
        $vy = _cleanheader($vy);
      }
      valeq("$prefix/$key", $vx, $vy);
    }
    return;
  }

  if (defined $x and defined $y) {
    $x =~ s/^\s// if $x =~ m/^\s/;
    $y =~ s/^\s// if $y =~ m/^\s/;
    $x =~ s/\s$// if $x =~ m/\s$/;
    $y =~ s/\s$// if $y =~ m/\s$/;
  }

  my $xe = $j->encode([$x]);
  my $ye = $j->encode([$y]);
  say "MISMATCH $prefix $xe => $ye" unless $xe eq $ye;
}

sub _cleanheader {
  my $val = shift;
  $val =~ s/\s+/ /gs;
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;
  return $val;
}
