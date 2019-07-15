#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-store.t 71 2019-07-05 18:17:43Z abalama $
#
#########################################################################
use Test::More tests => 8;
use App::MonM::Store;

my $dbi = new App::MonM::Store();

ok(!$dbi->error, "DBI errors") or diag($dbi->error);
#note(explain($dbi));

# Add new record
{
    ok($dbi->add(
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 0,
        message => "New record"
    ), "Add new record") or diag($dbi->error);
}

# Get record data
my %info = ();
{
    %info = $dbi->get(
        name    => "foo",
    );
    ok($info{id} && !$dbi->error, "Get record data 1") or diag($dbi->error);
}
#note(explain(\%info));

# Update record
{
    ok($dbi->set(
        id      => $info{id},
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 1,
        message => "Updated record"
    ), "Update record") or diag($dbi->error);
}

# Get record data
{
    my %up_info = $dbi->get(
        name    => "foo",
    );
    ok($up_info{id} && !$dbi->error, "Get record data 2") or diag($dbi->error);
    ok($up_info{id} && $up_info{status} != $info{status}, "Change status");
}
#note(explain(\%info));

# Get all records
my @all = ();
{
    @all = $dbi->getall();
    ok(@all && !$dbi->error, "Get all records") or diag($dbi->error);
}
#note(explain(\@all));

# Delete record
{
    ok($dbi->del(
        id  => $info{id},
    ), "Delete record") or diag($dbi->error);
}

1;

__END__
