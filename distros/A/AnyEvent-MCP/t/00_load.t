use common::sense;
use Test::More;

# Modules that need only the mandatory distribution dependencies.
# Optional components such as Worker::IMAP have their own tests.
for my $module (qw(
   AnyEvent::MCP
   AnyEvent::MCP::Client
   AnyEvent::MCP::Client::HTTP
   AnyEvent::MCP::Client::JSONL
   AnyEvent::MCP::Client::Request
   AnyEvent::MCP::Config
   AnyEvent::MCP::Extension
   AnyEvent::MCP::File
   AnyEvent::MCP::Helper
   AnyEvent::MCP::Permissions::Ask
   AnyEvent::MCP::Server
   AnyEvent::MCP::Server::Connect
   AnyEvent::MCP::Server::HTTP
   AnyEvent::MCP::Server::JSONL
   AnyEvent::MCP::Server::Permissions
   AnyEvent::MCP::Server::Request
   AnyEvent::MCP::Server::Simple
   AnyEvent::MCP::Server::Toolset
   AnyEvent::MCP::Workdirs
)) {
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
