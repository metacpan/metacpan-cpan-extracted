#!/usr/local/bin/perl
use strict;
use warnings;
use File::Spec;
use Getopt::Long;
use LWP::UserAgent;
use YAML;

my $download_base_url = "http://ftp.gnu.org/pub/gnu/";

main();

sub main
{
    my %config = ();

    my $meta_file;
    foreach my $f qw(META.yml ../META.yml) {
        if (-f $f) {
            $meta_file = $f;
            last;
        }
    }

    if ($meta_file) {
        my $meta = YAML::LoadFile($meta_file);
        # version = X.YYZZZ. We need X.YY
        if ($meta->{version}) {
            $config{version} = substr($meta->{version}, 0, 4);
        }
    }

    if( ! GetOptions(\%config, "version=s", "os=s") ) {
        exit 1;
    }

    die "no version?!" if
        (!$config{version} || $config{version} !~ /^[\d\.]+$/);

    my $tgz   = "libiconv-$config{version}.tar.gz";
    
    my $local = File::Spec->catfile('src', $tgz);
    my $url   = "$download_base_url/libiconv/$tgz";

    my $ua = LWP::UserAgent->new(
        agent      => "Alien::Iconv source downloader",
        keep_alive => 1,
        env_proxy  => 1,
    );
    print "downloading...\n",
          "  from: $url\n",
          "  local: $local\n";
    my $res = $ua->mirror($url, $local);
}