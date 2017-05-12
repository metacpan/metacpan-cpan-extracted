package Apache2::FileHash::GET;

use strict;
use warnings;

use Carp;
use Digest::MD5;
use Math::BigInt;
use File::Temp;
use File::Copy;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(DECLINED OK REDIRECT);

use constant METHOD => "GET";

our $Config = {
    METHOD => {
        re_path => qr(^/getFile/(.*)),
        re_hashed => qr(^/getFile/(0x[a-zA-Z0-9]{32}\.(.*))),
    },
};

sub handler
{
    my $r = shift;

    return(Apache2::Const::DECLINED) unless $r->method() eq METHOD;

    $r->handler("perl-script");
    $r->push_handlers(PerlResponseHandler => \&file_handler);

    # First GET
    my $uri = $r->uri();
    unless ($uri =~ m#$Config->{METHOD}{re_hashed}#) {
        if ($uri =~ m#$Config->{METHOD}{re_path}#) {
            my $path = $1;
            my $filename = &Apache2::FileHash::hashing_function($r, $path);

            my $netloc = &Apache2::FileHash::netloc($r, $filename);

            $r->headers_out->set(Location => $netloc);
            $r->status(Apache2::Const::REDIRECT);

            return Apache2::Const::REDIRECT;
        }
    }

    return Apache2::Const::OK;
}

sub file_handler
{
    my $r = shift;

    my $uri = $r->uri();

    # Second pass GET
    if ($uri =~ m#$Config->{METHOD}{re_hashed}#) {
        my $file = $1;
        my $extension = $2;

        my $newfile = $Apache2::FileHash::Config->[0]{GLOBALS}{base_dir} . "/$file";

        my $types = MIME::Types->new();
        my $mime = $types->mimeTypeOf($extension);
        $r->content_type($mime);
        open(my $fh, $newfile) or die("error: open: $newfile: $!\n");

        my $buffer;
        my $len = 1024;
        while (read($fh, $buffer, $len)) {
            last unless $len;
            $r->print($buffer);
        }

        close($fh);

        return(Apache2::Const::OK);
    }
}

1;
