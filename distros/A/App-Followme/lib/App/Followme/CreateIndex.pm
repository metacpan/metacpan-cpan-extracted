package App::Followme::CreateIndex;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use IO::Dir;
use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile no_upwards);

use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "2.00";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            template_file => 'create_index.htm',
            data_pkg => 'App::Followme::WebData',
           );
}

#----------------------------------------------------------------------
#  Create an index to all files in a folder with a specified extension

sub run {
    my ($self, $folder) = @_;

    eval {$self->update_folder($folder)};
    $self->check_error($@, $folder);

    return;
}

#----------------------------------------------------------------------
# Return a flag indicating that recursion on folders is not needed

sub no_recurse {
    my ($self) = @_;

    my $template_file = $self->get_template_name($self->{template_file});
    my $template = fio_read_page($template_file);
    die "Couldn't read template: $template_file" unless $template;

    return web_has_variables($template, '@all_files', '@top_files');
}

#----------------------------------------------------------------------
# Return true if each section in a file has been filled from the template

sub sections_are_filled {
    my ($self, $filename) = @_;

    my $page = fio_read_page($filename);
    return unless $page;
    my $page_sections = web_parse_sections($page);

    my $template_file = $self->get_template_name($self->{template_file});
    my $template = fio_read_page($template_file);
    die "Couldn't read template: $template_file" unless $template;
    my $template_sections = web_parse_sections($template);

    foreach my $name (keys %$template_sections) {
        next unless $template_sections->{$name} =~ /\S/;
        return unless $page_sections->{$name} =~ /\S/;
    }

    return 1;
}

#----------------------------------------------------------------------
# Set exclude_index to true in the data package

sub setup {
    my ($self, %configuration) = @_;

    $self->{data}{exclude_index} = 1;
    return;
}

#----------------------------------------------------------------------
# Find files in directory to convert and do that

sub update_folder {
    my ($self, $folder) = @_;

    my $index_file = $self->to_file($folder);
    my $base_index_file = $self->to_file($self->{data}{base_directory}); 

    my $template_file = $self->get_template_name($self->{template_file});
    my $newest_file = $self->{data}->build('newest_file', $base_index_file);


    unless (fio_is_newer($index_file, $template_file, @$newest_file) &&
            $self->sections_are_filled($index_file)) {

        my $page = $self->render_file($self->{template_file}, $base_index_file);

        my $prototype_file = $self->find_prototype($folder, 0);
        $page = $self->reformat_file($prototype_file, $index_file, $page);
        fio_write_page($index_file, $page);
    }

    unless ($self->no_recurse) {
        my $folders = $self->{data}->build('folders', $index_file);
        foreach my $subfolder (@$folders) {
            eval {$self->update_folder($subfolder)};
            $self->check_error($@, $subfolder);
        }
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::CreateIndex - Create index file for a directory

=head1 SYNOPSIS

    use App::Followme::CreateIndex;
    my $indexer = App::Followme::CreateIndex->new($configuration);
    $indexer->run($directory);

=head1 DESCRIPTION

This package builds an index for a directory containing links to all the files
contained in it with the specified extensions. The variables described below are
substituted into a template to produce the index. Loop comments that look like

    <!-- for @files -->
    <!-- endfor -->

indicate the section of the template that is repeated for each file contained
in the index.

=head1 CONFIGURATION

The following fields in the configuration file are used:

=over 4

=item template_file

The name of the template file. The template file is either in the same
directory as the configuration file used to invoke this method, or if not
there, in the templates subdirectory. The default value is 'create_index.htm'.

=item data_pkg

The name of the class used to find and parse files included in the index. The
default value is 'App::Followme::WebData', which handles html files.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
