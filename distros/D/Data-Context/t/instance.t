use strict;
use warnings;
use Test::More;# tests => 2;
use Path::Tiny;
use Data::Dumper qw/Dumper/;

use Data::Context;
use Data::Context::Instance;
use Data::Context::Loader::File;
my $dc = Data::Context->new(
    path => path($0)->parent->child('dc') . '',
);

my $have_json = eval {require JSON        };
my $have_yaml = eval {require YAML::XS    };
my $have_xml  = eval {require XML::Simple };

test_object();
test_sort();

done_testing;

sub test_object {
    my $dci;
    SKIP: {
        skip "Need JSON to run" => 1 unless $have_json;

        require Data::Context::Loader::File::JS;
        $dci = Data::Context::Instance->new(
            path => 'data',
            loader => Data::Context::Loader::File::JS->new(
                file   => path($0)->parent->child('dc/data.dc.js'),
                type   => 'js',
            ),
            dc   => $dc,
        )->init;

        ok $dci, 'get an object back';
        #diag Dumper $dci->raw;
        #diag Dumper $dci->actions;
        #diag Dumper $dci->get_data({test=>{value=>['replace']}});
    }

    SKIP: {
        skip "Need YAML::XS to run" => 1 unless $have_yaml;

        require Data::Context::Loader::File::YAML;
        $dci = Data::Context::Instance->new(
            path => 'deep/child',
            loader => Data::Context::Loader::File::YAML->new(
                file => path($0)->parent->child('dc/deep/child.dc.yml'),
                type => 'yaml',
            ),
            dc   => $dc,
        )->init;

        ok $dci, 'get an object back';
        is $dci->raw->{basic}, 'text', 'Get data from parent config';
        #diag Dumper $dci->raw;
    }

    SKIP: {
        skip "Need XML::Simple to run" => 1 unless $have_xml;

        require Data::Context::Loader::File::XML;
        $dci = Data::Context::Instance->new(
            path => 'data',
            loader => Data::Context::Loader::File::XML->new(
                file => path($0)->parent->child('dc/_default.dc.xml'),
                type => 'xml',
            ),
            dc   => $dc,
        )->init;

        ok $dci, 'get data for xml';
        #diag Dumper $dci->raw;
        #diag Dumper $dci->actions;
        #diag Dumper $dci->get_data({test=>{value=>['replace']}});
    }
}

sub test_sort {
    my @tests = (
        {
            four  => { found => 1, order => -1 },
            two   => { found => 2, order => undef },
            three => { found => 3, order => undef },
            one   => { found => 4, order => 1 },
        } => [ qw/ one two three four / ],
    );
    my $sorted = [ Data::Context::Instance::_sort_optional( $tests[0] ) ];

    is_deeply $sorted, $tests[1], "Sorted correctly"
        or diag Dumper $sorted, $tests[1];
}
