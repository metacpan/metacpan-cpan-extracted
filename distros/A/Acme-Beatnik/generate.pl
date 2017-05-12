#!/usr/bin/perl

#Fill ASCII values in @numbers
#This is for 'Hello World'
my @numbers = qw(72 101 108 108 111 32 87 111 114 108 100);
my @foo = @numbers;
my @values = qw();
my $foo;
for(@numbers)
{ while($_)
  { my $number = int(rand(15));
    $number += 3;
    if ($number >= $_)
    { push(@values,5); #Push number on stack
      push(@values,$_); #Number
      $foo += $_;
      push(@values,7);
      $_ = 0;
    } else
    { $_ -= $number;
      push(@values,5); #Push number on stack
      push(@values,$number);
      $foo += $number;
      push(@values,7);
    }
  }
  push(@values,9); #mark end of word
}
print $foo[0],"\n";
for(@values) { print $_,"\n"; }
open(FILE,"<words.txt") || die $!; 
#Assume wordlist is in words.txt
#Format : 5 = Foo
while(<FILE>)
{ chomp $_;
  my ($value,$word) = split(/ = /,$_);
  $words{$word} = $value;
}
close(FILE);
my $i;
for my $n (@values)
{ $i++;
  my @words = grep { $words{$_} == $n } keys %words;
  if ($n != 1) { print $words[int rand($#words)] , " " ; }
  else { print "a"; } #There are no words in the table with value 1, so assume 'a'
  if ($i > 10) { $i = 0; print "\n"; }
}
