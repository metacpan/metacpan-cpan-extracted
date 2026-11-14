use common::sense;
use Test::More;
BEGIN {
   plan skip_all => "filesystem subprocess smoke tests require POSIX fork"
      if $^O eq "MSWin32";
}
use AnyEvent ();
use AnyEvent::MCP::Client::JSONL ();
use File::Temp ();
use Cwd ();
use MIME::Base64 ();
use JSON::XS ();

my $dir = Cwd::abs_path File::Temp::tempdir (CLEANUP => 1);
my $client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--stdio", "--sandbox=none",
      "--auto-allow", "*,*,*", "-s", "executable.perl=$^X", $dir],
   env => { %ENV, HOME => $dir, XDG_CONFIG_HOME => $dir },
);

sub call {
   my ($tool, $args) = @_;

   my $cv = AE::cv;
   my $timer = AE::timer 15, 0, sub { die "core filesystem test timed out\n" };
   $client->call ($tool, $args, sub { $cv->send ([@_]) });
   my ($ok, $result) = @{$cv->recv};
   $ok or die JSON::XS::encode_json $result;
   $result->{isError} and die JSON::XS::encode_json $result;
   $result->{structuredContent}
}

my $workdirs = call workdirs => {};
is $workdirs->{resolved_workdirs}{1}, $dir, "configured workdir is available";

my $bytes = "hello\0world\n";
my $w = call "file-write" => {
   path => "item", data => MIME::Base64::encode_base64 ($bytes, ""),
};
is $w->{bytes}, length $bytes, "file-write accepts binary data";

my $r = call "file-read" => { path => "item" };
is MIME::Base64::decode_base64 ($r->{data}), $bytes, "file-read returns exact bytes";

my $stat = call stat => { paths => ["item"] };
is $stat->{result}[0]{type}, "file", "stat identifies a regular file";

call "path-op" => { path => "item", rename => "moved" };
ok !-e "$dir/item" && -f "$dir/moved", "path-op renames files";

$r = call "file-read" => { path => "moved" };
is MIME::Base64::decode_base64 ($r->{data}), $bytes, "renamed file remains readable";

my $exec = call exec => {
   argv => [$^X, "-e", 'binmode STDIN; binmode STDOUT; local $/; print <STDIN>'],
   stdin => "core stdin\n", reason => "Core filesystem subprocess smoke test",
};
is $exec->{stdout}, "core stdin\n", "exec passes stdin and captures stdout";

$client->close;
done_testing;
