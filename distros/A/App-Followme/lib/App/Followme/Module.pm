package App::Followme::Module;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use IO::File;
use File::Spec::Functions qw(abs2rel catfile file_name_is_absolute
                             no_upwards rel2abs splitdir updir);
use App::Followme::FIO;
use App::Followme::NestedText;
use App::Followme::Web;

use base qw(App::Followme::ConfiguredObject);

our $VERSION = "2.01";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            template_file => '',
            web_extension => 'html',
            configuration_file => 'followme.cfg',
            template_directory => '_templates',
            data_pkg => 'App::Followme::WebData',
            template_pkg => 'App::Followme::Template',
           );
}

#----------------------------------------------------------------------
# Main method of all module subclasses (stub)

sub run {
    my ($self, $folder, $base_folder, $top_folder) = @_;
    $base_folder ||= $folder;
    $top_folder ||= $base_folder;

    my $pkg = ref $self;
    die "Run method not implemented by $pkg\n";
}

#----------------------------------------------------------------------
# Check for error and warn if found

sub check_error {
    my($self, $error, $folder) = @_;
    return 1 unless $error;

    my $pkg = ref $self;
    my $filename = $self->to_file($folder);
    warn "$pkg $filename: $error";

    return;
}

#----------------------------------------------------------------------
# Find an file to serve as a prototype for updating other files

sub find_prototype {
    my ($self, $directory, $uplevel) = @_;

    $uplevel = 0 unless defined $uplevel;
    ($directory) = fio_split_filename($directory);
    my @path = splitdir(abs2rel($directory, $self->{top_directory}));

    for (;;) {
        my $dir = catfile($self->{top_directory}, @path);

        if ($uplevel) {
            $uplevel -= 1;
        } else {
            my $pattern = "*.$self->{web_extension}";
            my $file = fio_most_recent_file($dir, $pattern);
            return $file if $file;
        }

        last unless @path;
        pop(@path);
    }

    return;
}

#----------------------------------------------------------------------
# Get the full template name

sub get_template_name {
    my ($self, $template_file) = @_;

    my $template_directory = fio_full_file_name($self->{top_directory},
                                                $self->{template_directory});

    my @directories = ($self->{base_directory}, $template_directory);

    foreach my $directory (@directories) {
        my $template_name = fio_full_file_name($directory, $template_file);
        return $template_name if -e $template_name;
    }

    die "Couldn't find template: $template_file\n";
}

#----------------------------------------------------------------------
# Read the configuration from a file

sub read_configuration {
    my ($self, $filename, %configuration) = @_;
	
    foreach my $name (qw(run_before run_after)) {
        $configuration{$name} ||= [];
    }

	my %new_configuration = nt_parse_almost_yaml_file($filename);
    my $final_configuration = nt_merge_items(\%configuration, 
                                             \%new_configuration);

    return %$final_configuration;
}

#----------------------------------------------------------------------
# Reformat the contents of an html file using one or more prototypes

sub reformat_file {
    my ($self, @files) = @_;

    my $page;
    my $section = {};
    foreach my $file (reverse @files) {
        if (defined $file) {
            if ($file =~ /\n/) {
                $page = web_substitute_sections($file, $section);
            } elsif (-e $file) {
                $page = web_substitute_sections(fio_read_page($file), $section);
            }
        }
    }

    return $page;
}

#----------------------------------------------------------------------
# Render the data contained in a file using a template

sub render_file {
    my ($self, $template_file, $file) = @_;

    $template_file = $self->get_template_name($template_file);
    my $template = fio_read_page($template_file);

    my $renderer = $self->{template}->compile($template);
    return $renderer->($self->{data}, $file);
}

#----------------------------------------------------------------------
# Convert filename to index file if it is a directory

sub to_file {
    my ($self, $file) = @_;

    $file = catfile($file, "index.$self->{web_extension}") if -d $file;
    return $file;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::Module - Base class for modules invoked from configuration

=head1 SYNOPSIS

    use Cwd;
    use App::Followme::Module;
    my $obj = App::Followme::Module->new();
    my $directory = getcwd();
    $obj->run($directory);

=head1 DESCRIPTION

This module serves as the basis of all the computations
performed by App::Followme, and thus is used as the base class for all its
modules. It contains a few methods used by the modules and is not meant to
be invoked itself.

=head1 METHODS

Packages loaded as modules get a consistent behavior by subclassing
App::Followme:Module. It is not invoked directly. It provides methods for i/o,
handling templates and prototypes.

A template is a file containing commands and variables for making a web page.
First, the template is compiled into a subroutine and then the subroutine is
called with a metadata object as an argument to fill in the variables and
produce a web page. A prototype is the most recently modified web page in a
directory. It is combined with the template so that the web page has the same
look as the other pages in the directory.

=over 4

=item $flag = $self->check_error($error, $folder);

Provides common error formatting and checking for modules. It generates a
warning message if $error is set. $folder is the name of the file or folder
that the operation that generated the error was invoked on. The return value
is Perl true  if $error was set.

=item $filename = $self->find_prototype($directory, $uplevel);

Return the name of the most recently modified web page in a directory. If
$uplevel is defined, search that many directory levels up from the directory
passed as the first argument.

=item $filename = $self->get_template_name($template_file);

Searches in the standard places for a template file and returns the full
filename if it is found. Throws an error if the template is not found.

=item %configuration = $self->read_configuration($filename, %configuration);

Update the configuraion parameters by reading the contents of a configuration
file.

=item $page = $self->reformat_file(@files);

Reformat a file using one or more prototypes. The first file is the
prototype, the second, the subprototype, and the last file is the file to
be updated.

=item $page = $self->render_file($template_file, $file);

Render a file as html using a template. The data subpackage is used to
retrieve the data from the file.

=item $file = $self->to_file($file);

A convenience method that converts a folder name to an index file name,
otherwise pass the file name unchanged.

=back

=head1 CONFIGURATION

The following fields in the configuration file are used in this class and every
class based on it:

=over 4

=item template_file

The name of the template file used by this module.

=item web_extension

The extension used by web files. The default value is 'html'.

=item configuration_file

The name of the file containing the configuration. The default value is
'followme.cfg'.

=item template_directory

The name of the directory containing the template files. The name is relative
to the top directory of the web site. The default value is '_templates'.

=item data_pkg

The name of the Perl module that generates data to be put into the template.
It should be a subclass of App::Followme::BaseData. The default value is
'App::Followme::WebData'.

=item template_pkg

The name of the Perl Module used to generate web pages from templates.
The default value is 'App::Followme::Template'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
