package ClearCase::ForceLock;

use warnings;
use strict;

our $VERSION = '0.01';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(funlocklt flocklt);

use Net::SSH::Perl;
use ClearCase::VobPathConv;

our $flk = '/usr/bin/locklbtype';
our $view = 'perl_view';
our $exec = '/opt/rational/clearcase/bin/cleartool setview -exec';
sub ssh() {
  my $host = 'my.unix.sshd.host';
  my $ssh = Net::SSH::Perl->new($host);
  my $account = getlogin || getpwuid($<)
    or die "Couldn't get the uid: $!\n";
  $ssh->login($account);
  return $ssh;
}
sub funlocklt($$) {
  my ($lt, $vob) = @_;
  $vob = winpath2ux($vob);
  my($out, $err, $ret) = ssh()->cmd(
    "$exec '$flk --unlock --vob $vob --lbtype $lt' $view");
  print STDERR join("\n", grep(/^cleartool:/, split /\n/, $err), '') if $err;
  print $out if $out;
  return $ret;
}
sub flocklt($$;$$) {
  my ($lt, $vob, $rep, $nusers) = @_;
  $vob = winpath2ux($vob);
  my $cmd = "$flk --vob $vob";
  $cmd .= " --replace" if $rep;
  $cmd .= " --nusers $nusers" if $nusers;
  my($out, $err, $ret) = ssh()->cmd("$exec '$cmd --lbtype $lt' $view");
  print STDERR join("\n", grep(/^cleartool:/, split /\n/, $err), '') if $err;
  print $out if $out;
  return $ret;
}

1;
