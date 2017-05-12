#file:t/response/TestApache/Upload.pm
#------------------------------------
package TestApache::Upload;

use strict;
use warnings;

use Apache2::Const -compile => 'OK';
use CGI qw();

sub handler {
    my $r = shift;
    $r->content_type('text/plain');

    # Using CGI so we don't have to depend on Apache2::Request
    my $q = CGI->new();

    my $fh = $q->upload('HTTPUPLOAD');
    if ($fh) {
        # Test the file that was uploaded.
        #   It consists of 40_000 1's,
        #   so we make sure that we only receive 1's,
        #   and add up the total number of characters.
        my $chars   = 0;
        my $file_ok = 1;
        my $buffer;
        while ( my $bytesread = read( $fh, $buffer, 1024 ) ) {
            $buffer =~ tr/1//d;
            $file_ok = 0 if $buffer;
            $chars += $bytesread;
        }

        $r->write("read $chars characters from file\n");
        $r->write( "file is " . ( $file_ok ? 'ok' : 'not ok' ) . "\n" );
    }
    else {
        $r->write("file upload not found\n");
    }

    # Look directly into the cache that Apache2::UploadProgress
    # maintains to make sure that there is an entry for the file
    # we uploaded.
    my $entry = $Apache2::UploadProgress::CACHE->get('1234567890abcdef1234567890abcdef');

    if ($entry) {
        my @values = unpack( 'LL', $entry );
        $r->write("cache entry: ".join(', ', @values)."\n");
        if ($values[0] > 0 && $values[0] == $values[1]) {
            $r->write("upload progress finished successfully\n");
        }
        else {
            $r->write("upload progress did not finished successfully\n");
        }
    }
    else {
        $r->write("no cache entry found\n");
    }

    Apache2::Const::OK;
}

1;
