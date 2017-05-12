package Bigtop::Backend::Init::Std;
use strict; use warnings;

use Cwd;        # for use in manifest updates
use ExtUtils::Manifest;
use File::Find;
use File::Spec;
use File::Basename;
use File::Copy;
use Inline;

my %stubs = (
    'Build.PL'      => 1,
    'Changes'       => 1,
    'MANIFEST.SKIP' => 1,
    'README'        => 1,
);

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'app',
            qw(
                authors
                email
                contact_us
                copyright_holder
                license_text
            ),
        )
    );
}

sub what_do_you_make {
    return [
        [ 'Build.PL'         => 'Module::Build script'                       ],
        [ 'Changes'          => 'Almost empty Changes file'                  ],
        [ 'README'           => 'Boilerplate README'                         ],
        [ 'lib/'             => 'lib dir used by Control and Model backends' ],
        [ 't/'               => 'testing dir used by Control backend'        ],
        [ 'docs/name.bigtop' => 'Copy of your bigtop file [create mode only]'],
    ];
}

sub backend_block_keywords {
    my @trailer = ( 'backward_boolean', '', '', 'no_gen' );
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip MANIFEST generation',
          type    => 'boolean' },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },
    ];
}

sub validate_build_dir {
    my $class      = shift;
    my $build_dir  = shift;
    my $tree       = shift;
    my $create     = shift;

    my $warning_signs = 0;
    if ( -d $build_dir ) {
        unless ( $create ) {
            # see if there are familiar surroundings in the build_dir
            my $buildpl = File::Spec->catfile( $build_dir, 'Build.PL' );
            my $changes = File::Spec->catfile( $build_dir, 'Changes'  );
            my $t       = File::Spec->catdir(  $build_dir, 't'        );
            my $lib     = File::Spec->catdir(  $build_dir, 'lib'      );

            $warning_signs++ unless ( -f $buildpl );
            $warning_signs++ unless ( -f $changes );
            $warning_signs++ unless ( -d $t       );
            $warning_signs++ unless ( -d $lib     );

            # dig deep for the main module
            my $app_name   = $tree->get_appname();
            my @mod_pieces = split /::/, $app_name;
            my $main_mod   = pop @mod_pieces;
            $main_mod      .= '.pm';

            my $saw_base   = 0;
            my $wanted     = sub {
                $saw_base++ if ( $_ eq $main_mod );
            };

            find( $wanted, $build_dir );

            $warning_signs++ unless ( $saw_base );
        }
    }
    else {
        die "$build_dir does not exist, and I couldn't make it.\n";
    }

    if ( $warning_signs > 2 ) {
        my $base_dir          = $tree->{configuration}{base_dir} || '.';
        my $config_build_dir  = $base_dir;
        if ( $tree->{configuration}{app_dir} ) {
            $config_build_dir = File::Spec->catdir(
                $base_dir, $tree->{configuration}{app_dir}
            );
        }
        die "$build_dir doesn't look like a build dir (level=$warning_signs),\n"
          . "  use --create to force a build in or under $config_build_dir\n";
    }
}

our $template_is_setup     = 0;
our $default_template_text = <<'EO_Template';
[% BLOCK Changes %]
Revision history for Perl web application [% app_name %]

0.01  [% time_stamp %]
    - original version created with bigtop version [% bigtop_version %][% IF flags %] using:
        [% flags %]
[% END %]
[% END %]

[% BLOCK README %]
[% app_name %] version 0.01
===========================

Place description here.

INSTALLATION

To install this module type:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

DEPENDENCIES

This module requires these other modules and libraries:

    [% control_backend %]

COPYRIGHT AND LICENCE

Put the correct copyright and license info here.

Copyright (c) [% year %] by [% copyright_holder %]

[% IF license_text %]
[% license_text %]

[% ELSE %]
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
[% END %]
[% END %]

[% BLOCK MANIFEST_SKIP %]
# Avoid version control files.
\bRCS\b
\bCVS\b
,v$
\B\.svn\b

# Avoid Makemaker generated and utility files.
\bMakefile$
\bblib
\bMakeMaker-\d
\bpm_to_blib$
\bblibdirs$
# ^MANIFEST\.SKIP$

# Avoid Module::Build generated and utility files.
\bBuild$
\b_build

# Avoid temp and backup files.
~$
\.tmp$
\.old$
\.bak$
\#$
\b\.#
\.swp$

# Avoid inline's dropings
_Inline

[% END %]

[% BLOCK Build_PL %]
[%# app_name %]
use strict;
use Gantry::Build;

my $build = Gantry::Build->new(
    build_web_directory => 'html',
    install_web_directories =>  {
        # XXX unix specific paths
        'dev'   => '/home/httpd/html/[% app_dash_name %]',
        'qual'  => '/home/httpd/html/[% app_dash_name %]',
        'prod'  => '/home/httpd/html/[% app_dash_name %]',
    },
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => '[% app_name %]',
    requires           => {
        'perl'      => '5',
        'Gantry'    => '3.0',
        'HTML::Prototype' => '0',
    },
    create_makefile_pl  => 'passthrough',

    # XXX unix specific paths
    script_files        => [ glob('bin/*') ],
    'recursive_test_files' => 1,

    # XXX unix specific paths
    install_path        => { script => '/usr/local/bin' },
);

$build->create_build_script;
[% END %]
EO_Template

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
        TT                  => $template_text,
        PRE_CHOMP           => 0,
        POST_CHOMP          => 0,
        TRIM_LEADING_SPACE  => 1,
        TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

sub gen_Init {
    my $class       = shift;
    my $build_dir   = shift;
    my $tree        = shift;
    my $bigtop_file = shift;
    my $flags       = shift;

    # build dirs: lib, t
    my $test_dir     = File::Spec->catdir( $build_dir, 't' );
    my $lib_dir      = File::Spec->catdir( $build_dir, 'lib' );
    mkdir $test_dir;
    mkdir $lib_dir;

    # build flat files
    foreach my $simple_file
                    qw(
                        Changes
                        MANIFEST_SKIP
                        README
                        Build_PL
                    )
    {
        next if ( defined $tree->{configuration}{Init}{$simple_file}
                    and
                  $tree->{configuration}{Init}{$simple_file} eq 'no_gen'
                );
        ( my $actual_file = $simple_file ) =~ s/_/./;
        $class->init_simple_file( $build_dir, $tree, $actual_file, $flags );
    }

    # copy the bigtop file to its new home
    if ( defined $bigtop_file ) {
        my $docs_dir        = File::Spec->catdir( $build_dir, 'docs' );
        mkdir $docs_dir;

        my $bigtop_basename = File::Basename::basename( $bigtop_file );
        my $bigtop_copy
                = File::Spec->catfile( $docs_dir, $bigtop_basename );
        File::Copy::copy( $bigtop_file, $bigtop_copy )
                unless $bigtop_copy eq $bigtop_file;
    }

    # build the MANIFEST
    unless ( defined $tree->{configuration}{Init}{MANIFEST}
                and
             $tree->{configuration}{Init}{MANIFEST} eq 'no_gen' )
    {
        my $original_dir = getcwd();
        chdir $build_dir;

        $ExtUtils::Manifest::Verbose = 0;
        ExtUtils::Manifest::mkmanifest();

        chdir $original_dir;
    }
}

sub init_simple_file {
    my $class        = shift;
    my $build_dir    = shift;
    my $tree         = shift;
    my $file_base    = shift;
    my $flags        = shift;

    # where does this belong?
    my $file_name    = File::Spec->catfile( $build_dir, $file_base );
    my $app_name     = $tree->get_appname();
    my $app_dash_name= $app_name;
    $app_dash_name   =~ s/::/-/g;

    # should we really build this file?
    return if ( $stubs{ $file_base } and -f $file_name );

    # get the time
    my $right_now = scalar localtime;
    my $year      = ( localtime )[5];
    $year        += 1900;

    # who owns this?
    my $statements       = $tree->{application}{lookup}{app_statements};
    my $copyright_holder = $tree->get_copyright_holder();
    my $license_text;

    # what framework?

    my $control_backend;
    my $config = $tree->get_config;
    if ( defined $config->{__BACKENDS__}{ Control } ) {
        $control_backend =
            $tree->get_config->{__BACKENDS__}{ Control }[0]{ __NAME__ };
    }

    if ( defined $statements->{license_text} ) {
        $license_text = $statements->{license_text}[0];
    }

    # what Inline::TT sub are we calling?
    my $block_sub = "$class\::$file_base";
    $block_sub    =~ s/\./_/g;

    # open wide
    my $SIMPLE_FILE;
    unless ( open $SIMPLE_FILE, '>', $file_name ) {
        warn "Couldn't write $file_name: $!\n";
        return;
    }

    # make and print file
    {
        no strict 'refs';
        print $SIMPLE_FILE $block_sub->( {
            time_stamp       => $right_now,
            app_name         => $app_name,
            app_dash_name    => $app_dash_name,
            copyright_holder => $copyright_holder,
            year             => $year,
            license_text     => $license_text,
            flags            => $flags,
            control_backend  => $control_backend,
            bigtop_version   => $Bigtop::VERSION,
        } );
    }

    # all done
    close $SIMPLE_FILE or warn "Problem closing $file_name: $!\n";
}

1;

__END__

=head1 NAME

Bigtop::Backend::Init::Std - Bigtop backend which works sort of like h2xs

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        build_dir `/home/yourname`;
        app_dir   `appsubdir`;
        Init Std {}
    }
    app App::Name {
    }

when you type

    bigtop --create your.bigtop Init

or

    bigtop --create your.bigtop all

this module will generate the build directory as

    /home/yourname/appsubdir

Then it will make subdirectories: t, lib, and docs.  Then it will make
files: Changes, MANIFEST, MANIFEST.SKIP, README, and Build.PL. 
Finally, it will copy your.bigtop into the docs dir of under appsubdir.

As with any backend, you can include C<no_gen 1;> in its config block:

    config {
        Init Std { no_gen 1; }
    }

Then, no files will be generated.  But, you can also exclude indiviual
files it would build.  Simply list the file name as a keyword and
give the value no_gen:

    config {
        Init Std {
            MANIFEST no_gen;
            Changes  no_gen;
        }
    }

If you are in create mode and your config does not include app_dir, one
will be formed from the app name, in the manner of h2xs.  So, in the above
example it would be

    /home/yourname/App-Name

Outside of create mode, the current directory is used for building, if
it looks like a plausible build directory (it has a Build.PL, etc).  In
that case, having a base_dir and/or app_dir in your config will result
in warning(s) that they are being ignored.

=head1 KEYWORDS

This module registers app level keywords: authors, contact_us,
copyright_holder, license_text, and the now deprecated email (which is a
synonymn for contact_us).  These are also regiersted by Bigtop::Control and
they have the same meaning there.

It actually pays no attention to the rest of the app section of the
bigtop input, except to build the default app_dir from the app_name.

=head1 METHODS

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    Build_PL
    Changes
    README
    MANIFEST
    MANIFEST_SKIP
    template

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: roughly what h2xs makes.

=item validate_build_dir

Called by Bigtop::Parser to make sure a non-create build is happening
in a valid build dir.

=item gen_Init

Called by Bigtop::Parser to get me to do my thing.

=item output_cgi

What I call on the various AST packages to do my thing.

=item init_simple_file

What I call to build each regular file (like Changes, Build.PL, etc.).

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
