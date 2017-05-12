use strict;

use File::Spec;
use Module::Build;

my $subclass = Module::Build->subclass(
    class   => 'Bigtop::Builder',
    code    => &_custom_code(),
);

my $build = $subclass->new(
    module_name         => 'Bigtop',
    license             => 'perl',
    create_makefile_pl  => 'passthrough',
    requires            => {
        'Parse::RecDescent' => 0,
        'Config::General' => 0,
        'Template'        => 2.0,
        'Inline'          => 0.40,
        'Inline::TT'      => 0.06,
        'Gantry'          => 3.48, # need row level permissions
        'IO::Prompt'      => 0,
        'HTTP::Server::Simple' => 0.27, # for tentmaker
        'JSON'            => 0, # because gantry controllers will want it
        'File::HomeDir'   => 0, # bigtop defaults come from home dirs
        'DBIx::Class'     => 0, # kickstarted apps assume you have this
    },
    build_requires      => {
        'Test'        => 0,
        'Test::More'  => 0,
        'Test::Warn'  => 0,
        'Test::Files' => 0.13,
    },
    script_files        => [ glob( 'scripts/*' ) ],
    tentmaker_files     => [ glob( 'tenttemplates/*' ) ],
    test_files          => [
#        't/dbixclass/01_dbixclass.t',
        't/*.t',
        't/scripthelp/*.t',
        't/bigtop/*.t',
        't/tentmaker/*.t',
        't/init/*.t',
        't/postgres/*.t',
        't/sqlite/*.t',
        't/mysql/*.t',
        't/db2/*.t',
        't/gantry/*.t',
        't/sitelook/*.t',
        't/dbixclass/*.t',
        't/cdbi/*.t',
        't/diagram/*.t',
        't/cleanup/*.t',
	],
);

eval { require Gantry; };
my $try_for_tentmaker = ( $@ ) ? 0 : 1;

if ( $try_for_tentmaker ) {

    my $default_template_path = $ENV{'TENTMAKER_TEMPLATE_PATH'} || '/usr/local/share/TentMaker';

    eval {
        require Bigtop::TentMakerPath;
        $default_template_path = Bigtop::TentMakerPath->get_template_path;
    };

    my $install_tentmaker = 'y';
    if (! $ENV{'TENTMAKER_TEMPLATE_PATH'}) {
        print "\n\nBigtop has an editor called tentmaker.  It allows\n";
        print "you to edit bigtop files with a DOM compatible browser\n";
        print "(like Firefox).  tentmaker requires some templates.\n\n";

        my $install_tentmaker = $build->y_n(
            "Do you want to install the tentmaker templates?",
            'y'
        );
    }
    
    $build->notes( install_tentmaker => $install_tentmaker );

    if ( $install_tentmaker ) {
        my $tentmaker_template_path = $default_template_path;
        if (! $ENV{'TENTMAKER_TEMPLATE_PATH'}) {
            print "\n\nTentMaker needs to store some templates on your system.\n";
            print "Please choose a location for them.\n\n";

            $tentmaker_template_path = $build->prompt(
                "Path for TentMaker templates",
                $default_template_path,
            );
        }
        
        $build->notes( tentmaker_template_path => $tentmaker_template_path );

        # Write a module which tentmaker can use to find its templates.
        my $tent_path_module = File::Spec->catfile(
                                    qw( lib Bigtop TentMakerPath.pm )
                                );

        my $template_dir;

        if ( open my $TENT_PATH, '>', $tent_path_module ) {
            print $TENT_PATH <<"EO_TENT_PATH";
package Bigtop::TentMakerPath;
use strict;

sub get_template_path {
    return '$tentmaker_template_path';
}

1;

=head1 NAME

Bigtop::TentMakerPath - keeps track of where the tentmaker templates live

=head1 SYNOPSIS

In tentmaker:

    use Bigtop::TentMakerPath;

    my \$tent_path = Bigtop::TentMakerPath->get_template_path();

=head1 DESCRIPTION

Duing initial perl Build.PL, the user is asked to supply a path for
tentmaker's templates.  If they do that, this module is written and
later installed, to keep track of where the user wanted the templates.
Then, tentmaker can call get_template_path to find out where they are.

=head1 METHODS

=over 4

=item get_template_path

Returns the path, specified by the installing user, to the tentmaker templates.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil\@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
EO_TENT_PATH
            close $TENT_PATH;
        }
    }
}
else {
    print "\n\n  Bigtop has an editor called tentmaker.  You need to\n";
    print "  install Gantry, AND re-run Build.PL, in order to use it.\n\n\n";
    $build->notes( install_tentmaker => 0 );
}

$build->create_build_script;

sub _custom_code {
    return q{
        sub ACTION_install {
            my $self = shift;

            $self->SUPER::ACTION_install();

            return unless ( $self->notes( 'install_tentmaker' ) );

            my $props = $self->{properties};
            my $files = $props->{tentmaker_files};

            my $path  = $self->notes( 'tentmaker_template_path' );
            foreach my $file ( @{ $files } ) {
                $self->copy_if_modified( $file, $path );
            }
            print "installed tentmaker templates to $path\n";
        }
        sub ACTION_dist {
            my $self = shift;

            if ( -x 'skip/gendocs' ) {
                `skip/gendocs`;
            }

            $self->SUPER::ACTION_dist();
        }
    };
}
