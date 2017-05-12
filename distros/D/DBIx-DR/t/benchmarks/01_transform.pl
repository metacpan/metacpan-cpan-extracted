#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);

use lib qw(lib);
use DBIx::DR::PlPlaceHolders;
use Benchmark qw(:all) ;
use Data::Dumper;

my $sql = q[

    SELECT
        u.*
    FROM
        users AS u

    % if ($filters->{role_name}) {
        LEFT JOIN roles AS r ON u.rid = r.id
    % }

    % if ($filters->{user_name}) {
        LEFT JOIN user_cards AS uc ON u.id = uc.uid
    % }

    WHERE
        1 = 1

    % if ($filters->{role_name}) {
        AND r.name = <%= $filters->{role_name} %>
    % }

    % if ($filters->{user_name}) {
        AND uc.name = <%= $filters->{user_name} %>
    % }
];

print "Two active filters\n";

my $tp = DBIx::DR::PlPlaceHolders->new;


my $b1 = timeit 10000, sub {

    $tp->sql_transform( $sql,
        filters => { role_name => 'Superadmin', user_name => 'Vasya' }
    );

};

printf "%s\n", $b1->timestr;


printf "One active filter\n";
my $b2 = timeit 10000, sub {

    $tp->sql_transform(
        $sql,
        filters => { role_name => 'Superadmin' }
    );

};
printf "%s\n", $b2->timestr;

print "No active filters\n";
my $b3 = timeit 10000, sub {

    $tp->sql_transform($sql, filters => {});

};
printf "%s\n", $b3->timestr;

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

