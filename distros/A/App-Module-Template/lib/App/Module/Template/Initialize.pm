package App::Module::Template::Initialize;

use strict;
use warnings;

our $VERSION = '0.11';

use base qw(Exporter);

use Carp;
use File::Path qw/make_path/;
use File::HomeDir;
use File::Spec;

our (@EXPORT_OK, %EXPORT_TAGS);

@EXPORT_OK = qw(
    module_template
    _get_tmpl_body
    _get_tmpl_file
    _get_tmpl_path
    _make_tmpl_path
    _write_tmpl_file
); # on demand
%EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
);

=pod

=head1 NAME

App::Module::Template::Initialize - Templates to pre-populate template directory

=head1 VERSION

This documentation refers to App::Module::Template::Initialize version 0.11.

=head1 SYNOPSIS

    use App::Module::Template::Initialize qw/module_template/;

    module_template($path);

=head1 DESCRIPTION

App::Module::Template::Initialize contains the templates and method to initialize the .module-templates/templates directory for use by module-template.

See module-template for configuration and usage.

=head1 SUBROUTINES/METHODS

=over

=item C<module_template>

This subroutine iterates the templates and creates files and directories in $HOME/.module-template.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

=item * Carp

=item * File::Path

=item * File::HomeDir

=item * File::Spec

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any issues or feature requests to L<https://github.com/tscornpropst/App-Module-Template/issues>. Patches are welcome.

=head1 AUTHOR

Trevor S. Cornpropst <tscornpropst@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Trevor S. Cornpropst <tscornpropst@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut


our $TEMPLATES = {
    config => {
        file => 'config',
        path => '.module-template',
        body => <<'END_OF_BODY',
author           = Default Author
email            = author@example.com
support_address  = support@example.com
min_perl_version = 5.016
eumm_version     = 6.63
license_type     = artistic_2
license_body     =<<END_OF_LICENSE
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
END_OF_LICENSE

<template_toolkit>
  PRE_CHOMP = 0
  POST_CHOMP = 0
  ENCODING = utf8
  ABSOLUTE = 1
  RELATIVE = 1
</template_toolkit>
END_OF_BODY
    },
    gitignore => {
        file => '.gitignore',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
/blib/
/.build/
_build/
cover_db/
inc/
Build
!Build/
Build.bat
.last_cover_stats
/Makefile
/Makefile.old
/MANIFEST.bak
/META.yml
/META.json
/MYMETA.*
nytprof.out
/pm_to_blib
*.o
*.bs
*.swp
END_OF_BODY
    },
    travis_yml => {
        file => '.travis.yml',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
language: perl
perl:
  - "5.20"
  - "5.18"
  - "5.16"

before_install:
  - cpanm --quiet --notest Devel::Cover::Report::Coveralls

install:
  - cpanm --quiet --notest --installdeps .

script:
  - PERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine prove -l t
  - cover

after_success:
  - cover -report coveralls
END_OF_BODY
    },
    makefile_pl => {
        file => 'Makefile.PL',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
use strict;
use warnings;

use [% min_perl_version %];

use ExtUtils::MakeMaker [% eumm_version %];

my %WriteMakefileArgs = (
    NAME                  => '[% module %]',
    AUTHOR                => '[% author %] <[% email %]>',
    VERSION_FROM          => '[% module_path %]',
    ABSTRACT_FROM         => '[% module_path %]',
    LICENSE               => '[% license_type %]',
    DISTNAME              => '[% dist %]',
    MIN_PERL_VERSION      => [% min_perl_version %],
    BUILD_REQUIRES        => {
        'ExtUtils::MakeMaker' => [% eumm_version %],
    },
    CONFIGURE_REQUIRES    => {
        'ExtUtils::MakeMaker' => [% eumm_version %],
    },
    PREREQ_PM             => {
        'Carp'            => 0,
        'POSIX'           => 0,
        #'Some::Module' => 1.23,
    },
    TEST_REQUIRES         => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    test                  => { "TESTS" => "t/*.t", },
    dist                  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                 => { FILES => '-*' },
);

my %FallbackPrereqs = (
    'Carp'                => 0,
    'POSIX'               => 0,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
END_OF_BODY
    },
    license => {
        file => 'LICENSE',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
The Artistic License 2.0

           Copyright (c) [% year %] [% author %]

     Everyone is permitted to copy and distribute verbatim copies
      of this license document, but changing it is not allowed.

Preamble

This license establishes the terms under which a given free software
Package may be copied, modified, distributed, and/or redistributed.
The intent is that the Copyright Holder maintains some artistic
control over the development of that Package while still keeping the
Package available as open source and free software.

You are always permitted to make arrangements wholly outside of this
license directly with the Copyright Holder of a given Package.  If the
terms of this license do not permit the full use that you propose to
make of the Package, you should contact the Copyright Holder and seek
a different licensing arrangement.

Definitions

    "Copyright Holder" means the individual(s) or organization(s)
    named in the copyright notice for the entire Package.

    "Contributor" means any party that has contributed code or other
    material to the Package, in accordance with the Copyright Holder's
    procedures.

    "You" and "your" means any person who would like to copy,
    distribute, or modify the Package.

    "Package" means the collection of files distributed by the
    Copyright Holder, and derivatives of that collection and/or of
    those files. A given Package may consist of either the Standard
    Version, or a Modified Version.

    "Distribute" means providing a copy of the Package or making it
    accessible to anyone else, or in the case of a company or
    organization, to others outside of your company or organization.

    "Distributor Fee" means any fee that you charge for Distributing
    this Package or providing support for this Package to another
    party.  It does not mean licensing fees.

    "Standard Version" refers to the Package if it has not been
    modified, or has been modified only in ways explicitly requested
    by the Copyright Holder.

    "Modified Version" means the Package, if it has been changed, and
    such changes were not explicitly requested by the Copyright
    Holder.

    "Original License" means this Artistic License as Distributed with
    the Standard Version of the Package, in its current version or as
    it may be modified by The Perl Foundation in the future.

    "Source" form means the source code, documentation source, and
    configuration files for the Package.

    "Compiled" form means the compiled bytecode, object code, binary,
    or any other form resulting from mechanical transformation or
    translation of the Source form.


Permission for Use and Modification Without Distribution

(1)  You are permitted to use the Standard Version and create and use
Modified Versions for any purpose without restriction, provided that
you do not Distribute the Modified Version.


Permissions for Redistribution of the Standard Version

(2)  You may Distribute verbatim copies of the Source form of the
Standard Version of this Package in any medium without restriction,
either gratis or for a Distributor Fee, provided that you duplicate
all of the original copyright notices and associated disclaimers.  At
your discretion, such verbatim copies may or may not include a
Compiled form of the Package.

(3)  You may apply any bug fixes, portability changes, and other
modifications made available from the Copyright Holder.  The resulting
Package will still be considered the Standard Version, and as such
will be subject to the Original License.


Distribution of Modified Versions of the Package as Source

(4)  You may Distribute your Modified Version as Source (either gratis
or for a Distributor Fee, and with or without a Compiled form of the
Modified Version) provided that you clearly document how it differs
from the Standard Version, including, but not limited to, documenting
any non-standard features, executables, or modules, and provided that
you do at least ONE of the following:

    (a)  make the Modified Version available to the Copyright Holder
    of the Standard Version, under the Original License, so that the
    Copyright Holder may include your modifications in the Standard
    Version.

    (b)  ensure that installation of your Modified Version does not
    prevent the user installing or running the Standard Version. In
    addition, the Modified Version must bear a name that is different
    from the name of the Standard Version.

    (c)  allow anyone who receives a copy of the Modified Version to
    make the Source form of the Modified Version available to others
    under

    (i)  the Original License or

    (ii)  a license that permits the licensee to freely copy,
    modify and redistribute the Modified Version using the same
    licensing terms that apply to the copy that the licensee
    received, and requires that the Source form of the Modified
    Version, and of any works derived from it, be made freely
    available in that license fees are prohibited but Distributor
    Fees are allowed.


Distribution of Compiled Forms of the Standard Version
or Modified Versions without the Source

(5)  You may Distribute Compiled forms of the Standard Version without
the Source, provided that you include complete instructions on how to
get the Source of the Standard Version.  Such instructions must be
valid at the time of your distribution.  If these instructions, at any
time while you are carrying out such distribution, become invalid, you
must provide new instructions on demand or cease further distribution.
If you provide valid instructions or cease distribution within thirty
days after you become aware that the instructions are invalid, then
you do not forfeit any of your rights under this license.

(6)  You may Distribute a Modified Version in Compiled form without
the Source, provided that you comply with Section 4 with respect to
the Source of the Modified Version.


Aggregating or Linking the Package

(7)  You may aggregate the Package (either the Standard Version or
Modified Version) with other packages and Distribute the resulting
aggregation provided that you do not charge a licensing fee for the
Package.  Distributor Fees are permitted, and licensing fees for other
components in the aggregation are permitted. The terms of this license
apply to the use and Distribution of the Standard or Modified Versions
as included in the aggregation.

(8) You are permitted to link Modified and Standard Versions with
other works, to embed the Package in a larger work of your own, or to
build stand-alone binary or bytecode versions of applications that
include the Package, and Distribute the result without restriction,
provided the result does not expose a direct interface to the Package.


Items That are Not Considered Part of a Modified Version

(9) Works (including, but not limited to, modules and scripts) that
merely extend or make use of the Package, do not, by themselves, cause
the Package to be a Modified Version.  In addition, such works are not
considered parts of the Package itself, and are not subject to the
terms of this license.


General Provisions

(10)  Any use, modification, and distribution of the Standard or
Modified Versions is governed by this Artistic License. By using,
modifying or distributing the Package, you accept this license. Do not
use, modify, or distribute the Package, if you do not accept this
license.

(11)  If your Modified Version has been derived from a Modified
Version made by someone other than you, you are nevertheless required
to ensure that your Modified Version complies with the requirements of
this license.

(12)  This license does not grant you the right to use any trademark,
service mark, tradename, or logo of the Copyright Holder.

(13)  This license includes the non-exclusive, worldwide,
free-of-charge patent license to make, have made, use, offer to sell,
sell, import and otherwise transfer the Package with respect to any
patent claims licensable by the Copyright Holder that are necessarily
infringed by the Package. If you institute patent litigation
(including a cross-claim or counterclaim) against any party alleging
that the Package constitutes direct or contributory patent
infringement, then this Artistic License to you shall terminate on the
date that such litigation is filed.

(14)  Disclaimer of Warranty:
THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS
IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL
LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
END_OF_BODY
    },
    changes => {
        file => 'Changes',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
Revision history for [% module %]

Author [% author %]
Email [% email %]

0.01    [% today %]
        [% module %] created

END_OF_BODY
    },
    readme => {
        file => 'README',
        path => '.module-template/templates',
        body => <<'END_OF_BODY',
[% module %] is Copyright (C) [% year %], [% author %].

INSTALLATION

To install this module, run the following commands:

        perl Makefile.PL
        make
        make test
        make install

SUPPORT AND DOCUMENTATION

After install, you can find documentation for this module with the
perldoc command.

        perldoc [% module %]

LICENSE INFORMATION

This [library|program|code|module] is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. For details, see the full text of the license in the file LICENSE.
END_OF_BODY
    },
    script => {
        file => 'script.pl',
        path => '.module-template/templates/bin',
        body => <<'END_OF_BODY',
#!/usr/bin/perl
#
# AUTHOR: [% author %], [% email %]
# CREATED: [% today %]

use [% min_perl_version %];

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use POSIX qw(strftime);

__END__

=pod

=head1 NAME

[% module %] - <one line description>

=head1 VERSION

This documentation refers to [% module %] version 0.01.

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=head1 DESCRIPTION

=head1 REQUIREMENTS

None.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION

None.

=head1 EXIT STATUS

None.

=head1 DEPENDENCIES

=over

=item * Carp

=item * POSIX

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any issues or feature requests to L<[% support_address %]>. Patches are welcome.

=head1 AUTHOR

[% author %] <[% email %]>

=head1 COPYRIGHT AND LICENSE

Copyright (c) [% year %], [% author %] <[% email %]>. All rights reserved.

[% license_body %]

=cut

END_OF_BODY
    },
    module => {
        file => 'Module.pm',
        path => '.module-template/templates/lib',
        body => <<'END_OF_BODY',
package [% module %];

use [% min_perl_version %];

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

use Carp;
use POSIX qw(strftime);

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@EXPORT      = qw(); # by default, don't do this unless absolutely necessary
@EXPORT_OK   = qw(); # on demand
%EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
);

{
#-------------------------------------------------------------------------------
sub new {
    my ($class, $arg) = @_;

    my $self = bless {}, $class;

    $self->_init($args);

    return $self;
}

#-------------------------------------------------------------------------------
sub _init {
    my ($self, $arg) = @_;

#    $self->SUPER::_init($arg);

    return;
}

}

1;

__END__

=pod

=head1 NAME

[% module %] - <one line description>

=head1 VERSION

This documentation refers to [% module %] version 0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over

=item C<function_name>

=back

=head1 EXAMPLES

None.

=head1 DIAGNOSTICS

=over

=item B<Error Message>

=item B<Error Message>

=back

=head1 CONFIGURATION AND ENVIRONMENT

[% module %] requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item * Carp

=item * POSIX

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any issues or feature requests to L<[% support_address %]>. Patches are welcome.

=head1 AUTHOR

[% author %] <[% email %]>

=head1 COPYRIGHT AND LICENSE

Copyright (c) [% year %], [% author %] <[% email %]>. All rights reserved.

[% license_body %]

=cut

END_OF_BODY
    },
    load_test => {
        file => '00-load.t',
        path => '.module-template/templates/t',
        body => <<'END_OF_BODY',
#!perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok( '[% module %]' );

diag( "Testing [% module %] $[% module %]::VERSION, Perl $], $^X" );
END_OF_BODY
    },
    critic_test => {
        file => 'critic.t',
        path => '.module-template/templates/xt/author',
        body => <<'END_OF_BODY',
#!perl

use strict;
use warnings;

use File::Spec;
use Test::More;

eval { require Test::Perl::Critic; };

if ( $@ ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 'xt/author', 'perlcritic.rc' );

Test::Perl::Critic->import( -profile => $rcfile );

all_critic_ok();
END_OF_BODY
    },
    critic_rc => {
        file => 'perlcritic.rc',
        path => '.module-template/templates/xt/author',
        body => <<'END_OF_BODY',
severity = 1
color = 1
verbose = 8

# Configure these policies
[InputOutput::RequireCheckedSyscalls]
exclude_functions = print
[Documentation::RequirePodSections]
lib_sections = NAME | VERSION | SYNOPSIS | DESCRIPTION | SUBROUTINES/METHODS | DIAGNOSTICS | CONFIGURATION AND ENVIRONMENT | DEPENDENCIES | INCOMPATIBILITIES | BUGS AND LIMITATIONS | AUTHOR | COPYRIGHT AND LICENSE
script_sections = NAME | USAGE | DESCRIPTION | REQUIRED ARGUMENTS | OPTIONS | DIAGNOSTICS | EXIT STATUS | CONFIGURATION | DEPENDENCIES | INCOMPATIBILITIES | BUGS AND LIMITATIONS | AUTHOR | COPYRIGHT AND LICENSE

# Do not load these policies
[-CodeLayout::ProhibitParensWithBuiltins]
[-CodeLayout::RequireTidyCode]
[-ControlStructures::ProhibitCStyleForLoops]
[-ControlStructures::ProhibitPostfixControls]
[-ControlStructures::ProhibitUnlessBlocks]
[-Subroutines::ProhibitBuiltinHomonyms]
[-ValuesAndExpressions::ProhibitNoisyQuotes]
[-ValuesAndExpressions::RequireInterpolationOfMetachars]
[-Variables::ProhibitPunctuationVars]
END_OF_BODY
    },
    pod_coverage_test => {
        file => 'pod-coverage.t',
        path => '.module-template/templates/xt/author',
        body => <<'END_OF_BODY',
#!perl

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
END_OF_BODY
    },
    pod_syntax_test => {
        file => 'pod-syntax.t',
        path => '.module-template/templates/xt/release',
        body => <<'END_OF_BODY',
#!perl

use strict;
use warnings;

use Test::More;

my $min_tp = 1.41;

eval "use Test::Pod $min_tp";

plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
END_OF_BODY
    },
    kwalitee_test => {
        file => 'kwalitee.t',
        path => '.module-template/templates/xt/release',
        body => <<'END_OF_BODY',
#!perl

use strict;
use warnings;

use Test::More;
use Test::Kwalitee qw/kwalitee_ok/;

kwalitee_ok();

done_testing();
END_OF_BODY
    },
};

#-------------------------------------------------------------------------------
sub module_template {
    my ($base_path) = @_;

    my $tmpl_path = defined $base_path
        ? $base_path
        : File::HomeDir->my_home();

    # Don't clobber an existing configuration
    my $path_to_app_dir = File::Spec->catdir( $tmpl_path, '.module-template' );

    if ( -d $path_to_app_dir ) {
        croak "Directory $path_to_app_dir exists. Manually remove this directory before proceeding.";
    }

    for my $tmpl_name (keys %{$TEMPLATES}) {
        _make_tmpl_path($tmpl_path, $tmpl_name);
        _write_tmpl_file($tmpl_path, $tmpl_name);
    }

    return $path_to_app_dir;
}

#-------------------------------------------------------------------------------
sub _get_tmpl_body {
    my ($template_name) = @_;

    return exists $TEMPLATES->{$template_name}{body}
        ? $TEMPLATES->{$template_name}{body}
        : undef;
}

#-------------------------------------------------------------------------------
sub _get_tmpl_file {
    my ($template_name) = @_;

    return exists $TEMPLATES->{$template_name}{file}
        ? $TEMPLATES->{$template_name}{file}
        : undef;
}

#-------------------------------------------------------------------------------
sub _get_tmpl_path {
    my ($template_name) = @_;

    return exists $TEMPLATES->{$template_name}{path}
        ? $TEMPLATES->{$template_name}{path}
        : undef;
}

#-------------------------------------------------------------------------------
sub _make_tmpl_path {
    my ($base_path, $template_name) = @_;

    return unless ( ( $base_path ) and ( $template_name ) );

    return unless exists $TEMPLATES->{$template_name};

    my $template_path = _get_tmpl_path($template_name);

    my $fq_path = File::Spec->catdir( $base_path, $template_path );

    # make_path silently fails on existing directories
    make_path($fq_path);

    return $fq_path;
}

#-------------------------------------------------------------------------------
sub _write_tmpl_file {
    my ($base_path, $template_name) = @_;

    return unless ( ( $base_path ) and ( $template_name ) );

    return unless exists $TEMPLATES->{$template_name};

    my $template_path = _get_tmpl_path($template_name);

    my $template_file = _get_tmpl_file($template_name);

    my $fqfn = File::Spec->catfile( $base_path, $template_path, $template_file );

    open ( my $fh, '>', $fqfn ) or croak "Couldn't open '$fqfn': $!";

    print {$fh} _get_tmpl_body($template_name);

    close $fh;

    return $fqfn;
}

1;

__END__
