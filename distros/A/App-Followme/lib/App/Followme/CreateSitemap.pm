package App::Followme::CreateSitemap;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use File::Spec::Functions qw(catfile);
use App::Followme::FIO;

our $VERSION = "1.99";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            sitemap => 'sitemap.txt',
            include_index => 1,
            data_pkg => 'App::Followme::WebData',
           );
}

#----------------------------------------------------------------------
# Write a list of urls in a directory tree

sub run {
    my ($self, $folder) = @_;

    my @urls = $self->list_urls($folder);
    my $page = join("\n", @urls) . "\n";

    my $filename = catfile($folder, $self->{sitemap});
    fio_write_page($filename, $page);

    return;
}

#----------------------------------------------------------------------
# Return a list of the urls of all web pages in a directory

sub list_urls {
    my ($self, $folder) = @_;

    my @urls;
    my $index_file = $self->to_file($folder);
    my $files = $self->{data}->build('files_by_name', $index_file);

    foreach my $file (@$files) {
        # build returns a reference, so must dereference
        my $url = $self->{data}->build('remote_url', $file);
        push(@urls, $$url);
    }

    my $folders = $self->{data}->build('folders', $index_file);

    foreach my $subfolder (@$folders) {
        push(@urls, $self->list_urls($subfolder));
    }

    return @urls;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::CreateSitemap - Create a Google sitemap

=head1 SYNOPSIS

    use App::Followme::Sitemap;
    my $map = App::Followme::Sitemap->new();
    $map->run($folder);

=head1 DESCRIPTION

This module creates a sitemap file, which is a text file containing the url of
every page on the site, one per line. It is also intended as a simple example of
how to write a module that can be run by followme.

=head1 CONFIGURATION

The following field in the configuration file are used:

=over 4

=item sitemap

The name of the sitemap file. It is written to the directory this module is
invoked from. Typically this is the top folder of a site. The default value is
sitemap.txt.

=item data_pkg

The package used to retrieve information from each file contained in the
sitemap. The default value is 'App::Followme::WebData'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
