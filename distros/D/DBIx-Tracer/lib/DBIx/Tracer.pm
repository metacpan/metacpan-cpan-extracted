package DBIx::Tracer;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.03';

use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Carp;

our $IN_DO;

my $org_execute               = \&DBI::st::execute;
my $org_bind_param            = \&DBI::st::bind_param;
my $org_db_do                 = \&DBI::db::do;
my $org_db_selectall_arrayref = \&DBI::db::selectall_arrayref;
my $org_db_selectrow_arrayref = \&DBI::db::selectrow_arrayref;
my $org_db_selectrow_array    = \&DBI::db::selectrow_array;

my $pp_mode   = $INC{'DBI/PurePerl.pm'} ? 1 : 0;

my $st_execute;
my $st_bind_param;
my $db_do;
my $selectall_arrayref;
my $selectrow_arrayref;
my $selectrow_array;

our $OUTPUT;

sub new {
    my $class = shift;

    # argument processing
    my %args;
    if (@_==1) {
        if (ref $_[0] eq 'CODE') {
            $args{code} = $_[0];
        } else {
            %args = %{$_[0]};
        }
    } else {
        %args = @_;
    }
    for (qw(code)) {
        unless ($args{$_}) {
            croak "Missing mandatory parameter $_ for DBIx::Tracer->new";
        }
    }

    my $logger = $args{code};

    # create object
    my $self = bless \%args, $class;

    # wrap methods
    my $st_execute    = $class->_st_execute($org_execute, $logger);
    $st_bind_param = $class->_st_bind_param($org_bind_param, $logger);
    $db_do         = $class->_db_do($org_db_do, $logger);
    unless ($pp_mode) {
        $selectall_arrayref = $class->_select_array($org_db_selectall_arrayref, 0, $logger);
        $selectrow_arrayref = $class->_select_array($org_db_selectrow_arrayref, 0, $logger);
        $selectrow_array    = $class->_select_array($org_db_selectrow_array, 1, $logger);
    }

    no warnings qw(redefine prototype);
    *DBI::st::execute    = $st_execute;
    *DBI::st::bind_param = $st_bind_param;
    *DBI::db::do         = $db_do;
    unless ($pp_mode) {
        *DBI::db::selectall_arrayref = $selectall_arrayref;
        *DBI::db::selectrow_arrayref = $selectrow_arrayref;
        *DBI::db::selectrow_array    = $selectrow_array;
    }

    return $self;
}

sub DESTROY {
    my $self = shift;

    no warnings qw(redefine prototype);
    *DBI::st::execute    = $org_execute;
    *DBI::st::bind_param = $org_bind_param;
    *DBI::db::do         = $org_db_do;
    unless ($pp_mode) {
        *DBI::db::selectall_arrayref = $org_db_selectall_arrayref;
        *DBI::db::selectrow_arrayref = $org_db_selectrow_arrayref;
        *DBI::db::selectrow_array    = $org_db_selectrow_array;
    }
}

# ------------------------------------------------------------------------- 
# wrapper methods.

sub _st_execute {
    my ($class, $org, $logger) = @_;

    return sub {
        my $sth = shift;
        my @params = @_;
        my @types;

        my $dbh = $sth->{Database};
        my $ret = $sth->{Statement};
        if (my $attrs = $sth->{private_DBIx_Tracer_attrs}) {
            my $bind_params = $sth->{private_DBIx_Tracer_params};
            for my $i (1..@$attrs) {
                push @types, $attrs->[$i - 1]{TYPE};
                push @params, $bind_params->[$i - 1] if $bind_params;
            }
        }
        $sth->{private_DBIx_Tracer_params} = undef;

        my $begin = [gettimeofday];
        my $wantarray = wantarray ? 1 : 0;
        my $res = $wantarray ? [$org->($sth, @_)] : scalar $org->($sth, @_);
        my $time = tv_interval($begin, [gettimeofday]);

        # DBD::SQLite calls ::st::execute from ::do.
        # It makes duplicated logging output.
        unless ($IN_DO) {
            $class->_logging($logger, $dbh, $ret, $time, \@params);
        }

        return $wantarray ? @$res : $res;
    };
}

sub _st_bind_param {
    my ($class, $org) = @_;

    return sub {
        my ($sth, $p_num, $value, $attr) = @_;
        $sth->{private_DBIx_Tracer_params} ||= [];
        $sth->{private_DBIx_Tracer_attrs } ||= [];
        $attr = +{ TYPE => $attr || 0 } unless ref $attr eq 'HASH';
        $sth->{private_DBIx_Tracer_params}[$p_num - 1] = $value;
        $sth->{private_DBIx_Tracer_attrs }[$p_num - 1] = $attr;
        $org->(@_);
    };
}

sub _select_array {
    my ($class, $org, $is_selectrow_array, $logger) = @_;

    return sub {
        my $wantarray = wantarray;
        my ($dbh, $stmt, $attr, @bind) = @_;

        no warnings qw(redefine prototype);
        local *DBI::st::execute = $org_execute; # suppress duplicate logging

        my $ret = ref $stmt ? $stmt->{Statement} : $stmt;

        my $begin = [gettimeofday];
        my $res;
        if ($is_selectrow_array) {
            $res = $wantarray ? [$org->($dbh, $stmt, $attr, @bind)] : $org->($dbh, $stmt, $attr, @bind);
        }
        else {
            $res = $org->($dbh, $stmt, $attr, @bind);
        }
        my $time = tv_interval($begin, [gettimeofday]);

        $class->_logging($logger, $dbh, $ret, $time, \@bind);

        if ($is_selectrow_array) {
            return $wantarray ? @$res : $res;
        }
        return $res;
    };
}

sub _db_do {
    my ($class, $org, $logger) = @_;

    return sub {
        my $wantarray = wantarray ? 1 : 0;
        my ($dbh, $stmt, $attr, @bind) = @_;

        local $IN_DO = 1;

        my $ret = $stmt;

        my $begin = [gettimeofday];
        my $res = $wantarray ? [$org->($dbh, $stmt, $attr, @bind)] : scalar $org->($dbh, $stmt, $attr, @bind);
        my $time = tv_interval($begin, [gettimeofday]);

        $class->_logging($logger, $dbh, $ret, $time, \@bind);

        return $wantarray ? @$res : $res;
    };
}

sub _logging {
    my ($class, $logger, $dbh, $sql, $time, $bind_params) = @_;
    $bind_params ||= [];

    $logger->(
        dbh         => $dbh,
        time        => $time,
        sql         => $sql,
        bind_params => $bind_params,
    );
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Tracer - Easy tracer for DBI

=head1 SYNOPSIS

    use DBIx::Tracer;

    my $tracer = DBIx::Tracer->new(
        sub {
            my %args = @_;
            say $args{dbh};
            say $args{time};
            say $args{sql};
            say "Bind: $_" for @{$args{bind_params}};
        }
    );

=head1 DESCRIPTION

DBIx::Tracer is easy tracer for DBI. You can trace a SQL queries without 
modifying configuration in your application.

You can insert snippets using DBIx::Tracer, and profile it.

=head1 GUARD OBJECT

DBIx::Tracer uses Scope::Guard-ish guard object strategy.

C<< DBIx::Tracer->new >> installs method modifiers, and C<< DBIx::Tracer->DESTROY >> uninstall method modifiers.

You must keep the instance of DBIx::Trace in the context.

=head1 METHODS

=over 4

=item DBIx::Tracer->new(CodeRef: $code)

    my $tracer = DBIx::Tracer->new(
        sub { ... }
    );

Create instance of DBIx::Tracer. Constructor takes callback function, will call on after each queries executed.

You must keep this instance you want to logging. Destructor uninstall method modifiers.

=back

=head1 CALLBACK OPTIONS

DBIx::Tracer passes following parameters to callback function.

=over 4

=item dbh

instance of $dbh.

=item sql

SQL query in string.

=item bind_params : ArrayRef[Str]

binded parameters for the query in arrayref.

=item time

Elapsed times for query in floating seconds.

=back

=head1 FAQ

=over 4

=item Why don't you use Callbacks feature in DBI?

I don't want to modify DBI configuration in my application for tracing.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 THANKS TO

xaicron is author of L<DBIx::QueryLog>. Most part of DBIx::Tracer was taken from DBIx::QueryLog.

=head1 SEE ALSO

L<DBIx::QueryLog>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
