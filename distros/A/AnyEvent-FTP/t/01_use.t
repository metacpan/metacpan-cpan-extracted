use Test2::V0 -no_srand => 1;

sub require_ok ($);

require_ok 'AnyEvent::FTP';
require_ok 'AnyEvent::FTP::Client';
require_ok 'AnyEvent::FTP::Client::Response';
require_ok 'AnyEvent::FTP::Client::Role::FetchTransfer';
require_ok 'AnyEvent::FTP::Client::Role::ListTransfer';
require_ok 'AnyEvent::FTP::Client::Role::RequestBuffer';
require_ok 'AnyEvent::FTP::Client::Role::ResponseBuffer';
require_ok 'AnyEvent::FTP::Client::Role::StoreTransfer';
require_ok 'AnyEvent::FTP::Client::Site';
require_ok 'AnyEvent::FTP::Client::Site::Base';
require_ok 'AnyEvent::FTP::Client::Site::Microsoft';
require_ok 'AnyEvent::FTP::Client::Site::NetFtpServer';
require_ok 'AnyEvent::FTP::Client::Site::Proftpd';
require_ok 'AnyEvent::FTP::Client::Transfer';
require_ok 'AnyEvent::FTP::Client::Transfer::Active';
require_ok 'AnyEvent::FTP::Client::Transfer::Passive';
require_ok 'AnyEvent::FTP::Request';
require_ok 'AnyEvent::FTP::Response';
require_ok 'AnyEvent::FTP::Role::Event';
require_ok 'AnyEvent::FTP::Server';
require_ok 'AnyEvent::FTP::Server::Connection';
require_ok 'AnyEvent::FTP::Server::Context';
require_ok 'AnyEvent::FTP::Server::Context::FS';
require_ok 'AnyEvent::FTP::Server::Context::FSRO';
require_ok 'AnyEvent::FTP::Server::Context::FSRW';
require_ok 'AnyEvent::FTP::Server::Context::Memory';
require_ok 'AnyEvent::FTP::Server::OS::UNIX';
require_ok 'AnyEvent::FTP::Server::Role::Auth';
require_ok 'AnyEvent::FTP::Server::Role::Context';
require_ok 'AnyEvent::FTP::Server::Role::Help';
require_ok 'AnyEvent::FTP::Server::Role::Old';
require_ok 'AnyEvent::FTP::Server::Role::ResponseEncoder';
require_ok 'AnyEvent::FTP::Server::Role::TransferPrep';
require_ok 'AnyEvent::FTP::Server::Role::Type';
require_ok 'AnyEvent::FTP::Server::UnambiguousResponseEncoder';
require_ok 'Test::AnyEventFTPServer';
done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
