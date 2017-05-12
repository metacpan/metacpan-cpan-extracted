# -*-perl-*-
# Creation date: 2003-03-30 16:26:50
# Authors: Don
# Change log:
# $Revision: 1963 $

# Copyright (c) 2003-2012 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

{   package DBIx::Wrapper::SQLCommand;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my $proto = shift;
        my $str = shift;
        
        my $self = bless { _str => $str }, ref($proto) || $proto;
        return $self;
    }

    sub new_cond {
        my ($proto, $dbh, $cond, $val) = @_;
        my $self = bless { _cond => $cond, _dbh => $dbh, _val => $val }, ref($proto) || $proto;
        return $self;

    }

    sub asString {
        my $self = shift;
        my $str = $self->{_str};
        return $str;
    }
    *as_string = \&asString;

    sub get_condition {
        my $self = shift;
        my $bind = shift;
        
        my $cond_str = $self->{_cond};

        unless (defined($cond_str)) {
            return;
        }

        my $val = $self->{_val};

        my $cond = '';
        if ($cond_str eq 'not') {
            if (defined($val)) {
                $cond = '!=';
                if ($bind) {
                    return wantarray ? ($cond, '?') : $cond;
                }
                else {
                    my $rv = $self->{_dbh}->quote($val);
                    return wantarray ? ($cond, $rv) : $cond;
                }
                            
            }
            else {
                $cond = 'IS NOT NULL';
                return wantarray ? ($cond, undef) : $cond;
            }
        }
        
    }

    sub has_condition {
        my $self = shift;
        return defined($self->{_cond});
    }

    sub get_val {
        return shift()->{_val};
    }
    
}

1;


