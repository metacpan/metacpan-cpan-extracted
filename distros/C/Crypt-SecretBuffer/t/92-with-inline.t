use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

subtest lib_exists => sub {
   my $inline_vars= Crypt::SecretBuffer->Inline('C');
   # The first two elements of LIBS should be -LPATH to the library and -llibraryfile
   my ($qpath, $path, $file)= $inline_vars->{LIBS} =~ /^-L(?:"([^"]+)"|([^"]\S+)) -l(\S+)/;
   $path= $qpath if defined $qpath; # (?| not introduced until perl 5.10
   ok( length $path && length $file, 'parsed LIBS' )
      or diag "Unexpected LIBS format: '$inline_vars->{LIBS}'";
   ok( -d $path, 'path exists' )
      or diag "Not a directory: '$path'";
   ok( -f File::Spec->catfile($path, $file), 'libfile exists' )
      or diag "Not a file: '".File::Spec->catfile($path, $file)."'";
} or do {
   diag explain(Crypt::SecretBuffer->Inline('C'));
   diag explain(@INC);
   diag $^O eq 'MSWin32'? `dir /b /s` : `find .`;
};

subtest test_inline_example => sub {
   skip_all "Require Inline::C for this test"
      unless eval { require Inline::C };

   if (ok(eval <<END_PM, 'compile inline example') )
package TestSecretBufferWithInline;
use Inline with => 'Crypt::SecretBuffer';
use Inline C => <<END_C;

#include <SecretBuffer.h>

int test(secret_buffer *buf) {
   return buf->len;
}

END_C

1;
END_PM
   {
      my $secret= secret(length => 10);
      is( TestSecretBufferWithInline::test($secret), 10, 'called Inline fn on SecretBuffer' );
   }
   else {
      diag $@;
   }
} or do {
   diag explain(Crypt::SecretBuffer->Inline('C'));
   diag explain(@INC);
   diag $^O eq 'MSWin32'? `dir /b /s` : `find .`;
};

done_testing;
