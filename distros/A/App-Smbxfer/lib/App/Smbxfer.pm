#! /usr/bin/perl

package App::Smbxfer;
our $VERSION = 0.01;

use strict;
use warnings;
use Carp;

use Exporter;
use Getopt::Long;
use IO::Prompt;
use Filesys::SmbClient;

# Exports...
use base qw( Exporter );
our @EXPORT_OK = qw(
    credentials             do_smb_transfer          parse_smb_spec
    create_smb_dir_path     create_local_dir_path    smb_element_type
    smb_upload              smb_download
);

__PACKAGE__->run unless caller;

#######

sub usage {
    qq{
USAGE
    Smbxfer <options> //<server>/<share>[/<path>[/<filename>]] <local-name>
    Smbxfer <options> <local-name> //<server>/<share>[/<path>/<filename>]

}
}

#######

sub options {
    qq{
OPTIONS
    Usage information:
    --usage|help

    Command-line options:
    --options

    Name of file containing credentials (standard smb credentials file):
    --cred <credentials-filename>
    
    Transfer directory <local-name>:
    --recursive

    Create parent directories:
    --parents

}
}

#######

sub run {
    # Process command-line options...
    my ($cred, $recursive, $create_parents, $usage, $options);
    my $options_ok = GetOptions(
        'cred=s'        => \$cred,
        'recursive'     => \$recursive,
        'parents'       => \$create_parents,
        'usage|help'    => \$usage,
        'options'       => \$options,
    );
    die usage unless $options_ok;

    ( defined $usage ) && die usage;
    ( defined $options ) && die options;
    
    my ( $source, $dest ) = @ARGV;
    die usage unless defined $source && defined $dest;
     
    # Ensure that exactly one of source/dest is in "SMB path spec" format...
    ($dest =~ m|^//|) xor ($source =~ m|^//|) or die usage;
    
    # Get access credentials for SMB connection...
    my ($username, $password, $domain) = credentials($cred);
    
    # Prepare SMB connection object...
    my $smb = Filesys::SmbClient->new(
        username => $username, password => $password, workgroup => $domain
    );

    # Determine if source is local (not in "SMB path spec" format)...
    my $source_is_local = ($source !~ m|^//|);

    my ($local_path, $remote_smb_path_spec) = validated_paths(
        SMB => $smb,
        SOURCE => $source,
        DEST => $dest,
        SOURCE_IS_LOCAL => $source_is_local
    );
    
    # Initiate transfer...
    do_smb_transfer(
        SMB_OBJECT =>        $smb,
        LOCAL_PATH =>        $local_path,
        SMB_PATH_SPEC =>     $remote_smb_path_spec,
        SOURCE_IS_LOCAL =>   $source_is_local,
        RECURSIVE =>         $recursive,
        CREATE_PARENTS =>    $create_parents
    );
}

#########################

sub credentials {
    my ($credentials_filename) = @_;

    my ($username, $password, $domain);

    if ($credentials_filename) {
        # Read access credentials from file formatted using standard smbmount
        # syntax...
        open( my $credentials, '<', "$credentials_filename" )
            or croak "cannot open credentials file: $!";
    
        my @lines;
        while( <$credentials> ){
            my ($value) = (m/.*=\s+?(.*)$/);
            push @lines, $value;
        }
        close $credentials;
        ($username, $password, $domain) = @lines;
    }
    else {
        # Getting credentials interactively...
        $username = prompt( "username? " );
        $password = prompt( "password? ", -e => '*' );
        $domain =   prompt( "domain? " );
    }

    return $username, $password, $domain;
}

#########################

sub validated_paths {
    my %param = @_;

    my $smb =               $param{SMB}     or croak "SMB object required";
    my $source =            $param{SOURCE};
    my $dest =              $param{DEST};
    my $source_is_local =   $param{SOURCE_IS_LOCAL};

    defined $source          or croak "Source path required";
    defined $dest            or croak "Destination path required";
    defined $source_is_local or croak "SOURCE_IS_LOCAL param required";

    # Ensure that exactly one of source/dest is in "SMB path spec" format...
    ($dest =~ m|^//|) xor ($source =~ m|^//|)
        or croak 'source OR destination must be in "SMB path spec" format';
    
    my ($local_path, $remote_smb_path_spec) = ($source, $dest);
    ($local_path, $remote_smb_path_spec) = ($dest, $source) unless $source_is_local;

    # Normalize form of local and remote paths...
    $local_path =~ s|//|/|g;
    $local_path =~ s|/$||;
    $remote_smb_path_spec =~ s|^/+||;  # temporarily remove valid leading '//'
    $remote_smb_path_spec =~ s|//|/|g;
    $remote_smb_path_spec =~ s|/$||;   # no trailing slash
    $remote_smb_path_spec = 'smb://' . $remote_smb_path_spec;

    # Find type of remote element...
    my $remote_element_type = smb_element_type( $smb, $remote_smb_path_spec )
        or croak "Error: SMB specification $remote_smb_path_spec not found";

    # Check types of source and destination...
    my ($source_is_dir, $dest_is_dir_or_nonexistent);
    if( $source_is_local ) {
        croak "Error: local source $source is not a file or a directory"
            unless( -f $source or -d $source );
        $source_is_dir = -d $source;
        $dest_is_dir_or_nonexistent = 1 unless defined $remote_element_type;
        # Consider file shares to be directories for purposes of file transfer...
        $dest_is_dir_or_nonexistent = 1 if $remote_element_type == SMBC_DIR or $remote_element_type == SMBC_FILE_SHARE;
    }
    else {
        croak "Error: SMB source $source is not a file or a directory"
            unless( $remote_element_type == SMBC_FILE or $remote_element_type == SMBC_DIR );
        $source_is_dir = ( $remote_element_type == SMBC_DIR );
        $dest_is_dir_or_nonexistent = (not -e $dest or -d $dest);
    }

    # If source is a dir, any existing dest must also be a dir...
    croak "Error: when transferring a directory source, any existing destination must also be a directory"
        if( $source_is_dir and not $dest_is_dir_or_nonexistent );

    return $local_path, $remote_smb_path_spec;
}

#########################

sub do_smb_transfer {
    my %param = @_;

    my $smb =                                 $param{SMB_OBJECT}        or croak "SMB object required";
    my $local_path =                          $param{LOCAL_PATH}        or croak "local path required";
    my $smb_path_spec =                       $param{SMB_PATH_SPEC}     or croak "remote SMB path specification required";
    my $source_is_local =                     $param{SOURCE_IS_LOCAL};
    my $recursive =                           $param{RECURSIVE};
    my $create_parents =                      $param{CREATE_PARENTS};

    # Create leading directories of destination path if requested...
    if( $create_parents ) {
        my ($smb_parent_path) = ( parse_smb_spec( $smb_path_spec ) )[2];

        if( $source_is_local ) {
            # Create remote SMB path to hold local source...
            my ($local_path_parent_dirs) = ( $local_path =~ m|/?(.*)/[^/]+/?$| );

            my $element_type = smb_element_type( $smb, $smb_path_spec );
            unless( $element_type == SMBC_DIR or $element_type == SMBC_FILE_SHARE ) {
                die "Error: destination must be a directory with --parents option.";
            }
            create_smb_dir_path( $smb, $smb_path_spec, $local_path_parent_dirs );

            # postfix destination path with parent dirs we just created from source...
            $smb_path_spec .= '/' . $local_path_parent_dirs;
        }
        else {
            # Create local path to hold remote SMB source...
            unless( -d $local_path ) {
                die "Error: destination must be a directory with --parents option.";
            }
            create_local_dir_path( $local_path, $smb_parent_path );

            # postfix destination path with parent dirs we just created from source...
            $local_path .= '/' . $smb_parent_path;
        }
    }

    my $rc = 0;
    if( $source_is_local ) {
        # Transfer: local -> remote...
        $rc = smb_upload(
            SMB_OBJ => $smb,
            SOURCE => $local_path,
            SMB_PATH_SPEC => $smb_path_spec,
            RECURSIVE => $recursive
        );
    }
    else {
        # Transfer: remote -> local...
        $rc = smb_download(
            SMB_OBJ => $smb,
            SMB_PATH_SPEC => $smb_path_spec,
            LOCAL_DEST_NAME => $local_path,
            RECURSIVE => $recursive
        );
    }

    return $rc;
}

#########################

sub parse_smb_spec {
    my ($path) = @_;

    my ($server, $share);
    ($server, $share, $path) =
        ($path =~ m|
            //([\w\.]+)        # //server
            /(\w+)             #         /share
            /?(.+)?            #               /path/to/something
        |x);

    # Path spec is invalid...
    return unless $server && $share;

    my ($share_spec, $parent_path, $path_spec, $parent_path_spec, $basename);

    $share_spec = "smb://$server/$share/";
    $path_spec = $share_spec;
    $parent_path_spec = $share_spec;

    if( defined $path ) {
        ($parent_path) = ( $path =~ m|(.*/)[^/]+/?$| );
        $path_spec .= $path;
        $parent_path_spec .= $parent_path if $parent_path;
        ($basename) = ($path =~ m|([^/]*)$| );
    }

    return $server, $share, $parent_path, $path,
           $share_spec, $path_spec, $parent_path_spec,
           $basename;
}


#########################

sub create_smb_dir_path {
    my ( $smb, $smb_path_spec_prefix, $path_to_create ) = @_;

    my ($root, $remaining_path) =
        ($path_to_create =~ m|
            ^/?         # optional leading '/'
            ([^/]+?)    # 1st capture: anything but dir separators
            (/.*)?      # 2nd capture (optional): separator followed by dir names with separators
            /?$         # optional trailing '/'
        |x);

    if( $root ) {
        $smb->mkdir( $smb_path_spec_prefix . '/' . $root, '0666' )
            or croak "SMB error: cannot mkdir $smb_path_spec_prefix/$root: $!";
    }
    else {
        # We were called without a valid path to create...
        return;
    }

    if( $remaining_path ) {
        create_smb_dir_path( $smb, $smb_path_spec_prefix . '/' . $root, $remaining_path );
    }

    return 1;
}

#########################

sub create_local_dir_path {
    my ( $local_prefix, $path_to_create ) = @_;

    my ($root, $remaining_path) =
        ($path_to_create =~ m|
            ^/?         # optional leading '/'
            ([^/]+?)    # 1st capture: anything but dir separators
            (/.*)?      # 2nd capture (optional): separator followed by dir names with separators
            /?$         # optional trailing '/'
        |x);

    if( $root ) {
        mkdir( $local_prefix . '/' . $root ) or croak "cannot mkdir $root: $!";
    }
    else {
        # We were called without a valid path to create...
        return;
    }

    if( $remaining_path ) {
        create_local_dir_path( $local_prefix . '/' . $root, $remaining_path );
    }

    return 1;
}

#########################

sub smb_element_type {
    my ($smb, $smb_path_spec) = @_;

    my ($share_name, $smb_parent_path, $smb_path, $smb_share_spec,
    $smb_basename) = ( parse_smb_spec( $smb_path_spec ) )[1,2,3,4,7];

    my $base_type;
    if( $smb_path ) {
        if( $smb_basename ) {
            # Look in parent directory for base of path and find type of base
            my $parent = $smb_share_spec;
            $parent .= $smb_parent_path if $smb_parent_path;
            my $smb_fd = $smb->opendir( $parent )
                or croak "SMB error: cannot opendir: $!";

            while( my $share_root_item = $smb->readdir_struct( $smb_fd ) ) {
                if( lc $share_root_item->[1] eq lc $smb_basename ) {
                    $base_type = $share_root_item->[0];
                    last;
                }
            }
            $smb->closedir( $smb_fd );
        }
        else {
            # Path does not have multiple levels...
            # Open root dir of share and look for path...
            my $smb_fd = $smb->opendir( $smb_share_spec )
                or croak "SMB error: cannot opendir: $!";

             while( my $share_root_item = $smb->readdir_struct( $smb_fd ) ) {
                if( lc $share_root_item->[1] eq lc $smb_path ) {
                    $base_type = $share_root_item->[0];
                    last;
                }
            }
            $smb->closedir( $smb_fd );
        }
    }
    elsif( $smb_share_spec ) {
        # No path given; does the given SMB spec identify a file share?
        my ($server) = ( $smb_share_spec =~ m|smb://([^/]+)/| );
        my $smb_fd = $smb->opendir( "smb://$server/" )
            or croak "SMB error: cannot opendir: $!";
        while( my $share = $smb->readdir_struct( $smb_fd ) ) {
            if( lc $share->[1] eq lc $share_name ) {
                $base_type = $share->[0];
                last;
            }
        }
    }
    else {
        croak "SMB specification $smb_path_spec not found";
    }

    # Element not found...
    return if not defined $base_type;

    return $base_type;
}

#########################

sub smb_download {
    my %param = @_;

    my $smb =               $param{SMB_OBJ} or croak "Filesys::SmbClient object required for download";
    my $src_smb_path_spec = $param{SMB_PATH_SPEC} or croak "SMB path specification of source required to download";
    my $local_dest_name =   $param{LOCAL_DEST_NAME};
    my $recursive =         $param{RECURSIVE};

    my ($src_smb_path, $src_basename) =
        (parse_smb_spec( $src_smb_path_spec ))[3,7];

    my $elem_type = smb_element_type( $smb, $src_smb_path_spec );

    if( $elem_type == SMBC_DIR ) {
        # Download directory...
        unless( $recursive ) {
            print "Omitting directory $src_smb_path in non-recursive mode.\n";
            return;
        }
        else {
            # Create dir at destination...
            mkdir( $local_dest_name . '/' . $src_basename )
                or croak "cannot mkdir: $!";
        }

        my $smb_fd = $smb->opendir( $src_smb_path_spec )
            or croak "SMB error: cannot opendir: $!";
    
        while( my $smb_elem = $smb->readdir( $smb_fd ) ) {
            next if $smb_elem =~ /^\.{1,2}$/;     # skip . and ..
            smb_download(
                SMB_OBJ => $smb,
                SMB_PATH_SPEC => $src_smb_path_spec . '/' . $smb_elem,
                LOCAL_DEST_NAME => $local_dest_name . '/' . $src_basename,
                RECURSIVE => 1,
            );
        }
        $smb->closedir( $smb_fd );
    }
    elsif( $elem_type == SMBC_FILE ) {
        # Download file...

        # If destination is a dir then file goes inside it...
        $local_dest_name .= '/' . $src_basename if( -d $local_dest_name );

        open( my $localfile, '>', $local_dest_name )
            or croak "cannot open file: $!";
        
        my $smb_fd = $smb->open( $src_smb_path_spec )
            or croak "SMB error: cannot open: $!";

        while( my $buf = $smb->read( $smb_fd ) ) {
            print $localfile $buf;
        }

        $smb->close( $smb_fd );
        close( $localfile );
    }
    else {
        warn "$src_basename is not a directory or a file...ignoring.\n";
    }

    return 1;
}

#########################

sub smb_upload {
    my %param = @_;

    my $smb =               $param{SMB_OBJ}         or croak "Filesys::SmbClient object required for upload";
    my $local_src =         $param{SOURCE}          or croak "Name of local file or directory required for upload";
    my $smb_path_spec =     $param{SMB_PATH_SPEC}   or croak "SMB path specification of destination required for upload";
    my $recursive =         $param{RECURSIVE};

    my $elem_type = smb_element_type( $smb, $smb_path_spec );
    my ($src_basename) = ($local_src =~ m|([^/]*)$| );

    if( -d $local_src ) {
        # Upload directory...
        unless( $recursive ) {
            print "Omitting directory $local_src in non-recursive mode.\n";
            return;
        }
        else {
            # Create dir at destination...
            $smb->mkdir( $smb_path_spec . '/' .  $src_basename, '0666' )
                or croak "SMB error: cannot mkdir: $!";
        }

        opendir( my $local_dir, $local_src )
            or croak "cannot opendir: $!";

        while ( my $local_dir_elem = readdir( $local_dir ) ) {
            next if $local_dir_elem =~ /^\.{1,2}$/;     # skip . and ..

            smb_upload(
                SMB_OBJ => $smb,
                SOURCE => $local_src . '/' . $local_dir_elem,
                SMB_PATH_SPEC => $smb_path_spec . '/' . $src_basename,
                RECURSIVE => 1
            );
        }
        closedir( $local_dir );
    }
    elsif( -f $local_src ) {
        # Upload file...
        
        if( $elem_type == SMBC_FILE ) {
            # Destination is an existing file; remove file remotely...
            $smb->unlink( $smb_path_spec )
                or croak "SMB error: cannot unlink: $!";
        }
        elsif( $elem_type == SMBC_DIR ) {
            # Destination is an existing dir => file goes inside it...
            $smb_path_spec .= '/' . $src_basename;
        }

        open( my $sourcefile, '<', $local_src )
            or croak "cannot open file: $!";
    
        my $smb_fd = $smb->open('>' . $smb_path_spec, '0777')
            or croak "SMB error: cannot create file: $!";
    
        $smb->write( $smb_fd, $_ ) while( <$sourcefile> );
    
        $smb->close( $smb_fd );
        close( $sourcefile );
    }
    else {
        warn "$local_src is not a directory or a file...ignoring.\n";
    }

    return 1;
}

#########################
1;

__END__

=pod

=head1 NAME

App::Smbxfer - A "modulino" (module/program hybrid) for file
transfer between Samba shares and the local filesystem.


=head1 MODULINO: MOTIVATION AND DESCRIPTION

This software provides a subset of the features of smbclient.  The main
motivation for its existence was a limitation in smbclient causing a timeout
that precluded transfer of large files.

An especially useful way to apply this modulino is to invoke it as a
non-interactive command-line tool.  This can be an effective way to create cron
jobs for backup of data TO Samba shares.

As a module, it provides functions to conduct file transfers, get information on
Samba filesystem objects, and to perform validations on "SMB path specs," Samba
location identifiers of the form:

    smb://server/share/path/to/something


=head1 VERSION

This documentation refers to App::Smbxfer version 0.01.


=head1 MODULE: FUNCTIONS

Functions in App::Smbxfer are used to aid with transferring files between Samba
shares and the local filesysem.  This is the context in which the following
functions are provided.

=head2 usage

Prints command-line usage information.

=head2 options

Prints command-line options.

=head2 run

"main() method" for running module as a command-line program.

=head2 credentials

    my ($username, $password, $domain) = credentials( $credentials_file );

Load SMB access credentials from the specified filename, which should be
formatted as expected by the smb* suite of tools (smbclient, etc.)

=head2 validated_paths

    my ($local_path, $remote_smb_path_spec) = validated_paths(
        SMB => $smb,
        SOURCE => $source,
        DEST => $dest,
        SOURCE_IS_LOCAL => $whether_or_not_source_is_local_path
    );

Given source, destination paths as expected by modulino's run()
function, performs validations and returns normalized forms of both paths in
order (source, dest).

=head2 do_smb_transfer

    do_smb_transfer(
        SMB_OBJECT =>        $smb,
        LOCAL_PATH =>        $local_path,
        SMB_PATH_SPEC =>     $remote_smb_path_spec,
        SOURCE_IS_LOCAL =>   $whether_or_not_source_is_local_path,
        RECURSIVE =>         1,
        CREATE_PARENTS =>    1
    );

Handles setup for upload/download, then delegates responsibility for file
transfer to the appropriate handler.

=head2 parse_smb_spec

    my ($smb_parent_path, $smb_path, $smb_share_spec) =
        ( parse_smb_spec( $smb_path_spec ) )[2,3,4];

Given a Samba location identifier with optional leading 'smb:', returns a
number of potentially useful pieces of the path (server, share, path name,
basename, etc.).

The following are returned (in order):

=over

=item 0

Server

=item 1

Share

=item 2

Parent path

=item 3

Path

=item 4

Share spec

=item 5

Path spec

=item 6

Parent path spec

=item 7

Basename

=back

=for Enhancement
    cleanup to fix returning a long list of variables?

=cut

=head2 create_smb_dir_path 

    create_smb_dir_path( $smb, $smb_path_spec_prefix, $path_to_create );

Creates directories on the Samba share leading up to and including the given
directory path.  The path created is rooted at the specified SMB path spec
prefix, which should represent an existing directory node in the Samba share
filesystem.

=head2 create_local_dir_path 

    create_local_dir_path( $local_prefix, $path_to_create );

Creates directories on the local filesystem leading up to and including the
given directory path.  The path created is rooted at the specified prefix path,
which should represent an existing directory node in the local filesystem.

=head2 smb_element_type

    my $remote_element_type = smb_element_type( $smb, $smb_path_spec );

Find the 'type' (file, dir, etc.) of an SMB element given its path spec.  If
the element itself does not exist, an undefined value is returned.

=head2 smb_download 

    smb_download(
        SMB_OBJ => $smb,
        SMB_PATH_SPEC => $smb_path_spec,
        LOCAL_DEST_NAME => $local_path,
        RECURSIVE => 0
    );
    
Download a file from a Samba network share to the local filesystem.

=head2 smb_upload 

        smb_upload(
            SMB_OBJ => $smb,
            SOURCE => $local_path,
            SMB_PATH_SPEC => $smb_path_spec,
            RECURSIVE => 1
        );

Upload a file from the local filesystem to a Samba network share.


=head1 PROGRAM: USAGE

  USAGE
    Smbxfer <options> //<server>/<share>[/<path>[/<filename>]] <local-name>
    Smbxfer <options> <local-name> //<server>/<share>[/<path>/<filename>]


  OPTIONS
    Usage information:
    --usage|help

    Command-line options:
    --options

    Name of file containing credentials (standard smb credentials file):
    --cred <credentials-filename>
    
    Transfer directory <local-name>:
    --recursive

    Create parent directories:
    --parents


=head1 PROGRAM: REQUIRED ARGUMENTS

As in the 'cp' command, two arguments are required: the source and the
destination, in that order.


=head1 PROGRAM: OPTIONS

This program can be given an option, '--cred', that specifies the path to a
filename containing Samba access credentials, explained in the CONFIGURATION AND
ENVIRONMENT section.
   
For recursive transfers, the '--recursive' flag is supported.  The '--parents'
flag causes the entire directory structure from the source path argument to be
replicated at the destination.  If the source path argument is a relative path,
only the dirs in the path as specified will be created at the destination.  For
the entire path from root to be created, specify an absolute path for the
source path.

For usage and options information, try ('--usage' or '--help') and
'--options', respectively.


=head1 PROGRAM: DIAGNOSTICS

=over

=item C<< Invalid options! >>

Command-line options were not recognized.  C<< --usage >> and C<< --options >> provide
succinct information to resolve.


=item C<< cannot open credentials file: ... >>

The specified Samba access credentials file could not be opened.


=item C<< Error: SMB specification F< smb path spec > not found >>

Could not connect to the indicated Samba server/share/path.


=item C<< source OR destination must be in "SMB path spec" format >>

Exactly one of the source and destination must be formatted in "SMB path
specification" format: '//<server>/<share>[/<path>]'


=item C<< Error: local source F< source > is not a file or a directory >>

Only files or directories may be uploaded to a Samba server.


=item C<< Error: SMB source F< source > is not a file or a directory >>

Only files or directories may be downloaded from a Samba server.


=item C<< Error: when transferring a directory source, any existing destination
must also be a directory >>

An directory was specified as the source for a transfer and a file was specified
as the destination.


=item C<< Error: destination must be a directory with --parents option. >>

When using --parents to replicate parent directory structures, the destination
must be a directory, not some existing file (since replication of directory
structures implies restrictions on the location of the target file).


=item C<< Omitting directory $src_smb_path in non-recursive mode. >>

The --recursive option must be used for directory transfers.


=item C<< F< path > is not a directory or a file...ignoring. >>

Only files or directories can be uploaded or downloaded using smb_upload() or
smb_download().


=item C<< cannot open file: ... >>

Local OS error while trying to open a file.


=item C<< cannot mkdir F< path >: ... >>

Local OS error while trying to create a directory.


=item C<< SMB error: cannot create file: ... >>

Remote Samba error while trying to create a file.


=item C<< SMB error: cannot mkdir F< path >: ... >>

Remote Samba error while trying to create a directory.


=item C<< SMB error: cannot opendir: ... >>

Remote Samba error while trying to open a directory.


=item C<< SMB error: cannot unlink: ... >>

Remote Samba error while trying to delete a file.


=back


=head1 PROGRAM: CONFIGURATION AND ENVIRONMENT

The credentials file that can be used via the '--cred' option should be in the
same format used by smbclient.  This file looks as follows:

    username = <username>
    password = <password>
    domain = <domain>
 

=head1 PROGRAM: NON-TRIVIAL DEPENDENCIES

Filesys::SmbClient

IO::Prompt


=head1 PROGRAM: INCOMPATIBILITIES

No known incompatibilities.


=head1 BUGS AND LIMITATIONS

No known bugs.  Please report problems to Karl Erisman
(kerisman@cpan.org).  Patches are welcome.


=head1 AUTHOR

Karl Erisman (kerisman@cpan.org)


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Karl Erisman (kerisman@cpan.org).  All rights
reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.


=head1 SCRIPT CATEGORIES

Networking

UNIX/System_Administration

Win32

=cut
