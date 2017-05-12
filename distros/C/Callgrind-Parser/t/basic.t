use strict;
use warnings;
use Test::Spec;
use base qw(Test::Spec);
use Test::Exception;
use Callgrind::Parser;

describe "Callgrind::Parser" => sub{
    describe "parseFile" => sub {
	it "dies if it cannot read input file" => sub {
	    dies_ok { Callgrind::Parser::parseFile('/some/path/to/a/file/that/isnt/there.txt')} 'Should have died';
	};
	it "returns hash with header data and maint" => sub {
	    my $res = Callgrind::Parser::parseFile('t/data/helloworld.out');
	    ok(exists $res->{meta});
	    ok(exists $res->{main});
	}
    };
};

runtests;