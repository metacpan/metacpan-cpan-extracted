use Test2::V0;
use Crypt::SecretBuffer qw( secret );

my $buf= Crypt::SecretBuffer->new("test");
is( $buf->length, 4, 'buf->length' );

my $clone= secret($buf);
is( $clone->length, 4, 'clone->length' );

my %perl_internal= map +($_ => 1), qw( isa can import bootstrap dl_load_flags );
subtest clean_namespace => sub {
   my $ns= \%Crypt::SecretBuffer::;
   my @public= qw( append append_asn1_der_length append_base128be append_base128le
      append_console_line append_lenprefixed append_random append_read append_sysread as_pipe
      assign capacity clear index length load_file memcmp new rindex save_file scan span splice
      stringify stringify_mask substr syswrite unmask_to write_async );
   is( [ grep /^[a-z]/ && !$perl_internal{$_}, sort keys %$ns ], \@public )
      or diag explain $ns;
};

done_testing;
