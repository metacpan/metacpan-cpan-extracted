use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

subtest lib_exists => sub {
   my $inline_vars= Crypt::SecretBuffer->Inline('C');
   # The first element of LIBS should be the absolute path to the library
   my ($qpath, $path)= $inline_vars->{LIBS} =~ /^(?:"([^"]+)"|([^"]\S*))\b/;
   $path= $qpath if defined $qpath; # (?| not introduced until perl 5.10
   ok( length $path, 'parsed LIBS' )
      or diag "Unexpected LIBS format: '$inline_vars->{LIBS}'";
   ok( -f $path, 'path exists' )
      or diag "Not a file: '$path'";
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

SV *make_span(secret_buffer *buf, UV pos, UV lim) {
   SV *s= secret_buffer_span_new_obj(buf, pos, lim, 0);
   /* Return value of SV expects a positive refcount, but have a mortal */
   SvREFCNT_inc(s);
   return s;
}

END_C

1;
END_PM
   {
      my $secret= secret(length => 10);
      is( TestSecretBufferWithInline::test($secret), 10, 'called Inline fn on SecretBuffer' );
      is( TestSecretBufferWithInline::make_span($secret, 1, 2),
         object {
            call buffer => $secret;
            call pos => 1;
            call lim => 2;
            call len => 1;
            call encoding => 'ISO-8859-1';
         },
         'secret_buffer_span_new_obj'
      );
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
