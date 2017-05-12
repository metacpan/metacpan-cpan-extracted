use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
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
};

my $p = Data::Processor->new($schema);
my $data_template = $p->make_data();
ok (exists $data_template->{GENERAL}, 'section "GENERAL" exists');
ok (exists $data_template->{GENERAL}->{logfile}, '"logfile" exists');
ok ($data_template->{GENERAL}->{logfile} = 'absolute path to logfile (?-xism:/.*)', 'logifle has correct content');

my $data_template = $p->make_data($schema->{GENERAL}->{members}->{silos});
ok (exists $data_template->{'silo-.+'}, 'entry point "silos" found');
ok ($data_template->{'silo-.+'}->{url} =~ m{^url of the silo server. Only https:// allowed},
    'url has correct content');


done_testing;
