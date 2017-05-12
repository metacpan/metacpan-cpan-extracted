package App::HistHub::Web;
use strict;
use warnings;

use Catalyst::Runtime '5.70';
use parent qw/Catalyst/;

use Catalyst qw/
    ConfigLoader
    /;

__PACKAGE__->config(
    default_view => 'TD',

    'Plugin::ConfigLoader' => {
        file => __PACKAGE__->path_to('config')->stringify,
    },
);

__PACKAGE__->setup;

=head1 NAME

App::HistHub::Web - Web api for App::HistHub

=head1 SYNOPSIS

    script/app_histhub_web_server.pl

=head1 SEE ALSO

L<App::HistHub>.

=head1 AUTHOR

Daisuke Murase

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
