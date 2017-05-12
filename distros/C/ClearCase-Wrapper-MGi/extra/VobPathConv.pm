package ClearCase::VobPathConv;

use strict;
use warnings;
use ClearCase::Argv;
use constant PTHSEP => $^O =~ /MSWin32/ ? '\\' : '/';
require Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(uxpath2local uxtag2local uxpath2localtag winpath2ux localtag2tgt);

ClearCase::Argv->ipc(1);
our $ct = ClearCase::Argv->new({autochomp=>1, stderr=>0});
our ($rgyhost, $locreg) = grep s/^\s+Registry (?:host|region): (.*)$/$1/,
  $ct->argv(qw(hostinfo -l))->stderr(2)->qx;
die "Couldn't access a rgy host, stopped" unless $rgyhost;
our ($unixreg) = grep s/^\s+Registry region: (.*)$/$1/,
  $ct->argv(qw(hostinfo -l), $rgyhost)->qx;

sub uxpath2local($) {
  my $path = shift;
  return $path if $locreg eq $unixreg;
  my @d = split '/', $path;
  my $i = $#d;
  while (!$ct->argv(qw(lsvob -s -reg), $unixreg, join('/', @d[0..$i]))->qx
	   and $i) { $i-- }
  return $i? join(PTHSEP, uxtag2local(join('/', @d[0..$i])), @d[++$i..$#d]):'';
}
sub uxtag2local($) {
  my $tag = shift;
  return $tag if $locreg eq $unixreg;
  my ($uuid) = grep s/^\s+Vob tag replica uuid: (.*)$/$1/,
    $ct->argv(qw(lsvob -l -reg), $unixreg, $tag)->qx;
  return $uuid? $ct->argv(qw(lsvob -s -uuid), $uuid)->qx : '';
}
sub uxpath2localtag($) {
  my $path = shift;
  my @d = split '/', $path;
  my $i = $#d;
  while (!$ct->argv(qw(lsvob -s -reg), $unixreg, join('/', @d[0..$i]))->qx
	   and $i) { $i-- }
  return $i? uxtag2local(join('/', @d[0..$i])): '';
}
sub winpath2ux($;$) {
  my ($path, $host) = @_;
  my ($tgtreg) = $host? grep s/^\s+Registry region: (.*)$/$1/,
    $ct->argv(qw(hostinfo -l), $host)->qx : ($unixreg);
  $path =~ s/[a-zA-Z]:\\+(.*)$/$1/;
  my @d = grep {length $_} split m%/|\\%, $path;
  shift @d if $ct->argv(qw(lsview -s), $d[0])->stderr(0)->qx;
  return '' unless @d;
  my ($uuid) = grep s/^\s+Vob tag replica uuid: (.*)$/$1/,
    $ct->argv(qw(lsvob -l), '\\' . shift @d)->qx;
  return '' unless $uuid;
  my $uxtag = $ct->argv(qw(lsvob -s -reg), $tgtreg, '-uuid', $uuid)->qx;
  return $uxtag? join('/', $uxtag, @d): '';
}
sub localtag2tgt($;$) {
  my ($tag, $host) = @_;
  my ($tgtreg) = $host? (grep s/^\s+Registry region: (.*)$/$1/,
    $ct->argv(qw(hostinfo -l), $host)->qx) : ($unixreg);
  return (-d $tag? $tag : '') if $locreg eq $tgtreg;
  my ($uuid) = grep s/^\s+Vob tag replica uuid: (.*)$/$1/,
    $ct->argv(qw(lsvob -l -reg), $locreg, $tag)->qx;
  return $uuid? $ct->argv(qw(lsvob -s -uuid), $uuid, '-reg', $tgtreg)->qx : '';
}
1;
