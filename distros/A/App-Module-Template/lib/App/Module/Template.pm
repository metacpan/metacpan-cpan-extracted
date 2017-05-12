package App::Module::Template;

use 5.016;

use strict;
use warnings;

our $VERSION = '0.11';

use base qw(Exporter);

use App::Module::Template::Initialize;

use Carp;
use Config::General;
use File::Copy;
use File::HomeDir;
use File::Path qw/make_path/;
use File::Spec;
use Getopt::Std;
use POSIX qw(strftime);
use Template;
use Try::Tiny;

our (@EXPORT_OK, %EXPORT_TAGS);
@EXPORT_OK = qw(
    run
    _get_config
    _get_config_path
    _get_module_dirs
    _get_module_fqfn
    _get_template_path
    _module_path_exists
    _process_dirs
    _process_file
    _process_template
    _validate_module_name
);
%EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
);

#-------------------------------------------------------------------------------
sub run {
    my $class = shift;

    my %opt;
    # -c config file
    # -m module name
    # -t template dir, location of template files
    getopts('c:m:t:', \%opt);

    unless ( ( exists $opt{m} ) and ( defined $opt{m} ) ) {
        croak "-m <Module::Name> is required. exiting...\n";
    }

    my $module   = $opt{m};
    my $dist     = $module; $dist =~ s/::/-/gmsx;
    my $file     = $module; $file =~ s/.*:://msx; $file .= '.pm';
    my $dist_dir = File::Spec->catdir( File::Spec->curdir, $dist );
    my $tmpl_vars;

    try {
        _validate_module_name($module);
    } catch {
        croak "$_ module-template. exiting...";
    };

    if ( _module_path_exists($dist_dir) ) {
        croak "Destination directory $dist_dir exists. exiting...";
    }

    my $template_dir = _get_template_path($opt{t});

    my $config_file = _get_config_path($opt{c}, $template_dir);

    my $cfg = _get_config($config_file);

    # Setting this lets TT2 handle creating the destination files/directories
    $cfg->{template_toolkit}{OUTPUT_PATH} = $dist_dir;

    my $tt2 = Template->new( $cfg->{template_toolkit} );

    # don't need this in the $tmpl_vars
    delete $cfg->{template_toolkit};

    my $dirs = _get_module_dirs( $module );

    # Template Vars
    $tmpl_vars = $cfg;
    $tmpl_vars->{module} = $module;
    $tmpl_vars->{today} = strftime('%Y-%m-%d', localtime());
    $tmpl_vars->{year} = strftime('%Y', localtime());
    $tmpl_vars->{module_path} = File::Spec->catfile( @{$dirs}, $file );

    _process_dirs($tt2, $tmpl_vars, $template_dir, $template_dir);

    # add the distribution dir to the front so our module ends up in the
    # right place
    unshift @{$dirs}, $dist_dir;

    my $fqfn = _get_module_fqfn( $dirs, $file );

    # create the module directory to receive the named module.pm
    make_path( File::Spec->catdir( @{$dirs} ) );

    # rename the template file with the module file name
    move( File::Spec->catfile( $dist_dir, 'lib', 'Module.pm' ), $fqfn );

    return 1;
}

#-------------------------------------------------------------------------------
sub _get_config {
    my ($config_file) = @_;

    my %cfg = Config::General->new(
            -ConfigFile            => $config_file,
            -MergeDuplicateBlocks  => 1,
            -MergeDuplicateOptions => 1,
            -AutoLaunder           => 1,
            -SplitPolicy           => 'equalsign',
            -InterPolateVars       => 1,
            -UTF8                  => 1,
    )->getall() or croak "Could not read configuration file $config_file";

    return \%cfg;
}

#-------------------------------------------------------------------------------
sub _get_config_path {
    my ($opt, $template_dir) = @_;

    my $config_file;

    if ( defined $opt ) {
        $config_file = $opt;
    }
    else {
        $config_file = File::Spec->catfile( $template_dir, '../config' );
    }

    unless ( -f $config_file ) {
        croak "Could not locate configuration file $config_file\n";
    }

    return $config_file;
}

#-------------------------------------------------------------------------------
# Split the module name into directories
#-------------------------------------------------------------------------------
sub _get_module_dirs {
    my ($module) = @_;

    my @dirs = split( /::/msx, $module );

    # remove the last part of the module name because that will be the filename
    pop @dirs;

    unshift @dirs, 'lib';

    return \@dirs;
}

#-------------------------------------------------------------------------------
# Return the path to the fully qualified file name
#-------------------------------------------------------------------------------
sub _get_module_fqfn {
    my ($dirs, $file_name) = @_;

    return File::Spec->catfile( @{$dirs}, $file_name );
}

#-------------------------------------------------------------------------------
sub _get_template_path {
    my ($opt) = @_;

    my $template_dir;

    if ( defined $opt ) {

        unless ( -d $opt ) {
            croak "Template directory $opt does not exist";
        }

        $template_dir = $opt;
    }
    else {
        $template_dir  = File::Spec->catdir( File::HomeDir->my_home(), '.module-template', 'templates' );

        unless ( -d $template_dir ) {
            # initialize .module-template in user's home directory
            App::Module::Template::Initialize::module_template();
        }
    }

    return $template_dir;
}

#-------------------------------------------------------------------------------
sub _module_path_exists {
    my ($module_path) = @_;

    if ( ( defined $module_path ) and ( -d $module_path ) ) {
        return 1;
    }

    return;
}

#-------------------------------------------------------------------------------
# Walk the template directory
#-------------------------------------------------------------------------------
sub _process_dirs {
    my ($tt2, $tmpl_vars, $template_dir, $source) = @_;

    if ( -d $source ) {
        my $dir;

        unless ( opendir $dir, $source ) {
            croak "Couldn't open directory $source: $!; skipping.\n";
        }

        while ( my $file = readdir $dir ) {
            next if $file eq '.' or $file eq '..';

            my $target = File::Spec->catfile($source, $file);

            _process_dirs($tt2, $tmpl_vars, $template_dir, $target);
        }

        closedir $dir;
    }
    else {
        my $output = _process_file($template_dir, $source);

        _process_template($tt2, $tmpl_vars, $source, $output);
    }

    return $source;
}

#-------------------------------------------------------------------------------
# Return the output path for TT2
#-------------------------------------------------------------------------------
sub _process_file {
    my ($template_dir, $source_file) = @_;

    # regex matches paths on *nix or *dos
    my ($stub) = $source_file =~ m{\A$template_dir[/\\](.*)\z}mosx;

    return $stub;
}

#-------------------------------------------------------------------------------
sub _process_template {
    my ($tt2, $tmpl_vars, $template, $output) = @_;

    $tt2->process($template, $tmpl_vars, $output) or croak $tt2->error();

    return $template;
}

#-------------------------------------------------------------------------------
# Validate the module naming convention
#
# 1. No top-level namespaces
# 2. No all lower case names
# 3. Match XXX::XXX
#-------------------------------------------------------------------------------
sub _validate_module_name {
    my ($module_name) = @_;

    given ( $module_name ) {
        when ( $module_name =~ m/\A[A-Za-z]+\z/msx )
        {
            croak "'$module_name' is a top-level namespace";
        }
        when ( $module_name =~ m/\A[a-z]+\:\:[a-z]+/msx )
        {
            croak "'$module_name' is an all lower-case namespace";
        }
        # module name conforms
        when ( $module_name =~ m/\A[A-Z][A-Za-z]+(?:\:\:[A-Z][A-Za-z]+)+\z/msx )
        {
            return 1;
        }
        default {
            croak "'$module_name' does not meet naming requirements";
        }
    }
}

1;

__END__

=pod

=head1 NAME

App::Module::Template - Perl module scaffolding with Template Toolkit

=head1 VERSION

This documentation refers to App::Module::Template version 0.11.

=head1 SYNOPSIS

    use App::Module::Template;

    App::Module::Template->run(@ARGS);

=head1 DESCRIPTION

App::Module::Template contains the subroutines to support 'module-template'. See module-template for usage.

=head1 SUBROUTINES/METHODS

=over

=item C<run>

This function is called by module-template to execute logic of the program.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

App::Module::Template is configured by ~/.module-template/config. See module-template for more information.

=head1 DEPENDENCIES

=over

=item * Carp

=item * Config::General

=item * File::Copy

=item * File::HomeDir

=item * File::Path

=item * File::Spec

=item * Getopt::Std

=item * POSIX

=item * Template

=item * Try::Tiny

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

