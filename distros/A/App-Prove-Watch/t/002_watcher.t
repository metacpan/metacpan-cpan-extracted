# -*- perl -*-


use Test::More;
use Test::Spec;
use App::Prove::Watch;

{
	package mock::watcher;
	use strict;
	use warnings;
	
	sub new  {
		my $class = shift;
		return bless [@_], $class;
	}
	
	sub wait {
		my ($self, $code) = @_;
		
		my $path = shift @$self;
		$code->({ path => $path });
	}
}

describe "A prove watcher" => sub {	
	it "should be able to instantiate itself." => sub {
		my $sut = App::Prove::Watch->new();
		isa_ok($sut, 'App::Prove::Watch');
	};
	
	describe "with a work dir" => sub {
		it "should run tests when files change" => sub {
			my $sut = App::Prove::Watch->new(
				'--run' => sub { pass("Called") }
			);
			$sut->watcher(mock::watcher->new('somefile'));
			$sut->run(1);	
		};
	};
	
	describe "with ignore arguments" => sub {
		it "should ignore files it was told to ignore" => sub {
			my $called = 0;
			my $sut = App::Prove::Watch->new(
				'--run'    => sub { $called++ },
				'--ignore' => 'some.*'
			);
			$sut->watcher(mock::watcher->new(qw/somefile anotherfile/));
			$sut->run(1);
			
			is($called, 2);
		};	
	};
};




runtests;