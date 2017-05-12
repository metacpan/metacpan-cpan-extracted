#---------------------------------------------------------------------
package t::Vectors;
#
# Copyright 2013 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Run tests using test vectors from the ECRYPT Stream Cipher Project
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;

use FindBin '$Bin';
use Test::More;

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(test_vectors);

use Crypt::Salsa20;

sub DIGEST_LEN () { 64 }

my $strict_testing = !!$ENV{AUTHOR_TESTING};

sub failed
{
  BAIL_OUT('failed when AUTHOR_TESTING is set') if $strict_testing;
} # end failed

sub test_vectors
{
  my ($rounds) = @_;

  my $fn = "$Bin/$rounds-verified.test-vectors";

  open(my $in, '<', $fn) or die "Can't open $fn: $!";

  my $prefix = '';

  while (<$in>) {
    if (/^Set /) {
      chomp;
      s/#//;
      my $name = $prefix . $_;
      my (%args, @tests, $key);

      while (<$in>) {
        chomp;
        last unless /\S/;

        s/^\s+//;

        if (s/^(\S+)\s+=\s*//) {
          $args{$key = $1} = $_;
          if ($key =~ /^stream\[(\d+)\.\.(\d+)\]$/) {
            push @tests, [$1, $2];
          }
        } else {
          $args{$key} .= $_;
        }
      }

      my $salsa20 = Crypt::Salsa20->new(-key => pack('H*', $args{key}),
                                        -iv  => pack('H*', $args{IV}),
                                        -rounds => $rounds);
      my $cbytes = $salsa20->encrypt("\0" x ($tests[-1][1] + 1));

      for my $test (@tests) {
        $key = "stream[$test->[0]..$test->[1]]";
        is(uc unpack('H*', substr($cbytes, $test->[0], $test->[1]-$test->[0]+1)),
           $args{$key},
           "$name $key") or failed;
      }

      my $xor_digest = "\0" x DIGEST_LEN;
      for (my $pos = 0; $pos < length $cbytes; $pos += DIGEST_LEN) {
        $xor_digest ^= substr($cbytes, $pos, DIGEST_LEN);
      }

      is(uc unpack('H*', $xor_digest), $args{'xor-digest'}, "$name xor-digest")
          or failed;
    } elsif (/^Primitive Name: (.+)/) {
      $prefix = "$1 ";
    }
  }
} # end test_vectors

1;
