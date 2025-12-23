use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret );
use Crypt::SecretBuffer::PEM;

# Test utility to compare Span objects with a string of bytes
sub span_of_bytes {
   my $bytes= shift;
   return object {
      call [ cmp => $bytes ], 0;
   };
}
sub dump_span {
   my $span= shift;
   ($span->can('unmask_to')? $span : $span->copy)->unmask_to(sub { $_[0] })
}

subtest no_headers => sub {
   my $buf= secret(<<END);
-----BEGIN SOMETHING-----
VGVzdA==
-----END SOMETHING-----
END
   my $pem= Crypt::SecretBuffer::PEM->parse($buf->span);
   is( $pem,
       object {
         call label => 'SOMETHING';
         call content => object {
            call [ memcmp => "VGVzdA==\n" ], 0;
            call [ cmp => "Test" ], 0;
         };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($buf), 0, 'serialize' );
};

# I frequently encounter PEM data where the END marker lacks a newline.
subtest missing_final_newline => sub {
   my $buf= secret("-----BEGIN SOMETHING-----\nVGVzdA==\n-----END SOMETHING-----");
   my $canonical= "-----BEGIN SOMETHING-----\nVGVzdA==\n-----END SOMETHING-----\n";
   my $pem= Crypt::SecretBuffer::PEM->parse($buf->span);
   is( $pem,
       object {
         call label => 'SOMETHING';
         call content => object {
            call [ memcmp => "VGVzdA==\n" ], 0;
            call [ cmp => "Test" ], 0;
         };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($canonical), 0, 'serialize' );
};


subtest empty_content => sub {
   my $buf= secret(<<END);
-----BEGIN THE THING-----
-----END THE THING-----
END
   my $pem= Crypt::SecretBuffer::PEM->parse($buf->span);
   is( $pem,
       object {
         call label => 'THE THING';
         call content => object { call len => 0; };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($buf), 0, 'serialize' );
};

subtest with_headers => sub {
   my $buf= secret(<<END);
-----BEGIN CUSTOM FORMAT-----
Param1: 1
x:2

qwertyuiopqwertyuiop
-----END CUSTOM FORMAT-----
END
   my $canonical= secret(<<END);
-----BEGIN CUSTOM FORMAT-----
Param1: 1
x: 2

qwertyuiopqwertyuiop
-----END CUSTOM FORMAT-----
END

   my $pem= Crypt::SecretBuffer::PEM->parse($buf->span);
   is( $pem,
       object {
         call label => 'CUSTOM FORMAT';
         call header_kv => [ 'Param1', span_of_bytes('1'), 'x', span_of_bytes('2') ];
         call headers => { Param1 => span_of_bytes('1'), x => span_of_bytes('2') };
         call content => object {
            call [ memcmp => "qwertyuiopqwertyuiop\n" ], 0;
            call [ cmp => "\xab\x07\xab\xb7\x2b\xa2\xa2\x9a\xb0\x7a\xbb\x72\xba\x2a\x29" ], 0;
         };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($canonical), 0, 'serialize' )
      or diag dump_span($pem->serialize);
};

subtest mutiple_pem_blocks => sub {
   my @pem= Crypt::SecretBuffer::PEM->parse_all(secret(<<END)->span);
some text
some more text
-----BEGIN ONE THING-----
qwertyui
-----END ONE THING-----
more text and some things
-----BEGIN ANOTHER THING-----
qwertyui
-----END ANOTHER THING-----
-----BEGIN YET ANOTHER THING-----
qwertyui
-----END YET ANOTHER THING-----
....df.df.
dfsijcijefownjfkljfb
sjne jghekfoidjvsolkmf
END
   is( \@pem,
       [ object { call label => 'ONE THING'; },
         object { call label => 'ANOTHER THING'; },
         object { call label => 'YET ANOTHER THING'; },
       ],
       'Found all 3 PEM blocks'
   );
};

done_testing;
