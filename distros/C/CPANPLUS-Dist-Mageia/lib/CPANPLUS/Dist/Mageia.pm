#
# This file is part of CPANPLUS-Dist-Mageia
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package CPANPLUS::Dist::Mageia;
# ABSTRACT: A CPANPLUS backend to build Mageia RPMs
$CPANPLUS::Dist::Mageia::VERSION = '2.103';
use base 'CPANPLUS::Dist::Base';

use CPANPLUS::Error; # imported subs: error(), msg()
use File::Basename  qw{ basename dirname };
use File::Copy      qw{ copy };
use File::ShareDir  qw{ dist_dir };
use File::Slurp     qw{ slurp };
use IPC::Cmd        qw{ run can_run };
use List::Util      qw{ first };
use List::MoreUtils qw{ uniq };
use Pod::POM;
use Pod::POM::View::Text;
use POSIX ();
use Readonly;
use Text::Wrap;


my @RPMSUBDIRS = qw{ build rpm source spec srcrpm };
my %RPMDIR =  map {do { chomp(my $d=qx[ rpm --eval %_${_}dir ]); $_, $d; }} @RPMSUBDIRS ;

# -- class methods


sub format_available {
    # check mageia release file
    if ( ! -f '/etc/mageia-release' ) {
        error( 'not on a mageia system' );
        return;
    }

    my $flag;

    # check rpm tree structure
    foreach my $subdir ( keys %RPMDIR ) {
        my $dir = "$RPMDIR{$subdir}";
        next if -d $dir;
        error( "missing directory '$dir'" );
        $flag++;
    }

    # check prereqs
    for my $prog ( qw[ rpm rpmbuild gcc ] ) {
        next if can_run($prog);
        error( "'$prog' is a required program to build mageia packages" );
        $flag++;
    }

    return not $flag;
}


# -- public methods


sub init {
    my ($self) = @_;
    my $status = $self->status; # an Object::Accessor
    # distname: Foo-Bar
    # distvers: 1.23
    # extra_files: qw[ /bin/foo /usr/bin/bar ]
    # rpmname:  perl-Foo-Bar
    # rpmpath:  $RPMDIR/RPMS/noarch/perl-Foo-Bar-1.23-1mga2008.0.noarch.rpm
    # rpmvers:  1
    # srpmpath: $RPMDIR/SRPMS/perl-Foo-Bar-1.23-1mga2008.0.src.rpm
    # specpath: $RPMDIR/SPECS/perl-Foo-Bar.spec
    $status->mk_accessors(qw[ distname distvers extra_files rpmname rpmpath
        rpmvers srpmpath specpath ]);

    return 1;
}



sub prepare {
    my ($self, %args) = @_;
    my $status = $self->status;               # private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # parse args.
    my %opts = (
        force   => $conf->get_conf('force'),  # force rebuild
        perl    => $^X,
        verbose => $conf->get_conf('verbose'),
        %args,
    );

    # dry-run with makemaker: find build prereqs.
    msg( "dry-run prepare with makemaker..." );
    $self->SUPER::prepare( %args );

    # compute & store package information
    my $distname    = $module->package_name;
    $status->distname( $distname );
    my $distvers    = $module->package_version;
    my $distext     = $module->package_extension;
    my $distsummary    = _module_summary($module);
    my $distdescr      = _module_description($module);
    #my $distlicense    =
    my ($disttoplevel) = $module->name=~ /([^:]+)::/;
    my @reqs           = sort { $a cmp $b} (
        keys(%{ $module->status->prereqs }),
        keys(%{ $self->find_configure_requires }),
    );


    my ($distbuild, $distmaker, $distinstall);
    if (-e _path_to_makefile_pl($module)) {
        push @reqs, 'Module::Build::Compat' if _is_module_build_compat($module);
        $distbuild = "%{__perl} Makefile.PL INSTALLDIRS=vendor\n";
        $distmaker = "%make";
        $distinstall = "%make_install";
    } else {
        # module::build only distribution
        # The double dashes ("--") are for Module::Build::Tiny compatibility:
        #   * https://rt.cpan.org/Ticket/Display.html?id=86240
        #   * https://wiki.mageia.org/en/Perl_policy
        push @reqs, 'Module::Build';
        $distbuild = "%{__perl} Build.PL --installdirs=vendor\n";
        $distmaker = "./Build";
        $distinstall = "./Build install --destdir=%{buildroot}";
    }
    my $distbreqs      = join "\n", map { "BuildRequires: perl($_)" }
                         grep { $_ ne "perl" } @reqs;
    my @docfiles =
        uniq
        grep {
            ( /^[A-Z.]+$/ && !/^MANIFEST/ ) ||
            m{^(Change(s|log)|META.(json|yml)|(ex|s)amples?|e[gx]|demos?)$}i
        }
        map { basename $_ }
        grep { m!^[^/]+/[^/]+$! }       # only interested in root files
        @{ $module->status->files };
    my $distarch =
        defined( first { /\.(c|xs)$/i } @{ $module->status->files } )
        ? 'BuildRequires: perl-devel'
        : 'BuildArch: noarch';

    my $rpmname = _mk_pkg_name($distname);
    $status->rpmname( $rpmname );


    # check whether package has been build.
    if ( my $pkg = $self->_has_been_build($rpmname, $distvers) ) {
        my $modname = $module->module;
        msg( "already created package for '$modname' at '$pkg'" );

        if ( not $opts{force} ) {
            msg( "won't re-spec package since --force isn't in use" );
            # c::d::mga store
            $status->rpmpath($pkg); # store the path of rpm
            # cpanplus api
            $status->prepared(1);
            $status->created(1);
            $status->dist($pkg);
            return $pkg;
            # XXX check if it works
        }

        msg( '--force in use, re-specing anyway' );
        # FIXME: bump rpm version
    } else {
        msg( "writing specfile for '$distname'..." );
    }

    # compute & store path of specfile.
    my $spec = "$RPMDIR{spec}/$rpmname.spec";
    $status->specpath($spec);

    my $vers = $module->version;

    # writing the spec file.
    my $tmpl = _template_spec_file_path();
    open my $tmplfh, '<', $tmpl or die "can't open '$tmpl': $!";

    POSIX::setlocale(&POSIX::LC_ALL, 'C');
    my $specfh;
    if ( not open $specfh, '>', $spec ) {
        error( "can't open '$spec': $!" );
        return;
    }
    while ( defined( my $line = <$tmplfh> ) ) {
        last if $line =~ /^__END__$/;

        $line =~ s/DISTNAME/$distname/;
        $line =~ s/DISTVERS/$distvers/g;
        $line =~ s/DISTSUMMARY/$distsummary/;
        $line =~ s/DISTEXTENSION/$distext/;
        $line =~ s/DISTBUILDBUILDER/$distbuild/;
        $line =~ s/DISTINSTALL/$distinstall/;
        $line =~ s/DISTARCH/$distarch/;
        $line =~ s/DISTMAKER/$distmaker/;
        $line =~ s/DISTBUILDREQUIRES/$distbreqs/;
        $line =~ s/DISTDESCR/$distdescr/;
        $line =~ s/DISTDOC/@docfiles ? "%doc @docfiles" : ''/e;
        $line =~ s/DISTTOPLEVEL/$disttoplevel/;
        $line =~ s/DISTEXTRA/join( "\n", @{ $status->extra_files || [] })/e;
        $line =~ s/DISTDATE/POSIX::strftime("%a %b %d %Y", localtime())/e;

        print $specfh $line;
    }
    close $specfh;

    # copy package.
    my $basename = basename $module->status->fetch;
    my $tarball = "$RPMDIR{source}/$basename";
    copy( $module->status->fetch, $tarball );

    msg( "specfile for '$distname' written" );
    # return success
    $status->prepared(1);
    return 1;
}



sub create {
    my ($self, %args) = @_;
    my $status = $self->status;               # private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # parse args.
    my %opts = (
        force   => $conf->get_conf('force'),  # force rebuild
        perl    => $^X,
        verbose => $conf->get_conf('verbose'),
        %args,
    );

    # check if we need to rebuild package.
    if ( $status->created && defined $status->dist ) {
        if ( not $opts{force} ) {
            msg( "won't re-build package since --force isn't in use" );
            return $status->dist;
        }
        msg( '--force in use, re-building anyway' );
    }

    RPMBUILD: {
        # dry-run with makemaker: handle prereqs.
        msg( 'dry-run build with makemaker...' );
        $self->SUPER::create( %args );


        my $spec     = $status->specpath;
        my $distname = $status->distname;
        my $rpmname  = $status->rpmname;

        msg( "building '$distname' from specfile..." );

        # dry-run, to see if we forgot some files
        my ($buffer, $success);
        DRYRUN: {
            local $ENV{LC_ALL} = 'C';
            $success = run(
                command => "rpmbuild -ba --quiet $spec",
                verbose => $opts{verbose},
                buffer  => \$buffer,
            );
        }

        # check if the dry-run finished correctly
        if ( $success ) {
            my ($rpm)  = (sort glob "$RPMDIR{rpm}/*/$rpmname-*.rpm")[0];
            my ($srpm) = (sort glob "$RPMDIR{srcrpm}/$rpmname-*.src.rpm")[-1];
            msg( "rpm created successfully: $rpm" );
            msg( "srpm available: $srpm" );
            # c::d::mga store
            $status->rpmpath($rpm);
            $status->srpmpath($srpm);
            # cpanplus api
            $status->created(1);
            $status->dist($rpm);
            return $rpm;
        }

        # unknown error, aborting.
        if ( not $buffer =~ /^\s+Installed .but unpackaged. file.s. found:\n(.*)\z/ms ) {
            error( "failed to create mageia package for '$distname': $buffer" );
            # cpanplus api
            $status->created(0);
            return;
        }

        # additional files to be packaged
        msg( "extra files installed, fixing spec file" );
        my $files = $1;
        $files =~ s/^\s+//mg; # remove spaces
        my @files = split /\n/, $files;
        $status->extra_files( \@files );
        $self->prepare( %opts, force => 0 );
        msg( 'restarting build phase' );
        redo RPMBUILD;
    }
}



sub install {
    my ($self, %args) = @_;
    my $status = $self->status;               # private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # parse args.
    my %opts = (
        verbose => $conf->get_conf('verbose'),
        %args,
    );


    my $rpm = $self->status->rpmpath;
    msg( "installing $rpm" );

    # install the rpm
    # sudo is used, which means sudoers should be properly configured.
    my ($buffer, $success);
    INSTALL: {
        local $ENV{LC_ALL} = 'C';
        my $sudo = $> == 0 ? '' : 'sudo';
        $success = run(
            command => "$sudo rpm -Uv $rpm",
            verbose => $opts{verbose},
            buffer  => \$buffer,
        );
    }

    # check if the install finished correctly
    if ( $success ) {
        msg("successfully installed $rpm");
        $status->installed(1);
    } else {
        error("error while installing $rpm");
    }
}


# -- private methods

#
# my $bool = $self->_has_been_build;
#
# return true if there's already a package build for this module.
#
sub _has_been_build {
    my ($self, $name, $vers) = @_;
    my $pkg = ( sort glob "$RPMDIR{rpm}/*/$name-$vers-*.rpm" )[-1];
    return $pkg;
    # FIXME: should we check cooker?
}


# -- private subs

#
# my $path = _path_to_makefile_pl();
#
# return the path to the extracted makefile.pl
#
sub _path_to_makefile_pl {
    my $module = shift;
    return $module->_status->extract . '/Makefile.PL';
}


#
# my $bool = _is_module_build_compat();
#
# return true if shipped makefile.pl is auto-generated with
# module::build::compat usage.
#
sub _is_module_build_compat {
    my ($module) = @_;
    my $makefile = _path_to_makefile_pl($module);
    my $content  = slurp($makefile);
    return $content =~ /Module::Build::Compat/;
}


#
# my $path = _template_spec_file_path();
#
# return the absolute path where the template spec will be located.
#
sub _template_spec_file_path {
    my $path = dist_dir('CPANPLUS-Dist-Mageia');
    return "$path/template.spec";
}


#
# my $name = _mk_pkg_name($dist);
#
# given a distribution name, return the name of the mageia rpm
# package. in most cases, it will be the same, but some pakcage name
# will be too long as a rpm name: we'll have to cut it.
#
sub _mk_pkg_name {
    my ($dist) = @_;
    my $name = 'perl-' . $dist;
    return $name;
}



#
# my $description = _module_description($module);
#
# given a cpanplus::module, try to extract its description from the
# embedded pod in the extracted files. this would be the first paragraph
# of the DESCRIPTION head1.
#
sub _module_description {
    my ($module) = @_;

    my $path = dirname $module->_status->extract; # where tarball has been extracted
    my @docfiles =
        map  { "$path/$_" }               # prepend extract directory
        sort { length $a <=> length $b }  # sort by length: we prefer top-level module description
        grep { /\.(pod|pm)$/ }            # filter out those that can contain pod
        @{ $module->_status->files };     # list of embedded files

    # parse file, trying to find a header
    my $parser = Pod::POM->new;
    DOCFILE:
    foreach my $docfile ( @docfiles ) {
        my $pom = $parser->parse_file($docfile);  # try to find some pod
        next DOCFILE unless defined $pom;         # the file may contain no pod, that's ok
        HEAD1:
        foreach my $head1 ($pom->head1) {
            next HEAD1 unless $head1->title eq 'DESCRIPTION';
            my $pom  = $head1->content;                         # get pod for DESCRIPTION paragraph
            my $text = $pom->present('Pod::POM::View::Text');   # transform pod to text
            my @paragraphs = split /\n\n/, $text;               # split into paragraphs
            splice @paragraphs, 3 if @paragraphs > 3;           # only the 3 first paragraphs
            return join "\n\n", @paragraphs;
        }
    }

    return '';
}


#
# my $summary = _module_summary($module);
#
# given a cpanplus::module, return its registered description (if any)
# or try to extract it from the embedded pod in the extracted files.
#
sub _module_summary {
    my ($module) = @_;

    # registered modules won't go farther...
    my $summary = $module->description;

    if (!$summary) {
        my $path = dirname $module->_status->extract; # where tarball has been extracted
        my @docfiles =
            map  { "$path/$_" }               # prepend extract directory
            sort { length $a <=> length $b }  # sort by length: we prefer top-level module summary
            grep { /\.(pod|pm)$/ }            # filter out those that can contain pod
            @{ $module->_status->files };     # list of files embedded

        # parse file, trying to find a header
        my $parser = Pod::POM->new;
        DOCFILE:
        foreach my $docfile ( @docfiles ) {
            my $pom = $parser->parse_file($docfile);  # try to find some pod
            next unless defined $pom;                 # the file may contain no pod, that's ok
            HEAD1:
            foreach my $head1 ($pom->head1) {
                # continue till we find '=head1 NAME'
                my $title = $head1->title;
                next HEAD1 unless $title eq 'NAME';
                # extract the description in NAME section
                my $content = $head1->content;
                next DOCFILE unless $content =~ /^[^-]+ - (.*)$/m;
                $summary = $1 if $content;
            }
        }
    }

    if (!$summary) {
        $summary = 'no summary found';
    }

    # summary must begin with an uppercase, without any final dot
    # (this is a rpmlint policy)
    $summary =~ s/^(.)/\u$1/;
    $summary =~ s/\.$//;

    return $summary;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Mageia - A CPANPLUS backend to build Mageia RPMs

=head1 VERSION

version 2.103

=head1 SYNOPSIS

    $ cpan2dist --format=CPANPLUS::Dist::Mageia Some::Random::Package

=head1 DESCRIPTION

CPANPLUS::Dist::Mageia is a distribution class to create Mageia packages
from CPAN modules, and all of their dependencies. This allows you to have
the most recent copies of CPAN modules installed, using your package
manager of choice, but without having to wait for central repositories
to be updated.

You can either install them using the API provided in this package, or
manually via the C<rpm> command.

Some of the bleading edge CPAN modules have already been turned into
Mageia packages for you, and you can make use of them by adding the
Cauldron repositories (“core/release”).

Note that these packages are built automatically from CPAN and are
assumed to have the same license as perl and come without support.
Please always refer to the original CPAN package if you have questions.

=head1 METHODS

=head2 my $bool = CPANPLUS::Dist::Mageia->format_available;

Return a boolean indicating whether or not you can use this package to
create and install modules in your environment.

It will verify if you are on a Mageia system, and if you have all the
necessary components avialable to build your own Mageia packages. You
will need at least these dependencies installed: C<rpm>, C<rpmbuild> and
C<gcc>.

=head2 my $bool = $mga->init;

Sets up the C<CPANPLUS::Dist::Mageia> object for use. Effectively creates
all the needed status accessors.

Called automatically whenever you create a new C<CPANPLUS::Dist> object.

=head2 my $bool = $mga->prepare;

Prepares a distribution for creation. This means it will create the RPM
C<.spec> file needed to build the RPM and source RPM. This will also satisfy
any prerequisites the module may have.

Note that the .spec file will be as accurate as possible. However, some
fields may be wrong (especially the description, and maybe the summary)
since it relies on parsing POD to find this information.

Returns true on success and false on failure.

You may then call C<< $mga->create >> on the object to create the RPM
from the spec file, and then C<< $mga->install >> on the object to
actually install it.

=head2 my $bool = $mga->create;

Builds the RPM file from the spec file created during the C<create()>
step.

Returns true on success and false on failure.

You may then call C<< $mga->install >> on the object to actually install it.

=head2 my $bool = $mga->install;

Installs the RPM using C<rpm -U>. If run as a non-root user, uses
C<sudo>. This assumes that current user has sudo rights (without
password for max efficiency) to run C<rpm>.

Returns true on success and false on failure

=head1 TODO

=head2 Scan for proper license

Right now we assume that the license of every module is C<the same
as perl itself>. Although correct in almost all cases, it should
really be probed rather than assumed.

=head2 Long description

Right now we provide the description as given by the module in its
meta-data. However, not all modules provide this meta-data and rather
than scanning the files in the package for it, we simply default to the
name of the module.

=head1 SEE ALSO

L<CPANPLUS::Backend>, L<CPANPLUS::Module>, L<CPANPLUS::Dist>,
C<cpan2dist>, C<rpm>, C<urpmi>

You can look for information on this module at:

=over 4

=item * MetaCPAN

L<http://metacpan.org/release/CPANPLUS-Dist-Mageia>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANPLUS-Dist-Mageia>

=item * Git repository

L<http://github.com/jquelin/cpanplus-dist-mageia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANPLUS-Dist-Mageia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANPLUS-Dist-Mageia>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
