#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More tests => 8;
use App::MonM::Notifier::Store;

my $dbi = App::MonM::Notifier::Store->new(
        file => "monotifier-test.db",
        expires => 60, # 1 min for test
);

ok(!$dbi->error, "DBI errors") or diag($dbi->error);
#note(explain($dbi));

# Add new record
my $newid = 0;
{
    ok($newid = $dbi->enqueue(
        to      => "bob",
        channel => "SaveToFile",
        subject => "Save message to file",
        message => "My Message",
        attributes => {param1 => "quux", param2 => 123}, # Channel attributes
    ), "Enqueue message") or diag($dbi->error);
}

# Set error (requeue)
{
    ok($dbi->requeue(
        id => $newid,
        code => 2,
        error => "My Error",
    ), sprintf("Requeue message %d", $newid)) or diag($dbi->error);;
}

# Get record data
my %info = ();
{
    my $entity = $dbi->retrieve;
    ok($entity->{id} && !$dbi->error, sprintf("Retrieve data %d", $entity->{id})) or diag($dbi->error);
    %info = %$entity if ref($entity) eq 'HASH';
}
#note(explain(\%info));

# Mark as Sent
{
    ok($dbi->dequeue(id => $info{id}), "Mark as Sent")
        or diag($dbi->error);
}

# Delete too old records
{
    ok($dbi->cleanup, "Delete too old records") or diag($dbi->error);
}

# Get all records
my @all = ();
{
    @all = $dbi->getAll();
    ok(@all && !$dbi->error, "Get all records") or diag($dbi->error);
}
#note(explain(\@all));

# Delete all record
{
    ok($dbi->purge, "Delete all record") or diag($dbi->error);
}

1;

__END__
