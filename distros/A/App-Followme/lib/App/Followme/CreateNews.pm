package App::Followme::CreateNews;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use File::Spec::Functions qw(abs2rel catfile no_upwards rel2abs splitdir);
use App::Followme::FIO;

our $VERSION = "1.94";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            news_index_length => 5,
            news_template_file => 'create_news.htm',
            index_template_file => 'create_news_index.htm',
            data_pkg => 'App::Followme::WebData',
           );
}

#----------------------------------------------------------------------
# Create a page of recent news items and indexes in each subdirectory

sub run {
    my ($self, $folder) = @_;

    eval{$self->update_folder($self->{base_directory})};
    $self->check_error($@, $self->{base_directory});
    return;
}

#----------------------------------------------------------------------
# Update the index files in each directory

sub update_folder {
    my ($self, $folder) = @_;

    my $index_file = $self->to_file($folder);
    my $newest_file = $self->{data}->build('newest_file', $index_file);

    my $template_file;
    if (fio_same_file($folder, $self->{base_directory})) {
        $template_file = $self->get_template_name($self->{news_template_file});
    } else {
        $template_file = $self->get_template_name($self->{index_template_file});
    }

    unless (fio_is_newer($index_file, $template_file, @$newest_file)) {
        my $page = $self->render_file($template_file, $index_file);
        my $prototype_file = $self->find_prototype();

        $page = $self->reformat_file($prototype_file, $index_file, $page);
        fio_write_page($index_file, $page);
    }

    my $folders = $self->{data}->build('folders', $index_file);
    foreach my $subfolder (@$folders) {
        eval {$self->update_folder($subfolder)};
        $self->check_error($@, $subfolder);
    }

    return;
}

#----------------------------------------------------------------------
#  Add index file to list of excluded files

sub setup {
    my ($self, %configuration) = @_;

    my @exclude;
    if ($self->{data}{exclude}) {
        @exclude = split(/\s*,\s*/, $self->{data}{exclude});
    }

    my $index_file = join('.', 'index', $self->{web_extension});
    push(@exclude, $index_file);

    $self->{data}{exclude} = join(',', @exclude);
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::CreateNews - Create an index with the more recent files

=head1 SYNOPSIS

    use App::Followme::CreateNews;
    my $indexer = App::Followme::CreateNews->new($configuration);
    $indexer->run($directory);

=head1 DESCRIPTION

This package creates an index for files in the current directory that contains
the text of the most recently modified files together with links to the files.
It can be used to create a basic weblog.

=head1 CONFIGURATION

The following fields in the configuration file are used:

=over 4

=item news_index_length

The number of pages to include in the index.

=item news_template_file

The news template creates the index in the base directory. The default value is
'create_news.htm'.

=item index_template_file

The index template creates index files in each of the subdirectories. The
default value is 'create_news_index.htm'.

=item data_pkg

The class used to extract data from each of the news files. The default value
is 'App::Followme::WebData'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
