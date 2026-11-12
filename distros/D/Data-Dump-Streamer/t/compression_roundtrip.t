use 5.012;
use strict;
use warnings;
use Test::More;
use File::Temp           qw(tempfile);
use Data::Dump::Streamer qw(Dump sqz usqz);

plan skip_all => 'needs Compress::Zlib and MIME::Base64'
    unless eval { require Compress::Zlib; require MIME::Base64; 1 };

my @includes= map { "-I$_" } grep { !ref } @INC;
my @cases= (
    [ 'binary bytes',        "compress me\0\xff" x 20 ],
    [ 'UTF-8-looking bytes', "\xc3\xa9\0" ],
    [ 'empty bytes',         '' ],
    [ 'wide characters',     "wide \x{100} \x{1f642}\0" ],
);
for my $case (
    [ ASCII     => 'plain ASCII' ],
    [ 'Latin-1' => "caf\xe9" ],
    [ empty     => '' ]
) {
    utf8::upgrade($case->[1]);
    push @cases, [ "Unicode $case->[0]", $case->[1] ];
}

for my $case (@cases) {
    subtest $case->[0] => sub {
        plan tests => 7;
        my $original= $case->[1];
        my $snapshot= $original;
        my $unicode= utf8::is_utf8($original) ? 1 : 0;
        my $payload= eval { sqz($original) };
        is($@, '', 'compression accepts the string');
        return if $@;

        my $copy= usqz($payload);
        is($copy, $original, 'sqz/usqz restores the characters');
        is(utf8::is_utf8($copy) ? 1 : 0,
            $unicode, 'sqz/usqz restores the UTF-8 flag');

        my $text= Dump($original)->Compress(-1)->Terse(1)->Out;
        my ($program, $filename)=
            tempfile(SUFFIX => '.pl', TMPDIR => 1, UNLINK => 1);
        print {$program} "use strict;\nuse warnings;\nmy \$value = do {\n",
            $text, <<'CHILD'

};
my $unicode = utf8::is_utf8($value) ? 1 : 0;
print $unicode, ':', join(',', unpack('U*', $value)), "\n";
CHILD
            or die "Cannot write $filename: $!";
        close $program or die "Cannot close $filename: $!";

        # Reconstruction must load its own optional dependencies, rather
        # than relying on modules loaded while generating this dump.
        open my $child, '-|', $^X, @includes, $filename
            or die "Cannot start reconstruction interpreter: $!";
        my $output= do { local $/; <$child> };
        my $success= close $child;
        ok($success, 'compressed dump runs in a fresh interpreter')
            or diag "Reconstruction process status: $?";
        is(
            $output,
            $unicode . ':' . join(',', unpack('U*', $original)) . "\n",
            'fresh reconstruction preserves characters and the UTF-8 flag'
        );
        is($original, $snapshot,
            'compression leaves the input characters unchanged');
        is(utf8::is_utf8($original) ? 1 : 0,
            $unicode, 'compression leaves the input UTF-8 flag unchanged');
    };
}

my $legacy= MIME::Base64::encode(Compress::Zlib::compress($cases[0][1], 9), '');
is(sqz($cases[0][1]), $legacy,      'byte payload format is unchanged');
is(usqz($legacy),     $cases[0][1], 'legacy untagged payload still decodes');

done_testing;
