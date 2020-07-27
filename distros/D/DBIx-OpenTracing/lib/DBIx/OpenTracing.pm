package DBIx::OpenTracing;
use strict;
use warnings;
use feature qw[ state ];
use syntax 'maybe';
use B;
use DBI;
use List::Util qw[ sum ];
use OpenTracing::GlobalTracer;
use Scalar::Util qw[ blessed ];
use Scope::Context;

our $VERSION = 'v0.0.3';

use constant TAGS_DEFAULT => ('db.type' => 'sql');

use constant {
    _DBI_EXECUTE            => \&DBI::st::execute,
    _DBI_DO                 => \&DBI::db::do,
    _DBI_SELECTALL_ARRAYREF => \&DBI::db::selectall_arrayref,
    _DBI_SELECTROW_ARRAYREF => \&DBI::db::selectrow_arrayref,
    _DBI_SELECTROW_ARRAY    => \&DBI::db::selectrow_array,
};
use constant _PP_MODE => !!$INC{'DBI/PurePerl.pm'};

if (%DBIx::QueryLog::SKIP_PKG_MAP) {    # hide from DBIx::QueryLog's caller()
    $DBIx::QueryLog::SKIP_PKG_MAP{ (__PACKAGE__) } = 1;
}

my ($is_enabled, $is_suspended);

sub _numeric_result { 0 + $_[0] }
sub _array_size     { scalar @{ $_[0] } }

sub enable {
    return if $is_enabled or $is_suspended;

    state $do                 = _gen_wrapper(_DBI_DO, \&_numeric_result);
    state $selectall_arrayref = _gen_wrapper(_DBI_SELECTALL_ARRAYREF, \&_array_size);
    state $selectrow_arrayref = _gen_wrapper(_DBI_SELECTROW_ARRAYREF);
    state $selectrow_array    = _gen_wrapper(_DBI_SELECTROW_ARRAY);
 
    no warnings 'redefine';
    *DBI::st::execute = \&_execute;

    if (not _PP_MODE) {    # everything goes through execute() in PP mode
        *DBI::db::do                 = $do;
        *DBI::db::selectall_arrayref = $selectall_arrayref;
        *DBI::db::selectrow_arrayref = $selectrow_arrayref;
        *DBI::db::selectrow_array    = $selectrow_array;
    }
 
    $is_enabled = 1;

    return;
}

sub disable {
    return unless $is_enabled;

    no warnings 'redefine';
    *DBI::st::execute = _DBI_EXECUTE;

    if (not _PP_MODE) {
        *DBI::db::do                 = _DBI_DO;
        *DBI::db::selectall_arrayref = _DBI_SELECTALL_ARRAYREF;
        *DBI::db::selectrow_arrayref = _DBI_SELECTROW_ARRAYREF;
        *DBI::db::selectrow_array    = _DBI_SELECTROW_ARRAY;
    }
 
    $is_enabled = 0;

    return;
}

sub import   { enable() }
sub unimport { disable() }

sub _tags_dbh {
    my ($dbh) = @_;
    return (
        maybe
        'db.user'     => $dbh->{Username},
        'db.instance' => $dbh->{Name},
    );
}

sub _tags_sth {
    my ($sth) = @_;
    return ('db.statement' => $sth) if !blessed($sth) or !$sth->isa('DBI::st');
    return (
        _tags_dbh($sth->{Database}),
        'db.statement' => $sth->{Statement},
    );
}

sub _execute {
    my $sth = shift;
    
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer();
    my $scope = $tracer->start_active_span(
        'dbi_execute',
        tags => { TAGS_DEFAULT, _tags_sth($sth) },
    );
    my $span = $scope->get_span();

    my $result;
    my $failed = !eval { $result = $sth->${ \_DBI_EXECUTE }(@_); 1 };
    my $error  = $@;

    if ($failed or not defined $result) {
        $span->add_tag(error => 1);
    }
    elsif ($sth->{NUM_OF_FIELDS} == 0) {    # non-select statement
        $span->add_tag('db.rows' => $result + 0);
    }
    $scope->close();

    die $error if $failed;
    return $result;
}

sub _gen_wrapper {
    my ($method, $row_counter) = @_;
    my $method_name = B::svref_2object($method)->GV->NAME;

    return sub {
        my $dbh = shift;
        my ($statement) = @_;

        my $tracer = OpenTracing::GlobalTracer->get_global_tracer();
        my $scope = $tracer->start_active_span("dbi_$method_name",
            tags => {
                TAGS_DEFAULT,
                _tags_sth($statement),
                _tags_dbh($dbh),
            },
        );
        my $span = $scope->get_span();

        my $result;
        my $wantarray = wantarray;          # eval has its own
        my $failed    = !eval {
            if ($wantarray) {
                $result = [ $dbh->$method(@_) ];
            }
            else {
                $result = $dbh->$method(@_);
            }
            1;
        };
        my $error = $@;

        if ($failed or defined $dbh->err) {
            $span->add_tag(error => 1);
        }
        elsif (defined $row_counter) {
            my $rows = sum(map { $row_counter->($_) } $wantarray ? @$result : $result);
            $span->add_tag('db.rows' => $rows);
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
