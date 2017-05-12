#!/usr/bin/perl -w
use strict;

use CPAN::Testers::WWW::Reports::Parser;
use Data::Dumper;
use Test::More;

eval "use YAML::XS";
plan skip_all => "YAML::XS required for testing YAML parser" if $@;
plan tests => 50;

my $count = 537;
my $report_original = {
    'ostext'        => 'Linux',
    'version'       => '0.13',
    'status'        => 'PASS',
    'dist'          => 'App-Maisha',
    'osvers'        => '2.6.26-2-686',
    'csspatch'      => 'unp',
    'state'         => 'pass',
    'distribution'  => 'App-Maisha',
    'perl'          => '5.11.5',
    'distversion'   => 'App-Maisha-0.13',
    'cssperl'       => 'dev',
    'osname'        => 'linux',
    'platform'      => 'i686-linux',
    'id'            => 7046516,
    'guid'          => '07046529-b19f-3f77-b713-d32bba55d77f'
};
my $report_filtered = {
    'version'       => '0.13',
    'grade'         => 'PASS',
    'distname'      => 'App-Maisha',
    'guid'          => '07046529-b19f-3f77-b713-d32bba55d77f',
    'url'           => 'http://www.cpantesters.org/cpan/report/07046529-b19f-3f77-b713-d32bba55d77f'
};
my $report_extended = {
    'ostext'        => 'Linux',
    'version'       => '0.13',
    'status'        => 'PASS',
    'grade'         => 'PASS',
    'dist'          => 'App-Maisha',
    'osvers'        => '2.6.26-2-686',
    'csspatch'      => 'unp',
    'state'         => 'pass',
    'distribution'  => 'App-Maisha',
    'perl'          => '5.11.5',
    'distversion'   => 'App-Maisha-0.13',
    'cssperl'       => 'dev',
    'osname'        => 'linux',
    'platform'      => 'i686-linux',
    'id'            => 7046516,
    'distname'      => 'App-Maisha',
    'dist'          => 'App-Maisha',
    'guid'          => '07046529-b19f-3f77-b713-d32bba55d77f',
    'url'           => 'http://www.cpantesters.org/cpan/report/07046529-b19f-3f77-b713-d32bba55d77f'
};
my @fields = qw(guid distname version grade url);
my @all_fields = qw(
            id distribution dist distname version distversion perl 
            state status grade action osname ostext osvers platform 
            archname url csspatch cssperl);

# failure tests
{
    my $obj;
    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new(
            'format' => 'YAML'
        );
    };
    like($@,qr/Must specify a file or data block to parse/);
    is( $obj, undef );

    eval {
        $obj = CPAN::Testers::WWW::Reports::Parser->new(
            'format' => 'YAML',
            'file'   => 'missing-file.yml'
        );
    };
    like($@,qr/Cannot access file/);
    is( $obj, undef );
}

# file tests
{
    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format' => 'YAML',
        'file'   => './t/samples/App-Maisha.yaml'
    );
    isa_ok($obj,'CPAN::Testers::WWW::Reports::Parser');

    my $data = $obj->reports();
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_original,'.. matches original report');

    $data = $obj->reports(@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_filtered,'.. matches filtered report');

    $data = $obj->reports('ALL',@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_extended,'.. matches extended report');

    $obj->filter();
    $data = $obj->report();
    #diag(Dumper($data));
    is_deeply($data,$report_original,'.. matches original report');

    $obj->reload;
    $obj->filter(@fields);
    $data = $obj->report();
    #diag(Dumper($data));
    is_deeply($data,$report_filtered,'.. matches filtered report');

    $obj->reload;
    $obj->filter('ALL',@fields);
    $data = $obj->report();
    #diag(Dumper($data));
    is_deeply($data,$report_extended,'.. matches extended report');

    $obj->reload;
    $obj->filter();
    my $reports = 0;
    while( $data = $obj->report() ) { $reports++ };
    is($reports,$count,'.. report count correct');

    {
        $obj->{loaded} = 0;
        $obj->filter(@all_fields);
        $data = $obj->report();

        no strict 'refs';
        for (qw(  id distribution dist distname version distversion perl 
                  state status grade action osname ostext osvers platform 
                  archname url csspatch cssperl )) {
            is($obj->$_(),$data->{$_},".. field '$_' matches direct and indirect access");
        }
    }
}

# glob tests
{
    open FILE, '<', './t/samples/App-Maisha.yaml';

    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format' => 'YAML',
        'file'   => \*FILE
    );
    isa_ok($obj,'CPAN::Testers::WWW::Reports::Parser');

    my $data = $obj->reports();
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_original,'.. matches original report');

    $data = $obj->reports(@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_filtered,'.. matches filtered report');

    $data = $obj->reports('ALL',@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_extended,'.. matches extended report');

    $obj->filter();
    $data = $obj->report();
    #diag(Dumper($data));
    is_deeply($data,$report_original,'.. matches original report');
}

# data tests
{
    open FILE, '<', './t/samples/App-Maisha.yaml';
    my $yaml = do { local $/; <FILE> };

    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        'format' => 'YAML',
        'data'   => $yaml
    );
    isa_ok($obj,'CPAN::Testers::WWW::Reports::Parser');

    my $data = $obj->reports();
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_original,'.. matches original report');

    $data = $obj->reports(@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_filtered,'.. matches filtered report');

    $data = $obj->reports('ALL',@fields);
    #diag(Dumper($data->[0]));
    is(scalar(@$data),$count,'.. report count correct');
    is_deeply($data->[0],$report_extended,'.. matches extended report');

    $obj->filter();
    $data = $obj->report();
    is_deeply($data,$report_original,'.. matches original report');
}
