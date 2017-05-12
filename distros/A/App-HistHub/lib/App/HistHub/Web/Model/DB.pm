package App::HistHub::Web::Model::DB;
use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'App::HistHub::Schema',
    connect_info => [
        'dbi:SQLite:',
        {
            on_connect_do => [
                _create_table(),
            ]
        },
    ],
);

sub _create_table {
    my $sql = <<_CREATE_;
CREATE TABLE peer (
       id INTEGER NOT NULL PRIMARY KEY,
       uid TEXT NOT NULL,
       access_time INTEGER NOT NULL
);
CREATE UNIQUE INDEX uid ON peer (uid);

CREATE TABLE hist_queue (
       id INTEGER NOT NULL PRIMARY KEY,
       peer INTEGER NOT NULL,
       data TEXT NOT NULL,
       timestamp INTEGER NOT NULL
);
_CREATE_

    map { "$_;" } grep { $_ =~ /\S/ } split /;/, $sql;
}

=head1 NAME

App::HistHub::Web::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<App::HistHub::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<App::HistHub::Schema>

=head1 AUTHOR

Daisuke Murase

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
