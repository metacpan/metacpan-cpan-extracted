#
# Business::BancaSella::Ris::FileFast
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

package Business::BancaSella::Ris::FileFast;

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

sub remove {
    my ($self,$password) = @_;
    unless ( $self->extract($password) ) {
        die "Unable to find $password in $self->{'file'}";
    }
    return;
}

sub check {
    my ($self,$password) = @_;
    return $self->extract($password,1);
}

#
# verify if a returned password exists
#
# param $merchant_code  the code of the merchant
# param $password       the password returned
#
# return true if the password exists, false elsewhere
# raise an exception 'SYSTEM : description' on file error
#
#
sub extract {
    my ($self,$password,$only_test) = @_;

    unless ( $password =~ /^[a-zA-Z0-9]{32}$/ ) {
        die "PARAMETER. password corrupt\n";
    }

    # open the file
    unless ( open(RESPONSE,"+<$self->{'file'}") ) {
        die "SYSTEM. opening $self->{'file'} : $!\n";
    }

    # lock the file
    my $has_lock = eval { flock(RESPONSE,2) };
    if ( $@ ) {
        #warn "WARNING. this platform don't implements 'flock'\n";
    } elsif ( ! $has_lock ) {
        close(RESPONSE);
        die "SYSTEM. locking $self->{'file'} : $!\n";
    }

    # length of a row of password
    my $row_length = 34;

    # read the size of the file
    my $size_bytes;
    unless ( $size_bytes = (stat(RESPONSE))[7] ) {
        close(RESPONSE);
        if ( $! ne '' ) {
        	die $!;
        } else {
        	die  "EMPTY. file $self->{'file'} is empty\n";
        }
    }
    if ( $size_bytes % $row_length != 0 ) {
        close(RESPONSE);
        die "CORRUPT. dimension of $self->{'file'} is wrong\n";
    }

    # number of passwords in the file
    my $size = $size_bytes/$row_length;

    # range
    my $left = 0;
    my $middle;
    my $right = $size - 1;
    # hash value of the password to search
    my $password_hash = _hash($password);
    # hash values of the range
    my $left_hash = _hash_min();
    my $middle_hash;
    my $right_hash = _hash_max();

    # sign of the read passwords, '-' if used, '+' elsewhere
    my $middle_sign;
    my $passwords_used = 0;

    my $find = 0;
    my $steps = 0;
    my $row;

    while ( $right >= $left ) {

        # increment the steps
        $steps++;

        # the middle position to test
        $middle = $left + int(( ( $password_hash - $left_hash ) * ( $right - $left ))
        / ( $right_hash - $left_hash )); # /

        if ( $_DEBUG ) {
            print STDERR "position : [$left,$middle,$right]\n";
        }

        # seek at the middle
        unless ( seek(RESPONSE,$middle*$row_length,0) ) {
            close(RESPONSE);
            die "SYSTEM.while seek in $self->{'file'}  $!\n";
        }

        # read the password
        unless ( read(RESPONSE,$row,$row_length) ) {
            close(RESPONSE);
            die "SYSTEM. reading $self->{'file'} : $!\n";
        }
        unless ( $row =~ /^([+-])([a-zA-Z0-9]{32})\n$/ ) {
            close(RESPONSE);
            die "CORRUPT. $self->{'file'} corrupted at line ".($middle+1)."\n";
        }
        $middle_sign = $1;
        my $password_middle = $2;
        $middle_hash = _hash($password_middle);

        $passwords_used++ if $middle_sign eq '-';

        # debug information
        if ( $_DEBUG ) {
            print STDERR  "hash : [$left_hash,$middle_hash,$right_hash]\n",
                "password : [?,$password_middle,?]";
        }

        # verify the password
        if ( $password_middle eq $password ) {
            if ( $middle_sign eq '+' ) {
                # first use of the password, set the sign
                unless ( $only_test ) {
                    unless ( seek(RESPONSE,$middle*$row_length,0) ) {
                        close(RESPONSE);
                        die "SYSTEM. while seek in $self->{'file'} : $!\n" }
                    unless ( print RESPONSE '-' ) {
                        close(RESPONSE);
                        die "SYSTEM. writing $self->{'file'} : $!\n";
                    }
                }
                $find = 1;
            }
            # set the range to exit from the search
            $left = $right + 1;
        }
        elsif ( $password gt $password_middle ) {
            # the password is in the right range (middle,right)
            $left = $middle + 1;
            $left_hash = $middle_hash;
        } else {
            # the password is in the left range (left,middle)
            $right = $middle - 1;
            $right_hash = $middle_hash;
        }

    } # end while

    # close the file
    close(RESPONSE);

    # debug information
    print STDERR "Search in $steps steps.\n" if $_DEBUG;

    return $find;
}

#
# create the work copy of a ris file
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
    foreach my $password ( sort @passwords ) {
        unless ( print TARGET "+$password\n" ) {
            close(TARGET);
            unlink($self->{'file'});
            die "SYSTEM. writing file $self->{'file'} at line $line: $!\n";
        }
        $line++;
    }
    close(TARGET);

    return;
}

##
## Private methods
##

#
# calculate a hash of a password
#
# param $password  the password
# return a value in [0,242234] from the first two words of the password
#
sub _hash {
    my ($password) = @_;
    $password =~ /^(\w)(\w)(\w)/;
    return _alf2num($1)*62*62 + _alf2num($2)*62 + _alf2num($3);
}

# return the min hash value
sub _hash_min { 0 }

# return the min hash value
sub _hash_max { 238327 }

#
# calculate a integer from an alfanumeric character
# '0'->0, ... ,'9'->9, 'A'->10, ... ,'Z'->35, 'a'->36, ... ,'z'->61
#
sub _alf2num {
    my $asc = ord($_[0]);
    return ( $asc >= 97 && $asc <= 122 ) ? ( $asc - 61 )
        : (( $asc >= 65 && $asc <= 90 ) ? ( $asc - 55 ) : $asc - 48 );
}

1;
