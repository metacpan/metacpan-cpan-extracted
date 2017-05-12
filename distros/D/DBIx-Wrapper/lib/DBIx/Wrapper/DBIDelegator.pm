# Creation date: 2005-10-16 20:42:19
# Authors: don

# Copyright (c) 2005-2012 Don Owens <don@owensnet.com>.  All rights reserved.

# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.  See perlartistic.

# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

use strict;
use warnings;

package DBIx::Wrapper::DBIDelegator;

use vars qw($VERSION);
$VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

# use Scalar::Util qw(refaddr);
use Carp qw(cluck);

my %i_data;

sub refaddr($) {
    my $obj = shift;
    my $pkg = ref($obj) or return undef;
  bless $obj, 'DBIx::Wrapper::Fake';
  my $i = int($obj);
  bless $obj, $pkg;
  return $i;
}


sub _new {
    my $proto = shift;
    my $self = bless {}, ref($proto) || $proto;
    $i_data{ refaddr($self) } = {};
    return $self;
}

sub TIEHASH {
    my $proto = shift;
    my $dbix_dbh = shift;

    my $self = $proto->_new;
    $i_data{ refaddr($self) }{_dbix_dbh} = $dbix_dbh;

    return $self;
}

sub _get_dbi {
    my $self = shift;
    return $i_data{ refaddr($self) }{_dbix_dbh}->get_dbi;
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    if ($key =~ /\A_(?:dbh|username|auth|attr|data_source_str|dbd_driver|db_style|debug)\Z/) {
        my ($package, $filename, $line, $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, $hints, $bitmask);
        
        my $frame = 1;
        my $this_pkg = __PACKAGE__;
        
        ($package, $filename, $line, $subroutine, $hasargs,
         $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);
        while (defined($package) and $package eq $this_pkg) {
            $frame++;
            ($package, $filename, $line, $subroutine, $hasargs,
             $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($frame);
            
            # if we get more than 10 something must be wrong
        last if $frame >= 10;
        }
        
        local($Carp::CarpLevel) = $frame;

        cluck "Accessing DBIx::Wrapper's internal data directly.  Don't do that.";
    }
    
    return $self->_get_dbi()->{$key};
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    my $dbi = $self->_get_dbi;

    $self->_get_dbi()->{$key} = $value;
    return $value;
}

sub DELETE {
    my $self = shift;
    my $key = shift;

    return delete $self->_get_dbi()->{$key};
}

sub CLEAR {
    my $self = shift;

    %{ $self->_get_dbi() } = ();
}

sub EXISTS {
    my $self = shift;
    my $key = shift;

    return exists $self->_get_dbi()->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    my $dbi = $self->_get_dbi;
    my $cnt = keys %$dbi; # reset each() iterator
    return each %$dbi;
}

sub NEXTKEY {
    my $self = shift;
    my $last_key = shift;
    
    return each %{ $self->_get_dbi };
}

sub SCALAR {
    my $self = shift;

    return scalar(%{ $self->_get_dbi });
}

sub UNTIE {
    # noop
}

sub DESTROY {
    my $self = shift;
    
    delete $i_data{ refaddr($self) };
    return;
}

1;

# Local Variables: #
# mode: perl #
# tab-width: 4 #
# indent-tabs-mode: nil #
# cperl-indent-level: 4 #
# perl-indent-level: 4 #
# End: #
# vim:set ai si et sta ts=4 sw=4 sts=4:
