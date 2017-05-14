package App::Repo::Agent;

use 5.010;
use LWP::Curl;
use Data::Dumper;
use Digest::SHA qw< sha1_hex sha256_hex >;
use Digest::MD5 qw< md5_hex >;
use Term::ANSIColor;
use JSON::PP;
use File::Path;
use File::Find;
use File::Copy;

use warnings;
use strict;

=head1 NAME
 
App::Repo - creates Packages list and starts APT repository
 
=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = ( 'printer' );
our $VERSION = '0.01';

my $base_path = "$ENV{HOME}/.repo/stash";

my $curl = LWP::Curl->new(
    user_agent   => 'Telesphoreo APT-HTTP/1.0.592',
    #agent => 'Cydia/0.9 CFNetwork/711.4.6 Darwin/14.0.0',
    timeout => 10,
    maxredirs => 10,
);

sub get_packages {
    my $repo_url = shift; $repo_url =~ s/\/$//;
    my @packages_list = qw( Packages Packages.bz2 Packages.gz );

    mkpath($base_path);
    for(@packages_list){
        my $packages_tmp_file = "$base_path/$_";
        say "packages_tmp_file: $packages_tmp_file";
        say "trying $repo_url/$_";
        my $system = system("curl --user-agent \"Telesphoreo APT-HTTP/1.0.592\" -kLo $packages_tmp_file $repo_url/$_");
        say "system: $system";

        #my $res = $curl->get("$repo_url/$_");
        #if($res->is_success){
        #open(my $fh,"> :raw :bytes",$packages_tmp_file);
        #        print $fh $res->content;
        #        close $fh;
        #        }
    }
    return parse_control($repo_url, "Packages.gz");
}

sub parse_control {
    my( $repo_url, $packages_tmp_file ) = @_;
    my( @packages, %packages, $i ) = ();

    if( -f "$base_path/Packages.gz"){
        say "gz exist";
        system("gunzip -f $base_path/Packages.gz");
    } 
    if( -f "$base_path/Packages.bz2"){
        say "bz2 exist";
        system("bzcat $base_path/Packages.bz2 > $base_path/Packages");
    }

    if( -f "$base_path/Packages"){
        open(my $fh, '<', "$base_path/Packages") || die "cant open $base_path/Packages: $!";
        while(<$fh>){ 
            if( /\:\ /){ 
                s/(.*?)(\:\ )(.*)/$1$2$3/;
                my($key, $value) = ($1, $3); chomp $value;
                $packages{$key} = $value;
            } else { 
                $packages{url} = "$repo_url/$packages{Filename}";
                $packages{number} = $i++;
                $packages{repository} = $repo_url;
                $packages{t} = $repo_url;
                push @packages, { %packages };
            }
        }
    }
    return \@packages;
}

#print Dumper(get_packages("$ARGV[0]"));

sub read_json {
    open(my $fh,"<", "$base_path/packages.json") || die "cant open: $base_path/packages.json: $!";
    my $json = <$fh>;
    my $p = decode_json $json;
}

sub write_json {
    my @p = @{get_packages(shift)};
    my $json = encode_json \@p;
    open(my $fh,">", "$base_path/packages.json") || die "cant open: $base_path/packages.json: $!";
    print $fh $json;
}

sub printer {
    my @p = @{get_packages(shift)};
    my %lenght = ();
    for(@p){
        print colored(['white on_cyan'],"$_->{number}") . " $_->{Name}" . colored(['blue']," - ");
    }
}


#my @url = grep { $_->{Name} } @{get_packages("$ARGV[0]")};
#for(@url){
#    say $_->{url};
#}





printer("$ARGV[0]");
#for(@p){ say $_->{Name} };

__DATA__
my $res = $furl->get('http://repo.biteyourapple.net/#download.php?package=repo.biteyourapple.net.phixretroios9');
open( my $fh,">", 'debian.deb' ) || die "cant write to debian.deb: $!";
print $fh $res->content;
close $fh;

die;

# print Dumper($furl->env_proxy());
 


#my $res = $furl->get('http://repo.biteyourapple.net/download.php?package=repo.biteyourapple.net.quada');
#my $res = $furl->get('http://repo.biteyourapple.net/download.php?package=repo.biteyourapple.net.voguewallpapers');
die $res->status_line unless $res->is_success;

 
__DATA__


10.0.0.32 - - [03/Aug/2016:13:59:39 +0200] "GET http://repo.biteyourapple.net/download.php?package=repo.biteyourapple.net.voguewallpapers HTTP/1.1" 302 0 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11;



my $res = $furl->post(
    'http://example.com/', # URL
    [...],                 # headers
    [ foo => 'bar' ],      # form data (HashRef/FileHandle are also okay)
);
 
# Accept-Encoding is supported but optional
$furl = Furl->new(
    headers => [ 'Accept-Encoding' => 'gzip' ],
);
my $body = $furl->get('http://example.com/some/compressed');
