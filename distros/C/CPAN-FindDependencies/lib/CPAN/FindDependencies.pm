#!perl -w

package CPAN::FindDependencies;

use strict;
use vars qw($p $VERSION @ISA @EXPORT_OK);

use YAML::Tiny ();
use LWP::UserAgent;
use Module::CoreList;
use Scalar::Util qw(blessed);
use CPAN::FindDependencies::Dependency;
use CPAN::FindDependencies::MakeMaker qw(getreqs_from_mm);
use Parse::CPAN::Packages;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '2.47';

use constant DEFAULT02PACKAGES => 'http://www.cpan.org/modules/02packages.details.txt.gz';
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

=head1 HOW IT WORKS

The module uses the CPAN packages index to map modules to distributions and
vice versa, and then fetches distributions' META.yml or Makefile.PL files from
C<http://search.cpan.org/> to determine pre-requisites.  This means that a
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
so can't divine their pre-requisites, will be suppressed;

=item fatalerrors

Failure to get a module's dependencies will be a fatal error
instead of merely emitting a warning;

=item perl

Use this version of perl to figure out what's in core.  If not
specified, it defaults to 5.005.  Three part version numbers
(eg 5.8.8) are supported but discouraged.

=item 02packages

The location of CPAN.pm's C<02packages.details.txt.gz> file as a
local filename, with either a relative or an absolute path.  If not
specified, it is fetched from a CPAN mirror instead.  The file is
fetched just once.

=item cachedir

A directory to use for caching.  It defaults to no caching.  Even if
caching is turned on, this is only for META.yml or Makefile.PL files.
02packages is not cached - if you want to read that from a local disk, see the
C<02packages> option.

=item maxdepth

Cuts off the dependency tree at the specified depth.  Your specified
module is at depth 0, your dependencies at depth 1, their dependencies
at depth 2, and so on.

=item usemakefilepl

If set to true, then for any module that doesn't have a META.yml,
try to use its Makefile.PL as well.  Note that this involves
downloading code from the Internet and running it.  This obviously
opens you up to all kinds of bad juju, hence why it is disabled
by default.

=item recommended

Adds recommended modules to the list of dependencies, if set to a true value.


=back

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

=head1 SECURITY

If you set C<usemakefilepl> to a true value, this module may download code
from the internet and execute it.  You should think carefully before enabling
that feature.

=head1 BUGS/WARNINGS/LIMITATIONS

You must have web access to L<http://search.cpan.org/> and (unless
you tell it where else to look for the index)
L<http://www.cpan.org/>, or have all the data cached locally..
If any
META.yml or Makefile.PL files are missing, the distribution's dependencies will
not be found and a warning will be spat out.

Startup can be slow, especially if it needs to fetch the index from
the interweb.

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

L<http://search.cpan.org>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 - 2015 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

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

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub finddeps {
    my($module, %opts) = @_;

    $opts{perl} ||= 5.005;
    $opts{maxdepth} ||= MAXINT;

    die(__PACKAGE__.": $opts{perl} is a broken version number\n")
        if($opts{perl} =~ /[^0-9.]/);

    if($opts{perl} =~ /\..*\./) {
        _emitwarning(
            "Three-part version numbers are a bad idea",
            %opts
        );
        my @parts = split(/\./, $opts{perl});
        $opts{perl} = $parts[0] + $parts[1] / 1000 + $parts[2] / 1000000;
    }

    if(!$p) {
        local $SIG{__WARN__} = sub {};
        $p = Parse::CPAN::Packages->new(_get02packages($opts{'02packages'}));
    }

    return _finddeps(
        opts    => \%opts,
        target  => $module,
        seen    => {},
        version => ($p->package($module) ? $p->package($module)->version() : 0)
    );
}

sub _emitwarning {
    my($msg, %opts) = @_;
    $msg = __PACKAGE__.": $msg\n";
    if(!$opts{nowarnings}) {
        if($opts{fatalerrors} ) {
            die('FATAL: '.$msg);
        } else {
            warn('WARNING: '.$msg);
        }
    }
}

sub _module2obj {
    my $module = shift;
    $module = $p->package($module);
    return undef if(!$module);
    return $module->distribution();
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }

sub _get02packages {
    my $file = shift;
    if($file) {
        eval 'use URI::file';
        die($@) if($@);
        $file = URI::file->new_abs($file);
    }
    _get($file || DEFAULT02PACKAGES) ||
        die(__PACKAGE__.": Couldn't fetch 02packages index file\n");
}

sub _get {
    my $url = shift;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    $ua->agent(__PACKAGE__."/$VERSION");
    my $response = $ua->get($url);
    if($response->is_success()) {
        return $response->content();
    } else {
        return undef;
    }
}

sub _incore {
    my %args = @_;
    my $core = $Module::CoreList::version{$args{perl}}{$args{module}};
    $core =~ s/_/00/g if($core);
    $args{version} =~ s/_/00/g;
    return ($core && $core >= $args{version}) ? $core : undef;
}

sub _finddeps_uncached {
    my %args = @_;
    my( $target, $opts, $depth, $version, $seen) = @args{qw(
        target opts depth version seen
    )};
    $depth ||= 0;

    return [] if(
        $target eq 'perl' ||
        _incore(
            module => $target,
            perl => $opts->{perl},
            version => $version)
    );

    my $dist = _module2obj($target);

    return [] unless(blessed($dist));

    my $author   = $dist->cpanid();
    my $distname = $dist->distvname();

    return [] if($seen->{$distname});
    $seen->{$distname} = 1;

    my %reqs = @{_getreqs(
        author   => $author,
        distname => $distname,
        opts     => $opts,
    )};
    my $warning = '';
    if($reqs{'-warning'}) {
        $warning = $reqs{'-warning'};
        %reqs = ();
    }

    return [
        CPAN::FindDependencies::Dependency->_new(
            depth      => $depth,
            cpanmodule => $target,
            p          => $p,
            version    => $version || 0,
            ($warning ? (warning => $warning) : ())
        ),
        ($depth != $opts->{maxdepth}) ? (map {
            # print "Looking at $_\n";
            _finddeps(
                target  => $_,
                opts    => $opts,
                depth   => $depth + 1,
                seen    => $seen,
                version => $reqs{$_}
            );
        } sort keys %reqs) : ()
    ];
}

sub _get_file_cached {
    my %args = @_;
    my($src, $destfile, $opts) = @args{qw(src destfile opts)};
    my $contents;
    if($opts->{cachedir} && -d $opts->{cachedir} && -r $opts->{cachedir}."/$destfile") {
        open(my $cachefh, $opts->{cachedir}."/$destfile") ||
            _emitwarning('Error reading '.$opts->{cachedir}."/$destfile: $!");
        local $/ = undef;
        $contents = <$cachefh>;
        close($cachefh);
    } else {
        $contents = _get($src);
        if($contents && $opts->{cachedir} && -d $opts->{cachedir}) {
            open(my $cachefh, '>', $opts->{cachedir}."/$destfile") ||
                _emitwarning('Error writing '.$opts->{cachedir}."/$destfile: $!");
            print $cachefh $contents;
            close($cachefh);
        }
    }
    return $contents;
}

sub _getreqs {
    my %args = @_;
    my($author, $distname, $opts) = @args{qw(author distname opts)};

    # Prefer a META.yml, but if that's not found
    #     add the warning to the 'warning stack', if there is one
    # Try scanning the Makefile.PL if this is enabled
    #     if found, remove the META.yml warning and return deps
    # If neither is found, add warning to stack and return

    my $yaml = _get_file_cached(
        src => "http://search.cpan.org/src/$author/$distname/META.yml",
        destfile => "$distname.yml",
        opts => $opts
    );
    if ($yaml) {
        my $yaml = eval { YAML::Tiny::Load($yaml); };
        if ($@ || !defined($yaml)) {
            _emitwarning("$author/$distname: failed to parse META.yml", %{$opts})
        } else {
            $yaml->{requires} ||= {};
            $yaml->{build_requires} ||= {};
            $yaml->{recommends} ||= {};
            return [
	        %{$yaml->{requires}}, %{$yaml->{build_requires}},
		($opts->{recommended} ? %{$yaml->{recommends}} : ()),
	    ];
        }
    } else {
        _emitwarning("$author/$distname: no META.yml", %{$opts});
    }
        
    # We could have failed to parse the META.yml, but we still want to try the Makefile.PL
    if(!$opts->{usemakefilepl}) {
        return ['-warning', 'no META.yml'];
    } else {
        my $makefilepl = _get_file_cached(
            src => "http://search.cpan.org/src/$author/$distname/Makefile.PL",
            destfile => "$distname.MakefilePL",
            opts => $opts
        );
        if($makefilepl) {
            my $result = getreqs_from_mm($makefilepl);
            if ('HASH' eq ref $result) {
                return [ %{ $result } ];
            } else {
                _emitwarning("$author/$distname: $result", %{$opts});
                return ['-warning', $result];
            }
        } else {
            _emitwarning("$author/$distname: no META.yml nor Makefile.PL", %{$opts});
            return ['-warning', 'no META.yml nor Makefile.PL'];
        }
    }
}

1;
