package Apache2::FileHash::PUT;

use strict;
use warnings;

use Carp;
use Digest::MD5;
use Math::BigInt;
use File::Temp;
use File::Copy;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::ServerUtil ();
use Apache2::ServerRec ();
use Apache2::Process ();
use APR::Table ();
use Apache2::Const -compile => qw(DECLINED OK REDIRECT);
use Math::BigInt;

use APR::Brigade ();
use APR::Bucket ();
use Apache2::Const -compile => qw(MODE_READBYTES);
use APR::Const -compile => qw(SUCCESS BLOCK_READ);

use MIME::Base64;
use Apache2::FileHash;

use constant METHOD => "PUT";

our $Config = {
    METHOD => {
        re_path => qr(^/storeFile/(.*)),
    },
};

sub handler
{
    my $r = shift;

    return(Apache2::Const::DECLINED) unless $r->method() eq METHOD;

    $r->handler("perl-script");
    $r->push_handlers(PerlResponseHandler => \&file_handler);

    my $uri = $r->uri();
    my $path = "";
    if ($uri =~ m#$Config->{METHOD}{re_path}#) {
        $path = $1;
    }

    # First PUT
    unless (&Apache2::FileHash::inbucket($r, $path)) {
        my $filename = &Apache2::FileHash::hashing_function($r, $path);
        my $netloc = &Apache2::FileHash::netloc($r, $filename); # need netloc_hashed and netloc_uri

        my $bucket = &Apache2::FileHash::getbucket($r, $filename);

        my $location = $bucket->{location};
        my $name = $bucket->{name};
        my $method = $bucket->{method};
        my $port = $bucket->{port};

        my $new_netloc = "${method}://${name}:$port$uri";

        $r->headers_out->set(Location => $new_netloc);
        $r->status(Apache2::Const::REDIRECT);

        return Apache2::Const::REDIRECT;
    }

    return(Apache2::Const::OK);
}

sub file_handler
{
    my $r = shift;

    my $uri = $r->uri();

    my $path = "";
    if ($uri =~ m#$Config->{METHOD}{re_path}#) {
        $path = $1;
    }

    # Write Many.  Read Many.  Unlink at your own risk.
    if ($path) {
        my $status = &Apache2::FileHash::save_file($r, $path);

        $r->content_type('text/plain');
        $r->print($status == Apache2::Const::OK ? "0" : "1");
    }

    return(Apache2::Const::OK);
}

1;
