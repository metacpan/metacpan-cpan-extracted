# -*-perl-*-
# Creation date: 2003-03-30 15:23:31
# Authors: Don
# Change log:
# $Revision: 1963 $

# Copyright (c) 2003-2012 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.


use strict;

{   package DBIx::Wrapper::Statement;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my ($proto) = @_;
        my $self = bless {}, ref($proto) || $proto;
        return $self;
    }


    ####################
    # getters/setters

    sub _getSth {
        my ($self) = @_;
        return $$self{_sth};
    }

    sub _setSth {
        my ($self, $sth) = @_;
        $$self{_sth} = $sth;
    }

    sub get_dbi_sth {
        my ($self) = @_;
        return $self->_getSth;
    }

    # return the field names with their case modified as specified by setNameArg()
    sub get_field_names {
        my ($self) = @_;

        my $name_arg = $self->_getParent()->getNameArg;
        return $self->_getSth()->{$name_arg};

    }
    *getFieldNames = \&get_field_names;

    # return the field/column names from the driver with their case unmodified
    sub get_names {
        my ($self) = @_;

        return $self->_getSth()->{NAME};
    }
    *getNames = \&get_names;

    # return the field/column names in all uppercase
    sub get_names_uc {
        my ($self) = @_;

        return $self->_getSth()->{NAME_uc};
    }
    *getNamesUc = \&get_names_uc;

    # return the field/column names in all lowercase
    sub get_names_lc {
        my ($self) = @_;

        return $self->_getSth()->{NAME_uc};
    }
    *getNamesLc = \&get_names_lc;

    sub _getParent {
        my ($self) = @_;
        return $$self{_parent};
    }

    sub _setParent {
        my ($self, $parent) = @_;
        $$self{_parent} = $parent;
    }

    sub _getQuery {
        my $self = shift;
        return $self->{_query};
    }

    sub _setQuery {
        my $self = shift;
        my $query = shift;
        $self->{_query} = $query;
    }

    sub _getRequestObj {
        return shift()->{_request_obj};
    }
    
    sub _setRequestObj {
        my $self = shift;
        $self->{_request_obj} = shift;
    }
    
}

1;

