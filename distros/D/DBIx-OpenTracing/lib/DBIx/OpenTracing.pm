package DBIx::OpenTracing;
use strict;
use warnings;
use feature qw[ state ];
use syntax 'maybe';
use B;
use Carp qw[ croak ];
use Caller::Hide qw[ hide_package ];
use DBI;
use DBIx::OpenTracing::Constants ':ALL';
use List::Util qw[ sum0 ];
use OpenTracing::GlobalTracer;
use Package::Constants;
use Scalar::Util qw[ blessed looks_like_number ];
use Scope::Context;

our $VERSION = 'v0.1.0';

hide_package(__PACKAGE__);

use constant TAGS_DEFAULT => (DB_TAG_TYPE ,=> 'sql');

use constant {
    _DBI_EXECUTE            => \&DBI::st::execute,
    _DBI_DO                 => \&DBI::db::do,
    _DBI_SELECTROW_ARRAY    => \&DBI::db::selectrow_array,
    _DBI_SELECTROW_ARRAYREF => \&DBI::db::selectrow_arrayref,
    _DBI_SELECTROW_HASHREF  => \&DBI::db::selectrow_hashref,
    _DBI_SELECTALL_ARRAYREF => \&DBI::db::selectall_arrayref,
    _DBI_SELECTALL_ARRAY    => \&DBI::db::selectall_array,
    _DBI_SELECTROW_ARRAY    => \&DBI::db::selectrow_array,
    _DBI_SELECTALL_HASHREF  => \&DBI::db::selectall_hashref,
    _DBI_SELECTCOL_ARRAYREF => \&DBI::db::selectcol_arrayref,
};
if (%DBIx::QueryLog::SKIP_PKG_MAP) {    # hide from DBIx::QueryLog's caller()
    $DBIx::QueryLog::SKIP_PKG_MAP{ (__PACKAGE__) } = 1;
}

our $is_currently_traced;    # lexicals can't be localized
my ($is_enabled, $is_suspended);

sub _numeric_result { 0+ $_[0] }
sub _sum_elements   { looks_like_number($_[0]) ? $_[0] : 1 }
sub _array_size     { scalar @{ $_[0] } }
sub _hash_key_count { scalar keys %{ $_[0] } }

# signature processors                statement, bind values
sub _sig_dbh_stmt_attr_bind     { @_[     1,      3 .. $#_   ] }
sub _sig_dbh_stmt_key_attr_bind { @_[     1,      4 .. $#_   ] }
sub _sig_sth_bind               { @_[     0,      1 .. $#_   ] }

sub enable {
    return if $is_enabled or $is_suspended;

    no warnings 'redefine';
    state $execute = _gen_wrapper(_DBI_EXECUTE, {
        signature       => \&_sig_sth_bind,
        row_counter     => \&_numeric_result,
        count_condition => sub {
            my ($sth) = @_;
            my $fields = $sth->{NUM_OF_FIELDS};
            return !defined $fields || $fields == 0;    # non-select
        },
    });
    *DBI::st::execute = $execute;

    state $do = _gen_wrapper(_DBI_DO, {
        signature   => \&_sig_dbh_stmt_attr_bind,
        row_counter => \&_numeric_result,
    });
    *DBI::db::do = $do;

    state $selectall_array = _gen_wrapper(_DBI_SELECTALL_ARRAY, {
        signature   => \&_sig_dbh_stmt_attr_bind,
        row_counter => \&_sum_elements
    });
    *DBI::db::selectall_array = $selectall_array;

    state $selectall_arrayref = _gen_wrapper(_DBI_SELECTALL_ARRAYREF, {
        signature   => \&_sig_dbh_stmt_attr_bind,
        row_counter => \&_array_size
    });
    *DBI::db::selectall_arrayref = $selectall_arrayref;

    state $selectcol_arrayref = _gen_wrapper(_DBI_SELECTCOL_ARRAYREF, {
        signature   => \&_sig_dbh_stmt_attr_bind,
        row_counter => \&_array_size,
    });
    *DBI::db::selectcol_arrayref = $selectcol_arrayref;

    state $selectrow_array = _gen_wrapper(_DBI_SELECTROW_ARRAY, {
        signature => \&_sig_dbh_stmt_attr_bind,
    });
    *DBI::db::selectrow_array = $selectrow_array;

    state $selectrow_arrayref = _gen_wrapper(_DBI_SELECTROW_ARRAYREF, {
        signature => \&_sig_dbh_stmt_attr_bind
    });
    *DBI::db::selectrow_arrayref = $selectrow_arrayref;

    state $selectall_hashref = _gen_wrapper(_DBI_SELECTALL_HASHREF, {
        signature   => \&_sig_dbh_stmt_key_attr_bind,
        row_counter => \&_hash_key_count,
    });
    *DBI::db::selectall_hashref = $selectall_hashref;

    state $selectrow_hashref = _gen_wrapper(_DBI_SELECTROW_HASHREF, {
        signature => \&_sig_dbh_stmt_attr_bind,
    });
    *DBI::db::selectrow_hashref = $selectrow_hashref;
 
    $is_enabled = 1;

    return;
}

sub disable {
    return unless $is_enabled;

    no warnings 'redefine';
    *DBI::st::execute            = _DBI_EXECUTE;
    *DBI::db::do                 = _DBI_DO;
    *DBI::db::selectall_array    = _DBI_SELECTALL_ARRAY;
    *DBI::db::selectall_arrayref = _DBI_SELECTALL_ARRAYREF;
    *DBI::db::selectcol_arrayref = _DBI_SELECTCOL_ARRAYREF;
    *DBI::db::selectrow_array    = _DBI_SELECTROW_ARRAY;
    *DBI::db::selectrow_arrayref = _DBI_SELECTROW_ARRAYREF;
    *DBI::db::selectall_hashref  = _DBI_SELECTALL_HASHREF;
    *DBI::db::selectrow_hashref  = _DBI_SELECTROW_HASHREF;
 
    $is_enabled = 0;

    return;
}

sub import {
    my ($class, $tag_mode) = @_;

    enable();
    return if not defined $tag_mode;

    my @sensitive_tags = (
        DB_TAG_SQL,
        DB_TAG_BIND,
        DB_TAG_USER,
        DB_TAG_DBNAME,
    );

    if ($tag_mode eq '-none') {
        $class->hide_tags(DB_TAGS_ALL);
    }
    elsif ($tag_mode eq '-safe') {
        $class->hide_tags(@sensitive_tags);
    }
    elsif ($tag_mode eq '-secure') {
        $class->_disable_tags(@sensitive_tags);
    }
    else {
        croak "Unknown mode: $tag_mode";
    }
    return;
}

sub unimport { disable() }

sub _tags_dbh {
    my ($dbh) = @_;
    return if !blessed($dbh) or !$dbh->isa('DBI::db');

    my $dbname = $dbh->{Name};
    $dbname = $1 if $dbname =~ /dbname=([^;]+);/;

    return (
        maybe DB_TAG_USER   ,=> $dbh->{Username},
        maybe DB_TAG_DBNAME ,=> $dbname,
    );
}

sub _tags_sth {
    my ($sth) = @_;
    my (%tags, $sql);
    if (!blessed($sth) or !$sth->isa('DBI::st')) {
        $sql = "$sth";
    }
    else {
        %tags = _tags_dbh($sth->{Database});
        $sql  = $sth->{Statement};
    }
    $sql = _remove_sql_comments($sql);

    $tags{ (DB_TAG_SQL) } = $sql;

    if (my $summary = _gen_sql_summary($sql)) {
        $tags{ (DB_TAG_SQL_SUMMARY) } = $summary;
    }

    return %tags;
}

sub _remove_sql_comments {    # TODO: support engine-specific syntax properly
    my ($sql) = @_;

    $sql =~ s{
        (?> # skip over strings and quoted table names
            (['"`])            # opening quote
            .*?
            (?<!\\)(?:\\{2})*  # make sure the closing quote is not escaped
            \1                 # closing quote
        )? \K 
        | \#.*?$           # hash until end of line
        | --.*?$           # double-dash until end of line
        | /\* (?s).*? \*/  # multi-line C-style comment
    }{}gmx;

    return $sql;
}

sub _gen_sql_summary {
    my ($sql) = @_;

    # comments are removed, so the first occurence should be the keyword
    my ($type) = $sql =~ /\b(
        insert | select   | update
      | delete | truncate | show
      | alter  | create   | drop
    )/ix;
    return if not $type;

    my $table = '...';
    if ($sql =~ m{(?:from|into|update|truncate|drop|alter|table)\s+(`?)(\w+)\1}i) {
        $table = $2;
    }
    return uc($type) . ": $table";
}

sub _tags_bind_values {
    my ($bind_ref) = @_;
    return if not @$bind_ref;

    my $bind_str = join ',', map { defined $_ ? "`$_`" : 'undef' } @$bind_ref;
    return (DB_TAG_BIND ,=> $bind_str);
}

sub _tags_caller {
    my ($call_package, $call_filename, $call_line) = CORE::caller(1);
    my $call_sub = (CORE::caller(2))[3];
    return (
        maybe
        DB_TAG_CALLER_SUB     ,=> $call_sub,
        DB_TAG_CALLER_FILE    ,=> $call_filename,
        DB_TAG_CALLER_LINE    ,=> $call_line,
        DB_TAG_CALLER_PACKAGE ,=> $call_package,
    );
}

{
    my (%hidden_tags, %disabled_tags);

    sub _filter_tags {
        my ($tags) = @_;
        delete @$tags{ keys %disabled_tags, keys %hidden_tags };
        return $tags;
    }

    sub _tag_enabled {
        my ($tag) = @_;
        return !!_filter_tags({ $tag => 1 })->{$tag};
    }

    sub hide_tags {
        my ($class, @tags) = @_;;
        return if not @tags;

        undef @hidden_tags{@tags};
        return;
    }

    sub show_tags {
        my ($class, @tags) = @_;
        return if not @tags;

        delete @hidden_tags{@tags};
        return;
    }

    sub hide_tags_temporarily {
        my $class = shift;
        my @tags  = grep { not exists $hidden_tags{$_} } @_;
        $class->hide_tags(@tags);
        Scope::Context->up->reap(sub { $class->show_tags(@tags) });
    }

    sub show_tags_temporarily {
        my $class = shift;
        my @tags = grep { exists $hidden_tags{$_} } @_;
        $class->show_tags(@tags);
        Scope::Context->up->reap(sub { $class->hide_tags(@tags) });
    }

    sub _disable_tags {
        my ($class, @tags) = @_;
        undef @disabled_tags{@tags};
        return;
    }

    sub _enable_tags {
        my ($class, @tags) = @_;
        delete @disabled_tags{@tags};
        return;
    }

    sub disable_tags {
        my $class = shift;
        my @tags  = grep { not exists $disabled_tags{$_} } @_;
        $class->_disable_tags(@tags);
        Scope::Context->up->reap(sub { $class->_enable_tags(@tags) });
    }
}

sub _add_tag {
    my ($span, $tag, $value) = @_;
    return unless _tag_enabled($tag);
    $span->add_tag($tag => $value);
}

sub _gen_wrapper {
    my ($method, $args) = @_;
    my $row_counter     = $args->{row_counter};
    my $sig_processor   = $args->{signature};
    my $count_condition = $args->{count_condition};
    my $method_name     = B::svref_2object($method)->GV->NAME;

    my $can_count_rows = sub {
        defined $row_counter
            and
        !defined $count_condition || $count_condition->(@_)
    };

    return sub {
        goto $method if $is_currently_traced;
        local $is_currently_traced = 1;

        my ($statement, @bind) = $sig_processor->(@_);
        my $handle = shift;

        my $tracer = OpenTracing::GlobalTracer->get_global_tracer();
        my $scope  = $tracer->start_active_span(
            "dbi_$method_name",
            tags => _filter_tags({
                TAGS_DEFAULT,
                _tags_sth($statement),
                _tags_dbh($handle),
                _tags_bind_values(\@bind),
                _tags_caller(),
            }),
        );
        my $span = $scope->get_span();

        my $result;
        my $wantarray = wantarray;    # eval has its own
        my $failed    = !eval {
            if ($wantarray) {
                $result = [ $handle->$method(@_) ];
            }
            else {
                $result = $handle->$method(@_);
            }
            1;
        };
        my $error = $@;

        if ($failed or defined $handle->err) {
            $span->add_tag(error => 1);
        }
        elsif ($can_count_rows->($handle)) {
            my $rows = sum0(map { $row_counter->($_) } $wantarray ? @$result : $result);
            _add_tag($span, DB_TAG_ROWS,=> $rows);
        }
        $scope->close();

        die $error if $failed;
        return $wantarray ? @$result : $result;
    }
}

sub enable_temporarily {
    return if $is_enabled;

    enable();
    Scope::Context->up->reap(\&disable);
}

sub disable_temporarily {
    return unless $is_enabled;

    disable();
    Scope::Context->up->reap(\&enable);
}

sub suspend {
    return if $is_suspended;

    my $was_enabled = $is_enabled;
    disable();
    $is_suspended = 1;
    Scope::Context->up->reap(sub { $is_suspended = 0; enable() if $was_enabled });
}

1;
