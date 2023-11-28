use strict;
use warnings FATAL => 'all';

use Test::More;

use lib 't';
use common qw( new_fh );

diag "Testing DBM::Deep against Perl $] located at $^X";

use_ok( 'DBM::Deep' );

subtest 'hash' => sub {
    subtest 'tied' => sub {
        my ($fh, $filename) = new_fh();

        # this creates a file with pack_size small
        DBM::Deep->new(
            file      => $filename,
            pack_size => 'small',
        );

        {
            tie my %db, 'DBM::Deep', $filename;
            eval { for (0..99999) { $db{$_} = $_ } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # try again on the same file
        {
            tie my %db, 'DBM::Deep', $filename;
            # first, can we still read the old file?
            eval {
                for(0, 178) { is($db{$_}, $_, "read record $_"); }
                is($db{179}, undef, "record 179 doesn't exist");
            };
            is($@, '', "no exception");

            # now update it
            eval { for (0..99999) { $db{$_} = $_; } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # file still uncorrupted?
        tie my %db, 'DBM::Deep', $filename;
        for(0, 178) { is($db{$_}, $_, "read record $_ again"); }
        is($db{179}, undef, "record 179 doesn't exist");
    };

    subtest 'object' => sub {
        my ($fh, $filename) = new_fh();

        {
            my $db = DBM::Deep->new(
                file      => $filename,
                pack_size => 'small',
            );

            eval { for (0..99999) { $db->{$_} = $_; } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # try again on the same file
        {
            my $db = DBM::Deep->new( file => $filename);
            # first, can we still read the old file?
            eval {
                for(0, 178) { is($db->{$_}, $_, "read record $_"); }
                is($db->{179}, undef, "record 179 doesn't exist");
            };
            is($@, '', "no exception");

            # now update it
            eval { for (0..99999) { $db->{$_} = $_; } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # file still uncorrupted?
        my $db = DBM::Deep->new( file => $filename);
        for(0, 178) { is($db->{$_}, $_, "read record $_ again"); }
        is($db->{179}, undef, "record 179 doesn't exist");
    };
};

subtest 'array' => sub {
    subtest 'tied' => sub {
        my ($fh, $filename) = new_fh();

        # this creates a file with pack_size small
        DBM::Deep->new(
            file      => $filename,
            pack_size => 'small',
            type      => DBM::Deep->TYPE_ARRAY,
        );

        {
            tie my @db, 'DBM::Deep', $filename;
            eval { for (0..99999) { push @db, $_ } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # try again on the same file
        {
            tie my @db, 'DBM::Deep', $filename;
            # first, can we still read the old file?
            eval {
                for(0, 176) { is($db[$_], $_, "read record $_"); }
                is($db[177], undef, "record 177 doesn't exist");
            };
            is($@, '', "no exception");

            # now update it
            eval { for (0..99999) { $db[$_] = $_; } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # file still uncorrupted?
        tie my @db, 'DBM::Deep', $filename;
        for(0, 176) { is($db[$_], $_, "read record $_ again"); }
        is($db[177], undef, "record 179 doesn't exist");
    };

    subtest 'object' => sub {
        my ($fh, $filename) = new_fh();

        {
            my $db = DBM::Deep->new(
                file      => $filename,
                pack_size => 'small',
                type      => DBM::Deep->TYPE_ARRAY,
            );

            eval { for (0..99999) { push @{$db}, $_ } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # try again on the same file
        {
            my $db = DBM::Deep->new(
                file => $filename,
                type => DBM::Deep->TYPE_ARRAY,
            );
            # first, can we still read the old file?
            eval {
                for(0, 176) { is($db->[$_], $_, "read record $_"); }
                is($db->[177], undef, "record 177 doesn't exist");
            };
            is($@, '', "no exception");

            # now update it
            eval { for (0..99999) { push @{$db}, $_ } };
            like($@, qr/DBM::Deep: too much data, try a bigger pack_size/, "died as expected");
        }

        # file still uncorrupted?
        my $db = DBM::Deep->new(
            file => $filename,
            type => DBM::Deep->TYPE_ARRAY,
        );
        for(0, 176) { is($db->[$_], $_, "read record $_ again"); }
        is($db->[177], undef, "record 177 doesn't exist");
    };
};

done_testing;
