package App::Repo;
use Data::Dumper;
use Digest::SHA qw< sha1_hex sha256_hex >;
use Digest::MD5 qw< md5_hex >;
use File::Path;
use File::Find;
use File::Copy;

use warnings;
use strict;

=head1 NAME
 
App::Repo - create debian repository
 
=cut

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = ( 'digest', 'packages' );
our $VERSION = '0.11';


my @deb_files = ();
my $url_base = 'https://fastapi.metacpan.org/source';
my $stash = "$ENV{HOME}/.repo";

my $digest = sub {
    my $file = shift;
    my( $data, %data ) = ();
    open(my $fh,"<:raw :bytes",$file) || die "cant open $file: $!";
    while(<$fh>){
        $data .= $_;
    }

    %data = (
        sha1    =>  sha1_hex($data),
        sha256  =>  sha256_hex($data),
        md5     =>  md5_hex($data),
    );

    return \%data;
};

my $content = sub {
    my( $dir, $file ) = @_;
    my @control = ();

    if($file =~ /\.deb/){
        my $file_size = -s "$dir/$file";
        system("mkdir -p $stash/tmp && cp $dir/$file $stash/tmp/ && cd $stash/tmp && ar -x $stash/tmp/$file && tar -xf $stash/tmp/control.tar.gz && cd -");
        open(my $fh,"<","$stash/tmp/control") || die "cant open $stash/tmp/control: $!";
        while(<$fh>){
            if(/^\n/){ next };
            chomp;
            push @control, $_;
        }
        push @control, 'Size: ' . $file_size;
        push @control, 'Filename: ' . "deb/$file"; 
        push @control, 'MD5sum: ' . $digest->("$dir/$file")->{'md5'};
        push @control, 'SHA1: ' . $digest->("$dir/$file")->{'sha1'};
        push @control, 'SHA256: ' . $digest->("$dir/$file")->{'sha256'};
        push @control, "\n";
        print "$file\n";
        return \@control;
    } else { print "no deb file\n" }
};

my $find_deb = sub {
    my $deb_dir = shift;
    my @packages = ();
    find( sub{ 
            if(/\.deb$/){
                push @deb_files, $_;
            }}, $deb_dir );

    for my $deb_file (@deb_files){
        push @packages, $content->($deb_dir, $deb_file);
    }
    return \@packages;
};


sub digest {
    $digest->(shift);
}

sub packages {
    $find_deb->(shift);
}
1;
