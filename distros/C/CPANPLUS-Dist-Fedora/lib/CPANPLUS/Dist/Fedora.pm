#
# This file is part of CPANPLUS::Dist::Fedora.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package CPANPLUS::Dist::Fedora;

use strict;
use warnings;

use base 'CPANPLUS::Dist::Base';

use Cwd;
use CPANPLUS::Error; # imported subs: error(), msg()
use File::Basename;
use File::Copy      qw[ copy ];
use IPC::Cmd        qw[ run can_run ];
use List::Util      qw[ first ];
use Pod::POM;
use Pod::POM::View::Text;
use POSIX qw[ strftime ];
use Text::Wrap;
use Template;

our $VERSION = '0.0.9';

sub _get_spec_template
{
    # Dealing with DATA gets increasingly messy, IMHO
    # So we're going to use the Template Toolkit instead
    return <<'END_SPEC';

Name:       [% status.rpmname %]
Version:    [% status.distvers %]
Release:    [% status.rpmvers %]%{?dist}
License:    [% status.license %]
Group:      Development/Libraries
Summary:    [% status.summary %]
Source:     http://search.cpan.org/CPAN/[% module.path %]/[% status.distname %]-%{version}.[% module.package_extension %]
Url:        http://metacpan.org/release/[% status.distname %]
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
[% IF status.is_noarch %]BuildArch:  noarch[% END %]
[% brs = buildreqs; FOREACH br = brs.keys.sort -%]
Requires: [% rpm_req(br) %][% IF (brs.$br != 0) %] >= [% brs.$br %][% END %]
[% END -%]
BuildRequires: perl(ExtUtils::MakeMaker)
[% FOREACH br = brs.keys.sort -%]
BuildRequires: [% rpm_req(br) %][% IF (brs.$br != 0) %] >= [% brs.$br %][% END %]
[% END -%]


%description
[% status.description -%]


%prep
%setup -q -n [% status.distname %]-%{version}

%build
[% IF (!status.is_noarch) -%]
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}" INSTALLVENDORLIB=%{perl_vendorlib} INSTALLVENDORMAN3DIR=%{_mandir}/man3
[% ELSE -%]
%{__perl} Makefile.PL INSTALLDIRS=vendor INSTALLVENDORLIB=%{perl_vendorlib} INSTALLVENDORMAN3DIR=%{_mandir}/man3
[% END -%]
make %{?_smp_mflags}

%install
rm -rf %{buildroot}

make pure_install PERL_INSTALL_ROOT=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
[% IF (!status.is_noarch) -%]
find %{buildroot} -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
[% END -%]
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'

%{_fixperms} %{buildroot}/*

%check
make test

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc [% docfiles %]
[% IF (status.is_noarch) -%]
%{perl_vendorlib}/*
[% ELSE -%]
%{perl_vendorarch}/*
%exclude %dir %{perl_vendorarch}/auto
[% END -%]
%{_mandir}/man3/*.3*

%changelog
* [% date %] [% packager %] [% status.distvers %]-[% status.rpmvers %]
- initial Fedora packaging
- generated with cpan2dist (CPANPLUS::Dist::Fedora version [% packagervers %])
END_SPEC
}

#--
# class methods

#
# my $bool = CPANPLUS::Dist::Fedora->format_available;
#
# Return a boolean indicating whether or not you can use this package to
# create and install modules in your environment.
#
sub format_available {
    # Check Fedora release file
    if ( not ( -f '/etc/fedora-release' or -f '/etc/redhat-release') ) {
        error( 'Not on a Fedora system' );
        return;
    }

    my $flag;

    # check prereqs
    for my $prog ( qw[ rpm rpmbuild gcc ] ) {
        next if can_run($prog);
        error( "'$prog' is a required program to build Fedora packages" );
        $flag++;
    }

    return not $flag;
}

#--
# public methods

#
# my $bool = $fedora->init;
#
# Sets up the C<CPANPLUS::Dist::Fedora> object for use, and return true if
# everything went fine.
#
sub init {
    my ($self) = @_;
    my $status = $self->status; # an Object::Accessor
    # distname: Foo-Bar
    # distvers: 1.23
    # extra_files: qw[ /bin/foo /usr/bin/bar ]
    # rpmname:     perl-Foo-Bar
    # rpmpath:     $RPMDIR/RPMS/noarch/perl-Foo-Bar-1.23-1mdv2008.0.noarch.rpm
    # rpmvers:     1
    # rpmdir:      $DIR
    # srpmpath:    $RPMDIR/SRPMS/perl-Foo-Bar-1.23-1mdv2008.0.src.rpm
    # specpath:    $RPMDIR/SPECS/perl-Foo-Bar.spec
    # is_noarch:   true if pure-perl
    # license:     try to figure out the actual license
    # summary:     one-liner summary
    # description: a paragraph summary or so
    $status->mk_accessors(
        qw[ distname distvers extra_files rpmname rpmpath rpmvers rpmdir
            srpmpath specpath is_noarch license summary description
          ]
    );

    # This is done to initialise it.
    $self->_get_current_dir();

    return 1;
}

sub prepare {
    my ($self, %args) = @_;
    my $status = $self->status;               # Private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # Parse args.
    my %opts = (
        force   => $conf->get_conf('force'),  # force rebuild
        perl    => $^X,
        verbose => $conf->get_conf('verbose'),
        %args,
    );

    # Dry-run with makemaker: find build prereqs.
    msg( "dry-run prepare with makemaker..." );
    $self->SUPER::prepare( %args );

    # Compute & store package information
    my $distname    = $module->package_name;
    $status->distname($distname);
    $status->distvers($module->package_version);
    $status->summary(_module_summary($module));
    $status->description(_module_description($module));
    $status->license($self->_module_license($module));
    #$status->disttop($module->name=~ /([^:]+)::/);
    my $dir = $status->rpmdir($self->_get_current_dir());
    $status->rpmvers(1);

    # Cache files
    my @files = @{ $module->status->files };

    # Handle build/test/requires
    my $buildreqs = $module->status->prereqs;
    $buildreqs->{'Module::Build::Compat'} = 0
        if _is_module_build_compat($module);

    # Files for %doc
    my @docfiles =
        grep { /(README|Change(s|log)|LICENSE)$/i }
        map { basename $_ }
        @files
        ;

    # Figure out if we're noarch or not
    $status->is_noarch(do { first { /\.(c|xs)$/i } @files } ? 0 : 1);

    my $rpmname = _mk_pkg_name($distname);
    $status->rpmname( $rpmname );

    # check whether package has been build.
    if ( my $pkg = $self->_has_been_built($rpmname, $status->distvers) ) {
        my $modname = $module->module;
        msg( "already created package for '$modname' at '$pkg'" );

        if ( not $opts{force} ) {
            msg( "won't re-spec package since --force isn't in use" );
            # c::d::mdv store
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

    # Compute & store path of specfile.
    $status->specpath("$dir/$rpmname.spec");

    # Prepare our template
    my $tmpl = Template->new({ EVAL_PERL => 1 });

    my $spec_template = $self->_get_spec_template();

    # Process template into spec
    $tmpl->process(
        \$spec_template,
        {
            status    => $status,
            module    => $module,
            buildreqs => $buildreqs,
            date      => strftime("%a %b %d %Y", localtime),
            packager  => $self->_get_packager(),
            docfiles  => join(' ', @docfiles),
            rpm_req => sub {
                my $br = shift;
                return (($br eq 'perl') ? $br : "perl($br)");
            },

            packagervers => $VERSION,
            # s/DISTEXTRA/join( "\n", @{ $status->extra_files || [] })/e;
            # ... FIXME
        },
        $status->specpath,
    );

    if ( $intern->_callbacks->munge_dist_metafile ) {
        print 'munging...';

        my $orig_contents = _read_file( $status->specpath );
        my $new_contents = $intern->_callbacks->munge_dist_metafile->($intern, $orig_contents);
        _write_file( $status->specpath, $new_contents );
    }

    # copy package.
    my $tarball = "$dir/" . basename $module->status->fetch;
    copy $module->status->fetch, $tarball;

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

        msg( "Building '$distname' from specfile $spec..." );

        # dry-run, to see if we forgot some files
        my ($buffer, $success);
        my $dir = $status->rpmdir;
        DRYRUN: {
            local $ENV{LC_ALL} = 'C';
            $success = run(
                #command => "rpmbuild -ba --quiet $spec",
                command =>
                    'rpmbuild -ba '
                    . qq{--define '_sourcedir $dir' }
                    . qq{--define '_builddir $dir'  }
                    . qq{--define '_srcrpmdir $dir' }
                    . qq{--define '_rpmdir $dir'    }
                    . $spec,
                verbose => $opts{verbose},
                buffer  => \$buffer,
            );
        }

        # check if the dry-run finished correctly
        if ( $success ) {
            my ($rpm)  = (sort glob "$dir/*/$rpmname-*.rpm")[-1];
            my ($srpm) = (sort glob "$dir/$rpmname-*.src.rpm")[-1];
            msg( "RPM created successfully: $rpm" );
            msg( "SRPM available: $srpm" );
            # c::d::mdv store
            $status->rpmpath($rpm);
            $status->srpmpath($srpm);
            # cpanplus api
            $status->created(1);
            $status->dist($rpm);
            return $rpm;
        }

        # unknown error, aborting.
        if ( not $buffer =~ /^\s+Installed .but unpackaged. file.s. found:\n(.*)\z/ms ) {
            error( "Failed to create Fedora package for '$distname': $buffer" );
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
        $self->prepare( %opts, force => 1 );
        msg( 'restarting build phase' );
        redo RPMBUILD;
    }
}

sub install {
    my ($self, %args) = @_;
    my $rpm = $self->status->rpm;
    error( "installing $rpm" );
    die;
    #$dist->status->installed
}



#--
# Private methods:

sub _read_file {
    my ($filename) = @_;
    open my $fh, '< :encoding(utf8)', $filename;
    local $/;
    my $contents = <$fh>;
    close ($fh);

    return $contents
}

sub _write_file {
    my ($filename, $contents) = @_;
    open my $fh, '> :encoding(utf8)', $filename;
    print {$fh} $contents;
    close ($fh);

    return;
}

#
# my $bool = $self->_has_been_built;
#
# Returns true if there's already a package built for this module.
#
sub _has_been_built {
    my ($self, $name, $vers) = @_;
    my $RPMDIR = $self->_get_RPMDIR();
    my $pkg = ( sort glob "$RPMDIR/RPMS/*/$name-$vers-*.rpm" )[-1];
    return $pkg;
    # FIXME: should we check cooker?
}


#--
# Private subs

sub _is_module_build_compat {
    my ($module) = @_;
    my $makefile = $module->_status->extract . '/Makefile.PL';

    open my $mk_fh, "<", $makefile;

    my $found = 0;

    LINES:
    while (my $line = <$mk_fh>)
    {
        if ($line =~ /Module::Build::Compat/)
        {
            $found = 1;
            last LINES;
        }
    }

    close($mk_fh);

    return $found;
}


#
# my $name = _mk_pkg_name($dist);
#
# given a distribution name, return the name of the mandriva rpm
# package. in most cases, it will be the same, but some pakcage name
# will be too long as a rpm name: we'll have to cut it.
#
sub _mk_pkg_name {
    my ($dist) = @_;
    my $name = 'perl-' . $dist;
    return $name;
}

# determine the module license.
#
# FIXME! for now just return the default licence

sub _module_license
{
    my $self = shift;
    my $module = shift;

    return $self->_get_default_license();
}

sub _get_default_license
{
    return 'CHECK(GPL+ or Artistic)';
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
            my @paragraphs = (split /\n\n/, $text)[0..2];       # only the 3 first paragraphs
            return join "\n\n", @paragraphs;
        }
    }

    return 'no description found';
}


#
# my $summary = _module_summary($module);
#
# Given a CPANPLUS::Module, return its registered description (if any)
# or try to extract it from the embedded POD in the extracted files.
#
sub _module_summary {
    my ($module) = @_;

    # registered modules won't go farther...
    return $module->description if $module->description;

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
            my $title = $head1->title;
            next HEAD1 unless $title eq 'NAME';
            my $content = $head1->content;
            next DOCFILE unless $content =~ /^[^-]+ - (.*)$/m;
            return $1 if $content;
        }
    }

    return 'no summary found';
}

sub _get_RPMDIR
{
    my $self = shift;

    # Memoize it.
    if (!defined($self->{_RPMDIR}))
    {
        chomp(my $d=qx[ rpm --eval %_topdir ]);
        $self->{_RPMDIR} = $d;
    }

    return $self->{_RPMDIR};
}

sub _get_packager
{
    my $self = shift;

    # Memoize it.
    if (!defined($self->{_packager}))
    {
        my $d = `rpm --eval '%{packager}'`;
        chomp $d;
        $self->{_packager} = $d;
    }

    return $self->{_packager};
}

sub _get_current_dir
{
    my $self = shift;

    # Memoize it.
    if (!defined($self->{_current_dir}))
    {
        $self->{_current_dir} = cwd();
    }

    return $self->{_current_dir};
}

1;

__END__

=head1 NAME

CPANPLUS::Dist::Fedora - a cpanplus backend to build Fedora/RedHat rpms



=head1 SYNOPSIS

    cpan2dist --format=CPANPLUS::Dist::Fedora Some::Random::Package



=head1 DESCRIPTION

CPANPLUS::Dist::Fedora is a distribution class to create Fedora packages
from CPAN modules, and all its dependencies. This allows you to have
the most recent copies of CPAN modules installed, using your package
manager of choice, but without having to wait for central repositories
to be updated.

You can either install them using the API provided in this package, or
manually via rpm.

Note that these packages are built automatically from CPAN and are
assumed to have the same license as perl and come without support.
Please always refer to the original CPAN package if you have questions.



=head1 CLASS METHODS

=head2 $bool = CPANPLUS::Dist::Fedora->format_available;

Return a boolean indicating whether or not you can use this package to
create and install modules in your environment.

It will verify if you are on a mandriva system, and if you have all the
necessary components avialable to build your own mandriva packages. You
will need at least these dependencies installed: C<rpm>, C<rpmbuild> and
C<gcc>.



=head1 PUBLIC METHODS

=head2 $bool = $fedora->init;

Sets up the C<CPANPLUS::Dist::Fedora> object for use. Effectively creates
all the needed status accessors.

Called automatically whenever you create a new C<CPANPLUS::Dist> object.


=head2 $bool = $fedora->prepare;

Prepares a distribution for creation. This means it will create the rpm
spec file needed to build the rpm and source rpm. This will also satisfy
any prerequisites the module may have.

Note that the spec file will be as accurate as possible. However, some
fields may wrong (especially the description, and maybe the summary)
since it relies on pod parsing to find those information.

Returns true on success and false on failure.

You may then call C<< $fedora->create >> on the object to create the rpm
from the spec file, and then C<< $fedora->install >> on the object to
actually install it.


=head2 $bool = $fedora->create;

Builds the rpm file from the spec file created during the C<create()>
step.

Returns true on success and false on failure.

You may then call C<< $fedora->install >> on the object to actually install it.


=head2 $bool = $fedora->install;

Installs the rpm using C<rpm -U>.

B</!\ Work in progress: not implemented.>

Returns true on success and false on failure



=head1 TODO

There are no TODOs of a technical nature currently, merely of an
administrative one;

=over

=item o Scan for proper license

Right now we assume that the license of every module is C<the same
as perl itself>. Although correct in almost all cases, it should
really be probed rather than assumed.


=item o Long description

Right now we provided the description as given by the module in it's
meta data. However, not all modules provide this meta data and rather
than scanning the files in the package for it, we simply default to the
name of the module.


=back



=head1 BUGS

Please report any bugs or feature requests to C<< < cpanplus-dist-fedora at
rt.cpan.org> >>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Fedora>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.



=head1 SEE ALSO

L<CPANPLUS::Backend>, L<CPANPLUS::Module>, L<CPANPLUS::Dist>,
C<cpan2dist>, C<rpm>, C<yum>


C<CPANPLUS::Dist::Fedora> development takes place on
L<https://svn.berlios.de/svnroot/repos/web-cpan/CPANPLUS-Dist/trunk/>
- feel free to join us.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANPLUS-Dist-Fedora>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANPLUS-Dist-Fedora>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANPLUS-Dist-Fedora>

=back



=head1 AUTHOR

Originally based on CPANPLUS-Dist-Mdv by:

Jerome Quelin, C<< <jquelin at cpan.org> >>

Shlomi Fish ( L<http://www.shlomifish.org/> ) changed it into
CPANPLUS-Dist-Fedora.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Modified by Shlomi Fish, 2008 - all ownership disclaimed.

Modified again by Chris Weyl <cweyl@alumni.drew.edu> 2008.

=cut

