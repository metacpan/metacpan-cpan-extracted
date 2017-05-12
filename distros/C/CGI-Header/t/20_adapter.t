use strict;
use warnings;
use Test::MockTime qw/set_fixed_time/;
use CGI;
use CGI::Cookie;
use CGI::Header::Adapter;
use Test::More tests => 3;
use Test::Exception;

set_fixed_time( 1341637509 );

# NOTE: $q->redirect( -p3p => \@tags ) doesn't work

my @args = (
    '-NPH'          => 1,
    '-Status'       => '304 Not Modified',
    '-Content_Type' => 'text/plain',
    '-Charset'      => 'utf-8',
    '-Attachment'   => 'genome.jpg',
    '-P3P'          => 'CAO DSP LAW CURa',
    '-Target'       => 'ResultsWindow',
    '-Expires'      => '+3d',
    '-Foo_Bar'      => 'baz',
    '-Cookie'       => [ CGI::Cookie->new(ID => 123456) ],
);

my $header = CGI::Header::Adapter->new( header => { @args } );

is_deeply $header->as_arrayref, [
    'Server',              'cmdline',
    'Status',              '304 Not Modified',
    'Window-Target',       'ResultsWindow',
    'P3P',                 'policyref="/w3c/p3p.xml", CP="CAO DSP LAW CURa"',
    'Set-Cookie',          'ID=123456; path=/',
    'Expires',             'Tue, 10 Jul 2012 05:05:09 GMT',
    'Date',                'Sat, 07 Jul 2012 05:05:09 GMT',
    'Content-Disposition', 'attachment; filename="genome.jpg"',
    'Foo-bar',             'baz',
    'Content-Type',        'text/plain; charset=utf-8',
];

is $header->as_string, $header->query->header( @args );

throws_ok { $header->finalize } qr{^call to abstract method};
