use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret MATCH_MULTI UTF8 MATCH_REVERSE );

subtest index_str => sub {
   my $buf = Crypt::SecretBuffer->new("abc123\0abc456");
   is($buf->index('abc'), 0, 'find first substring');
   is($buf->index('123'), 3, 'find middle substring');
   is($buf->index("\0"), 6, 'find NUL byte');
   is($buf->index("\0", 6), 6, 'find NUL byte');
   is($buf->index('abc', 4), 7, 'find substring after offset');
   is($buf->index('nope'), -1, 'return -1 when not found');
   is($buf->index('abc', -4), -1, 'negative offset beyond substring');
   is($buf->index("6", $buf->length-1), $buf->length-1, 'find last byte starting from last byte');
   is($buf->index("6", -1), $buf->length-1, 'find last byte using negative index');
   is($buf->index(secret("\0abc")), 6, 'Use secretbuffer as pattern' );
};

subtest rindex_str => sub {
   my $buf = Crypt::SecretBuffer->new("abc123\0abc456");
   is($buf->rindex('abc'), 7, 'find second "abc"');
   is($buf->rindex("\0"), 6, 'find NUL byte');
   is($buf->rindex("\0", 6), 6, 'find NUL byte from its own ofs');
   is($buf->rindex('abc', 1), 0, 'find substring from within length of substring');
   is($buf->rindex('nope'), -1, 'return -1 when not found');
   is($buf->rindex("a", 0), 0, 'find first byte starting from first byte');
   is($buf->rindex("6", -1), 12, 'find last byte using negative index');
   is($buf->index(secret("\0abc")), 6, 'Use secretbuffer as pattern' );
};

sub _render_char {
   $_[0] >= 0x21 && $_[0] <= 0x7E? chr $_[0] : sprintf("\\x%02X", $_[0])
}
sub bitmap_to_invlist {
   my @invlist;
   for (0..0xFF) {
      push @invlist, $_ if vec($_[0], $_, 1) ^ (@invlist & 1);
   }
   return \@invlist
}

# Test the inversion lists created for various charsets.
# Right now this is converting bitmaps from first 256 bytes into an inversion list,
# but in the future I'd like the back-end to be using inversion lists and able to cover
# unicode.
subtest charset => sub {
   # tests below use \x{100} to force perl-interpretation of a regex
   # as a baseline to compare the parsed bitmap to the perl-generated one.
   my $uni_literal= "\x{1000}";
   # third column regards unicode above 0x7F: 0 = none match, 1 = all match, 2 = need to test
   my @tests= (
      [ qr/[a-z]/                      => [97, 123], 0 ],
      [ qr/[a-z]/i                     => [65, 91, 97, 123], 0 ],
      ($] ge '5.026'? ( # /xx wasn't added until 5.26
         [ qr/[a-z 5\x{100}]/ixx       => [53, 54, 65, 91, 97, 123], 2 ],
         [ qr/[a-z 5]/ixx              => [53, 54, 65, 91, 97, 123], 0 ],
      ):()),
      [ do { no warnings; qr/[\0-\108\7777-9]/ } => [0, 9, 55, 58], 2 ],
      [ qr/[\t\r\n]/                   => [9, 11, 13, 14], 0 ],
      [ qr/[[:alpha:]]/                => [65, 91, 97, 123], 2 ],
      [ qr/[\x00-\e]/                  => [0, 28], 0 ],
      [ qr/[$uni_literal]/             => [ 0x1000, 0x1001 ], 2 ],
      [ qr/[\p{Block: Katakana}]/      => [ 0x30A0, 0x3100 ], 2 ],
      [ qr/[^[:digit:]]/               => [ 0,0x30, 0x3A ], 2 ],
      ($] ge '5.012'? ( # \p{digit} wasn't available until 5.12
         [ qr/[[:alpha:]\P{digit}]/    => [ 0,0x30, 0x3A ], 2 ],
      ):()),
      [ qr/[\p{alpha}\P{alpha}]/       => [ 0 ], 2 ],
      [ qr/[^\0\n]/                    => [ 1,10, 11 ], 1 ],
   );
   for (@tests) {
      my ($re, $invlist, $above7F)= @$_;
      my $cset= Crypt::SecretBuffer::Exports::_debug_charset($re);
      $cset->{invlist}= bitmap_to_invlist(delete $cset->{bitmap});
      # for now, remove all invlist items greater than 0xFF
      pop @{$cset->{invlist}} while 0xFF < ($cset->{invlist}[-1]||0);
      pop @$invlist while 0xFF < ($invlist->[-1]||0);
      is( $cset, { invlist => $invlist, unicode_above_7F => $above7F }, "$re" );
   }
};

subtest index_charset => sub {
   my $buf = Crypt::SecretBuffer->new("abc123\0abc456" );
   is( $buf->index(qr/[0-9]/), 3, 'find first digit' );
   is( $buf->rindex(qr/[0-9]/), 12, 'find last digit' );
   is( $buf->index(qr/[a-z]/), 0, 'find first alpha' );
   is( $buf->rindex(qr/[a-z]/), 9, 'find last alpha' );
};

subtest scan_charset => sub {
   my $str= "abc123\x{100}\x{1000}abc456";
   utf8::encode($str);
   my $buf = Crypt::SecretBuffer->new($str);
   is( [$buf->scan(qr/[0-9]/)], [3,1], 'find digit' );
   is( [$buf->scan(qr/[0-9]/, MATCH_MULTI)], [3,3], 'find span of digits' );
   is( [$buf->scan(qr/[^a-z0-9]/, UTF8)], [6, 2], 'single char of unicode spans 2 bytes' );
   is( [$buf->scan(qr/[^a-z0-9]+/, UTF8)], [6, 5], 'unicode spans 2+3 bytes' );
   is( [$buf->scan(qr/[^a-z0-9]/, UTF8|MATCH_REVERSE)], [8, 3], 'second char of unicode spans 3 bytes' );
   is( [$buf->scan(qr/[^a-z0-9]+/, UTF8|MATCH_REVERSE)], [6, 5], 'unicode spans 2+3 bytes' );
};

done_testing;

