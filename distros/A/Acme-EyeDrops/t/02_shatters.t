#!/usr/bin/perl
# 02_shatters.t (was module.t)
# Test program for module bug raised by Mark Puttman.

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

# Fails with "Out of memory!" with perl 5.10.0: comment out tests 2-4 for now.
# print "1..4\n";
print "1..1\n";

my $module_str = <<'GROK';
package MyEye;
use strict;

sub new
{
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self={};
     $self->{name}=shift;
  bless $self,$class;
  return $self;
}

sub printName
{
  my $self=shift;
  print "My Name is $self->{name}\n";
}

1;
GROK

my $main_str = <<'GROK';
use MyEye;

my $obj=MyEye->new("mark");
$obj->printName();
GROK

my $camelstr = get_eye_string('camel');
my $japhstr = get_eye_string('japh');
my $tmpf = 'bill.tmp';

# -------------------------------------------------

my $itest = 0;
my $prog;

# JAPH  MyEye.pm -----------------------------------

$prog = sightly({ Shape         => 'japh',
                  SourceString  => $module_str,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file('MyEye.pm', $prog);
$prog =~ tr/!-~/#/;
$prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog eq $japhstr or print "not ";
++$itest; print "ok $itest - MyEye.pm shape\n";

# Camel myeye.pl -----------------------------------

$prog = sightly({ Shape         => 'camel',
                  SourceString  => $main_str,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
# Fails with "Out of memory!" with perl 5.10.0: comment out tests 2-4 for now.
# my $outstr = `$^X -w -Mstrict $tmpf`;
# my $rc = $? >> 8;
# $rc == 0 or print "not ";
# ++$itest; print "ok $itest - MyEye.pm rc\n";
# $outstr eq "My Name is mark\n" or print "not ";
# ++$itest; print "ok $itest - MyEye.pm output\n";
# $prog =~ tr/!-~/#/;
# $prog eq $camelstr or print "not ";
# ++$itest; print "ok $itest - shape\n";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
unlink('MyEye.pm') or die "error: unlink 'MyEye.pm': $!";
