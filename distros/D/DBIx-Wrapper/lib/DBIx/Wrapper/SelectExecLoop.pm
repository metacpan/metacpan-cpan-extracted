# -*-perl-*-
# Creation date: 2004-04-21 10:45:30
# Authors: Don
# Change log:
# $Revision: 1963 $

# Copyright (c) 2004-2012 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

{   package DBIx::Wrapper::SelectExecLoop;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    use base 'DBIx::Wrapper::Statement';
    
    sub new {
        my ($proto, $parent, $query, $multi) = @_;

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

        my $self =
            bless { _query => $query, _multi => $multi || '' }, ref($proto) || $proto;
        $self->_setSth($sth);
        $self->_setParent($parent);
        $self->_setQuery($query);
        $self->_setRequestObj($r);
        
        return $self;
    }

    sub next {
        my ($self, $exec_args) = @_;
        my $query = $self->_getQuery;
        my $sth = $self->_getSth;
        my $r = $self->_getRequestObj;
        $r->setExecArgs($exec_args);
        
        if ($$self{_multi}) {
            $self->_getParent()->_runPreExecHook($r);
            $exec_args = $r->getExecArgs;
            
            my $rv = $sth->execute(@$exec_args);
            
            $r->setExecReturnValue($rv);
            $self->_getParent()->_runPostExecHook($r);

            $self->_getParent()->_runPreFetchHook($r);
            $sth = $r->getStatementHandle;

            if ($rv) {
                my $rows = [];
                my $row = $sth->fetchrow_hashref($self->_getParent()->getNameArg);
                while ($row) {
                    $r->setReturnVal($row);
                    $self->_getParent()->_runPostFetchHook($r);
                    $row = $r->getReturnVal;

                    push @$rows, $row if $row;

                    $self->_getParent()->_runPreFetchHook($r);
                    $sth = $r->getStatementHandle;

                    $row = $sth->fetchrow_hashref($self->_getParent()->getNameArg);
                }
                return $rows;
            }

        } else {
            $self->_getParent()->_runPreExecHook($r);
            $exec_args = $r->getExecArgs;

            my $rv = $sth->execute(@$exec_args);
            $r->setExecReturnValue($rv);

            $self->_getParent()->_runPostExecHook($r);
            if ($rv) {
                $self->_getParent()->_runPreFetchHook($r);
                $sth = $r->getStatementHandle;

                my $result = $sth->fetchrow_hashref($self->_getParent()->getNameArg);
                $r->setReturnVal($result);
                $self->_getParent()->_runPostFetchHook($r);
                $result = $r->getReturnVal;
                return $result;
            }
        }
        return undef;
    }

    sub DESTROY {
        my ($self) = @_;
        my $sth = $self->_getSth;
        $sth->finish if $sth;
    }

}

1;


