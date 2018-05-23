use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = schema();
my $processor = Data::Processor->new($schema);
eval{$processor->validate()};
chomp $@;
ok ($@ =~ /^cannot validate without "data"/, $@);


my $data = data();
my $error_collection = $processor->validate($data);
my @errors = $error_collection->as_array();
ok (scalar(@errors)==2, '2 errors found');
ok ($error_collection->count()==2, 'error count =2');
ok ($error_collection->any_error_contains(
        string => 'not_existing',
        field  => 'message'
    ),
    "mandatory schema key 'not_existing' not in config"
);

ok ($error_collection->any_error_contains(
        string => "NOT_THERE",
        field  => 'message',
    ),
    "mandatory schema section 'NOT_THERE' not found in config"
);

ok ($error_collection->any_error_contains(
        string => "silo-a",
        field  => 'path',
    ),
    "missing value from 'silo-a'"
);

ok ($error_collection->any_error_contains(
        string => "root",
        field  => 'path',
    ),
    "section missing from 'root'"
);

$data = {
    GENERAL => {
        logfile => '/tmp/n3k-poller.log',
        cachedb => '/tmp/n3k-cache.db',
        history => '3d',
        silos   => {
            'silo-a' => {
                url => 'https://silo-a/api',
                key => 'my-secret-shared-key',
                not_existing => 'make go away my error!',
            }
        }
    },
    NOT_THERE => 'whatnot'
};
$error_collection = $processor->validate($data);
ok ($error_collection->count==0, 'no more errors with corrected config');

# check error messages from schema.
$data = {

};
$error_collection = $processor->validate($data);
ok ($error_collection->count==2, '2 errors');

ok ($error_collection->any_error_contains(
        string => "We shall not proceed without a section that is NOT_THERE",
        field  => 'message',
    ),
    'correct error msg'
);

subtest 'Errors with no error message drop the error message clause' => sub{
    my $nem_schema = {
        x => {
            value => qr{x},
        },
        y => {
            value => qr{y},
            error_msg => 'Oh dear',
        },
    };
    my $nem_processor = Data::Processor->new(
        $nem_schema
    );
    my $ec = $nem_processor->validate({});
    is( $ec->count, 2, 'Get two errors');
    my @nem_errors = $ec->as_array;
    my ($xerr) = grep{/\'x\'/} @nem_errors;
    my ($yerr) = grep{/\'y\'/} @nem_errors;
    unlike($xerr, qr{Error msg:}, 'No error message clause on the x error');
    like($yerr, qr{Error msg:}, 'Error message clause on the y error');
};

done_testing;

sub data {
    return {
        GENERAL => {
            logfile => '/tmp/n3k-poller.log',
            cachedb => '/tmp/n3k-cache.db',
            history => '3d',
            silos   => {
                'silo-a' => {
                    url => 'https://silo-a/api',
                    key => 'my-secret-shared-key',
                }
            }

        }
    }
}

sub schema {
    return {
        GENERAL => {
            description => 'general settings',
            error_msg   => 'Section GENERAL missing',
            members => {
                logfile => {
                    value       => qr{/.*},
                    # or a coderef: value => sub{return 1},
                    description => 'absolute path to logfile',
                },
                cachedb => {
                    value => qr{/.*},
                    description => 'absolute path to cache (sqlite) database file',
                },
                history => {
                },
                silos => {
                    description => 'silos store collected data',
                    # "members" stands for all "non-internal" fields
                    members => {
                        'silo-.+' => {
                            regex => 1,
                            members => {
                                url => {
                                    value       => qr{https.*},
                                    example     => 'https://silo-a/api',
                                    description => 'url of the silo server. Only https:// allowed',
                                },
                                key => {
                                    description => 'shared secret to identify node'
                                },
                                not_existing => {
                                }
                            }
                        }
                    }
                }
            }
        },
        NOT_THERE => {
            error_msg => 'We shall not proceed without a section that is NOT_THERE',
        }
    }
}

