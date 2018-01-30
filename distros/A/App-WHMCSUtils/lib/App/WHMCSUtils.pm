## no critic (InputOutput::RequireBriefOpen)

package App::WHMCSUtils;

our $DATE = '2018-01-29'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use IPC::System::Options qw(system readpipe);
use Path::Tiny;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to WHMCS',
};

our %args_db = (
    db_name => {
        schema => 'str*',
        req => 1,
    },
    db_host => {
        schema => 'str*',
        default => 'localhost',
    },
    db_port => {
        schema => 'net::port*',
        default => '3306',
    },
    db_user => {
        schema => 'str*',
    },
    db_pass => {
        schema => 'str*',
    },
);

sub _connect_db {
    require DBIx::Connect::MySQL;

    my %args = @_;

    my $dsn = join(
        "",
        "DBI:mysql:database=$args{db_name}",
        (defined($args{db_host}) ? ";host=$args{db_host}" : ""),
        (defined($args{db_port}) ? ";port=$args{db_port}" : ""),
    );

    DBIx::Connect::MySQL->connect(
        $dsn, $args{db_user}, $args{db_pass},
        {RaiseError => 1},
    );
}

$SPEC{restore_whmcs_client} = {
    v => 1.1,
    summary => "Restore a missing client from SQL database backup",
    args => {
        sql_backup_file => {
            schema => 'filename*',
            description => <<'_',

Can accept either `.sql` or `.sql.gz`.

Will be converted first to a directory where the SQL file will be extracted to
separate files on a per-table basis.

_
        },
        sql_backup_dir => {
            summary => 'Directory containing per-table SQL files',
            schema => 'dirname*',
            description => <<'_',


_
        },
        client_email => {
            schema => 'str*',
        },
        client_id => {
            schema => 'posint*',
        },
        restore_invoices => {
            schema => 'bool*',
            default => 1,
        },
        restore_hostings => {
            schema => 'bool*',
            default => 1,
        },
        restore_domains => {
            schema => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        'req_one&' => [
            ['sql_backup_file', 'sql_backup_dir'],
            ['client_email', 'client_id'],
        ],
    },
    deps => {
        prog => "mysql-sql-dump-extract-tables",
    },
    features => {
        dry_run => 1,
    },
};
sub restore_whmcs_client {

    my %args = @_;

    local $CWD;

    my $sql_backup_dir;
    my $decompress = 0;
    if ($args{sql_backup_file}) {
        return [404, "No such file: $args{sql_backup_file}"]
            unless -f $args{sql_backup_file};
        my $pt = path($args{sql_backup_file});
        my $basename = $pt->basename;
        if ($basename =~ /(.+)\.sql\z/i) {
            $sql_backup_dir = $1;
        } elsif ($basename =~ /(.+)\.sql\.gz\z/i) {
            $sql_backup_dir = $1;
            $decompress = 1;
        } else {
            return [412, "SQL backup file should be named *.sql or *.sql.gz: ".
                        "$args{sql_backup_file}"];
        }
        if (-d $sql_backup_dir) {
            log_info "SQL backup dir '$sql_backup_dir' already exists, ".
                "skipped extracting";
        } else {
            mkdir $sql_backup_dir, 0755
                or return [500, "Can't mkdir '$sql_backup_dir': $!"];
            $CWD = $sql_backup_dir;
            my @cmd;
            if ($decompress) {
                push @cmd, "zcat", $pt->absolute->stringify, "|";
            } else {
                push @cmd, "cat", $pt->absolute->stringify, "|";
            }
            push @cmd, "mysql-sql-dump-extract-tables",
                "--include-table-pattern", '^(tblclients|tblinvoices|tblinvoiceitems|tblorders)$';
            system({shell=>1, die=>1, log=>1}, @cmd);
        }
    } elsif ($args{sql_backup_dir}) {
        $sql_backup_dir = $args{sql_backup_dir};
        return [404, "No such dir: $sql_backup_dir"]
            unless -d $sql_backup_dir;
        $CWD = $sql_backup_dir;
    }

    my @sql;

    my $clientid = $args{client_id};
  FIND_CLIENT:
    {
        open my $fh, "<", "tblclients"
            or return [500, "Can't open $sql_backup_dir/tblclients: $!"];
        my $clientemail;
        $clientemail = lc $args{client_email} if defined $args{client_email};
        while (<$fh>) {
            next unless /^INSERT INTO `tblclients` \(`id`, `firstname`, `lastname`, `companyname`, `email`, [^)]+\) VALUES \((\d+),'(.*?)','(.*?)','(.*?)','(.*?)',/;
            my ($rid, $rfirstname, $rlastname, $rcompanyname, $remail) = ($1, $2, $3, $4, $5);
            if (defined $clientid) {
                # find by ID
                if ($rid == $clientid) {
                    $clientemail = $remail;
                    push @sql, $_;
                    log_info "Found client ID=%s in backup", $clientid;
                    last FIND_CLIENT;
                }
            } else {
                # find by email
                if (lc $remail eq $clientemail) {
                    $clientid = $rid;
                    push @sql, $_;
                    log_info "Found client email=%s in backup: ID=%s", $clientemail, $clientid;
                    last FIND_CLIENT;
                }
            }
        }
        return [404, "Couldn't find client email=$clientemail in database backup, please check the email or try another backup"];
    }

    my @invoiceids;
  FIND_INVOICES:
    {
        last unless $args{restore_invoices};
        open my $fh, "<", "tblinvoices"
            or return [500, "Can't open $sql_backup_dir/tblinvoices: $!"];
        while (<$fh>) {
            next unless /^INSERT INTO `tblinvoices` \(`id`, `userid`, [^)]+\) VALUES \((\d+),(\d+),/;
            my ($rid, $ruserid) = ($1, $2);
            if ($ruserid == $clientid) {
                push @invoiceids, $rid;
                push @sql, $_;
                log_info "Found client invoice in backup: ID=%s", $rid;
            }
        }
        log_info "Number of invoices found for client in backup: %d", ~~@invoiceids if @invoiceids;
    }

  FIND_INVOICEITEMS:
    {
        last unless @invoiceids;
        open my $fh, "<", "tblinvoiceitems"
            or return [500, "Can't open $sql_backup_dir/tblinvoiceitems: $!"];
        while (<$fh>) {
            next unless /^INSERT INTO `tblinvoiceitems` \(`id`, `invoiceid`, `userid`, [^)]+\) VALUES \((\d+),(\d+),(\d+)/;
            my ($rid, $rinvoiceid, $ruserid) = ($1, $2, $3);
            if (grep {$rinvoiceid == $_} @invoiceids) {
                log_trace "Adding invoice item %s for invoice #%s", $rid, $rinvoiceid;
                push @sql, $_;
            }
        }
    }

  FIND_HOSTINGS:
    {
        last unless $args{restore_hostings};
        open my $fh, "<", "tblhosting"
            or return [500, "Can't open $sql_backup_dir/tblhosting: $!"];
        while (<$fh>) {
            next unless /^INSERT INTO `tblhosting` \(`id`, `userid`, [^)]+\) VALUES \((\d+),(\d+),(\d+)/;
            my ($rid, $ruserid) = ($1, $2, $3);
            if ($ruserid == $clientid) {
                log_trace "Found hosting for client in backup: ID=%d", $rid;
                push @sql, $_;
            }
        }
    }

  FIND_DOMAINS:
    {
        last unless $args{restore_domains};
        open my $fh, "<", "tbldomains"
            or return [500, "Can't open $sql_backup_dir/tbldomains: $!"];
        while (<$fh>) {
            next unless /^INSERT INTO `tbldomains` \(`id`, `userid`, [^)]+\) VALUES \((\d+),(\d+),(\d+)/;
            my ($rid, $ruserid) = ($1, $2, $3);
            if ($ruserid == $clientid) {
                log_trace "Found domain for client in backup: ID=%d", $rid;
                push @sql, $_;
            }
        }
    }

    # TODO: tickets?

    # records in tblaccounts (transactions) are not deleted when client is
    # deleted

    [200, "OK", \@sql];
}

sub _add_monthly_revs {
    my ($row, $date1, $date2, $date_old_limit) = @_;

    if ($date2) {
        my ($y1, $m1) = $date1 =~ /\A(\d{4})-(\d{2})-(\d{2})/
            or die "Can't parse date1 '$date1'";
        my ($y2, $m2) = $date2 =~ /\A(\d{4})-(\d{2})-(\d{2})/
            or die "Can't parse date2 '$date2'";

        # first calculate how many months
        my ($y, $m) = ($y1, $m1);
        my $num_months = 0;
        while (1) {
            $num_months++;
            last if $y == $y2 && $m == $m2;
            $m++; if ($m == 13) { $m = 1; $y++ }
        }
        ($y, $m) = ($y1, $m1);
        for my $i (1..$num_months) {
            my $key = sprintf("rev_%04d_%02d", $y, $m);
            if ($date_old_limit) {
                $date_old_limit =~ /^(\d{4})-(\d{2})/;
                $key = "rev_past" if $key lt "rev_${1}_$2";
            }
            $row->{$key} += $row->{amount} / $num_months;
            $m++; if ($m == 13) { $m = 1; $y++ }
        }
    } else {
        $date1 =~ /\A(\d{4})-(\d{2})-(\d{2})/
            or die "Can't parse date '$date1'";
        $row->{"rev_${1}_${2}"} = $row->{amount};
    }
}

$SPEC{calc_deferred_revenue} = {
    v => 1.1,
    description => <<'_',

This utility collects invoice items from paid invoices, filters eligible ones,
then defers the revenue to separate months for items that should be deferred,
and finally sums the amounts to calculate total monthly deferred revenues.

This utility can also be instructed (via setting the `full` option to true) to
output the full CSV report (each items with their categorizations and deferred
revenues).

Recognizes English and Indonesian description text.

Categorization heuristics:

* Fund deposits are not recognized as revenues.
* Hosting revenues are deferred, but when the description indicates starting and
  ending dates and the dates are not too old.
* Domain and addon revenues are not deferred, they are recognized immediately.
* Other items will be assumed as immediate revenues.

Extra rules (applied first) can be specified via the `extra_rules` option.

To use this utility, install the Perl CPAN distribution <pm:App::WHMCSUtils>.
Then, create a configuration file `~/whmcs-calc-deferred-revenue.conf`
containing something like:

    db_name=YOURDBNAME
    db_host=YOURDBHOST
    db_user=YOURDBUSER
    db_pass=YOURDBPASS

`db_host` defaults to `localhost`. `db_user` and `db_pass` can be omitted if you
have `/etc/my.cnf` or `~/.my.cnf`. This utility can search for username/password
from those files.

You can also add other configuration like `extra_rules`, e.g.:

    extra_rules=[{"type": "^$", "description": "^(?^i)sewa\\b.*ruang", "category": "rent"}]

You can then run the utility for the desired, e.g.:

    % whmcs-calc-deferred-revenue --date-start 2013-01-01 --date-end 2017-10-31 \
        --date-old-limit 2013-01-01 --full --output-file ~/output.csv

Wait for a while and check the output at `~/output.csv`.

_
    args => {
        %args_db,
        date_start => {
            summary => 'Start from this date (based on invoice payment date)',
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
            tags => ['category:filtering'],
        },
        date_end => {
            summary => 'End at this date (based on invoice payment date)',
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
            tags => ['category:filtering'],
        },
        date_old_limit => {
            summary => 'Set what date will be considered too old to recognize item as revenue',
            schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
            description => <<'_',

Default is 2008-01-01.

_
        },
        extra_rules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'extra_rule',
            schema => ['array*', of=>['hash*', of=>'re*']],
            description => <<'_',

Example (in JSON):

    [
        {
            "type": "^$",
            "description": "^SEWA",
            "category": "rent"
        }
    ]

_
            tags => ['category:rule'],
        },
        full => {
            schema => 'true*',
            tags => ['category:output'],
        },
        output_file => {
            schema => 'filename*',
        },
    },
    features => {
        progress => 1,
    },
};
sub calc_deferred_revenue {
    require String::Escape;

    my %args = @_;

    log_trace "args=%s", \%args;

    my $date_old_limit = $args{date_old_limit} ?
        $args{date_old_limit}->ymd : '2008-01-01';

    my $progress = $args{-progress};

    my $dbh = _connect_db(%args);

    my $extra_wheres = '';
    if ($args{date_start}) {
        $extra_wheres .= " AND i.datepaid >= '".$args{date_start}->ymd()." 00:00:00'";
    }
    if ($args{date_end}) {
        $extra_wheres .= " AND i.datepaid <= '".$args{date_end}->ymd()." 23:59:59'";
    }

    my @fields = qw(id invoiceid datepaid clientid type relid amount category description);

    my $sth = $dbh->prepare(<<_);
SELECT

  ii.id id,
  ii.invoiceid invoiceid,
  ii.userid clientid,
  ii.type type,
  ii.relid relid,
  ii.description description,
  ii.amount amount,
  -- ii.taxed taxed,
  -- ii.duedate duedate,
  -- ii.notes notes,

  i.datepaid datepaid

FROM tblinvoiceitems ii
LEFT JOIN tblinvoices i ON ii.invoiceid=i.id
WHERE
  i.status='Paid' AND
  i.datepaid IS NOT NULL AND
  ii.amount <> 0 $extra_wheres
ORDER BY i.datepaid
_

    log_info "Loading all paid invoice items ...";
    $sth->execute;
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row;
    }
    log_info "Number of invoice items: %d", ~~@rows;

    my $num_errors = 0;

    $progress->target(~~@rows) if $progress;
  ITEM:
    for my $i (0..$#rows) {
        my $row = $rows[$i];
        my $label = "(".($i+1)."/".(scalar @rows).
            ") item#$row->{id} inv#=$row->{invoiceid} datepaid=#$row->{datepaid} type=".($row->{type} // '')." amount=$row->{amount} description='".String::Escape::backslash($row->{description})."'";
        log_trace "Processing $label: %s ...", $row;
        $progress->update if $progress;

        my ($date1, $date2);
      EXTRACT_DATE:
        {
            last unless $row->{description} =~ m!\((?<date1>(?<d1>\d{2})/(?<m1>\d{2})/(?<y1>\d{4})) - (?<date2>(?<d2>\d{2})/(?<m2>\d{2})/(?<y2>\d{4}))\)!;
            my %m = %+;
          CHECK_DATE: {
                $m{d1} <= 31 or do { log_warn "$label: Day is >31 in date1 '$m{date1}', assuming immediate"; undef $date1; last CHECK_DATE };
                $m{m1} <= 12 or do { log_warn "$label: Month is >12 in date1 '$m{date1}', assuming immediate"; undef $date1; last CHECK_DATE };
                $m{d2} <= 31 or do { log_warn "$label: Day is >31 in date2 '$m{date1}', assuming immediate"; undef $date2; last CHECK_DATE };
                $m{m2} <= 12 or do { log_warn "$label: Month is >12 in date2 '$m{date2}', assuming immediate"; undef $date2; last CHECK_DATE };
                $date1 = "$m{y1}-$m{m1}-$m{d1}";
                $date2 = "$m{y2}-$m{m2}-$m{d2}";
                if ($date1 gt $date2) {
                    log_warn "$label: Date1 '$date1' > date2 '$date2', assuming immediate";
                    undef $date1; undef $date2;
                    last CHECK_DATE;
                }
                # sanity check
                if ($date2 lt $date_old_limit) {
                    $row->{category} = 'old';
                    $row->{rev_past} = $row->{amount};
                    log_info "$label: Date2 '$date2' is too old (< $date_old_limit), recognizing as past revenue";
                    next ITEM;
                }
            }
        }

        # sometimes invoices are created manually (type=''), so we have to infer
        # type from description
        my $type = $row->{type};
      INFER_TYPE: {
            last if $type;
            if ($row->{description} =~ /^(perpanjangan domain|domain renewal)/i && $date1 && $date2) {
                $type = 'Domain';
                last INFER_TYPE;
            }
            if ($row->{description} =~ /^(perpanjangan hosting|hosting renewal)/i && $date1 && $date2) {
                $type = 'Domain';
                last INFER_TYPE;
            }
            if ($row->{description} =~ /^(opsi tambahan|addon)\b/i && $date1 && $date2) {
                $type = 'Addon';
                last INFER_TYPE;
            }
            # assume anything else with date range as hosting
            if ($date1 && $date2) {
                $type = 'Hosting';
                last INFER_TYPE;
            }
        }

      ITEM_DEPOSIT:
        {
            last unless $type eq 'AddFunds' || ($type eq '' && $row->{description} =~ /^deposit dana/i);
            $row->{category} = 'deposit';
            log_trace "$label: AddFunds is not a revenue";
            next ITEM;
        }

      ITEM_EXTRA_RULES:
        {
            last unless $args{extra_rules} && @{$args{extra_rules}};
            for my $i (0..$#{ $args{extra_rules} }) {
                my $rule = $args{extra_rules}[$i];
                if ($rule->{type}) {
                    log_trace "Matching extra rule: type: %s vs %s", $rule->{type}, $type;
                    next unless $type =~ /$rule->{type}/;
                }
                if ($rule->{description}) {
                    log_trace "Matching extra rule: description: %s vs %s", $rule->{description}, $row->{description};
                    next unless $row->{description} =~ /$rule->{description}/;
                }
                log_trace "%s: matches rule #%d", $label, $i+1;
                $row->{category} = $rule->{category};
                goto DEFER;
            }
        }

      ITEM_HOSTING:
        {
            last unless $type =~ /^Hosting$/ && $date1 && $date2;
            $row->{category} = 'revenue_deferred';
            log_debug "$label: Item is hosting, deferring revenue $row->{amount} from $date1 to $date2";
            goto DEFER;
        }

        if ($type =~ /^(|Invoice|Item|Hosting|Addon|Domain|DomainAddonIDP|DomainRegister|DomainTransfer|PromoDomain|PromoHosting|Upgrade|MG_DIS_CHARGE)$/) {
            $row->{category} = 'revenue_immediate';
            log_debug "$label: Type is '$type', recognized revenue $row->{amount} immediately (not deferred) at date of payment $row->{datepaid}";
            goto DEFER;
        }

        unless ($row->{category}) {
            $row->{category} = 'revenue_immediate';
            log_warn "$label: Can't categorize, assuming immediate";
            goto DEFER;
        }

      DEFER:
        {
            if ($row->{category} eq 'revenue_deferred' && $date1 && $date2) {
                _add_monthly_revs($row, $date1, $date2, $date_old_limit);
            } elsif ($row->{category} eq 'revenue_immediate') {
                _add_monthly_revs($row, $row->{datepaid}, undef);
            }
        }
        $row->{type} = "$type (inferred)" if !$row->{type} && $type;
    }

    if ($num_errors) {
        return [500, "There are still errors in the invoice items, please fix first"];
    }

    log_info "Calculating revenues ...";
    my %totalrow;
    for my $row (@rows) {
        for my $k (keys %$row) {
            if ($k =~ /^rev_(\d{4})_(\d{2})$/) {
                $totalrow{$k} += $row->{$k};
            } elsif ($k =~ /^rev_past$/) {
                $totalrow{$k} += $row->{$k};
            }
        }
    }
    $totalrow{rev_total_nonpast} = 0;
    for (grep {/^rev_\d/} keys %totalrow) {
        $totalrow{rev_total_nonpast} += $totalrow{$_};
    }

    if ($args{full}) {
        log_info "Producing CSV ...";
        $progress->target(2 * @rows);

        # collect fields to output
        my %months;
        for my $row (@rows) {
            for my $k (keys %$row) {
                $months{$k}++ if $k =~ /^rev_/;
            }
        }
        push @fields, "rev_past" if delete $months{rev_past};
        push @fields, $_ for sort keys %months;
        push @fields, "rev_total_nonpast"
            if exists $totalrow{rev_total_nonpast};

        # output rows
        my $fh;
        if ($args{output_file}) {
            open $fh, ">", $args{output_file}
                or return [500, "Can't open $args{output_file}: $!"];
        } else {
            $fh = \*STDOUT;
        }
        require Text::CSV_XS;
        my $csv = Text::CSV_XS->new({ binary=>1 });

        # header row
        $csv->combine(@fields);
        print $fh $csv->string, "\n";

        # data row
        for my $row (@rows) {
            $progress->update;
            $csv->combine(map {$row->{$_} // ''} @fields);
            print $fh $csv->string, "\n";
        }

        # total row
        $totalrow{id} = "TOTAL";
        $csv->combine(map {$totalrow{$_} // ''} @fields);
        print $fh $csv->string, "\n";
    }

    $progress->finish if $progress;
    return [200, "OK", \%totalrow];
}

1;
# ABSTRACT: CLI utilities related to WHMCS

__END__

=pod

=encoding UTF-8

=head1 NAME

App::WHMCSUtils - CLI utilities related to WHMCS

=head1 VERSION

This document describes version 0.005 of App::WHMCSUtils (from Perl distribution App-WHMCSUtils), released on 2018-01-29.

=head1 FUNCTIONS


=head2 calc_deferred_revenue

Usage:

 calc_deferred_revenue(%args) -> [status, msg, result, meta]

This utility collects invoice items from paid invoices, filters eligible ones,
then defers the revenue to separate months for items that should be deferred,
and finally sums the amounts to calculate total monthly deferred revenues.

This utility can also be instructed (via setting the C<full> option to true) to
output the full CSV report (each items with their categorizations and deferred
revenues).

Recognizes English and Indonesian description text.

Categorization heuristics:

=over

=item * Fund deposits are not recognized as revenues.

=item * Hosting revenues are deferred, but when the description indicates starting and
ending dates and the dates are not too old.

=item * Domain and addon revenues are not deferred, they are recognized immediately.

=item * Other items will be assumed as immediate revenues.

=back

Extra rules (applied first) can be specified via the C<extra_rules> option.

To use this utility, install the Perl CPAN distribution L<App::WHMCSUtils>.
Then, create a configuration file C<~/whmcs-calc-deferred-revenue.conf>
containing something like:

 db_name=YOURDBNAME
 db_host=YOURDBHOST
 db_user=YOURDBUSER
 db_pass=YOURDBPASS

C<db_host> defaults to C<localhost>. C<db_user> and C<db_pass> can be omitted if you
have C</etc/my.cnf> or C<~/.my.cnf>. This utility can search for username/password
from those files.

You can also add other configuration like C<extra_rules>, e.g.:

 extra_rules=[{"type": "^$", "description": "^(?^i)sewa\\b.*ruang", "category": "rent"}]

You can then run the utility for the desired, e.g.:

 % whmcs-calc-deferred-revenue --date-start 2013-01-01 --date-end 2017-10-31 \
     --date-old-limit 2013-01-01 --full --output-file ~/output.csv

Wait for a while and check the output at C<~/output.csv>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date_end> => I<date>

End at this date (based on invoice payment date).

=item * B<date_old_limit> => I<date>

Set what date will be considered too old to recognize item as revenue.

Default is 2008-01-01.

=item * B<date_start> => I<date>

Start from this date (based on invoice payment date).

=item * B<db_host> => I<str> (default: "localhost")

=item * B<db_name>* => I<str>

=item * B<db_pass> => I<str>

=item * B<db_port> => I<net::port> (default: 3306)

=item * B<db_user> => I<str>

=item * B<extra_rules> => I<array[hash]>

Example (in JSON):

 [
     {
         "type": "^$",
         "description": "^SEWA",
         "category": "rent"
     }
 ]

=item * B<full> => I<true>

=item * B<output_file> => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 restore_whmcs_client

Usage:

 restore_whmcs_client(%args) -> [status, msg, result, meta]

Restore a missing client from SQL database backup.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<client_email> => I<str>

=item * B<client_id> => I<posint>

=item * B<restore_domains> => I<bool> (default: 1)

=item * B<restore_hostings> => I<bool> (default: 1)

=item * B<restore_invoices> => I<bool> (default: 1)

=item * B<sql_backup_dir> => I<dirname>

Directory containing per-table SQL files.

=item * B<sql_backup_file> => I<filename>

Can accept either C<.sql> or C<.sql.gz>.

Will be converted first to a directory where the SQL file will be extracted to
separate files on a per-table basis.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-WHMCSUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-WHMCSUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-WHMCSUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
