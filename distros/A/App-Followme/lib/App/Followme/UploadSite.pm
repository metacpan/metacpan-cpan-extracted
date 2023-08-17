package App::Followme::UploadSite;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile catdir);

use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "2.03";

use constant SEED => 96;

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            verbose => 0,
            max_errors => 5,
            remote_url => '',
            hash_file => 'upload.hash',
            credentials => 'upload.cred',
            state_directory => '_state',
            data_pkg => 'App::Followme::UploadData',
            upload_pkg => 'App::Followme::UploadFtp',
           );
}

#----------------------------------------------------------------------
# Upload changed files in a directory tree

sub run {
    my ($self, $folder) = @_;

    my ($hash, $local) = $self->get_state();

    my ($user, $pass) = $self->get_word();
    $self->{upload}->open($user, $pass);

    eval {
        chdir($self->{top_directory})
            or die "Can't cd to $self->{top_directory}";

        $self->update_folder($self->{top_directory}, $hash, $local);
        $self->clean_files($hash, $local);
        $self->{upload}->close();

        chdir($folder);
    };

    my $error = $@;
    $self->write_hash_file($hash);

    die $error if $error;
    return;
}

#----------------------------------------------------------------------
# ASK_WORD -- Ask for user name and password if file not found

sub ask_word {
    my ($self) = @_;

    print "\nUser name: ";
    my $user = <STDIN>;
    chomp ($user);

    print "Password: ";
    my $pass = <STDIN>;
    chomp ($pass);

    return ($user, $pass);
}

#----------------------------------------------------------------------
# Delete files on remote site when they are no longer on local site

sub clean_files {
    my ($self, $hash, $local) = @_;

    # Sort files so that files in directories are deleted before
    # their directories are
    my @filenames = sort {length($b) <=> length($a)} keys(%$local);

    foreach my $filename (@filenames) {
        my $flag;
        if ($hash->{$filename} eq 'dir') {
            $flag = $self->{upload}->delete_directory($filename);
        } else {
            $flag = $self->{upload}->delete_file($filename);
        }

        if ($flag) {
            delete $hash->{$filename};
            print "delete $filename\n" if $self->{verbose};

        } else {
            die "Too many upload errors\n" if $self->{max_errors} == 0;
            $self->{max_errors} --;
        }
    }

    return;
}

#----------------------------------------------------------------------
# Get the state of the site, contained in the hash file

sub get_state {
    my ($self) = @_;


    my $hash_file = catfile($self->{top_directory},
                            $self->{state_directory},
                            $self->{hash_file});

    if (-e $hash_file) {
        $self->{target_date} = fio_get_date($hash_file);
    }

    my $hash = $self->read_hash_file($hash_file);
    my %local = map {$_ => 1} keys %$hash;

    return ($hash, \%local);
}

#----------------------------------------------------------------------
# GET_WORD -- Say the secret word, the duck comes down and you win $100

sub get_word {
    my ($self) = @_;

    my $filename = catfile(
                            $self->{top_directory},
                            $self->{state_directory},
                            $self->{credentials}
                           );

    my ($user, $pass);
    if (-e $filename) {
        ($user, $pass) = $self->read_word($filename);
    } else {
        ($user, $pass) = $self->ask_word();
        $self->write_word($filename, $user, $pass);
    }

    return ($user, $pass);
}

#----------------------------------------------------------------------
# Add obfuscation to string

sub obfuscate {
    my ($self, $user, $pass) = @_;

    my $obstr = '';
    my $seed = SEED;
    my $str = "$user:$pass";

    for (my $i = 0; $i < length($str); $i += 1) {
        my $val = ord(substr($str, $i, 1));
        $seed = $val ^ $seed;
        $obstr .= sprintf("%02x", $seed);
    }

    return $obstr;
}

#----------------------------------------------------------------------
# Read the hash for each file on the site from a file

sub read_hash_file {
    my ($self, $filename) = @_;

    my %hash;
    my $page = fio_read_page($filename);

    if ($page) {
        my @lines = split(/\n/, $page);
        foreach my $line (@lines) {
            my ($name, $value) = split (/\t/, $line, 2);
            die "Bad line in hash file: ($name)" unless defined $value;

            $hash{$name} = $value;
        }
    }

    return \%hash;
}

#----------------------------------------------------------------------
# Read the user name and password from a file

sub read_word {
    my ($self, $filename) = @_;

    my $obstr = fio_read_page($filename) || die "Cannot read $filename\n";
    chomp($obstr);

    my ($user, $pass) = $self->unobfuscate($obstr);
    return ($user, $pass);
}

#----------------------------------------------------------------------
# Rewrite the base tag of an html page

sub rewrite_base_tag {
    my ($self, $page) = @_;

    my $base_parser = sub {
        my ($metadata, @tokens) = @_;
       return "<base href=\"$self->{remote_url}\">";
    };

    my $global = 0;
    my $metadata = [];
    my $new_page = web_substitute_tags('<base href="*">',
                                $page,
                                $base_parser,
                                $metadata,
                                $global
                                );

    return $new_page;
}

#----------------------------------------------------------------------
# Initialize the configuration parameters

sub setup {
    my ($self) = @_;

    # Turn off messages when in quick mode
    $self->{verbose} = 0 if $self->{quick_mode};

    # The target date is the date of the hash file, used in quick mode
    # to select which files to test
    $self->{target_date} = 0;

    # Remove any trailing slash from url
    if ($self->{remote_url}) {
        $self->{remote_url} =~ s/\/$//;
    }

    return;
}

#----------------------------------------------------------------------
# Remove obfuscation from string

sub unobfuscate {
    my ($self, $obstr) = @_;

    my $str = '';
    my $seed = SEED;

    for (my $i = 0; $i < length($obstr); $i += 2) {
        my $val = hex(substr($obstr, $i, 2));
        $str .= chr($val ^ $seed);
        $seed = $val;
    }

    return split(/:/, $str, 2);
}

#----------------------------------------------------------------------
# Update an individual file

sub update_file {
    my ($self, $file, $hash) = @_;

    my $local_file = $file;

    # If there is a remote url, rewrite it into a new file
    if ($self->{remote_url}) {

        # Check extension, skip if not a web file
        my ($dir, $basename) = fio_split_filename($file);
        my ($ext) = $basename =~ /\.([^\.]*)$/;
        if ($ext eq $self->{web_extension}) {
            my $page = fio_read_page($file);

            if ($page) {
                $page = $self->rewrite_base_tag($page);
                $local_file = rel2abs(catfile($self->{state_directory}, $basename));
                fio_write_page($local_file, $page);
            }
        }
    }

    # Upload the file and return the status of the upload

    my $status = 0;
    my $remote_file = abs2rel($file, $self->{top_directory});
    if ($self->{upload}->add_file($local_file, $remote_file)) {
        $status = 1;

    } else {
        die "Too many upload errors\n" if $self->{max_errors} == 0;
        $self->{max_errors} --;
    }

    # Remove any temporary file
    unlink($local_file) if $file ne $local_file;
    return $status;
}

#----------------------------------------------------------------------
# Update files in one folder

sub update_folder {
    my ($self, $folder, $hash, $local) = @_;

    my $index_file = $self->to_file($folder);

    # Check if folder is new

    if ($folder ne $self->{top_directory}) {
        $folder = abs2rel($folder, $self->{top_directory});
        delete $local->{$folder} if exists $local->{$folder};

        if (! exists $hash->{$folder} ||
            $hash->{$folder} ne 'dir') {

            if ($self->{upload}->add_directory($folder)) {
                $hash->{$folder} = 'dir';
                print "add $folder\n" if $self->{verbose};

            } else {
                die "Too many upload errors\n" if $self->{max_errors} == 0;
                $self->{max_errors} --;
            }
        }
    }

    # Check each of the files in the directory

    my $files = $self->{data}->build('files', $index_file);

    foreach my $filename (@$files) {
        # Skip check if in quick mode and modification date is old

        if ($self->{quick_update}) {
            next if $self->{target_date} > fio_get_date($filename);
        }

        my $file = abs2rel($filename, $self->{top_directory});
        delete $local->{$file} if exists $local->{$file};

        my $value = ${$self->{data}->build('checksum', $filename)};

        # Add file if new or changed

        if (! exists $hash->{$file} || $hash->{$file} ne $value) {
            if ($self->update_file($filename)) {
                $hash->{$file} = $value;
                print "add $file\n" if $self->{verbose};
            }
        }
    }

    # Recursively check each of the subdirectories

    my $folders = $self->{data}->build('folders', $folder);
    foreach my $subfolder (@$folders) {
        $self->update_folder($subfolder, $hash, $local);
    }

    return;
}

#----------------------------------------------------------------------
# Write the hash back to a file

sub write_hash_file {
    my ($self, $hash) = @_;

    my @hash_list;
    while (my ($name, $value) = each(%$hash)) {
        push(@hash_list, "$name\t$value\n");
    }

    my $filename = catfile($self->{top_directory},
                           $self->{state_directory},
                           $self->{hash_file});

    fio_write_page($filename, join('', @hash_list));

    return;
}

#----------------------------------------------------------------------
# WRITE_WORD -- Write the secret word to a file

sub write_word {
    my ($self, $filename, $user, $pass) = @_;

    my $obstr = $self->obfuscate ($user, $pass);
    fio_write_page($filename, "$obstr\n");
    chmod (0600, $filename);

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::UploadSite - Upload changed and new files

=head1 SYNOPSIS

    my $app = App::Followme::UploadSite->new(\%configuration);
    $app->run($folder);

=head1 DESCRIPTION

This module uploads changed files to a remote site. The default method to do the
uploads is ftp, but that can be changed by changing the parameter upload_pkg.
This package computes a checksum for every file in the site. If the checksum has
changed since the last time it was run, the file is uploaded to the remote site.
If there is a checksum, but no local file, the file is deleted from the remote
site. If this module is run in quick mode, only files whose modification date is
later then the last time it was run are checked.

=head1 CONFIGURATION

The following fields in the configuration file are used:

=over 4

=item credentials

The name of the file which holds the user name and password for the remote site
in obfuscated form. Te default name is 'upload.cred'.

=item hash_file

The name of the file containing all the checksums for files on the site. The
default name is 'upload.hash'.

=item max_errors

The number of upload errors the module tolerate before quitting. The default
value is 5.

=item remote_url

The url of the remote website, e.g. http://www.cloudhost.com.

=item state_directory

The name of the directory containing the credentials and hash file. This
directory name is relative to the top directory of the site. The default
name is '_state'.

=item upload_pkg

The name of the package with methods that add and delete files on the remote
site. The default is L<App::Followme::UploadFtp>. Other packages can be
written, the methods a package must support can be found in
L<App::Followme::UploadNone>.

=item verbose

Print names of uploaded files when not in quick mode

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
