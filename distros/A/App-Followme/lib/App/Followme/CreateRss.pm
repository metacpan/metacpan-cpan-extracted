package App::Followme::CreateRss;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use File::Spec::Functions qw(catfile splitdir);
use MIME::Base64 qw(encode_base64);

use App::Followme::FIO;
use App::Followme::NestedText;

our $VERSION = "1.98";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            rss_extension => 'rss',
            data_pkg => 'App::Followme::WebData',
           );
}

#----------------------------------------------------------------------
# Write an rss file for the web pages in a directory

sub run {
    my ($self, $folder) = @_;

    my %rss = $self->build_rss($folder);

    my @path = splitdir($folder);
    my $filename = pop(@path) . '.' . $self->{rss_extension};
    $filename = catfile($folder, $filename);

    nt_write_almost_xml_file($filename, %rss);

    return;
}

#----------------------------------------------------------------------
# Return an rss file of the newest web pages in a directory

sub build_rss {
    my ($self, $folder) = @_;

    my $index_file = $self->to_file($folder);
    my $info = $self->file_info($index_file);
    my %channel = %$info;
    delete $channel{guid};

    my @items;
    my $files = $self->{data}->build('top_files', $index_file);

    foreach my $file (@$files) {
        push(@items, $self->file_info($file));
    }
    $channel{item} = \@items; 

    my $rss_tag = 'rss version="2.0"';
    my %rss = ($rss_tag => {channel => \%channel});

    return %rss;
}

#----------------------------------------------------------------------
# Return the pertinent information about a file for the rss file

sub file_info {
    my ($self, $file) = @_;
    my $info = {};

    # build returns a reference, so must dereference

    $info->{title} = ${$self->{data}->build('title', $file)};
    $info->{author} = ${$self->{data}->build('author', $file)};
    $info->{description} = ${$self->{data}->build('description', $file)};
    $info->{pubDate} = ${$self->{data}->build('date', $file)};
    $info->{link} = ${$self->{data}->build('remote_url', $file)};

    my $guid = encode_base64($info->{link});
    $guid =~ s/=*\n$//;
    $info->{guid} = $guid;

    return $info;
}

#----------------------------------------------------------------------
# Set exclude_index to true and set default date format

sub setup {
    my ($self, %configuration) = @_;

    $self->{data}{date_format} ||= 'Day, dd Mon yyyy';
    $self->{data}{exclude_index} = 1;
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::CreateRss - Create an rss file for a directory

=head1 SYNOPSIS

    use App::Followme::CreateRss;
    my $rss = App::Followme::CreateRss->new();
    $rss->run($folder);

=head1 DESCRIPTION

This module creates an rss file listing the newest files in a folder
and its subfolders.

=head1 CONFIGURATION

The following fields in the configuration file are used:

=over 4

=item rss_extension

The extension used for rss files. The default value is 'rss'.

=item data_pkg

The package used to retrieve information from each file contained in the
rss file. The default value is 'App::Followme::WebData'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
