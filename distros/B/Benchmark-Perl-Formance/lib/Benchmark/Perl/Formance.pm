package Benchmark::Perl::Formance;
# git description: v0.52-1-ge734e5c

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Perl 5 performance benchmarking framework
$Benchmark::Perl::Formance::VERSION = '0.53';
use 5.008;

use warnings;
use strict;

use Config;
use Config::Perl::V;
use Exporter;
use Getopt::Long ":config", "no_ignore_case", "bundling";
use Data::Structure::Util "unbless";
use Time::HiRes qw(gettimeofday);
use Devel::Platform::Info;
use List::Util "max";
use Data::DPath 'dpath', 'dpathi';
use File::Find;
use Storable "fd_retrieve", "store_fd";
use Sys::Hostname;
use Sys::Info;
use FindBin qw($Bin);

# comma separated list of default plugins - basically the non-troublemakers
my $DEFAULT_PLUGINS = join ",", qw(DPath
                                   Fib
                                   FibOO
                                   Mem
                                   MatrixReal
                                   Prime
                                   Rx
                                   RxMicro
                                   Shootout::fasta
                                   Shootout::regexdna
                                   Shootout::binarytrees
                                   Shootout::revcomp
                                   Shootout::nbody
                                   Shootout::spectralnorm
                                 );

# FibMXDeclare
my $ALL_PLUGINS = join ",", qw(DPath
                               Fib
                               FibMoose
                               FibMouse
                               FibOO
                               FibOOSig
                               MatrixReal
                               Mem
                               P6STD
                               PerlCritic
                               Prime
                               RegexpCommonTS
                               Rx
                               RxMicro
                               RxCmp
                               Shootout::binarytrees
                               Shootout::fannkuch
                               Shootout::fasta
                               Shootout::knucleotide
                               Shootout::mandelbrot
                               Shootout::nbody
                               Shootout::pidigits
                               Shootout::regexdna
                               Shootout::revcomp
                               Shootout::spectralnorm
                               SpamAssassin
                               Threads
                               ThreadsShared
                             );

our $scaling_script = "$Bin/benchmark-perlformance-set-stable-system";
our $metric_prefix  = "perlformance.perl5";

our $DEFAULT_INDENT          = 0;

my @run_plugins;

# incrementaly interesting Perl Config keys
my %CONFIG_KEYS = (
                   0 => [],
                   1 => [
                         qw(perlpath
                            version
                            archname
                            archname64
                            osvers
                            usethreads
                            useithreads
                          )],
                   2 => [
                         qw(gccversion
                            gnulibc_version
                            usemymalloc
                            config_args
                            optimize
                          )],
                   3 => [qw(ccflags
                            ccname
                            cccdlflags
                            ccdlflags
                            cppflags
                            nm_so_opt
                          )],
                   4 => [qw(PERL_REVISION
                            PERL_VERSION
                            PERL_SUBVERSION
                            PERL_PATCHLEVEL

                            api_revision
                            api_version
                            api_subversion
                            api_versionstring

                            gnulibc_version
                            dtrace
                            doublesize
                            alignbytes
                            bin_ELF
                            git_commit_date
                            version_patchlevel_string
                            d_mymalloc

                            i16size
                            i16type
                            i32size
                            i32type
                            i64size
                            i64type
                            i8size
                            i8type

                            longdblsize
                            longlongsize
                            longsize

                            perllibs
                            ptrsize
                            quadkind
                            quadtype
                            randbits
                          )],
                   5 => [
                         sort keys %Config
                        ],
                  );

sub new {
        my ($class, %args) = @_;
        bless { %args }, $class;
}

sub load_all_plugins
{
        my $path = __FILE__;
        $path =~ s,\.pmc?$,/Plugin,;

        my %all_plugins;
        finddepth ({ no_chdir => 1,
                     follow   => 1,
                     wanted   => sub { no strict 'refs';
                                       my $fullname = $File::Find::fullname;
                                       my $plugin   = $File::Find::name;
                                       $plugin      =~ s,^$path/*,,;
                                       $plugin      =~ s,/,::,;
                                       $plugin      =~ s,\.pmc?$,,;

                                       my $module = "Benchmark::Perl::Formance::Plugin::$plugin";
                                       # eval { require $fullname };
                                       eval "use $module"; ## no critic
                                       my $version = $@ ? "~" : ${$module."::VERSION"};
                                       $all_plugins{$plugin} = $version
                                         if -f $fullname && $fullname =~ /\.pmc?$/;
                               },
                   },
                   $path);
        return %all_plugins;
}

sub print_version
{
        my ($self) = @_;

        if ($self->{options}{verbose})
        {
                print "Benchmark::Perl::Formance version $Benchmark::Perl::Formance::VERSION\n";
                print "Plugins:\n";
                my %plugins = load_all_plugins;
                print "  (v$plugins{$_}) $_\n" foreach sort keys %plugins;
        }
        else
        {
                print $Benchmark::Perl::Formance::VERSION, "\n";
        }
}

sub usage
{
        print 'benchmark-perlformance - Frontend for Benchmark::Perl::Formance

Usage:

   $ benchmark-perlformance
   $ benchmark-perlformance --fastmode
   $ benchmark-perlformance --useforks
   $ benchmark-perlformance --plugins=SpamAssassin,RegexpCommonTS,RxCmp -v
   $ benchmark-perlformance -ccccc --indent=2
   $ benchmark-perlformance -q

If run directly it uses the perl in your PATH:

   $ /path/to/benchmark-perlformance

To use another perl start it via

   $ /other/path/to/bin/perl /path/to/benchmark-perlformance

For more details see

   man benchmark-perlformance
   perldoc Benchmark::Perl::Formance

';
}

sub do_disk_sync {
    system("sync ; sync");
}

sub prepare_stable_system
{
        my ($self) = @_;

        my $orig_values;
        if ($self->{options}{stabilize_cpu} and $^O eq "linux") {
                $self->{orig_system_values} = qx(sudo $scaling_script lo);
                do_disk_sync();
        }
}

sub restore_stable_system
{
        my ($self, $orig_values) = @_;
        if ($self->{options}{stabilize_cpu} and $^O eq "linux") {
                if (open my $RESTORE, "|-", "sudo $scaling_script restore") {
                    print $RESTORE $self->{orig_system_values};
                    close $RESTORE;
                }
        }
}

sub prepare_fast_system
{
        my ($self) = @_;

        my $orig_values;
        if ($self->{options}{stabilize_cpu} and $^O eq "linux") {
                $self->{orig_system_values} = qx(sudo $scaling_script hi);
        }
}

sub _error_printing
{
        my ($self, $pluginname, $error) = @_;

        my @errors = split qr/\n/, $error;
        my $maxerr = ($#errors < 10) ? $#errors : 10;
        print STDERR "# Skip plugin '$pluginname'"             if $self->{options}{verbose};
        print STDERR ":".$errors[0]                            if $self->{options}{verbose} > 1;
        print STDERR join("\n# ", "", @errors[1..$maxerr])     if $self->{options}{verbose} > 2;
        print STDERR "\n"                                      if $self->{options}{verbose};
}

sub run_plugin
{
        my ($self, $pluginname) = @_;

        $pluginname =~ s,\.,::,g;
        no strict 'refs';       ## no critic
        print STDERR "# Run $pluginname...\n" if $self->{options}{verbose} >= 2;
        my $res;
        eval {
                use IO::Handle;
                pipe(PARENT_RDR, CHILD_WTR);
                CHILD_WTR->autoflush(1);
                my $pid = open(my $PLUGIN, "-|"); # implicit fork
                if ($pid == 0) {
                        # run in child process
                        close PARENT_RDR;
                        eval "use Benchmark::Perl::Formance::Plugin::$pluginname"; ## no critic
                        if ($@) {
                                $self->_error_printing($pluginname, $@);
                                exit 0;
                        }
                        $0 = "benchmark-perl-formance-$pluginname";
                        eval {
                                $res = &{"Benchmark::Perl::Formance::Plugin::${pluginname}::main"}($self->{options});
                        };
                        if ($@) {
                                $self->_error_printing($pluginname, $@);
                                $res = { failed => $@ };
                        }
                        $res->{PLUGIN_VERSION} = ${"Benchmark::Perl::Formance::Plugin::${pluginname}::VERSION"};
                        store_fd($res, \*CHILD_WTR);
                        close CHILD_WTR;
                        exit 0;
                }
                close CHILD_WTR;
                $res = fd_retrieve(\*PARENT_RDR);
                close PARENT_RDR;
        };
        if ($@) {
                $res = {
                        failed => "Plugin $pluginname failed",
                        ($self->{options}{verbose} > 3 ? ( error  => $@ ) : ()),
                       }
        }
        return $res;
}

# That's specific to the Tapper wrapper around
# Benchmark::Perl::Formance and should be replaced
# with something generic
sub _perl_gitversion {
        my $perlpath = "$^X";
        $perlpath    =~ s,/[^/]*$,,;
        my $perl_gitversion  = "$perlpath/perl -MConfig -e 'print \$Config{bootstrap_perl_git_changeset}";

        if (-x $perl_gitversion) {
                my $gitversion = qx!$perl_gitversion! ;
                chomp $gitversion;
                return $gitversion;
        }
}

sub _perl_gitdescribe {
        my $perlpath = "$^X";
        $perlpath    =~ s,/[^/]*$,,;
        my $perl_gitdescribe  = "$perlpath/perl -MConfig -e 'print \$Config{bootstrap_perl_git_describe}";

        if (-x $perl_gitdescribe) {
                my $gitdescribe = qx!$perl_gitdescribe! ;
                chomp $gitdescribe;
                return $gitdescribe;
        }
}

sub _perl_symbolic_name {
        my $perlpath = "$^X";
        $perlpath    =~ s,/[^/]*$,,;
        my $perl_symbolic_name  = "$perlpath/perl -MConfig -e 'print \$Config{bootstrap_perl_symbolic_name}";

        if (-x $perl_symbolic_name) {
                my $executable = qx!$perl_symbolic_name! ;
                chomp $executable;
                return $executable;
        }
}

sub _get_hostname {
        my $host = "unknown-hostname";
        eval { $host = hostname };
        $host = "perl64.org" if $host eq "h1891504"; # special case for PerlFormance.Net Æsthetics
        return $host;
}

sub _plugin_results {
        my ($self, $plugin, $RESULTS) = @_;

        my @resultkeys = split(/\./, $plugin);
        my ($res) = dpath("/results/".join("/", map { qq("$_") } @resultkeys)."/Benchmark/*[0]")->match($RESULTS);

        return $res;
}

sub _codespeed_meta {
        my ($self, $RESULTS) = @_;

        my $codespeed_exe_suffix  = $self->{options}{cs_executable_suffix}  || $ENV{CODESPEED_EXE_SUFFIX}  || "";
        my $codespeed_exe         = $self->{options}{cs_executable}         || _perl_symbolic_name  || sprintf("perl-%s.%s%s",
                                                                                                                      $Config{PERL_REVISION},
                                                                                                                      $Config{PERL_VERSION},
                                                                                                                      $codespeed_exe_suffix,
                                                                                                                     );
        my $codespeed_project     = $self->{options}{cs_project}            || $ENV{CODESPEED_PROJECT}     || "perl5";
        my $codespeed_branch      = $self->{options}{cs_branch}             || $ENV{CODESPEED_BRANCH}      || "default";
        my $codespeed_commitid    = $self->{options}{cs_commitid}           || $ENV{CODESPEED_COMMITID}    || $Config{git_commit_id} || _perl_gitversion || "no-commit";
        my $codespeed_environment = $self->{options}{cs_environment}        || $ENV{CODESPEED_ENVIRONMENT} || _get_hostname || "no-env";
        my %codespeed_meta = (
                              executable  => $codespeed_exe,
                              project     => $codespeed_project,
                              branch      => $codespeed_branch,
                              commitid    => $codespeed_commitid,
                              environment => $codespeed_environment,
                             );

        return %codespeed_meta;
}

sub _get_bootstrap_perl_meta {
        my ($self) = @_;

        return map { ("$_" => $Config{$_}) } grep { /^bootstrap_perl/ } keys %Config;
}

sub _get_perl_config {
        my ($self) = @_;

        my @cfgkeys;
        my $showconfig = 4;
        push @cfgkeys, @{$CONFIG_KEYS{$_}} foreach 1..$showconfig;
        return map { ("perlconfig_$_" => $Config{$_}) } @cfgkeys;
}

sub _get_perl_config_v {
        my ($self) = @_;

        # only when ultimate verbose config requested
        return unless $self->{options}{showconfig} >= 5;

        my $config_v_myconfig = Config::Perl::V::myconfig ();
        my @config_v_keys = sort keys %$config_v_myconfig;

        # --- flat configs ---
        my $prefix      = "perlconfigv";
        my %perlconfigv = ();
        my %focus       = (
                           derived     => [ qw( Off_t uname) ],
                           build       => [ qw( osname stamp ) ],
                           environment => [ keys %{$config_v_myconfig->{environment}} ], # all
                    );
        foreach my $subcfg (keys %focus) {
                foreach my $k (@{$focus{$subcfg}}) {
                        $perlconfigv{join("_", $prefix, $subcfg, $k)} = $config_v_myconfig->{$subcfg}{$k};
                }
        }

        # --- nested configs ---

        # build options
        my @buildoptionkeys = keys %{$config_v_myconfig->{build}{options}};
        foreach my $k (keys %focus) {
                $perlconfigv{join("_", $prefix, "build", "options", $k)} = $config_v_myconfig->{build}{options}{$k};
        }

        return %perlconfigv;
}

sub _get_perlformance_config {
        my ($self) = @_;

        # only easy printable data (i.e., no "D" hash)
        my @config_keys = (qw(stabilize_cpu
                              fastmode
                              useforks
                              plugins
                            ));

        return map { $self->{options}{$_} ? ("perlformance_$_" => $self->{options}{$_}) : () } @config_keys;
}

sub _get_perlformance_env
{
        my ($self) = @_;

        # environment variables matching /^PERLFORMANCE_/
        my @config_keys = grep { $ENV{$_} ne '' } grep /^PERLFORMANCE_/, keys %ENV;

        return map { lc("env_$_") => $ENV{$_} } @config_keys;
}

sub _get_platforminfo {
        my ($self) = @_;

        my $get_info = Devel::Platform::Info->new->get_info;
        delete $get_info->{source}; # this currently breaks the simplified YAMLish
        return %$get_info;
}

sub _get_sysinfo {
        my ($self) = @_;

        my %sysinfo = ();
        my $prefix = "sysinfo";
        my $cpu = (Sys::Info->new->device("CPU")->identify)[0];
        $sysinfo{join("_", $prefix, "cpu", $_)} = $cpu->{$_} foreach qw(name
                                                                        family
                                                                        model
                                                                        stepping
                                                                        architecture
                                                                        number_of_cores
                                                                        number_of_logical_processors
                                                                        architecture
                                                                        manufacturer
                                                                      );
        $sysinfo{join("_", $prefix, "cpu", "l2_cache", "max_cache_size")} = $cpu->{L2_cache}{max_cache_size};
        return %sysinfo;
}

sub augment_results_with_meta {
        my ($self, $NAME_KEY, $VALUE_KEY, $META, $RESULTS) = @_;

        my @run_plugins = $self->find_interesting_result_paths($RESULTS);
        my @new_entries = ();
        foreach my $plugin (sort @run_plugins) {
                no strict 'refs'; ## no critic
                my $res = $self->_plugin_results($plugin, $RESULTS);
                my $benchmark =  join ".", $metric_prefix, ($self->{options}{fastmode} ? "$plugin(F)" : $plugin);
                push @new_entries, {
                                    %$META,
                                    # metric name and value at last position to override
                                    $NAME_KEY  => $benchmark,
                                    $VALUE_KEY => ($res || 0),
                                   };
        }
        return \@new_entries;
}

sub generate_codespeed_data
{
        my ($self, $RESULTS) = @_;

        my %META = _codespeed_meta();
        return $self->augment_results_with_meta("benchmark", "result_value", \%META, $RESULTS);
}

sub generate_BenchmarkAnythingData_data
{
        my ($self, $RESULTS) = @_;

        # share a common dataset with Codespeed, yet prefix it
        my %codespeed_meta = _codespeed_meta;
        my %prefixed_codespeed_meta = map { ("codespeed_$_" => $codespeed_meta{$_}) } keys %codespeed_meta;

        my %platforminfo = $self->_get_platforminfo;
        my %prefixed_platforminfo = map { ("platforminfo_$_" => $platforminfo{$_}) } keys %platforminfo;

        my %META =  (
                     %prefixed_platforminfo,
                     %prefixed_codespeed_meta,
                     $self->_get_bootstrap_perl_meta,
                     $self->_get_perl_config,
                     $self->_get_perl_config_v,
                     $self->_get_sysinfo,
                     $self->_get_perlformance_config,
                     $self->_get_perlformance_env,
                    );
        return $self->augment_results_with_meta("NAME", "VALUE", \%META, $RESULTS);
}

sub run {
        my ($self) = @_;

        my $help           = 0;
        my $showconfig     = 0;
        my $outstyle       = "summary";
        my $outfile        = "";
        my $platforminfo   = 0;
        my $codespeed      = 0;
        my $tapper         = 0;
        my $benchmarkanything = 0;
        my $benchmarkanything_report = 0;
        my $cs_executable_suffix = "";
        my $cs_executable        = "";
        my $cs_project           = "";
        my $cs_branch            = "";
        my $cs_commitid          = "";
        my $cs_environment       = "";
        my $verbose        = 0;
        my $version        = 0;
        my $fastmode       = 0;
        my $useforks       = 0;
        my $quiet          = 0;
        my $stabilize_cpu  = 0;
        my $plugins        = $DEFAULT_PLUGINS;
        my $indent         = $DEFAULT_INDENT;
        my $tapdescription = "";
        my $D              = {};

        # get options
        my $ok = GetOptions (
                             "help|h"           => \$help,
                             "quiet|q"          => \$quiet,
                             "indent=i"         => \$indent,
                             "plugins=s"        => \$plugins,
                             "verbose|v+"       => \$verbose,
                             "outstyle=s"       => \$outstyle,
                             "outfile=s"        => \$outfile,
                             "fastmode"         => \$fastmode,
                             "version"          => \$version,
                             "useforks"         => \$useforks,
                             "stabilize-cpu"    => \$stabilize_cpu,
                             "showconfig|c+"    => \$showconfig,
                             "platforminfo|p"   => \$platforminfo,
                             "codespeed"        => \$codespeed,
                             "tapper"           => \$tapper,
                             "benchmarkanything" => \$benchmarkanything,
                             "benchmarkanything-report" => \$benchmarkanything_report,
                             "cs-executable-suffix=s" => \$cs_executable_suffix,
                             "cs-executable=s"  => \$cs_executable,
                             "cs-project=s"     => \$cs_project,
                             "cs-branch=s"      => \$cs_branch,
                             "cs-commitid=s"    => \$cs_commitid,
                             "cs-environment=s" => \$cs_environment,
                             "tapdescription=s" => \$tapdescription,
                             "D=s%"             => \$D,
                            );

        # special meta options - order matters!
        $benchmarkanything = 1 if $tapper; # legacy option
        $benchmarkanything = 1 if $benchmarkanything_report;
        $platforminfo      = 1 if $benchmarkanything; # -p
        $showconfig        = 4 if $benchmarkanything; # -cccc
        $outstyle          = 'json' if $benchmarkanything and $outstyle !~ /^(json|yaml|yamlish)$/;
        $outstyle          = 'json' if $benchmarkanything_report;

        # fill options
        $self->{options} = {
                            help           => $help,
                            quiet          => $quiet,
                            verbose        => $verbose,
                            outfile        => $outfile,
                            outstyle       => $outstyle,
                            fastmode       => $fastmode,
                            useforks       => $useforks,
                            stabilize_cpu  => $stabilize_cpu,
                            showconfig     => $showconfig,
                            platforminfo   => $platforminfo,
                            codespeed      => $codespeed,
                            tapper         => $tapper,
                            benchmarkanything => $benchmarkanything,
                            benchmarkanything_report => $benchmarkanything_report,
                            cs_executable_suffix => $cs_executable_suffix,
                            cs_executable        => $cs_executable,
                            cs_project           => $cs_project,
                            cs_branch            => $cs_branch,
                            cs_commitid          => $cs_commitid,
                            cs_environment       => $cs_environment,
                            plugins        => $plugins,
                            tapdescription => $tapdescription,
                            indent         => $indent,
                            D              => $D,
                           };

        do { $self->print_version; exit  0 } if $version;
        do { usage;                exit  0 } if $help;
        do { usage;                exit -1 } if not $ok;

        # use forks if requested
        if ($useforks) {
                eval "use forks"; ## no critic
                $useforks = 0 if $@;
                print STDERR "# use forks " . ($@ ? "failed" : "") . "\n" if $verbose;
        }

        # static list because dynamic require influences runtimes
        $plugins = $ALL_PLUGINS if $plugins eq "ALL";

        # run plugins
        my $before = gettimeofday();
        my %RESULTS;
        my @plugins = grep /\w/, split '\s*,\s*', $plugins;

        $self->prepare_stable_system;
        foreach (@plugins)
        {
                my @resultkeys = split(qr/::|\./, $_);
                my $res = $self->run_plugin($_);
                eval "\$RESULTS{results}{".join("}{", @resultkeys)."} = \$res"; ## no critic
        }
        $self->prepare_fast_system; # simply set to max, as restore_stable_system() is no reliable approach anyway

        my $after  = gettimeofday();
        $RESULTS{perlformance}{overall_runtime}   = $after - $before;
        $RESULTS{perlformance}{config}{fastmode}  = $fastmode;
        $RESULTS{perlformance}{config}{use_forks} = $useforks;

        # Perl Config
        if ($showconfig)
        {
                # Config
                my @cfgkeys;
                push @cfgkeys, @{$CONFIG_KEYS{$_}} foreach 1..$showconfig;
                $RESULTS{perl_config} =
                {
                 map { $_ => $Config{$_} } sort @cfgkeys
                };

                # Config::Perl::V
                $RESULTS{perl_config_v} = Config::Perl::V::myconfig;
        }

        # Perl Config
        if ($platforminfo)
        {
                $RESULTS{platform_info} = { $self->_get_platforminfo };
        }

        # Codespeed data blocks
        if ($codespeed)
        {
                $RESULTS{codespeed} = $self->generate_codespeed_data(\%RESULTS);
        }

        # Tapper BenchmarkAnythingData blocks
        if ($tapper or $benchmarkanything)
        {
                $RESULTS{BenchmarkAnythingData} = $self->generate_BenchmarkAnythingData_data(\%RESULTS);
        }

        unbless (\%RESULTS);
        return \%RESULTS;
}

sub print_outstyle_yaml
{
        my ($self, $RESULTS) = @_;

        require YAML;
        return YAML::Dump($RESULTS);
}

sub print_outstyle_json
{
        my ($self, $RESULTS) = @_;

        require JSON;
        return JSON->new->allow_nonref->pretty->encode( $RESULTS );
}

sub print_outstyle_yamlish
{
        my ($self, $RESULTS) = @_;

        require Data::YAML::Writer;

        my $output = '';
        my $indent = $self->{options}{indent};
        my $yw = Data::YAML::Writer->new;
        $yw->write($RESULTS, sub { $output .= shift()."\n" });
        $output =~ s/^/" "x$indent/emsg; # indent

        my $tapdescription = $self->{options}{tapdescription};
        $output = "ok $tapdescription\n".$output if $tapdescription;
        return $output;
}

sub find_interesting_result_paths
{
        my ($self, $RESULTS) = @_;

        my @all_keys = ();

        my $benchmarks = dpathi($RESULTS)->isearch("//Benchmark");

        while ($benchmarks->isnt_exhausted) {
                my @keys;
                my $benchmark = $benchmarks->value;
                my $ancestors = $benchmark->isearch ("/::ancestor");

                while ($ancestors->isnt_exhausted) {
                        my $key = $ancestors->value->first_point->{attrs}{key};
                        push @keys, $key if defined $key;
                }
                pop @keys;
                push @all_keys, join(".", reverse @keys);
        }
        return @all_keys;
}

sub print_outstyle_summary
{
        my ($self, $RESULTS) = @_;

        my $output = '';

        my @run_plugins = $self->find_interesting_result_paths($RESULTS);
        my $len = max map { length } @run_plugins;
        $len   += 1+length($metric_prefix);

        foreach (sort @run_plugins) {
                no strict 'refs'; ## no critic
                my $res = $self->_plugin_results($_, $RESULTS);
                $output .= sprintf("%-${len}s : %f\n", join(".", $metric_prefix, $_), ($res || 0));
        }
        return $output;
}

sub print_results
{
        my ($self, $RESULTS) = @_;
        return if $self->{options}{quiet};

        my $outstyle = lc $self->{options}{outstyle};
        $outstyle = "summary" unless $outstyle =~ qr/^(summary|yaml|yamlish|json)$/;
        my $sub = "print_outstyle_$outstyle";

        my $output = $self->$sub($RESULTS);

        if (my $outfile = $self->{options}{outfile})
        {
                open my $OUTFILE, ">", $outfile or do {
                        warn "Can not open $outfile. Printing to STDOUT.\n";
                        print $output;
                };
                print $OUTFILE $output;
                close $OUTFILE;
        }
        elsif ($self->{options}{benchmarkanything_report})
        {
                my $ba_reporter;

                eval {
                        require BenchmarkAnything::Reporter;
                        $ba_reporter = BenchmarkAnything::Reporter->new(verbose => $self->{options}{verbose});
                        $ba_reporter->report({BenchmarkAnythingData => $RESULTS->{BenchmarkAnythingData}});
                };
                if ($@)
                {
                        print STDERR "# Could not add results to storage: $@\n";

                        require JSON;
                        require File::Path;
                        require File::Temp;
                        require File::Basename;

                        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

                        my $result_dir = File::Basename::dirname($ba_reporter->{config}{cfgfile});
                        if (! -w $result_dir) {
                                require File::HomeDir;
                                $result_dir = File::HomeDir->my_home;
                        }
                        if (! -w $result_dir) {
                                require File::Temp;
                                $result_dir = tempdir(CLEANUP => 0);
                        }

                        my $timestamp1         = sprintf("%04d-%02d-%02d", 1900+$year, $mon, $mday);
                        my $timestamp2         = sprintf("%02d-%02d-%02d", $hour, $min, $sec);
                        my $result_path        = "$result_dir/unreported_results/$timestamp1";

                        File::Path::make_path($result_path);

                        my ($FH, $result_file) = File::Temp::tempfile ("$timestamp2-XXXX", DIR => $result_path, SUFFIX => ".json");
                        print STDERR "# Writing them to file: $result_file\n";
                        print $FH JSON->new->allow_nonref->pretty->encode({BenchmarkAnythingData => $RESULTS->{BenchmarkAnythingData}});
                }
        }
        else
        {
                print $output;
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance - Perl 5 performance benchmarking framework

=head1 ABOUT

This benchmark suite tries to run some stressful programs and outputs
values that you can compare against other runs of this suite,
e.g. with other versions of Perl, modified compile parameter, or
another set of dependent libraries.

=head1 BUGS

=head2 No invariant dependencies

This distribution only contains the programs to run the tests and
according data. It uses a lot of libs from CPAN with all their
dependencies but it does not contain invariant versions of those used
dependency libs.

If total invariance is important to you, you are responsible to
provide that invariant environment by yourself. You could, for
instance, create a local CPAN mirror with CPAN::Mini and never upgrade
it. Then use that mirror for all your installations of Benchmark::Perl::Formance.

On the other side this could be used to track the performance of your
installation over time by continuously upgrading from CPAN.

=head2 It is not scientific

The benchmarks are basically just a collection of already existing
interesting things like large test suites found on CPAN or just
starting long running tasks that seem to stress perl features. It does
not really guarantee accuracy of only raw Perl features, i.e., it does
not care for underlying I/O speed and does not preallocate ressources
from the OS before using them, etc.

This is basically because I just wanted to start, even without
knowledge about "real" benchmark science.

Anyway, feel free to implement "real" benchmark ideas and send me
patches.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
