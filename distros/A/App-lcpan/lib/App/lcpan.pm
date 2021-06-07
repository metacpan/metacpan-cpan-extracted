package App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-05'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.068'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Clone::Util qw(clone modclone);
use List::Util qw(first);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       update
                       modules
                       dists
                       releases
                       authors
                       deps
                       rdeps
               );

# XXX also add author instead of just release name, since PAUSE allows 2
# different authors to have the same filename.

my %builtin_file_skip_list = (
    'Perl-ToPerl6-0.031.tar.gz' => 'too big, causes Archive::Tar to go out of mem', # 2016-02-10
);

my %builtin_file_skip_list_sub = (
    'CharsetDetector-2.0.2.tar.gz'        => 'segfaults Compiler::Lexer 0.22', # 2016-02-17
    'Crypt-GeneratePassword-0.05.tar.gz'  => 'segfaults Compiler::Lexer 0.22', # 2016-02-17
    'Encode-Detect-CJK-2.0.2.tar.gz'      => 'segfaults Compiler::Lexer 0.22', # 2016-02-17
    'Shipment-0.13.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2016-02-17
    'Shipment-2.00.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2016-02-17
    'Shipment-2.01.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2016-06-23
    'Shipment-2.02.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2016-06-29
    'Shipment-2.03.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2016-09-06
    'Shipment-3.01.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2018-02-08
    'Shipment-3.02.tar.gz'                => 'segfaults Compiler::Lexer 0.22', # 2019-07-23
    'App-IndonesianBankingUtils-0.07.tar.gz' => 'segfaults at phase 3/3',      # 2016-08-18
    'Bencher-Scenarios-HashSlicing-0.003.tar.gz' => 'eats memory',             # 2020-03-04
);

our %SPEC;

# BEGIN argument specifications.

# %argspecFOO is the new naming scheme and we will eventually switch to this.
# %FOO_args is the old naming scheme.

our %common_args = (
    cpan => {
        schema => 'dirname*',
        summary => 'Location of your local CPAN mirror, e.g. /path/to/cpan',
        description => <<'_',

Defaults to C<~/cpan>.

_
        tags => ['common'],
    },
    index_name => {
        summary => 'Filename of index',
        schema  => 'filename*',
        default => 'index.db',
        tags => ['common'],
        description => <<'_',

If `index_name` is a filename without any path, e.g. `index.db` then index will
be located in the top-level of `cpan`. If `index_name` contains a path, e.g.
`./index.db` or `/home/ujang/lcpan.db` then the index will be located solely
using the `index_name`.

_
        completion => sub {
            my %args = @_;
            my $word    = $args{word} // '';
            my $cmdline = $args{cmdline};
            my $r       = $args{r};

            return undef unless $cmdline;

            # force reading config file
            $r->{read_config} = 1;
            my $res = $cmdline->parse_argv($r);

            my $args = $res->[2];
            _set_args_default($args);

            require Complete::File;
            require Complete::Util;
            Complete::Util::hashify_answer(
                Complete::File::complete_file(
                    word => $word,
                    starting_path => $args->{cpan},
                    filter => sub {
                        # dir (to dig down deeper) or index.db*
                        (-d $_[0]) || $_[0] =~ /index\.db/;
                    },
                ),
                {path_sep=>'/'},
            );
        },
    },
    use_bootstrap => {
        summary => 'Whether to use bootstrap database from App-lcpan-Bootstrap',
        schema => 'bool*',
        default => 1,
        description => <<'_',

If you are indexing your private CPAN-like repository, you want to turn this
off.

_
        tags => ['common'],
    },
);

our %all_args = (
    all => {
        schema => 'bool',
        cmdline_aliases => {a=>{}},
    },
);

our %detail_args = (
    detail => {
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

our %query_args = (
    query => {
        summary => 'Search query',
        schema => 'str*',
        cmdline_aliases => {q=>{}},
        pos => 0,
        tags => ['category:filtering'],
    },
    %detail_args,
);

our %query_multi_args = (
    query => {
        summary => 'Search query',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {q=>{}},
        pos => 0,
        slurpy => 1,
        tags => ['category:filtering'],
    },
    detail => {
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
    or => {
        summary => 'When there are more than one query, perform OR instead of AND logic',
        schema  => ['bool', is=>1],
        tags => ['category:filtering'],
    },
);

our %fauthor_args = (
    author => {
        summary => 'Filter by author',
        schema => 'str*',
        cmdline_aliases => {a=>{}},
        completion => \&_complete_cpanid,
        tags => ['category:filtering'],
    },
);

our %fdist_args = (
    dist => {
        summary => 'Filter by distribution',
        schema => 'perl::distname*',
        cmdline_aliases => {d=>{}},
        completion => \&_complete_dist,
        tags => ['category:filtering'],
    },
);

our %flatest_args = (
    latest => {
        schema => ['bool*'],
        tags => ['category:filtering'],
    },
);

our %file_id_args = (
    file_id => {
        summary => 'Filter by file ID',
        schema => 'posint*',
        #completion => \&_complete_file_id,
        tags => ['category:filtering'],
    },
);

our %finclude_core_args = (
    include_core => {
        summary => 'Include core modules',
        'summary.alt.bool.not' => 'Exclude core modules',
        schema  => 'bool',
        default => 1,
        tags => ['category:filtering'],
    },
);

our %finclude_noncore_args = (
    include_noncore => {
        summary => 'Include non-core modules',
        'summary.alt.bool.not' => 'Exclude non-core modules',
        schema  => 'bool',
        default => 1,
        tags => ['category:filtering'],
    },
);

our %finclude_indexed_args = (
    include_indexed => {
        summary => 'Include modules that are indexed (listed in 02packages.details.txt.gz)',
        'summary.alt.bool.not' => 'Exclude modules that are indexed (listed in 02packages.details.txt.gz)',
        schema  => 'bool',
        default => 1,
        tags => ['category:filtering'],
    },
);

our %finclude_unindexed_args = (
    include_unindexed => {
        summary => 'Include modules that are not indexed (not listed in 02packages.details.txt.gz)',
        'summary.alt.bool.not' => 'Exclude modules that are not indexed (not listed in 02packages.details.txt.gz)',
        schema  => 'bool',
        default => 1,
        cmdline_aliases => {
            broken => {is_flag=>1, summary => 'Alias for --exclude-indexed --include-unindexed', code => sub { $_[0]{include_unindexed}=1; $_[0]{include_indexed}=0 }},
        },
        tags => ['category:filtering'],
    },
);

our %fctime_args = (
    added_since => {
        summary => 'Include only records that are added since a certain date',
        schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural']],
        tags => ['category:filtering'],
    },
    added_since_last_index_update => {
        summary => 'Include only records that are added since the last index update',
        schema => 'true*',
        tags => ['category:filtering'],
    },
    added_since_last_n_index_updates => {
        summary => 'Include only records that are added since the last N index updates',
        schema => 'posint*',
        tags => ['category:filtering'],
    },
);

our %fmtime_args = (
    updated_since => {
        summary => 'Include only records that are updated since certain date',
        schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural']],
        tags => ['category:filtering'],
    },
    updated_since_last_index_update => {
        summary => 'Include only records that are updated since the last index update',
        schema => 'true*',
        tags => ['category:filtering'],
    },
    updated_since_last_n_index_updates => {
        summary => 'Include only records that are updated since the last N index updates',
        schema => 'posint*',
        tags => ['category:filtering'],
    },
);

our %fctime_or_mtime_args = (
    added_or_updated_since => {
        summary => 'Include only records that are added/updated since a certain date',
        schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural']],
        cmdline_aliases => {since=>{}},
        tags => ['category:filtering'],
    },
    added_or_updated_since_last_index_update => {
        summary => 'Include only records that are added/updated since the last index update',
        schema => 'true*',
        cmdline_aliases => {since_last_index_update=>{}},
        tags => ['category:filtering'],
    },
    added_or_updated_since_last_n_index_updates => {
        summary => 'Include only records that are added/updated since the last N index updates',
        schema => 'posint*',
        cmdline_aliases => {since_last_n_index_updates=>{}},
        tags => ['category:filtering'],
    },
);

our %perl_version_args = (
    perl_version => {
        summary => 'Set base Perl version for determining core modules',
        schema  => 'str*',
        default => "$^V",
        cmdline_aliases => {V=>{}},
    },
);

our %random_args = (
    random => {
        summary => 'Random sort',
        schema => 'true*',
        tags => ['category:ordering'],
    },
);

our %sort_args_for_authors = (
    sort => {
        summary => 'Sort the result',
        schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/id name email rec_mtime/]]],
        default => ['id'],
        tags => ['category:ordering'],
    },
    %random_args,
);

our %sort_args_for_mods = (
    sort => {
        summary => 'Sort the result',
        schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/module author rdeps rel_mtime/]]],
        default => ['module'],
        tags => ['category:ordering'],
    },
    %random_args,
);

our %sort_args_for_dists = (
    sort => {
        summary => 'Sort the result',
        schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/dist author release rel_size rel_mtime abstract/]]],
        default => ['dist'],
        tags => ['category:ordering'],
    },
    %random_args,
);

# XXX should it be put in App/lcpan/Cmd/subs.pm?
our %sort_args_for_subs = (
    sort => {
        summary => 'Sort the result',
        schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/sub package linum author/]]],
        default => ['sub'],
        tags => ['category:ordering'],
    },
    %random_args,
);

our %paging_args = (
    result_limit => {
        summary => 'Only return a certain number of records',
        schema => 'uint*',
        tags => ['category:paging'],
    },
    result_start => {
        summary => 'Only return starting from the n\'th record',
        schema => 'posint*',
        default => 1,
        tags => ['category:paging'],
    },
);

our %full_path_args = (
    full_path => {
        schema => ['bool*' => is=>1],
        tags => ['expose-fs-path'],
    },
);

our %no_path_args = (
    no_path => {
        schema => ['bool*' => is=>1],
    },
);

our %mod_args = (
    module => {
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
        completion => \&_complete_mod,
    },
);

our %mods_args = (
    modules => {
        schema => ['array*', of=>'perl::modname*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_mod,
    },
);

our %argspec0opt_modules = (
    modules => {
        schema => ['array*', of=>'perl::modname*', min_len=>1],
        'x.name.is_plural' => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_mod,
    },
);

our %argspecopt_mods = (
    modules => {
        schema => ['array*', of=>'perl::modname*', min_len=>1],
        'x.name.is_plural' => 1,
        element_completion => \&_complete_mod,
    },
);

our %pods_args = (
    pods => {
        schema => ['array*', of=>'perl::modname*', min_len=>1],
        'x.name.is_plural' => 1,
        'x.name.singular' => 'pod',
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        #element_completion => \&_complete_pod, # will be too slow with the current schema
    },
);

our %mod_or_dist_args = (
    module_or_dist => {
        summary => 'Module or dist name',
        schema => ['str*', # XXX perl::mod_or_distname
               ],
        req => 1,
        pos => 0,
        completion => \&App::lcpan::_complete_mod_or_dist,
    },
);

our %mods_or_dists_args = (
    modules_or_dists => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'module_or_dist',
        summary => 'Module or dist names',
        schema => ['array*', of => ['str*']], # XXX perl::mod_or_distname
        req => 1,
        pos => 0,
        slurpy => 1,
        element_completion => \&App::lcpan::_complete_mod_or_dist,
    },
);

our %script_args = (
    script => {
        schema => 'filename::unix*',
        req => 1,
        pos => 0,
        completion => \&_complete_script,
    },
);

our %scripts_args = (
    scripts => {
        schema => ['array*', of=>'filename::unix*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_script,
    },
);

our %mod_or_dist_or_script_args = (
    module_or_dist_or_script => {
        # XXX coerce rule: from string: convert / to ::
        summary => 'Module or dist or script name',
        schema => ['str*',
               ],
        req => 1,
        pos => 0,
        completion => \&App::lcpan::_complete_mod_or_dist_or_script,
    },
);

our %author_args = (
    author => {
        schema => 'str*',
        req => 1,
        pos => 0,
        completion => \&_complete_cpanid,
    },
);

our %authors_args = (
    authors => {
        schema => ['array*', of=>'str*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_cpanid,
    },
);

our %dist_args = (
    dist => {
        schema => 'perl::distname*',
        req => 1,
        pos => 0,
        completion => \&_complete_dist,
    },
);

our %dists_args = (
    dists => {
        summary => 'Distribution names (e.g. Foo-Bar)',
        schema => ['array*', of=>'perl::distname*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_dist,
    },
);

our %argspecopt_dists = (
    dists => {
        summary => 'Distribution names (e.g. Foo-Bar)',
        schema => ['array*', of=>'perl::distname*', min_len=>1],
        'x.name.is_plural' => 1,
        element_completion => \&_complete_dist,
    },
);

our %dists_with_optional_vers_args = (
    dists => {
        summary => 'Distribution names (with optional version suffix, e.g. Foo-Bar@1.23)',
        schema => ['array*', of=>'perl::distname_with_optional_ver*', min_len=>1],
        'x.name.is_plural' => 1,
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_dist,
    },
);

our %argspec0opt_dists_with_optional_vers = (
    dists => {
        summary => 'Distribution names (with optional version suffix, e.g. Foo-Bar@1.23)',
        schema => ['array*', of=>'perl::distname_with_optional_ver*', min_len=>1],
        'x.name.is_plural' => 1,
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
        element_completion => \&_complete_dist,
    },
);

our %rel_args = (
    release => {
        schema => 'str*', # XXX perl::relname
        req => 1,
        pos => 0,
        completion => \&_complete_rel,
    },
);

our %dist_or_rel_args = (
    dist_or_release => {
        schema => 'str*', # XXX [any, of=>[perl::relname, perl::distname]]
        req => 1,
        pos => 0,
        completion => \&_complete_dist, # XXX dist/release
    },
);

our %sort_args_for_rels = (
    sort => {
        schema => ['array*', of=>['str*', in=>[qw/author -author size -size name -name mtime -mtime/]]],
        default => ['name'],
        tags => ['category:sorting'],
    },
    %random_args,
);

our %overwrite_args = (
    overwrite => {
        summary => 'Whether to overwrite existing file',
        schema => ['bool*', is=>1],
        cmdline_aliases => {o=>{}},
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Manage local CPAN mirror',
};

sub _set_args_default {
    my $args = shift;
    if (!$args->{cpan}) {
        require File::HomeDir;
        $args->{cpan} = File::HomeDir->my_home . '/cpan';
    }
    $args->{index_name} //= 'index.db';
    if (!defined($args->{num_backups})) {
        $args->{num_backups} = 7;
    }
}

# set {added_,updated_,added_or_udpated_}since from
# {added_,updated_,added_or_updated_}since_last_{index_update,n_index_updates},
# set, since SQL query will usually use the former
sub _set_since {
    my ($args, $dbh) = @_;

    my $num_sinces = 0;
    if (defined $args->{added_since}) { $num_sinces++ }
    if (defined $args->{updated_since}) { $num_sinces++ }
    if (defined $args->{added_or_updated_since}) { $num_sinces++ }
    if (defined $args->{added_since_last_index_update} || defined $args->{updated_since_last_index_update} || defined $args->{added_or_updated_since_last_index_update}) {
        my ($time) = $dbh->selectrow_array("SELECT date FROM log WHERE category='update_index' AND summary LIKE 'Begin%' ORDER BY date DESC");
        die "Index has not been updated at all, cannot use {added_,updated_,added_or_updated_}since_last_index_update option" unless $time;
        if (delete $args->{added_since_last_index_update})            { $args->{added_since}            //= $time; log_trace "Setting added_since=%s", $time; $num_sinces++ }
        if (delete $args->{updated_since_last_index_update})          { $args->{updated_since}          //= $time; log_trace "Setting updated_since=%s", $time; $num_sinces++ }
        if (delete $args->{added_or_updated_since_last_index_update}) { $args->{added_or_updated_since} //= $time; log_trace "Setting added_or_updated_since=%s", $time; $num_sinces++ }
    }
    if (defined $args->{added_since_last_n_index_updates} || defined $args->{updated_since_last_n_index_updates} || defined $args->{added_or_updated_since_last_n_index_updates}) {
        my $n = int($args->{added_since_last_n_index_updates} // $args->{updated_since_last_n_index_updates} // $args->{added_or_updated_since_last_n_index_updates});
        $n = 1 if $n < 1;
        my $sth = $dbh->prepare("SELECT date FROM log WHERE category='update_index' AND summary LIKE 'Begin%' ORDER BY date DESC");
        $sth->execute;
        my $i = 0;
        my $time;
        1 while ++$i <= $n && (($time) = $sth->fetchrow_array);
        die "Index has not been updated that many times, please set a lower number for {,added_,updated_}since_last_n_index_updates option" if $i < $n;
        if (delete $args->{added_since_last_n_index_updates})            { $args->{added_since}            //= $time; log_trace "Setting added_since=%s", $time; $num_sinces++ }
        if (delete $args->{updated_since_last_n_index_updates})          { $args->{updated_since}          //= $time; log_trace "Setting updated_since=%s", $time; $num_sinces++ }
        if (delete $args->{added_or_updated_since_last_n_index_updates}) { $args->{added_or_updated_since} //= $time; log_trace "Setting added_or_updated_since=%s", $time; $num_sinces++ }
    }

    die "Multiple {added_,updated_,added_or_updated_}since options set, please set only one to avoid confusion" if $num_sinces > 1;
}

sub _add_since_where_clause {
    my ($args, $where, $table) = @_;
    if (defined $args->{added_since}  )          { push @$where, "$table.rec_ctime >= ". (0+$args->{added_since}) }
    if (defined $args->{updated_since})          { push @$where, "($table.rec_mtime >= ". (0+$args->{updated_since}). " AND $table.rec_ctime < ".(0+$args->{updated_since}). ")" }
    if (defined $args->{added_or_updated_since}) { push @$where, "($table.rec_ctime >= ". (0+$args->{added_or_updated_since}). " OR $table.rec_mtime >= ". (0+$args->{added_or_updated_since}). ")" }
}

sub _fmt_time {
    require POSIX;

    my $epoch = shift;
    return '' unless defined($epoch);
    POSIX::strftime("%Y-%m-%dT%H:%M:%SZ", gmtime($epoch));
}

sub _numify_ver {
    my $v;
    eval { $v = version->parse($_[0]) };
    $v ? $v->numify : undef;
}

sub _dists_with_optional_vers2file_ids {
    my ($dbh, $dists_with_optional_vers) = @_;

    return [] unless $dists_with_optional_vers;
    my $file_ids = [];
    for my $dist_with_optional_ver (@$dists_with_optional_vers) {
        my $dist = $dist_with_optional_ver;
        my $file_id;
        if ($dist =~ s/@(.+)$//) {
            my $ver = $1;
            ($file_id) = $dbh->selectrow_array("SELECT id FROM file WHERE dist_name=? AND dist_version=?", {}, $dist, $ver);
            do { warn "lcpan: No such dist '$dist' version '$ver'\n"; next } unless $file_id;
        } else {
            ($file_id) = $dbh->selectrow_array("SELECT id FROM file WHERE dist_name=? AND is_latest_dist=1", {}, $dist);
            do { warn "lcpan: No such dist '$dist'\n"; next } unless $file_id;
        }
        push @$file_ids, $file_id unless grep { $file_id == $_ } @$file_ids;
    }

    $file_ids;
}

sub _modules2file_ids {
    my ($dbh, $modules) = @_;

    return [] unless $modules && @$modules;
    my $file_ids = [];
    for my $module (@$modules) {
        my ($file_id) = $dbh->selectrow_array("SELECT file_id FROM module WHERE name=?", {}, $module);
        do { warn "lcpan: No such module '$module'\n"; next } unless $file_id;
        push @$file_ids, $file_id unless grep { $file_id == $_ } @$file_ids;
    }

    $file_ids;
}

sub _dists2theirmods {
    my ($dbh, $dists) = @_;

    return [] unless $dists;
    my $mods = [];
    for my $dist (@$dists) {
        my $sth = $dbh->prepare("SELECT name FROM module WHERE file_id IN (SELECT id FROM file WHERE dist_name=? AND is_latest_dist=1)");
        $sth->execute($dist);
        my @dist_mods;
        while (my ($dist_mod) = $sth->fetchrow_array) {
            push @dist_mods, $dist_mod;
        }
        do { warn "lcpan: No such distribution or distribution does not contain any module: '$dist'\n"; next } unless @dist_mods;
        for my $dist_mod (@dist_mods) { push @$mods, $dist_mod unless grep { $dist_mod eq $_ } @$mods }
    }

    $mods;
}

sub _fullpath {
    my ($filename, $cpan, $cpanid) = @_;
    $cpanid = uc($cpanid); # just to be safe
    "$cpan/authors/id/".substr($cpanid, 0, 1)."/".
        substr($cpanid, 0, 2)."/$cpanid/$filename";
}

sub _relpath {
    my ($filename, $cpanid) = @_;
    $cpanid = uc($cpanid); # just to be safe
    substr($cpanid, 0, 1)."/".
        substr($cpanid, 0, 2)."/$cpanid/$filename";
}

sub _dblog {
    no strict 'refs';

    my ($dbh, $level, $category, $summary) = @_;
    $dbh->do("INSERT INTO log (date,lcpan_version,pid, level,category,summary) VALUES (?,?,?, ?,?,?)", {},
             time(), ${__PACKAGE__ . "::VERSION"}, $$,
             $level, $category, $summary);
}

sub _fill_namespace {
    require DBIx::Util::Schema;
    my $dbh = shift;

    my $has_rec_ctime = DBIx::Util::Schema::has_column($dbh, "namespace", "rec_ctime");
    my $has_rec_mtime = DBIx::Util::Schema::has_column($dbh, "namespace", "rec_mtime");
    my $sth_sel_mod = $dbh->prepare("SELECT name FROM module");
    my $sth_ins_ns  = $has_rec_ctime ?
        $dbh->prepare("INSERT INTO namespace (name, rec_ctime, rec_mtime, num_sep, has_child, num_modules) VALUES (?,?,?,?,?,1)") :
        $dbh->prepare("INSERT INTO namespace (name, num_sep, has_child, num_modules) VALUES (?,?,?,1)");
    my $sth_upd_ns_inc_num_mod = $has_rec_mtime ?
        $dbh->prepare("UPDATE namespace SET num_modules=num_modules+1, has_child=1, rec_mtime=? WHERE name=?") :
        $dbh->prepare("UPDATE namespace SET num_modules=num_modules+1, has_child=1 WHERE name=?");
    $sth_sel_mod->execute;
    my %cache;
    my $now = time();
    while (my ($mod) = $sth_sel_mod->fetchrow_array) {
        my $has_child = 0;
        while (1) {
            if ($cache{$mod}++) {
                $sth_upd_ns_inc_num_mod->execute(($has_rec_mtime ? ($now) : ()), $mod);
            } else {
                my $num_sep = 0;
                while ($mod =~ /::/g) { $num_sep++ }
                $sth_ins_ns->execute($mod, ($has_rec_ctime ? ($now, $now) : ()), $num_sep, $has_child);
            }
            $mod =~ s/::\w+\z// or last;
            $has_child = 1;
        }
    }
}

sub _set_namespace {
    my ($dbh, $mod) = @_;
    my $sth_sel_ns  = $dbh->prepare("SELECT name FROM namespace WHERE name=?");
    my $sth_ins_ns  = $dbh->prepare("INSERT INTO namespace (name, rec_ctime, rec_mtime, num_sep, has_child, num_modules) VALUES (?,?,?,?,?,1)");
    my $sth_upd_ns_inc_num_mod = $dbh->prepare("UPDATE namespace SET num_modules=num_modules+1, has_child=1, rec_mtime=? WHERE name=?");

    my $has_child = 0;
    my $now = time();
    while (1) {
        $sth_sel_ns->execute($mod);
        my $row = $sth_sel_ns->fetchrow_arrayref;
        if ($row) {
            $sth_upd_ns_inc_num_mod->execute($now, $mod);
        } else {
            my $num_sep = 0;
            while ($mod =~ /::/g) { $num_sep++ }
            $sth_ins_ns->execute($mod, $now, $now, $num_sep, $has_child);
        }
        $mod =~ s/::\w+\z// or last;
        $has_child = 1;
    }
}

our $db_schema_spec = {
    latest_v => 15,

    install => [
        'CREATE TABLE author (
             cpanid VARCHAR(20) NOT NULL PRIMARY KEY,
             fullname VARCHAR(255) NOT NULL,
             email TEXT,
             rec_ctime INT,
             rec_mtime INT
         )',
        'CREATE INDEX ix_author__rec_ctime ON author(rec_ctime)',
        'CREATE INDEX ix_author__rec_mtime ON author(rec_mtime)',

        'CREATE TABLE file (
             id INTEGER NOT NULL PRIMARY KEY,
             name TEXT NOT NULL,
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid),

             mtime INT,
             size INT,

             -- file status: ok (archive type is known, content can be listed,
             -- and at least some files can be extracted), nofile (file does not
             -- exist in mirror), unsupported (archive type is not supported,
             -- e.g. rar, pm.gz), err (cannot be opened/extracted for some
             -- reason)

             file_status TEXT,
             file_error TEXT,

             -- META.* processing status: ok (meta has been extracted and
             -- parsed), err (META.json/META.yml has some error), nometa (no
             -- META.json/META.yml found).

             meta_status TEXT,
             meta_error TEXT,

             dist_name TEXT,
             dist_abstract TEXT,
             dist_version VARCHAR(20),
             dist_version_numified VARCHAR(20),
             is_latest_dist BOOLEAN,

             -- POD processing status: ok (POD has been extracted and
             -- parsed/indexed).

             pod_status TEXT,

             -- sub processing status: ok (sub names have been parsed/indexed)

             sub_status TEXT,

             has_metajson INTEGER,
             has_metayml INTEGER,
             has_makefilepl INTEGER,
             has_buildpl INTEGER,

             rec_ctime INT,
             rec_mtime INT
        )',
        'CREATE UNIQUE INDEX ix_file__id ON file(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_file__cpanid__name ON file(cpanid,name)',
        'CREATE INDEX ix_file__rec_ctime ON file(rec_ctime)',
        'CREATE INDEX ix_file__rec_mtime ON file(rec_mtime)',
        'CREATE INDEX ix_file__dist_name ON file(dist_name)',

        # files inside the release archive file
        'CREATE TABLE content (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id),
             path TEXT NOT NULL,
             package TEXT, -- only the first package declaration will be recorded
             mtime INT,
             size INT, -- uncompressed size
             rec_ctime INT,
             rec_mtime INT
        )',
        'CREATE UNIQUE INDEX ix_content__id ON content(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_content__file_id__path ON content(file_id, path)',
        'CREATE INDEX ix_content__package ON content(package)',
        'CREATE INDEX ix_content__rec_ctime ON content(rec_ctime)',
        'CREATE INDEX ix_content__rec_mtime ON content(rec_mtime)',

        'CREATE TABLE module (
             id INTEGER NOT NULL PRIMARY KEY,
             name VARCHAR(255) NOT NULL,
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid), -- [cache]
             file_id INTEGER NOT NULL,
             version VARCHAR(20),
             version_numified DECIMAL,
             content_id INTEGER REFERENCES content(id),
             abstract TEXT,
             rec_ctime INT,
             rec_mtime INT
         )',
        'CREATE UNIQUE INDEX ix_module__id ON module(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_module__name ON module(name)',
        'CREATE INDEX ix_module__file_id ON module(file_id)',
        'CREATE INDEX ix_module__cpanid ON module(cpanid)',
        'CREATE INDEX ix_module__rec_ctime ON module(rec_ctime)',
        'CREATE INDEX ix_module__rec_mtime ON module(rec_mtime)',

        'CREATE TABLE script (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id), -- [cache]
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid), -- [cache]
             name TEXT NOT NULL,
             content_id INT REFERENCES content(id),
             abstract TEXT,
             rec_ctime INT,
             rec_mtime INT
        )',
        'CREATE UNIQUE INDEX ix_script__id ON script(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_script__file_id__name ON script(file_id, name)',
        'CREATE INDEX ix_script__name ON script(name)',
        'CREATE INDEX ix_script__rec_ctime ON script(rec_ctime)',
        'CREATE INDEX ix_script__rec_mtime ON script(rec_mtime)',

        'CREATE TABLE mention (
             id INTEGER NOT NULL PRIMARY KEY,
             source_file_id INT NOT NULL REFERENCES file(id), -- [cache]
             source_content_id INT NOT NULL REFERENCES content(id),
             module_id INTEGER, -- if mention module and module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if mention module and module is unknown (unlisted in module table), only the name will be recorded here
             script_name TEXT,  -- if mention script
             rec_ctime INT,
             rec_mtime INT
        )',
        'CREATE UNIQUE INDEX ix_mention__id ON mention(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_mention__module_id__source_content_id   ON mention(module_id, source_content_id)',
        'CREATE UNIQUE INDEX ix_mention__module_name__source_content_id ON mention(module_name, source_content_id)',
        'CREATE UNIQUE INDEX ix_mention__script_name__source_content_id ON mention(script_name, source_content_id)',
        'CREATE INDEX ix_mention__rec_ctime ON mention(rec_ctime)',
        'CREATE INDEX ix_mention__rec_mtime ON mention(rec_mtime)',

        'CREATE TABLE namespace (
            name VARCHAR(255) NOT NULL,
            num_sep INT NOT NULL,
            has_child BOOL NOT NULL,
            num_modules INT NOT NULL,
            rec_ctime INT,
            rec_mtime INT
        )',
        'CREATE UNIQUE INDEX ix_namespace__name ON namespace(name)',
        'CREATE INDEX ix_namespace__rec_ctime ON namespace(rec_ctime)',
        'CREATE INDEX ix_namespace__rec_mtime ON namespace(rec_mtime)',

        'CREATE TABLE dep (
             file_id INTEGER,
             module_id INTEGER, -- if module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if module is unknown (unlisted in module table), only the name will be recorded here
             rel TEXT, -- relationship: requires, ...
             phase TEXT, -- runtime, ...
             version VARCHAR(20),
             version_numified DECIMAL,
             rec_ctime INT,
             rec_mtime INT,
             FOREIGN KEY (file_id) REFERENCES file(id),
             FOREIGN KEY (module_id) REFERENCES module(id)
         )',
        'CREATE INDEX ix_dep__module_name ON dep(module_name)',
        'CREATE INDEX ix_dep__file_id ON dep(file_id)',
        'CREATE INDEX ix_dep__module_id ON dep(module_id)',
        'CREATE INDEX ix_dep__rec_ctime ON dep(rec_ctime)',
        'CREATE INDEX ix_dep__rec_mtime ON dep(rec_mtime)',

        'CREATE TABLE sub (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id), --[cache]
             content_id INTEGER NOT NULL REFERENCES content(id),
             name TEXT NOT NULL,
             linum INTEGER NOT NULL,
             rec_ctime INT,
             rec_mtime INT
         )',
        'CREATE UNIQUE INDEX ix_sub__id ON sub(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_sub__name__content_id ON sub(name, content_id)',
        'CREATE INDEX ix_sub__rec_ctime ON sub(rec_ctime)',
        'CREATE INDEX ix_sub__rec_mtime ON sub(rec_mtime)',

        'CREATE TABLE log (
             id INTEGER NOT NULL PRIMARY KEY,
             date INTEGER NOT NULL,
             lcpan_version TEXT,
             pid INTEGER NOT NULL,
             level INTEGER NOT NULL, -- like in Log::ger: fatal=10, error=20, warn=30, info=40, debug=50, trace=60
             category TEXT NOT NULL,
             summary TEXT NOT NULL
         )',
        'CREATE UNIQUE INDEX ix_log__id ON log(id)',
        'CREATE INDEX ix_log__date ON log(date)',
        'CREATE INDEX ix_log__category ON log(category)',
    ], # install

    upgrade_to_v2 => [
        # actually we don't have any schema changes in v2, but we want to
        # reindex release files that haven't been successfully indexed
        # because aside from META.{json,yml}, we now can get information
        # from Makefile.PL or Build.PL.
        qq|DELETE FROM dep  WHERE dist_id IN (SELECT id FROM dist WHERE file_id IN (SELECT id FROM file WHERE status<>'ok'))|, # shouldn't exist though
        qq|DELETE FROM dist WHERE file_id IN (SELECT id FROM file WHERE status<>'ok')|,
        qq|DELETE FROM file WHERE status<>'ok'|,
    ],

    upgrade_to_v3 => [
        # empty data, we'll reindex because we'll need to set has_* and
        # discard all info
        'DELETE FROM dist',
        'DELETE FROM module',
        'DELETE FROM file',
        'ALTER TABLE file ADD COLUMN has_metajson   INTEGER',
        'ALTER TABLE file ADD COLUMN has_metayml    INTEGER',
        'ALTER TABLE file ADD COLUMN has_makefilepl INTEGER',
        'ALTER TABLE file ADD COLUMN has_buildpl    INTEGER',
        'ALTER TABLE dist   ADD COLUMN version_numified DECIMAL',
        'ALTER TABLE module ADD COLUMN version_numified DECIMAL',
        'ALTER TABLE dep    ADD COLUMN version_numified DECIMAL',
    ],

    upgrade_to_v4 => [
        # there is some changes to data structure: 1) add column 'cpanid' to
        # module & dist (for improving performance of some queries); 2) we
        # record deps per-file, not per-dist so we can delete old files'
        # data more easily. we also empty data to force reindexing.

        'DELETE FROM dist',
        'DELETE FROM module',
        'DELETE FROM file',

        'ALTER TABLE module ADD COLUMN cpanid VARCHAR(20) NOT NULL DEFAULT \'\' REFERENCES author(cpanid)',
        'CREATE INDEX ix_module__cpanid ON module(cpanid)',
        'ALTER TABLE dist ADD COLUMN cpanid VARCHAR(20) NOT NULL DEFAULT \'\' REFERENCES author(cpanid)',
        'CREATE INDEX ix_dist__cpanid ON dist(cpanid)',

        'DROP TABLE dep',
        'CREATE TABLE dep (
             file_id INTEGER,
             dist_id INTEGER, -- [cache]
             module_id INTEGER, -- if module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if module is unknown (unlisted in module table), only the name will be recorded here
             rel TEXT, -- relationship: requires, ...
             phase TEXT, -- runtime, ...
             version VARCHAR(20),
             version_numified DECIMAL,
             FOREIGN KEY (file_id) REFERENCES file(id),
             FOREIGN KEY (dist_id) REFERENCES dist(id),
             FOREIGN KEY (module_id) REFERENCES module(id)
         )',
        'CREATE INDEX ix_dep__module_name ON dep(module_name)',
    ],

    upgrade_to_v5 => [
        'ALTER TABLE dist ADD COLUMN is_latest BOOLEAN',
    ],

    upgrade_to_v6 => [
        'CREATE TABLE namespace (
            name VARCHAR(255) NOT NULL,
            num_sep INT NOT NULL,
            has_child BOOL NOT NULL,
            num_modules INT NOT NULL
        )',
        'CREATE UNIQUE INDEX ix_namespace__name ON namespace(name)',
        \&_fill_namespace,
    ],

    upgrade_to_v7 => [
        # actually PAUSE allows two authors to have the same filename. although
        # directory is still ignored, so a single author still cannot have
        # dir1/File-1.0.tar.gz and dir2/File-1.0.tar.gz.
        'DROP INDEX ix_file__name',
        'CREATE UNIQUE INDEX ix_file__cpanid__name ON file(cpanid,name)',
    ],

    upgrade_to_v8 => [
        # empty all data, we're now indexing the contents of each release
        # because we want to index more (scripts, module mentions in POD, etc)
        \&_reset,

        # we are deleting a column
        'DROP TABLE file',
        'CREATE TABLE file (
             id INTEGER NOT NULL PRIMARY KEY,
             name TEXT NOT NULL,
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid),

             mtime INT,
             size INT,

             -- file status: ok (archive type is known, content can be listed,
             -- and at least some files can be extracted), nofile (file does not
             -- exist in mirror), unsupported (archive type is not supported,
             -- e.g. rar, pm.gz)

             file_status TEXT,
             file_error TEXT,

             -- META.* processing status: ok (meta has been extracted and
             -- parsed), metaerr (META.json/META.yml has some error), nometa (no
             -- META.json/META.yml found).

             meta_status TEXT,
             meta_error TEXT,

             -- POD processing status: ok (POD has been extracted and
             -- parsed/indexed), NULL (has not been processed yet).

             pod_status TEXT,

             has_metajson INTEGER,
             has_metayml INTEGER,
             has_makefilepl INTEGER,
             has_buildpl INTEGER
        )',

        'CREATE TABLE content (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id),
             path TEXT NOT NULL,
             package TEXT, -- only the first package declaration will be recorded
             mtime INT,
             size INT -- uncompressed size
        )',
        'CREATE UNIQUE INDEX ix_content__file_id__path ON content(file_id, path)',

        'ALTER TABLE module ADD COLUMN content_id INTEGER REFERENCES content(id)',
        'ALTER TABLE module ADD COLUMN abstract TEXT',

        'CREATE TABLE script (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id), -- [cache]
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid), -- [cache]
             name TEXT NOT NULL,
             content_id INT REFERENCES content(id),
             abstract TEXT
        )',
        'CREATE UNIQUE INDEX ix_script__file_id__name ON script(file_id, name)',
        'CREATE INDEX ix_script__name ON script(name)',

        'CREATE TABLE mention (
             id INTEGER NOT NULL PRIMARY KEY,
             source_file_id INT NOT NULL REFERENCES file(id), -- [cache]
             source_content_id INT NOT NULL REFERENCES content(id),
             module_id INTEGER, -- if mention module and module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if mention module and module is unknown (unlisted in module table), only the name will be recorded here
             script_name TEXT   -- if mention script
        )',
        'CREATE UNIQUE INDEX ix_mention__module_id__source_content_id   ON mention(module_id, source_content_id)',
        'CREATE UNIQUE INDEX ix_mention__module_name__source_content_id ON mention(module_name, source_content_id)',
        'CREATE UNIQUE INDEX ix_mention__script_name__source_content_id ON mention(script_name, source_content_id)',
    ],

    upgrade_to_v9 => [
        'CREATE INDEX ix_content__package ON content(package)',
    ],

    upgrade_to_v10 => [
        # there was a bug which excludes content with mode > 777 which excludes
        # some (many?) content, so we reindex content/mention/script
        sub {
            my $dbh = shift;
            $dbh->do("UPDATE file SET file_status=NULL, file_error=NULL, pod_status=NULL");
            $dbh->do("DELETE FROM mention");
            $dbh->do("DELETE FROM script");
            $dbh->do("DELETE FROM content");
        },

        'ALTER TABLE file ADD COLUMN sub_status TEXT',

        # experimental
        'CREATE TABLE sub (
             id INTEGER NOT NULL PRIMARY KEY,
             file_id INTEGER NOT NULL REFERENCES file(id), --[cache]
             content_id INTEGER NOT NULL REFERENCES content(id),
             name TEXT NOT NULL,
             linum INTEGER NOT NULL
         )',
        'CREATE UNIQUE INDEX ix_sub__name__content_id ON sub(name, content_id)',

    ],

    upgrade_to_v11 => [
        # forgot to add indices because FOREIGN KEY does not automatically
        # create indexes
        'CREATE INDEX ix_dep__file_id ON dep(file_id)',
        'CREATE INDEX ix_dep__dist_id ON dep(dist_id)',
        'CREATE INDEX ix_dep__module_id ON dep(module_id)',
    ],

    upgrade_to_v12 => [
        'CREATE UNIQUE INDEX ix_file__id ON file(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_content__id ON content(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_module__id ON module(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_script__id ON script(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_mention__id ON mention(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_dist__id ON dist(id)', # not created automatically when there is another unique index?
        'CREATE UNIQUE INDEX ix_sub__id ON sub(id)', # not created automatically when there is another unique index?
    ],

    upgrade_to_v13 => [
        # add rec_ctime & rec_mtime column to all tables, so user can query
        # recently added/modified authors, modules, ...

        'ALTER TABLE author ADD COLUMN rec_ctime INT',
        'ALTER TABLE author ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_author__rec_ctime ON author(rec_ctime)',
        'CREATE INDEX ix_author__rec_mtime ON author(rec_mtime)',
        "UPDATE author SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE author SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE file ADD COLUMN rec_ctime INT',
        'ALTER TABLE file ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_file__rec_ctime ON file(rec_ctime)',
        'CREATE INDEX ix_file__rec_mtime ON file(rec_mtime)',
        "UPDATE file SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE file SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE content ADD COLUMN rec_ctime INT',
        'ALTER TABLE content ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_content__rec_ctime ON content(rec_ctime)',
        'CREATE INDEX ix_content__rec_mtime ON content(rec_mtime)',
        "UPDATE content SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE content SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE module ADD COLUMN rec_ctime INT',
        'ALTER TABLE module ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_module__rec_ctime ON module(rec_ctime)',
        'CREATE INDEX ix_module__rec_mtime ON module(rec_mtime)',
        "UPDATE module SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE module SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE script ADD COLUMN rec_ctime INT',
        'ALTER TABLE script ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_script__rec_ctime ON script(rec_ctime)',
        'CREATE INDEX ix_script__rec_mtime ON script(rec_mtime)',
        "UPDATE script SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE script SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE mention ADD COLUMN rec_ctime INT',
        'ALTER TABLE mention ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_mention__rec_ctime ON mention(rec_ctime)',
        'CREATE INDEX ix_mention__rec_mtime ON mention(rec_mtime)',
        "UPDATE mention SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE mention SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE namespace ADD COLUMN rec_ctime INT',
        'ALTER TABLE namespace ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_namespace__rec_ctime ON namespace(rec_ctime)',
        'CREATE INDEX ix_namespace__rec_mtime ON namespace(rec_mtime)',
        "UPDATE namespace SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE namespace SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE dist ADD COLUMN rec_ctime INT',
        'ALTER TABLE dist ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_dist__rec_ctime ON dist(rec_ctime)',
        'CREATE INDEX ix_dist__rec_mtime ON dist(rec_mtime)',
        "UPDATE dist SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE dist SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE dep ADD COLUMN rec_ctime INT',
        'ALTER TABLE dep ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_dep__rec_ctime ON dep(rec_ctime)',
        'CREATE INDEX ix_dep__rec_mtime ON dep(rec_mtime)',
        "UPDATE dep SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE dep SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",

        'ALTER TABLE sub ADD COLUMN rec_ctime INT',
        'ALTER TABLE sub ADD COLUMN rec_mtime INT',
        'CREATE INDEX ix_sub__rec_ctime ON sub(rec_ctime)',
        'CREATE INDEX ix_sub__rec_mtime ON sub(rec_mtime)',
        "UPDATE sub SET rec_ctime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_ctime IS NULL",
        "UPDATE sub SET rec_mtime=(SELECT value FROM meta WHERE name='last_index_time') WHERE rec_mtime IS NULL",
    ],

    upgrade_to_v14 => [
        # add log table
        'CREATE TABLE log (
             id INTEGER NOT NULL PRIMARY KEY,
             date INTEGER NOT NULL,
             lcpan_version TEXT,
             pid INTEGER NOT NULL,
             level INTEGER NOT NULL, -- like in Log::ger: fatal=10, error=20, warn=30, info=40, debug=50, trace=60
             category TEXT NOT NULL,
             summary TEXT NOT NULL
         )',
        'CREATE UNIQUE INDEX ix_log__id ON log(id)',
        'CREATE INDEX ix_log__date ON log(date)',
        'CREATE INDEX ix_log__category ON log(category)',
    ],

    upgrade_to_v15 => [
        # we merge 'dist' into 'file' table to make things simpler, because
        # 'dist' has a 1:1 relationship with 'file'
        'ALTER TABLE file ADD COLUMN dist_name TEXT',
        'ALTER TABLE file ADD COLUMN dist_abstract TEXT',
        'ALTER TABLE file ADD COLUMN dist_version VARCHAR(20)',
        'ALTER TABLE file ADD COLUMN dist_version_numified VARCHAR(20)',
        'ALTER TABLE file ADD COLUMN is_latest_dist BOOLEAN',
        'CREATE INDEX ix_file__dist_name ON file(dist_name)',

        'DROP TABLE dist',

        # recreate table dep to remove the dist_id column
        'DROP TABLE dep',
        'CREATE TABLE dep (
             file_id INTEGER,
             module_id INTEGER, -- if module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if module is unknown (unlisted in module table), only the name will be recorded here
             rel TEXT, -- relationship: requires, ...
             phase TEXT, -- runtime, ...
             version VARCHAR(20),
             version_numified DECIMAL,
             rec_ctime INT,
             rec_mtime INT,
             FOREIGN KEY (file_id) REFERENCES file(id),
             FOREIGN KEY (module_id) REFERENCES module(id)
         )',

        # since there were misplaced placeholders when setting rec_mtime (fixed
        # in 3be9ae8), we will need to redo file indexing.
        sub {
            my $dbh = shift;
            log_info("Will be reindexing for all files due to bug in lcpan <= 1.056");
            _reset($dbh, 'soft');
        },
    ],

    # for testing
    install_v1 => [
        'CREATE TABLE author (
             cpanid VARCHAR(20) NOT NULL PRIMARY KEY,
             fullname VARCHAR(255) NOT NULL,
             email TEXT
         )',

        'CREATE TABLE file (
             id INTEGER NOT NULL PRIMARY KEY,
             name TEXT NOT NULL,
             cpanid VARCHAR(20) NOT NULL REFERENCES author(cpanid),

             -- processing status: ok (meta has been extracted and parsed),
             -- nometa (file does contain cpan meta), nofile (file does not
             -- exist in mirror), unsupported (file type is not supported,
             -- e.g. rar, non archive), metaerr (meta has some error), err
             -- (other error).
             status TEXT
         )',
        'CREATE UNIQUE INDEX ix_file__name ON file(name)',

        'CREATE TABLE module (
             id INTEGER NOT NULL PRIMARY KEY,
             name VARCHAR(255) NOT NULL,
             file_id INTEGER NOT NULL,
             version VARCHAR(20)
         )',
        'CREATE UNIQUE INDEX ix_module__name ON module(name)',
        'CREATE INDEX ix_module__file_id ON module(file_id)',

        # this is inserted
        'CREATE TABLE dist (
             id INTEGER NOT NULL PRIMARY KEY,
             name VARCHAR(90) NOT NULL,
             abstract TEXT,
             file_id INTEGER NOT NULL,
             version VARCHAR(20)
         )',
        'CREATE INDEX ix_dist__name ON dist(name)',
        'CREATE UNIQUE INDEX ix_dist__file_id ON dist(file_id)',

        'CREATE TABLE dep (
             dist_id INTEGER,
             module_id INTEGER, -- if module is known (listed in module table), only its id will be recorded here
             module_name TEXT,  -- if module is unknown (unlisted in module table), only the name will be recorded here
             rel TEXT, -- relationship: requires, ...
             phase TEXT, -- runtime, ...
             version TEXT,
             FOREIGN KEY (dist_id) REFERENCES dist(id),
             FOREIGN KEY (module_id) REFERENCES module(id)
         )',
        'CREATE INDEX ix_dep__module_name ON dep(module_name)',
        'CREATE UNIQUE INDEX ix_dep__dist_id__module_id ON dep(dist_id,module_id)',
    ],
}; # spec

sub _create_schema {
    require SQL::Schema::Versioned;

    my $dbh = shift;

    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $dbh, spec => $db_schema_spec);
    die "Can't create/update schema: $res->[0] - $res->[1]\n"
        unless $res->[0] == 200;
}

sub _db_path {
    my ($cpan, $index_name) = @_;
    $index_name =~ m!/|\\! ? $index_name : "$cpan/$index_name";
}

sub _use_db_bootstrap {
    require File::ShareDir;
    require File::Which;
    require IPC::System::Options;

    my $db_path = shift;
    return if -f $db_path;

    my $dist_dir;
    eval { $dist_dir = File::ShareDir::dist_dir("App-lcpan-Bootstrap") };
    if ($@) {
        log_warn "Could not find bootstrap database, consider installing ".
            "App::lcpan::Bootstrap for faster index creation";
        return;
    }
    unless (File::Which::which("xz")) {
        log_warn "Could not use bootstrap database, the 'xz' utility ".
            "is not available to decompress the bootstrap";
        return;
    }
    log_info "Decompressing bootstrap database ...";
    IPC::System::Options::system(
        {shell=>1, die=>1, log=>1},
        "xz", "-cd", "$dist_dir/db/index.db.xz", \">", $db_path,
    );
}

sub _connect_db {
    require DBI;

    my ($mode, $cpan, $index_name, $use_bootstrap) = @_;

    my $db_path = _db_path($cpan, $index_name);
    _use_db_bootstrap($db_path) if $use_bootstrap;
    log_trace("Connecting to SQLite database at %s ...", $db_path);
    if ($mode eq 'ro') {
        # avoid creating the index file automatically if we are only in
        # read-only mode
        die "Can't find index '$db_path'\n" unless -f $db_path;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", undef, undef,
                           {RaiseError=>1});
    $dbh->do("PRAGMA cache_size = 400000"); # 400M
    _create_schema($dbh);
    $dbh;
}

# all subcommands (except special ones like 'update') call this first. lcpan can
# be used in daemon mode or CLI, and this routine handles both case. in daemon
# mode, we set $App::lcpan::state (containing database handle, etc) and reuse
# it. in CLI, there is no reuse between invocation.
sub _init {
    my ($args, $mode) = @_;

    unless ($App::lcpan::state) {
        _set_args_default($args);
        my $state = {
            dbh => _connect_db($mode, $args->{cpan}, $args->{index_name}, $args->{use_bootstrap}),
            cpan => $args->{cpan},
            index_name => $args->{index_name},
        };
        $App::lcpan::state = $state;
    }
    $App::lcpan::state;
}

# return "" if success, or error string
sub _check_meta {
    my $meta = shift;

    unless (ref($meta) eq 'HASH') {
        return "not a hash";
    }
    unless (defined $meta->{name}) {
        return "does not contain name";
    }
    "";
}

sub _parse_meta_json {
    require Parse::CPAN::Meta;

    my $content = shift;

    my $data;
    eval {
        $data = Parse::CPAN::Meta->load_json_string($content);
    };
    return ($@, undef) if $@;
    my $metaerr = _check_meta($data);
    return ($metaerr, undef) if $metaerr;
    return ("", $data);
}

sub _parse_meta_yml {
    require Parse::CPAN::Meta;

    my $content = shift;

    my $data;
    eval {
        $data = Parse::CPAN::Meta->load_yaml_string($content);
    };
    return ($@, undef) if $@;
    my $metaerr = _check_meta($data);
    return ($metaerr, undef) if $metaerr;
    return ("", $data);
}

sub _add_prereqs {
    my ($file_id, $hash, $phase, $rel, $sth_ins_dep, $sth_sel_mod) = @_;
    log_trace("  Adding prereqs (%s %s): %s", $phase, $rel, $hash);
    my $now = time();
    for my $mod (keys %$hash) {
        $sth_sel_mod->execute($mod);
        my $row = $sth_sel_mod->fetchrow_hashref;
        my ($mod_id, $mod_name);
        if ($row) {
            $mod_id = $row->{id};
        } else {
            $mod_name = $mod;
        }
        my $ver = $hash->{$mod};
        $sth_ins_dep->execute($file_id, $mod_id, $mod_name, $phase,
                              $rel, $ver, _numify_ver($ver),
                              $now, $now);
    }
}

sub _index_pod {
    my ($file_id, $file_name, $script_name,
        $content_id, $content_path,
        $ct,
        $type,

        $sth_sel_mod,
        $sth_sel_script,
        $sth_set_module_abstract,
        $sth_set_script_abstract,
        $sth_set_content_package,

        $module_ids,
        $module_file_ids,
        $script_file_ids,
        $scripts_re,
        $sth_ins_mention,
    ) = @_;

    log_trace("  Indexing POD of %s", $content_path);

    my $abstract;
    if ($ct =~ /^=head1 \s+ NAME\s*\R
                \s*\R
                \S+ \s+ - \s+ ([^\r\n]+)
               /mx) {
        $abstract = $1;
    }

    my $pkg;
    my ($module_id, $script_id);
    if ($ct =~ /^\s*package [ \t]+ ([A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*)\b
               /mx) {
        $pkg = $1;
        log_trace("  found package declaration '%s'", $pkg);
        $sth_set_content_package->execute($pkg, time(), $content_id);

        if ($type eq 'pm_or_pod') {
            # set module abstract if pkg refers to a known module
            $sth_sel_mod->execute($pkg);
            my $row = $sth_sel_mod->fetchrow_hashref;
            $sth_sel_mod->finish;
            if ($row) {
                $module_id = $row->{id};
                if ($abstract) {
                    log_trace("  set abstract for module %s: %s", $pkg, $abstract);
                    $sth_set_module_abstract->execute($abstract, time(), $module_id);
                }
            }
        }
    }

    if (defined $script_name) {
        $sth_sel_script->execute($script_name, $file_id);
        my $row = $sth_sel_script->fetchrow_hashref;
        $sth_sel_script->finish;
        if (!$row) {
            # shouldn't happen
            log_warn("BUG: Unknown script %s in %s (%s), skipped",
                     $script_name, $content_path, $file_name);
            return;
        }
        $script_id = $row->{id};
        # set script abstract
        if ($abstract) {
            log_trace("  set abstract for script %s (%s): %s", $script_name, $file_name, $abstract);
            $sth_set_script_abstract->execute($abstract, time(), $script_id);
        }
    }

    # list pod mentions
    {
        # turns out we cannot reuse Pod::Simple object? we must recreate the
        # instance for every parse.

        require App::lcpan::PodParser;
        my $pod_parser = App::lcpan::PodParser->new;
        $pod_parser->{file_id} = $file_id;
        $pod_parser->{content_id} = $content_id;
        $pod_parser->{module_ids} = $module_ids;
        $pod_parser->{module_file_ids} = $module_file_ids;
        $pod_parser->{script_file_ids} = $script_file_ids;
        $pod_parser->{scripts_re} = $scripts_re;
        $pod_parser->{sth_ins_mention} = $sth_ins_mention;

        eval {
            $pod_parser->parse_string_document($ct);
        };
        if ($@) {
            log_error("Can't parse POD for file '%s', skipped", $content_path);
        }
    }
}

sub _index_sub {
    my ($file_id,
        $content_id, $content_path,
        $ct,

        $sth_ins_sub,
    ) = @_;

    log_trace("  Indexing subs in %s", $content_path);

    require Compiler::Lexer;
    my $lexer = Compiler::Lexer->new;
    my $tokens = $lexer->tokenize($ct);
    for my $i (0..@$tokens-1) {
        my $t = $tokens->[$i];
        my $sub;
        if ($i < @$tokens-1 && $t->{name} eq 'FunctionDecl') {
            my $t2 = $tokens->[$i+1];
            if ($t2->{name} eq 'Function') {
                $sub = $t2->{data};
            }
        }
        next unless $sub;
        next if $sub =~ /\A_/;
        log_trace("  found sub declaration '%s' (line %s)", $sub, $t->{line});
        my $now = time();
        $sth_ins_sub->execute($sub, $t->{line}, $file_id, $content_id, $now,$now);
    }
}

sub _update_files {
    require IPC::System::Options;
    require JSON::PP;

    my %args = @_;
    _set_args_default(\%args);
    my $cpan = $args{cpan};
    my $index_name = $args{index_name};

    my $remote_url = $args{remote_url} // "http://mirrors.kernel.org/cpan";
    my $max_file_size = $args{max_file_size};

    my %plugin_args;
    if ($args{max_file_size}) {
        $plugin_args{FilterLcpan}{max_size} = $args{max_file_size};
    }
    if ($args{include_author} && @{ $args{include_author} }) {
        $plugin_args{FilterLcpan}{include_author} = $args{include_author};
    }
    if ($args{exclude_author} && @{ $args{exclude_author} }) {
        $plugin_args{FilterLcpan}{exclude_author} = $args{exclude_author};
    }
    $plugin_args{FilterLcpan}{verbose} = 1 if log_is_info();
    if (defined $args{retry_max_attempts}) {
        $plugin_args{Retry}{max_attempts} = $args{retry_max_attempts};
    }
    if (defined $args{retry_delay}) {
        $plugin_args{Retry}{delay} = $args{retry_delay};
    }

    my @cmd = (
        "minicpan",
        (log_is_warn() ? () : ("-q")),
        "-l", $cpan,
        "-r", $remote_url,
    );
    my $env = {};
    $env->{LWP_USERAGENT_PLUGINS} = JSON::PP::encode_json([%plugin_args]);
    $env->{PERL5OPT} = "-MLWP::Protocol::Patch::CountBytesIn -MEnd::PrintBytesIn -MLWP::UserAgent::Patch::Plugin";

    IPC::System::Options::system(
        {die=>1, log=>1, env=>$env},
        @cmd,
    );

    my $dbh = _connect_db('rw', $cpan, $index_name, $args{use_bootstrap});
    $dbh->do("INSERT OR REPLACE INTO meta (name,value) VALUES (?,?)",
             {}, 'last_mirror_time', time());

    [200];
}

sub _delete_releases_records {
    my ($dbh, @file_ids) = @_;

    log_trace("  Deleting dep records");
    $dbh->do("DELETE FROM dep WHERE file_id IN (".join(",",@file_ids).")");

    {
        my $sth = $dbh->prepare("SELECT name FROM module WHERE file_id IN (".join(",",@file_ids).")");
        $sth->execute;
        my @mods;
        while (my ($mod) = $sth->fetchrow_array) {
            push @mods, $mod;
        }

        my $sth_upd_ns_dec_num_mod = $dbh->prepare("UPDATE namespace SET num_modules=num_modules-1 WHERE name=?");
        for my $mod (@mods) {
            while (1) {
                $sth_upd_ns_dec_num_mod->execute($mod);
                $mod =~ s/::\w+\z// or last;
            }
        }
        $dbh->do("DELETE FROM namespace WHERE num_modules <= 0");

        log_trace("  Deleting module records");
        $dbh->do("DELETE FROM module WHERE file_id IN (".join(",",@file_ids).")");
    }

    log_trace("  Deleting mention records");
    $dbh->do("DELETE FROM mention WHERE source_file_id IN (".join(",",@file_ids).")");

    log_trace("  Deleting script records");
    $dbh->do("DELETE FROM script WHERE file_id IN (".join(",",@file_ids).")");

    log_trace("  Deleting sub records");
    $dbh->do("DELETE FROM sub WHERE file_id IN (".join(",",@file_ids).")");

    log_trace("  Deleting content records");
    $dbh->do("DELETE FROM content WHERE file_id IN (".join(",",@file_ids).")");

    $dbh->do("DELETE FROM file WHERE id IN (".join(",",@file_ids).")");
}

my $re_metajson = qr!^[/\\]?(?:[^/\\]+[/\\])?META\.json$!;
my $re_metayml  = qr!^[/\\]?(?:[^/\\]+[/\\])?META\.yml$!;

sub _sort_prefer_metajson_over_metayml {
    my @members = @_;

    # make sure we prefer META.json (SPEC 2.0) over .yml (SPEC 1.4)
    sort {
        my $a_filename = $a->{full_path} // $a->fileName;
        my $b_filename = $b->{full_path} // $b->fileName;
        my $a_is_metajson = $a_filename =~ $re_metajson;
        my $b_is_metajson = $b_filename =~ $re_metajson;
        my $a_is_metayml  = $a_filename =~ $re_metayml;
        my $b_is_metayml  = $b_filename =~ $re_metayml;

        ($a_is_metajson && $b_is_metayml) ? -1 :
            ($a_filename cmp $b_filename);
    } @members;
}

sub _list_archive_members {
    my ($path, $filename, $fileid) = @_;

    my ($zip, $tar);
    my @members;
    if ($path =~ /\.zip$/i) {
        require Archive::Zip;
        $zip = Archive::Zip->new;
        $zip->read($path) == Archive::Zip::AZ_OK()
            or do {
                log_error("Can't read zip file '%s', skipped", $filename);
                return [500, "can't read zip '$filename', skipped", undef, {'func.file_id'=>$fileid}];
            };
        #log_trace("  listing zip members ...");
        @members = $zip->members;
        #log_trace("  members: %s", \@members);
    } else {
        require Archive::Tar;
        eval {
            $tar = Archive::Tar->new;
            $tar->read($path); # can still die untrapped when out of mem
            die $tar->error if $tar->error;
            #log_trace("  listing tar members ...");
            @members = $tar->list_files(["full_path","mode","mtime","size"]);
            #log_trace("  members: %s", \@members);
        };
        if ($@) {
            log_error("Can't read tar file '%s', skipped", $filename);
            return [500, "$@", undef, {'func.file_id'=>$fileid}];
        }
    }
    [200, "OK", \@members, {'func.zip' => $zip, 'func.tar' => $tar}];
}

sub _get_meta {
    my ($la_res) = @_;
    my @members = _sort_prefer_metajson_over_metayml(@{$la_res->[2]});

    my $zip = $la_res->[3]{'func.zip'};
    my $tar = $la_res->[3]{'func.tar'};
    my $meta;

    if ($zip) {
        for my $member (@members) {
            if ($member->fileName =~ m!(?:/|\\)?(META\.yml|META\.json)$!) {
                log_trace("  found META: %s", $member->fileName);
                my $type = $1;
                #log_trace("content=[[%s]]", $content);
                my $content = $zip->contents($member);
                if ($type eq 'META.yml') {
                    (my $metaerr, $meta) = _parse_meta_yml($content);
                    return [500, $metaerr] if $metaerr;
                } elsif ($type eq 'META.json') {
                    (my $metaerr, $meta) = _parse_meta_json($content);
                    return [500, $metaerr] if $metaerr;
                }
                last;
            }
        }
    } else {
        for my $member (@members) {
            if ($member->{full_path} =~ m!/?(META\.yml|META\.json)$!) {
                log_trace("  found META %s", $member->{full_path});
                my $type = $1;
                my ($obj) = $tar->get_files($member->{full_path});
                my $content = $obj->get_content;
                if ($type eq 'META.yml') {
                    (my $metaerr, $meta) = _parse_meta_yml($content);
                    return [500, $metaerr] if $metaerr;
                } elsif ($type eq 'META.json') {
                    (my $metaerr, $meta) = _parse_meta_json($content);
                    return [500, $metaerr] if $metaerr;
                }
                last;
            }
        }
    }
    [200, "OK", $meta];
}

sub _update_index {
    require DBI;
    require File::Temp;
    require IO::Compress::Gzip;

    my %args = @_;
    _set_args_default(\%args);
    my $cpan = $args{cpan};
    my $index_name = $args{index_name};

    my $db_path = _db_path($cpan, $index_name);
    if ($args{num_backups} > 0 && (-f $db_path)) {
        require File::Copy;
        require Logfile::Rotate;
        log_info("Rotating old indexes ...");
        my $rotate = Logfile::Rotate->new(
            File  => $db_path,
            Count => $args{num_backups},
            Gzip  => 'no',
        );
        $rotate->rotate;
        File::Copy::copy("$db_path.1", $db_path)
              or return [500, "Copy $db_path.1 -> $db_path failed: $!"];
    }

    my $dbh  = _connect_db('rw', $cpan, $index_name, $args{use_bootstrap});

    # check whether we need to reindex if a sufficiently old (and possibly
    # incorrect) version of us did the reindexing
    {
        no strict 'refs';
        my $our_version = ${__PACKAGE__.'::VERSION'};

        my ($indexer_version) = $dbh->selectrow_array("SELECT value FROM meta WHERE name='indexer_version'");
        last unless $indexer_version;
        if ($our_version && version->parse($indexer_version) > version->parse($our_version)) {
            return [412, "Database is indexed by version ($indexer_version) newer than current software's version ($our_version), bailing out"];
        }
        if (version->parse($indexer_version) <= version->parse("0.35")) {
            log_info("Reindexing from scratch, deleting previous index content ...");
            _reset($dbh);
        }
    }

    _dblog($dbh, 40, "update_index", "Begin updating index");

    # parse 01mailrc.txt.gz and insert the parse result to 'author' table
  PARSE_MAILRC:
    {
        require DBIx::UpdateTable::FromHoH;

        my $path = "$cpan/authors/01mailrc.txt.gz";
        log_info("Parsing %s ...", $path);
        open my($fh), "<:gzip", $path or do {
            log_info("%s does not exist, skipped", $path);
            last PARSE_MAILRC;
        };

        my $hoh = {};
        my $line = 0;
        while (<$fh>) {
            $line++;
            my ($cpanid, $fullname, $email) = /^alias (\S+)\s+"(.*) <(.+)>"/ or do {
                log_warn("  line %d: syntax error, skipped: %s", $line, $_);
                next;
            };
            $hoh->{$cpanid} = {fullname=>$fullname, email=>$email};
        }
        my $now = time();
        my $res = DBIx::UpdateTable::FromHoH::update_table_from_hoh(
            dbh => $dbh,
            table => 'author',
            hoh => $hoh,
            key_column => 'cpanid',
            data_columns => [qw/fullname email/],
            extra_insert_columns => {rec_ctime=>$now, rec_mtime=>$now},
            extra_update_columns => {rec_mtime=>$now},
        );
        if ($res->[0] == 200) {
            log_info("Updated author table: %s", $res);
        } elsif ($res->[0] == 304) {
            log_trace("author table unchanged: %s", $res);
        } else {
            log_error("Can't update author table: %s", $res);
        }
    }

    # some darkpans (e.g. produced by OrePAN) has authors/00whois.xml instead
  PARSE_WHOIS:
    {
        my $path = "$cpan/authors/00whois.xml";
        log_info("Parsing %s ...", $path);
        open my($fh), "<", $path or do {
            log_info("%s does not exist, skipped", $path);
            last PARSE_WHOIS;
        };

        # currently we don't bother to use a real xml parser and just use regex
        # instead
        my $content = do { local $/; ~~<$fh> };

        # i would like to use INSERT OR IGNORE, but rows affected returned by
        # execute() is always 1?

        my $hoh = {};
        while ($content =~ m!<id>(\w+)</id>!g) {
            my ($cpanid) = ($1);
            $hoh->{$cpanid} = {fullname=>$cpanid, email=>undef};
        }
        my $now = time();
        my $res = DBIx::UpdateTable::FromHoH::update_table_from_hoh(
            dbh => $dbh,
            table => 'author',
            hoh => $hoh,
            key_column => 'cpanid',
            data_columns => [qw/fullname email/],
            extra_insert_columns => {rec_ctime=>$now, rec_mtime=>$now},
            extra_update_columns => {rec_mtime=>$now},
        );
        if ($res->[0] == 200) {
            log_info("Updated author table: %s", $res);
        } elsif ($res->[0] == 304) {
            log_trace("author table unchanged: %s", $res);
        } else {
            log_error("Can't update author table: %s", $res);
        }
    }

    # parse 02packages.details.txt.gz and insert the parse result to 'file' and
    # 'module' tables. we haven't parsed distribution names yet because that
    # will need information from META.{json,yaml} inside release files.
  PARSE_PACKAGES:
    {
        my $path = "$cpan/modules/02packages.details.txt.gz";
        log_info("Parsing %s ...", $path);
        open my($fh), "<:gzip", $path or die "Can't open $path (<:gzip): $!";

        my $sth_sel_file = $dbh->prepare("SELECT id FROM file WHERE name=? AND cpanid=?");
        my $sth_ins_file = $dbh->prepare("INSERT INTO file (name,cpanid,mtime,size, rec_ctime,rec_mtime) VALUES (?,?,?,?, ?,?)");
        my $sth_ins_mod  = $dbh->prepare("INSERT INTO module (name,file_id,cpanid,version,version_numified, rec_ctime,rec_mtime) VALUES (?,?,?,?,?, ?,?)");
        my $sth_upd_mod  = $dbh->prepare("UPDATE module SET file_id=?,cpanid=?,version=?,version_numified=?, rec_mtime=? WHERE name=?"); # sqlite currently does not have upsert

        $dbh->begin_work;

        my %file_ids_in_table; # key="cpanid|filename"
        my $sth = $dbh->prepare("SELECT cpanid,name,id FROM file");
        $sth->execute;
        while (my ($cpanid, $name, $id) = $sth->fetchrow_array) {
            $file_ids_in_table{"$cpanid|$name"} = $id;
        }

        my %file_ids_in_02packages; # key="cpanid|filename", val=id (or undef if already exists in db)
        my $line = 0;
        while (<$fh>) {
            $line++;
            next unless /\S/;
            next if /^\S+:\s/;
            chomp;
            my ($pkg, $ver, $path) = split /\s+/, $_;
            $ver = undef if $ver eq 'undef';
            my ($author, $file) = $path =~ m!^./../(.+?)/(.+)! or do {
                log_warn("  line %d: Invalid path %s, skipped", $line, $path);
                next;
            };
            my $file_id;
            if (exists $file_ids_in_02packages{"$author|$file"}) {
                $file_id = $file_ids_in_02packages{"$author|$file"};
            } else {
                $sth_sel_file->execute($file, $author);
                my $path = _fullpath($file, $cpan, $author);
                my @stat = stat $path;
                unless ($sth_sel_file->fetchrow_arrayref) {
                    my $now = time();
                    $sth_ins_file->execute(
                        $file, $author, @stat ? $stat[9] : undef, @stat ? $stat[7] : undef,
                        $now, $now);
                    $file_id = $dbh->last_insert_id("","","","");
                    log_trace("  New file: %s (author %s)", $file, $author);
                }
                $file_ids_in_02packages{"$author|$file"} = $file_id;
            }
            next unless $file_id;

            my $mod_id;
            if (($mod_id) = $dbh->selectrow_array("SELECT id FROM module WHERE name=?", {}, $pkg)) {
                $sth_upd_mod->execute(      $file_id, $author, $ver, _numify_ver($ver), time(), $pkg);
            } else {
                my $now = time();
                $sth_ins_mod->execute($pkg, $file_id, $author, $ver, _numify_ver($ver), $now,$now);
                $mod_id = $dbh->last_insert_id("","","","");
                _set_namespace($dbh, $pkg);
            }

            log_trace("  New/updated module: %s (file ID=%d, module ID=%d)", $pkg, $file_id, $mod_id);
        } # while <fh>

        # cleanup: delete file record (as well as dists, modules, and deps
        # records) for files in db that are no longer in 02packages.
      CLEANUP:
        {
            my @old_file_ids;
            my @old_file_entries; # ("author|filename", ...)
            for my $k (sort keys %file_ids_in_table) {
                next if exists $file_ids_in_02packages{$k};
                push @old_file_ids, $file_ids_in_table{$k};
                push @old_file_entries, $k;
            }
            last CLEANUP unless @old_file_ids;

            _delete_releases_records($dbh, @old_file_ids);
            log_trace("  Deleted file records (%d): %s", ~~@old_file_entries, \@old_file_entries);
        }

        $dbh->commit;
    }

    my @passes;
    if ($args{skip_file_indexing_pass_1}) {
        log_info("Will be skipping file indexing pass 1");
    } else {
        push @passes, 1;
    }
    if ($args{skip_file_indexing_pass_2}) {
        log_info("Will be skipping file indexing pass 2");
    } else {
        push @passes, 2;
    }
    if ($args{skip_file_indexing_pass_3} ||
            ($args{skip_sub_indexing} // 1)) {
        log_info("Will be skipping file indexing pass 3");
    } else {
        push @passes, 3;
    }

  PROCESS_FILES_PASS:
    for my $pass (@passes) {
        # we're processing files in several passes.

        # the first pass: insert content, scripts, extract meta, insert dep
        # information, set file_status and meta_status.

        # the second pass: extract PODs and insert module/script abstracts and
        # pod mentions.

        # the third pass: subroutine indexing

        # we're doing it in several passes because: in pass 2, we want to
        # collect all known scripts first to be able to detect links to scripts
        # in POD (collected in pass 1). also some passes are more high-level
        # and/or experimental and/or optional.

        my $sth = $dbh->prepare(
            $pass == 1 ?
                "SELECT * FROM file WHERE file_status IS NULL OR meta_status IS NULL ORDER BY name" :

                $pass == 2 ?
                "SELECT * FROM file WHERE pod_status IS NULL AND file_status NOT IN ('nofile','unsupported','err') ORDER BY name" :

                "SELECT * FROM file WHERE sub_status IS NULL AND file_status NOT IN ('nofile','unsupported','err') ".
                "AND EXISTS(SELECT id FROM content WHERE file_id=file.id AND package IS NOT NULL) ORDER BY name"
        );
        $sth->execute;

        my @files;
        while (my $row = $sth->fetchrow_hashref) {
            push @files, $row;
        }

        my $sth_set_file_status = $dbh->prepare("UPDATE file SET file_status=?,file_error=?, rec_mtime=? WHERE id=?");
        my $sth_ins_content = $dbh->prepare("INSERT OR REPLACE INTO content (file_id,path,mtime,size, rec_ctime,rec_mtime) VALUES (?,?,?,?, ?,?)");
        my $sth_ins_script = $dbh->prepare("INSERT OR REPLACE INTO script (name, cpanid, content_id, file_id, rec_ctime,rec_mtime) VALUES (?,?,?,?, ?,?)");

        my $sth_set_meta_status = $dbh->prepare("UPDATE file SET meta_status=?,meta_error=?, rec_mtime=? WHERE id=?");
        my $sth_set_meta_info = $dbh->prepare("UPDATE file SET has_metajson=?,has_metayml=?,has_makefilepl=?,has_buildpl=?, rec_mtime=? WHERE id=?");
        my $sth_set_dist_info = $dbh->prepare("UPDATE file SET dist_name=?,dist_abstract=?,dist_version=?,dist_version_numified=?, rec_mtime=? WHERE id=?");
        my $sth_ins_dep = $dbh->prepare("INSERT OR REPLACE INTO dep (file_id,module_id,module_name,phase,rel, version,version_numified, rec_ctime,rec_mtime) VALUES (?,?,?,?,?, ?,?, ?,?)");

        my $sth_sel_mod  = $dbh->prepare("SELECT * FROM module WHERE name=?");
        my $sth_sel_script  = $dbh->prepare("SELECT * FROM script WHERE name=? AND file_id=?");

        # for pass 2
        my $sth_set_pod_status = $dbh->prepare("UPDATE file SET pod_status=?, rec_mtime=? WHERE id=?");
        my $sth_sel_content = $dbh->prepare("SELECT * FROM content WHERE file_id=?");
        my $sth_set_module_abstract = $dbh->prepare("UPDATE module SET abstract=?, rec_mtime=? WHERE id=?");
        my $sth_set_script_abstract = $dbh->prepare("UPDATE script SET abstract=?, rec_mtime=? WHERE id=?");
        my $sth_ins_mention = $dbh->prepare("INSERT OR IGNORE INTO mention (source_content_id,source_file_id,module_id,module_name,script_name, rec_ctime,rec_mtime) VALUES (?,?,?,?,?, ?,?)");
        my $sth_set_content_package = $dbh->prepare("UPDATE content SET package=?, rec_mtime=? WHERE id=?");

        # for pass 3
        my $sth_sel_content__has_package = $dbh->prepare("SELECT * FROM content WHERE file_id=? AND package IS NOT NULL");
        my $sth_ins_sub = $dbh->prepare("INSERT OR IGNORE INTO sub (name, linum, file_id, content_id, rec_ctime,rec_mtime) VALUES (?,?,?,?, ?,?)");
        my $sth_set_sub_status = $dbh->prepare("UPDATE file SET sub_status=?, rec_mtime=? WHERE id=?");

        my $module_ids; # hash, key=module name, value=module id
        my $module_file_ids; # hash, key=module name, value=file id
        my $script_file_ids; # hash, key=script name, value=[file id, ...]
        my $scripts_re;
        if ($pass == 2) {
            # prepare the names of all scripts & modules, for quick reference
            $module_ids = {};
            $module_file_ids = {};
            $script_file_ids = {};
            my $sth = $dbh->prepare("SELECT id,file_id,name FROM module");
            $sth->execute;
            while (my $row = $sth->fetchrow_hashref) {
                $module_ids->{$row->{name}} = $row->{id};
                $module_file_ids->{$row->{name}} = $row->{file_id};
            }

            my %script_names;
            $sth = $dbh->prepare("SELECT name,file_id FROM script");
            $sth->execute;
            while (my $row = $sth->fetchrow_hashref) {
                $script_names{ $row->{name} }++;
                $script_file_ids->{$row->{name}} //= [];
                push @{ $script_file_ids->{$row->{name}} }, $row->{file_id};
            }
            my @script_names = sort {length($b) <=> length($a) || $a cmp $b}
                keys %script_names;
            $scripts_re = "\\A(?:" . join("|", map {quotemeta} @script_names) . ")\\z";
            $scripts_re = qr/$scripts_re/;
            #log_trace("TMP: script_re = %s", $scripts_re);
            #log_trace("TMP: scripts_names = %s", \%script_names);
        }

        my $i = 0;
        my $after_begin;

      FILE:
        for my $file (@files) {

            # commit after every 500 files
            if ($i % 500 == 499) {
                log_trace("COMMIT");
                $dbh->commit;
                $dbh->begin_work;
            }
            if ($i % 500 == 0) {
                unless ($after_begin) {
                    log_trace("BEGIN");
                    $dbh->begin_work;
                    $after_begin = 1;
                }
            }
            $i++;

            if (my $reason = $builtin_file_skip_list{ $file->{name} }) {
                log_info("Skipped file %s (reason: built-in file skip list: %s)", $file->{name}, $reason);
                next FILE;
            }

            if ($args{skip_index_files} && first {$_ eq $file->{name}} @{ $args{skip_index_files} }) {
                log_info("Skipped file %s (reason: skip_index_files)", $file->{name});
                next FILE;
            }

            if ($args{skip_index_file_patterns} && first {$file->{name} =~ $_} @{ $args{skip_index_file_patterns} }) {
                log_info("Skipped file %s (reason: skip_index_file_patterns)", $file->{name});
                next FILE;
            }

            my $path = _fullpath($file->{name}, $cpan, $file->{cpanid});

            log_info("[pass %d/3][#%i/%d] Processing file %s ...",
                        $pass, $i, ~~@files, $path);

            if (!$file->{file_status}) {
                unless (-f $path) {
                    log_error("File %s doesn't exist, skipped", $path);
                    $sth_set_file_status->execute("nofile", undef, time(), $file->{id});
                    $sth_set_meta_status->execute("nometa", undef, time(), $file->{id});
                    next FILE;
                }
                if ($path !~ /(.+)\.(tar|tar\.gz|tar\.bz2|tar\.Z|tgz|tbz2?|zip)$/i) {
                    log_error("Doesn't support file type: %s, skipped", $file->{name});
                    $sth_set_file_status->execute("unsupported", undef, time(), $file->{id});
                    $sth_set_meta_status->execute("nometa", undef, time(), $file->{id});
                    next FILE;
                }
            }

            next FILE if $file->{file_status} && $file->{file_status} =~ /\A(unsupported)\z/;

            my $la_res = _list_archive_members($path, $file->{name}, $file->{id});
            unless ($la_res->[0] == 200) {
                $sth_set_file_status->execute("err", $la_res->[1], time(), $la_res->[3]{'func.file_id'});
                $sth_set_meta_status->execute("err", "file err", time(), $la_res->[3]{'func.file_id'});
                next FILE;
            }
            my @members = @{ $la_res->[2] };
            my $zip = $la_res->[3]{'func.zip'};
            my $tar = $la_res->[3]{'func.tar'};

            my $code_is_script = sub {
                my $name = shift;
                unless ($name =~ m!\A
                                   (?:\./)?
                                   (?:[^/]+/)?
                                   (?:s?bin|scripts?)/
                                   ([^/]+)
                                   \z!x) {
                    return (undef);
                }
                my $script_name = $1;
                if ($script_name =~ /\A\./ # e.g. "bin/.exists"
                        || $script_name =~ /\A(?:README(?:\.\w+)?)\z/) { # probably not a script
                    return (undef);
                }
                return ($script_name);
            };

            my $code_is_pm_or_pod = sub {
                my $name = shift;
                # flat, *.pm in top-level
                if ($name =~ m!\A
                               (?:\./)?
                               (?:[^/]+/)? # enclosing dir
                               [^/]+\.(?:pm|pod)?
                               \z
                              !ix) {
                    return 1;
                }
                # *.pm under lib
                if ($name =~ m!\A
                               (?:\./)?
                               (?:[^/]+/)? # enclosing dir
                               lib/
                               (?:[^/]+/)*
                               [^/]+\.(?:pm|pod)?
                               \z
                              !ix) {
                    return 1;
                }
                return 0;
            };

            if (!$file->{file_status}) {
                # list contents & scripts and insert into database
                my %script_names;
                if ($zip) {
                    for my $member (@members) {
                        # skip directory/symlinks
                        next if $member->{isSymbolicLink} || $member->{fileName} =~ m!/\z!;
                        my $now = time();
                        $sth_ins_content->execute(
                            $file->{id}, $member->{fileName}, $member->{lastModFileDateTime}, $member->{uncompressedSize},
                            $now,$now);
                        my $content_id = $dbh->last_insert_id("","","","");
                        my ($script_name) = $code_is_script->($member->{fileName});
                        if (defined $script_name) {
                            unless ($script_names{$script_name}++) {
                                my $now = time();
                                $sth_ins_script->execute($script_name, $file->{cpanid}, $content_id, $file->{id},
                                                         $now,$now);
                            }
                        }
                    }
                } else {
                    my %mem; # tar allows duplicate path?
                    for my $member (@members) {
                        next if $member->{full_path} =~ m!/\z!;
                        next if !$member->{size};
                        next if $mem{$member->{full_path}}++;
                        my $now = time();
                        $sth_ins_content->execute(
                            $file->{id}, $member->{full_path}, $member->{mtime}, $member->{size},
                            $now,$now);
                        my $content_id = $dbh->last_insert_id("","","","");
                        my ($script_name) = $code_is_script->($member->{full_path});
                        if (defined $script_name) {
                            unless ($script_names{$script_name}++) {
                                my $now = time();
                                $sth_ins_script->execute($script_name, $file->{cpanid}, $content_id, $file->{id},
                                                     $now,$now);
                            }
                        }
                    }
                }
                $sth_set_file_status->execute("ok", undef, time(), $file->{id});
                $file->{file_status} = 'ok';
            }

            next FILE if $file->{file_status} ne 'ok';

            my $meta;
          GET_META:
            {
                last if $file->{meta_status};
                my ($has_metajson, $has_metayml, $has_makefilepl, $has_buildpl);
                if ($zip) {
                    $has_metajson   = (first { $_ =~ $re_metajson } @members) ? 1:0;
                    $has_metayml    = (first { $_ =~ $re_metayml  } @members) ? 1:0;
                    $has_makefilepl = (first {m!^[/\\]?(?:[^/\\]+[/\\])?Makefile\.PL$!} @members) ? 1:0;
                    $has_buildpl    = (first {m!^[/\\]?(?:[^/\\]+[/\\])?Build\.PL$!} @members) ? 1:0;
                } else {
                    $has_metajson   = (first { $_->{full_path} =~ $re_metajson } @members) ? 1:0;
                    $has_metayml    = (first { $_->{full_path} =~ $re_metayml  } @members) ? 1:0;
                    $has_makefilepl = (first {$_->{full_path} =~ m!/([^/]+)?Makefile\.PL$!} @members) ? 1:0;
                    $has_buildpl    = (first {$_->{full_path} =~ m!/([^/]+)?Build\.PL$!} @members) ? 1:0;
                }

                my $gm_res = _get_meta($la_res);
                if ($gm_res->[0] == 200) {
                    $meta = $gm_res->[2];
                } else {
                    log_warn("  error in meta: %s", $gm_res->[1]);
                }
                $sth_set_meta_status->execute($meta ? "ok" : "nometa", undef, time(), $file->{id});
                $sth_set_meta_info->execute($has_metajson, $has_metayml, $has_makefilepl, $has_buildpl, time(), $file->{id});
            }

          GET_DEPS:
            {
                last unless $meta;

                # insert dist & dependency information from meta

                my $dist_name = $meta->{name};
                my $dist_abstract = $meta->{abstract};
                my $dist_version = $meta->{version};
                $dist_name =~ s/::/-/g; # sometimes author miswrites module name

                $sth_set_dist_info->execute($dist_name, $dist_abstract, $dist_version, _numify_ver($dist_version), time(), $file->{id});

                # insert dependency information
                if (ref($meta->{configure_requires}) eq 'HASH') {
                    _add_prereqs($file->{id}, $meta->{configure_requires}, 'configure', 'requires', $sth_ins_dep, $sth_sel_mod);
                }
                if (ref($meta->{build_requires}) eq 'HASH') {
                    _add_prereqs($file->{id}, $meta->{build_requires}, 'build', 'requires', $sth_ins_dep, $sth_sel_mod);
                }
                if (ref($meta->{test_requires}) eq 'HASH') {
                    _add_prereqs($file->{id}, $meta->{test_requires}, 'test', 'requires', $sth_ins_dep, $sth_sel_mod);
                }
                if (ref($meta->{requires}) eq 'HASH') {
                    _add_prereqs($file->{id}, $meta->{requires}, 'runtime', 'requires', $sth_ins_dep, $sth_sel_mod);
                }
                if (ref($meta->{prereqs}) eq 'HASH') {
                    for my $phase (keys %{ $meta->{prereqs} }) {
                        my $phprereqs = $meta->{prereqs}{$phase};
                        for my $rel (keys %$phprereqs) {
                            _add_prereqs($file->{id}, $phprereqs->{$rel}, $phase, $rel, $sth_ins_dep, $sth_sel_mod);
                        }
                    }
                }
            } # GET_DEPS

          PARSE_POD:
            {
                last if $pass != 2;
                last if $file->{pod_status};

                my @contents;
                $sth_sel_content->execute($file->{id});
                while (my $row = $sth_sel_content->fetchrow_hashref) {
                    push @contents, $row;
                }
                $sth_sel_content->finish;

                for my $content (@contents) {
                    my ($script_name) = $code_is_script->($content->{path});
                    my $is_pm_or_pod = $code_is_pm_or_pod->($content->{path});
                    next unless defined($script_name) || $is_pm_or_pod;

                    my $ct;
                    if ($zip) {
                        $ct = $zip->contents($content->{path});
                    } else {
                        my ($obj) = $tar->get_files($content->{path});
                        $ct = $obj->get_content;
                    }

                    _index_pod(
                        $file->{id}, $file->{name}, $script_name,
                        $content->{id}, $content->{path},
                        $ct,
                        defined($script_name) ? 'script' : 'pm_or_pod',

                        $sth_sel_mod,
                        $sth_sel_script,
                        $sth_set_module_abstract,
                        $sth_set_script_abstract,
                        $sth_set_content_package,

                        $module_ids,
                        $module_file_ids,
                        $script_file_ids,
                        $scripts_re,
                        $sth_ins_mention,
                    );
                } # for each content

                $sth_set_pod_status->execute("ok", time(), $file->{id});
            } # PARSE_POD

          PARSE_SUB:
            {
                last if $pass != 3;

                if (my $reason = $builtin_file_skip_list_sub{ $file->{name} }) {
                    log_info("Skipped indexing subs for file %s (reason: built-in file skip list for sub: %s)", $file->{name}, $reason);
                    $sth_set_sub_status->execute("skipped", time(), $file->{id});
                    last;
                }

                if ($args{skip_sub_indexing_files} && first {$_ eq $file->{name}} @{ $args{skip_sub_indexing_files} }) {
                    log_info("Skipped indexing subs for file %s (reason: skip_sub_indexing_files)", $file->{name});
                    $sth_set_sub_status->execute("skipped", time(), $file->{id});
                    last;
                }

                if ($args{skip_sub_indexing_file_patterns} && first {$file->{name} =~ $_} @{ $args{skip_sub_indexing_file_patterns} }) {
                    log_info("Skipped indexing subs for file %s (reason: skip_sub_indexing_file_patterns)", $file->{name});
                    $sth_set_sub_status->execute("skipped", time(), $file->{id});
                    last;
                }

                my @contents;
                $sth_sel_content__has_package->execute($file->{id});
                while (my $row = $sth_sel_content__has_package->fetchrow_hashref) {
                    push @contents, $row;
                }
                $sth_sel_content__has_package->finish;

                for my $content (@contents) {
                    my $ct;
                    if ($zip) {
                        $ct = $zip->contents($content->{path});
                    } else {
                        my ($obj) = $tar->get_files($content->{path});
                        $ct = $obj->get_content;
                    }

                    _index_sub(
                        $file->{id},
                        $content->{id}, $content->{path},
                        $ct,

                        $sth_ins_sub,
                    );
                } # for each content

                $sth_set_sub_status->execute("ok", time(), $file->{id});
            } # PARSE_SUB

        } # for each file

        if ($after_begin) {
            log_trace("COMMIT");
            $dbh->commit;
        }
    } # process files

    # TODO: try to extract its CPAN META or Makefile.PL/Build.PL (dependencies
    # information), parse its PODs (module/script abstracts, 'mentions'
    # information)

    # there remains some files for which we haven't determine the dist name of
    # (e.g. non-existing file, no info, other error). we determine the dist from
    # the module name.
    {
        my $sth = $dbh->prepare("SELECT * FROM file WHERE dist_name IS NULL");
        my @files;
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            push @files, $row;
        }

        my $sth_sel_mod = $dbh->prepare("SELECT * FROM module WHERE file_id=? ORDER BY name LIMIT 1");
        my $sth_set_dist_info = $dbh->prepare("UPDATE file SET dist_name=?,dist_version=?,dist_version_numified=?, rec_mtime=? WHERE id=?");

        $dbh->begin_work;
      FILE:
        for my $file (@files) {
            $sth_sel_mod->execute($file->{id});
            my $row = $sth_sel_mod->fetchrow_hashref or next FILE;
            my $dist_name = $row->{name};
            $dist_name =~ s/::/-/g;
            log_trace("Setting dist name for %s as %s (from module name %s)", $row->{name}, $dist_name, $row->{name});
            $sth_set_dist_info->execute($dist_name, $row->{version}, _numify_ver($row->{version}), time(), $file->{id});
        }
        $dbh->commit;
    }

    {
        log_trace("Updating is_latest_dist column ...");
        $dbh->do("UPDATE file SET is_latest_dist=".
                     "(SELECT CASE WHEN EXISTS(SELECT name FROM file f2 WHERE f2.dist_name=file.dist_name AND f2.dist_version_numified>file.dist_version_numified) THEN 0 ELSE 1 END)".
                     " WHERE dist_name IS NOT NULL");
    }

  UPDATE_TIMESTAMPS: {
        my $now = time();

        _dblog($dbh, 40, "update_index", "Finish updating index");

        my ($index_creation_time_exists) = $dbh->selectrow_array(
            "SELECT 1 FROM META WHERE name='index_creation_time'");
        my ($last_index_time) = $dbh->selectrow_array(
            "SELECT value FROM META WHERE name='last_index_time'");
        unless ($index_creation_time_exists) {
            $dbh->do("INSERT INTO meta (name,value) VALUES (?,?)",
                     {}, 'index_creation_time',
                     $last_index_time ? undef : $now);
        }
        $dbh->do("INSERT OR REPLACE INTO meta (name,value) VALUES (?,?)",
                 {}, 'last_index_time', $now);

        # record the module version that does the indexing
        {
            no strict 'refs';
            $dbh->do("INSERT OR REPLACE INTO meta (name,value) VALUES (?,?)",
                     {}, 'indexer_version', ${__PACKAGE__.'::VERSION'});
        }
    }

    [200];
}

$SPEC{'update'} = {
    v => 1.1,
    summary => 'Create/update local CPAN mirror',
    description => <<'_',

This subcommand first create/update the mirror files by downloading from a
remote CPAN mirror, then update the index.

_
    args_rels => {
        # it should be: update_index=0 conflicts with force_update_index
        #choose_one => [qw/update_index force_update_index/],
    },
    args => {
        %common_args,
        max_file_size => {
            summary => 'If set, skip downloading files larger than this',
            schema => 'int',
            tags => ['category:filtering'],
        },
        retry_max_attempts => {
            summary => 'Number of retry attempts on failed HTTP request',
            schema => 'int',
            tags => ['category:retry'],
        },
        retry_delay => {
            summary => 'Number of seconds to delay between retry attempt',
            schema => 'int',
            tags => ['category:retry'],
        },
        include_author => {
            summary => 'Only include files from certain author(s)',
            'summary.alt.plurality.singular' => 'Only include files from certain author',
            schema => ['array*', of=>['str*', match=>qr/\A[A-Z]{2,9}\z/]],
            tags => ['category:filtering'],
        },
        exclude_author => {
            summary => 'Exclude files from certain author(s)',
            'summary.alt.plurality.singular' => 'Exclude files from certain author',
            schema => ['array*', of=>['str*', match=>qr/\A[A-Z]{2,9}\z/]],
            tags => ['category:filtering'],
        },
        remote_url => {
            summary => 'Select CPAN mirror to download from',
            schema => 'str*',
        },
        update_files => {
            summary => 'Update the files',
            'summary.alt.bool.not' => 'Skip updating the files',
            schema => 'bool',
            default => 1,
        },
        update_index => {
            summary => 'Update the index',
            'summary.alt.bool.not' => 'Skip updating the index',
            schema => 'bool',
            default => 1,
        },
        force_update_index => {
            summary => 'Update the index even though there is no change in files',
            schema => ['bool', is=>1],
        },
        skip_index_files => {
            summary => 'Skip one or more files from being indexed',
            'x.name.is_plural' => 1,
            'summary.alt.plurality.singular' => 'Skip a file from being indexed',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {
                F => {
                    summary => 'Alias for --skip-index-file',
                    code => sub {
                        $_[0]{skip_index_files} //= [];
                        push @{ $_[0]{skip_index_files} }, $_[1];
                    },
                },
            },
            examples => ['Foo-Bar-1.23.tar.gz'],
        },
        skip_index_file_patterns => {
            summary => 'Skip one or more file patterns from being indexed',
            'x.name.is_plural' => 1,
            'summary.alt.plurality.singular' => 'Specify a file pattern to skip from being indexed',
            schema => ['array*', of=>'re*'],
            cmdline_aliases => {
            },
            examples => ['^Foo-Bar-\d'],
        },
        skip_sub_indexing_files => {
            summary => 'Skip one or more files from being parsed for subs',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'skip_sub_indexing_file',
            'summary.alt.plurality.singular' => 'Skip a file from being parsed for subs',
            schema => ['array*', of=>'str*'],
            examples => ['Foo-Bar-1.23.tar.gz'],
        },
        skip_sub_indexing_file_patterns => {
            summary => 'Skip one or more file patterns from being parsed for subs',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'skip_sub_indexing_file_pattern',
            'summary.alt.plurality.singular' => 'Specify a file pattern to skip being parsed for subs',
            schema => ['array*', of=>'re*'],
            cmdline_aliases => {
            },
            examples => ['^Foo-Bar-\d'],
        },
        skip_file_indexing_pass_1 => {
            schema => 'bool*',
        },
        skip_file_indexing_pass_2 => {
            schema => 'bool*',
        },
        skip_file_indexing_pass_3 => {
            schema => 'bool*',
        },
        skip_sub_indexing => {
            schema => ['bool'],
            default => 1,
            description => <<'_',

Since sub indexing is still experimental, it is not enabled by default. To
enable it, pass the `--no-skip-sub-indexing` option.

_
        },
    },
    tags => ['write-to-db', 'write-to-fs'],
};
sub update {
    my %args = @_;
    _set_args_default(\%args);
    my $cpan = $args{cpan};

    my $packages_path = "$cpan/modules/02packages.details.txt.gz";
    my @st1 = stat($packages_path);
    if (!$args{update_files}) {
        log_info("Skipped updating files (reason: option update_files=0)");
    } else {
        _update_files(%args); # it only returns 200 or dies
    }
    my @st2 = stat($packages_path);

    if (!$args{update_index} && !$args{force_update_index}) {
        log_info("Skipped updating index (reason: option update_index=0)");
    } elsif (!$args{force_update_index} && $args{update_files} &&
                 @st1 && @st2 && $st1[9] == $st2[9] && $st1[7] == $st2[7]) {
        log_info("%s doesn't change mtime/size, skipping updating index",
                    $packages_path);
        return [304, "Files did not change, index not updated"];
    } else {
        my $res = _update_index(%args);
        return $res unless $res->[0] == 200;
    }
    [200, "OK"];
}

sub _table_exists {
    my ($dbh, $schema, $name) = @_;
    my $sth = $dbh->table_info(undef, $schema, $name, undef);
    $sth->fetchrow_hashref ? 1:0;
}

sub _reset {
    # this sub is used since v7, so we need to check tables that have not
    # existed in v7 or earlier.
    my ($dbh, $soft) = @_;
    $dbh->do("DELETE FROM dep");
    $dbh->do("DELETE FROM namespace");
    $dbh->do("DELETE FROM mention")   if _table_exists($dbh, "main", "mention");
    $dbh->do("DELETE FROM module");
    $dbh->do("DELETE FROM script")    if _table_exists($dbh, "main", "script");
    $dbh->do("DELETE FROM sub")       if _table_exists($dbh, "main", "sub");
    $dbh->do("DELETE FROM dist")      if _table_exists($dbh, "main", "dist");
    $dbh->do("DELETE FROM content")   if _table_exists($dbh, "main", "content");
    $dbh->do("DELETE FROM file");
    $dbh->do("DELETE FROM author");
    $dbh->do("DELETE FROM log")       if _table_exists($dbh, "main", "log") && !$soft;

    $dbh->do("DELETE FROM meta WHERE name='index_creation_time'") if !$soft;
}

$SPEC{'reset'} = {
    v => 1.1,
    summary => 'Reset (empty) the database index',
    description => <<'_',

All data tables will be emptied. This includes all records in the `log` table as
well as `index_creation_time` record in the `meta` table, so there is no records
of previous indexing activity. There is also no record of resetting in the
`log`.

Tables are not dropped and re-created. The `meta` table is not emptied.

_
    args => {
        %common_args,
    },
    tags => ['write-to-db'],
};
sub reset {
    require IO::Prompt::I18N;

    my %args = @_;

    my $state = _init(\%args, 'rw');
    my $dbh = $state->{dbh};

    return [200, "Cancelled"]
        unless IO::Prompt::I18N::confirm("Confirm reset index", {default=>0});

    _reset($dbh);
    [200, "Reset"];
}

$SPEC{'stats'} = {
    v => 1.1,
    summary => 'Statistics of your local CPAN mirror',
    args => {
        %common_args,
    },
};
sub stats {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $stat = {};

    ($stat->{num_authors}) = $dbh->selectrow_array("SELECT COUNT(*) FROM author");
    ($stat->{num_authors_with_releases}) = $dbh->selectrow_array("SELECT COUNT(DISTINCT cpanid) FROM file");
    ($stat->{num_modules}) = $dbh->selectrow_array("SELECT COUNT(*) FROM module");
    ($stat->{num_namespaces}) = $dbh->selectrow_array("SELECT COUNT(*) FROM namespace");
    (
        $stat->{num_releases},
        $stat->{num_releases_with_metajson},
        $stat->{num_releases_with_metayml},
        $stat->{num_releases_with_makefilepl},
        $stat->{num_releases_with_buildpl},
    ) = $dbh->selectrow_array("SELECT
  COUNT(*),
  SUM(CASE has_metajson WHEN 1 THEN 1 ELSE 0 END),
  SUM(CASE has_metayml WHEN 1 THEN 1 ELSE 0 END),
  SUM(CASE has_makefilepl WHEN 1 THEN 1 ELSE 0 END),
  SUM(CASE has_buildpl WHEN 1 THEN 1 ELSE 0 END)
FROM file");
    ($stat->{schema_version}) = $dbh->selectrow_array("SELECT value FROM meta WHERE name='schema_version'");

    ($stat->{num_scripts}) = $dbh->selectrow_array("SELECT COUNT(DISTINCT name) FROM script");
    ($stat->{num_content}) = $dbh->selectrow_array("SELECT COUNT(*) FROM content");
    ($stat->{num_mentions}) = $dbh->selectrow_array("SELECT COUNT(*) FROM mention");

    ($stat->{total_filesize}) = $dbh->selectrow_array("SELECT SUM(size) FROM file");

    ($stat->{num_subs}) = $dbh->selectrow_array("SELECT COUNT(*) FROM sub");

    {
        my ($time) = $dbh->selectrow_array("SELECT value FROM meta WHERE name='index_creation_time'");
        $stat->{raw_index_creation_time} = $time;
        $stat->{index_creation_time} = _fmt_time($time);
    }
    {
        my ($time) = $dbh->selectrow_array("SELECT value FROM meta WHERE name='last_index_time'");
        $stat->{raw_last_index_time} = $time;
        $stat->{last_index_time} = _fmt_time($time);
    }
    {
        my ($ver) = $dbh->selectrow_array("SELECT value FROM meta WHERE name='indexer_version'");
        $stat->{indexer_version} = $ver;
    }
    {
        my @st = stat "$state->{cpan}/modules/02packages.details.txt.gz";
        $stat->{mirror_mtime} = _fmt_time(@st ? $st[9] : undef);
        $stat->{raw_mirror_mtime} = $st[9];
    }

    [200, "OK", $stat];
}

$SPEC{'log'} = {
    v => 1.1,
    summary => 'Show database index log',
    args => {
        %common_args,
    },
};
sub log {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $sth = $dbh->prepare("SELECT * FROM log ORDER BY date");
    $sth->execute;
    my @rows;
    while (my $row = $sth->fetchrow_hashref) { push @rows, $row }

    [200, "OK", \@rows, {
        'table.fields'        => ['id', 'date', 'pid', 'lcpan_version', 'level', 'category', 'summary'],
        'table.field_formats' => [undef, 'iso8601_datetime', undef, undef, undef, undef, undef],
    }];
}

sub _complete_mod {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of module name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # allow writing Mod::SubMod as Mod/SubMod
    my $uses_slash = $word =~ s!/!::!g ? 1:0;

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT name FROM module WHERE name LIKE ? ORDER BY name");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($mod) = $sth->fetchrow_array) {
        # only complete one level deeper at a time
        if ($mod =~ /:\z/) {
            next unless $mod =~ /\A\Q$word\E:*\w+\z/i;
        } else {
            next unless $mod =~ /\A\Q$word\E\w*(::\w+)?\z/i;
        }
        push @res, $mod;
    }

    # convert back to slash if user originally typed with slash
    if ($uses_slash) { for (@res) { s!::!/!g } }

    \@res;
};

sub _complete_mod_or_dist {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of module/distro name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # allow writing Mod::SubMod as Mod/SubMod
    my $uses_slash = $word =~ s!/!::!g ? 1:0;

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth;

    my $is_dist;
    if ($word =~ /-/) {
        $is_dist++;
        $sth = $dbh->prepare(
            "SELECT DISTINCT dist_name FROM file WHERE dist_name LIKE ? ORDER BY dist_name");
    } else {
        $sth = $dbh->prepare(
            "SELECT name FROM module WHERE name LIKE ? ORDER BY name");
    }
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($e) = $sth->fetchrow_array) {
        # only complete one level deeper at a time
        if ($is_dist) {
            if ($e =~ /-\z/) {
                next unless $e =~ /\A\Q$word\E-*\w+\z/i;
            } else {
                next unless $e =~ /\A\Q$word\E\w*(-\w+)?\z/i;
            }
        } else {
            if ($e =~ /:\z/) {
                next unless $e =~ /\A\Q$word\E:*\w+\z/i;
            } else {
                next unless $e =~ /\A\Q$word\E\w*(::\w+)?\z/i;
            }
        }
        push @res, $e;
    }

    # convert back to slash if user originally typed with slash
    if ($uses_slash) { for (@res) { s!::!/!g } }

    \@res;
};

sub _complete_mod_or_dist_or_script {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of module/distro/script name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # allow writing Mod::SubMod as Mod/SubMod
    my $uses_slash = $word =~ s!/!::!g ? 1:0;

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth;

    my $is_dist;
    if ($word =~ /-/) {
        $is_dist++;
        $sth = $dbh->prepare(
            "SELECT DISTINCT dist_name FROM file WHERE dist_name LIKE ? ORDER BY dist_name");
    } else {
        $sth = $dbh->prepare(
            "SELECT name FROM module WHERE name LIKE ? ORDER BY name");
    }
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($e) = $sth->fetchrow_array) {
        # only complete one level deeper at a time
        if ($is_dist) {
            if ($e =~ /-\z/) {
                next unless $e =~ /\A\Q$word\E-*\w+\z/i;
            } else {
                next unless $e =~ /\A\Q$word\E\w*(-\w+)?\z/i;
            }
        } else {
            if ($e =~ /:\z/) {
                next unless $e =~ /\A\Q$word\E:*\w+\z/i;
            } else {
                next unless $e =~ /\A\Q$word\E\w*(::\w+)?\z/i;
            }
        }
        push @res, $e;
    }

    # also get candidates from script name
    unless ($word =~ /::/) {
        $sth = $dbh->prepare(
            "SELECT DISTINCT name FROM script WHERE name LIKE ? ORDER BY name");
        $sth->execute($word . '%');
        while (my ($e) = $sth->fetchrow_array) {
            push @res, $e;
        }
    }

    # convert back to slash if user originally typed with slash
    if ($uses_slash) { for (@res) { s!::!/!g } }

    \@res;
};

sub _complete_ns {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of namespace first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT name FROM namespace WHERE name LIKE ? ORDER BY name");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($ns) = $sth->fetchrow_array) {
        # only complete one level deeper at a time
        if ($ns =~ /:\z/) {
            next unless $ns =~ /\A\Q$word\E:*\w+\z/i;
        } else {
            next unless $ns =~ /\A\Q$word\E\w*(::\w+)?\z/i;
        }
        push @res, $ns;
    }

    \@res;
};

sub _complete_script {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of script name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT DISTINCT name FROM script WHERE name LIKE ? ORDER BY name");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($script) = $sth->fetchrow_array) {
        push @res, $script;
    }

    \@res;
};

sub _complete_dist {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of distro name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT DISTINCT dist_name FROM file WHERE dist_name LIKE ? ORDER BY dist_name");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($dist) = $sth->fetchrow_array) {
        # only complete one level deeper at a time
        if ($dist =~ /-\z/) {
            next unless $dist =~ /\A\Q$word\E-*\w+\z/i;
        } else {
            next unless $dist =~ /\A\Q$word\E\w*(-\w+)?\z/i;
        }
        push @res, $dist;
    }

    \@res;
};

sub _complete_cpanid {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of PAUSE ID first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT cpanid,fullname FROM author WHERE cpanid LIKE ? ORDER BY cpanid");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($cpanid, $fullname) = $sth->fetchrow_array) {
        push @res, {word=>$cpanid, summary=>$fullname};
    }

    \@res;
};

sub _complete_rel {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of release name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth = $dbh->prepare(
        "SELECT name FROM file WHERE name LIKE ? ORDER BY name");
    $sth->execute($word . '%');

    # XXX follow Complete::Common::OPT_CI

    my @res;
    while (my ($rel) = $sth->fetchrow_array) { #
        push @res, $rel;
    }

    \@res;
};

sub _complete_content_package_or_script {
    my %args = @_;

    my $word = $args{word} // '';

    # completing from an empty word is very slow
    return {message=>"Please enter a few characters of content/package/script name first", static=>1}
        unless length $word;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    _set_args_default($res->[2]);

    my $dbh;
    eval { $dbh = _connect_db('ro', $res->[2]{cpan}, $res->[2]{index_name}, 0) };

    # if we can't connect (probably because database is not yet setup), bail
    if ($@) {
        log_trace("[comp] can't connect to db, bailing: %s", $@);
        return undef;
    }

    my $sth;
    my @res;

    # complete from content package
    {
        $sth = $dbh->prepare(
            "SELECT DISTINCT package FROM content WHERE package LIKE ? ORDER BY package");
        $sth->execute($word . '%');

        # XXX follow Complete::Common::OPT_CI

        while (my ($pkg) = $sth->fetchrow_array) {
            # only complete one level deeper at a time
            if ($pkg =~ /:\z/) {
                next unless $pkg =~ /\A\Q$word\E:*\w+\z/i;
            } else {
                next unless $pkg =~ /\A\Q$word\E\w*(::\w+)?\z/i;
            }
            push @res, $pkg;
        }
    }

    # complete from script
    {
        last if $word =~ /::/;
        $sth = $dbh->prepare(
            "SELECT DISTINCT name FROM script WHERE name LIKE ? ORDER BY name");
        $sth->execute($word . '%');

        # XXX follow Complete::Common::OPT_CI

        while (my ($script) = $sth->fetchrow_array) {
            push @res, $script;
        }
    }

    \@res;
};


$SPEC{authors} = {
    v => 1.1,
    summary => 'List authors',
    args => {
        %common_args,
        %{( modclone {
            $_->{query}{element_completion} = sub {
                my %args = @_;
                my $r = $args{r};
                return undef unless $r;
                my $cmdline = $args{cmdline};
                my $res = $cmdline->parse_argv($r);
                return undef unless $res->[0] == 200;

                # provide completion for modules if query_type is exact-cpanid
                my $qt = $res->[2]{query_type} // '';
                return _complete_cpanid(%args) if $qt eq 'exact-cpanid';

                undef;
            };
        } \%query_multi_args )},
        query_type => {
            schema => ['str*', in=>[qw/any cpanid exact-cpanid fullname regexp-fullname email exact-email/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut --query-type exact-cpanid',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-cpanid' },
                },
                r => {
                    summary => 'Shortcut --query-type regexp-fullname',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'regexp-fullname' },
                },
                n => {
                    summary => 'Shortcut --query-type cpanid',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'cpanid' },
                },
            },
        },
        %fctime_or_mtime_args,
        %sort_args_for_authors,
        %paging_args,
    },
    result => {
        description => <<'_',

By default will return an array of CPAN ID's. If you set `detail` to true, will
return array of records.

_
    },
    examples => [
        {
            summary => 'List all authors',
            argv    => [],
            test    => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Find CPAN IDs which start with something',
            argv    => ['MICHAEL%'],
            result  => ['MICHAEL', 'MICHAELW'],
            test    => 0,
        },
    ],
};
sub authors {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $qt = $args{query_type} // 'any';
    my $sort = $args{sort} // ['id'];

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = uc($q0 =~ /%/ ? $q0 : '%'.$q0.'%');
                push @q_where, "(cpanid LIKE ? OR fullname LIKE ? OR email like ?)";
                push @bind, $q, $q, $q;
            } elsif ($qt eq 'cpanid') {
                my $q = uc($q0 =~ /%/ ? $q0 : '%'.$q0.'%');
                push @q_where, "(cpanid LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-cpanid') {
                push @q_where, "(cpanid=?)";
                push @bind, uc($q0);
            } elsif ($qt eq 'fullname') {
                my $q = uc($q0 =~ /%/ ? $q0 : '%'.$q0.'%');
                push @q_where, "(fullname LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'regexp-fullname') {
                push @q_where, "(fullname REGEXP ?)";
                push @bind, $q0;
            } elsif ($qt eq 'email') {
                my $q = uc($q0 =~ /%/ ? $q0 : '%'.$q0.'%');
                push @q_where, "(email LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-email') {
                push @q_where, "(LOWER(email)=?)";
                push @bind, lc($q0);
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }

    _set_since(\%args, $dbh);
    _add_since_where_clause(\%args, \@where, 'author');

    my @order;
    if ($args{random}) { push @order, "RANDOM()" }
    for (@$sort) { /\A(-?)(\w+)/ and push @order, $2 . ($1 ? " DESC" : "") }

    my $sql = "SELECT
  cpanid id,
  fullname name,
  email
FROM author".
        (@where ? " WHERE ".join(" AND ", @where) : "").
        (@order ? " ORDER BY ".join(", ", @order) : "").
        ($args{result_limit} ? " LIMIT ".($args{result_start} && $args{result_start} > 1 ? ($args{result_start}-1)."," : "").($args{result_limit}+0) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{id};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/id name email/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

$SPEC{modules} = {
    v => 1.1,
    summary => 'List modules/packages',
    args => {
        %common_args,
        %{( modclone {
            $_->{query}{element_completion} = sub {
                my %args = @_;
                my $r = $args{r};
                return undef unless $r;
                my $cmdline = $args{cmdline};
                my $res = $cmdline->parse_argv($r);
                return undef unless $res->[0] == 200;

                # provide completion for modules if query_type is exact-name
                my $qt = $res->[2]{query_type} // '';
                return _complete_mod(%args) if $qt eq 'exact-name';

                undef;
            };
        } \%query_multi_args )},
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name regexp-name abstract/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut --query-type exact-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-name' },
                },
                r => {
                    summary => 'Shortcut --query-type regexp-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'regexp-name' },
                },
                n => {
                    summary => 'Shortcut --query-type name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'name' },
                },
            },
        },
        %fauthor_args,
        %fdist_args,
        %flatest_args,
        %finclude_core_args,
        %finclude_noncore_args,
        %perl_version_args,
        %fctime_args,
        %fmtime_args,
        %fctime_or_mtime_args,
        namespaces => {
            'x.name.is_plural' => 1,
            summary => 'Select modules belonging to certain namespace(s)',
            schema => ['array*', of=>'perl::modname*'],
            tags => ['category:filtering'],
            element_completion => \&_complete_ns,
            cmdline_aliases => {N => {}},
        },
        %sort_args_for_mods,
        %paging_args,
    },
    result => {
        description => <<'_',

By default will return an array of package names. If you set `detail` to true,
will return array of records.

_
    },
};
sub modules {
    require Module::CoreList::More;

    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $author = uc($args{author} // '');
    my $qt = $args{query_type} // 'any';
    my $sort = $args{sort} // ['module'];
    my $include_core    = $args{include_core} // 1;
    my $include_noncore = $args{include_noncore} // 1;
    my $plver   = $args{perl_version} // "$^V";

    my @cols = (
        ['module.name', 'module'],
        ['module.version', 'version'],
        ['module.abstract', 'abstract'],
        ['file.dist_name', 'dist'],
        ['file.cpanid', 'author'],
        ['file.mtime', 'rel_mtime', 'iso8601_datetime'],
    );

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(module.name LIKE ? OR module.abstract LIKE ? OR file.dist_name LIKE ?)";
                push @bind, $q, $q, $q;
            } elsif ($qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(module.name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(module.name=?)";
                push @bind, $q0;
            } elsif ($qt eq 'regexp-name') {
                push @q_where, "(module.name REGEXP ?)";
                push @bind, $q0;
            } elsif ($qt eq 'abstract') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(module.abstract LIKE ?)";
                push @bind, $q;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if ($author) {
        push @where, "(author=?)";
        push @bind, $author;
    }
    if ($args{dist}) {
        push @where, "(dist=?)";
        push @bind, $args{dist};
    }
    if ($args{namespaces} && @{ $args{namespaces} }) {
        my @ns_where;
        for my $ns (@{ $args{namespaces} }) {
            return [400, "Invalid namespace '$ns', please use Word or Word(::Sub)+"]
                unless $ns =~ /\A\w+(::\w+)*\z/;
            push @ns_where, "(module.name='$ns' OR module.name LIKE '$ns\::%')";
        }
        push @where, "(".join(" OR ", @ns_where).")";
    }
    if ($args{latest}) {
        push @where, "file.is_latest_dist";
    } elsif (defined $args{latest}) {
        push @where, "NOT file.is_latest_dist";
    }

    _set_since(\%args, $dbh);
    _add_since_where_clause(\%args, \@where, 'module');

    my @order;
    if ($args{random}) { push @order, "RANDOM()" }
    for (@$sort) { /\A(-?)(\w+)/ and push @order, $2 . ($1 ? " DESC" : "") }

    my $sql = "SELECT ".join(", ", map {ref($_) ? "$_->[0] AS $_->[1]" : $_} @cols)."
FROM module
LEFT JOIN file ON module.file_id=file.id
".
    (@where ? " WHERE ".join(" AND ", @where) : "").
    (@order ? " ORDER BY ".join(", ", @order) : "").
    ($args{result_limit} ? " LIMIT ".($args{result_start} && $args{result_start} > 1 ? ($args{result_start}-1)."," : "").($args{result_limit}+0) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        $row->{is_core} = $row->{module} eq 'perl' ||
            Module::CoreList::More->is_still_core(
                $row->{module}, undef,
                version->parse($plver)->numify);
        next if !$include_core    &&  $row->{is_core};
        next if !$include_noncore && !$row->{is_core};
        push @res, $detail ? $row : $row->{module};
    }
    my $resmeta = {};
    if ($detail) {
        $resmeta->{'table.fields'} = [
            (map {ref($_) ? $_->[1] : $_}    @cols),
            ("is_core")];
        $resmeta->{'table.field_formats'} = [
            (map {ref($_) ? $_->[2] : undef} @cols),
            (undef)];
    }
    [200, "OK", \@res, $resmeta];
}

$SPEC{packages} = $SPEC{modules};
sub packages { goto &modules }

$SPEC{dists} = {
    v => 1.1,
    summary => 'List distributions',
    args => {
        %common_args,
        %{( modclone {
            $_->{query}{element_completion} = sub {
                my %args = @_;
                my $r = $args{r};
                return undef unless $r;
                my $cmdline = $args{cmdline};
                my $res = $cmdline->parse_argv($r);
                return undef unless $res->[0] == 200;

                # provide completion for dists if query_type is exact-name
                my $qt = $res->[2]{query_type} // '';
                return _complete_dist(%args) if $qt eq 'exact-name';

                undef;
            };
        } \%query_multi_args )},
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name regexp-name abstract/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut for --query-type exact-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-name' },
                },
                r => {
                    summary => 'Shortcut for --query-type regexp-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'regexp-name' },
                },
                n => {
                    summary => 'Shortcut for --query-type name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'name' },
                },
            },
        },
        %fauthor_args,
        %flatest_args,
        %fctime_args,
        %fmtime_args,
        %fctime_or_mtime_args,
        has_makefilepl => {
            schema => 'bool',
            tags => ['category:filtering'],
        },
        has_buildpl => {
            schema => 'bool',
            tags => ['category:filtering'],
        },
        has_metayml => {
            schema => 'bool',
            tags => ['category:filtering'],
        },
        has_metajson => {
            schema => 'bool',
            tags => ['category:filtering'],
        },
        has_multiple_rels => {
            'summary.alt.bool.yes' => 'Only list dists having multiple releases indexed',
            'summary.alt.bool.not' => 'Only list dists having a single release indexed',
            schema => 'bool',
            tags => ['category:filtering'],
        },
        rel_mtime_newer_than => {
            schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural']],
            tags => ['category:filtering'],
        },
        %sort_args_for_dists,
        %paging_args,
    },
    result => {
        description => <<'_',

By default will return an array of distribution names. If you set `detail` to
true, will return array of records.

_
    },
    args_rels => {
        choose_one => [qw/latest has_multiple_rels/],
    },
    examples => [
        {
            summary => 'List all distributions',
            argv    => ['--cpan', '/cpan'],
            test    => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all distributions (latest version only)',
            argv    => ['--cpan', '/cpan', '--latest'],
            test    => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Grep by distribution name, return detailed record',
            argv    => ['--cpan', '/cpan', 'data-table'],
            test    => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary   => 'Filter by author, return JSON',
            src       => '[[prog]] --cpan /cpan --author perlancar --json',
            src_plang => 'bash',
            test      => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub dists {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $author = uc($args{author} // '');
    my $qt = $args{query_type} // 'any';
    my $sort = $args{sort} // ['dist'];

    my @cols = (
        "f.dist_name dist",
        "f.cpanid author",
        "f.dist_version version",
        "f.name release",
        "f.size rel_size",
        "f.mtime rel_mtime",
        "f.dist_abstract abstract",
    );

    my %delcols;
    my @bind;
    my @where;
    #my @having;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(f.dist_name LIKE ? OR f.dist_abstract LIKE ?)";
                push @bind, $q, $q;
            } elsif ($qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(f.dist_name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(f.dist_name=?)";
                push @bind, $q0;
            } elsif ($qt eq 'regexp-name') {
                push @q_where, "(f.dist_name REGEXP ?)";
                push @bind, $q0;
            } elsif ($qt eq 'abstract') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(f.dist_abstract LIKE ?)";
                push @bind, $q;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if ($author) {
        push @where, "(author=?)";
        push @bind, $author;
    }
    if ($args{latest}) {
        push @where, "is_latest_dist";
    } elsif (defined $args{latest}) {
        push @where, "NOT(is_latest_dist)";
    }
    if (defined $args{has_makefilepl}) {
        if ($args{has_makefilepl}) {
            push @where, "has_makefilepl<>0";
        } else {
            push @where, "has_makefilepl=0";
        }
    }
    if (defined $args{has_buildpl}) {
        if ($args{has_buildpl}) {
            push @where, "has_buildpl<>0";
        } else {
            push @where, "has_buildpl=0";
        }
    }
    if (defined $args{has_metayml}) {
        if ($args{has_metayml}) {
            push @where, "has_metayml<>0";
        } else {
            push @where, "has_metayml=0";
        }
    }
    if (defined $args{has_metajson}) {
        if ($args{has_metajson}) {
            push @where, "has_metajson<>0";
        } else {
            push @where, "has_metajson=0";
        }
    }
    if (defined $args{has_multiple_rels}) {
        push @cols, "(SELECT COUNT(*) FROM file f2 WHERE f2.dist_name=f.dist_name) rel_count";
        if ($args{has_multiple_rels}) {
            push @where, "rel_count > 1";
        } else {
            push @where, "rel_count = 1";
        }
        $delcols{rel_count}++;
    }
    if (defined $args{rel_mtime_newer_than}) {
        push @where, "f.mtime > ?";
        push @bind, $args{rel_mtime_newer_than};
    }

    _set_since(\%args, $dbh);
    _add_since_where_clause(\%args, \@where, 'f');

    my @order;
    if ($args{random}) { push @order, "RANDOM()" }
    for (@$sort) { /\A(-?)(\w+)/ and push @order, $2 . ($1 ? " DESC" : "") }

    my $sql = "SELECT ".join(", ", @cols)."
FROM file f
".
        (@where ? " WHERE ".join(" AND ", @where) : "").
        (@order ? " ORDER BY ".join(", ", @order) : "").
        ($args{result_limit} ? " LIMIT ".($args{result_start} && $args{result_start} > 1 ? ($args{result_start}-1)."," : "").($args{result_limit}+0) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        delete $row->{$_} for keys %delcols;
        push @res, $detail ? $row : $row->{dist};
    }
    my $resmeta = {};
    if ($detail) {
        $resmeta->{'table.fields'}        = [qw/dist author version release rel_size rel_mtime abstract/];
        $resmeta->{'table.field_formats'} = [undef,  undef, undef,  undef,  undef, 'iso8601_datetime',  undef];
    }
    [200, "OK", \@res, $resmeta];
}

$SPEC{'releases'} = {
    v => 1.1,
    summary => 'List releases/tarballs',
    args => {
        %common_args,
        %fauthor_args,
        %{( modclone {
            $_->{query}{element_completion} = sub {
                my %args = @_;
                my $r = $args{r};
                return undef unless $r;
                my $cmdline = $args{cmdline};
                my $res = $cmdline->parse_argv($r);
                return undef unless $res->[0] == 200;

                # provide completion for releases if query_type is exact-name
                my $qt = $res->[2]{query_type} // '';
                return _complete_rel(%args) if $qt eq 'exact-name';

                undef;
            };
        } \%query_multi_args )},
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name regexp-name/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut for --query-type exact-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-name' },
                },
                r => {
                    summary => 'Shortcut for --query-type regexp-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'regexp-name' },
                },
                n => {
                    summary => 'Shortcut for --query-type name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'name' },
                },
            },
        },
        has_metajson   => {schema=>'bool'},
        has_metayml    => {schema=>'bool'},
        has_makefilepl => {schema=>'bool'},
        has_buildpl    => {schema=>'bool'},
        %flatest_args,
        %fctime_args,
        %fmtime_args,
        %fctime_or_mtime_args,
        %full_path_args,
        %no_path_args,
        %sort_args_for_rels,
        %paging_args,
    },
    args_rels => {
        choose_one => ['full_path', 'no_path'],
    },
    description => <<'_',

The status field is the processing status of the file/release by lcpan. `ok`
means file has been extracted and the meta files parsed, `nofile` means file is
not found in mirror (possibly because the mirroring process excludes the file
e.g. due to file size too large), `nometa` means file does not contain
META.{yml,json}, `unsupported` means file archive format is not supported (e.g.
rar), `err` means some other error in processing file.

_
};
sub releases {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $author = uc($args{author} // '');
    my $qt = $args{query_type} // 'any';
    my $sort = $args{sort} // ['name'];

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any' || $qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(f1.name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(f1.name=?)";
                push @bind, $q0;
            } elsif ($qt eq 'regexp-name') {
                push @q_where, "(f1.name REGEXP ?)";
                push @bind, $q0;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if ($author) {
        push @where, "(f1.cpanid=?)";
        push @bind, $author;
    }
    if (defined $args{has_metajson}) {
        push @where, $args{has_metajson} ? "(has_metajson=1)" : "(has_metajson=0)";
    }
    if (defined $args{has_metayml}) {
        push @where, $args{has_metayml} ? "(has_metayml=1)" : "(has_metayml=0)";
    }
    if (defined $args{has_makefilepl}) {
        push @where, $args{has_makefilepl} ? "(has_makefilepl=1)" : "(has_makefilepl=0)";
    }
    if (defined $args{has_buildpl}) {
        push @where, $args{has_buildpl} ? "(has_buildpl=1)" : "(has_buildpl=0)";
    }
    if ($args{latest}) {
        push @where, "d.is_latest";
    } elsif (defined $args{latest}) {
        push @where, "NOT(d.is_latest)";
    }

    _set_since(\%args, $dbh);
    _add_since_where_clause(\%args, \@where, 'f1');

    my @order;
    if ($args{random}) { push @order, "RANDOM()" }
    for (@$sort) { /\A(-?)(\w+)/ and push @order, $2 . ($1 ? " DESC" : "") }

    my $sql = "SELECT
  f1.name name,
  f1.cpanid author,
  f1.size size,
  f1.mtime mtime,
  has_metajson,
  has_metayml,
  has_makefilepl,
  has_buildpl,
  file_status,
  file_error,
  meta_status,
  meta_error,
  pod_status
FROM file f1
".
    (@where ? " WHERE ".join(" AND ", @where) : "").
    (@order ? " ORDER BY ".join(", ", @order) : "").
    ($args{result_limit} ? " LIMIT ".($args{result_start} && $args{result_start} > 1 ? ($args{result_start}-1)."," : "").($args{result_limit}+0) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        if ($args{no_path}) {
        } elsif ($args{full_path}) {
            $row->{name} = _fullpath($row->{name}, $state->{cpan}, $row->{author});
        } else {
            $row->{name} = _relpath($row->{name}, $row->{author});
        }
        for (qw/file_error meta_error/) {
            $row->{$_} =~ s/\R+/ /g if defined $row->{$_};
        }
        push @res, $detail ? $row : $row->{name};
    }
    my $resmeta = {};
    if ($detail) {
        $resmeta->{'table.fields'}        = [qw/name author size mtime                 has_metayml has_metajson has_makefilepl has_buildpl file_status file_error meta_status meta_error pod_status/];
        $resmeta->{'table.field_formats'} = [undef,  undef, undef, 'iso8601_datetime', undef,      undef,       undef,         undef,      undef,      undef,     undef,      undef,     undef];
    }
    [200, "OK", \@res, $resmeta];
}

sub _get_prereqs {
    require Module::CoreList::More;
    require Version::Util;

    my ($file_ids0, $dbh, $memory_by_mod_name, $memory_by_file_id,
        $level, $max_level, $filters, $plver, $flatten, $dont_uniquify, $phase, $rel) = @_;

    my $file_ids = [];

    for my $file_id (@$file_ids0) {
        unless ($memory_by_file_id->{$file_id} && $dont_uniquify) {
            push @$file_ids, $file_id;
            $memory_by_file_id->{$file_id} = 1;
        }
    }

    log_trace("Finding dependencies for file ID(s) %s (level=%i) ...", $file_ids, $level);
    return [200, "OK", []] unless @$file_ids;

    my @where = ("dp.file_id IN (".join(",", @$file_ids).")");
    my @bind  = ();

    if ($filters->{authors}) {
        push @where, '('.join(' OR ', ('author=?') x @{$filters->{authors}}).')';
        push @bind , @{$filters->{authors}};
    }
    if ($filters->{authors_arent}) {
        for (@{ $filters->{authors_arent} }) {
            push @where, 'author <> ?';
            push @bind , $_;
        }
    }

    _add_since_where_clause($filters, \@where, 'dp');

    # fetch the dependency information
    my $sth = $dbh->prepare("SELECT
  (SELECT dist_name FROM file WHERE id=dp.file_id) AS dist,
  CASE
     WHEN module_name IS NOT NULL THEN module_name
     ELSE (SELECT name   FROM module WHERE id=dp.module_id)
  END AS module,
  (SELECT cpanid FROM module WHERE id=dp.module_id) AS author,
  (SELECT dist_name FROM file WHERE id=(SELECT file_id FROM module WHERE id=dp.module_id)) AS module_dist,
  (SELECT file_id FROM module WHERE id=dp.module_id) AS module_file_id,
  phase,
  rel,
  version
FROM dep dp
WHERE ".join(" AND ", @where)."
ORDER BY module".($level > 1 ? " DESC" : ""));
    $sth->execute(@bind);
    my @res;
  MOD:
    while (my $row = $sth->fetchrow_hashref) {
        # BUG? we can encounter case where module is undef
        next unless defined $row->{module};

        next unless $phase eq 'ALL' || $row->{phase} eq $phase;
        next unless $rel   eq 'ALL' || $row->{rel}   eq $rel;

        # some dists, e.g. XML-SimpleObject-LibXML (0.60) have garbled prereqs,
        # e.g. they write PREREQ_PM => { mod1, mod2 } when it should've been
        # PREREQ_PM => {mod1 => 0, mod2=>1.23}. we ignore such deps.
        unless (eval { version->parse($row->{version}); 1 }) {
            log_info("Invalid version $row->{version} (in dependency to $row->{module}), skipped");
            next;
        }

        if (!$dont_uniquify && (
            (exists $memory_by_mod_name->{$row->{module}}) ||
                ($level > 1 && defined $row->{module_dist} && exists $memory_by_file_id->{$row->{module_file_id}})
            )
        ) {
            if ($flatten) {
                $memory_by_mod_name->{$row->{module}} = $row->{version}
                    if version->parse($row->{version}) > version->parse($memory_by_mod_name->{$row->{module}});
            } else {
                next MOD;
            }
        }

        next if !$filters->{include_indexed}   && ( defined $row->{author} || $row->{module} eq 'perl');
        next if !$filters->{include_unindexed} && (!defined $row->{author} && $row->{module} ne 'perl');

        $row->{is_core} = $row->{module} eq 'perl' ||
            Module::CoreList::More->is_still_core($row->{module}, undef, version->parse($plver)->numify);
        next if !$filters->{include_core}    &&  $row->{is_core};
        next if !$filters->{include_noncore} && !$row->{is_core};
        if (defined $memory_by_mod_name->{$row->{module}}) {
            if (Version::Util::version_gt($row->{version}, $memory_by_mod_name->{$row->{module}})) {
                $memory_by_mod_name->{$row->{module}} = $row->{version};
            }
            next unless $dont_uniquify;
        }
        delete $row->{phase} unless $phase eq 'ALL';
        delete $row->{rel}   unless $rel   eq 'ALL';
        $memory_by_mod_name->{$row->{module}} = $row->{version};
        $row->{level} = $level;
        push @res, $row;
    }

    if (@res && ($max_level==-1 || $level < $max_level)) {
        my $subres = _get_prereqs([grep {defined} map { $_->{module_file_id} } @res], $dbh,
                                  $memory_by_mod_name,
                                  $memory_by_file_id,
                                  $level+1, $max_level, $filters, $plver, $flatten, $dont_uniquify, $phase, $rel);
        return $subres if $subres->[0] != 200;
        if ($flatten) {
            my %deps; # key = module name
            for my $s (@{$subres->[2]}, @res) {
                $s->{version} = $memory_by_mod_name->{$s->{module}};
                $deps{ $s->{module} } = $s;
            }
            @res = map {$deps{$_}} sort keys %deps;
        } else {
            # insert to res in appropriate places
          SUBRES_TO_INSERT:
            for my $s (@{$subres->[2]}) {
                for my $i (0..@res-1) {
                    my $r = $res[$i];
                    if (defined($s->{dist}) && defined($r->{module_dist}) &&
                            $s->{dist} eq $r->{module_dist}) {
                        splice @res, $i+1, 0, $s;
                        next SUBRES_TO_INSERT;
                    }
                }
                return [500, "Bug? Can't insert subres (module=$s->{module}, module_dist=$s->{module_dist})"];
            }
        }
    }

    [200, "OK", \@res];
}

sub _get_revdeps {
    my ($mods, $dbh, $memory_by_dist_name, $memory_by_mod_name,
        $level, $max_level, $filters, $flatten, $dont_uniquify, $phase, $rel) = @_;

    log_trace("Finding reverse dependencies for module(s) %s ...", $mods);

    # first, check that all modules are listed
    my @indexed_mod_names;
    my @unindexed_mod_names;
    for my $mod0 (@$mods) {
        my ($mod);
        if (ref($mod0) eq 'HASH') {
            $mod = $mod0->{mod};
        } else {
            ($mod) = $dbh->selectrow_array("SELECT name FROM module WHERE name=?", {}, $mod0)
                or do {
                    warn "lcpan: Module is unindexed: $mod0\n";
                    push @unindexed_mod_names, $mod0;
                    next;
                };
        }
        unless ($memory_by_mod_name->{$mod} && $dont_uniquify) {
            push @indexed_mod_names, $mod;
            $memory_by_mod_name->{$mod} = $mod;
        }
    }
    if (@indexed_mod_names) {
        if (@unindexed_mod_names) {
            warn "lcpan: There are unindexed as well as indexed module names, I'm ignoring unindexed module names for now (".join(", ", @unindexed_mod_names)."), this limitation will be rectified in the future.\n";
            @unindexed_mod_names = ();
        }
    } elsif (@unindexed_mod_names) {
        warn "lcpan: Can't do multilevel rdeps for unindexed modules (".join(", ", @unindexed_mod_names)."), ignoring multilevel request\n"
            if $max_level > 1;
        return _get_revdeps_unindexed(\@unindexed_mod_names, $dbh, $filters, $phase, $rel);
    } else {
        return [200, "OK", []];
    }

    my @where = ('module IN ('.join(",", map {$dbh->quote($_)} @indexed_mod_names).')');
    my @bind  = ();

    push @where, "dist IS NOT NULL";

    if ($filters->{authors}) {
        push @where, '('.join(' OR ', ('author=?') x @{$filters->{authors}}).')';
        push @bind , @{$filters->{authors}};
    }
    if ($filters->{authors_arent}) {
        for (@{ $filters->{authors_arent} }) {
            push @where, 'author <> ?';
            push @bind , $_;
        }
    }

    _add_since_where_clause($filters, \@where, 'dp');

    # get all dists that depend on that module
    my $sth = $dbh->prepare("SELECT
  -- dp.file_id AS _file_id, -- unused, for debugging only
  -- dp.module_id AS _mod_id,  -- unused, for debugging only

  (SELECT dist_name    FROM file WHERE id=dp.file_id)            AS dist,
  (SELECT dist_name    FROM file WHERE id=(SELECT file_id FROM module WHERE id=dp.module_id)) module_dist,
  (SELECT name         FROM module WHERE dp.module_id=module.id) AS module,
  (SELECT cpanid       FROM file WHERE dp.file_id=file.id)       AS author,
  (SELECT dist_version FROM file WHERE dp.file_id=file.id)       AS dist_version,
  phase,
  rel,
  version req_version
FROM dep dp
WHERE ".join(" AND ", @where)."
ORDER BY dist".($level > 1 ? " DESC" : ""));
    $sth->execute(@bind);
    my @res;
    while (my $row = $sth->fetchrow_hashref) {
        next unless $phase eq 'ALL' || $row->{phase} eq $phase;
        next unless $rel   eq 'ALL' || $row->{rel}   eq $rel;
        next if exists($memory_by_dist_name->{$row->{dist}}) && !$dont_uniquify;
        $memory_by_dist_name->{$row->{dist}} = $row->{dist_version};
        delete $row->{phase} unless $phase eq 'ALL';
        delete $row->{rel} unless $rel eq 'ALL';
        $row->{level} = $level;
        push @res, $row;
    }

    if (@res && ($max_level==-1 || $level < $max_level)) {
        # find the module of those depending dists
        my $sth = $dbh->prepare("
SELECT m.name name
FROM file f
JOIN module m
ON f.id=m.file_id
WHERE f.dist_name IN (".join(", ", map {$dbh->quote($_->{dist})} @res).")");
        $sth->execute();
        my @mods;
        while (my $row = $sth->fetchrow_hashref) {
            push @mods, {mod=>$row->{name}};
        }
        my $subres = _get_revdeps(\@mods, $dbh,
                                  $memory_by_dist_name, $memory_by_mod_name,
                                  $level+1, $max_level, $filters, $flatten, $dont_uniquify, $phase, $rel);
        return $subres if $subres->[0] != 200;
        # insert to res in appropriate places
      SUBRES_TO_INSERT:
        for my $s (@{$subres->[2]}) {
            for my $i (reverse 0..@res-1) {
                my $r = $res[$i];
                if ($s->{module_dist} eq $r->{dist}) {
                    splice @res, $i+1, 0, $s;
                    next SUBRES_TO_INSERT;
                }
            }
            return [500, "Bug? Can't insert subres (dist=$s->{dist}, module_dist=$s->{module_dist})"];
        }
    }

    [200, "OK", \@res];
}

sub _get_revdeps_unindexed {
    my ($mods, $dbh, $filters, $phase, $rel) = @_;

    my @where = ('module_name IN ('.join(",", map {$dbh->quote($_)} @$mods).')');
    my @bind  = ();

    push @where, "dist IS NOT NULL";

    if ($filters->{authors}) {
        push @where, '('.join(' OR ', ('author=?') x @{$filters->{authors}}).')';
        push @bind , @{$filters->{authors}};
    }
    if ($filters->{authors_arent}) {
        for (@{ $filters->{authors_arent} }) {
            push @where, 'author <> ?';
            push @bind , $_;
        }
    }

    _add_since_where_clause($filters, \@where, 'dp');

    # get all dists that depend on that module
    my $sth = $dbh->prepare("SELECT
  -- dp.file_id AS _file_id, -- unused, for debugging only
  -- dp.module_id AS _mod_id,  -- unused, for debugging only

  (SELECT dist_name    FROM file WHERE id=dp.file_id)            AS dist,
  NULL                                                           AS module_dist,
  module_name                                                    AS module,
  (SELECT cpanid       FROM file WHERE dp.file_id=file.id)       AS author,
  (SELECT dist_version FROM file WHERE dp.file_id=file.id)       AS dist_version,
  phase,
  rel,
  version req_version
FROM dep dp
WHERE ".join(" AND ", @where)."
ORDER BY dist");
    $sth->execute(@bind);
    my @res;
    while (my $row = $sth->fetchrow_hashref) {
        next unless $phase eq 'ALL' || $row->{phase} eq $phase;
        next unless $rel   eq 'ALL' || $row->{rel}   eq $rel;
        delete $row->{phase} unless $phase eq 'ALL';
        delete $row->{rel} unless $rel eq 'ALL';
        $row->{level} = 1;
        push @res, $row;
    }
    [200, "OK", \@res];
}

our %deps_phase_args = (
    phase => {
        schema => ['str*' => {
            match => qr/\A(develop|configure|build|runtime|test|ALL|x_\w+)\z/,
        }],
        default => 'runtime',
        cmdline_aliases => {
            all => {
                summary => 'Equivalent to --phase ALL --rel ALL',
                is_flag => 1,
                code => sub { $_[0]{phase} = 'ALL'; $_[0]{rel} = 'ALL' },
            },
        },
        completion => [qw/develop configure build runtime test ALL/],
        tags => ['category:filtering'],
    },
);

our %rdeps_phase_args = %{clone(\%deps_phase_args)};
$rdeps_phase_args{phase}{default} = 'ALL';

our %deps_rel_args = (
    rel => {
        schema => ['str*' => {
            match => qr/\A(requires|recommends|suggests|conflicts|ALL|x_\w+)\z/,
        }],
        default => 'requires',
        completion => [qw/requires recommends suggests conflicts ALL/],
        tags => ['category:filtering'],
    },
);

our %rdeps_rel_args = %{clone(\%deps_rel_args)};
$rdeps_rel_args{rel}{default} = 'ALL';

our %rdeps_level_args = (
    level => {
        summary => 'Recurse for a number of levels (-1 means unlimited)',
        schema  => ['int*', min=>1, max=>10],
        default => 1,
        cmdline_aliases => {
            l => {},
            R => {
                summary => 'Recurse (alias for `--level 10`)',
                is_flag => 1,
                code => sub { $_[0]{level} = 10 },
            },
        },
    },
);

our %deps_args = (
    %deps_phase_args,
    %deps_rel_args,
    level => {
        summary => 'Recurse for a number of levels (-1 means unlimited)',
        schema  => 'int*',
        default => 1,
        cmdline_aliases => {
            l => {},
            R => {
                summary => 'Recurse (alias for `--level -1`)',
                is_flag => 1,
                code => sub { $_[0]{level} = -1 },
            },
        },
    },
    flatten => {
        summary => 'Instead of showing tree-like information, flatten it',
        schema => 'bool',
        description => <<'_',

When recursing, the default is to show the final result in a tree-like table,
i.e. indented according to levels, e.g.:

    % lcpan deps -R MyModule
    | module            | author  | version |
    |-------------------|---------|---------|
    | Foo               | AUTHOR1 | 0.01    |
    |   Bar             | AUTHOR2 | 0.23    |
    |   Baz             | AUTHOR3 | 1.15    |
    | Qux               | AUTHOR2 | 0       |

To be brief, if `Qux` happens to also depends on `Bar`, it will not be shown in
the result. Thus we don't know the actual `Bar` version that is needed by the
dependency tree of `MyModule`. For example, if `Qux` happens to depends on `Bar`
version 0.45 then `MyModule` indirectly requires `Bar` 0.45.

To list all the direct and indirect dependencies on a single flat list, with
versions already resolved to the largest version required, use the `flatten`
option:

    % lcpan deps -R --flatten MyModule
    | module            | author  | version |
    |-------------------|---------|---------|
    | Foo               | AUTHOR1 | 0.01    |
    | Bar               | AUTHOR2 | 0.45    |
    | Baz               | AUTHOR3 | 1.15    |
    | Qux               | AUTHOR2 | 0       |

Note that `Bar`'s required version is already 0.45 in the above example.

_
    },
    dont_uniquify => {
        summary => 'Allow showing multiple modules for different dists',
        schema => 'bool*',
    },
    %finclude_core_args,
    %finclude_noncore_args,
    %perl_version_args,
    with_xs_or_pp => {
        summary => 'Check each dependency as XS/PP',
        schema  => ['bool*', is=>1],
        tags => ['category:filtering'],
    },
    %finclude_indexed_args,
    %finclude_unindexed_args,
    %fctime_args,
    %fmtime_args,
    %fctime_or_mtime_args,
);

our $deps_args_rels = {
    dep_any => [flatten => ['level']],
};

$SPEC{'deps'} = {
    v => 1.1,
    summary => 'List dependencies of distributions',
    description => <<'_',

By default only runtime requires are displayed. To see prereqs for other phases
(e.g. configure, or build, or ALL) or for other relationships (e.g. recommends,
or ALL), use the `--phase` and `--rel` options.

Note that dependencies information are taken from `META.json` or `META.yml`
files. Not all releases (especially older ones) contain them. <prog:lcpan> (like
MetaCPAN) does not extract information from `Makefile.PL` or `Build.PL` because
that requires running (untrusted) code.

Also, some releases specify dynamic config, so there might actually be more
dependencies.

_
    args => {
        %common_args,
        %argspec0opt_dists_with_optional_vers,
        %argspecopt_mods,
        %deps_args,
    },
    args_rels => {
        req_one => ['modules', 'dists'],
        dep_any => [flatten => ['level']],
    },
    examples => [
        {
            summary => 'List what modules Module-List requires',
            argv => ['Module-List'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List modules Module-List requires (module name will be converted to distro name)',
            argv => ['Module::List'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List what distribution that contains Sah::Schema::filename requires',
            description => <<'_',

Sah::Schema::filename is included in Sah-Schemas-Path distribution, so this
command is equivalent to "lcpan deps Sah-Schemas-Path". You can't do "lcpan deps
Sah::Schema::filename" because `lcpan` will assume that you ask "lcpan deps
Sah-Schema-filename" and there is no Sah-Schema-filename distribution.

_
            argv => ['--module', 'Sah::Schema::filename'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List non-core modules Module-List requires',
            argv => ['Module-List', '--exclude-core'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List dependencies of a specific distribution release',
            argv => ['Module-List@0.004'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub deps {
    require Module::XSOrPP;
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $file_ids =
        $args{dists} && !$args{modules} ? _dists_with_optional_vers2file_ids($dbh, $args{dists}) :
        $args{modules} && !$args{dists} ? _modules2file_ids($dbh, $args{modules}) :
        (return [400, "Please specify dists OR modules"]);
    my $phase    = $args{phase} // 'runtime';
    my $rel      = $args{rel} // 'requires';
    my $plver    = $args{perl_version} // "$^V";
    my $level    = $args{level} // 1;
    my $include_core    = $args{include_core} // 1;
    my $include_noncore = $args{include_noncore} // 1;
    my $with_xs_or_pp = $args{with_xs_or_pp};
    my $include_indexed = $args{include_indexed} // 1;
    my $include_unindexed = $args{include_unindexed} // 1;

    _set_since(\%args, $dbh);
    my $filters = {
        include_core => $include_core,
        include_noncore => $include_noncore,
        include_indexed => $include_indexed,
        include_unindexed => $include_unindexed,
        authors => $args{authors},
        authors_arent => $args{authors_arent},
        added_since => $args{added_since},
        updated_since => $args{updated_since},
        added_or_updated_since => $args{added_or_updated_since},
    };

    my $res = _get_prereqs($file_ids, $dbh, {}, {},
                           1, $level, $filters, $plver, $args{flatten}, $args{dont_uniquify}, $phase, $rel);

    return $res unless $res->[0] == 200;
    my @cols;
    push @cols, (qw/module/);
    push @cols, "dist" if @$file_ids > 1;
    push @cols, (qw/author version/);
    push @cols, "is_core";
    push @cols, "xs_or_pp" if $with_xs_or_pp;
    for (@{$res->[2]}) {
        if ($with_xs_or_pp) {
            $_->{xs_or_pp} = Module::XSOrPP::xs_or_pp($_->{module});
        }
        $_->{module} = ("  " x ($_->{level}-1)) . $_->{module}
            unless $args{flatten};
        delete $_->{dist} unless @$file_ids > 1 || $_->{level} > 1;
        delete $_->{module_file_id};
        delete $_->{level};
    }

    my $resmeta = {};
    $resmeta->{'table.fields'} = \@cols;
    $res->[3] = $resmeta;
    $res;
}

my %rdeps_args = (
    %common_args,
    %argspec0opt_modules,
    %argspecopt_dists,
    %rdeps_rel_args,
    %rdeps_phase_args,
    %rdeps_level_args,
    flatten => {
        summary => 'Instead of showing tree-like information, flatten it',
        schema => 'bool',
        description => <<'_',

See deps' *flatten* argument for more details.

_
    },
    dont_uniquify => {
        summary => 'Allow showing multiple modules for different dists',
        schema => 'true*',
    },
    authors => {
        'x.name.is_plural' => 1,
        summary => 'Filter certain author',
        schema => ['array*', of=>'str*'],
        description => <<'_',

This can be used to select certain author(s).

_
        completion => \&_complete_cpanid,
        tags => ['category:filtering'],
    },
    authors_arent => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'author_isnt',
        summary => 'Filter out certain author',
        schema => ['array*', of=>'str*'],
        description => <<'_',

This can be used to filter out certain author(s). For example if you want to
know whether a module is being used by another CPAN author instead of just
herself.

_
        completion => \&_complete_cpanid,
        tags => ['category:filtering'],
    },
    %fctime_args,
    %fmtime_args,
    %fctime_or_mtime_args,
);

our $rdeps_args_rels = {
    dep_any => [flatten => ['level']],
};

$SPEC{'rdeps'} = {
    v => 1.1,
    summary => 'List reverse dependencies',
    args => {
        %rdeps_args,
    },
    examples => [
        {
            summary => 'List what distributions depend on Sah::Schema::filename',
            argv => ['Sah::Schema::filename'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List what distributions depend on one of the modules in Sah-Schemas-Path',
            argv => ['--dist', 'Sah-Schemas-Path'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    args_rels => {
        req_one => ['modules', 'dists'],
        dep_any => [flatten => ['level']],
    },
};
sub rdeps {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $mods    =
        $args{modules} && !$args{dists} ? $args{modules} :
        $args{dists} && !$args{modules} ? _dists2theirmods($dbh, $args{dists}) :
        (return [400, "Please specify modules OR dists"]);
    my $level   = $args{level} // 1;
    my $authors =  $args{authors} ? [map {uc} @{$args{authors}}] : undef;
    my $authors_arent = $args{authors_arent} ? [map {uc} @{$args{authors_arent}}] : undef;

    _set_since(\%args, $dbh);
    my $filters = {
        authors => $authors,
        authors_arent => $authors_arent,
        added_since => $args{added_since},
        updated_since => $args{updated_since},
        added_or_updated_since => $args{added_or_updated_since},
    };

    my $res = _get_revdeps($mods, $dbh, {}, {}, 1, $level, $filters, $args{flatten}, $args{dont_uniquify}, $args{phase}, $args{rel});

    return $res unless $res->[0] == 200;
    for (@{$res->[2]}) {
        $_->{dist} = ("  " x ($_->{level}-1)) . $_->{dist}
            unless $args{flatten};
        delete $_->{module} unless @$mods > 1 || $_->{level} > 1;
        delete $_->{level};
    }

    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/dist author dist_version req_version/];
    $res->[3] = $resmeta;
    $res;
}

$SPEC{namespaces} = {
    v => 1.1,
    summary => 'List namespaces',
    args => {
        %common_args,
        %query_multi_args,
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name regexp-name/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut --query-type exact-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-name' },
                },
                r => {
                    summary => 'Shortcut --query-type regexp-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'regexp-name' },
                },
                n => {
                    summary => 'Shortcut --query-type name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'name' },
                },
            },
        },
        from_level => {
            schema => ['int*', min=>0],
            tags => ['category:filtering'],
        },
        to_level => {
            schema => ['int*', min=>0],
            tags => ['category:filtering'],
        },
        level => {
            schema => ['int*', min=>0],
            tags => ['category:filtering'],
        },
        sort => {
            schema => ['str*', in=>[qw/name -name num_modules -num_modules/]],
            default => 'name',
            tags => ['category:sorting'],
        },
        %fctime_args,
        %fmtime_args,
        %fctime_or_mtime_args,
    },
};
sub namespaces {
    my %args = @_;

    my $state = _init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $qt = $args{query_type} // 'any';

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any' || $qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(name=?)";
                push @bind, $q0;
            } elsif ($qt eq 'regexp-name') {
                push @q_where, "(name REGEXP ?)";
                push @bind, $q0;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if (defined $args{from_level}) {
        push @where, "(num_sep >= ?)";
        push @bind, $args{from_level}-1;
    }
    if (defined $args{to_level}) {
        push @where, "(num_sep <= ?)";
        push @bind, $args{to_level}-1;
    }
    if (defined $args{level}) {
        push @where, "(num_sep = ?)";
        push @bind, $args{level}-1;
    }

    _set_since(\%args, $dbh);
    _add_since_where_clause(\%args, \@where, "namespace");

    my $order = 'name';
    if ($args{sort} eq 'num_modules') {
        $order = "num_modules";
    } elsif ($args{sort} eq '-num_modules') {
        $order = "num_modules DESC";
    }
    my $sql = "SELECT
  name,
  num_modules
FROM namespace".
    (@where ? " WHERE ".join(" AND ", @where) : "")."
ORDER BY $order";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{name};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name num_modules/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Manage your local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan - Manage your local CPAN mirror

=head1 VERSION

This document describes version 1.068 of App::lcpan (from Perl distribution App-lcpan), released on 2021-06-05.

=head1 SYNOPSIS

See L<lcpan> script.

=head1 FUNCTIONS


=head2 authors

Usage:

 authors(%args) -> [$status_code, $reason, $payload, \%result_meta]

List authors.

Examples:

=over

=item * List all authors:

 authors();

=item * Find CPAN IDs which start with something:

 authors(query => ["MICHAEL%"]); # -> ["MICHAEL", "MICHAELW", undef, {}]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["id"])

Sort the result.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)


By default will return an array of CPAN ID's. If you set C<detail> to true, will
return array of records.



=head2 deps

Usage:

 deps(%args) -> [$status_code, $reason, $payload, \%result_meta]

List dependencies of distributions.

Examples:

=over

=item * List what modules Module-List requires:

 deps(dists => ["Module-List"]);

=item * List modules Module-List requires (module name will be converted to distro name):

 deps(dists => ["Module::List"]);

=item * List what distribution that contains Sah::Schema::filename requires:

 deps(modules => ["Sah::Schema::filename"]);

Sah::Schema::filename is included in Sah-Schemas-Path distribution, so this
command is equivalent to "lcpan deps Sah-Schemas-Path". You can't do "lcpan deps
Sah::Schema::filename" because C<lcpan> will assume that you ask "lcpan deps
Sah-Schema-filename" and there is no Sah-Schema-filename distribution.

=item * List non-core modules Module-List requires:

 deps(dists => ["Module-List"], include_core => 0);

=item * List dependencies of a specific distribution release:

 deps(dists => ["Module-List\@0.004"]);

=back

By default only runtime requires are displayed. To see prereqs for other phases
(e.g. configure, or build, or ALL) or for other relationships (e.g. recommends,
or ALL), use the C<--phase> and C<--rel> options.

Note that dependencies information are taken from C<META.json> or C<META.yml>
files. Not all releases (especially older ones) contain them. L<lcpan> (like
MetaCPAN) does not extract information from C<Makefile.PL> or C<Build.PL> because
that requires running (untrusted) code.

Also, some releases specify dynamic config, so there might actually be more
dependencies.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dists> => I<array[perl::distname_with_optional_ver]>

Distribution names (with optional version suffix, e.g. Foo-Bar@1.23).

=item * B<dont_uniquify> => I<bool>

Allow showing multiple modules for different dists.

=item * B<flatten> => I<bool>

Instead of showing tree-like information, flatten it.

When recursing, the default is to show the final result in a tree-like table,
i.e. indented according to levels, e.g.:

 % lcpan deps -R MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 |   Bar             | AUTHOR2 | 0.23    |
 |   Baz             | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

To be brief, if C<Qux> happens to also depends on C<Bar>, it will not be shown in
the result. Thus we don't know the actual C<Bar> version that is needed by the
dependency tree of C<MyModule>. For example, if C<Qux> happens to depends on C<Bar>
version 0.45 then C<MyModule> indirectly requires C<Bar> 0.45.

To list all the direct and indirect dependencies on a single flat list, with
versions already resolved to the largest version required, use the C<flatten>
option:

 % lcpan deps -R --flatten MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 | Bar               | AUTHOR2 | 0.45    |
 | Baz               | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

Note that C<Bar>'s required version is already 0.45 in the above example.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_indexed> => I<bool> (default: 1)

Include modules that are indexed (listed in 02packages.details.txt.gz).

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<include_unindexed> => I<bool> (default: 1)

Include modules that are not indexed (not listed in 02packages.details.txt.gz).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<modules> => I<array[perl::modname]>

=item * B<perl_version> => I<str> (default: "v5.34.0")

Set base Perl version for determining core modules.

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<with_xs_or_pp> => I<bool>

Check each dependency as XSE<sol>PP.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 dists

Usage:

 dists(%args) -> [$status_code, $reason, $payload, \%result_meta]

List distributions.

Examples:

=over

=item * List all distributions:

 dists(cpan => "/cpan");

=item * List all distributions (latest version only):

 dists(cpan => "/cpan", latest => 1);

=item * Grep by distribution name, return detailed record:

 dists(query => ["data-table"], cpan => "/cpan");

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<has_buildpl> => I<bool>

=item * B<has_makefilepl> => I<bool>

=item * B<has_metajson> => I<bool>

=item * B<has_metayml> => I<bool>

=item * B<has_multiple_rels> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<rel_mtime_newer_than> => I<date>

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["dist"])

Sort the result.

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)


By default will return an array of distribution names. If you set C<detail> to
true, will return array of records.



=head2 log

Usage:

 log(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show database index log.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 modules

Usage:

 modules(%args) -> [$status_code, $reason, $payload, \%result_meta]

List modulesE<sol>packages.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<namespaces> => I<array[perl::modname]>

Select modules belonging to certain namespace(s).

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<perl_version> => I<str> (default: "v5.34.0")

Set base Perl version for determining core modules.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["module"])

Sort the result.

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)


By default will return an array of package names. If you set C<detail> to true,
will return array of records.



=head2 namespaces

Usage:

 namespaces(%args) -> [$status_code, $reason, $payload, \%result_meta]

List namespaces.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<from_level> => I<int>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int>

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<sort> => I<str> (default: "name")

=item * B<to_level> => I<int>

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 packages

Usage:

 packages(%args) -> [$status_code, $reason, $payload, \%result_meta]

List modulesE<sol>packages.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<namespaces> => I<array[perl::modname]>

Select modules belonging to certain namespace(s).

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<perl_version> => I<str> (default: "v5.34.0")

Set base Perl version for determining core modules.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["module"])

Sort the result.

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)


By default will return an array of package names. If you set C<detail> to true,
will return array of records.



=head2 rdeps

Usage:

 rdeps(%args) -> [$status_code, $reason, $payload, \%result_meta]

List reverse dependencies.

Examples:

=over

=item * List what distributions depend on Sah::Schema::filename:

 rdeps(modules => ["Sah::Schema::filename"]);

=item * List what distributions depend on one of the modules in Sah-Schemas-Path:

 rdeps(dists => ["Sah-Schemas-Path"]);

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<authors> => I<array[str]>

Filter certain author.

This can be used to select certain author(s).

=item * B<authors_arent> => I<array[str]>

Filter out certain author.

This can be used to filter out certain author(s). For example if you want to
know whether a module is being used by another CPAN author instead of just
herself.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dists> => I<array[perl::distname]>

Distribution names (e.g. Foo-Bar).

=item * B<dont_uniquify> => I<true>

Allow showing multiple modules for different dists.

=item * B<flatten> => I<bool>

Instead of showing tree-like information, flatten it.

See deps' I<flatten> argument for more details.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<modules> => I<array[perl::modname]>

=item * B<phase> => I<str> (default: "ALL")

=item * B<rel> => I<str> (default: "ALL")

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 releases

Usage:

 releases(%args) -> [$status_code, $reason, $payload, \%result_meta]

List releasesE<sol>tarballs.

The status field is the processing status of the file/release by lcpan. C<ok>
means file has been extracted and the meta files parsed, C<nofile> means file is
not found in mirror (possibly because the mirroring process excludes the file
e.g. due to file size too large), C<nometa> means file does not contain
META.{yml,json}, C<unsupported> means file archive format is not supported (e.g.
rar), C<err> means some other error in processing file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<full_path> => I<bool>

=item * B<has_buildpl> => I<bool>

=item * B<has_makefilepl> => I<bool>

=item * B<has_metajson> => I<bool>

=item * B<has_metayml> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<no_path> => I<bool>

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["name"])

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 reset

Usage:

 reset(%args) -> [$status_code, $reason, $payload, \%result_meta]

Reset (empty) the database index.

All data tables will be emptied. This includes all records in the C<log> table as
well as C<index_creation_time> record in the C<meta> table, so there is no records
of previous indexing activity. There is also no record of resetting in the
C<log>.

Tables are not dropped and re-created. The C<meta> table is not emptied.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 stats

Usage:

 stats(%args) -> [$status_code, $reason, $payload, \%result_meta]

Statistics of your local CPAN mirror.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 update

Usage:

 update(%args) -> [$status_code, $reason, $payload, \%result_meta]

CreateE<sol>update local CPAN mirror.

This subcommand first create/update the mirror files by downloading from a
remote CPAN mirror, then update the index.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<exclude_author> => I<array[str]>

Exclude files from certain author(s).

=item * B<force_update_index> => I<bool>

Update the index even though there is no change in files.

=item * B<include_author> => I<array[str]>

Only include files from certain author(s).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<max_file_size> => I<int>

If set, skip downloading files larger than this.

=item * B<remote_url> => I<str>

Select CPAN mirror to download from.

=item * B<retry_delay> => I<int>

Number of seconds to delay between retry attempt.

=item * B<retry_max_attempts> => I<int>

Number of retry attempts on failed HTTP request.

=item * B<skip_file_indexing_pass_1> => I<bool>

=item * B<skip_file_indexing_pass_2> => I<bool>

=item * B<skip_file_indexing_pass_3> => I<bool>

=item * B<skip_index_file_patterns> => I<array[re]>

Skip one or more file patterns from being indexed.

=item * B<skip_index_files> => I<array[str]>

Skip one or more files from being indexed.

=item * B<skip_sub_indexing> => I<bool> (default: 1)

Since sub indexing is still experimental, it is not enabled by default. To
enable it, pass the C<--no-skip-sub-indexing> option.

=item * B<skip_sub_indexing_file_patterns> => I<array[re]>

Skip one or more file patterns from being parsed for subs.

=item * B<skip_sub_indexing_files> => I<array[str]>

Skip one or more files from being parsed for subs.

=item * B<update_files> => I<bool> (default: 1)

Update the files.

=item * B<update_index> => I<bool> (default: 1)

Update the index.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HISTORY

This application began as L<CPAN::SQLite::CPANMeta>, an extension of
L<CPAN::SQLite>. C<CPAN::SQLite> parses C<02packages.details.txt.gz> and
C<01mailrc.txt.gz> and puts the parse result into a SQLite database.
C<CPAN::SQLite::CPANMeta> parses the C<META.json>/C<META.yml> files in
individual release files and adds it to the SQLite database.

In order to simplify things for the users (one-step indexing) and get more
freedom in database schema, C<lcpan> skips using C<CPAN::SQLite> and creates its
own SQLite database. It also parses C<02packages.details.txt.gz> but does not
parse distribution names from it but instead uses C<META.json> and C<META.yml>
files extracted from the release files. If no C<META.*> files exist, then it
will use the module name.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::lcpan::Manual>

L<CPAN::SQLite>

L<CPAN::Mini>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Norbert Csongradi perlancar (@pc-office) Steven Haryanto (on Asus Zenbook)

=over 4

=item *

Norbert Csongradi <norbert@csongradi.hu>

=item *

perlancar (@pc-office) <perlancar@gmail.com>

=item *

Steven Haryanto (on Asus Zenbook) <stevenharyanto@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
