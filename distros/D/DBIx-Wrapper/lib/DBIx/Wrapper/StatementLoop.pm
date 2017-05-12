# -*-perl-*-
# Creation date: 2003-03-30 15:24:44
# Authors: Don
# Change log:
# $Revision: 1963 $

# Copyright (c) 2003-2012 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

{   package DBIx::Wrapper::StatementLoop;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use base 'DBIx::Wrapper::Statement';

    sub new {
        my ($proto, $parent, $query) = @_;

        my $r = DBIx::Wrapper::Request->new($parent);
        $r->setQuery($query);
        
        $parent->_runPrePrepareHook($r);
        $query = $r->getQuery;
        
        my $sth = $parent->_getDatabaseHandle()->prepare($query);
        
        $r->setStatementHandle($sth);
        $parent->_runPostPrepareHook($r);

        $r->setStatementHandle($sth);
        unless ($sth) {
            $parent->_printDbiError("\nQuery was '$query'\n");
            return $parent->setErr(0, $DBI::errstr);
        }
        
        my $self = bless {}, ref($proto) || $proto;
        $self->_setSth($sth);
        $self->_setParent($parent);
        $self->_setQuery($query);
        $self->_setRequestObj($r);
        
        return $self;
    }

    sub next {
        my ($self, $exec_args) = @_;
        if (scalar(@_) == 3) {
            $exec_args = [ $exec_args ] unless ref($exec_args);
        }
        $exec_args = [] unless $exec_args;

        my $r = $self->_getRequestObj;
        $r->setExecArgs($exec_args);

        my $sth = $self->_getSth;

        $self->_getParent()->_runPreExecHook($r);
        $exec_args = $r->getExecArgs;
        
        my $rv = $sth->execute(@$exec_args);

        $r->setExecReturnValue($rv);
        
        $self->_getParent()->_runPostExecHook($r);
        
        return $rv;
    }

    sub DESTROY {
        my ($self) = @_;
        my $sth = $self->_getSth;
        $sth->finish if $sth;
    }

}

1;

