use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use IO::Handle;
use File::Temp;
use Crypt::SecretBuffer qw(secret);

subtest 'syswrite to pipe' => sub {
    my ($r, $w) = pipe_with_data();
    my $buf = Crypt::SecretBuffer->new('secret data');
    my $written = $buf->syswrite($w);
    is($written, length('secret data'), 'wrote all bytes');
    close $w;
    local $/; my $got = <$r>;
    is($got, 'secret data', 'read back data');
    close $r;
};

subtest 'syswrite with offset/count' => sub {
    my ($r, $w) = pipe_with_data();
    my $buf = Crypt::SecretBuffer->new('abcdefgh');
    my $written = $buf->syswrite($w, 4, 2); # write cdef
    is($written, 4, 'wrote subset');
    close $w; local $/; my $got = <$r>;
    is($got, 'cdef', 'subset received');
    close $r;
};

subtest save_file => sub {
   my $buf = Crypt::SecretBuffer->new('abcdefgh');
   my $f= File::Temp->new;

   ok( !eval{ $buf->save_file("$f"); 1 }, "won't overwrite existing file" );
   $f->seek(0,0);
   my $text= <$f>;
   is( $text, undef, 'nothing available in file' );

   ok( $buf->save_file("$f", 1), "overwrite flag" );
   $f->seek(0,0);
   $text= <$f>;
   is( $text, "abcdefgh", "temp file now contains secret" );

   $buf->length(3); # truncate buffer
   if ($^O eq 'MSWin32') { # Win32 can't rename overtop an open file
      $f->close;
      ok( $buf->save_file("$f", 'rename'), 'overwrite via rename' );
   } else {
      ok( $buf->save_file("$f", 'rename'), 'overwrite via rename' );
      $f->seek(0,0);
      $text= <$f>;
      is( $text, "abcdefgh", "previous file content unchanged" );
      $f->close;
   }
   open my $fh, '<', "$f" or die "$!";
   $text= <$fh>;
   is( $text, "abc", "new file contains only 3 bytes" );
};

done_testing;

