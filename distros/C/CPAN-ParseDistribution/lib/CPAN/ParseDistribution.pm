package CPAN::ParseDistribution;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.54';

use Cwd qw(getcwd abs_path);
use File::Temp qw(tempdir);
use File::Find::Rule;
use File::Path;
use Data::Dumper;
use Archive::Tar;
use Archive::Zip;
use YAML qw(LoadFile);
use Safe;
use Parallel::ForkManager;
use Devel::CheckOS qw(os_is);

$Archive::Tar::DO_NOT_USE_PREFIX = 1;
$Archive::Tar::CHMOD = 0;

=head1 NAME

CPAN::ParseDistribution - index a file from the BackPAN

=head1 DESCRIPTION

Given a file from the BackPAN, this will let you find out what versions
of what modules it contains, the distribution name and version

=head1 SYNOPSIS

    my $dist = CPAN::ParseDistribution->new(
        'A/AU/AUTHORID/subdirectory/Some-Distribution-1.23.tar.gz',
        use_tar => '/bin/tar',
        ...
    );
    my $modules     = $dist->modules(); # hashref of modname => version
    my $distname    = $dist->dist();
    my $distversion = $dist->distversion();

=head1 METHODS

=head2 new

Constructor, takes a single mandatory argument, which should be a tarball
or zip file from the CPAN or BackPAN, and some optional named arguments:

=over

=item use_tar

The full path to 'tar'.  This is assumed to be GNU tar, and to be
sufficiently well-endowed as to be able to support bzip2 files.
Maybe I'll fix that at some point.  If this isn't specified, then
Archive::Tar is used instead.

You might want to use this if dealing with very large files, as
Archive::Tar is rather profligate with memory.

=back

=cut

sub new {
    my($class, $file, %extra_params) = @_;
    die("file parameter is mandatory\n") unless($file);
    die("$file doesn't exist\n") if(!-e $file);
    die("$file looks like a ppm\n")
        if($file =~ /\.ppm\.(tar(\.gz|\.bz2)?|tbz|tgz|zip)$/i);
    die("$file isn't the right type\n")
        if($file !~ /\.(tar(\.gz|\.bz2)?|tbz|tgz|zip)$/i);
    $file = abs_path($file);

    # dist name and version
    (my $dist = $file) =~ s{(^.*/|\.(tar(\.gz|\.bz2)?|tbz|tgz|zip)$)}{}gi;
    $dist =~ /^(.*)-(\d.*)$/;
    ($dist, my $distversion) = ($1, $2);
    die("Can't index perl itself ($dist-$distversion)\n")
        if($dist =~ /^(perl|ponie|kurila|parrot|Perl6-Pugs|v6-pugs)$/);

    bless {
        file    => $file,
        modules => {},
        dist    => $dist,
        distversion => $distversion,
        extra_params => \%extra_params,
    }, $class;
}

# takes a filename, unarchives it, returns the directory it's been
# unarchived into
sub _unarchive {
    my($file, %extra_params) = @_;
    my $olddir = getcwd();
    my $tempdir = tempdir(TMPDIR => 1);
    chdir($tempdir);
    if($file =~ /\.zip$/i) {
        my $zip = Archive::Zip->new($file);
        $zip->extractTree() if($zip);
    } elsif($file =~ /\.(tar(\.gz)?|tgz)$/i) {
        if($extra_params{use_tar}) {
            system(
                $extra_params{use_tar},
                (($file =~ /gz$/) ? 'xzf' : 'xf'),
                $file
            );
            system("chmod -R u+r *"); # tar might preserve unreadable perms
        } else {
            my $tar = Archive::Tar->new($file, 1);
            $tar->extract() if($tar);
        }
    } else {
        if($extra_params{use_tar}) {
            system( $extra_params{use_tar}, 'xjf', $file);
            system("chmod -R u+r *");
        } else {
            open(my $fh, '-|', qw(bzip2 -dc), $file) || die("Can't unbzip2\n");
            my $tar = Archive::Tar->new($fh);
            $tar->extract() if($tar);
        }
    }
    chdir($olddir);
    return $tempdir;
}

# adapted from PAUSE::pmfile::parse_version_safely in mldistwatch.pm
sub _parse_version_safely {
    my($parsefile) = @_;
    my $result;
    my $eval;
    local $/ = "\n";
    open(my $fh, $parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<$fh>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        chop;
        next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
        my($sigil, $var) = ($1, $2);
        my $current_parsed_line = $_;
        {
            local $^W = 0;
            no strict;
            my $c = Safe->new();
            $c->deny(qw(
                 tie untie tied chdir flock ioctl socket getpeername
                 ssockopt bind connect listen accept shutdown gsockopt
                 getsockname sleep alarm entereval reset dbstate
                 readline rcatline getc read formline enterwrite
                 leavewrite print sysread syswrite send recv eof
                 tell seek sysseek readdir telldir seekdir rewinddir
                 lock stat lstat readlink ftatime ftblk ftchr ftctime
                 ftdir fteexec fteowned fteread ftewrite ftfile ftis
                 ftlink ftmtime ftpipe ftrexec ftrowned ftrread ftsgid
                 ftsize ftsock ftsuid fttty ftzero ftrwrite ftsvtx
                 fttext ftbinary fileno ghbyname ghbyaddr ghostent
                 shostent ehostent gnbyname gnbyaddr gnetent snetent
                 enetent gpbyname gpbynumber gprotoent sprotoent
                 eprotoent gsbyname gsbyport gservent sservent
                 eservent  gpwnam gpwuid gpwent spwent epwent
                 getlogin ggrnam ggrgid ggrent sgrent egrent msgctl
                 msgget msgrcv msgsnd semctl semget semop shmctl
                 shmget shmread shmwrite require dofile caller
                 syscall dump chroot link unlink rename symlink
                 truncate backtick system fork wait waitpid glob
                 exec exit kill time tms mkdir rmdir utime chmod
                 chown fcntl sysopen open close umask binmode
                 open_dir closedir 
            ), ($] >= 5.010 ? qw(say) : ()));
            $c->share_from(__PACKAGE__, [qw(qv)]);
            s/\buse\s+version\b.*?;//gs;
            # qv broke some time between version.pm 0.74 and 0.82
            # so just extract it and hope for the best
            s/\bqv\s*\(\s*(["']?)([\d\.]+)\1\s*\)\s*/"$2"/;
            s/\buse\s+vars\b//g;
            $eval = qq{
                local ${sigil}${var};
                \$$var = undef; do {
                    $_
                }; \$$var
            };

            $result = _run_safely($c, $eval);
        };
        # stuff that's my fault because of the Safe compartment
        if($result->{error} && $result->{error} =~ /trapped by operation mask|safe compartment timed out/i) {
            warn("Unsafe code in \$VERSION\n".$result->{error}."\n$parsefile\n$eval");
            $result = undef;
        } elsif($result->{error}) {
            warn "_parse_version_safely: ".Dumper({
                eval => $eval,
                line => $current_parsed_line,
                file => $parsefile,
                err  => $result->{error},
            });
        }
        last;
    }
    close $fh;

    return exists($result->{result}) ? $result->{result} : undef;
}

sub _run_safely {
    if(os_is('Unix')) {
        eval 'use CPAN::ParseDistribution::Unix';
        return CPAN::ParseDistribution::Unix->_run(@_);
    } elsif(os_is('MicrosoftWindows')) {
        # FIXME once someone supplies CPAN::ParseDistribution::Windows
        warn("Windows is not fully supported by CPAN::ParseDistribution\n");
        warn("See the LIMITATIONS section in the documentation\n");
        eval 'use CPAN::ParseDistribution::Unix';
        return CPAN::ParseDistribution::Unix->_run(@_);
    }
}

=head2 isdevversion

Returns true or false depending on whether this is a developer-only
or trial release of a distribution.  This is determined by looking for
an underscore in the distribution version or the string '-TRIAL' at the
end of the distribution version.

=cut

sub isdevversion {
    my $self = shift;
    return 1 if($self->distversion() =~ /(_|-TRIAL$)/);
    return 0;
}

=head2 modules

Returns a hashref whose keys are module names, and their values are
the versions of the modules.  The version number is retrieved by
eval()ing what looks like a $VERSION line in the code.  This is done
in a C<Safe> compartment, but may be a security risk if you do this
with untrusted code.  Caveat user!

=cut

sub modules {
    my $self = shift;
    if(!(keys %{$self->{modules}})) {
        $self->{_modules_runs}++;
        my $tempdir = _unarchive($self->{file}, %{$self->{extra_params}});

        my $meta = (File::Find::Rule->file()->name('META.yml')->in($tempdir))[0];
        my $ignore = join('|', qw(t inc xt));
        my %ignorefiles;
        my %ignorepackages;
        my %ignorenamespaces;
        if($meta && -e $meta) {
            my $yaml = eval { LoadFile($meta); };
            if(!$@ &&
                # can we hash-deref this thing?
		ref($yaml) eq 'HASH' && 
                exists($yaml->{no_index}) &&
		ref($yaml->{no_index}) eq 'HASH'
            ) {
                if(exists($yaml->{no_index}->{directory})) {
                    if(ref($yaml->{no_index}->{directory}) eq 'ARRAY') {
                        $ignore = join('|', $ignore,
                            map { "$_/" } @{$yaml->{no_index}->{directory}}
                        );
                    } elsif(!ref($yaml->{no_index}->{directory})) {
                         $ignore .= '|'.$yaml->{no_index}->{directory}.'/'
                    }
                }
                if(exists($yaml->{no_index}->{file})) {
                    if(ref($yaml->{no_index}->{file}) eq 'ARRAY') {
                        %ignorefiles = map { $_, 1 }
                            @{$yaml->{no_index}->{file}};
                    } elsif(!ref($yaml->{no_index}->{file})) {
                         $ignorefiles{$yaml->{no_index}->{file}} = 1;
                    }
                }
                if(exists($yaml->{no_index}->{package})) {
                    if(ref($yaml->{no_index}->{package}) eq 'ARRAY') {
                        %ignorepackages = map { $_, 1 }
                            @{$yaml->{no_index}->{package}};
                    } elsif(!ref($yaml->{no_index}->{package})) {
                         $ignorepackages{$yaml->{no_index}->{package}} = 1;
                    }
                }
                if(exists($yaml->{no_index}->{namespace})) {
                    if(ref($yaml->{no_index}->{namespace}) eq 'ARRAY') {
                        %ignorenamespaces = map { $_, 1 }
                            @{$yaml->{no_index}->{namespace}};
                    } elsif(!ref($yaml->{no_index}->{namespace})) {
                         $ignorenamespaces{$yaml->{no_index}->{namespace}} = 1;
                    }
                }
            }
        }
        # find modules
        my @PMs = grep {
            my $pm = $_;
            $pm !~ m{^\Q$tempdir\E/[^/]+/($ignore)} &&
            !grep { $pm =~ m{^\Q$tempdir\E/[^/]+/$_$} } (keys %ignorefiles)
        } File::Find::Rule->file()->name('*.pm', '*.pm.PL')->in($tempdir);
        foreach my $PM (@PMs) {
            local $/ = undef;
            my $version = _parse_version_safely($PM);
            open(my $fh, $PM) || die("Can't read $PM\n");
            $PM = <$fh>;
            close($fh);

            # from PAUSE::pmfile::packages_per_pmfile in mldistwatch.pm
            if($PM =~ /\bpackage[ \t]+([\w\:\']+)\s*($|[};])/) {
                my $module = $1;
                $self->{modules}->{$module} = $version unless(
                    exists($ignorepackages{$module}) ||
                    (grep { $module =~ /${_}::/ } keys %ignorenamespaces)
                );
            }
        }
        rmtree($tempdir);
    }
    return $self->{modules};
}

=head2 dist

Return the name of the distribution. eg, in the synopsis above, it would
return 'Some-Distribution'.

=cut

sub dist {
    my $self = shift;
    return $self->{dist};
}

=head2 distversion

Return the version of the distribution. eg, in the synopsis above, it would
return 1.23.

Strictly speaking, the CPAN doesn't have distribution versions -
Foo-Bar-1.23.tar.gz is not considered to have any relationship to
Foo-Bar-1.24.tar.gz, they just happen to coincidentally have rather
similar contents.  But other tools, such as those used by the CPAN testers,
do treat distributions as being versioned.

=cut

sub distversion{
    my $self = shift;
    return $self->{distversion};
}

=head1 SECURITY

This module executes a very small amount of code from each module that
it finds in a distribution.  While every effort has been made to do
this safely, there are no guarantees that it won't let the distributions
you're examining do horrible things to your machine, such as email your
password file to strangers.  You are strongly advised to read the source
code and to run it in a very heavily restricted user account.

=head1 LIMITATIONS, BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<Github Issues|https://github.com/DrHyde/perl-modules-CPAN-ParseDistribution/issues>
and should include the smallest possible chunk of code, along with
any necessary data, which demonstrates the bug.  Ideally, this
will be in the form of files which I can drop in to the module's
test suite.

There is a known problem with parsing some pathological distributions
on Windows, where CPAN::ParseDistribution may either hang or crash. This
is because Windows doesn't properly support fork()ing and signals. I can
not fix this, but welcome patches with tests.

=cut

=head1 SEE ALSO

L<http://pause.perl.org/>

L<dumpcpandist>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2009-2011 David Cantrell E<lt>david@cantrell.org.ukE<gt>

Contains code originally from the PAUSE by Andreas Koenig.

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
