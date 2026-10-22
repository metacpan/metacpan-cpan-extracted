use common::sense;
use File::Find ();
use Test::More;

# Load every module, including new ones not yet added to the manifest.
my @modules;
File::Find::find ({ no_chdir => 1, wanted => sub {
   push @modules, $File::Find::name if /\.pm\z/ && -f _;
}}, "lib");

for my $path (sort @modules) {
   (my $module = $path) =~ s{\Alib/}{};
   $module =~ s{/}{::}g;
   $module =~ s/\.pm\z//;
   require_ok $module;
}

my $text = "\x{e4}\x{1f642}";
my $bytes = AnyEvent::MCP::utf8enc $text;
is $bytes, "\xc3\xa4\xf0\x9f\x99\x82", "encode UTF-8";
is AnyEvent::MCP::utf8dec ($bytes), $text, "decode UTF-8";
is $text, "\x{e4}\x{1f642}", "source is unchanged";
eval { AnyEvent::MCP::utf8dec ("\xff") };
ok $@, "reject invalid UTF-8";

done_testing;
