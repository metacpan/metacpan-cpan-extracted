package App::idxdb;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-22'; # DATE
our $DIST = 'App-idxdb'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use Data::Clone qw(clone);
use DateTime;
use File::chdir;

sub _set_args_default {
    my $args = shift;
    if (!$args->{dbpath}) {
        require File::HomeDir;
        $args->{dbpath} = File::HomeDir->my_home . '/idxdb.db';
    }
}

sub _connect_db {
    require DBI;

    my ($dbpath, $mode) = @_;

    if ($mode eq 'ro') {
        # avoid creating the database file automatically if we are only in
        # read-only mode
        die "Can't find index '$dbpath', check that path is correct. ".
            "Or maybe you should run the 'update' subcommand first to create the database.\n" unless -f $dbpath;
    }
    log_trace("Connecting to SQLite database at %s ...", $dbpath);
    DBI->connect("dbi:SQLite:database=$dbpath", undef, undef,
                 {RaiseError=>1});
}

sub _init {
    my ($args, $mode) = @_;

    unless ($App::idxdb::state) {
        _set_args_default($args);
        my $state = {
            #dbpath => $args->{dbpath},
            dbh => _connect_db($args->{dbpath}, $mode),
        };
        $App::idxdb::state = $state;
    }
    $App::idxdb::state;
}

my $today = DateTime->today;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Import data for stocks on the IDX (Indonesian Stock Exchange) and perform queries on them',
};

my %ownership_fields = (
    LocalIS => 'Local insurance',
    LocalCP => 'Local corporate',
    LocalPF => 'Local pension fund',
    LocalIB => 'Local bank',
    LocalID => 'Local individual',
    LocalMF => 'Local mutual fund',
    LocalSC => 'Local securities',
    LocalFD => 'Local foundation',
    LocalOT => 'Local other',
    LocalTotal => 'Local total',

    ForeignIS => 'Foreign insurance',
    ForeignCP => 'Foreign corporate',
    ForeignPF => 'Foreign pension fund',
    ForeignIB => 'Foreign bank',
    ForeignID => 'Foreign individual',
    ForeignMF => 'Foreign mutual fund',
    ForeignSC => 'Foreign securities',
    ForeignFD => 'Foreign foundation',
    ForeignOT => 'Foreign other',
    ForeignTotal => 'Foreign total',
);
my @ownership_fields = sort keys %ownership_fields;

my %daily_fields = (
    'Bid' => {type=>'price'},
    'BidVolume' => {type=>'volume'},
    'Change' => {type=>'price'},
    'Close' => {type=>'price'},
    'DelistingDate' => {type=>'date'},
    'FirstTrade' => {type=>'price'}, # != OpenPrice.
    'ForeignBuy' => {type=>'volume'},
    'ForeignSell' => {type=>'volume'},
    'ForeignNetBuy' => {type=>'volume'}, # calculated
    'AccumForeignBuy'    => {type=>'accum_volume'}, # calculated
    'AccumForeignSell'   => {type=>'accum_volume'}, # calculated
    'AccumForeignNetBuy' => {type=>'accum_volume'}, # calculated
    'Frequency' => {type=>'freq'},
    'High' => {type=>'price'},
    'IDStockSummary' => {type=>'str'},
    'IndexIndividual' => {type=>'index'},
    'ListedShares' => {type=>'num'},
    'Low' => {type=>'price'},
    'NonRegularFrequency' => {type=>'freq'},
    'NonRegularValue' => {type=>'money'},
    'NonRegularVolume' => {type=>'volume'},
    'Offer' => {type=>'price'},
    'OfferVolume' => {type=>'volume'},
    'OpenPrice' => {type=>'price'},
    'Previous' => {type=>'price'},
    'Remarks' => {type=>'str'},
    'TradebleShares' => {type=>'num'},
    'Value' => {type=>'money'},
    'Volume' => {type=>'volume'},
    'WeightForIndex' => {type=>'num'},
);
my @daily_fields = sort keys %daily_fields;

our %args_common = (
    dbpath => {
        summary => 'Path for SQLite database',
        description => <<'_',

If not specified, will default to `~/idxdb.db`.

_
        schema => 'str*',
        tags => ['common'],
    },
);

our %arg0_stock = (
    stock => {
        schema => 'idx::listed_stock_code*', # XXX allow unlisted ones too in the future
        req => 1,
        pos => 0,
    },
);

our %arg0_stocks = (
    stocks => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'stock',
        schema => ['array*', of=>'idx::listed_stock_code*', min_len=>1], # XXX allow unlisted ones too in the future
        req => 1,
        pos => 0,
        slurpy => 1,
    },
);

our %argsopt_filter_date = (
    date_start => {
        schema => ['date*', 'x.perl.coerce_to' => 'DateTime', 'x.perl.coerce_rules'=>['From_str::natural']],
        tags => ['category:filtering'],
        default => $today->clone->subtract(days=>30)->epoch,
        cmdline_aliases => {
            'week'   => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>     7); $_[0]{date_end} = $today}},
            '1week'  => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>     7); $_[0]{date_end} = $today}},
            'month'  => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>    30); $_[0]{date_end} = $today}},
            '1month' => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>    30); $_[0]{date_end} = $today}},
            '3month' => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>    90); $_[0]{date_end} = $today}},
            '6month' => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>   180); $_[0]{date_end} = $today}},
            'ytd'    => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->set(month=>1, day=>1);  $_[0]{date_end} = $today}},
            'year'   => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>   365); $_[0]{date_end} = $today}},
            '1year'  => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>   365); $_[0]{date_end} = $today}},
            '3year'  => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=> 3*365); $_[0]{date_end} = $today}},
            '5year'  => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=> 5*365); $_[0]{date_end} = $today}},
            '10year' => {is_flag=>1, code=>sub {$_[0]{date_start} = $today->clone->subtract(days=>10*365); $_[0]{date_end} = $today}},
        },
    },
    date_end => {
        schema => ['date*', 'x.perl.coerce_to' => 'DateTime', 'x.perl.coerce_rules'=>['From_str::natural']],
        tags => ['category:filtering'],
        default => $today->epoch,
    },
);

my $sch_ownership_field = ['str*'=>{in=>\@ownership_fields, 'x.in.summaries'=>[map {$ownership_fields{$_}} @ownership_fields]}];
my $sch_daily_field     = ['str*'=>{in=>\@daily_fields}];

our %argopt_field_ownership = (
    field => {
        schema => $sch_ownership_field,
        tags => ['category:field_selection'],
        default => 'ForeignTotal',
    },
);

our %argopt_fields_ownership = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        schema => ['array*', of=>$sch_ownership_field, 'x.perl.coerce_rules'=>['From_str::comma_sep']],
        tags => ['category:field_selection'],
        default => ['LocalTotal', 'ForeignTotal'],
        cmdline_aliases => {
            fields_all           => {is_flag=>1, code=>sub { $_[0]{fields} = \@ownership_fields }},
            fields_foreign       => {is_flag=>1, code=>sub { $_[0]{fields} = [grep {/Foreign/ && $_ ne 'ForeignTotal'} @ownership_fields] }},
            fields_foreign_total => {is_flag=>1, code=>sub { $_[0]{fields} = ['ForeignTotal'] }},
            fields_local         => {is_flag=>1, code=>sub { $_[0]{fields} = [grep {/Local/} @ownership_fields] }},
        },
    },
);

our %argopt_field_daily = (
    field => {
        schema => $sch_daily_field,
        tags => ['category:field_selection'],
        default => 'AccumForeignNetBuy',
    },
);

our %argopt_fields_daily = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        schema => ['array*', of=>$sch_daily_field, 'x.perl.coerce_rules'=>['From_str::comma_sep']],
        tags => ['category:field_selection'],
        default => ['Volume','Value','ForeignNetBuy'],
        cmdline_aliases => {
            fields_all         => {is_flag=>1, code=>sub { $_[0]{fields} = \@daily_fields }},
            fields_price       => {is_flag=>1, code=>sub { $_[0]{fields} = [qw/FirstTrade OpenPrice High Low Close/] }},
            fields_price_close => {is_flag=>1, code=>sub { $_[0]{fields} = [qw/Close/] }},
        },
    },
);

our %argopt_graph = (
    graph => {
        summary => 'Show graph instead of table',
        schema => 'bool*',
        tags => ['category:action'],
    },
);

$SPEC{update} = {
    v => 1.1,
    summary => 'Update data',
    description => <<'_',

Currently this routine imports from text files in the `gudangdata` repository on
the local filesystem. Functionality to import from server directly using
<pm:Finance::SE::IDX> and <pm:Finance::ID::KSEI> will be added in the future.

_
    args => {
        %args_common,
        gudangdata_path => {
            schema => 'dirname*',
            req => 1,
        },
    },
};
sub update {
    require DateTime;
    require DBIx::Util::Schema;
    require JSON::MaybeXS;

    my %args = @_;

    my $gd_path = $args{gudangdata_path};

    my $state = _init(\%args, 'rw');
    my $dbh = $state->{dbh};
    my $now = DateTime->now;

  UPDATE_META:
    {
        my $table_exists = DBIx::Util::Schema::table_exists($dbh, 'meta');
        last if $table_exists;
        log_info "Creating meta table ...";
        $dbh->do("CREATE TABLE meta (name TEXT PRIMARY KEY, value TEXT)");
    }

    my $sth_sel_meta = $dbh->prepare("SELECT value FROM meta WHERE name=?");
    my $sth_upd_meta = $dbh->prepare("INSERT OR REPLACE INTO meta (name,value) VALUES (?,?)");

  UPDATE_STOCK:
    {
        local $CWD = "$gd_path/table/idx_stock";
        my @st = stat "data.tsv" or die "Can't stat $CWD/data.tsv: $!";
        open my $fh, "<", "data.tsv" or die "Can't open $CWD/data.tsv: $!";

        # for simplicity, we replce whole table when updating data
        my $table_exists = DBIx::Util::Schema::table_exists($dbh, 'stock');
        if (!$table_exists) {
            log_info "Creating table 'stock' ...";
            $dbh->do("CREATE TABLE stock (code VARCHAR(4) PRIMARY KEY, sector TEXT NOT NULL, name TEXT NOT NULL, listing_date TEXT NOT NULL, shares DECIMAL NOT NULL, board TEXT NOT NULL)");
        }
        $sth_sel_meta->execute("stock_table_mtime");
        my ($stock_table_mtime) = $sth_sel_meta->fetchrow_array;
        if (!$stock_table_mtime || $stock_table_mtime < $st[9]) {
            my $sth_ins_stock = $dbh->prepare("INSERT INTO stock (code,sector,name,listing_date,shares,board) VALUES (?,?,?,?,?,?)");
            log_info "Updating table 'stock' ...";
            $dbh->begin_work;
            $dbh->do("DELETE FROM stock");
            <$fh>;
            while (my $line = <$fh>) {
                chomp $line;
                $sth_ins_stock->execute(split /\t/, $line);
            }
            $sth_upd_meta->execute("stock_table_mtime", time());
            $dbh->commit;
        }
    }

  UPDATE_DAILY_TRADING_SUMMARY:
    {
        log_trace "Updating daily trading summary ...";
        my $table_exists = DBIx::Util::Schema::table_exists($dbh, 'daily_trading_summary');
        my @table_fields;
        if ($table_exists) {
            @table_fields = map { $_->{COLUMN_NAME} } DBIx::Util::Schema::list_columns($dbh, 'daily_trading_summary');
        }
        local $CWD = "$gd_path/table/idx_daily_trading_summary/raw";
      YEAR:
        for my $year (reverse glob("*")) {
            local $CWD = $year;
          FILENAME:
            for my $filename (reverse glob("*.json.gz")) {
                $filename =~ /^(\d{4})(\d{2})(\d{2})/ or die;
                log_trace "Processing file $CWD/$filename ...";
                my $date = "$1-$2-${3}";
                if ($table_exists && $dbh->selectrow_array(q(SELECT 1 FROM daily_trading_summary WHERE "Date" = ?), {}, $date)) {
                    log_trace "Data for date $date already exist, skipping this date";
                    next FILENAME;
                }
                open my $fh, "gzip -cd $filename |" or die "Can't open $filename: $!";
                my $data = JSON::MaybeXS::decode_json(join("", <$fh>));
                $data = $data->[2]; $data = [] if ref $data ne 'ARRAY';
                unless ($table_exists) {
                    log_info "Creating table 'daily_trading_summary' ...";
                    my @field_defs;
                    for my $key (sort keys %{ $data->[0] }) {
                        next if $key =~ /^(No|StockName)$/;
                        my $type;
                        $type = 'DECIMAL' if $key =~ /^(OpenPrice|Close|Previous|High|Low|Change|.*Volume|Previous|FirstTrade|.*Value|.*Frequency|IndexIndividual|Offer.*|Bid.*|.*Shares|Weight.*|Foreign.*)$/;
                        $type //= 'TEXT';
                        push @table_fields, $key;
                        push @field_defs, qq("$key" $type);
                    }
                    push @table_fields, "ctime", "mtime";
                    push @field_defs  , "ctime INT NOT NULL", "mtime INT NOT NULL";
                    $dbh->do("CREATE TABLE daily_trading_summary (".join(", ", @field_defs).")");
                    $dbh->do("CREATE INDEX ix_daily_trading_summary__StockCode ON daily_trading_summary(StockCode)");
                    $dbh->do("CREATE UNIQUE INDEX ix_daily_trading_summary__Date__StockCode ON daily_trading_summary(Date,StockCode)");
                    $table_exists++;
                }
                log_info "Inserting daily trading summary for $date ..." if @$data;
                my $sql = "INSERT INTO daily_trading_summary (".join(",", map {qq("$_")} @table_fields).") VALUES (".join(",", map {"?"} @table_fields).")";
                #log_warn $sql;
                my $sth_ins_daily_trading_summary = $dbh->prepare($sql);
                $dbh->begin_work;
                for my $row (@$data) {
                    $row->{Date} =~ s/T\d.+//;
                    $row->{ctime} = time();
                    $row->{mtime} = time();
                    $sth_ins_daily_trading_summary->execute((map { $row->{$_} } @table_fields));
                }
                $dbh->commit;
            }
        }
    } # UPDATE_DAILY_TRADING_SUMMARY

  UPDATE_OWNERSHIP:
    {
        log_trace "Updating stock ownership ...";
        my $table_exists = DBIx::Util::Schema::table_exists($dbh, 'stock_ownership');
        my @table_fields;
        if ($table_exists) {
            @table_fields = map { $_->{COLUMN_NAME} } DBIx::Util::Schema::list_columns($dbh, 'stock_ownership');
        }
        local $CWD = "$gd_path/table/ksei_sec_ownership/raw";
      YEAR:
        for my $year (reverse glob("*")) {
            local $CWD = $year;
          YEARMON:
            for my $yearmon (reverse glob("*")) {
                local $CWD = $yearmon;
                my @txt_files = glob("*.txt");
                unless (@txt_files) {
                    log_debug "Directory $CWD does not contain any .txt files, skipping";
                    next YEARMON;
                }

                my $filename = $txt_files[0];
                $filename =~ /(\d{4})(\d{2})(\d{2})\./ or die;
                log_trace "Processing file $CWD/$filename ...";
                my $date = "$1-$2-${3}";
                if ($table_exists && $dbh->selectrow_array(q(SELECT 1 FROM stock_ownership WHERE "date" = ?), {}, $date)) {
                    log_debug "Data for date $date already exist, skipping this date";
                    next YEARMON;
                }
                open my $fh, "<", $filename or die "Can't open $filename: $!";
                chomp(my $line = <$fh>);
                my @fields = split /\|/, $line;
                for my $f (@fields) {
                    $f =~ s/[^A-Za-z]+//g;
                    if ($f eq 'Total') {
                        # there are two Total columns, the first one is local
                        # total, the second one is foreign total.
                        if (grep { $_ eq 'LocalTotal'} @fields) {
                            $f = 'ForeignTotal';
                        } else {
                            $f = 'LocalTotal';
                        }
                    }
                }

                unless ($table_exists) {
                    log_info "Creating table 'stock_ownership' ...";
                    my @table_field_defs;
                    push @table_fields    , "date";
                    push @table_field_defs, "date TEXT NOT NULL";
                    for my $f (@fields) {
                        next if $f =~ /^(Date|Type|SecNum)$/;
                        my $type;
                        $type = 'TEXT' if $f =~ /^(Code)$/;
                        $type //= 'DECIMAL';
                        push @table_fields, $f;
                        push @table_field_defs, qq("$f" $type);
                    }
                    push @table_fields    , "ctime", "mtime";
                    push @table_field_defs, "ctime INT NOT NULL", "mtime INT NOT NULL";
                    my $sql = "CREATE TABLE stock_ownership (".join(", ", @table_field_defs).")";
                    #log_warn $sql;
                    $dbh->do($sql);
                    $dbh->do("CREATE INDEX ix_stock_ownership__Code ON stock_ownership(Code)");
                    $dbh->do("CREATE UNIQUE INDEX ix_stock_ownership__date__Code ON stock_ownership(date,Code)");
                    $table_exists++;
                }

                log_info "Inserting stock ownership data for $date ...";
                my $sql = "INSERT INTO stock_ownership (".join(",", map {qq("$_")} @table_fields).") VALUES (".join(",", map {"?"} @table_fields).")";
                #log_warn $sql;
                my $sth_ins_stock_ownership = $dbh->prepare($sql);
                $dbh->begin_work;
                while (my $line = <$fh>) {
                    chomp($line);
                    my @row = split /\|/, $line;
                    my $row = {};
                    for (0..$#fields) { $row->{ $fields[$_] } = $row[ $_ ] }
                    next unless $row->{Type} eq 'EQUITY';
                    $row->{date}  = $date;
                    $row->{ctime} = time();
                    $row->{mtime} = time();
                    $sth_ins_stock_ownership->execute((map { $row->{$_} } @table_fields));
                }
                $dbh->commit;
            }
        }
    } # UPDATE_DAILY_TRADING_SUMMARY

    [200];
}

$SPEC{ownership} = {
    v => 1.1,
    summary => 'Show ownership of some stock through time',
    args => {
        %arg0_stock,
        %argsopt_filter_date,
        %argopt_fields_ownership,
        legend => {
            summary => 'Show legend of ownership instead (e.g. ForeignIB = foreign bank, etc)',
            schema => 'bool*',
            tags => ['category:action'],
        },
        %argopt_graph,
    },
    examples => [
        {
            summary => 'Show legends instead (e.g. ForeignIB = foreign bank, etc)',
            args => {legend=>1},
            test => 0,
        },
    ],
};
sub ownership {
    my %args = @_;
    my $stock = $args{stock};
    my $fields = $args{fields};

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    if ($args{legend}) {
        return [200, "OK", \%ownership_fields];
    }

    my @wheres;
    my @binds;
    push @wheres, "Code=?";
    push @binds, $stock;
    if ($args{date_start}) {
        push @wheres, "date >= '".$args{date_start}->ymd."'";
    }
    if ($args{date_end}) {
        push @wheres, "date <= '".$args{date_end}->ymd."'";
    }

    my $sth = $dbh->prepare("SELECT * FROM stock_ownership WHERE ".join(" AND ", @wheres)." ORDER BY date");
    $sth->execute(@binds);
    my @rows;

    while (my $row = $sth->fetchrow_hashref) {
        delete $row->{Code};
        delete $row->{Price};
        delete $row->{ctime};
        delete $row->{mtime};
        my $total = $row->{LocalTotal} + $row->{ForeignTotal};
        for (@ownership_fields) {
            $row->{$_} = sprintf(
                ($args{graph} ? "%.f":"%5.2f%%"), $row->{$_}/$total*100);
        }
        for my $f (@ownership_fields) { delete $row->{$f} unless (grep {$_ eq $f} @$fields) }
        push @rows, $row;
    }

    if ($args{graph}) {
        require Chart::Gnuplot;
        require Color::RGB::Util;
        require ColorTheme::Distinct::WhiteBG;
        require File::Temp;

        my ($tempfh, $tempfilename) = File::Temp::tempfile();
        $tempfilename .= ".png";

        my $theme = ColorTheme::Distinct::WhiteBG->new;
        my @colors = map { '#'.$theme->get_item_color($_) } ($theme->list_items);

        my $chart = Chart::Gnuplot->new(
            output   => $tempfilename,
            title    => "$stock ownership from ".$args{date_start}->ymd." to ".$args{date_end}->ymd,
            xlabel   => 'date',
            ylabel   => "\%",
            timeaxis => 'x',
            xtics    => {labelfmt=>'%Y-%m-%d', rotate=>"30 right"},
            #yrange   => [0, 100],
        );
        my $i = -1;
        my @datasets;
        for my $field (@$fields) {
            $i++;
            push @datasets, Chart::Gnuplot::DataSet->new(
                xdata   => [map { $_->{date} } @rows],
                ydata   => [map { $_->{$field} } @rows],
                timefmt => '%Y-%m-%d',
                title   => $field,
                color   => $colors[$i],
                style   => 'lines',
            );
        }
        $chart->plot2d(@datasets);

        require Browser::Open;
        Browser::Open::open_browser("file:$tempfilename");

        return [200];
    }

    [200, "OK", \@rows, {'table.fields'=>['date']}];
}

$SPEC{daily} = {
    v => 1.1,
    summary => 'Show data from daily stock/trading summary',
    args => {
        %arg0_stocks,
        %argsopt_filter_date,
        %argopt_fields_daily,
        total => {
            schema => 'bool*',
        },
        %argopt_graph,
    },
};
sub daily {
    my %args = @_;
    my $stocks = $args{stocks};
    my $fields = $args{fields};

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @wheres;
    my @binds;
    push @wheres, "StockCode IN (".join(",", map {$dbh->quote($_)} @$stocks).")";
    if ($args{date_start}) {
        push @wheres, "date >= '".$args{date_start}->ymd."'";
    }
    if ($args{date_end}) {
        push @wheres, "date <= '".$args{date_end}->ymd."'";
    }

    my $sth = $dbh->prepare("SELECT * FROM daily_trading_summary WHERE ".join(" AND ", @wheres)." ORDER BY date,StockCode");
    $sth->execute(@binds);
    my %stock_rows;   # key=stock code, value[row, ...]
    my %stock_totals; # key=stock code, value={ field=>TOTAL, ... }

    my ($mindate, $maxdate);
    while (my $row = $sth->fetchrow_hashref) {
        my $code = $row->{StockCode};
        $mindate //= $row->{Date};
        $maxdate   = $row->{Date};

        $stock_rows{$code} //= [];

        # calculated fields
        $row->{ForeignNetBuy}      = $row->{ForeignBuy} - $row->{ForeignSell};
        $row->{AccumForeignBuy}    = (@{ $stock_rows{$code} } ? $stock_rows{$code}[-1]{AccumForeignBuy}    : 0) + $row->{ForeignBuy}     if grep {$_ eq 'AccumForeignBuy'} @$fields;
        $row->{AccumForeignSell}   = (@{ $stock_rows{$code} } ? $stock_rows{$code}[-1]{AccumForeignSell}   : 0) + $row->{ForeignSell}    if grep {$_ eq 'AccumForeignSell'} @$fields;
        $row->{AccumForeignNetBuy} = (@{ $stock_rows{$code} } ? $stock_rows{$code}[-1]{AccumForeignNetBuy} : 0) + $row->{ForeignNetBuy}  if grep {$_ eq 'AccumForeignNetBuy'} @$fields;

        # calculate total
        if ($args{total}) {
            for my $f (@daily_fields) {
                my $spec = $daily_fields{$f};
                next unless $spec->{type} =~ /^(volume|money|freq)$/;
                $stock_totals{$code}{$f} += $row->{$f}  if defined $row->{$f};
            }
        }

        delete $row->{StockCode};
        delete $row->{persen};
        delete $row->{percentage};
        delete $row->{ctime};
        delete $row->{mtime};
        for my $f (@daily_fields) { delete $row->{$f} unless (grep {$_ eq $f} @$fields) }
        push @{ $stock_rows{$code} }, $row;
    }

    if ($args{graph}) {
        require Chart::Gnuplot;
        require Color::RGB::Util;
        require ColorTheme::Distinct::WhiteBG;
        require File::Temp;

        my ($tempfh, $tempfilename) = File::Temp::tempfile();
        $tempfilename .= ".png";

        my $theme = ColorTheme::Distinct::WhiteBG->new;
        my @colors = map { '#'.$theme->get_item_color($_) } ($theme->list_items);

        my $chart = Chart::Gnuplot->new(
            output   => $tempfilename,
            title    => join(",", @$fields)." of ".join(",",@$stocks)." from $mindate to $maxdate",
            xlabel   => 'date',
            ylabel   => "\%",
            timeaxis => 'x',
            xtics    => {labelfmt=>'%Y-%m-%d', rotate=>"30 right"},
            #yrange   => [0, 100],
        );
        my $i = -1;
        my @datasets;
      STOCK:
        for my $stock (@$stocks) {
          FIELD:
            for my $field (@$fields) {
                $i++;
                push @datasets, Chart::Gnuplot::DataSet->new(
                    xdata   => [map { $_->{Date} }   @{ $stock_rows{$stock} }],
                    ydata   => [map { $_->{$field} } @{ $stock_rows{$stock} }],
                    timefmt => '%Y-%m-%d',
                    title   => "$stock.$field",
                    color   => $colors[$i],
                    style   => 'lines',
                );
            }
        }
        $chart->plot2d(@datasets);

        require Browser::Open;
        Browser::Open::open_browser("file:$tempfilename");

        return [200];
    }

    for my $stock (@$stocks) {
        if ($args{total} && @{ $stock_rows{$stock}[$_] }) {
            for my $f (keys %{ $stock_totals{$stock} }) {
                delete $stock_totals{$stock}{$f} unless (grep {$_ eq $f} @$fields);
            }
            $stock_totals{$stock}{Date} = 'TOTAL';
            push @{ $stock_rows{$stock} }, $stock_totals{$stock};
        }
    }

    my $rows;
    my (@ff, @ffa, @fffmt);

    if (@$stocks > 1) {
        $rows = [];
        for my $i (0 .. $#{ $stock_rows{$stocks->[0]} }) {
            my $row = {
                Date => $stock_rows{$stocks->[0]}[$i]{Date},
            };
            for my $stock (@$stocks) {
                my $r = $stock_rows{$stock}[$i];
                for my $field (keys %$r) {
                    next if $field =~ /^(Date)$/;
                    $row->{"$stock.$field"} = $r->{$field};
                }
            }
            push @$rows, $row;
        }
    } else {
        @ff  = ('Date', @$fields);
        $rows = $stock_rows{$stocks->[0]};
        for (@ff) {
            push @ffa  , (($daily_fields{$_}{type}//'') =~ /^(price|volume|accum_volume|money|freq|num)$/ ? 'right'  : undef);
            push @fffmt, (($daily_fields{$_}{type}//'') =~ /^(price|volume|accum_volume|money|freq|num)$/ ? 'number' : undef);
        }
    }


    [200, "OK", $rows, {
        'table.fields'       =>\@ff,
        'table.field_aligns' =>\@ffa,
        'table.field_formats'=>\@fffmt,
    }];
}

1;
# ABSTRACT: Import data for stocks on the IDX (Indonesian Stock Exchange) and perform queries on them

__END__

=pod

=encoding UTF-8

=head1 NAME

App::idxdb - Import data for stocks on the IDX (Indonesian Stock Exchange) and perform queries on them

=head1 VERSION

This document describes version 0.004 of App::idxdb (from Perl distribution App-idxdb), released on 2021-01-22.

=head1 SYNOPSIS

See the included CLI script L<idxdb>.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 daily

Usage:

 daily(%args) -> [status, msg, payload, meta]

Show data from daily stockE<sol>trading summary.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date_end> => I<date> (default: 1611273600)

=item * B<date_start> => I<date> (default: 1608681600)

=item * B<fields> => I<array[str]> (default: ["Volume","Value","ForeignNetBuy"])

=item * B<graph> => I<bool>

Show graph instead of table.

=item * B<stocks>* => I<array[idx::listed_stock_code]>

=item * B<total> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 ownership

Usage:

 ownership(%args) -> [status, msg, payload, meta]

Show ownership of some stock through time.

Examples:

=over

=item * Show legends instead (e.g. ForeignIB = foreign bank, etc):

 ownership(legend => 1); # -> [400, "Missing required argument: stock", undef, {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date_end> => I<date> (default: 1611273600)

=item * B<date_start> => I<date> (default: 1608681600)

=item * B<fields> => I<array[str]> (default: ["LocalTotal","ForeignTotal"])

=item * B<graph> => I<bool>

Show graph instead of table.

=item * B<legend> => I<bool>

Show legend of ownership instead (e.g. ForeignIB = foreign bank, etc).

=item * B<stock>* => I<idx::listed_stock_code>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 update

Usage:

 update(%args) -> [status, msg, payload, meta]

Update data.

Currently this routine imports from text files in the C<gudangdata> repository on
the local filesystem. Functionality to import from server directly using
L<Finance::SE::IDX> and L<Finance::ID::KSEI> will be added in the future.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbpath> => I<str>

Path for SQLite database.

If not specified, will default to C<~/idxdb.db>.

=item * B<gudangdata_path>* => I<dirname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-idxdb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-idxdb>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-idxdb/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
