#
# Business::BancaSella::Ric::FileFast
#
# author       : Marco Gazerro <gazerro@open2b.com>
# initial date : 06/02/2001 ( originally in Open2b, www.open2b.com )
#
# version      : 0.11
# date         : 11/01/2002
#
# Copyright (c) 2001-2002 Marco Gazerro, Mauro Fedele
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Business::BancaSella::Ric::FileFast;

$VERSION = '0.11';
sub Version { $VERSION }

require 5.004;

use strict;

my $_DEBUG = 0;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    return $self->init(@_);
}

sub init {
    my ($self,%options) = @_;
    if ( $options{'file'} eq '' ) {
        die "You must declare file in " . ref($self) . "::new";
    }
    $self->{'file'} = $options{file};
    return $self;
}

sub file {
    my ($self,$value) = @_;
    $self->{'file'} = $value if defined $value;
    return $self->{'file'};
}

#
# extract a password from the ric file
#
# return the password extracted
# raise an exception 'SYSTEM. description' on I/O error
# raise an exception 'CORRUPT. description' if the file is corrupted
#
sub extract {
    my $self = shift;

    my $password;

    # open the file
    open(REQUEST,"+<$self->{'file'}")
        || die "SYSTEM. opening $self->{'file'} : $!\n";

    eval {

        # lock the file
        my $has_lock = eval { flock(REQUEST,2) };
        if ( $@ ) {
            warn "WARNING. this platform don't implements 'flock'\n";
        } elsif ( ! $has_lock ) {
            die "SYSTEM. locking $self->{'file'} : $!\n";
        }

        # length of a row of password
        my $row_length = 33;

        my $size_bytes;
        unless ( $size_bytes = (stat(REQUEST))[7] ) {
            die (( $! ) ? $! : "EMPTY : the file $self->{'file'} is empty\n" );
        }
        if ( $size_bytes % $row_length != 0 ) {
            die "CORRUPT. dimension of $self->{'file'} is wrong\n";
        }

        # number of passwords in the file
        my $size = $size_bytes / $row_length;

        # read the last password
        my $row;
        seek(REQUEST,($size-1)*$row_length,0)
            || die "SYSTEM. while seek in $self->{'file'} : $!\n";

        read(REQUEST,$row,$row_length) || die "SYSTEM. reading $self->{'file'} : $!\n";

        unless ( $row =~ /^([a-zA-Z0-9]{32})\n$/ ) {
            die "CORRUPT. file $self->{'file'} corrupted at last line\n";
        }
        $password = $1;

        # delete the last password
        my $is_truncate = eval { truncate(REQUEST,($size-1)*$row_length) };
        if ( $@ ) {
            die "SYSTEM. the 'truncate' function is not implemented on this platform!\n";
        }
        unless ( $is_truncate ) {
            die "SYSTEM. while truncate $self->{'file'} : $!\n";
        }

    }; # end eval

    my $error = $@;

    # close the file
    close(REQUEST);

    # die on error
    die $error if $error;

    # return the password
    return $password;
}

#
# create the work copy of a ric file
#
# return nothing
# raise an exception on error
#
sub prepare {
    my ($self,$source_file) = @_;

    # read the passwords
    open(SOURCE,"<$source_file") || die "SYSTEM. opening $source_file : $!\n";
    my @rows = <SOURCE>;
    if ( $! ) {
        die "SYSTEM. reading $source_file : $!\n";
    }
    close(SOURCE) || die "SYSTEM. closing $source_file : $!\n";

    # verify the passwords
    my @passwords = ();
    my $line = 1;
    foreach my $row ( @rows ) {
        unless ( $row =~ /^([a-zA-Z0-9]{32})\n+$/ ) {
            die "CORRUPT. file $source_file corrupted at line $line\n";
        }
        push @passwords, ($1);
    }

    # write the passwords
    open(TARGET,"+>$self->{'file'}") || die "SYSTEM. opening $self->{'file'} : $!\n";
    binmode(TARGET);
    $line = 1;
    foreach my $password ( @passwords ) {
        unless ( print TARGET "$password\n" ) {
            close(TARGET);
            unlink($self->{'file'});
            die "SYSTEM. writing file $self->{'file'} at line $line: $!\n";
        }
        $line++;
    }
    close(TARGET);

    return;
}

1;
