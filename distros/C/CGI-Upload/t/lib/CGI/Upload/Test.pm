package CGI::Upload::Test;
use strict;
use warnings;

use base 'Exporter';
## no critic (ProhibitAutomaticExportation);
our @EXPORT = qw(&upload_file &is_installed);

use Test::More;
use File::Spec::Functions qw(catfile);

# subroutine to upload any file (and prepare the multi-part version of it on the fly).
# For some reason you cannot run this function twice !?? What bug is this ?
# using local/plain.txt

use CGI::Upload;

sub upload_file {
    my $original_file = shift;
    my $args = shift || {};
    
    my $long_filename_on_client = $args->{long_filename_on_client} || $original_file;
    my $short_filename_on_client = $args->{short_filename_on_client} || $original_file;

    my $binmode = $^O =~ /OS2|VMS|Win|DOS|Cygwin/i;

    #### Prepare environment that looks like a CGI environment
    my $boundary = "----------9GN0yM260jGW3Pq48BILfC";

    open my $fh, "<", "local/$original_file" or die "Cannot open local/$original_file\n";
    binmode $fh if $binmode;
    my $original_content;
    my $original_size = read $fh, $original_content, 10000;

    my $original ="";
    $original .= qq(--$boundary\r\n); 
    $original .= qq(Content-Disposition: form-data; name="field"; filename="$long_filename_on_client"\r\n);
    $original .= qq(Content-Type: text/plain\r\n\r\n);
    $original .= qq($original_content\r\n);
    $original .= qq(--$boundary--\r\n);

    local $ENV{REQUEST_METHOD} = "POST";
    local $ENV{CONTENT_LENGTH} = length $original;
    local $ENV{CONTENT_TYPE}   = qq(multipart/form-data; boundary=$boundary);

    my $u;
    my $uploaded_content;
    my $uploaded_size;
    {
        local *STDIN;
        #open STDIN, "<", \$original;
    
        # As I can see CGI::Simple cannot work with in-memory file handle
        # (is it due to using sysread ?) so we have to save the content in
        # a temporary file.
        open my $fh, '>', 'tmpfile' or die "Cannot create temporary file: $!";
        binmode $fh if $binmode;
        print $fh $original;
        close $fh;
        ## no critic (ProhibitBarewordFileHandles)
        open STDIN, '<', 'tmpfile' or die "Could not open tmpfile : $!";

        binmode(STDIN) if $binmode;

        ###### This is the part of the actual code that should be written in the cgi script
        ###### on the server.
        # this first part is probably not needed as in a normal code one would use only one of the
        # options.
        my $module;
        if ($args->{module}) {
            $module = $args->{module};
            if ($module eq "CGI::Simple" and $args->{instance}) {
                require CGI::Simple;
                $CGI::Simple::DISABLE_UPLOADS = 0;
                $module = CGI::Simple->new;
            }
            if ($module eq "CGI" and $args->{instance}) {
                require CGI;
                $module = CGI->new;
            }
        }
    
        if ($module) {  
            $u = CGI::Upload->new({query => $module});
        } else {
            $u = CGI::Upload->new();
        }
        my $remote = $u->file_handle('field');
        $uploaded_size = read $remote, $uploaded_content, 10000;
        unlink "tmpfile";
    }
    is($u->file_name("field"), $short_filename_on_client, "filename '$short_filename_on_client' is correct");

    is($uploaded_size, $original_size, "size is correct");
    is($uploaded_content, $original_content, "Content is the same");

    # we might not need to test the following failors in every call, but on the other hand, why not ?
    eval {
        $u->invalid_call()
    };
    like($@, qr{CGI::Upload->AUTOLOAD : Unsupported object method within module - invalid_call}, "Invalid call trapped");
    ok(not(defined $u->file_name("other_field")), "returns undef");
    return;
}


# get a module name such as CGI::Simple and return true if it can be found in the current @INC
sub is_installed {
    my $module = shift;
    
    my $file = catfile split /::/, $module;
    $file .= ".pm";
    
    my $found = 0;
    return grep {-e "$_/$file"} @INC;
}

1;


