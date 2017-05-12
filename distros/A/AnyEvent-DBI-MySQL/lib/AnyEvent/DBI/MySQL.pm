package AnyEvent::DBI::MySQL;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.1.0';

## no critic(ProhibitMultiplePackages Capitalization ProhibitNoWarnings)

use base qw( DBI );
use AnyEvent;
use Scalar::Util qw( weaken );

my @DATA;
my @NEXT_ID = ();
my $NEXT_ID = 0;
my $PRIVATE = 'private_' . __PACKAGE__;
my $PRIVATE_async = "$PRIVATE/async";

# Force connect_cached() but with unique key in $attr - this guarantee
# cached $dbh will be reused only after they no longer in use by user.
# Use {RootClass} instead of $class->connect_cached() because
# DBI->connect_cached() will call $class->connect() in turn.
sub connect { ## no critic(ProhibitBuiltinHomonyms)
    my ($class, $dsn, $user, $pass, $attr) = @_;
    local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; carp $msg };
    my $id = @NEXT_ID ? pop @NEXT_ID : $NEXT_ID++;

    $attr //= {};
    $attr->{RootClass} = $class;
    $attr->{$PRIVATE} = $id;
    my $dbh = DBI->connect_cached($dsn, $user, $pass, $attr);
    return if !$dbh;

    # weaken cached $dbh to have DESTROY called when user stop using it
    my $cache = $dbh->{Driver}{CachedKids};
    for (grep {$cache->{$_} && $cache->{$_} == $dbh} keys %{$cache}) {
        weaken($cache->{$_});
    }

    weaken(my $weakdbh = $dbh);
    my $io_cb; $io_cb = sub {
        local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; warn "$msg\n" };
        my $data = $DATA[$id];
        my $cb = delete $data->{cb};
        my $h  = delete $data->{h};
        my $args=delete $data->{call_again};
        if ($cb && $h) {
            $cb->( $h->mysql_async_result, $h, $args // ());
        }
        else {
            $DATA[$id] = {};
            if ($weakdbh && $weakdbh->{mysql_auto_reconnect}) {
                $weakdbh->ping;         # initiate reconnect
                if ($weakdbh->ping) {   # check is reconnect was successful
                    $DATA[ $id ] = {
                        io => AnyEvent->io(
                            fh      => $weakdbh->mysql_fd,
                            poll    => 'r',
                            cb      => $io_cb,
                        ),
                    };
                }
            }
        }
    };
    $DATA[ $id ] = {
        io => AnyEvent->io(
            fh      => $dbh->mysql_fd,
            poll    => 'r',
            cb      => $io_cb,
        ),
    };

    return $dbh;
}


package AnyEvent::DBI::MySQL::db;
use base qw( DBI::db );
use Carp;
use Scalar::Util qw( weaken );

my $GLOBAL_DESTRUCT = 0;
END { $GLOBAL_DESTRUCT = 1; }

sub DESTROY {
    my ($dbh) = @_;

    if ($GLOBAL_DESTRUCT) {
        return $dbh->SUPER::DESTROY();
    }

    $DATA[ $dbh->{$PRIVATE} ] = {};
    push @NEXT_ID, $dbh->{$PRIVATE};
    if (!$dbh->{Active}) {
        $dbh->SUPER::DESTROY();
    }
    else {
        # un-weaken cached $dbh to keep it for next connect_cached()
        my $cache = $dbh->{Driver}{CachedKids};
        for (grep {$cache->{$_} && $cache->{$_} == $dbh} keys %{$cache}) {
            $cache->{$_} = $dbh;
        }
    }
    return;
}

sub do { ## no critic(ProhibitBuiltinHomonyms)
    my ($dbh, @args) = @_;
    local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; carp $msg };
    my $ref = ref $args[-1];
    if ($ref eq 'CODE' || $ref eq 'AnyEvent::CondVar') {
        my $data = $DATA[ $dbh->{$PRIVATE} ];
        if ($data->{cb}) {
            croak q{can't make more than one asynchronous query simultaneously};
        }
        $data->{cb} = pop @args;
        $data->{h} = $dbh;
        weaken($data->{h});
        $args[1] //= {};
        $args[1]->{async} //= 1;
        if (!$args[1]->{async}) {
            my $cb = delete $data->{cb};
            my $h  = delete $data->{h};
            $cb->( $dbh->SUPER::do(@args), $h );
            return;
        }
    }
    else {
        $args[1] //= {};
        if ($args[1]->{async}) {
            croak q{callback required};
        }
    }
    return $dbh->SUPER::do(@args);
}

sub prepare {
    my ($dbh, @args) = @_;
    local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; carp $msg };
    $args[1] //= {};
    $args[1]->{async} //= 1;
    my $sth = $dbh->SUPER::prepare(@args) or return;
    $sth->{$PRIVATE} = $dbh->{$PRIVATE};
    $sth->{$PRIVATE_async} = $args[1]->{async};
    return $sth;
}

{   # replace C implementations in Driver.xst because it doesn't play nicely with DBI subclassing
    no warnings 'redefine';
    *DBI::db::selectrow_array   = \&DBD::_::db::selectrow_array;
    *DBI::db::selectrow_arrayref= \&DBD::_::db::selectrow_arrayref;
    *DBI::db::selectall_arrayref= \&DBD::_::db::selectall_arrayref;
}

my @methods = qw(
    selectcol_arrayref
    selectrow_hashref
    selectall_hashref
    selectrow_array
    selectrow_arrayref
    selectall_arrayref
);
for (@methods) {
    my $method = $_;
    my $super = "SUPER::$method";
    no strict 'refs';
    *{$method} = sub {
        my ($dbh, @args) = @_;
        local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; carp $msg };

        my $attr_idx = $method eq 'selectall_hashref' ? 2 : 1;
        my $ref = ref $args[$attr_idx];
        if ($ref eq 'CODE' || $ref eq 'AnyEvent::CondVar') {
            splice @args, $attr_idx, 0, {};
        } else {
            $args[$attr_idx] //= {};
        }

        $ref = ref $args[-1];
        if ($ref eq 'CODE' || $ref eq 'AnyEvent::CondVar') {
            my $data = $DATA[ $dbh->{$PRIVATE} ];
            $args[$attr_idx]->{async} //= 1;
            my $cb = $args[-1];
            # The select*() functions should be called twice:
            # - first time they'll do only prepare() and execute()
            #   * we should return false from execute() to interrupt them
            #     after execute(), before they'll start fetching data
            #   * we shouldn't weaken {h} because their $sth will be
            #     destroyed when they will be interrupted
            # - second time they'll do only data fetching:
            #   * they should get ready $sth instead of query param,
            #     so they'll skip prepare()
            #   * this $sth should be AnyEvent::DBI::MySQL::st::ready,
            #     so they'll skip execute()
            $data->{call_again} = [@args[1 .. $#args-1]];
            weaken($dbh);
            $args[-1] = sub {
                my (undef, $sth, $args) = @_;
                return if !$dbh;
                if ($dbh->err) {
                    $cb->();
                }
                else {
                    bless $sth, 'AnyEvent::DBI::MySQL::st::ready';
                    $cb->( $dbh->$super($sth, @{$args}) );
                }
            };
            if (!$args[$attr_idx]->{async}) {
                delete $data->{call_again};
                $cb->( $dbh->$super(@args[0 .. $#args-1]) );
                return;
            }
        }
        else {
            if ($args[$attr_idx]->{async}) {
                croak q{callback required};
            } else {
                $args[$attr_idx]->{async} = 0;
            }
        }

        return $dbh->$super(@args);
    };
}


package AnyEvent::DBI::MySQL::st;
use base qw( DBI::st );
use Carp;
use Scalar::Util qw( weaken );

sub execute {
    my ($sth, @args) = @_;
    local $SIG{__WARN__} = sub { (my $msg=shift)=~s/ at .*//ms; carp $msg };
    my $data = $DATA[ $sth->{$PRIVATE} ];
    my $ref = ref $args[-1];
    if ($ref eq 'CODE' || $ref eq 'AnyEvent::CondVar') {
        if ($data->{cb}) {
            croak q{can't make more than one asynchronous query simultaneously};
        }
        $data->{cb} = pop @args;
        $data->{h} = $sth;
        if (!$sth->{$PRIVATE_async}) {
            my $cb = delete $data->{cb};
            my $h  = delete $data->{h};
            $cb->( $sth->SUPER::execute(@args), $h );
            return;
        }
        $sth->SUPER::execute(@args);
        if ($sth->err) { # execute failed, I/O won't happens
            my $cb = delete $data->{cb};
            my $h  = delete $data->{h};
            my $args=delete $data->{call_again};
            $cb->( undef, $h, $args // () );
        }
        return;
    }
    elsif ($sth->{$PRIVATE_async}) {
        croak q{callback required};
    }
    return $sth->SUPER::execute(@args);
}


package AnyEvent::DBI::MySQL::st::ready;
use base qw( DBI::st );
sub execute { return '0E0' };


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

AnyEvent::DBI::MySQL - Asynchronous MySQL queries


=head1 VERSION

This document describes AnyEvent::DBI::MySQL version v2.1.0


=head1 SYNOPSIS

    use AnyEvent::DBI::MySQL;

    # get cached but not in use $dbh
    $dbh = AnyEvent::DBI::MySQL->connect(…);

    # async
    $dbh->do(…,                 sub { my ($rv, $dbh) = @_; … });
    $sth = $dbh->prepare(…);
    $sth->execute(…,            sub { my ($rv, $sth) = @_; … });
    $dbh->selectall_arrayref(…, sub { my ($ary_ref)  = @_; … });
    $dbh->selectall_hashref(…,  sub { my ($hash_ref) = @_; … });
    $dbh->selectcol_arrayref(…, sub { my ($ary_ref)  = @_; … });
    $dbh->selectrow_array(…,    sub { my (@row_ary)  = @_; … });
    $dbh->selectrow_arrayref(…, sub { my ($ary_ref)  = @_; … });
    $dbh->selectrow_hashref(…,  sub { my ($hash_ref) = @_; … });

    # sync
    $rv = $dbh->do('…');
    $dbh->do('…', {async=>0}, sub { my ($rv, $dbh) = @_; … });


=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements asynchronous MySQL queries using
L<DBD::mysql/"ASYNCHRONOUS QUERIES"> feature. Unlike L<AnyEvent::DBI> it
doesn't spawn any processes.

You shouldn't use C<< {RaiseError=>1} >> with this module and should check
returned values in your callback to detect errors. This is because with
C<< {RaiseError=>1} >> exception will be thrown B<instead> of calling your
callback function, which isn't what you want in most cases.


=head1 INTERFACE 

The API is trivial: use it just like usual DBI, but instead of expecting
return value from functions which may block add one extra parameter: callback.
That callback will be executed with usual returned value of used method in
params (only exception is extra $dbh/$sth param in do() and execute() for
convenience).

=head2 SYNCHRONOUS QUERIES

In most cases to make usual synchronous query it's enough to don't provide
callback - use standard DBI params and it will work just like usual DBI.
Only exception is prepare()/execute() pair: you should use
C<< {async=>0} >> attribute for prepare() to have synchronous execute().

For convenience, you can quickly turn asynchronous query to synchronous by
adding C<< {async=>0} >> attribute - you don't have to rewrite code to
remove callback function. In this case your callback will be called
immediately after executing this synchronous query.

=head2 SUPPORTED DBI METHODS

=head3 connect

    $dbh = AnyEvent::DBI::MySQL->connect(...);

L<DBD::mysql> support only single asynchronous query per MySQL connection.
To make it easier to overcome this limitation provided connect()
constructor work using DBI->connect_cached() under the hood, but it reuse
only inactive $dbh - i.e. one which you didn't use anymore. So, connect()
guarantee to not return $dbh which is already in use in your code.
For example, in FastCGI or Mojolicious app you can safely use connect() to
get own $dbh per each incoming connection; after you send response and
close this connection that $dbh should automatically go out of scope and
become inactive (you can force this by C<$dbh=undef;>); after that this
$dbh may be returned by connect() when handling next incoming request.
As result you should automatically get a pool of connected $dbh which size
should match peak amount of simultaneously handled CGI requests.
You can flush that $dbh cache as documented by L<DBI> at any time.

NOTE: To implement this caching behavior this module catch DESTROY() for
$dbh and instead of destroying it (and calling $dbh->disconnect()) make it
available for next connect() call in cache. So, if you need to call
$dbh->disconnect() - do it manually and don't expect it to happens
automatically on $dbh DESTROY(), like it work in DBI.

Also, usual limitations for cached connections apply as documented by
L<DBI> (read: don't change $dbh configuration).

=head3 do

    $dbh->do(..., sub {
        my ($rv, $dbh) = @_;
        ...
    });

=head3 execute

    $sth->execute(..., sub {
        my ($rv, $sth) = @_;
        ...
    });

=head3 selectall_arrayref

    $dbh->selectall_arrayref(..., sub {
        my ($ary_ref) = @_;
        ...
    });

=head3 selectall_hashref

    $dbh->selectall_hashref(..., sub {
        my ($hash_ref) = @_;
        ...
    });

=head3 selectcol_arrayref

    $dbh->selectcol_arrayref(..., sub {
        my ($ary_ref) = @_;
        ...
    });

=head3 selectrow_array

    $dbh->selectrow_array(..., sub {
        my (@row_ary) = @_;
        ...
    });

=head3 selectrow_arrayref

    $dbh->selectrow_arrayref(..., sub {
        my ($ary_ref) = @_;
        ...
    });

=head3 selectrow_hashref

    $dbh->selectrow_hashref(..., sub {
        my ($hash_ref) = @_;
        ...
    });


=head1 LIMITATIONS

These DBI methods are not supported yet (i.e. they work as usually - in
blocking mode), mostly because they internally run several queries and
should be completely rewritten to support non-blocking mode.

NOTE: You have to provide C<< {async=>0} >> attribute to prepare() before
using execute_array() or execute_for_fetch().

    $sth->execute_array
    $sth->execute_for_fetch
    $dbh->table_info
    $dbh->column_info
    $dbh->primary_key_info
    $dbh->foreign_key_info
    $dbh->statistics_info
    $dbh->primary_key
    $dbh->tables


=head1 SEE ALSO

L<AnyEvent>, L<DBI>, L<AnyEvent::DBI>


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-AnyEvent-DBI-MySQL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-AnyEvent-DBI-MySQL>

    git clone https://github.com/powerman/perl-AnyEvent-DBI-MySQL.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=AnyEvent-DBI-MySQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/AnyEvent-DBI-MySQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-DBI-MySQL>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=AnyEvent-DBI-MySQL>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/AnyEvent-DBI-MySQL>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
