package DBI::Log;

use 5.006;
no strict;
no warnings;
use DBI;

our $VERSION = "0.07";
our $trace = 1;
our $path = "STDERR";
our $array;
our $fh;
our @queries;

INIT {
    my $orig_execute = \&DBI::st::execute;
    *DBI::st::execute = sub {
        my ($sth, @args) = @_;
        log_("execute", $sth->{Database}, $sth->{Statement}, \@args);
        my $retval = $orig_execute->($sth, @args);
        return $retval;
    };

    my $orig_selectall_arrayref = \&DBI::db::selectall_arrayref;
    *DBI::db::selectall_arrayref = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectall_arrayref", $dbh, $query, \@args);
        my $retval = $orig_selectall_arrayref->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_selectcol_arrayref = \&DBI::db::selectcol_arrayref;
    *DBI::db::selectcol_arrayref = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectcol_arrayref", $dbh, $query, \@args);
        my $retval = $orig_selectcol_arrayref->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_selectall_hashref = \&DBI::db::selectall_hashref;
    *DBI::db::selectall_hashref = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectall_hashref", $dbh, $query, \@args);
        my $retval = $orig_selectall_hashref->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_selectrow_arrayref = \&DBI::db::selectrow_arrayref;
    *DBI::db::selectrow_arrayref = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectrow_arrayref", $dbh, $query, \@args);
        my $retval = $orig_selectrow_arrayref->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_selectrow_array = \&DBI::db::selectrow_array;
    *DBI::db::selectrow_array = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectrow_array", $dbh, $query, \@args);
        my $retval = $orig_selectrow_array->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_selectrow_hashref = \&DBI::db::selectrow_hashref;
    *DBI::db::selectrow_hashref = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("selectrow_hashref", $dbh, $query, \@args);
        my $retval = $orig_selectrow_hashref->($dbh, $query, $yup, @args);
        return $retval;
    };

    my $orig_do = \&DBI::db::do;
    *DBI::db::do = sub {
        my ($dbh, $query, $yup, @args) = @_;
        log_("do", $dbh, $query, \@args);
        my $retval = $orig_do->($dbh, $query, $yup, @args);
        return $retval;
    };
}

sub log_ {
    my ($name, $dbh, $query, $args) = @_;
    my $i = 0;
    my @callers;
    while (my @caller = caller($i++)) {
        push @callers, \@caller;
    }
    # subs like selectall_arrayref will call execute within it, we don't
    # want to log the same query twice
    return if (grep {$_->[0] eq "DBI::Log"} @callers) > 1;
    my $info = "-- " . scalar(localtime()) . "\n";
    $i = 0;
    for my $caller (@callers) {
        my ($package, $file, $line, $sub) = @$caller;
        next if $package eq "DBI::Log";
        $sub =~ s/.*:://;
        $sub = $name if !$i++;
        $info .= "-- $sub $file $line\n";
        last if !$trace;
    }
    open_log();
    my $i = 0;
    if ($dbh) {
        $query =~ s{\?}{$dbh->quote($args->[$i++])}eg;
    }
    if ($fh) {
        print $fh "$info$query\n\n";
    }
    if ($array) {
        push @queries, $query;
    }
}

sub open_log {
    return if $fh;
    return if !$path;
    if ($path eq "STDERR") {
        $fh = \*STDERR;
    }
    elsif ($path eq "STDOUT") {
        $fh = \*STDOUT;
    }
    elsif ($path =~ m{^~/}) {
        my $home = (getpwuid($<))[7];
        $path =~ s{^~/}{$home/};
        open $fh, ">>", $path or die "Can't open $path: $!";
    }
    else {
        open $fh, ">>", $path or die "Can't open $path: $!";
    }
}

1;

__END__

=encoding utf8

=head1 NAME

DBI::Log - Log all DBI queries

=head1 SYNOPSIS

    use DBI::Log;

=head1 DESCRIPTION

You can use this module to log all queries that are made with DBI.
You just need to include it in your script and it will work
automatically.  By default, it will send output to STDERR, which
is useful for command line scripts and for CGI scripts since STDERR
will appear in the error log.

If you want to log elsewhere, set the $DBI::Log::path variable to
a different location.

    $DBI::Log::path = "~/querylog.sql";

The log is formatted as SQL, so if you look at it in an editor, it
might be highlighted. This is what the output may look like:

    -- Fri Sep 11 17:31:18 2015 taking 0 seconds
    -- execute t/test.t 18
    CREATE TABLE foo (a INT, b INT)

    -- Fri Sep 11 17:31:18 2015 taking 0 seconds
    -- do t/test.t 21
    INSERT INTO foo VALUES ('1', '2')

    -- Fri Sep 11 17:31:18 2015 taking 0 seconds
    -- selectcol_arrayref t/test.t 24
    SELECT * FROM foo

    -- Fri Sep 11 17:31:18 2015 taking 0 seconds
    -- do t/test.t 27
    -- (eval) t/test.t 27
    INSERT INTO bar VALUES ('1', '2')

Each query in the log is prepended with the date, the time it took
to run, and a stack trace. You can disable the stack trace by setting
$DBI::Log::trace to a false value.

You can set $DBI::Log::array to a true value and then all queries
will end up in @DBI::Log::queries.

There is a built-in way to log with DBI, which can be enabled with
DBI->trace(1), but the output is not easy to read through.

This module integrates placeholder values into the query, so the
log will contain valid queries.

=head1 METACPAN

L<https://metacpan.org/pod/DBI::Log>

=head1 REPOSITORY

L<https://github.com/zorgnax/dbilog>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 CONTRIBUTORS

Árpád Szász, E<lt>arpad.szasz@plenum.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

