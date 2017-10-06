use strict;
use warnings;
use Text::Patch qw( patch );
use Path::Tiny qw( path );

my $p = eval do { local $/; <DATA> };
die $@ if $@;

foreach my $filename (sort keys %$p)
{
  my $diff = $p->{$filename};
  my $file = path($filename);
  my $text = $file->slurp;
  print "patching $filename\n";
  $text = patch( $text, $diff, STYLE => 'Unified' );
  $file->spew($text);
}

__DATA__
my $VAR1 = {
          'crypto/x509/x509_vpm.c' => '@@ -101,11 +101,11 @@ sk_deep_copy(void *sk_void, void *copy_func_void, void *free_func_void)
 	void *(*copy_func)(void *) = copy_func_void;
 	void (*free_func)(void *) = free_func_void;
 	_STACK *ret = sk_dup(sk);
+	size_t i;
 
 	if (ret == NULL)
 		return NULL;
 
-	size_t i;
 	for (i = 0; i < ret->num; i++) {
 		if (ret->data[i] == NULL)
 			continue;
',
          'apps/openssl/compat/poll_win.c' => '@@ -44,9 +44,9 @@ conn_has_oob_data(int fd)
 static int
 is_socket(int fd)
 {
+	WSANETWORKEVENTS events;
 	if (fd < 3)
 		return 0;
-	WSANETWORKEVENTS events;
 	return (WSAEnumNetworkEvents((SOCKET)fd, NULL, &events) == 0);
 }
 
',
          'crypto/compat/posix_win.c' => '@@ -29,10 +29,11 @@ FILE *
 posix_fopen(const char *path, const char *mode)
 {
 	if (strchr(mode, \'b\') == NULL) {
+		FILE *f;
 		char *bin_mode = NULL;
 		if (asprintf(&bin_mode, "%sb", mode) == -1)
 			return NULL;
-		FILE *f = fopen(path, bin_mode);
+		f = fopen(path, bin_mode);
 		free(bin_mode);
 		return f;
 	}
',
          'crypto/modes/gcm128.c' => '@@ -1515,13 +1515,15 @@ int CRYPTO_gcm128_finish(GCM128_CONTEXT *ctx,const unsigned char *tag,
 	alen = BSWAP8(alen);
 	clen = BSWAP8(clen);
 #else
-	u8 *p = ctx->len.c;
+	{
+		u8 *p = ctx->len.c;
 
-	ctx->len.u[0] = alen;
-	ctx->len.u[1] = clen;
+		ctx->len.u[0] = alen;
+		ctx->len.u[1] = clen;
 
-	alen = (u64)GETU32(p)  <<32|GETU32(p+4);
-	clen = (u64)GETU32(p+8)<<32|GETU32(p+12);
+		alen = (u64)GETU32(p)  <<32|GETU32(p+4);
+		clen = (u64)GETU32(p+8)<<32|GETU32(p+12);
+	}
 #endif
 #endif
 
'
        };
