package CPANPLUS::Dist::Slackware::PackageDescription;

use strict;
use warnings;

our $VERSION = '1.030';

use English qw( -no_match_vars );

use CPANPLUS::Dist::Slackware::Util qw(catdir catfile tmpdir);

use Config;
use File::Temp qw();
use Module::CoreList qw();
use POSIX qw();
use Text::Wrap qw($columns);
use version 0.77 qw();

sub new {
    my ( $class, %attrs ) = @_;
    return bless \%attrs, $class;
}

sub module {
    my $self = shift;
    return $self->{module};
}

sub _normalize_name {
    my $name = shift;

    # Remove "-perl" from the end of the name.
    if ( $name ne 'uni-perl' ) {
        $name =~ s/-perl$//;
    }

    # Prepend "perl-" unless the name starts with "perl-".
    if ( $name !~ /^perl-/ ) {
        $name = 'perl-' . $name;
    }

    # Prepend "c" if the package is built for cperl.
    if ( defined $Config{'usecperl'} ) {
        $name = 'c' . $name;
    }

    return $name;
}

sub _normalize_version {
    my $version = shift;

    if ( !defined $version ) {
        $version = 0;
    }
    else {
        $version =~ s/^v//;
    }
    return $version;
}

sub normalized_name {
    my $self = shift;
    my $name = $self->{normalized_name};
    if ( !$name ) {
        $name = _normalize_name( $self->module->package_name );
        $self->{normalized_name} = $name;
    }
    return $name;
}

sub normalized_version {
    my $self    = shift;
    my $version = $self->{normalized_version};
    if ( !$version ) {
        $version = _normalize_version( $self->module->package_version );
        $self->{normalized_version} = $version;
    }
    return $version;
}

sub distname {
    my $self = shift;
    return $self->normalized_name . q{-} . $self->normalized_version;
}

sub build {
    my $self = shift;

    return $self->{build} || $ENV{BUILD} || 1;
}

sub set_build {
    my ( $self, $build ) = @_;

    return $self->{build} = $build;
}

sub arch {
    my $self = shift;
    my $arch = $self->{arch} || $ENV{ARCH};
    if ( !$arch ) {
        $arch = (POSIX::uname)[4];
        if ( $arch =~ /^i.86$/ ) {
            $arch = 'i586';
        }
        elsif ( $arch =~ /^arm/ ) {
            $arch = 'arm';
        }
    }
    return $arch;
}

sub tag {
    my $self = shift;
    return $self->{tag} || $ENV{TAG} || '_CPANPLUS';
}

sub type {
    my $self = shift;
    return $self->{type} || $ENV{PKGTYPE} || 'tgz';
}

sub filename {
    my $self = shift;
    my $filename
        = $self->distname . q{-}
        . $self->arch . q{-}
        . $self->build
        . $self->tag . q{.}
        . $self->type;
    return $filename;
}

sub outputdir {
    my $self = shift;
    return $self->{outputdir} || $ENV{OUTPUT} || tmpdir();
}

sub outputname {
    my $self       = shift;
    my $outputname = $self->filename;
    my $outputdir  = $self->outputdir;
    if ($outputdir) {
        $outputname = catfile( $outputdir, $outputname );
    }
    return $outputname;
}

sub installdirs {
    my $self = shift;
    return $self->{installdirs};
}

sub prefix {
    my $self = shift;

    my $installdirs = $self->installdirs;

    return $Config{"${installdirs}prefixexp"};
}

sub bindir {
    my $self = shift;

    my $installdirs = $self->installdirs;

    return $Config{"${installdirs}binexp"};
}

sub mandirs {
    my $self = shift;

    my $installdirs = $self->installdirs;

    my %mandir = map {
        my $dir = $Config{"${installdirs}man${_}direxp"};
        if ( !$dir ) {
            $dir = catdir( $self->prefix, 'man', "man${_}" );
        }
        $dir =~ s,/usr/share/man/,/usr/man/,;
        $_ => $dir
    } ( 1, 3 );
    return %mandir;
}

sub docdir {
    my $self = shift;

    my $installdirs = $self->installdirs;

    return catfile( $self->prefix, 'doc', $self->distname );
}

sub docfiles {
    my $self   = shift;
    my $module = $self->module;

    my $wrksrc = $module->status->extract;
    return if !$wrksrc;

    my $dh;
    opendir( $dh, $wrksrc ) or return;
    my @docfiles = grep {
        m{ ^(?:
                AUTHORS
                | BUGS
                | Change(?:s|Log)(?:\.md)?
                | COPYING(?:\.(?:LESSER|LIB))?
                | CREDITS
                | FAQ
                | LICEN[CS]E
                | NEWS
                | README(?:\.(?:md|pod))?
                | THANKS
                | TODO
            )$
        }xi && -f catfile( $wrksrc, $_ )
    } readdir $dh;
    closedir $dh;
    return @docfiles;
}

sub _summary_from_pod {
    my $self    = shift;
    my $module  = $self->module;
    my $srcname = $module->module;

    eval {
        require Pod::Find;
        require Pod::Simple::PullParser;
    } or return;

    my $wrksrc = $module->status->extract;
    return if !$wrksrc;

    my $summary = q{};
    my @dirs    = (
        map { catdir( $wrksrc, $_ ) } qw(blib/lib blib/bin lib bin), $wrksrc
    );
    my $podfile = Pod::Find::pod_where( { -dirs => \@dirs }, $srcname );
    if ($podfile) {
        my $parser = Pod::Simple::PullParser->new;
        $parser->set_source($podfile);
        my $title = $parser->get_title;
        if ( $title && $title =~ /^(?:\S+\s+)+?-+\s+(.+)/xs ) {
            $summary = $1;
        }
        else {

            # XXX Try harder to find a summary.
        }
    }
    return $summary;
}

sub _summary_from_meta {
    my $self   = shift;
    my $module = $self->module;

    eval { require Parse::CPAN::Meta } or return;

    my $wrksrc = $module->status->extract;
    return if !$wrksrc;

    my $summary = q{};
    for (qw(META.yml META.json)) {
        my $metafile = catfile( $wrksrc, $_ );
        if ( -f $metafile ) {
            my $distmeta;
            eval { $distmeta = Parse::CPAN::Meta::LoadFile($metafile) }
                or next;
            if (   $distmeta
                && $distmeta->{abstract}
                && $distmeta->{abstract} !~ /unknown/i )
            {
                $summary = $distmeta->{abstract};
                last;
            }
        }
    }
    return $summary;
}

sub summary {
    my $self   = shift;
    my $module = $self->module;

    my $summary
        = $self->_summary_from_meta
        || $module->description
        || $self->_summary_from_pod
        || q{};
    $summary =~ s/[\r\n]+/ /g;    # Replace vertical whitespace.
    return $summary;
}

sub _webpage {
    my $self   = shift;
    my $module = $self->module;
    my $name   = $module->package_name;

    return "https://metacpan.org/release/$name";
}

sub config_function {
    my $self = shift;

    return <<'END_CONFIG';
config() {
    NEW=$1
    OLD=${NEW%.new}
    # If there's no config file by that name, mv it over:
    if [ ! -r "$OLD" ]; then
        mv "$NEW" "$OLD"
    elif [ -f "$NEW" -a -f "$OLD" ]; then
        NEWCKSUM=$(cat "$NEW" | md5sum)
        OLDCKSUM=$(cat "$OLD" | md5sum)
        if [ "$NEWCKSUM" = "$OLDCKSUM" ]; then
            # toss the redundant copy
            rm "$NEW"
        else
            # preserve perms
            cp -p "$OLD" "${NEW}.incoming"
            cat "$NEW" > "${NEW}.incoming"
            mv "${NEW}.incoming" "$NEW"
        fi
    elif [ -h "$NEW" -a -h "$OLD" ]; then
        NEWLINK=$(readlink -n "$NEW")
        OLDLINK=$(readlink -n "$OLD")
        if [ "$NEWLINK" = "$OLDLINK" ]; then
            # remove the redundant link
            rm "$NEW"
        fi
    fi
    # Otherwise, we leave the .new copy for the admin to consider...
}
END_CONFIG
}

sub _slack_desc_header {
    my ( $self, $indentation_level ) = @_;

    my $tab = q{ } x $indentation_level;

    return <<"END_DESC";
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|'
# on the right side marks the last column you can put a character in.  You must
# make exactly 11 lines for the formatting to be correct.  It's also
# customary to leave one space after the ':'.

$tab|-----handy-ruler------------------------------------------------------|
END_DESC
}

sub slack_desc {
    my $self = shift;

    my $name    = $self->normalized_name;
    my $prefix  = "$name:";
    my $title   = "$prefix $name";
    my $summary = $self->summary;
    my $webpage = $self->_webpage;

    # Format the summary.
    my $tab = "$prefix ";
    $columns = 71 + length $tab;
    my $body = Text::Wrap::wrap( $tab, $tab, $summary );

    my $max_body_line_count = 9;    # 11 - 2

    # How long in lines is the formatted text?
    my $body_line_count = @{ [ $body =~ /^\Q$tab\E/mg ] };
    if ( $body_line_count < $max_body_line_count ) {

        # Add the distribution's webpage if there is enough space left.
        my $link = Text::Wrap::wrap( $tab, $tab,
            "For more info, visit: $webpage" );
        my $link_line_count = @{ [ $link =~ /^\Q$tab\E/mg ] };
        if ( $body_line_count + $link_line_count < $max_body_line_count ) {
            if ( $body_line_count > 0 ) {

                # Insert an empty line between the summary and the link.
                $body .= "\n$prefix\n";
                ++$body_line_count;
            }
            $body .= $link;
            $body_line_count += $link_line_count;
        }

        # Add empty lines if necessary.
        $body .= "\n$prefix" x ( $max_body_line_count - $body_line_count );
    }
    elsif ( $body_line_count > $max_body_line_count ) {

        # Cut the summary if it is too long.
        $body = join "\n",
            ( split /\n/, $body )[ 0 .. $max_body_line_count - 1 ];
    }
    return
          $self->_slack_desc_header( length $name )
        . "$title\n"
        . "$prefix\n"
        . "$body\n";
}

sub build_script {
    my $self        = shift;
    my $module      = $self->module;
    my $name        = $module->package_name;
    my $version     = $module->package_version;
    my $installdirs = $self->installdirs;

    # Quote single quotes.
    $name =~ s/('+)/'"$1"'/g;
    $version =~ s/('+)/'"$1"'/g;

    return <<"END_SCRIPT";
#!/bin/sh
SRCNAM='$name'
VERSION=\${VERSION:-'$version'}
INSTALLDIRS=\${INSTALLDIRS:-$installdirs}
cpan2dist --format CPANPLUS::Dist::Slackware --dist-opts installdirs=\$INSTALLDIRS \$SRCNAM-\$VERSION
END_SCRIPT
}

sub _prereqs {
    my $self   = shift;
    my $module = $self->module;
    my $cb     = $module->parent;

    my $perl_version = version->parse($PERL_VERSION);
    my %prereqs;
    my $prereq_ref = $module->status->prereqs;
    if ($prereq_ref) {
        for my $srcname ( keys %{$prereq_ref} ) {
            my $modobj = $cb->module_tree($srcname);
            next if !$modobj;

            # Don't list core modules as prerequisites.
            next if $modobj->package_is_perl_core;

            # Task::Weaken is only a build dependency.
            next if $modobj->package_name eq 'Task-Weaken';

            # Omit modules that are distributed with Perl.
            my $version = $prereq_ref->{$srcname};
            my $s       = Module::CoreList->removed_from($srcname);
            if ( !defined $s || $perl_version < version->parse($s) ) {
                ## cpan2dist is run with -w, which triggers a warning in
                ## Module::CoreList.
                local $WARNING = 0;
                my $r = Module::CoreList->first_release( $srcname, $version );
                next if defined $r && version->parse($r) <= $perl_version;
            }

            my $name = _normalize_name( $modobj->package_name );
            if ( !exists $prereqs{$name}
                || version->parse( $prereqs{$name} )
                < version->parse($version) )
            {
                $prereqs{$name} = $version;
            }
        }
    }
    my @prereqs
        = map { { name => $_, version => _normalize_version( $prereqs{$_} ) } }
        sort { uc $a cmp uc $b } keys %prereqs;
    return @prereqs;
}

sub readme_slackware {
    my $self    = shift;
    my $module  = $self->module;
    my $name    = $module->package_name;
    my $version = $module->package_version;

    $columns = 78;

    my $title  = "$name for Slackware Linux";
    my $line   = q{=} x length $title;
    my $readme = "$title\n$line\n\n";

    my @prereqs = $self->_prereqs;

    my $text = 'This package was created by CPANPLUS::Dist::Slackware'
        . " from the Perl distribution '$name' version $version.";
    $readme .= Text::Wrap::wrap( q{}, q{}, $text ) . "\n";

    if (@prereqs) {
        $readme
            .= "\n"
            . "Required modules\n"
            . "----------------\n\n"
            . "The following Perl packages are required:\n\n";
        for my $prereq (@prereqs) {
            my $prereq_name    = $prereq->{name};
            my $prereq_version = $prereq->{version};
            $readme .= "* $prereq_name";
            if ( $prereq_version ne '0' ) {
                $readme .= " >= $prereq_version";
            }
            $readme .= "\n";
        }
    }

    return $readme;
}

sub destdir {
    my $self = shift;

    my $module  = $self->module;
    my $cb      = $module->parent;
    my $destdir = $self->{destdir};
    if ( !$destdir ) {
        my $template = 'package-' . $self->normalized_name . '-XXXXXXXXXX';
        my $wrkdir = $ENV{TMP} || catdir( tmpdir(), 'CPANPLUS' );
        if ( !-d $wrkdir ) {
            $cb->_mkdir( dir => $wrkdir )
                or die "Could not create directory '$wrkdir': $OS_ERROR\n";
        }
        $destdir = File::Temp::tempdir( $template, DIR => $wrkdir );
        chmod oct '0755', $destdir
            or die "Could not chmod '$destdir': $OS_ERROR\n";
        $self->{destdir} = $destdir;
    }
    return $destdir;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::PackageDescription - Collect information on a new Slackware compatible package

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::PackageDescription version 1.030.

=head1 SYNOPSIS

    use CPANPLUS::Dist::Slackware::PackageDescription;

    $pkgdesc = CPANPLUS::Dist::Slackware::PackageDescription->new(
        module => $modobj,
        tag    => '_MYTAG',
        type   => 'txz'
    );

    $filename = $pkgdesc->filename();
    $summary  = $pkgdesc->summary();
    $desc     = $pkgdesc->slack_desc();
    @docfiles = $pkgdesc->docfiles();

=head1 DESCRIPTION

This module gets information on a yet to be created Slackware compatible
package.  The information is obtained from a CPANPLUS::Module object, the
file system and the environment.  Among other things, the module translates a
Perl distribution's name and version into a package name.  It tries to find a
short summary that describes the distribution.  It can build a F<slack_desc>
description for you.  It finds standard documentation files like F<README> and
F<Changes>.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< CPANPLUS::Dist::Slackware::PackageDescription->new(%attrs) >>

Returns a newly constructed object.

    $pkgdesc = CPANPLUS::Dist::Slackware::PackageDescription->new(
        module => $modobj,
        %attrs
    );

The CPANPLUS::Module object is mandatory.  All other attributes are
optional.

=item B<< $pkgdesc->module >>

Returns the CPANPLUS::Module object that was passed to the constructor.

=item B<< $pkgdesc->normalized_name >>

Returns the package name, e.g. "perl-Some-Module".

=item B<< $pkgdesc->normalized_version >>

Returns the package version, e.g. "0.01".

=item B<< $pkgdesc->distname >>

Returns the package name and version, e.g. "perl-Some-Module-0.01".

=item B<< $pkgdesc->build >>

Returns the package's build number.  Defaults to C<$ENV{BUILD}> or "1".

=item B<< $pkgdesc->set_build >>

Sets the package's build number.

=item B<< $pkgdesc->arch >>

Returns the package architecture.  If unset, either the value of C<$ENV{ARCH}>
or a platform-specific identifier like "i586" is returned.

=item B<< $pkgdesc->tag >>

Returns a tag that is added to the package filename.  Defaults to C<$ENV{TAG}>
or "_CPANPLUS".

=item B<< $pkgdesc->type >>

Returns the package extension.  Defaults to C<$ENV{PKGTYPE}> or "tgz".  Other
possible values are "tbz", "tlz" and "txz".

=item B<< $pkgdesc->filename >>

Returns the package's filename, e.g.
F<perl-Some-Module-0.01-i586-1_CPANPLUS.tgz>.

=item B<< $pkgdesc->outputdir >>

Returns the directory where all created packages are stored.  Defaults to
F<$OUTPUT>, F<$TMPDIR> or F</tmp>.

=item B<< $pkgdesc->outputname >>

Returns the package's full filename, e.g.
F</tmp/perl-Some-Module-0.01-i586-1_CPANPLUS.tgz>.

=item B<< $pkgdesc->installdirs >>

Returns "vendor" or "site".

=item B<< $pkgdesc->prefix >>

Returns the directory below which the package will be installed, e.g. "/usr"
or "/usr/local".

=item B<< $pkgdesc->bindir >>

Returns the location of executables, e.g. "/usr/bin".

=item B<< $pkgdesc->mandirs >>

Returns a map of manual page directories, e.g. (1 => "/usr/man/man1", 3 =>
"/usr/man/man3").

=item B<< $pkgdesc->docdir >>

Returns the packages's documentation directory, e.g.
F</usr/doc/perl-Some-Module-0.01>.

=item B<< $pkgdesc->docfiles >>

Returns a list of standard documentation files that the distribution contains,
e.g. C<("Changes", "LICENSE, "README")>.  The filenames are relative to the
distribution's top-level directory.

Must be called after the distribution has been extracted.

=item B<< $pkgdesc->summary >>

Returns a description of the distribution's purpose, e.g. "Drop atomic bombs
on Australia".

Must not be called before the distribution has been extracted.  Gives better
results when called after the distribution has been built, i.e. when the
"blib" directory is available.

=item B<< $pkgdesc->config_function >>

Returns a C<config> shell function that can be added to the F<doinst.sh>
script in the package's F<install> directory.

Only the shell function is returned.  You have to add the C<config> function
calls for each configuration file yourself.

=item B<< $pkgdesc->slack_desc >>

Returns a Slackware package description that can be written to the
F<slack-desc> file in the package's F<install> directory.

=item B<< $pkgdesc->build_script >>

Returns a build script that can be written to F<perl-Some-Module.SlackBuild>
in the package's documentation directory.

=item B<< $pkgdesc->readme_slackware >>

Returns the text of a F<README.SLACKWARE> file that can be stored in the
package's documentation directory.  The returned document lists the build
dependencies.  You can add more text to this document, e.g. a list of
configuration files provided by the package.

=item B<< $pkgdesc->destdir >>

Returns the staging directory where the distribution is temporarily installed,
e.g. F</tmp/CPANPLUS/package-perl-Some-Module-01yEr7X43K>.  Defaults to a
package-specific subdirectory in F<$TMP> or F</tmp/CPANPLUS>.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

See above and CPANPLUS::Dist::Slackware for supported environment variables.

=head1 DEPENDENCIES

See CPANPLUS::Dist::Slackware.

=head1 INCOMPATIBILITIES

None known.

=head1 SEE ALSO

CPANPLUS::Dist::Slackware

=head1 AUTHOR

Andreas Voegele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

Please report any bugs using the issue tracker at
L<https://github.com/graygnuorg/CPANPLUS-Dist-Slackware/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2020 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See https://dev.perl.org/licenses/ for more information.

=cut
