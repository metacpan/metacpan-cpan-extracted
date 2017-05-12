use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catdir catfile/;
use File::Path qw/make_path/;
use File::Slurp;
use File::Basename qw/basename/;
use Dancer ":tests";
use Dancer::Plugin::Dropbox;

plan tests => 1;

my $basedir = catdir(t => "dropbox-dir");

set plugins => {
                Dropbox => {
                            basedir => $basedir
                           }
               };

# here we have 4 keywords which we should test in its bare form
# dropbox_send_file => this has been tested
# dropbox_upload_file
# dropbox_create_directory
# dropbox_delete_file

ok(!dropbox_delete_file("test", "/", "hello"));



