package ClearCase::FixSrcCont;

use warnings;
use strict;
use File::Basename;
use ClearCase::Argv;

our $VERSION = '0.01';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(add2fix runfix);

my $ct = new ClearCase::Argv({ipc=>1, autochomp=>1});
my $broker = $ENV{FSCBROKER};
my $fxsc = '/usr/local/bin/fixsrccnt';
my (%tofix, %textfile);
my $user = getpwuid($<) or die "Failed to get uid: $!";

sub textfile {
  my ($typ, $ele) = @_;
  return 1 if $typ eq 'text_file';
  my $vob = $ct->des(['-s'], "vob:$ele")->qx;
  return $textfile{$vob}->{$typ} if defined($textfile{$vob}->{$typ});
  my $sup = $typ;
  do {
    return $textfile{$vob}->{$typ} = 1 if $sup eq 'text_file';
    ($sup) = grep s/^\s*supertype: (.*)$/$1/, $ct->des("eltype:$sup\@$vob")->qx;
  } while $sup and $sup ne 'file_system_object';
  return $textfile{$vob}->{$typ} = 0;
}
sub add2fix {
  return unless $broker and -x $broker;
  for (@_) {
    my $ver = $_; #version from which just branched off/checked out
    my ($oidpr, $ele, $elt) = $ct->des([qw(-fmt %On\n%En\n%[type]p)], $ver)->qx;
    next unless textfile($elt, $ele);
    my $v0 = $ct->des([qw(-fmt %En@@%PVn)], $ele)->qx; #branch 0, checkedout
    my $oid0 = $ct->des([qw(-fmt %On)], $v0)->qx;
    my ($br) = $v0 =~ m%^(.*)/0$%;		#branch
    my $oidbr = $ct->des([qw(-fmt %On)], $br)->qx;
    my ($dir) = grep s/^source cont="(.*)"$/$1/, $ct->dump($v0)->qx;
    $dir = dirname($dir);
    my $owner = $ct->des([qw(-fmt %[owner]p)], "vob:$ele\@\@")->qx; # for -nda
    $owner =~ s%^.*/%%;
    push @{$tofix{$owner}}, join '@', $dir, $oid0, $oidbr, $oidpr;
  }
}

sub runfix {
  add2fix(@_);
  for (keys %tofix) {
    my $arg = join '@@', @{$tofix{$_}};
    if (/^\Q$user\E$/) {
      system($fxsc, $arg);
    } else {
      system($broker, "$_:$arg");
    }
  }
}

1;
