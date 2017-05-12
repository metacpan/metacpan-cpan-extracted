#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 23;

use CPAN::Testers::WWW::Reports::Query::Reports;
#use Data::Dumper;

my $nomock;
my ($mock,$url,%raw);

BEGIN {
	eval "use Test::MockObject";
    $nomock = $@;

    unless($nomock) {
        $mock = Test::MockObject->new();
        $mock->fake_module( 'WWW::Mechanize', 
            'get'       => sub { $url = $_[1]; return; },  
            'success'   => sub { return 1; },  
            'content'   => sub { return $raw{$url} } 
        );
        $mock->fake_new( 'WWW::Mechanize' );
        $mock->set_true( qw(success) );
    }
}

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
        error   => '',
        raw     => '{"7211":{"version":"1.25","dist":"GD","osvers":"2.7","state":"pass","perl":"5.5.3","fulldate":"200002231727","osname":"solaris","postdate":"200002","type":"2","id":"7211","guid":"00007211-b19f-3f77-b713-d32bba55d77f","platform":"sun4-solaris","tester":"schinder@pobox.com"}}
'
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
        error   => '',
        raw     => '{"7211":{"version":"1.25","dist":"GD","osvers":"2.7","state":"pass","perl":"5.5.3","fulldate":"200002231727","osname":"solaris","postdate":"200002","type":"2","id":"7211","guid":"00007211-b19f-3f77-b713-d32bba55d77f","platform":"sun4-solaris","tester":"schinder@pobox.com"}}
'
    },
    { 
        range   => '-',
        count   => 2500,
        error   => '',
        raw     => '{"7211":{"version":"1.25","dist":"GD","osvers":"2.7","state":"pass","perl":"5.5.3","fulldate":"200002231727","osname":"solaris","postdate":"200002","type":"2","id":"7211","guid":"00007211-b19f-3f77-b713-d32bba55d77f","platform":"sun4-solaris","tester":"schinder@pobox.com"}}
'
    }
);

for my $arg (@args) {
    next    unless($arg->{raw});

    if($arg->{date}) {
        $raw{'http://www.cpantesters.org/cgi-bin/reports-metadata.cgi?date=' . $arg->{date}} = $arg->{raw}; 
    } elsif($arg->{range}) {
        $raw{'http://www.cpantesters.org/cgi-bin/reports-metadata.cgi?range=' . $arg->{range}} = $arg->{raw}; 
    }
}

#diag("raw=".Dumper(\%raw));

SKIP: {
	skip "Test::MockObject required for plugin testing\n", 23   if($nomock);

    my $query = CPAN::Testers::WWW::Reports::Query::Reports->new();
    isa_ok($query,'CPAN::Testers::WWW::Reports::Query::Reports');

    for my $args (@args) {
        if(defined $args->{date}) {
            my $data = $query->date( $args->{date} );
            my $skip = $args->{results} ? scalar(keys %{$args->{results}}) : 0;

            #diag("url=$url, raw=$raw{$url}");

            is($query->error,$args->{error},'.. no error reported');
            is($query->raw,$args->{raw},'.. raw query matches') if(defined $args->{raw});

            if($data && $args->{results}) {
                is($data->{$_},$args->{results}{$_},".. got '$_' in date hash [$args->{date}]") for(keys %{$args->{results}});

            } elsif($args->{results}) {
                diag($query->error());
                if($args->{results}) { ok(0)   for(keys %{$args->{results}}) }

            } else {
                is($data, undef,".. got no results, as expected [$args->{date}]");
            }

        } elsif(defined $args->{range}) {
            my $data = $query->range( $args->{range} );

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
                diag($query->error());
                if($args->{results}) { ok(0)   for(keys %{$args->{results}}) }
                ok(0)   if($args->{start});
                ok(0)   if($args->{stop});
                ok(0)   if($args->{count});
            }

        } else {
            ok(0,'missing date or range test');
        }
    }
}
