#!/usr/bin/env perl

use Catmandu::BagIt;
use File::Find;
use File::Spec;
use Getopt::Long;
use Carp;

my $algorithm = 'sha512';
my $version   = '1.0';
my $replace;

GetOptions(
    "a|algorithm=s" => \$algorithm,
    "v|version=s"   => \$version,
    "replace"       => \$replace,
    "append"        => \$append
);

my $command = shift;

usage() unless $command;

if (0) {}
elsif ($command eq 'addinfo') {
    &cmd_addinfo(@ARGV);
}
elsif ($command eq 'removeinfo') {
    &cmd_removeinfo(@ARGV);
}
elsif ($command eq 'create') {
    &cmd_create(@ARGV);
}
elsif ($command eq 'read') {
    &cmd_read(@ARGV);
}
elsif ($command eq 'holey') {
    &cmd_holey(@ARGV);
}
elsif ($command eq 'complete') {
    &cmd_complete(@ARGV);
}
elsif ($command eq 'valid') {
    &cmd_valid(@ARGV);
}
else {
    usage();
}

sub usage {
    print STDERR <<EOF;
usage: $0 addinfo|complete|create|holey|read|removeinfo|valid

 addinfo [--replace] directory NAME VALUE
 complete directory
 create directory
 holey directory
 read directory
 removeinfo directory NAME
 valid directory
EOF
    exit(1);
}

sub cmd_addinfo {
    my ($directory,$tag,$value) = @_;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    if ($replace) {
        $bagit->remove_info($tag);
    }

    $bagit->add_info($tag,$value);

    unless ($bagit->locked) {
        $bagit->write($directory, overwrite => 1);
    }

    if ($bagit->errors) {
        print STDERR join("\n",$bagit->errors);
        exit 2;
    }
}

sub cmd_removeinfo {
    my ($directory,$tag,$value) = @_;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    $bagit->remove_info($tag);

    unless ($bagit->locked) {
        $bagit->write($directory, overwrite => 1);
    }

    if ($bagit->errors) {
        print STDERR join("\n",$bagit->errors);
        exit 2;
    }
}

sub cmd_create {
    my ($directory) = shift;

    my @files = ();
    find(sub {
        push @files , $File::Find::name ;
    }, $directory);

    my $bagit = Catmandu::BagIt->new(algorithm => $algorithm, version => $version);

    my $cdirectory = File::Spec->canonpath($directory);

    for my $path (@files) {
        next unless -f $path;
        my $cpath = substr(File::Spec->canonpath($path),length($cdirectory) + 1);
        $bagit->add_file($cpath, IO::File->new($path));
        print "$cpath <-- $path\n";
    }

    if ($bagit->errors) {
        print STDERR join("\n",$bagit->errors);
        exit 2;
    }

    unless ($bagit->locked) {
        $bagit->write($directory, overwrite => 1);
    }
}

sub cmd_read {
    my ($directory) = shift;

    croak "No such directory: $directory" unless -d $directory;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    printf "path: %s\n", $bagit->path;
    printf "version: %s\n"  , $bagit->version;
    printf "encoding: %s\n" , $bagit->encoding;

    printf "tags:\n";
    for my $tag ($bagit->list_info_tags) {
        my @values = $bagit->get_info($tag);
        for my $value (@values) {
            printf " - $tag: \"%s\"\n" , $value;
        }
    }

    printf "tag-sums:\n";
    for my $file ($bagit->list_tagsum) {
        my $sum = $bagit->get_tagsum($file);
        printf " $file: %s\n" , $sum;
    }

    printf "file-sums:\n";
    for my $file ($bagit->list_checksum) {
        my $sum = $bagit->get_checksum($file);
        printf " $file: %s\n" , $sum;
    }

    printf "files:\n";
    for my $file ($bagit->list_files) {
        my $stat = [stat($file->path)];
        printf "  -";
        printf " name: %s\n", $file->filename;
        printf "    size: %d\n", $stat->[7];
        printf "    last-mod: %s\n", scalar(localtime($stat->[9]));
    }
}

sub cmd_holey {
    my ($directory) = shift;

    croak "No such directory: $directory" unless -d $directory;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    if ($bagit->is_holey) {
        print "$directory is holey\n";
        exit 0;
    }
    else {
        print "$directory is not holey!\n";
        if ($bagit->errors) {
            print STDERR join("\n",$bagit->errors);
        }
        exit 2;
    }
}

sub cmd_complete {
    my ($directory) = shift;

    croak "No such directory: $directory" unless -d $directory;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    if ($bagit->complete) {
        print "$directory is complete\n";
        exit 0;
    }
    else {
        print "$directory is not complete!\n";
        if ($bagit->errors) {
            print STDERR join("\n",$bagit->errors);
        }
        exit 2;
    }
}

sub cmd_valid {
    my ($directory) = shift;

    croak "No such directory: $directory" unless -d $directory;

    my $bagit = Catmandu::BagIt->read($directory);

    unless ($bagit) {
        print STDERR "$directory is not a bag\n";
        exit(2);
    }

    if ($bagit->valid) {
        print "$directory is valid\n";
        exit 0;
    }
    else {
        print "$directory is not valid!\n";
        if ($bagit->errors) {
            print STDERR join("\n",$bagit->errors);
        }
        exit 2;
    }
}
