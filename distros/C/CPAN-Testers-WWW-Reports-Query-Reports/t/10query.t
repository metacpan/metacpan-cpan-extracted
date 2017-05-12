#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 28;

use CPAN::Testers::WWW::Reports::Query::Reports;
#use Data::Dumper;

# various argument sets for examples

my @args = (
    { 
        date    => '2005-02-08',
        results => { from => 182971, to => 183076, range => '182971-183076' },
        error   => '',
        raw     => '{"to":"183076","from":"182971","range":"182971-183076","list":["182971","182972","182978","182979","182980","182981","182982","182983","182984","182985","182986","182987","182988","182989","182990","182991","182992","182993","182994","182995","182996","182997","182998","182999","183000","183001","183002","183005","183006","183007","183008","183009","183010","183011","183012","183013","183014","183015","183016","183017","183018","183019","183020","183021","183022","183023","183024","183025","183026","183027","183028","183029","183030","183031","183033","183034","183037","183039","183040","183041","183042","183045","183046","183047","183048","183049","183051","183052","183053","183054","183055","183056","183057","183058","183059","183060","183061","183062","183063","183064","183065","183066","183067","183069","183070","183076"]}
'
    },
    { 
        range   => '7211',
        count   => 1,
        results => { '7211' => {
                        'version'   => '1.25',
                        'dist'      => 'GD',
                        'osvers'    => '2.7',
                        'state'     => 'pass',
                        'perl'      => '5.5.3',
                        'fulldate'  => '200002231727',
                        'osname'    => 'solaris',
                        'postdate'  => '200002',
                        'platform'  => 'sun4-solaris',
                        'guid'      => '00007211-b19f-3f77-b713-d32bba55d77f',
                        'id'        => '7211',
                        'type'      => '2',
                        'tester'    => 'schinder@pobox.com'
                   } },
        error   => '',
        raw     => '{"7211":{"version":"1.25","dist":"GD","osvers":"2.7","state":"pass","perl":"5.5.3","fulldate":"200002231727","osname":"solaris","postdate":"200002","type":"2","id":"7211","guid":"00007211-b19f-3f77-b713-d32bba55d77f","platform":"sun4-solaris","tester":"schinder@pobox.com"}}
'
    },
    { 
        range   => '7211-',
        start   => 7211,
        count   => 2500,
        results => { '7211' => {
                        'version'   => '1.25',
                        'dist'      => 'GD',
                        'osvers'    => '2.7',
                        'state'     => 'pass',
                        'perl'      => '5.5.3',
                        'fulldate'  => '200002231727',
                        'osname'    => 'solaris',
                        'postdate'  => '200002',
                        'platform'  => 'sun4-solaris',
                        'guid'      => '00007211-b19f-3f77-b713-d32bba55d77f',
                        'id'        => '7211',
                        'type'      => '2',
                        'tester'    => 'schinder@pobox.com'
                   } },
        error   => ''
    },
    { 
        range   => '-7211',
        stop    => 7211,
        count   => 2500,
        results => { '7211' => {
                        'version'   => '1.25',
                        'dist'      => 'GD',
                        'osvers'    => '2.7',
                        'state'     => 'pass',
                        'perl'      => '5.5.3',
                        'fulldate'  => '200002231727',
                        'osname'    => 'solaris',
                        'postdate'  => '200002',
                        'platform'  => 'sun4-solaris',
                        'guid'      => '00007211-b19f-3f77-b713-d32bba55d77f',
                        'id'        => '7211',
                        'type'      => '2',
                        'tester'    => 'schinder@pobox.com'
                   } },
        error   => ''
    },
    { 
        range   => '-',
        count   => 2500,
        error   => ''
    },
);

# bad data
my @bad = (
    { 
        date    => '',
        results => undef,
        error   => undef
    },
    { 
        date    => 'blah',
        results => undef,
        error   => undef
    },
    { 
        range   => '',
        results => undef,
        error   => undef
    },
    { 
        range   => 'blah',
        results => undef,
        error   => undef
    },
);

my $query = CPAN::Testers::WWW::Reports::Query::Reports->new();
isa_ok($query,'CPAN::Testers::WWW::Reports::Query::Reports');

{
    for my $args (@bad) {
        if(defined $args->{date}) {
            my $data = $query->date( $args->{date} );
            is($data, undef,".. got no results, as expected for date [$args->{date}]");
        } elsif(defined $args->{range}) {
            my $data = $query->range( $args->{range} );
            is($data, undef,".. got no results, as expected for range [$args->{range}]");
        }
        is($query->error,$args->{error},'.. no error reported');
    }
}

SKIP: {
    skip "Network unavailable", 19 if(pingtest());

    for my $args (@args) {
        if(defined $args->{date}) {
            my $data = $query->date( $args->{date} );
            my $skip = $args->{results} ? scalar(keys %{$args->{results}}) : 0;

            SKIP: {
                skip "Request timeout, skipping", $skip + 2
                    if($query->error && $query->error =~ /read timeout|Can't connect to www.cpantesters.org/);

                is($query->error,$args->{error},'.. no error reported');
                is($query->raw,$args->{raw},'.. raw query matches') if(defined $args->{raw});

                if($data && $args->{results}) {
                    is($data->{$_},$args->{results}{$_},".. got '$_' in date hash [$args->{date}]") for(keys %{$args->{results}});
                } elsif($args->{results}) {
                    SKIP: {
                        skip "No response from request, site may be down", $skip;

                        #diag($query->error());
                        if($args->{results}) { ok(1)   for(keys %{$args->{results}}) }
                    }
                } else {
                    is($data, undef,".. got no results, as expected [$args->{date}]");
                }
            }

        } elsif(defined $args->{range}) {
            my $data = $query->range( $args->{range} );
            my $skip = $args->{results} ? scalar(keys %{$args->{results}}) : 0;
            for(qw(start stop count)) {
                $skip++ if($args->{$_});
            }

            SKIP: {
                skip "Request timeout, skipping", $skip + 2
                    if($query->error && $query->error =~ /read timeout|Can't connect to www.cpantesters.org/);

                is($query->error,$args->{error},'.. no error reported');
                is($query->raw,$args->{raw},'.. raw query matches') if(defined $args->{raw});

                if($data) {
                    if($args->{results}) {
                        #diag(Dumper( $data ));
                        is_deeply($data->{$_},$args->{results}{$_},".. got '$_' in range hash [$args->{range}]") 
                            for(keys %{$args->{results}});
                    }
                    my @keys = sort { $a <=> $b } keys %$data;
                    if($args->{start}) {
                        is($keys[0], $args->{start},".. got start value [$args->{range}]");
                    }
                    if($args->{stop}) {
                        is($keys[-1], $args->{stop},".. got stop value [$args->{range}]");
                    }
                    if($args->{count}) {
                        cmp_ok(scalar @keys, '<=', $args->{count},".. counted number of records [$args->{range}]");
                    }
                } else {
                    SKIP: {
                        skip "No response from request, site may be down", $skip;

                        #diag($query->error());
                        if($args->{results}) { ok(1)   for(keys %{$args->{results}}) }
                        ok(1)   if($args->{start});
                        ok(1)   if($args->{stop});
                        ok(1)   if($args->{count});
                    }
                }
            }

        } else {
            ok(0,'missing date or range test');
        }
    }
}

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = 'www.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /cygwin/i                            ? "ping $domain 56 1" : # ping [ -dfqrv ] host [ packetsize [ count [ preload ]]]
                $^O =~ /dos|os2|mswin32|netware/i           ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
