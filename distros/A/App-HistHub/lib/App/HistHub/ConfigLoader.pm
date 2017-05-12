package App::HistHub::ConfigLoader;
use strict;
use warnings;

use FindBin::libs qw/export/;
use File::HomeDir;
use YAML;

=head1 NAME

App::HistHub::ConfigLoader - App::HistHub ConfigLoader class

=head1 DESCRIPTION

See L<App::HistHub>.

=head1 METHODS

=head2 load

=cut

sub load {
    my @files;
    my $base = (@App::HistHub::ConfigLoader::lib)[0];
    if ($base) {
        push @files, "$base/config.yaml";
        push @files, "$base/config_local.yaml";
    }
    push @files, File::HomeDir->my_home . '/.histhub';

    my $conf = {};
    for my $file (@files) {
        next unless -f $file && -s _ && -r _;
        my $c = YAML::LoadFile($file);
        for my $k (keys %$c) {
            $conf->{$k} = $c->{$k};
        }
    }

    $conf;
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

