package CPAN::FindDependencies;

use strict;
use warnings;
use vars qw(@net_log $VERSION @ISA @EXPORT_OK);

use Archive::Tar;
use Archive::Zip;
use Env::Path;
use File::Temp qw(tempfile);
use File::Type;
use LWP::UserAgent;
use Module::CoreList;
use Scalar::Util qw(blessed);
use CPAN::Meta;
use CPAN::FindDependencies::Dependency;
use CPAN::FindDependencies::MakeMaker qw(getreqs_from_mm);
use Parse::CPAN::Packages;
use URI::file;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '3.11';

use constant MAXINT => ~0;

=head1 NAME

CPAN::FindDependencies - find dependencies for modules on the CPAN

=head1 SYNOPSIS

    use CPAN::FindDependencies;
    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' ('.$dep->distribution().")\n";
    }

=head1 INCOMPATIBLE CHANGES

Up to version 2.49 you used the C<02packages> argument to specify where a
cached C<02packages.details.txt.gz> could be found. That argument no longer
exists as of version 3.00, use the C<mirror> argument instead.

Up to version 2.49, C<maxdepth =E<gt> 0> would incorrectly return the whole
tree. From version 3.00 it cuts the tree off at its root so will only return
the module that you asked about. Not very useful, but correct.

In version 2.49 you used the C<configreqs> argument to specify that you were
interested in configure-time requirements as well as build- and run-time
requirements. That option no longer exists as of version 3.00, it will always
report on configure, build, test, and run-time requirements.


=head1 HOW IT WORKS

The module uses the CPAN packages index to map modules to distributions and
vice versa, and then fetches distributions' metadata or Makefile.PL files from
a CPAN mirror to determine pre-requisites.  This means that a
working interwebnet connection is required.

=head1 FUNCTIONS

There is just one function, which is not exported by default
although you can make that happen in the usual fashion.

=head2 finddeps

Takes a single compulsory parameter, the name of a module
(ie Some::Module); and the following optional
named parameters:

=over

=item nowarnings

Warnings about modules where we can't find their META.yml or Makefile.PL, and
so can't divine their pre-requisites, will be suppressed. Other warnings may
still be emitted though, such as those telling you about modules which have
dodgy (but still understandable) metadata;

=item fatalerrors

Failure to get a module's dependencies will be a fatal error
instead of merely emitting a warning;

=item perl

Use this version of perl to figure out what's in core.  If not
specified, it defaults to 5.005.  Three part version numbers
(eg 5.8.8) are supported but discouraged.

=item cachedir

A directory to use for caching.  It defaults to no caching.  Even if
caching is turned on, this is only for META.yml or Makefile.PL files.

The cache is never automatically cleared out. It is your responsibility
to clear out old data.

=item maxdepth

Cuts off the dependency tree at the specified depth.  Your specified
module is at depth 0, your dependencies at depth 1, their dependencies
at depth 2, and so on.

If you don't specify any maxdepth at all it will grovel over the
entire tree.

=item mirror

This can be provided more than once, if for example you want to use
a private L<Pinto> repository for your own code while using a public
CPAN mirror for open source dependencies. The argument comes in two parts
separated by a comma - the base URL from which to fetch files, and
optionally the URL or a file from which to fetch the index
C<02packages.details.txt.gz> file to use with that mirror.

  mirror https://cpan.mydomain.net,file:///home/me/mycache/02packages.txt.gz

If you want to use the default CPAN mirror (https://cpan.metacpan.org/)
but also specify an index location you can use C<DEFAULT> for the mirror URL.

So for example, to use your own special private mirror, including fetching
02packages from it, but also use the default mirror with a cached local
copy of its 02packages, specify two mirrors thus:

  mirror => 'https://cpan.mydomain.net',
  mirror => 'DEFAULT,file:///home/me/mycache/02packages.txt.gz'

The index is cached for three minutes or until your process finishes, whichever is soonest. This is because it is HUMUNGOUS and parsing it takes ages even when it's loaded from a local disk, and I don't want the tests to take forever.

=item usemakefilepl

If set to true, then for any module that doesn't have a META.yml,
try to use its Makefile.PL as well.  Note that this involves
downloading code from the Internet and running it.  This obviously
opens you up to all kinds of bad juju, hence why it is disabled
by default. NB that this fetches Makefile.PL from
L<https://fastapi.metacpan.org> B<only> so will not work for private mirrors.
This is a deliberate choice, your own private code ought to be packaged
properly with a META file, you should only care about divining dependencies
from Makefile.PL if you rely on really old stuff on public CPAN mirrors.

=item recommended

Adds recommended modules to the list of dependencies, if set to a true value.

=item suggested

Adds suggested modules to the list of dependencies, if set to a true value.


=back

Order of arguments is not important.

It returns a list of CPAN::FindDependencies::Dependency objects, whose
useful methods are:

=over

=item name

The module's name;

=item distribution

The distribution containing this module;

=item version

The minimum required version of his module (if specified in the requirer's
pre-requisites list);

=item depth

How deep in the dependency tree this module is;

=item warning

If any warning was generated (even if suppressed) for the module,
it will be recorded here.

=back

Any modules listed as dependencies but which are in the perl core
distribution for the version of perl you specified are suppressed.

These objects are returned in a semi-defined order.  You can be sure
that a module will be immediately followed by one of its dependencies,
then that dependency's dependencies, and so on, followed by the 'root'
module's next dependency, and so on.  You can reconstruct the tree
by paying attention to the depth of each object.

The ordering of any particular module's immediate 'children' can be
assumed to be random - it's actually hash key order.

=head1 TREE PRUNING

The dependency tree is pruned to remove duplicates. This means that even though
C<Test::More>, for example, is a dependency of almost everything on the CPAN,
it will only be listed once.


=head1 SECURITY

If you set C<usemakefilepl> to a true value, this module may download code
from the internet and execute it.  You should think carefully before enabling
that feature.

=head1 BUGS/WARNINGS/LIMITATIONS

You must have web access to L<http://metacpan.org/> and (unless
you tell it where else to look for the index)
L<http://www.cpan.org/>, or have all the data cached locally..
If any
metadata or Makefile.PL files are missing, the distribution's dependencies will
not be found and a warning will be spat out.

Startup can be slow, especially if it needs to fetch the index from
the interweb.

Dynamic dependencies - for example, dependencies that only apply on some
platforms - can't be reliably resolved. They *may* be resolved if you use the
unsafe Makefile.PL, but even that can't be relied on.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in my git repo and
will pass once I've fixed the bug

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPAN-FindDependencies.git>

=head1 SEE ALSO

L<CPAN>

L<http://deps.cpantesters.org/>

L<http://metacpan.org>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 - 2019 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 THANKS TO

Stephan Loyd (for fixing problems with some META.yml files)

Alexandr Ciornii (for a patch to stop it segfaulting on Windows)

Brian Phillips (for the code to report on required versions of modules)

Ian Tegebo (for the code to extract deps from Makefile.PL)

Georg Oechsler (for the code to also list 'recommended' modules)

Jonathan Stowe (for making it work through HTTP proxies)

Kenneth Olwing (for support for 'configure_requires')

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

my $default_mirror = 'https://cpan.metacpan.org/';
my @valid_params = qw(
    nowarnings
    fatalerrors
    perl
    cachedir
    maxdepth
    mirror
    usemakefilepl
    recommended
    suggested
);

sub finddeps {
    @net_log = ();
    my $module = '';
    my @args = @_;

    my $self = bless({ indices => [], mirrors => [], seen => {} }, __PACKAGE__);

    while(@args) {
        my $option = shift(@args);
        # print STDERR "found argument $option. Remaining args [".join(', ', @args)."]\n";
        if($option eq 'mirror') {
            my($mirror, $packages) = split(/,/, shift(@args));
            $mirror = $default_mirror if($mirror eq 'DEFAULT');
            $mirror .= '/' unless($mirror =~ m{/$});
            $packages = "${mirror}modules/02packages.details.txt.gz"
                unless($packages);
            ($mirror, $packages) = map {
                $_ =~ /^https?:\/\// ? $_ : ''.URI::file->new_abs($_);
            } ($mirror, $packages);
            push @{$self->{mirrors}}, {
                mirror   => $mirror,
                packages => $packages
            };
        } elsif(grep { $_ eq $option } @valid_params) {
            $self->{$option} = shift(@args);
        } elsif(!$module) {
            $module = $option
        } else {
            die("Can't look for dependencies for '$option', already looking for deps for '$module'\n");
        }
    }
    unless(@{$self->{mirrors}}) {
        push @{$self->{mirrors}}, {
            mirror   => $default_mirror,
            packages => "${default_mirror}modules/02packages.details.txt.gz"
        }
    }

    $self->{maxdepth} = MAXINT unless(defined($self->{maxdepth}));

    $self->{perl} ||= 5.005;
    die(__PACKAGE__.": $self->{perl} is a broken version number\n")
        if($self->{perl} =~ /[^0-9.]/);
    if($self->{perl} =~ /\..*\./) {
        my @parts = split(/\./, $self->{perl});
        $self->{perl} = $parts[0] + $parts[1] / 1000 + $parts[2] / 1000000;
    }

    my $first_found = $self->_first_found($module);
    return $self->_finddeps(
        module  => $module,
        version => ($first_found ? $first_found->version() : 0)
    );
}

# indices are cached for performance, cos even if the
# file is fetched from disk uncompressing/parsing take ages.
# the cache lasts three minutes.
our %_parsed_index_cache = ();
sub _indices {
    my $self = shift;
    if(!@{$self->{indices}}) {
        local $SIG{__WARN__} = sub {};
        $self->{indices} = [map {
            my $url = $_->{packages};
            if(!(exists($_parsed_index_cache{$url}) && $_parsed_index_cache{$url}->{expiry} > time())) {
                $_parsed_index_cache{$url}->{expiry} = time() + 180;
                $_parsed_index_cache{$url}->{index} = Parse::CPAN::Packages->new(
                    $self->_get($url) || die(__PACKAGE__.": Couldn't fetch 02packages index file from $url\n")
                );
            }
            $_parsed_index_cache{$url}->{index}
        } @{$self->{mirrors}}]
    }
    return @{$self->{indices}};
}

# look through all the mirrors' 02packages for a module and return a
# Parse::CPAN::Packages::Package for the first one it finds
sub _first_found {
    my $self = shift;
    my $module = shift;
    return (map { $_->package($module) } grep { $_->package($module) } $self->_indices())[0];
}

sub _yell {
    my $self = shift;
    my $msg = shift;
    $msg = __PACKAGE__.": $msg";
    $msg = "$msg\n" unless(substr($msg, -1, 1) eq "\n");
    if(!$self->{nowarnings}) {
        if($self->{fatalerrors} ) {
            die('FATAL: '.$msg);
        } else {
            warn('WARNING: '.$msg);
        }
    }
}

sub _get {
    my $self = shift;
    my $url = shift;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    $ua->agent(__PACKAGE__."/$VERSION");
    push @net_log, $url;
    my $response = $ua->get($url);
    if($response->is_success()) {
        return $response->content();
    } else {
        return undef;
    }
}

sub _incore {
    my $self = shift;
    my %args = @_;
    my $core = $Module::CoreList::version{$args{perl}}{$args{module}};
    $core =~ s/_/00/g if($core);
    $args{version} =~ s/_/00/g;
    return ($core && $core >= $args{version}) ? $core : undef;
}

sub _finddeps {
    my $self = shift;
    my %args = @_;
    my( $module, $depth, $version) = @args{qw(module depth version)};
    $depth ||= 0;

    return () if(
        $module eq 'perl' ||
        $self->_incore(
            module => $module,
            perl => $self->{perl},
            version => $version)
    );

    my $dist = do {
        my $package = $self->_first_found($module);
        $package ? $package->distribution() : undef;
    };

    return () unless(blessed($dist));

    my $author   = $dist->cpanid();
    my $distname = $dist->distvname();

    return () if($self->{seen}->{$distname}++);

    my %reqs = $self->_getreqs(
        author   => $author,
        distname => $distname,
        distfile => $dist->filename(),
    );

    return (
        CPAN::FindDependencies::Dependency->_new(
            depth        => $depth,
            distribution => $dist,
            cpanmodule   => $module,
            indices      => [$self->_indices()],
            version      => $version || 0,
            $reqs{'-warning'} ? (warning => $reqs{'-warning'}) : ()
        ),
        (!exists($reqs{'-warning'}) && $depth != $self->{maxdepth}) ? (map {
            # print "Looking at $_\n";
            $self->_finddeps(
                module  => $_,
                depth   => $depth + 1,
                version => $reqs{$_}
            );
        } sort keys %reqs) : ()
    );
}

# caching wrapper around _get
#   can be asked to fetch a .meta, an archive, or a Makefile.PL,
#   so it knows how to figure out what the cache filename is
#   for those, based on the URL
# can be asked to get whichever first succeeds of multiple options.
# currently those are always a metadata file or an archive, which
# will resolve to the same cache file.
sub _get_cached {
    my $self = shift;
    my %args = @_;
    my($src, $post_process) = @args{qw(src post_process)};
    my $contents;
    # asked to check multiple sources? Return the first which has
    # content (or what's cached)
    if(ref($src)) {
        foreach my $this_url (@{$src}) {
            last if($contents = $self->_get_cached(
                post_process => $post_process,
                src          => $this_url
            ));
        }
        return $contents;
    }

    my $cachefile = $src;
    if($cachefile =~ /Makefile.PL/) {
        $cachefile =~ s{.*/([^/]+)/Makefile.PL$}{$1.MakefilePL};
    } else {
        $cachefile =~ s{.*/(.*?)\.(meta|zip|tar\.bz2|tar\.gz|tgz)$}{$1.meta};
    }

    if($self->{cachedir} && -d $self->{cachedir} && -r $self->{cachedir}."/$cachefile") {
        open(my $cachefh, $self->{cachedir}."/$cachefile") ||
            $self->_yell('Error reading '.$self->{cachedir}."/$cachefile: $!");
        local $/ = undef;
        $contents = <$cachefh>;
        close($cachefh);
    } else {
        $contents = $self->_get($src);
        if($contents && $post_process ) {
            $contents = $post_process->($contents);
        }
        if($contents && $self->{cachedir} && -d $self->{cachedir}) {
            open(my $cachefh, '>', $self->{cachedir}."/$cachefile") ||
                $self->_yell('Error writing '.$self->{cachedir}."/$cachefile: $!");
            print $cachefh $contents;
            close($cachefh);
        }
    }
    return $contents;
}

sub _getreqs {
    my $self = shift;
    my %args = @_;
    my($author, $distname, $distfile) = @args{qw(author distname distfile)};

    my $meta_file;
    foreach my $source (@{$self->{mirrors}}) {
        $meta_file = $self->_get_cached(
            src => [
                $source->{mirror}."authors/id/".
                    substr($author, 0, 1).'/'.
                    substr($author, 0, 2).'/'.
                    "$author/$distname.meta",
                $source->{mirror}."authors/id/".
                    substr($author, 0, 1).'/'.
                    substr($author, 0, 2).'/'.
                    "$author/$distfile"
            ],
            post_process => sub {
                # _get_cached normally just returns a file, but we're
                # asking it to either fetch a metadata file or if that can't be
                # found fetch an archive from which we want to extract a file,
                # and then cache that extracted file's contents. This function
                # takes a blob of data and if it looks like a zip or a tarball
                # tries to extract a META.json or META.yml and return its content
                # (or the empty string if not found), otherwise if it doesn't
                # look like an archive, assume that the input was a valid metadata
                # file after all and just return it.
                my $file_data = shift;
                my $meta_file_re = qr/^([^\/]+\/)?META\.(json|yml)/;
                my $rval = '';

                # We should be able to avoid writing to disk by something like
                # this but it doesn't work, for either zip or tar <shrug>
                # # my $tar = Archive::Tar->new();
                # # $tar->read([string opened as file])
                my(undef, $tempfile) = tempfile('CPAN-FindDependencies-XXXXXXXX', TMPDIR => 1, OPEN => 0);
                open(my $fh, '>', "$tempfile") || die("Can't write $tempfile: $!\n");
                binmode($fh); # Windows smells of wee
                print $fh $file_data;
                close($fh);

                if(File::Type->mime_type($file_data) eq 'application/zip') {
                    my $zip = Archive::Zip->new($tempfile);
                    if(my @members = sort { $a cmp $b } $zip->membersMatching($meta_file_re)) {
                        $rval = $zip->contents($members[0])
                    }
                } elsif(File::Type->mime_type($file_data) =~ m{^application/x-(bzip2|gzip|tar)$}) {
                    $rval = sub {
                        my $tar = Archive::Tar->new(shift());
                        # sort to ensure that we get JSON by preference, META.json
                        # often contains more info
                        if(my @members = sort { $a cmp $b } grep { /$meta_file_re/ } $tar->list_files()) {
                            return $tar->get_content($members[0])
                        }
                    }->($tempfile);
                } else { $rval = $file_data; } # oh, it must have been a meta file

                unlink $tempfile;

                return $rval;
            },
        );
        last if($meta_file);
    }
    if ($meta_file) {
        my $meta_data = eval {
            local $SIG{__WARN__} = sub {
                warn(join("\n", "In $distfile, $_[0]", @_[1 .. $#_]));
            };
            CPAN::Meta->load_string($meta_file);
        };
        if ($@ || !defined($meta_data)) {
            $self->_yell("$author/$distname: failed to parse metadata")
        } else {
            my $reqs = $meta_data->effective_prereqs();
            return %{
                $reqs->merged_requirements(
                    [qw(configure build test runtime)],
                    [
                        'requires',
                        ($self->{recommended} ? 'recommends' : ()),
                        ($self->{suggested}   ? 'suggests'   : ())
                    ]
                )->as_string_hash()
            };
        }
    } else {
        $self->_yell("$author/$distname: no metadata");
    }
    
    # We could have failed to parse the metadata file, but we still want to try the Makefile.PL
    if(!$self->{usemakefilepl}) {
        return ('-warning', 'no metadata');
    } else {
        my $makefilepl = $self->_get_cached(
            src => "https://fastapi.metacpan.org/source/$author/$distname/Makefile.PL",
        );
        if($makefilepl) {
            my $result = getreqs_from_mm($makefilepl);
            if ('HASH' eq ref $result) {
                return %{ $result };
            } else {
                $self->_yell("$author/$distname: $result");
                return ('-warning', $result);
            }
        } else {
            $self->_yell("$author/$distname: no metadata nor Makefile.PL");
            return ('-warning', 'no metadata nor Makefile.PL');
        }
    }
}

1;
