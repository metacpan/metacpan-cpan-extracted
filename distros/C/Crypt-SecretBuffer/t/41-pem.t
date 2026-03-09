use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret );
use Crypt::SecretBuffer::PEM;
use Crypt::SecretBuffer::PEM::Headers;

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

   is( $pem->serialize->memcmp($buf), 0, 'serialize' )
      or note dump_span($pem->serialize);
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

   my $pem= Crypt::SecretBuffer::PEM->parse($buf->span, secret_headers => 1);
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

   $pem= Crypt::SecretBuffer::PEM->parse($buf->span);
   is( $pem,
       object {
         call label => 'CUSTOM FORMAT';
         call header_kv => [ 'Param1', 1, 'x', 2 ];
         call headers => { Param1 => 1, x => 2 };
         call content => object {
            call [ memcmp => "qwertyuiopqwertyuiop\n" ], 0;
            call [ cmp => "\xab\x07\xab\xb7\x2b\xa2\xa2\x9a\xb0\x7a\xbb\x72\xba\x2a\x29" ], 0;
         };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($canonical), 0, 'serialize' )
      or diag dump_span($pem->serialize);
   # Try again with nonsecret content
   $pem->content("\xab\x07\xab\xb7\x2b\xa2\xa2\x9a\xb0\x7a\xbb\x72\xba\x2a\x29");
   $pem->header_kv->[1]= '1';
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

subtest header_manipulation => sub {
   my @kv= (
      A     => 1,
      ' A ' => 2,
      xyz   => 8,
      a     => 3,
      XYz   => 9,
   );
   my $h= Crypt::SecretBuffer::PEM::Headers->new(raw_kv_array => \@kv);
   is( $h->get('a'), 3, 'one match for "a"' );
   $h->caseless_keys(1);
   is( $h->get('a'), [1,3], 'caseless, two matches for "a"' );
   $h->trim_keys(1);
   is( $h->get('a'), [1,2,3], 'caseless+trim, three matches for "a"' );

   $h->caseless_keys(0);
   $h->set(xyz => 6);
   is( \@kv, [ A => 1, ' A ' => 2, xyz => 6, a => 3, XYz => 9 ],
      'modified only xyz' );
   $h->set('XYZ' => [8,7,6]);
   is( \@kv, [ A => 1, ' A ' => 2, xyz => 6, a => 3, XYz => 9, XYZ => 8, XYZ => 7, XYZ => 6 ],
      'appended new XYZ values' );
   $h->caseless_keys(1);
   $h->set('XYZ' => [8,7,6]);
   is( \@kv, [ A => 1, ' A ' => 2, xyz => 8, xyz => 7, xyz => 6, a => 3 ],
      'xyz gets 3 values, others removed' );

   $h->delete('a');
   is( \@kv, [ xyz => 8, xyz => 7, xyz => 6 ],
      'all "a" matches removed' );
   $h->append(A => 1);
   is( \@kv, [ xyz => 8, xyz => 7, xyz => 6, A => 1 ],
      'added new key/value' );
};

subtest header_tied_hash_obj => sub {
   my $pem= Crypt::SecretBuffer::PEM->new(
      content => 'example',
      header_kv => [
         A => 1,
         a => 2,
         ' A ' => 3,
      ]
   );
   is( { %{$pem->headers} }, { A => 1, a => 2, ' A ' => 3 }, 'dump headers hash' );
   $pem->headers->caseless_keys(1)->trim_keys(1);
   is( { %{$pem->headers} }, { A => [1,2,3] }, 'dump headers hash with casefolding and trim' );
};

subtest header_unicode => sub {
   my $canonical= "-----BEGIN SOMETHING-----\n"
                . "\xE8\xA9\xA6: -\xE8\xA9\xA6-\n"
                . "\n"
                . "VGVzdA==\n"
                . "-----END SOMETHING-----\n";
   my $pem= Crypt::SecretBuffer::PEM->parse(secret($canonical)->span);
   is( $pem,
       object {
         call label => 'SOMETHING';
         # should be bytes
         call header_kv => [
            "\xE8\xA9\xA6", "-\xE8\xA9\xA6-",
         ];
         call headers => object {
            call [ unicode_keys => 1 ], T;
            call [ unicode_values => 1 ], T;
            # should be unicode
            call [ get => "\x{8A66}" ] => "-\x{8A66}-";
         };
         # original scalars should be unchanged
         call header_kv => [
            "\xE8\xA9\xA6", "-\xE8\xA9\xA6-",
         ];
         call content => object {
            call [ memcmp => "VGVzdA==\n" ], 0;
            call [ cmp => "Test" ], 0;
         };
       },
       'parse'
   ) or diag explain $pem;

   is( $pem->serialize->memcmp($canonical), 0, 'serialize' );
};

my %perl_internal= map +($_ => 1), qw( isa can import );
subtest clean_namespace => sub {
   my $ns= \%Crypt::SecretBuffer::PEM::;
   my @public= qw( buffer content header_kv headers label new parse parse_all serialize );
   is( [ grep /^[a-z]/ && !$perl_internal{$_}, sort keys %$ns ], \@public, 'PEM' )
      or diag explain $ns;

   $ns= \%Crypt::SecretBuffer::PEM::Headers::;
   @public= qw( append caseless_keys delete get get_array keys new raw_kv_array set trim_keys
                unicode_keys unicode_values );
   is( [ grep /^[a-z]/ && !$perl_internal{$_}, sort keys %$ns ], \@public, 'PEM::Headers' )
      or diag explain $ns;
};

done_testing;
