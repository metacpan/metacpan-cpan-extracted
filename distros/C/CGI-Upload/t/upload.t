#!/usr/bin/perl
use strict;
use warnings;

# Uploading one single file that was prepared as multipart message 
# 
# original file: local/plain.txt
# prepared as multipart file: local/plain.txt_multi



# Comment:
# the CGI::Upload call under -w causes a warning in the CGI module that is reported as one of these:
# Use of uninitialized value in pattern match (m//) at (eval 8) line 4
# this hapens if the HTTP_USER_AGENT is not defined

# On the other hand HTTP::BrowserDetect complains heavily if the HTTP_USER_AGENT is not something
# it expects. e.g. this one:    $ENV{HTTP_USER_AGENT} = "Linux";
# This is not very related to CGI::Upload but well.


# If I copy-paste the whole section of the upload, the second section does not
# work correctly. Is this a bug or a user error ?

#open(my $in, '<', 't/upload_post_text.txt') or die 'missing test file';

use lib 'lib';
use CGI::Upload;

use Test::More tests => 4;

{

    local $ENV{REQUEST_METHOD} = 'POST';
    local $ENV{CONTENT_LENGTH} = '217';
    #local $ENV{QUERY_STRING}   = '';
    local $ENV{CONTENT_TYPE}   = 'multipart/form-data; boundary=----------9GN0yM260jGW3Pq48BILfC';
    $ENV{HTTP_USER_AGENT} = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.3) Gecko/20030312";

    my $u;
    my $uploaded_content;
    my $uploaded_size;
    {
        local *STDIN;
        ## no critic (ProhibitBarewordFileHandles)
        open(STDIN, '<', 'local/plain.txt_multi') 
                    or die "missing test file 'local/plain.txt_multi'\n";
        binmode(STDIN);

        $u = CGI::Upload->new();
        #SKIP: {
        #   skip "fix invalid call", 1;
            ok(not(defined $u->file_name("other_field")), "returns undef");
        #}
        my $remote = $u->file_handle('field');
        $uploaded_size = read $remote, $uploaded_content, 10000;
    }
    is($u->file_name("field"), "plain.txt", "filename is correct");

    open my $fh, "<", "local/plain.txt" or die "Cannot open local/plain.txt\n";
    my $original_content;
    my $original_size = read $fh, $original_content, 10000;
    is($uploaded_size, $original_size, "size is correct");
    is($uploaded_content, $original_content, "Content is the same");
}


