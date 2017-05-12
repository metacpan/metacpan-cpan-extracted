#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Update;
# ABSTRACT: update command implementation
$App::Magpie::Action::Update::VERSION = '2.010';
use CPAN::Mini;
use File::Copy;
use Moose;
use Parse::CPAN::Packages::Fast;
use Path::Tiny;
use version;

with 'App::Magpie::Role::Logging';
with 'App::Magpie::Role::RunningCommand';



sub run {
    my ($self) = @_;

    # check if there's a spec file to update...
    my $specdir = path("SPECS");
    -e $specdir or $self->log_fatal("cannot find a SPECS directory, aborting");
    my @specfiles =
        grep { /\.spec$/ }
        $specdir->children;
    scalar(@specfiles) > 0
        or $self->log_fatal("could not find a spec file, aborting");
    scalar(@specfiles) < 2
        or $self->log_fatal("more than one spec file found, aborting");
    my $specfile = shift @specfiles;
    my $spec = $specfile->slurp;
    my $pkgname = $specfile->basename; $pkgname =~ s/\.spec$//;
    $self->log( "updating $pkgname" );

    # check if package uses %upstream_{name|version}
    my ($distname) = ( $spec =~ /^%define\s+upstream_name\s+(.*)$/m );
    my ($distvers) = ( $spec =~ /^%define\s+upstream_version\s+(.*)$/m );
    defined($distname) or $self->log_fatal( "package does not use %upstream_name" );
    defined($distvers) or $self->log_fatal( "package does not use %upstream_version" );
    $self->log_debug( "perl distribution to update: $distname v$distvers" );

    # check if we have a minicpan at hand
    my $cpanmconf = CPAN::Mini->config_file;
    defined($cpanmconf)
        or $self->log_fatal("no minicpan installation found, aborting");
    my %config   = CPAN::Mini->read_config( {quiet=>1} );
    my $cpanmdir = path( $config{local} );
    $self->log_debug( "found a minicpan installation in $cpanmdir" );

    # try to find a newer version
    $self->log_debug( "parsing 02packages.details.txt.gz" );
    my $modgz   = $cpanmdir->child("modules", "02packages.details.txt.gz");
    my $p       = Parse::CPAN::Packages::Fast->new( $modgz->stringify );
    my $dist    = $p->latest_distribution( $distname );
    my $newvers = $dist->version;
    if ( version->new( $newvers ) <= version->new( $distvers ) ) {
        $self->log( "no new version found" );
        if ( path("refresh")->exists ) {
            $self->log( "... but a previous 'refresh' script was found, trying to run it" );
            $self->run_command( "./refresh" );
            return;
        }
        $self->log_fatal( "... and no previous 'refresh' script found, aborting" );
    }
    $self->log( "new version found: $newvers" );

    # copy tarball
    my $cpantarball = $cpanmdir->child( "authors", "id", $dist->prefix );
    my $tarball     = $dist->filename;
    $self->log_debug( "copying $tarball to SOURCES" );
    copy( $cpantarball->stringify, "SOURCES" )
        or $self->log_fatal( "could not copy $cpantarball to SOURCES: $!" );
    my $suffix = $tarball; $suffix =~ s/.*$newvers\.//g;
    $self->log( "new suffix: $suffix" );

    # update spec file
    $self->log_debug( "updating spec file $specfile" );
    $spec =~ s/%mkrel \d+/%mkrel 1/;
    $spec =~ s/^(%define\s+upstream_version)\s+.*/$1 $newvers/m;
    $spec =~ s/^(source.*upstream_version[^.]*)\..*/$1.$suffix/mi;
    my $specfh = $specfile->openw;
    $specfh->print( $spec );
    $specfh->close;

    # create script
    my $script  = path( "refresh" );
    my $fh = $script->openw;
    $fh->print(<<EOF);
#!/bin/bash
magpie fix -v                  && \\
bm -l                          && \\
mgarepo sync                   && \\
svn ci -m "update to $newvers" && \\
mgarepo submit                 && \\
rm \$0
EOF
    $fh->close;
    chmod 0755, $script;

    # try to install buildrequires
    if ( ! $ENV{MAGPIE_NO_URPMI_BUILDREQUIRES} ) {
        $self->log( "installing buildrequires" );
        $self->run_command( "LC_ALL=C sudo urpmi --wait-lock --buildrequires $specfile" );
    }

    # fix spec file, update buildrequires
    require App::Magpie::Action::FixSpec;
    App::Magpie::Action::FixSpec->new->run;

    # local dry-run
    $self->log( "trying to build package locally" );
    $self->run_command( "bm -l" );

    # push changes
    $self->log( "committing changes" );
    $self->run_command( "mgarepo sync" );
    $self->run_command( "svn ci -m 'update to $newvers'" );

    # submit
    require App::Magpie::Action::BSWait;
    App::Magpie::Action::BSWait->new->run;
    $self->log( "submitting package" );
    $self->run_command( "mgarepo submit" );
    $script->remove;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Update - update command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $update = App::Magpie::Action::Update->new;
    $update->run;

=head1 DESCRIPTION

This module implements the C<update> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    $update->run;

Try to update the current checked-out package to its latest version, if
there's one available.

=head1 ENVIRONMENT VARS

F<MAGPIE_NO_URPMI_BUILDREQUIRES> prevents update to try installation of
the buildrequires.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
