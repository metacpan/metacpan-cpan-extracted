package CPAN::Unpack;
use strict;
use warnings;
use Archive::Extract;
use Fcntl qw(:mode);
use File::Basename qw(basename);
use File::Find;
use File::Path;
use Parse::CPAN::Packages::Fast;
use YAML::Any ();
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(cpan destination quiet));
$Archive::Extract::PREFER_BIN = 1;

our $VERSION = '0.31';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub unpack {
    my $self    = shift;
    my $counter = 0;

    my $cpan = $self->cpan;
    die "No $cpan" unless -d $cpan;

    my $destination = $self->destination;
    mkdir $destination;
    die "No $destination" unless -d $destination;

    my $packages_filename = "$cpan/modules/02packages.details.txt.gz";
    die "No packages at $packages_filename" unless -f $packages_filename;

    my %unpacked_versions;
    if ( -e "$destination/unpacked_versions.yml" ) {
        local $/;
        open( my $fh, "<", "$destination/unpacked_versions.yml" );
        %unpacked_versions = %{ YAML::Any::Load(<$fh>) };
        close $fh;
    }

    sub fixme {
        my $path = $_;
        my $mode = ( stat($path) )[2];
        if ( S_ISDIR($mode) ) {
            chmod( ( S_IMODE($mode) | S_IRWXU ), $path )
                unless ( ( $mode & S_IRWXU ) == S_IRWXU );
        }
    }
    my $p = Parse::CPAN::Packages::Fast->new($packages_filename);
    foreach my $distribution ( $p->latest_distributions ) {
        $counter++;
        my $want             = "$destination/" . $distribution->dist;
        my $archive_filename = "$cpan/authors/id/" . $distribution->prefix;

        unless ( -f $archive_filename ) {
            warn "Archive $archive_filename not found";
            next;
        }

        my $unpacked = $unpacked_versions{ $distribution->dist };

        if ( !defined( $distribution->version ) ) {

       # This is a bug in Parse::CPAN::Packages (and ::Fast). It affects a few
       # dozen packages, so use the mtime as version
            $unpacked_versions{ $distribution->dist }
                = "x" . ( stat $archive_filename )[9];
        } else {
            $unpacked_versions{ $distribution->dist }
                = "x" . $distribution->version;
        }

        if ( defined($unpacked)
            && $unpacked eq $unpacked_versions{ $distribution->dist } 
            && -d $want )
        {
            next;
        }

        if ( -d $want ) {
            print "Deleting old version of " . $distribution->dist . "\n"
                unless $self->quiet;
            rmtree $want;
        }

        print "Unpacking " . $distribution->prefix . " ($counter)\n"
            unless $self->quiet;

        my $extract = Archive::Extract->new( archive => $archive_filename );
        my $to = "$destination/test";
        rmtree($to);
        mkdir($to);
        $extract->extract( to => $to );

        # Fix up broken permissions
        File::Find::find( { wanted => \&fixme, follow => 0, no_chdir => 1 },
            $to );

        my @files = <$to/*>;
        my $files = @files;
        if ( $files == 1 ) {
            my $file = $files[0];
            if ( S_ISDIR( ( stat( $file ) )[2] ) ) {
                rename $file, $want;
            } else {
                mkdir $want;
                rename $file, "$want/" . basename($file);
            }
            rmdir $to;
        } else {
            rename $to, $want;
        }

        unless ( $counter % 500 ) {

           # Write this every now and then to prevent ^C from killing the list
            open( my $fh, ">", "$destination/unpacked_versions.yml.tmp" );
            print $fh YAML::Any::Dump( \%unpacked_versions );
            close $fh;
            rename "$destination/unpacked_versions.yml.tmp",
                "$destination/unpacked_versions.yml";
        }
    }

    open( my $fh, ">", "$destination/unpacked_versions.yml.tmp" );
    print $fh YAML::Any::Dump( \%unpacked_versions );
    close $fh;
    rename "$destination/unpacked_versions.yml.tmp",
        "$destination/unpacked_versions.yml";
}

__END__

=head1 NAME

CPAN::Unpack - Unpack CPAN distributions

=head1 SYNOPSIS

  use CPAN::Unpack;
  my $u = CPAN::Unpack->new;
  $u->cpan("path/to/CPAN/");
  $u->destination("cpan_unpacked/");
  $u->quiet(1);
  $u->unpack;

=head1 DESCRIPTION

The Comprehensive Perl Archive Network (CPAN) is a very useful
collection of Perl code. It has a whole lot of module
distributions. This module unpacks the latest version of each
distribution. It places it in a directory of your choice with
directories being the name of the distribution.

It requires a local CPAN mirror to run. You can construct one using
something similar to:

  /usr/bin/rsync -av --delete ftp.nic.funet.fi::CPAN /Users/acme/cpan/CPAN/

Note that a CPAN mirror can take up about 1.5G of space (and will take
a while to rsync initially). Additionally, unpacking will use up about
another 1.6G.

This can be handy for code metrics, searching CPAN, or just being very
nosy indeed.

This uses Parse::CPAN::Packages::Fast's latest_distributions method for
finding the latest distribution.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004-8, Leon Brocard
              2012, Dennis Kaarsemaker

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
