#-*- Mode: CPerl -*-
use Test::More;
use strict;

sub unescape_qstr {
  my $qstr = shift;
  $qstr =~ s{\\n}{\n}g;
  $qstr =~ s{\\t}{\t}g;
  $qstr =~ s{^\\#}{#}g;
  return $qstr;
}

## \@qdata = load_qdata($filename)
sub load_qdata {
  my $file = shift;
  open(my $fh, "<$file")
    or die("load_qdata(): open failed for file '$file': $!");
  my @qdata = qw();
  while (defined($_=<$fh>)) {
    chomp;
    next if (/^\s*$/ || /^\#/);
    my ($q1,$q2,$cmt) = split(/\t/,$_,3);
    push(@qdata,[unescape_qstr($q1),unescape_qstr($q2),$cmt]);
  }
  close($fh);
  return \@qdata;
}

## undef = qtest(\&parsesub, $qstr0,$qstr1)
## undef = qtest(\&parsesub, $qstr0,$qstr1,$cmt)
sub qtest {
  my ($sub,$qstr0,$qstr1,$cmt) = @_;
  $cmt = "{$qstr0} == {$qstr1}" if (!$cmt || $cmt =~ /^\s*$/);

  my $q0 = eval { $sub->($qstr0); };
  my $q1 = eval { $sub->($qstr1); };
  if ($q0->can('toHash') && $q1->can('toHash')) {
    $q0 = $q0->toHash;
    $q1 = $q1->toHash;
  }
  elsif ($q0->can('toJson') && $q1->can('toJson')) {
    $q0 = $q0->toJson;
    $q1 = $q1->toJson;
  }
  is_deeply($q0,$q1,$cmt);
}

## undef = qtestall(\&parsesub, \@qdata)
sub qtestall {
  my ($sub,$qdata) = @_;
  qtest($sub, @$_) foreach (@$qdata);
}

## undef = qtestfile(\&parsesub, $filename)
sub qtestfile {
  my ($sub,$qfile) = @_;
  my $qdata = load_qdata($qfile);
  qtestall($sub,$qdata);
}

1; ##-- be happy

