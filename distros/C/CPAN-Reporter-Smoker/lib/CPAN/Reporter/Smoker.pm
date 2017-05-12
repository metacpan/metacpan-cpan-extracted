use 5.006;
use strict;
use warnings;
package CPAN::Reporter::Smoker;

our $VERSION = '0.29';

use Carp;
use Config;
use CPAN 1.93;
use CPAN::Tarzip;
use CPAN::HandleConfig;
use CPAN::Reporter::History 1.1702;
use Compress::Zlib 1.2;
use Fcntl ':flock';
use File::Basename qw/basename dirname/;
use File::Spec 3.27;
use File::Temp 0.20;
use List::Util 1.03 qw/shuffle/;
use Probe::Perl 0.01;
use Term::Title 0.01;

use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw/ start /; ## no critic Export

#--------------------------------------------------------------------------#
# globals
#--------------------------------------------------------------------------#

my $perl = Probe::Perl->find_perl_interpreter;
my $tmp_dir = File::Temp::tempdir(
  'C-R-Smoker-XXXXXXXX', DIR => File::Spec->tmpdir, CLEANUP => 1
);

#--------------------------------------------------------------------------#
# start -- start automated smoking
#--------------------------------------------------------------------------#
my %spec = (
  clean_cache_after => {
    default => 100,
    is_valid => sub { /^\d+$/ },
  },
  restart_delay => {
    default => 12 * 3600, # 12 hours
    is_valid => sub { /^\d+$/ },
  },
  set_term_title => {
    default => 1,
    is_valid => sub { /^[01]$/ },
  },
  status_file => {
    default => File::Spec->catfile( File::Spec->tmpdir, "smoker-status-$$.txt" ),
    is_valid => sub { -d dirname( $_ ) },
  },
  list => {
    default => undef,
    is_valid => sub { !defined $_ || ref $_ eq 'ARRAY' || -r $_ }
  },
  install => {
    default  => 0,
    is_valid => sub { /^[01]$/ },
  },
  'reverse' => {
    default => 0,
    is_valid => sub { /^[01]$/ },
  },
  'random' => {
    default => 0,
    is_valid => sub { /^[01]$/ },
  },
  force_trust => {
    default => 0,
    is_valid => sub { /^[01]$/ },
  },
  'reload_history_period' => {
    default => 30*60,
    is_valid => sub { /^\d+$/ },
  },
  filter => {
    default => undef,
    is_valid => sub { !defined $_ || ref $_ eq 'CODE' }
  },
  skip_dev_versions => {
    default => 0,
    is_valid => sub { /^[01]$/ },
  },
  '_start_from_timestamp' => {
    default => 0,
    is_valid => sub { /^(?:[\d.]{8}|0)$/ },
  },
  _hook_after_test => {
    default => undef,
    is_valid => sub { !defined $_ || ref $_ eq 'CODE' }
  },
);

sub start {
  my %args = map { $_ => $spec{$_}{default} } keys %spec;
  croak "Invalid arguments to start(): must be key/value pairs"
  if @_ % 2;
  while ( @_ ) {
    my ($key, $value) = splice @_, 0, 2;
    local $_ = $value; # alias for validator
    croak "Invalid argument to start(): $key => $value"
    unless $spec{$key} && $spec{$key}{is_valid}->($value);
    $args{$key} = $value;
  }

  # Stop here if we're just testing
  return 1 if $ENV{PERL_CR_SMOKER_SHORTCUT};

  # Notify before CPAN messages start
  $CPAN::Frontend->mywarn( "Starting CPAN::Reporter::Smoker\n" );

  # Let things know we're running automated
  local $ENV{AUTOMATED_TESTING} = 1;

  # Always accept default prompts
  local $ENV{PERL_MM_USE_DEFAULT} = 1;
  local $ENV{PERL_EXTUTILS_AUTOINSTALL} = "--defaultdeps";

  # Load CPAN configuration
  my $init_cpan = 0;
  unless ( $init_cpan++ ) {
    CPAN::HandleConfig->load();
    CPAN::Shell::setup_output;
    CPAN::Index->reload;
    $CPAN::META->checklock(); # needed for cache scanning
  }

  # Win32 SIGINT propogates all the way to us, so trap it before we smoke
  # Must come *after* checklock() to override CPAN's $SIG{INT}
  local $SIG{INT} = \&_prompt_quit;

  # Master loop
  # loop counter will increment with each restart - useful for testing
  my $loop_counter = 0;

  # global cache of distros smoked to speed skips on restart
  my %seen = map { $_->{dist} => 1 } CPAN::Reporter::History::have_tested();
  my $history_loaded_at = time;

  SCAN_LOOP:
  while ( 1 ) {
    $loop_counter++;
    my $loop_start_time = time;
    my $dists;

    # Get the list of distributions to process
    if ( $args{list} ) {
      # Given a list
      if ( ref $args{list} eq 'ARRAY' ) {
        $dists = $args{list};
      }
      # Given a file
      else {
        open( my $list_fh, "<", $args{list} ) or die $!;
        my @list = map { chomp; $_ } grep { /\S/ } <$list_fh>;
        $dists = \@list;
      }
    }
    else {
      # Or get list from CPAN
      my $package = _get_module_index( 'modules/02packages.details.txt.gz' );
      my $find_ls = _get_module_index( 'indices/find-ls.gz' );
      CPAN::Index->reload;
      $CPAN::Frontend->mywarn( "Smoker: scanning and sorting index\n");

      $dists = _parse_module_index( $package, $find_ls, $args{skip_dev_versions}, $args{_start_from_timestamp} );

      $CPAN::Frontend->mywarn( "Smoker: found " . scalar @$dists . " distributions on CPAN\n");
    }

    # Maybe reverse the list
    if ( $args{'reverse'} ) {
      $dists = [ reverse @$dists ];
    }

    # Maybe shuffle the list
    if ( $args{'random'} ) {
      $dists = [ shuffle @$dists ];
    }

    # Check if we need to manually reset test history during each dist loop
    my $reset_string = q{};
    if ( $CPAN::Config->{build_dir_reuse}
      && $CPAN::META->can('reset_tested') )
    {
      $reset_string = 'CPAN::Index->reload; $CPAN::META->reset_tested; '
    }

    # Force trust_test_report_history if requested
    my $trust_string = q{};
    if ( $args{force_trust} ) {
      $trust_string = '$CPAN::Config->{trust_test_report_history} = 1; '
    }

    # Clean cache on start and count dists tested to trigger cache cleanup
    _clean_cache();
    my $dists_tested = 0;

    # Start smoking
    DIST:
    for my $d ( 0 .. $#{$dists} ) {
      my $dist = CPAN::Shell->expandany($dists->[$d]);
      my $base = $dist->base_id;
      my $count = sprintf('%d/%d', $d+1, scalar @$dists);
      if ( $seen{$base}++ ) {
        $CPAN::Frontend->mywarn(
          "Smoker: already tested $base [$count]\n");
        next DIST;
      }
      elsif ( $args{filter} and $args{filter}->($dist) ) {
        $CPAN::Frontend->mywarn(
          "Smoker: dist skipped $base [$count]\n");
        next DIST;
      }
      elsif ( CPAN::Distribution->new(%{$dist})->prefs->{disabled} ) {
        $CPAN::Frontend->mywarn(
          "Smoker: dist disabled $base [$count]\n");
        next DIST;
      }
      else {
        # record distribution being smoked
        my $time = scalar localtime();
        my $msg = "$base [$count] at $time";
        if ( $args{set_term_title} ) {
          Term::Title::set_titlebar( "Smoking $msg" );
        }
        $CPAN::Frontend->mywarn( "\nSmoker: testing $msg\n\n" );
        local $ENV{PERL_CR_SMOKER_CURRENT} = $base;
        open my $status_fh, ">", $args{status_file};
        if ( $status_fh ) {
          flock $status_fh, LOCK_EX;
          print {$status_fh} $msg;
          flock $status_fh, LOCK_UN;
          close $status_fh;
        }
        # invoke CPAN.pm to test distribution
        system($perl, "-MCPAN", "-e",
          "\$CPAN::Config->{test_report} = 1; " . $trust_string
          . $reset_string . ($args{'install'} ? 'install' : 'test')
          . "( '$dists->[$d]' )"
        );
        my $interrupted = 0;
        if ( $? & 127 ) {
          $interrupted = 1;
          _prompt_quit( $? & 127 ) ;
        }

        if ($args{_hook_after_test}) {
          $args{_hook_after_test}->($dist, $interrupted);
        }
        
        # cleanup and record keeping
        unlink $args{status_file} if -f $args{status_file};
        $dists_tested++;
      }
      if ( $dists_tested >= $args{clean_cache_after} ) {
        _clean_cache();
        $dists_tested = 0;
      }
      if (time - $history_loaded_at > $args{reload_history_period}) { #_reload_history
        %seen = map { $_->{dist} => 1 } CPAN::Reporter::History::have_tested();
        $history_loaded_at = time;
        $CPAN::Frontend->mywarn( "List of distros smoked updated\n");
      }

      next SCAN_LOOP if time - $loop_start_time > $args{restart_delay};
    }
    last SCAN_LOOP if $ENV{PERL_CR_SMOKER_RUNONCE};
    last SCAN_LOOP if $args{list};
    # if here, we are out of distributions to test, so sleep
    my $delay = int( $args{restart_delay} - ( time - $loop_start_time ));
    if ( $delay > 0 ) {
      $CPAN::Frontend->mywarn(
        "\nSmoker: Finished all available dists. Sleeping for $delay seconds.\n\n"
      );
      sleep $delay ;
    }
  }

  CPAN::cleanup();
  return $loop_counter;
}

#--------------------------------------------------------------------------#
# private variables and functions
#--------------------------------------------------------------------------#

sub _clean_cache {
  my $phase = $CPAN::Config->{scan_cache};
  # Possibly clean up cache if it exceeds defined size
  if ( $CPAN::META->{cachemgr} ) {
    $CPAN::META->{cachemgr}->scan_cache($phase);
  }
  else {
    $CPAN::META->{cachemgr} = CPAN::CacheMgr->new($phase); # also scans cache
  }
}

sub _prompt_quit {
    my ($sig) = @_;
    # convert numeric to name
    if ( $sig =~ /\d+/ ) {
        my @signals = split q{ }, $Config{sig_name};
        $sig = $signals[$sig] || '???';
    }
    $CPAN::Frontend->myprint(
        "\nStopped during $ENV{PERL_CR_SMOKER_CURRENT}.\n"
    ) if defined $ENV{PERL_CR_SMOKER_CURRENT};
    $CPAN::Frontend->myprint(
        "\nCPAN testing halted on SIG$sig.  Continue (y/n)? [n]\n"
    );
    my $answer = <STDIN>;
    CPAN::cleanup(), exit 0 unless substr( lc($answer), 0, 1) eq 'y';
    return;
}

#--------------------------------------------------------------------------#
# _get_module_index
#
# download the 01modules index and return the local file name
#--------------------------------------------------------------------------#

sub _get_module_index {
    my ($remote_file) = @_;

    $CPAN::Frontend->mywarn(
        "Smoker: getting $remote_file from CPAN\n");
    # CPAN.pm may not use aslocal if it's a file:// mirror
    my $aslocal_file = File::Spec->catfile( $tmp_dir, basename( $remote_file ));
    my $actual_local = CPAN::FTP->localize( $remote_file, $aslocal_file, 1 );
    if ( ! -r $actual_local ) {
        die "Couldn't get '$remote_file' from your CPAN mirror. Halting\n";
    }
    return $actual_local;
}

my $module_index_re = qr{
    ^\s href="\.\./authors/id/./../    # skip prelude
    ([^"]+)                     # capture to next dquote mark
    .+? </a>                    # skip to end of hyperlink
    \s+                         # skip spaces
    \S+                         # skip size
    \s+                         # skip spaces
    (\S+)                       # capture day
    \s+                         # skip spaces
    (\S+)                       # capture month
    \s+                         # skip spaces
    (\S+)                       # capture year
}xms;

my %months = (
    Jan => '01', Feb => '02', Mar => '03', Apr => '04', May => '05',
    Jun => '06', Jul => '07', Aug => '08', Sep => '09', Oct => '10',
    Nov => '11', Dec => '12'
);

# standard regexes
# note on archive suffixes -- .pm.gz shows up in 02packagesf
my %re = (
    bundle => qr{^Bundle::},
    mod_perl => qr{/mod_perl},
    perls => qr{(?:
          /(?:emb|syb|bio)?perl-\d
        | /(?:parrot|ponie|kurila|Perl6-Pugs)-\d
        | /perl-?5\.004
        | /perl_mlb\.zip
    )}xi,
    archive => qr{\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|(?<!ppm\.)zip|pm.gz)$}i,
    target_dir => qr{
        ^(?:
            modules/by-module/[^/]+/./../ |
            modules/by-module/[^/]+/ |
            modules/by-category/[^/]+/[^/]+/./../ |
            modules/by-category/[^/]+/[^/]+/ |
            authors/id/./../
        )
    }x,
    leading_initials => qr{(.)/\1./},
);

# match version and suffix
$re{version_suffix} = qr{([-._]v?[0-9].*)($re{archive})};

# split into "AUTHOR/Name" and "Version"
$re{split_them} = qr{^(.+?)$re{version_suffix}$};

# matches "AUTHOR/tarball.suffix" or AUTHOR/modules/tarball.suffix
# and not other "AUTHOR/subdir/whatever"

# Just get AUTHOR/tarball.suffix from whatever file name is passed in
sub _get_base_id {
    my $file = shift;
    my $base_id = $file;
    $base_id =~ s{$re{target_dir}}{};
    return $base_id;
}

sub _base_name {
    my ($base_id) = @_;
    my $base_file = basename $base_id;
    my ($base_name, $base_version) = $base_file =~ $re{split_them};
    return $base_name;
}

#--------------------------------------------------------------------------#
# _parse_module_index
#
# parse index and return array_ref of distributions in reverse date order
#--------------------------------------------------------------------------#-

sub _parse_module_index {
    my ( $packages, $file_ls, $skip_dev_versions, $start_from_timestamp ) = @_;

    # first walk the packages list
    # and build an index

    my (%valid_bases, %valid_distros, %mirror);
    my (%latest, %latest_dev);

    my $gz = Compress::Zlib::gzopen($packages, "rb")
        or die "Cannot open package list: $Compress::Zlib::gzerrno";

    my $inheader = 1;
    while ($gz->gzreadline($_) > 0) {
        if ($inheader) {
            $inheader = 0 unless /\S/;
            next;
        }

        my ($module, $version, $path) = split;

        my $base_id = _get_base_id("authors/id/$path");

        # skip all perl-like distros
        next if $base_id =~ $re{perls};

        # skip mod_perl environment
        next if $base_id =~ $re{mod_perl};

        # skip all bundles
        next if $module =~ $re{bundle};

        $valid_distros{$base_id}++;
        my $base_name = _base_name( $base_id );
        if ($base_name) {
            $latest{$base_name} = {
                datetime => 0,
                base_id => $base_id
            };
        }
    }

    # next walk the find-ls file
    local *FH;
    tie *FH, 'CPAN::Tarzip', $file_ls;

    while ( defined ( my $line = <FH> ) ) {
        my %stat;
        @stat{qw/inode blocks perms links owner group size datetime name linkname/}
            = split q{ }, $line;

        unless ($stat{name} && $stat{perms} && $stat{datetime}) {
            next;
        }
        # skip directories, symlinks and things that aren't a tarball
        next if $stat{perms} eq "l" || substr($stat{perms},0,1) eq "d";
        next unless $stat{name} =~ $re{target_dir};
        next unless $stat{name} =~ $re{archive};

        next if $start_from_timestamp && $stat{datetime} < $start_from_timestamp;

        # skip if not AUTHOR/tarball
        # skip perls
        my $base_id = _get_base_id($stat{name});
        next unless $base_id;

        next if $base_id =~ $re{perls};

        # skip Perl6 distros: AUTHOR/Perl6/...
        next if $base_id =~ m{\A\w+/Perl6/};

        my $base_name = _base_name( $base_id );

        # if $base_id matches 02packages, then it is the latest version
        # and we definitely want it; also update datetime from the initial
        # assumption of 0
        if ( $valid_distros{$base_id} ) {
            $mirror{$base_id} = $stat{datetime};
            next unless $base_name;
            if ( $stat{datetime} > $latest{$base_name}{datetime} ) {
                $latest{$base_name} = {
                    datetime => $stat{datetime},
                    base_id => $base_id
                };
            }
        }
        # if not in the packages file, we only want it if it resembles
        # something in the package file and we only the most recent one
        else {
            # skip if couldn't parse out the name without version number
            next unless defined $base_name;

            # skip unless there's a matching base from the packages file
            next unless $latest{$base_name};

            next if $skip_dev_versions;

            # keep only the latest
            $latest_dev{$base_name} ||= { datetime => 0 };
            if ( $stat{datetime} > $latest_dev{$base_name}{datetime} ) {
                $latest_dev{$base_name} = {
                    datetime => $stat{datetime},
                    base_id => $base_id
                };
            }
        }
    }

    if ( !$start_from_timestamp ) {
        # pick up anything from packages that wasn't found in find-ls
        # usually because find-ls is updated more rarely than packages
        # as it is missing from find-ls, timestamp would be set to 0
        for my $name ( keys %latest ) {
            my $base_id = $latest{$name}{base_id};
            $mirror{$base_id} = $latest{$name}{datetime} unless $mirror{$base_id};
        }
    }

    # for dev versions, it must be newer than the latest version of
    # the same base name from the packages file

    for my $name ( keys %latest_dev ) {
        if ( ! $latest{$name} ) {
            next;
        }
        next if $latest{$name}{datetime} > $latest_dev{$name}{datetime};
        $mirror{ $latest_dev{$name}{base_id} } = $latest_dev{$name}{datetime}
    }

    return [ sort { $mirror{$b} <=> $mirror{$a} } keys %mirror ];
}

1;

# ABSTRACT: Turnkey CPAN Testers smoking

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Reporter::Smoker - Turnkey CPAN Testers smoking

=head1 VERSION

version 0.29

=head1 SYNOPSIS

     $ perl -MCPAN::Reporter::Smoker -e start

=head1 DESCRIPTION

Rudimentary smoke tester for CPAN Testers, built upon L<CPAN::Reporter>.  Use
at your own risk.  It requires a recent version of CPAN::Reporter to run.

Currently, CPAN::Reporter::Smoker requires zero independent configuration;
instead it uses configuration settings from CPAN.pm and CPAN::Reporter.

Once started, it retrieves a list of distributions from the configured CPAN
mirror and begins testing them in reverse order of upload.  It will skip any
distribution which has already had a report sent by CPAN::Reporter.

Features (or bugs, depending on your point of view):

=over

=item *

No configuration needed

=item *

Tests each distribution as a separate CPAN process -- each distribution
has prerequisites like build_requires satisfied from scratch

=item *

Automatically checks for new distributions every twelve hours or as
otherwise specified

=item *

Continues until interrupted with CTRL-C

=item *

Checks CPAN.pm "distroprefs" to see if distributions should be skipped
(before handing off to CPAN)

=back

Current limitations:

=over

=item *

Does not attempt to retest distributions that had reports discarded because
of prerequisites that could not be satisfied

=item *

Does not test trial version if there is no non-trial version

=back

=head2 WARNING -- smoke testing is risky

Smoke testing will download and run programs that other people have uploaded to
CPAN.  These programs could do B<anything> to your system, including deleting
everything on it.  Do not run CPAN::Reporter::Smoker unless you are prepared to
take these risks.

=head1 USAGE

=head2 C<<< start() >>>

Starts smoke testing using defaults already in CPAN::Config and
CPAN::Reporter's .cpanreporter directory.  Runs until all distributions are
tested or the process is halted with CTRL-C or otherwise killed.

C<<< start() >>> supports several optional arguments:

=over

=item *

C<<< clean_cache_after >>> -- number of distributions that will be tested
before checking to see if the CPAN build cache needs to be cleaned up
(not including any prerequisites tested). Must be a positive integer.
Defaults to 100

=item *

C<<< list >>> -- if provided, this list of distributions will be tested instead
of all of CPAN.  May be a reference to an array of distribution names or may
be a filename containing one distribution name per line.  Distribution names
must be of the form 'AUTHORE<sol>Dist-Name-0.00.tar.gz'

=item *

C<<< restart_delay >>> -- number of seconds that must elapse before restarting
smoke testing. This will reload indices to search for new distributions
and restart testing from the most recent distribution. Must be a positive
integer; Defaults to 43200 seconds (12 hours)

=item *

C<<< skip_dev_versions >>> -- if true, unindexed distributions will not be tested.
Valid values are 0 or 1. Defaults to 0.

=item *

C<<< set_term_title >>> -- toggle for whether the terminal titlebar will be
updated with the distribution being smoke tested and the starting time
of the test. Helps determine if a test is hung and which distribution
might be responsible.  Valid values are 0 or 1.  Defaults to 1

=item *

C<<< status_file >>> -- during testing, the name of the distribution under test
and a timestamp are written to this file. The file is removed after the
test is complete.  This helps identify a problem distribution if testing
hangs or crashes the computer. If the argument includes a path, all
directories to the file must exist. Defaults to C<<< smoker-status-$$.txt >>>
in File::Spec-E<gt>tmpdir.

=item *

C<<< install >>> -- toggle for whether the distribution should be installed
after successful testing. Can be useful to avoid prerequisite re-building
and growing PERL5LIB for the cost of disk space used for installed
modules. Valid values are 0 or 1. Defaults to 0

=item *

C<<< reverse >>> -- toggle the order in which releases are tested. When set to 1,
testing starts from the older release not the most recent one (or the last
distribution if --list is provided). Valid values are 0 or 1. Defaults to 0

=item *

C<<< random >>> -- toggle whether to randomize distribution test order. When set to 1,
the list of releases is shuffled. Valid values are 0 or 1. Defaults to 0

=item *

C<<< force_trust >>> -- toggle whether to override CPAN's
C<<< trust_test_report_history >>> option. When set to 1, C<<< trust_test_report_history >>>
is set to 1.  When set to 0, C<<< trust_test_report_history >>> is left alone and
whatever the user has configured for their CPAN client is used.
Valid values are 0 or 1. Defaults to 0

=item *

C<<< reload_history_period >>> -- after this period in seconds, history of modules
smoked will be reloaded when possible.
Default value 1800 seconds (30 minutes).

=back

=head1 HINTS

=head2 Selection of distributions to test

Only the most recently uploaded developer and normal releases will be
tested, and only if the developer release is newer than the regular release
indexed by PAUSE.

For example, if Foo-Bar-0.01, Foo-Bar-0.02, Foo-Bar-0.03_01 and Foo-Bar-0.03_02
are on CPAN, only Foo-Bar-0.02 and Foo-Bar-0.03_02 will be tested, and in
reverse order of when they were uploaded.  Once Foo-Bar-0.04 is released and
indexed, Foo-Bar-0.03_02 will not longer be tested.

To avoid testing script or other tarballs, developer distributions included
must have a base distribution name that resembles a distribution tarball
already indexed by PAUSE.  If the first upload of distribution to PAUSE is a
developer release -- Baz-Bam-0.00_01.tar.gz -- it will not be tested as there
is no indexed Baz-Bam appearing in CPAN's 02packages.details.txt file.

Unauthorized tarballs are treated like developer releases and will be tested
if they resemble an indexed distribution and are newer than the indexed
tarball.

Perl, parrot, kurila, Pugs and similar distributions will not be tested.  The
skip list is based on CPAN::Mini and matches as follows:

     qr{(?:
           /(?:emb|syb|bio)?perl-\d
         | /(?:parrot|ponie|kurila|Perl6-Pugs)-\d
         | /perl-?5\.004
         | /perl_mlb\.zip
     )}xi,

Bundles and mod_perl distributions will also not be tested, though mod_perl is
likely to be requested as a dependency by many modules.  See the next section
for how to tell CPAN.pm not to test certain dependencies.

=head2 Skipping additional distributions

If certain distributions hang, crash or otherwise cause trouble, you can use
CPAN's "distroprefs" system to disable them.  If a distribution is disabled, it
won't be built or tested.  If a distribution's dependency is disabled, a
failing test is just discarded.

The first step is configuring a directory for distroprefs files:

     $ cpan
     cpan> o conf init prefs_dir
     cpan> o conf commit

Next, ensure that either the L<YAML> or L<YAML::Syck> module is installed.
(YAML::Syck is faster).  Then create a file in the C<<< prefs_dir >>> directory
to hold the list of distributions to disable, e.g. call it C<<< disabled.yml >>>

In that file, you can add blocks of YAML code to disable distributions.  The
match criteria "distribution" is a regex that matches against the canonical
name of a distribution, e.g. C<<< AUTHOR/Foo-Bar-3.14.tar.gz >>>.

Here is a sample file to show you some syntax (don't actually use these,
though):

     ---
     comment: "Tests take too long"
     match:
         distribution: "^DAGOLDEN/CPAN-Reporter-\d"
     disabled: 1
     ---
     comment: "Skip Win32 distributions"
     match:
         distribution: "/Win32"
     disabled: 1
     ---
     comment: "Skip distributions by Andy Lester"
     match:
         distribution: "^PETDANCE"
     disabled: 1

Please note that disabling distributions like this will also disable them
for normal, non-smoke usage of CPAN.pm.

One distribution that I would recommend either installing up front or else
disabling with distroprefs is mod_perl, as it is a common requirement for many
Apache:: modules but does not (easily) build and test under automation.

     ---
     comment: "Don't build mod_perl if required by some other module"
     match:
         distribution: "/mod_perl-\d"
     disabled: 1

Distroprefs are more powerful than this -- they can be used to automate
responses to prompts in distributions, set environment variables, specify
additional dependencies and so on.  Read the docs for CPAN.pm for more and
look in the "distroprefs" directory in the CPAN distribution tarball for
examples.

=head2 Using a local CPAN::Mini mirror

Because distributions must be retrieved from a CPAN mirror, the smoker may
cause heavy network load and will repetitively download common build
prerequisites.

An alternative is to use L<CPAN::Mini> to create a local CPAN mirror and to
point CPAN's C<<< urllist >>> to the local mirror.

     $ cpan
     cpan> o conf urllist unshift file:///path/to/minicpan
     cpan> o conf commit

However, CPAN::Reporter::Smoker needs the C<<< find-ls.gz >>> file, which
CPAN::Mini does not mirror by default.  Add it to a .minicpanrc file in your
home directory to include it in your local CPAN mirror.

     also_mirror: indices/find-ls.gz

Note that CPAN::Mini does not mirror developer versions.  Therefore, a
live, network CPAN Mirror will be needed in the urllist to retrieve these.

Note that CPAN requires the LWP module to be installed to use a local CPAN
mirror.

Alternatively, you might experiment with the alpha-quality release of
L<CPAN::Mini::Devel>, which subclasses CPAN::Mini to retrieve developer
distributions (and find-ls.gz) using the same logic as
CPAN::Reporter::Smoker.

=head2 Timing out hanging tests

CPAN::Reporter (since 1.08) supports a 'command_timeout' configuration option.
Set this option in the CPAN::Reporter configuration file to time out tests that
hang up or get stuck at a prompt.  Set it to a high-value to avoid timing out a
lengthy tests that are still running  -- 1000 or more seconds is probably
enough.

Warning -- on Win32, terminating processes via the command_timeout is equivalent to
SIGKILL and could cause system instability or later deadlocks

This option is still considered experimental.

=head2 Avoiding repetitive prerequisite testing

Because CPAN::Reporter::Smoker satisfies all requirements from scratch, common
dependencies (e.g. Class::Accessor) will be unpacked, built and tested
repeatedly.

As of version 1.92_56, CPAN supports the C<<< trust_test_report_history >>> config
option.  When set, CPAN will check the last test report for a distribution.
If one is found, the results of that test are used instead of running tests
again.

     $ cpan
     cpan> o conf init trust_test_report_history
     cpan> o conf commit

=head2 Avoiding repetitive prerequisite builds (EXPERIMENTAL)

CPAN has a C<<< build_dir_reuse >>> config option.  When set (and if a YAML module is
installed and configured), CPAN will attempt to make build directories
persistent.  This has the potential to save substantial time and space during
smoke testing.  CPAN::Reporter::Smoker will recognize if this option is set
and make adjustments to the test process to keep PERL5LIB from growing
uncontrollably as the number of persistent directories increases.

B<NOTE:> Support for C<<< build_dir_reuse >>> is highly experimental. Wait for at least
CPAN version 1.92_62 before trying this option.

     $ cpan
     cpan> o conf init build_dir_reuse
     cpan> o conf commit

=head2 Stopping early if a prerequisite fails

Normally, CPAN.pm continues testing a distribution even if a prerequisite fails
to build or fails testing.  Some distributions may pass their tests even
without a listed prerequisite, but most just fail (and CPAN::Reporter discards
failures if prerequisites are not met).

As of version 1.92_57, CPAN supports the C<<< halt_on_failure >>> config option.
When set, a prerequisite failure stops further processing.

     $ cpan
     cpan> o conf init halt_on_failure
     cpan> o conf commit

However, a disadvantage of halting early is that no DISCARD grade is
recorded in the history.  The next time CPAN::Reporter::Smoker runs, the
distribution will be tested again from scratch.  It may be better to let all
prerequisites finish so the distribution can fail its test and be flagged
with DISCARD so it will be skipped in the future.

=head2 CPAN cache bloat

CPAN will use a lot of scratch space to download, build and test modules.  Use
CPAN's built-in cache management configuration to let it purge the cache
periodically if you don't want to do this manually.  When configured, the cache
will be purged on start and after a certain number of distributions have
been tested as determined by the C<<< clean_cache_after >>> option for the
C<<< start() >>> function.

     $ cpan
     cpan> o conf init build_cache scan_cache
     cpan> o conf commit

=head2 CPAN verbosity

Recent versions of CPAN are verbose by default, but include some lesser
known configuration settings to minimize this for untarring distributions and
for loading support modules.  Setting the verbosity for these to 'none' will
minimize some of the clutter to the screen as distributions are tested.

     $ cpan
     cpan> o conf init /verbosity/
     cpan> o conf commit

=head2 Saving reports to files instead of sending directly

In some cases, such as when smoke testing using a development or prerelease
toolchain module like Test-Harness, it may be preferable to save reports to
files in a directory for review prior to submitting them.  To do this,
manually set the C<<< transport >>> option in your CPAN::Reporter config file to use
the L<Test::Reporter::Transport::File> transport.

     transport=File /path/to/directory

After review, send saved reports using Test::Reporter:

     Test::Reporter->new()->read($filename)->send()

=head1 ENVIRONMENT

Automatically sets the following environment variables to true values
while running:

=over

=item *

C<<< AUTOMATED_TESTING >>> -- signal that tests are being run by an automated
smoke testing program (i.e. don't expect interactivity)

=item *

C<<< PERL_MM_USE_DEFAULT >>> -- accept L<ExtUtils::MakeMaker> prompt() defaults

=item *

C<<< PERL_EXTUTILS_AUTOINSTALL >>> -- set to '--defaultdeps' for default
dependencies

=back

The following environment variables, if set, will modify the behavior of
CPAN::Reporter::Smoker.  Generally, they are only required during the
testing of CPAN::Reporter::Smoker

=over

=item *

C<<< PERL_CR_SMOKER_RUNONCE >>> -- if true, C<<< start() >>> will exit after all
distributions are tested instead of sleeping for the C<<< restart_delay >>>
and then continuing

=item *

C<<< PERL_CR_SMOKER_SHORTCUT >>> -- if true, C<<< start() >>> will process arguments (if
any) but will return before starting smoke testing; used for testing argument
handling by C<<< start() >>>

=back

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Reporter-Smoker>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 SEE ALSO

=over

=item *

L<CPAN>

=item *

L<CPAN::Reporter>

=item *

L<CPAN::Testers>

=item *

L<CPAN::Mini>

=item *

L<CPAN::Mini::Devel>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/cpan-testers/CPAN-Reporter-Smoker/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/cpan-testers/CPAN-Reporter-Smoker>

  git clone https://github.com/cpan-testers/CPAN-Reporter-Smoker.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alexandr Ciornii Christian Walde gregor herrmann

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

gregor herrmann <gregoa@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
