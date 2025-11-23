use Test2::V0;
use Crypt::SecretBuffer qw( secret );

subtest 'basic substr functionality' => sub {
   my $buf = Crypt::SecretBuffer->new("password123");
   
   # Test with substr(offset)
   my $sub1 = $buf->substr(4);
   isa_ok($sub1, 'Crypt::SecretBuffer');
   is($sub1->{stringify_mask}, $buf->{stringify_mask}, 'stringify_mask is inherited');
   
   # Make visible to test content
   local $sub1->{stringify_mask} = undef;
   is("$sub1", 'word123', 'substr(4) returns remainder of buffer');
   
   # Test with substr(offset, length)
   my $sub2 = $buf->substr(4, 4);
   local $sub2->{stringify_mask} = undef;
   is("$sub2", 'word', 'substr(4, 4) returns specific portion');
   
   # Test with substr(0, length)
   my $sub3 = $buf->substr(0, 4);
   local $sub3->{stringify_mask} = undef;
   is("$sub3", 'pass', 'substr(0, 4) returns beginning portion');
   
   # Test negative offset
   my $sub4 = $buf->substr(-3);
   local $sub4->{stringify_mask} = undef;
   is("$sub4", '123', 'substr(-3) returns last 3 chars');
   
   # Test negative length
   my $sub5 = $buf->substr(0, -3);
   local $sub5->{stringify_mask} = undef;
   is("$sub5", 'password', 'substr(0, -3) omits last 3 chars');
};

subtest 'replacement functionality' => sub {
   my $buf = Crypt::SecretBuffer->new("password123");
   local $buf->{stringify_mask} = undef;

   # Test replacement
   $buf->substr(4, 4, Crypt::SecretBuffer->new("SECRET"));
   is("$buf", 'passSECRET123', 'substr replacement works correctly');

   # Test empty replacement
   $buf->substr(4, 6, undef);
   is("$buf", 'pass123', 'replace with undef');

   # Test replacement beyond string length
   $buf->substr(7, 0, Crypt::SecretBuffer->new("!"));
   is("$buf", 'pass123!', 'replace with secret');

   # Test replacement with a Span
   $buf->substr(7, 999, Crypt::SecretBuffer->new("0123456789")->span(4,4));
   is("$buf", 'pass1234567', 'replace with Span');

   # Test replacement with a scalar
   $buf->substr(1, -1, 123456789);
   is("$buf", 'p1234567897', 'replace with scalar');

   # Test replacement with a scalar-ref
   $buf->substr(1, -1, \"--");
   is("$buf", 'p--7', 'replace with scalar-ref');
};

subtest 'edge cases' => sub {
   my $buf = Crypt::SecretBuffer->new("test");
   
   # Test empty result
   my $empty = $buf->substr(0, 0);
   isa_ok($empty, 'Crypt::SecretBuffer');
   is($empty->length, 0, 'empty substr has zero length');
   
   # Test substr beyond string length
   my $beyond = $buf->substr(10, 5);
   is($beyond->length, 0, 'substr beyond length returns empty buffer');
   
   # Test substr with edge offsets
   my $edge1 = $buf->substr(4);
   is($edge1->length, 0, 'substr at exact string end returns empty buffer');
   
   # Test modifying original after substr
   my $slice = $buf->substr(1, 2);
   $buf->clear();
   local $slice->{stringify_mask} = undef;
   is("$slice", 'es', 'substr creates independent copy');
};

subtest 'security aspects' => sub {
   my $buf = Crypt::SecretBuffer->new("secretpassword");
   
   # Check that default stringify behavior is maintained
   my $sub = $buf->substr(6);
   is("$sub", '[REDACTED]', 'substr result has redacted stringify');
   
   # Test that substr is truly separate from original
   $buf->clear();
   $sub->{stringify_mask} = undef;
   is("$sub", 'password', 'substr maintains independence after original clear');
   
   # Check behavior with custom stringify_mask
   $buf = Crypt::SecretBuffer->new("secretpassword");
   $buf->{stringify_mask} = '***';
   my $sub2 = $buf->substr(0, 6);
   is("$sub2", '***', 'substr inherits custom stringify_mask');

   # Verify bytes got wiped when substr-splice shrinks the buffer
   $buf= Crypt::SecretBuffer->new("0123456789");
   $buf->{stringify_mask}= undef;
   $buf->substr(2,2,"");
   is( $buf, "01456789", 'remove 2 chars' );
   $buf->length(10);
   is( $buf, "01456789\0\0", 'substr wiped bytes when shrunk' );
};

done_testing;
