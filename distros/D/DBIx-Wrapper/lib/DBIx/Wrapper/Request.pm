# -*-perl-*-
# Creation date: 2004-10-29 14:01:59
# Authors: Don
# $Revision: 1963 $

use strict;

{   package DBIx::Wrapper::Request;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my $proto = shift;
        my $db_obj = shift;
        my $self = bless { _db_obj => $db_obj }, ref($proto) || $proto;
        return $self;
    }

    sub getDbObj {
        return shift()->{_db_obj};
    }

    sub getQuery {
        shift()->{_query};
    }

    sub setQuery {
        my $self = shift;
        $self->{_query} = shift;
    }

    sub getExecArgs {
        return shift()->{_exec_args} || [];
    }

    sub setExecArgs {
        my $self = shift;
        my $args = shift;
        if (ref($args) eq 'ARRAY') {
            $self->{_exec_args} = $args;
        } else {
            $self->{_exec_args} = [ $args ];
        }
    }

    sub getExecReturnValue {
        return shift()->{_exec_return_value};
    }

    sub setExecReturnValue {
        my $self = shift;
        $self->{_exec_return_value} = shift;
    }

    sub getReturnVal {
        return shift()->{_return_record};
    }
    
    sub setReturnVal {
        my $self = shift;
        $self->{_return_record} = shift;
    }

    sub getStatementHandle {
        return shift()->{_statement_handle};
    }

    sub setStatementHandle {
        my $self = shift;
        $self->{_statement_handle} = shift;
    }

    sub getErrorStr {
        return shift()->{_errstr};
    }

    sub setErrorStr {
        my $self = shift;
        $self->{_errstr} = shift;
    }

    sub OK {
        return 1;
    }

    sub DECLINED {
        return 0;
    }

}

1;

=pod

=head1 NAME

DBIx::Wrapper::Request - Request object for database operations

=head1 SYNOPSIS

Objects of the class are created by DBIx::Wrapper objects and
passed to hooks.  You should never have to create one yourself.

 my $db = $req->getDbObj;

 my $query = $req->getQuery;
 $req->setQuery($query);

 my $exec_args = $req->getExecArgs;
 $req->setExecArgs(\@args);

 my $rv = $req->getExecReturnValue;
 $req->setExecReturnValue($rv);

 my $rv = $req->getReturnVal;
 $req->setReturnVal($rv);

 my $sth = $req->getStatementHandle;
 $req->setStatementHandle($sth);

 my $err_str = $req->getErrorStr;
 $req->setErrorStr($err_str);

=head1 DESCRIPTION

DBIx::Wrapper::Request objects are used to encapsulate date
passed between DBIx::Wrapper methods at various stages of
executing a query.

=head1 METHODS

=head2 C<getDbObj()>

Returns the DBIx::Wrapper object that created the Request object.

=head2 C<getQuery()>

Returns the current query.

=head2 C<setQuery($query)>

Sets the current query.

=head2 C<getExecArgs()>

Returns a reference to the array of execute arguments passed to
the DBIx::Wrapper method currently executing.

=head2 C<setExecArgs(\@args)>

Sets the current execute arguments.

=head2 C<getExecReturnValue()>

Returns the current execute() return value.

=head2 C<setExecReturnValue($rv)>

Sets the current execute() return value.

=head2 C<getReturnVal()>

Gets the current return value (from a fetch).

=head2 C<setReturnVal($rv)>

Sets the current return value (from a fetch).

=head2 C<getStatementHandle()>

Get the current statement handle being used.

=head2 C<setStatementHandle($sth)>

Set the current statement handle to use.

=head2 C<$req->getErrorStr()>

Get the error string.

=head2 C<setErrorStr($err_str)>

Set the error string.


=head1 EXAMPLES

    ##################################################
    # Pre prepare hook

    $db_obj->addPrePrepareHook(\&_db_pre_prepare_hook)

    sub _db_pre_prepare_hook {
        my $self = shift;
        my $r = shift;
        my $query = $r->getQuery;
        
        if ($query =~ /^\s*(?:update|delete|insert|replace|create|drop|alter)/i) {
            my $db = $r->getDbObj;
            unless ($db->ping) {
                # db connection has gone away, so try to reconnect
                my $msg = "UI DataProvider pre-prepare: db ping failed, reconnecting to ";
                $msg .= $db->_getDataSource;
                print STDERR $msg . "\n";
                my $tries_left = 5;
                my $connected = 0;
                my $sleep_time = 0;
                while ($tries_left) {
                    $sleep_time++;
                    sleep $sleep_time;
                    $tries_left--;
                    $connected = $db->reconnect;
                    last if $connected;
                }

                unless ($connected) {
                    die "Couldn't reconnect to db after ping failure: dsn=" . $db->_getDataSource;
                }
            }
        }
                            
        return $r->OK;
    }


    ##################################################
    # Post execute hook

    sub _db_post_exec_hook {
        my $self = shift;
        my $r = shift;

        my $exec_successful = $r->getExecReturnValue;
        unless ($exec_successful) {
            my $query = $r->getQuery;
            if ($r->getQuery =~ /^\s*(?:select|show)/i) {
                my $errstr = $r->getErrorStr;
                if ($errstr =~ /Lost connection to MySQL server during query/i) {
                    my $db = $r->getDbObj;
                    my $msg = "UI DataProvider post exec: lost connection to MySQL server ";
                    $msg .= "during query, reconnecting to " . $db->_getDataSource;
                    print STDERR $msg . "\n";
                    my $tries_left = 5;
                    my $connected = 0;
                    my $sleep_time = 0;
                    while ($tries_left) {
                        $sleep_time++;
                        sleep $sleep_time;
                        $tries_left--;
                        $connected = $db->reconnect;
                        last if $connected;
                    }
                                      
                    if ($connected) {
                        my $sth = $db->prepare_no_hooks($r->getQuery);
                        $r->setStatementHandle($sth);
                        my $exec_args = $r->getExecArgs;
                        my $rv = $sth->execute(@$exec_args);
                        $r->setExecReturnValue($rv);
                    } else {
                        die "Couldn't reconnect to db after losing connection: dsn="
                            . $db->_getDataSource;
                    }
                }
            }
        }
                          
        return $r->OK;
    }


=head1 BUGS

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004-2012 Don Owens (don@regexguy.com).  All rights reserved.

This free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See perlartistic.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.


=head1 VERSION

$Id: Request.pm 1963 2012-01-17 15:41:53Z don $

=cut
