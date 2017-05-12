###########################################
package Cvs::Trigger;
###########################################

use strict;
use warnings;
use File::Spec;
use Log::Log4perl qw(:easy);
use Data::Dumper;
use Cache::FileCache;
use Storable qw(freeze thaw);
use POSIX;

our $VERSION = "0.04";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        routines => { 'commitinfo' => \&commitinfo,
                      'loginfo'    => \&loginfo,
                      'verifymsg'  => \&verifymsg,
                    },
        cache_default_expires_in  => 3600,
        cache_auto_purge_interval => 1800,
        cache_namespace           => "cvs",
        %options,
    };

    if($self->{cache}) {
        $self->{file_cache} = Cache::FileCache->new({
                namespace           => $self->{cache_namespace},
                default_expires_in  => $self->{cache_default_expires_in},
                auto_purge_interval => $self->{cache_auto_purge_interval},
        });
    }

    bless $self, $class;
}

###########################################
sub parse {
###########################################
    my($self, $type, $opts) = @_;

    $type = $self->{type} unless defined $type;
    LOGDIE "No type defined" unless defined $type;

    if(exists $self->{routines}->{$type}) {
        DEBUG "Running $type (pid=$$ ppid=", getppid(), ")";
        $self->{routines}->{$type}->($self, $opts);
    } else {
        LOGDIE "Unknown type: $type";
    }
}

###########################################
sub commitinfo {
###########################################
    my($self, $opts) = @_;

    $opts ||= {};
    my $n_opt_args = ($opts->{n_opt_args} || 0);
    my $trigger = "commitinfo";
    my @nargv   = @ARGV[$n_opt_args .. $#ARGV];

    if(@nargv < 2) {
        LOGDIE "Argument error: $trigger expects at least 2 parameters ",
               "(got @nargv)";
    }

    my($repo_dir, @files) = @nargv;
    my @opts              = @ARGV[1 .. $n_opt_args-2];

    my $res = {
        repo_dir => $repo_dir,
        files    => \@files,
        opts     => \@opts,
        trigger  => $trigger,
        argv     => \@nargv,
    };

    if($self->{file_cache}) {
        $self->_cache_set($repo_dir, @files);
    }

    DEBUG "$trigger return parameters: ", Dumper($res);

    return $res;
}

###########################################
sub verifymsg {
###########################################
    my($self) = @_;

    DEBUG "Running verifymsg ($$ ", getppid(), ")";

    if(@ARGV < 1) {
        LOGDIE "Argument error: verifymsg expects at least 1 parameter";
    }

    my $tmp_file = $ARGV[-1];

    my $data = _slurp($tmp_file);

    my @opts = ();
    @opts = @ARGV[1 .. $#ARGV-1] if @ARGV > 1;

    my $res = {
        opts    => \@opts,
        message => $data,
    };

    if($self->{cache}) {
        $res->{cache} = $self->_cache_get();

        my $ttl = $self->_cache_ttl_dec();

        if($ttl < 1) {
            DEBUG "ttl=$ttl: Removing the cache for ", getppid();
            $self->{file_cache}->remove(getppid());
        } else {
            # Don't remove it yet, this could be a multi-dir check-in and
            # another verifymsg might be following and still rely on the cache.
            DEBUG "ttl=$ttl: Keeping the cache";
        }
    }

    DEBUG "verifymsg parameters: ", Dumper($res);
    return $res;
}

#2006/04/08 13:29:22 argv=verifymsg /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Slurping data from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Read (7)[foobar.] from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 data=foobar
#2006/04/08 13:29:22 Slurping data from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 Read (7)[foobar.] from /tmp/cvsDYgcCY
#2006/04/08 13:29:22 msg=foobar
#2006/04/08 13:29:22 pid=20651 ppid=20644

###########################################
sub loginfo {
###########################################
    my($self, $opts) = @_;

    $opts ||= {};
    my $rev_fmt = ($opts->{rev_fmt} || undef);

    my @opts = @ARGV;

    my $data = join '', <STDIN>;

    DEBUG "Running loginfo ($$ ", getppid(), "): argv=[@ARGV] data=[$data]";

    my $res = {
        opts    => \@opts,
    };

    $self->loginfo_message_parse($data, $res, $rev_fmt);

    DEBUG "loginfo returns ", Dumper($res);

    return $res;
}

###########################################
sub loginfo_message_parse {
###########################################
    my($self, $data, $res, $rev_fmt) = @_;

    DEBUG "Parsing $data";

    if(defined $rev_fmt) {
        if($rev_fmt ne "sVv") {
            LOGDIE "For now, only 'sVv' is supported ",
                   "as a revision info format (got '$rev_fmt')";
        }
            # Extract/remove first line
        my($line) = ($data =~ /(.*)/);
        $data =~ s/(.*)\n//;

        DEBUG "Extracted revision line $line";

        my($path, @fields) = split ' ', $line;
        for(@fields) {
            my($file, $rev1, $rev2) = split /,/, $_;
            $res->{revs}->{$file} = [$rev1, $rev2];
        }
    }

    if($data =~
         m#Update\sof\s(.*)\n
           In\sdirectory\s(.*?):(.*)\n\n
          #x) {
        $res->{repo_dir}  = $1;
        $res->{host}      = $2;
        $res->{local_dir} = $3;
    }

    if($data =~ m#Modified\sFiles:\n#gx) {
        while($data =~ /^\s+(.*)/mg) {
            my @files = split ' ', $1;
            push @{ $res->{files} }, @files;
        }
    }

    if($data =~ m#Log\sMessage:\n(.*)#sgx) {
        $res->{message} = $1;
    }

    return $res;
}

#Update of /tmp/vHmsem4xFV/cvsroot/m/a
#In directory mybox:/tmp/vHmsem4xFV/local_root/m/a
#
#Modified Files:
#       a1.txt
#Log Message:
#m/a/a1.txt-check-in-message

#2006/04/08 13:29:22 argv=loginfo
#2006/04/08 13:29:22 pid=20656 ppid=20653
#2006/04/08 13:29:22 stdin: a txt,1.20,1.21
#2006/04/08 13:29:22 stdin: Update of /home/mschilli/testcvs/a
#2006/04/08 13:29:22 stdin: In directory mybox:/mnt/big2/mschilli.do.not.delete/tmp/a
#2006/04/08 13:29:22 stdin: 
#2006/04/08 13:29:22 stdin: Modified Files:
#2006/04/08 13:29:22 stdin:      txt 
#2006/04/08 13:29:22 stdin: Log Message:
#2006/04/08 13:29:22 stdin: foobar
#2006/04/08 13:29:22 stdin: 

###########################################
sub _slurp {
###########################################
    my($file) = @_;

    local $/ = undef;

    open FILE, "<$file" or
        LOGDIE "Cannot open $file ($!)";
    my $data = <FILE>;
    close FILE;

    return $data;
}

#2006/04/08 13:29:11 argv=commitinfo /home/mschilli/testcvs/a txt
#2006/04/08 13:29:11 Slurping data from /home/mschilli/testcvs/a
#2006/04/08 13:29:11 Read (0)[] from /home/mschilli/testcvs/a
#2006/04/08 13:29:11 data=
#2006/04/08 13:29:11 pid=20645 ppid=20644
#

###########################################
sub _cache_set {
###########################################
    my($self, $repo_dir, @files) = @_;

    my $ppid = getppid();

    my $cdata = $self->_cache_get();

    for my $file (@files) {
        DEBUG "Caching $repo_dir/$file under ppid=$ppid";

        push @{ $cdata->{$repo_dir} }, $file;
    }
    $cdata->{_ttl} += 1;
    DEBUG "Setting $ppid cache to ", Dumper($cdata);
    $self->{file_cache}->set($ppid, freeze $cdata);
}

###########################################
sub _cache_ttl_dec {
###########################################
    my($self) = @_;

    my $ppid = getppid();

    my $cdata = $self->_cache_get();
    $cdata->{_ttl}--;

    $self->{file_cache}->set($ppid, freeze $cdata);

    return $cdata->{_ttl};
}

###########################################
sub _cache_get {
###########################################
    my($self) = @_;

    my $ppid = getppid();

    my $cdata;

    if(my $c = $self->{file_cache}->get($ppid)) {
        DEBUG "Cache hit on ppid=$ppid";
        $cdata = thaw $c;
    } else {
        DEBUG "Cache miss on ppid=$ppid";
        $cdata = { _ttl => 0 };
    }

    return $cdata;
}

###########################################
package Cvs::Temp;
###########################################
use strict;
use warnings;
use File::Temp qw(tempdir);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
use Cwd;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        dir => tempdir(CLEANUP => 1),
        %options,
    };

    $self->{cvsroot}     = "$self->{dir}/cvsroot";
    $self->{local_root}  = "$self->{dir}/local_root";
    $self->{out_dir}     = "$self->{dir}/out_dir";
    $self->{bin_dir}     = "$self->{dir}/bin";

    mkd $self->{local_root};
    mkd $self->{out_dir};
    mkd $self->{bin_dir};

    DEBUG "tempdir = $self->{dir}";

    $self->{cvs_bin}  = bin_find("cvs") unless defined $self->{cvs_bin};
    $self->{perl_bin} = bin_find("perl") unless 
                        defined $self->{perl_bin};

    if(! defined $self->{cvs_bin}) {
        LOGDIE "Cannot find 'cvs' binary in your PATH.";
    }

    my($stdout, $stderr, $rc) = tap $self->{cvs_bin}, "-v";
    if($rc == 0 and $stdout =~ /(\d+\.\d+)/) {
        $self->{cvs_version} = $1;
    } else {
        LOGDIE "Cannot determine CVS version ($stderr)";
    }

    bless $self, $class;

    return $self;
}

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->cvs_cmd("init");
    DEBUG "New cvs created in $self->{cvsroot}";

    cd $self->{local_root};
    $self->cvs_cmd("co", "CVSROOT");
    cdback;
}

###########################################
sub test_trigger_code {
###########################################
    my($self, $type, $cache, $parse_opt) = @_;

    my $script = <<'EOT';
_shebang_
use lib '_cwd_/blib/lib';
use lib '_cwd_/blib/arch';
use Cvs::Trigger qw(:all);
use YAML qw(DumpFile);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ level => $DEBUG, file => ">>_logfile_",
        layout => "%F{1}-%L: %m%n" });
DEBUG "_type_ trigger starting @ARGV";
my $c = Cvs::Trigger->new(_cache_);
my $ret = $c->parse("_type_", _parse_opt_);
my $count = 1;
while(-f "_tmpfile_.$count") {
    $count++;
}
DEBUG "Creating _tmpfile_.$count";
DumpFile "_tmpfile_.$count", $ret;
EOT

    my $shebang = "#!" . $self->{perl_bin};
    $script =~ s/_shebang_/$shebang/g;

    $script =~ s#_tmpfile_#$self->{out_dir}/trigger.yml#g;
    $script =~ s#_cwd_#cwd()#ge;
    $script =~ s#_logfile_#$self->{out_dir}/log#g;
    $script =~ s/_type_/$type/g;
    if($cache) {
        $script =~ s/_cache_/cache => 1/g;
    } else {
        $script =~ s/_cache_//g;
    }

    if($parse_opt) {
        $script =~ s/_parse_opt_/$parse_opt/g;
    } else {
        $script =~ s/_parse_opt_/undef/g;
    }

    DEBUG "Test trigger code: $script";

    return $script;
}

###########################################
sub module_import {
###########################################
    my($self) = @_;

    DEBUG "Importing module";

    cd $self->{local_root};

    mkd "m/a/b";
    blurt "a1text", "m/a/a1.txt";
    blurt "a2text", "m/a/a2.txt";
    blurt "btext",  "m/a/b/b.txt";

    cd "m";
    $self->cvs_cmd("import", "-m", "msg", "m", "tag1", "tag2");
    cdback;

    cd $self->{local_root};
    rmf "m";
    cdback;

    $self->cvs_cmd("co", "m");
    cdback;
}

###########################################
sub files_commit {
###########################################
    my($self, @files) = @_;

    my $dir = $self->{local_root};
    cd $dir;

    for my $file (@files) {
        blurt rand(1E10), $file;
    }
    $self->cvs_cmd("commit", "-m", "@files-check-in-message", @files);

    cdback;
}

###########################################
sub single_file_commit {
###########################################
    my($self, $content, $file, $message) = @_;

    my $dir = $self->{local_root};
    cd $dir;

    blurt $content, $file;
    $self->cvs_cmd("commit", "-m", $message, $file);

    cdback;
}

###########################################
sub admin_rebuild {
###########################################
    my($self) = @_;

    my $dir = "$self->{local_root}/CVSROOT";
    cd $dir;

    $self->cvs_cmd("commit", "-m", "admin rebuild", ".");

    cdback;
}

###########################################
sub cvs_cmd {
###########################################
    my($self, @cmd) = @_;

    unshift @cmd, $self->{cvs_bin}, "-d", $self->{cvsroot};
    DEBUG "Running CVS command @cmd";

    my($stdout, $stderr, $rc) = tap @cmd;

    if($rc) {
        LOGDIE "@cmd failed: $stderr";
    }

    if($stderr) {
        ERROR "cvs cmd warning $stderr";
    }

    DEBUG "@cmd succeeded: $stdout";
}


###########################################
sub loginfo_line {
###########################################
    my($self, $script) = @_;

    # The CVS folks had the glorious idea to change the loginfo format
    # in 1.12 in a non-backward-compatible way. What were they thinking?
    if($self->{cvs_version} < 1.12) {
        return "DEFAULT ((echo %{sVv}; cat) | $script)";
    }

    return "DEFAULT ((echo %1{sVv}; cat) | $script)";
}

###########################################
sub latest_yml {
###########################################
    my($self, $index) = @_;

    my $dir = $self->{out_dir};
    my @ymls = sort { -M $b <=> -M $a } <$dir/trigger.yml.*>;

    $index = -1 unless defined $index;

    return $ymls[$index];
}

1;

__END__

=head1 NAME

Cvs::Trigger - Argument parsers for CVS triggers

=head1 SYNOPSIS

    # CVSROOT/commitinfo
    DEFAULT /path/trigger

    # /path/trigger
    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();
    my $args = $c->parse("commitinfo");

    if( $args->{repo_dir} =~ m#/secret$#) {
        die "You can't check stuff into the secret project";
    }

    for my $file (@{ $args->{files} }) {
        if( $file =~ /\.doc$/ ) {
            die "Sorry, we don't allow .doc files in CVS";
        }
    }

=head1 DESCRIPTION

CVS provides three different hooks to intercept check-ins. They can be used
to approve/reject check-ins or to take action, like logging the check-in
in a database.

=over 4

=item C<commitinfo>

Gets executed before the check-in happens. If it returns a false value
(usually caused by calling C<die()>), the check-in gets rejected.

The following entry in the CVS admin file C<commitinfo> calls the hook
for all check-ins:

    # CVSROOT/commitinfo
    ALL /path/cvstrig

The corresponding script, C</path/cvstrig>, parses the arguments which 
C<cvs> passes to them:

    # /path/cvstrig
    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();
    my $args = $c->parse("commitinfo");

Note that you need to specify the hook name to the C<parse> method, because
CVS provides the different hooks with different parameters. In case of
the C<commitinfo> hook, the following parameters are available as keys
into the has referenced by C<$args>:

=over 4

=item C<repo_dir>

Full path to the repository directory where the check-in happens, e.g.
C</cvsroot/foo/bardir>.

=item C<files>

Reference to an array of filenames involved the check-in. No path
information is provided, all files are relative to the C<repo_dir>
directory.

=item C<opts>

Additionally, optional parameters passed to the trigger script are available
with this parameter. Note that 
the number of these parameters needs to be passed to the C<parse> method:

    # CVSROOT/commitinfo
    ALL /path/cvstrig foo bar

    # /path/cvstrig
    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();
    my $args = $c->parse("commitinfo", { n_opt_args => 2 });

        # => "foo-bar"
    print join('-', @{ $args->{opts} }), "\n";

=back

=item C<verifymsg>

Gets executed right after the user entered the check-in message. Based on
the message text, the check-in can be approved or rejected.

This hook is typically used to enforce a certain format or content of the
log message provided by the user.

Here's an example that checks if the check-in message references a bug number:

    # CVSROOT/verifymsg
    DEFAULT /path/checkin-verifier

    # /path/checkin-verifier
    #!/usr/bin/perl
    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();
    my $args = $c->parse("verifymsg");
    
    if( $args->{message} =~ m(fixes bug #)) {
        die "No bug number specified";
    }

C<verifymsg> provides the message, accessible by the C<message> key
in the hash ref returned by the C<parse> method. Additionally, the 
C<opts> key provides a list of optional parameters passed to the script
(check C<commitinfo> for details).

=item C<loginfo>

Gets executed after the check-in succeeded. It doesn't matter if the 
corresponding script fails or not, the check-in has already happend
by the time it gets called.

An entry like

   DEFAULT /path/string

will call the loginfo script with the following data on STDIN:

    Update of /cvsroot/m/a
    In directory mybox:/local_root/m/a
    
    Modified Files:
           a1.txt
    Log Message:
    Fixing some bug, forgot which one. Yay!

There's no need to parse this, though, C<Cvs::Trigger> will do that for you.
The following hash keys are available:

=over 4

=item C<repo_dir>

Full path to the repository directory where the check-in happens, e.g.
C</cvsroot/foo/bardir>.

=item C<host>

Name of the host where the check-in has been initiated.

=item C<local_dir>

The directory in the user's workspace where the check-in got initiated.

=item C<message>

Check-in message.

=item C<files>

Reference to an array of filenames involved the check-in. No path
information is provided, all files are relative to the C<repo_dir>
directory.

=back

C<loginfo> scripts can get additional data from C<cvs>. For this to
happen, the call syntax in the C<loginfo> administration
file needs to change to this format:

   DEFAULT ((echo %{sVv}; cat) | /path/script)

The first line piped into the script's STDIN then consists of the file name,
the previous and the new revision number, all space-separated (oh well, this
seems to have been invented before spaces in file names came around):

    module/path file1.txt,1.3,1.4 file2,1.1,1.2
    Update of /tmp/RgNSQ4Yomr/cvsroot/module/path
    In directory mybox:/tmp/RgNSQ4Yomr/local_root/module/path

    Modified Files:
        file1.txt file2.txt
    Log Message:
        Here are my check-in notes.

In order to parse this enhanced format, the call to 
C<Cvs::Trigger>'s C<parse> method needs to be modified:

    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();
    my $args = $c->parse("verifymsg", { rev_fmt => "sVv" });

The result in args will then store the file names and their revisions
under the C<revs> key:

    use Data::Dumper;
    print Dumper($args->{revs});

        # $VAR1 = { file1.txt => [1.3, 1.4]
                    file2.txt => [1.1, 1.2]
                  }

=back

=head2 Use the same script for multiple hooks

You can call the same trigger script in multiple hooks. Since the parameters
passed to the script vary from hook to hook, the easiest solution is 
to pass the hook name on to the script, so that it can switch the command
argument parser accordingly:

    # CVSROOT/commitinfo
    DEFAULT /path/trigger commitinfo

    # CVSROOT/verifymsg
    DEFAULT /path/trigger verifymsg

    #!/usr/bin/perl
    use Cvs::Trigger;
    my $c = Cvs::Trigger->new();

    my $hook = shift;

       # First argument specifies the parser
    my $args = $c->parse( $hook );
    
    if( $hook eq "verifymsg" ) { 
        if( $args->{message} =~ m(fixes bug #)) {
            die "No bug number specified";
        }
    } 
    elsif( $hook eq "commitinfo" ) { 
        if( $args->{repo_dir} =~ m#/secret$#) {
            die "You can't check stuff into the secret project";
        }
    }

=head2 Remember fields by caching

THIS FEATURE IS EXPERIMENTAL. USE AT YOUR OWN RISK.

If you want to make a decision based on both the file name and the 
check-in message, none of the hooks provides all necessary information
in one swoop. If, say, C<.c> files need a bug number in their check-in
message and C<.txt> don't, here's a tricky way to forward the filenames
parsed by C<commitinfo> to the C<verifymsg> hook, which has the check-in
message available:

    # CVSROOT/commitinfo
    DEFAULT /path/trigger commitinfo

    # CVSROOT/verifymsg
    DEFAULT /path/trigger verifymsg

    #!/usr/bin/perl
    use Cvs::Trigger;

        # Turn on the cache
    my $c = Cvs::Trigger->new( cache => 1 );

    my $hook = shift;

       # First argument specifies the parser
    my $args = $c->parse( $hook );
    
    if( $hook eq "verifymsg" ) { 
        # We're in verifymsg now, but the cache still holds the file
        # names obtained in the commitinfo phase
        if( grep { /\.c$/ } @{ $args->{cache}->{files} } and
            $args->{message} =~ m(fixes bug #) ) {
            die "No bug number specified in .c file";
        }
    } 

Caching has a couple of gotchas, though. First, items can only stay
in the cache for a limited time, to avoid a cache overflow with many
simultaneous checkins going on.

However, the time span between C<commitinfo> and C<verifymsg> can hardly 
be estimated accurately. What if someone types "cvs commit" and then
goes to lunch? The editor window will stay open, and if the message
gets saved a couple of hours later, the cache still needs to hold a copy
of the C<commitinfo> data.

Deleting the cache data once C<verifymsg> is done with it doesn't work either.
If you type "cvs commit" in a directory with multiple subdirectories,
both the C<commitinfo> and C<verifymsg> will get called for each subdirectory
containing modified files. C<Cvs::Trigger> therefore maintains a TTL
(time to live) counter to keep track of how many instances of C<verifymsg>
are still going to read it. Bottom line: The cache entry will be deleted once
the last C<verifymsg> instance is done with it.

Nevertheless, determining the cache timeout is a delicate issue. The
default values are set as follows:

        # Turn on the cache
    my $c = Cvs::Trigger->new(
       cache                     => 1,
       cache_default_expires_in  => 3600,
       cache_auto_purge_interval => 1800,
       cache_namespace           => "cvs",
    );

Therefore, the cache will expire entries after an hour and it will run the
check/prune procedure every half hour. To set different values, simply call
C<new> with different parameters. The cache namespace can also be configured,
see the L<Cache::Cache> manual page for details.

The cache makes use of the fact that the C<commitinfo> and C<verifymsg> scripts
are run by processes sharing the same parent pid (ppid). The cache indexes
its data using this pid value. If the operating system reuses the same 
pid within the expiration timeframe, a clash will occur.

=head1 TODO List

    * Try filenames with commas, spaces, and newlines
    * tests for optional arguments
    * methods vs. hash access
    * no STDIN on loginfo => hangs

=head1 SEE ALSO

http://ximbiot.com/cvs/wiki/index.php?title=CVS--Concurrent_Versions_System_v1.12.12.1:_Reference_manual_for_Administrative_files#SEC184

=head1 LEGALESE

Copyright 2006 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2006, Mike Schilli <m@perlmeister.com>
