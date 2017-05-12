use strict;

$ENV{MOD_PERL} or die "not running under mod_perl";

print STDERR "Preloading SdnFw modules...";

my $smem = `ps -o rss --no-heading -p $$`;
chomp $smem;

use Carp;
use Apache::SdnFw::lib::DB;
#use Apache::SdnFw::lib::Memcached;
use Apache::SdnFw::object::home;
use Template;
use LWP::UserAgent;
use Crypt::CBC;
use Crypt::Blowfish;
use XML::Dumper;
use XML::Simple;
use Net::SMTP::SSL;
use Net::FTP;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);
use MIME::QuotedPrint qw(encode_qp);
use Date::Format;
use Data::Dumper;

if ($ENV{MEM_CALC}) {
	my $emem = `ps -o rss --no-heading -p $$`;
	chomp $emem;
	my $tmem = $emem-$smem;
	print STDERR "${tmem}k";
}

print STDERR "\n";

$SIG{__WARN__} = \&Carp::cluck;
