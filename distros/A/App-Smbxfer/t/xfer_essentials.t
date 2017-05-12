#
# Careful tests of the essentials, namely upload/download...
#
use strict;

use Test::More tests => 9;
use Test::Differences qw( eq_or_diff );

use Filesys::SmbClient;

use IO::Prompt;
use File::Find;
use File::Temp qw( tempdir );

BEGIN { use_ok( 'App::Smbxfer', qw( smb_element_type parse_smb_spec do_smb_transfer ) ) }

#~~~~ ((( begin test initialization ))) ~~~~
    prompt( "\n...Beginning test... <press ENTER> " );
    my $server =    prompt( "\n\nSamba server name? " );
    my $share =     prompt( "share name? " );
    my $domain =    prompt( "domain? " );
    my $username =  prompt( "username? " );
    my $password =  prompt( "password? ", -e => '*' );
    my $path_file = prompt( "enter the path to any existing file on the share (relative to share root): " );
    my $path_dir =  prompt( "enter the path to any existing directory on the share (relative to share root): " );
    
    my $smb_share_spec = "smb://$server/$share";

    my $smb = Filesys::SmbClient->new(
        username => $username, password => $password, workgroup => $domain
    );

    # name of dir that will be uploaded as a test:
    my $local_dirname_to_upload = 'dir_to_upload';
    # local relative path to directory containing test resources:
    my $local_path_to_test_resources = 't/test_resources';
    my $local_path_to_upload = "$local_path_to_test_resources/$local_dirname_to_upload";
    # name of temp dir to create at root of SMB share:
    my $remote_smbxfer_dirname = 'smbxfer_test';
    my $remote_smbxfer_path_spec = $smb_share_spec . '/' . $remote_smbxfer_dirname;

    # Make dir for testing...
    $smb->mkdir( $remote_smbxfer_path_spec, '0666' )
        or die "SMB error: cannot mkdir for testing: $!";

    # Future 'die()'s should clean up after tests before really 'die()'ing
    $SIG{__DIE__} = sub { cleanup( $smb, $remote_smbxfer_path_spec ); die @_ };
#~~~~ ((( end test initialization ))) ~~~~


#
# smb_element_type() tests...
#
TODO: {
    local $TODO = 'Find out why this behaves differently in different environments; may be related to different versions of libsmbclient.so';

    is( smb_element_type( $smb, $smb_share_spec          ), SMBC_FILE_SHARE, "detected element type: share" );
}
is( smb_element_type( $smb, "$smb_share_spec/$path_file" ), SMBC_FILE,       "detected element type: file" );
is( smb_element_type( $smb, "$smb_share_spec/$path_dir"  ), SMBC_DIR,        "detected element type: dir" );


#
# parse_smb_spec()
#
ok( my ($smb_share_path, $smb_path_spec) = (parse_smb_spec( $smb_share_spec ))[3,5], "parse share spec" );


#
# validated_paths()
#
is( (App::Smbxfer::validated_paths(
        SMB => $smb, SOURCE => $local_path_to_upload, DEST =>
        "//$server/$share/$remote_smbxfer_dirname", SOURCE_IS_LOCAL => 1
    ))[1],
    "$smb_share_spec/$remote_smbxfer_dirname",
    "validated_paths normalizes remote destination as expected"
);


#
# do_smb_transfer() tests...
#
ok( 
    # Upload a directory recursively...
    # ( an smb_upload() test; also tests parent path creation )
    do_smb_transfer(
        SMB_OBJECT =>        $smb,
        LOCAL_PATH =>        $local_path_to_upload,
        SMB_PATH_SPEC =>     "$smb_path_spec/$remote_smbxfer_dirname",
        SOURCE_IS_LOCAL =>   1,
        RECURSIVE =>         1,
        CREATE_PARENTS =>    1
    ),
    "test a transfer: upload test dir"
);

my $downloaded_dir = tempdir();
ok( 
    # Download the same directory recursively to a new location...
    # ( an smb_download() test; also tests parent path creation )
    do_smb_transfer(
        SMB_OBJECT =>        $smb,
        LOCAL_PATH =>        $downloaded_dir,
        SMB_PATH_SPEC =>
        "$smb_path_spec/$remote_smbxfer_dirname/$local_path_to_upload",
        SOURCE_IS_LOCAL =>   0,
        RECURSIVE =>         1,
        CREATE_PARENTS =>    1
    ),
    "test a transfer: download test dir to new location"
);

# Check that the upload/download actually worked: diff the dir structure of the
# local source directory we just uploaded and the one we subsequently
# downloaded...

# ...every path in the source directory used for the test upload...
my @uploaded_list;
find(
    sub {
        return if $_ eq '.';
        push @uploaded_list, $File::Find::name;
    },
    $local_path_to_upload
);

# ...every path in the new directory subsequently downloaded to temp space...
my @downloaded_list;
find(
    sub {
        return if $_ eq '.';

        # Remove leading path of local temporary directory and remote temp dir
        # because we want to compare only the part of the path representing
        # what we downloaded (its *relative* location to the temp dir)...
        (my $path_relative_to_temp) =
            ($File::Find::name =~ m|
                .*?
                $downloaded_dir/
                $remote_smbxfer_dirname/
                (.*)
            |x);
        $path_relative_to_temp =~ s|^/||;

        push @downloaded_list, $path_relative_to_temp;
    },
    "$downloaded_dir/$remote_smbxfer_dirname/$local_path_to_upload"
);

my @uploaded_paths = sort @uploaded_list;
my @downloaded_paths = sort @downloaded_list;

eq_or_diff( \@downloaded_paths, \@uploaded_paths, "uploaded and downloaded dir contents are the same" );

cleanup( $smb, $remote_smbxfer_path_spec );


#~~~~ ((( begin test cleanup ))) ~~~~
sub cleanup {
    my ($smb, $path_spec_to_remove) = @_;

    # Attempt to remove all data created on SMB share for testing...
    if( defined $smb ) {
        $smb->rmdir_recurse( $path_spec_to_remove )
            or die "SMB error during test cleanup: cannot rmdir_recurse: $!";
    }
}
#~~~~ ((( end test initialization ))) ~~~~

