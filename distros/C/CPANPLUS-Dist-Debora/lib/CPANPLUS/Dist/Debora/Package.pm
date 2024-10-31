package CPANPLUS::Dist::Debora::Package;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.014';

use Carp qw(croak);
use Config;
use CPAN::Meta;
use English qw(-no_match_vars);
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catdir catfile splitdir splitpath);
use File::Temp qw(tempdir);
use Net::Domain qw(hostfqdn);
use Software::LicenseUtils 0.103014;

use CPANPLUS::Dist::Debora::License;
use CPANPLUS::Dist::Debora::Pod;
use CPANPLUS::Dist::Debora::Util qw(
    parse_version
    module_is_distributed_with_perl
    decode_utf8
    can_run
    run
    find_most_recent_mtime
    find_shared_objects
);

# Map some distribution names to special package names.
my %PACKAGE_NAME_FOR = (
    'ack'              => 'ack',
    'App-Licensecheck' => 'licensecheck',
    'App-perlbrew'     => 'perlbrew',
    'TermReadKey'      => 'perl-Term-ReadKey',
);

# Version quirks.
my %VERSION_FOR = ('BioPerl-Run' => sub { parse_version($_[0])->normal });

# Modules with summaries and descriptions.
my %POD_FOR = (
    'ack'              => 'ack',
    'App-Licensecheck' => 'licensecheck',
    'TermReadKey'      => 'ReadKey.pm.PL',
    'TimeDate'         => 'Date::Parse',
    'YAML-LibYAML'     => 'YAML::XS',
);

# Common modules whose license might not be guessed.
my %LICENSE_FOR = (
    'AnyEvent'                    => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Apache-Htpasswd'             => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Cache-Cache'                 => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Canary-Stability'            => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'CGI-FormBuilder'             => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'CGI-FormBuilder-Source-Perl' => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Crypt-CBC'                   => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Encode-Detect'               => 'MPL-1.1',
    'Guard'                       => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Iterator'                    => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Iterator-Util'               => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Lingua-EN-Words2Nums'        => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Lingua-Stem-Snowball-Da'     => 'GPL-2.0-only',
    'Mozilla-CA'                  => 'MPL-2.0',
    'Socket6'                     => 'BSD',
    'String-ShellQuote'           => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'Sub-Delete'                  => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    'XML-Writer'                  => 'CC0-1.0',
);

sub new {
    my ($class, %attrs) = @_;

    my $attrs = $class->_buildargs(%attrs);

    return bless $attrs, $class;
}

sub _buildargs {
    my ($class, %attrs) = @_;

    if (!exists $attrs{module}) {
        croak 'No module';
    }

    my $builddir = $attrs{builddir} = $attrs{module}->status->extract;
    if (!defined $builddir) {
        croak 'No builddir';
    }

    if (!exists $attrs{installdirs}) {
        $attrs{installdirs} = 'vendor';
    }

    my $installdirs = $attrs{installdirs};
    if ($installdirs ne 'vendor' && $installdirs ne 'site') {
        croak "installdirs is neither 'vendor' nor 'site': '$installdirs'";
    }

    if (!exists $attrs{build_number}) {
        $attrs{build_number} = 1;
    }

    my $build_number = $attrs{build_number};
    if ($build_number !~ m{\A [1-9]\d* \z}xms) {
        croak "build_number is not a positive integer: '$build_number'";
    }

    $attrs{last_modification} = find_most_recent_mtime($builddir);

    return \%attrs;
}

sub _read {
    my ($self, $name, $default) = @_;

    if (!exists $self->{$name}) {
        $self->{$name} = $default->();
    }

    return $self->{$name};
}

sub module {
    my $self = shift;

    return $self->{module};
}

sub installdirs {
    my $self = shift;

    return $self->{installdirs};
}

sub sourcefile {
    my $self = shift;

    my $sourcefile
        = $self->_read('sourcefile', sub { $self->module->status->fetch });

    return $sourcefile;
}

sub sourcedir {
    my $self = shift;

    my $sourcedir
        = $self->_read('sourcedir', sub { dirname($self->sourcefile) });

    return $sourcedir;
}

sub last_modification {
    my $self = shift;

    return $self->{last_modification};
}

sub builddir {
    my $self = shift;

    return $self->{builddir};
}

sub outputdir {
    my $self = shift;

    my $outputdir = $self->_read('outputdir', sub { dirname($self->builddir) });

    return $outputdir;
}

sub stagingdir {
    my $self = shift;

    my $stagingdir = $self->_read('stagingdir',
        sub { tempdir('stagingXXXX', DIR => $self->outputdir) });

    return $stagingdir;
}

sub shared_objects {
    my $self = shift;

    my $shared_objects
        = $self->_read('shared_objects', sub { $self->_get_shared_objects });

    return $shared_objects;
}

sub is_noarch {
    my $self = shift;

    my $is_noarch = $self->_read('is_noarch', sub { $self->_get_is_noarch });

    return $is_noarch;
}

sub module_name {
    my $self = shift;

    my $module_name
        = $self->_read('module_name', sub { $self->_get_module_name });

    return $module_name;
}

sub dist_name {
    my $self = shift;

    return $self->module->package_name;
}

sub name {
    my $self = shift;

    my $name = $self->_read('name',
        sub { $self->_normalize_name($self->dist_name) });

    return $name;
}

sub dist_version {
    my $self = shift;

    return $self->module->package_version;
}

sub version {
    my $self = shift;

    my $version = $self->_read('version',
        sub { $self->_normalize_version($self->dist_version) });

    return $version;
}

sub build_number {
    my $self = shift;

    return $self->{build_number};
}

sub author {
    my $self = shift;

    my $author = $self->_read('author', sub { $self->module->author->author });

    return $author;
}

sub packager {
    my $self = shift;

    my $packager = $self->_read('packager', sub { $self->_get_packager });

    return $packager;
}

sub vendor {
    my $self = shift;

    my $vendor = $self->_read('vendor', sub { $self->_get_vendor });

    return $vendor;
}

sub url {
    my $self = shift;

    # A link to MetaCPAN is more useful than the homepage.
    my $url = $self->_read('url',
        sub { 'https://metacpan.org/dist/' . $self->dist_name });

    return $url;
}

sub summary {
    my $self = shift;

    my $summary = $self->_read('summary', sub { $self->_get_summary });

    return $summary;
}

sub description {
    my $self = shift;

    my $description
        = $self->_read('description', sub { $self->_get_description });

    return $description;
}

sub dependencies {
    my $self = shift;

    my $dependencies
        = $self->_read('dependencies', sub { $self->_get_dependencies });

    return $dependencies;
}

sub copyrights {
    my $self = shift;

    my $copyrights = $self->_read('copyrights', sub { $self->_get_copyrights });

    return $copyrights;
}

sub licenses {
    my $self = shift;

    my $licenses = $self->_read('licenses', sub { $self->_get_licenses });

    return $licenses;
}

sub license {
    my $self = shift;

    my $license = $self->_read('license', sub { $self->_get_license });

    return $license;
}

sub files {
    my $self = shift;

    my $files = $self->_read('files',
        sub { [@{$self->_get_docfiles}, @{$self->_get_stagingfiles}] });

    return $files;
}

sub files_by_type {
    my ($self, $type) = @_;

    my @files = map { $_->{name} } grep { $_->{type} eq $type } @{$self->files};

    return \@files;
}

sub mb_opt {
    my $self = shift;

    my $installdirs = $self->installdirs;

    return << "END_MB_OPT";
--installdirs $installdirs
END_MB_OPT
}

sub mm_opt {
    my $self = shift;

    my $installdirs = $self->installdirs;

    return << "END_MM_OPT";
INSTALLDIRS=$installdirs
END_MM_OPT
}

sub sanitize_stagingdir {
    my $self = shift;

    my $fail_count = 0;

    my $finddepth = sub {
        my $dir = shift;

        opendir my $dh, $dir
            or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            # Skip symbolic links.
            next ENTRY if -l $path;

            # Process sub directories first.
            if (-d $path) {
                __SUB__->($path);
            }

            # Sanitize the permissions.
            my @stat = lstat $path;
            if (!@stat) {
                error("Could not stat '$path': $OS_ERROR");
                next ENTRY;
            }

            my $old_mode = $stat[2] & oct '0777';
            my $new_mode = ($old_mode & oct '0755') | oct '0200';
            if ($old_mode != $new_mode) {
                if (!chmod $new_mode, $path) {
                    error("Could not chmod '$path': $OS_ERROR");
                    ++$fail_count;
                }
            }

            # Remove empty directories and some files.
            if (-d $path) {
                rmdir $path;
            }
            else {
                if (   $entry eq 'perllocal.pod'
                    || $entry eq '.packlist'
                    || $entry =~ m{[.]la \z}xms
                    || ($entry =~ m{[.]bs \z}xms && -z $path))
                {
                    if (!unlink $path) {
                        error("Could not remove '$path': $OS_ERROR");
                        ++$fail_count;
                    }
                }
            }
        }
        closedir $dh;

        return;
    };
    $finddepth->($self->stagingdir);

    return $fail_count == 0;
}

sub remove_stagingdir {
    my $self = shift;

    my $stagingdir = $self->{stagingdir};
    if (defined $stagingdir) {
        remove_tree($stagingdir);
        delete $self->{stagingdir};
    }

    return 1;
}

sub rpm_cmd {
    my $self = shift;

    state $rpm_cmd = can_run('rpm');

    return $rpm_cmd;
}

sub rpm_eval {
    my ($self, $expr) = @_;

    my $string = q{};

    my $rpm_cmd = $self->rpm_cmd;
    if ($rpm_cmd) {
        my @eval_cmd = ($rpm_cmd, '--eval', $expr);
        my $output   = q{};
        if (run(command => \@eval_cmd, buffer => \$output)) {
            chomp $output;
            $string = eval { decode_utf8($output) } // q{};
        }
    }

    return $string;
}

sub sudo_cmd {
    my $self = shift;

    my $module   = $self->module;
    my $backend  = $module->parent;
    my $config   = $backend->configure_object;
    my $sudo_cmd = $config->get_program('sudo') // 'sudo';

    return $sudo_cmd;
}

sub DESTROY {
    my $self = shift;

    my $stagingdir = $self->{stagingdir};
    if (defined $stagingdir) {
        ##no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval { remove_tree($stagingdir) };
    }

    return;
}

## no critic (Subroutines::ProhibitExcessComplexity)

sub _normalize_name {
    my ($self, $dist_name) = @_;

    my $name;
    if (exists $PACKAGE_NAME_FOR{$dist_name}) {
        $name = $PACKAGE_NAME_FOR{$dist_name};
    }
    else {
        $name = $dist_name;

        # Prepend "perl-" unless the name starts with "perl-".
        if ($name !~ m{\A perl-}xms) {
            $name = 'perl-' . $name;
        }
    }

    return $name;
}

sub _normalize_version {
    my ($self, $dist_version) = @_;

    my $dist_name = $self->dist_name;

    my $version = $dist_version // 0;

    if (exists $VERSION_FOR{$dist_name}) {
        $version = $VERSION_FOR{$dist_name}->($version);
    }

    $version =~ s{\A v}{}xms;    # Strip "v".

    return $version;
}

sub _unnumify_version {
    my ($self, $dist_version) = @_;

    my $version
        = $self->_normalize_version(parse_version($dist_version)->normal);

    return $version;
}

sub _get_meta {
    my $self = shift;

    my $meta;

    my $builddir = $self->builddir;
    META:
    for (qw(META.json META.yml)) {
        my $metafile = catfile($builddir, $_);
        if (-f $metafile) {
            $meta = eval { CPAN::Meta->load_file($metafile) };
            last META if defined $meta;
        }
    }

    return $meta;
}

sub _meta {
    my $self = shift;

    my $meta = $self->_read('meta', sub { $self->_get_meta });

    return $meta;
}

sub _get_pod {
    my $self = shift;

    my $builddir = $self->builddir;

    my $name = $POD_FOR{$self->dist_name} // $self->module_name;
    my @dirs = map { catdir($builddir, $_) } qw(blib/lib blib/bin lib bin .);
    my $pod  = CPANPLUS::Dist::Debora::Pod->find($name, @dirs, $builddir);

    return $pod;
}

sub _pod {
    my $self = shift;

    return $self->_read('pod', sub { $self->_get_pod });
}

sub _get_shared_objects {
    my $self = shift;

    my $stagingdir = $self->{stagingdir};
    if (!defined $stagingdir) {
        croak 'Call shared_objects after the distribution has been built';
    }

    my $shared_objects = find_shared_objects($stagingdir);

    return $shared_objects;
}

sub _get_is_noarch {
    my $self = shift;

    # Searching for source code files isn't reliable as there are Perl
    # distributions with C files in example directories.
    #
    # Instead, we look for an "auto" directory and search for shared objects
    # after the distribution has been installed in the staging directory.

    my $stagingdir = $self->{stagingdir};
    if (!defined $stagingdir) {
        croak 'Call is_arch after the distribution has been built';
    }

    my $is_noarch = @{$self->shared_objects} == 0;
    if ($is_noarch) {
        my $installdirs = $self->installdirs;
        my $archdir     = $Config{"install${installdirs}arch"};
        if (defined $archdir) {
            my $autodir = catdir($stagingdir, $archdir, 'auto');
            if (-d $autodir) {
                $is_noarch = 0;
            }
        }
    }

    return $is_noarch;
}

sub _get_module_name {
    my $self = shift;

    my $name = $self->module->module;

    # Is there a .pm file with the distribution's name?
    my @module   = split qr{-}xms, $self->dist_name;
    my $filename = catfile($self->builddir, 'lib', @module) . '.pm';
    if (-f $filename) {
        $name = join q{::}, @module;
    }

    return $name;
}

sub _get_packager {
    my $self = shift;

    my $name;
    my $email;

    my $EMAIL = qr{ \A
        (?:([^<]*) \h+)?     # name
        <? ([^>]+@[^>]+) >?  # email
    }xms;

    if ($self->rpm_eval('%{?packager}') =~ $EMAIL) {
        $name  = $1;
        $email = $2;
    }

    if (!$name) {
        NAME:
        for my $key (qw(DEBFULLNAME NAME GITLAB_USER_NAME)) {
            if ($ENV{$key}) {
                $name = eval { decode_utf8($ENV{$key}) };
                last NAME if $name;
            }
        }
    }

    for my $key (qw(DEBEMAIL EMAIL GITLAB_USER_EMAIL)) {
        if ($ENV{$key}) {
            my $value = eval { decode_utf8($ENV{$key}) };
            if ($value && $value =~ $EMAIL) {
                if (!$name) {
                    $name = $1;
                }
                if (!$email) {
                    $email = $2;
                }
            }
        }
    }

    my $user;

    my @pw = eval { getpwuid $UID };
    if (@pw) {
        $user = eval { decode_utf8($pw[0]) };

        if (!$name) {
            my $gecos = eval { decode_utf8($pw[6]) };
            if ($gecos) {
                ($name) = split qr{,}xms, $gecos;
            }
        }
    }

    if (!$user) {
        USER:
        for my $key (qw(LOGNAME USER USERNAME)) {
            if ($ENV{$key}) {
                $user = eval { decode_utf8($ENV{$key}) };
                last USER if $user;
            }
        }
    }

    if (!$user) {
        $user = 'nobody';
    }

    if (!$name) {
        $name = $user;
    }

    if (!$email) {
        my $host = hostfqdn;
        $host =~ s{[.]$}{}xms;
        $email = $user . q{@} . $host;
    }

    return "$name <$email>";
}

sub _get_vendor {
    my $self = shift;

    my $vendor = $self->rpm_eval('%{?vendor}');
    if (!$vendor || $vendor =~ m{%}xms) {
        $vendor = 'CPANPLUS';
    }

    return $vendor;
}

sub _get_summary_from_meta {
    my $self = shift;

    my $summary;

    my $meta = $self->_meta;
    if (defined $meta) {
        my $text = $meta->{abstract};
        if ($text && $text !~ m{unknown}xmsi) {
            $summary = $text;
        }
    }

    return $summary;
}

sub _get_summary_from_pod {
    my $self = shift;

    my $summary;

    my $pod = $self->_pod;
    if (defined $pod) {
        $summary = $pod->summary;
    }

    return $summary;
}

sub _get_summary {
    my $self = shift;

    my $summary = $self->_get_summary_from_meta // $self->_get_summary_from_pod
        // 'Module for the Perl programming language';
    $summary =~ s{\v+}{ }xmsg;                    # Replace newlines.
    $summary =~ s{[.]+ \z}{}xms;                  # Remove trailing dots.
    $summary =~ s{\A (?:An? | The) \h+}{}xmsi;    # Remove leading articles.

    return ucfirst $summary;
}

sub _get_description {
    my $self = shift;

    my $description = q{};

    my $pod = $self->_pod;
    if (defined $pod) {
        $description = $pod->description;
    }

    if (!$description) {
        my $module_name = $self->module_name;
        $description
            = "$module_name is a module for the Perl programming language.";
    }

    return $description;
}

sub _get_requires {
    my $self = shift;

    my %requires;

    my $prereqs = $self->module->status->prereqs // {};

    my $meta = $self->_meta;
    if (defined $meta && ref $meta->{prereqs} eq 'HASH') {
        my $meta_runtime  = $meta->{prereqs}->{runtime} // {};
        my $meta_requires = $meta_runtime->{requires}   // {};

        # We can only have dependencies that are in the prereqs.
        %requires = map { $_ => $meta_requires->{$_} }
            grep { exists $prereqs->{$_} } keys %{$meta_requires};
    }
    else {
        %requires = %{$prereqs};
    }

    return \%requires;
}

sub _get_dependencies {
    my $self = shift;

    my %requires = %{$self->_get_requires};
    my $backend  = $self->module->parent;

    # Sometimes versions are numified and cannot be compared with stringified
    # versions.
    my %version_for = (
        'Algorithm-Diff'   => sub {0},
        'BioPerl'          => sub { $self->_unnumify_version($_[0]) },
        'Catalyst'         => sub {0},
        'Catalyst-Runtime' => sub {0},
        'CGI-Simple'       => sub {0},
        'DBD-Pg'           => sub { $self->_unnumify_version($_[0]) },
        'Time-Local'       => sub {0},
    );

    my %dependency;

    MODULE:
    for my $module_name (keys %requires) {
        my $module = $backend->module_tree($module_name);
        next MODULE if !$module;

        # Task::Weaken is only a build dependency.
        next MODULE if $module_name eq 'Task::Weaken';

        # Ignore dependencies on modules for VMS and Windows.
        next MODULE if $module_name =~ m{\A (?:VMS | Win32)}xms;

        my $dist_name = $module->package_name;
        my $version   = parse_version($requires{$module_name});

        my $is_core
            = $module_name eq 'perl'
            || module_is_distributed_with_perl($module_name, $version)
            || $module->package_is_perl_core;

        if (exists $version_for{$dist_name}) {
            $version = $version_for{$dist_name}->($version);
        }

        if (!exists $dependency{$module_name}
            || $dependency{$module_name}->{version} < $version)
        {
            $dependency{$module_name} = {
                dist_name => $dist_name,
                version   => $version,
                is_module => $module_name ne 'perl',
                is_core   => $is_core,
            };
        }
    }

    my @dependencies = map { {
        module_name  => $_,
        dist_name    => $dependency{$_}->{dist_name},
        package_name => $self->_normalize_name($dependency{$_}->{dist_name}),
        version      => $self->_normalize_version($dependency{$_}->{version}),
        is_module    => $dependency{$_}->{is_module},
        is_core      => $dependency{$_}->{is_core},
    } } sort { uc $a cmp uc $b } keys %dependency;

    return \@dependencies;
}

sub _get_copyrights {
    my $self = shift;

    my @copyrights;

    my $pod = $self->_pod;
    if (defined $pod) {
        push @copyrights, @{$pod->copyrights};
    }

    if (!@copyrights) {
        my $author = $self->author;
        my $holder
            = $author ? "$author and possibly others" : 'unknown authors';
        my $time = $self->last_modification;
        my $year = (gmtime $time)[5] + 1900;
        push @copyrights, {year => $year, holder => $holder};
    }

    return \@copyrights;
}

sub _get_licenses_from_meta {
    my $self = shift;

    my @licenses;

    my $meta = $self->_meta;
    if (defined $meta) {
        my $keys = $meta->{license};
        if (defined $keys) {
            if (!ref $keys) {
                $keys = [$keys];
            }
            my %ignore_key = map { $_ => 1 } qw(open_source unrestricted);
            for my $key (grep { !exists $ignore_key{$_} } @{$keys}) {
                my @license
                    = Software::LicenseUtils->guess_license_from_meta_key($key,
                    2);
                if (@license) {
                    push @licenses, @license;
                }
            }
        }
    }

    return \@licenses;
}

sub _get_licenses_from_pod {
    my $self = shift;

    my @licenses;

    my $pod = $self->_pod;
    if (defined $pod) {
        my @license
            = Software::LicenseUtils->guess_license_from_pod($pod->text);
        if (@license) {
            push @licenses, @license;
        }
    }

    return \@licenses;
}

sub _get_licenses {
    my $self = shift;

    my %copyright = %{$self->copyrights->[-1]};

    my $get_license = sub {
        my $spdx_expression = shift;

        my $license = eval {
            Software::LicenseUtils->new_from_spdx_expression({
                spdx_expression => $spdx_expression,
                %copyright
            });
        };
        if (!$license) {
            $license = CPANPLUS::Dist::Debora::License->new({
                package => $self,
                %copyright
            });
        }

        return $license;
    };

    my %unique_guesses
        = map { $_->name => $_ } @{$self->_get_licenses_from_meta},
        @{$self->_get_licenses_from_pod};

    # Add the copyright year and author to the guessed licenses.
    my @licenses
        = map { $get_license->($_->spdx_expression) } values %unique_guesses;
    if (!@licenses) {
        push @licenses, $get_license->($LICENSE_FOR{$self->dist_name});
    }

    my @sorted_licenses
        = sort { $a->spdx_expression cmp $b->spdx_expression } @licenses;

    return \@sorted_licenses;
}

sub _get_license {
    my $self = shift;

    my @names   = map { $_->spdx_expression } @{$self->licenses};
    my $license = join ' AND ',
        map { @names > 1 && m{\b OR \b}xmsi ? "($_)" : $_ } @names;

    return $license;
}

sub _get_docfiles {
    my $self = shift;

    my $LICENSE = qr{ \A (?:
       COPYING(?:[.](?:LESSER|LIB))?
       | COPYRIGHT
       | LICEN[CS]E
       ) (?:[.](?:md|mkdn|pod|txt))? \z
    }xmsi;

    my $CHANGELOG = qr{ \A (?:
        Change(?:s|Log)
        ) (?:[.](?:md|mkdn|pod|txt))? \z
    }xmsi;

    my $DOC = qr{ \A (?:
        AUTHORS
        | BUGS
        | CONTRIBUTING
        | CREDITS
        | FAQ
        | NEWS
        | README
        | THANKS
        | TODO
        ) (?:[.](?:md|mkdn|pod|txt))? \z
    }xmsi;

    my %regex_for = (
        'license'   => $LICENSE,
        'changelog' => $CHANGELOG,
        'doc'       => $DOC,
    );

    my @files;

    my $fix_permissions = sub {
        my $dir = shift;

        chmod oct '0755', $dir;

        opendir my $dh, $dir
            or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            # Skip symbolic links.
            next ENTRY if -l $path;

            if (-d $path) {
                __SUB__->($path);
            }
            else {
                chmod oct '0644', $path;
            }
        }
        closedir $dh;

        return;
    };

    my $find = sub {
        my $dir = shift;

        opendir my $dh, $dir
            or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            # Skip symbolic links.
            next ENTRY if -l $path;

            if (-d $path) {
                if ($entry eq 'examples') {
                    $fix_permissions->($path);
                    my $file = {name => $entry, type => 'doc'};
                    push @files, $file;
                }
            }
            elsif (-s $path) {
                TYPE:
                for my $type (keys %regex_for) {
                    if ($entry =~ $regex_for{$type}) {
                        chmod oct '0644', $path;
                        my $file = {name => $entry, type => $type};
                        push @files, $file;
                        last TYPE;
                    }
                }
            }
        }
        closedir $dh;

        return;
    };
    $find->($self->builddir);

    my @sorted_files = sort { $a->{name} cmp $b->{name} } @files;

    return \@sorted_files;
}

sub _get_excludedirs {
    my $self = shift;

    # A list of directories that are provided by Perl and must not be removed
    # by packages.

    my @vars = qw(
        installsitearch
        installsitebin
        installsitelib
        installsiteman1dir
        installsiteman3dir
        installsitescript
        installvendorarch
        installvendorbin
        installvendorlib
        installvendorman1dir
        installvendorman3dir
        installvendorscript
    );

    my %excludedirs = map { $_ => 1 } qw(/etc);
    VAR:
    for my $var (@vars) {
        my $value = $Config{$var};
        next VAR if !$value;

        if ($var =~ m{arch \z}xms) {
            $value = catdir($value, 'auto');
        }

        my ($volume, $path) = File::Spec->splitpath($value, 1);

        my ($dir, @dirs) = splitdir($path);
        while (@dirs) {
            $dir = catdir($dir, shift @dirs);
            $excludedirs{$dir} = 1;
        }
    }

    return \%excludedirs;
}

sub _get_stagingfiles {
    my $self = shift;

    my $stagingdir        = $self->stagingdir;
    my $stagingdir_length = length $stagingdir;
    my $excludedirs       = $self->_get_excludedirs;

    my @files;

    my $find = sub {
        my $dir = shift;

        opendir my $dh, $dir
            or croak "Could not traverse '$dir': $OS_ERROR";
        ENTRY:
        while (defined(my $entry = readdir $dh)) {
            next ENTRY if $entry eq q{.} || $entry eq q{..};

            my $path = catfile($dir, $entry);

            my $name = substr $path, $stagingdir_length;
            my $type = -l $path ? 'link' : -d $path ? 'dir' : 'file';
            if ($type eq 'file') {
                my ($volume, $dirs, $file) = splitpath($name);
                my %subdir = map { $_ => 1 } splitdir($dirs);
                if (exists $subdir{etc}) {
                    $type = 'config';
                }
                elsif (exists $subdir{man}) {
                    $type = 'man';
                }
            }

            if (!exists $excludedirs->{$name}) {
                my $file = {name => $name, type => $type};
                push @files, $file;
            }

            # Skip symbolic links.
            next ENTRY if -l $path;

            if (-d $path) {
                __SUB__->($path);
            }
        }
        closedir $dh;

        return;
    };
    $find->($stagingdir);

    my @sorted_files = sort { $a->{name} cmp $b->{name} } @files;

    return \@sorted_files;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Package - Base class for package formats

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  use parent qw(CPANPLUS::Dist::Debora::Package);

  my $name         = $package->name;
  my $version      = $package->version;
  my $summary      = $package->summary;
  my $description  = $package->description;
  my @licenses     = @{$package->licenses};
  my @dependencies = @{$package->dependencies};
  my @files        = @{$package->files};

=head1 DESCRIPTION

This module collects information on a yet to be created Debian or RPM package.
The information is obtained from a L<CPANPLUS::Module> object, the file system
and the environment.  Among other things, the module gets the package name, a
short summary, a description, the license and the dependencies.

=head1 SUBROUTINES/METHODS

Any methods marked I<Abstract> must be implemented by subclasses.

=head2 new

  my $package = CPANPLUS::Dist::Debora::Package->new(
      module       => $module,
      installdirs  => 'vendor',
      build_number => 1,
  );

Creates a new object.  The L<CPANPLUS::Module> object parameter is mandatory.
All other attributes are optional.

=head2 format_priority  I<Abstract>

  my $priority = CPANPLUS::Dist::Debora::Package->format_priority;

Checks whether the package format is available.  Returns 0 if the required
package tools are not available, 1 if the tools are available and 2 or higher
if the format is the operating system's native format.

=head2 create  I<Abstract>

  my $ok = $package->create(verbose => 0|1);

Creates a package.

=head2 install  I<Abstract>

  my $ok = $package->install(verbose => 0|1);

Installs the package.

=head2 outputname  I<Abstract>

  my $outputname = $package->outputname;

Returns the package filename, e.g.
F<~/rpmbuild/RPMS/noarch/perl-Some-Module-1.0-1.noarch.rpm>.

=head2 module

  my $module = $package->module;

Returns the L<CPANPLUS::Module> object that was passed to the constructor.

=head2 installdirs

  my $installdirs = $package->installdirs;

Returns the installation location, which can be "vendor" or "site".  Defaults
to "vendor".

=head2 sourcefile

  my $sourcefile = $package->sourcefile;

Returns the path to the Perl distribution's source archive, e.g.
F<~/.cpanplus/authors/id/S/SO/SOMEBODY/Some-Module-1.0.tar.gz>.

=head2 sourcedir

  my $sourcedir = $package->sourcedir;

Returns the path to the Perl distribution's source directory, e.g.
F<~/.cpanplus/authors/id/S/SO/SOMEBODY>.

=head2 last_modification

  my $timestamp = $package->last_modification;

Returns the last modification time of the source.

=head2 builddir

  my $builddir = $package->builddir;

Returns the directory the source archive was extracted to, e.g.
F<~/.cpanplus/5.36.1/build/XXXX/Some-Module-1.0>.

=head2 outputdir

  my $outputdir = $package->outputdir;

Returns the build directory's parent directory, e.g.
F<~/.cpanplus/5.36.1/build/XXXX>.

=head2 stagingdir

  my $stagingdir = $package->stagingdir;

Returns the staging directory where CPANPLUS installs the Perl distribution,
e.g. F<~/.cpanplus/5.36.1/build/XXXX/stagingYYYY>.

=head2 shared_objects

  for my $shared_object (@{$package->shared_objects}) {
      say $shared_object;
  }

Returns a list of shared object files in the staging directory.

This method must only be called after the distribution has been built.

=head2 is_noarch

  my $is_no_arch = $package->is_noarch;

Returns true if the package is independent of the hardware architecture.

This method must only be called after the distribution has been built.

=head2 module_name

  my $module_name = $package->module_name;

Returns the name of the package's main module, e.g. "Some::Module".

=head2 dist_name

  my $dist_name = $package->dist_name;

Returns the Perl distribution's name, e.g. "Some-Module".

=head2 name

  my $name = $package->name;

Returns the package name, e.g. "perl-Some-Module" or "libsome-module-perl".

=head2 dist_version

  my $dist_name = $package->dist_name;

Returns the Perl distribution's version.

=head2 version

  my $version = $package->version;

Returns the package version.

=head2 build_number

  my $build_number = $package->build_number;

Returns the build number.  Defaults to 1.

The Debian revision and RPM release starts with the build number.

=head2 author

  my $author = $package->author;

Returns the name of the Perl distribution's author.

=head2 packager

  my $packager = $package->packager;

Returns the packager's name and email address.  Taken from the RPM macro
%packager, the environment variables C<DEBFULLNAME>, C<DEBEMAIL>, C<NAME>,
C<EMAIL> or the password database.  All environment variables and files have
to be encoded in ASCII or UTF-8.

=head2 vendor

  my $vendor = $package->vendor;

Returns "CPANPLUS" or the value of the RPM macro C<%vendor>.

=head2 url

  my $url = $package->url;

Returns a web address that links to the Perl distribution's documentation,
e.g. "https://metacpan.org/dist/Some-Module".

=head2 summary

  my $summary = $package->summary;

Returns the Perl distribution's one-line description.

=head2 description

  my $description = $package->description;

Returns the Perl distribution's description.

=head2 dependencies

  for my $dependency (@{$package->dependencies}) {
      my $module_name  = $dependency->{module_name};
      my $dist_name    = $dependency->{dist_name};
      my $package_name = $dependency->{package_name};
      my $version      = $dependency->{version};
      my $is_core      = $dependency->{is_core};
      my $is_module    = $dependency->{is_module};
  }

Builds a list of Perl modules that the package depends on.

=head2 copyrights

  for my $copyright (@{$package->copyrights}) {
      my $year   = $copyright->{year};
      my $holder = $copyright->{holder};
  }

Returns the copyright years and holders.

=head2 licenses

  for my $license (@{$package->licenses}) {
      my $full_text = $license->license;
  }

Returns L<Software::License> objects.

=head2 license

  my $license = $package->license;

Returns a license identifier, e.g. "Artistic-1.0-Perl OR GPL-1.0-or-later".
Returns "Unknown" if no license information was found.

=head2 files

  for my $file (@{$package->files}) {
      my $name = $file->{name};
      my $type = $file->{type};
  }

Builds a list of files that CPANPLUS installed in the staging directory.
Searches the build directory for README, LICENSE and other documentation
files.

Possible types are "changelog", "config", "dir", "doc", "file", "license",
"link" and "man".

=head2 files_by_type

  for my $file (@{$package->files_by_type($type)}) {
      my $name = $file->{name};
  }

Returns all files of the given type.

=head2 mb_opt

  local $ENV{PERL_MB_OPT} = $package->mb_opt;

Returns the options that are passed to C<perl Build.PL>.

=head2 mm_opt

  local $ENV{PERL_MM_OPT} = $package->mm_opt;

Returns the options that are passed to C<perl Makefile.PL>.

=head2 sanitize_stagingdir

  my $ok = $package->sanitize_stagingdir;

Fixes permissions.  Removes empty directories and files like F<perllocal.pod>
and F<.packlist>.

=head2 remove_stagingdir

  my $ok = $package->remove_stagingdir;

Removes the staging directory.

=head2 rpm_cmd

  my $rpm_cmd = $self->rpm_cmd;

Returns the path to the rpm command.

=head2 rpm_eval

  my $expr   = '%{?packager}';
  my $string = $package->rpm_eval($expr);

Evaluates an expression with rpm and returns the result or the empty string.

=head2 sudo_cmd

  my $sudo_cmd = $self->sudo_cmd;

Returns the path to the sudo command.

=head1 DIAGNOSTICS

See L<CPANPLUS::Dist::Debora> for diagnostics.

=head1 CONFIGURATION AND ENVIRONMENT

See L<CPANPLUS::Dist::Debora> for supported files and environment variables.

=head1 DEPENDENCIES

Requires the module L<Software::License> from CPAN.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

Some operating systems numify Perl distribution versions but not consistently.
This module sticks closely to the version string, which seems to be the most
common approach.

=head1 SEE ALSO

L<CPANPLUS::Dist::Debora::Package::Debian>,
L<CPANPLUS::Dist::Debora::Package::RPM>,
L<CPANPLUS::Dist::Debora::Package::Tar>,
L<CPANPLUS::Dist::Debora::License>,
L<CPANPLUS::Dist::Debora::Pod>,
L<CPANPLUS::Dist::Debora::Util>

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
