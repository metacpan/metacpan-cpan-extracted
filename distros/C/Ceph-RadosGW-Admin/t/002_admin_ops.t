#!perl

use strict;
use warnings;

use Test::Spec;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::VCR::LWP qw(withVCR withoutVCR);
use Ceph::RadosGW::Admin;
use FindBin;
use File::Spec;
use Test::MockTime qw(set_absolute_time);

set_absolute_time('2014-11-26T10:55:30Z');

BEGIN {
	eval {
		require File::Spec->catfile($FindBin::Bin, 'test_settings.pl');
	};
	
	if ($@) {
		require File::Spec->catfile($FindBin::Bin, 'test_settings.pl.sample');
	}
}


$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
my ($access_key, $secret_key, $url) = get_auth_info();


describe "A Rados Gateway Admin Client" => sub {
	it "should require connection arguments" => sub {
		dies_ok {
			Ceph::RadosGW::Admin->new;
		};
	
		like($@, qr/required/i);		
	};

	describe "with connection details" => sub {
		my $sut;

		before each => sub {
			$sut = Ceph::RadosGW::Admin->new(
				access_key => $access_key,
				secret_key => $secret_key,
				url        => $url,
			);
		};

		it "should instantiate itself" => sub {
			isa_ok($sut, 'Ceph::RadosGW::Admin');
		};
		describe "working with users" => sub {
			my $client;
			before each => sub {
				$client = Ceph::RadosGW::Admin->new(
					access_key => $access_key,
					secret_key => $secret_key,
					url        => $url,
				);
				
			};
			it "should be able to look up a user" => sub {
				my $sut = $client->get_user(uid => 'test_user');
				cmp_deeply(
					$sut,
					all(
						isa('Ceph::RadosGW::Admin::User'),					
						methods(
							user_id      => 'test_user',
							display_name => re(qr/\S/),
							suspended    => any(1,0), 
						)
					)
				);
			};
			it "should be able to look up another user" => sub {
				my $sut = $client->get_user(uid => 'test_user2');
				cmp_deeply(
					$sut,
					all(
						isa('Ceph::RadosGW::Admin::User'),					
						methods(
							user_id      => 'test_user2',
							display_name => re(qr/\S/),
							suspended    => any(1,0),
							max_buckets  => 1000,
							subusers     => [],
							keys         => [
								{
									user => 'test_user2',
									access_key => re(qr/\S/),
									secret_key => re(qr/\S/),
								}
							],
							swift_keys => [],
							caps       => [],
						)
					)
				);
			
			};
			it "should be able to create a user" => sub {
				eval {
					$client->get_user(
						uid => 'test_user3',
					)->delete;
				};
				my $sut = $client->create_user(
					uid          => 'test_user3',
					display_name => 'display',
				);
				cmp_deeply(
					$sut,
					all(
						isa('Ceph::RadosGW::Admin::User'),					
						methods(
							user_id      => 'test_user3',
							display_name => 'display',
						)
					)
				);
			};
		};
	};
};

describe "A User" => sub {
	my ($client, $user, $name);
	my $i = 4;
	before each => sub {
		$name = "test_user$i";
		$i++;
		
		$client = Ceph::RadosGW::Admin->new(
			access_key => $access_key,
			secret_key => $secret_key,
			url        => $url,
		);
		
		eval {
			withoutVCR {
				$client->get_user(
					uid => $name,
				)->delete;
			};
		};
		
		$user = $client->create_user(
			uid          => $name,
			display_name => 'display',
		);
	};
	
	after each => sub {
		eval {
			$client->get_user(
				uid => $name,
			)->delete;
		};
	};
	

	it "should be able to delete itself" => sub {
		$user->delete;
		dies_ok {
			$client->get_user(uid => $name);
		};
	};
	
	it "should be able to purge data when a user is deleted" => sub {
		my %args;
		$user->expects('_request')->returns(sub { shift; %args = @_ });
		$user->delete(purge_data => 1);
		cmp_deeply(
			\%args,
			{
				purge_data => 1,
				DELETE     => ignore(),
			}
		);
	};
	
	it "should be able to give a hashref version of itself" => sub {
		my $sut = $user->as_hashref;
		cmp_deeply(
			$sut,
			superhashof({
				user_id      => $name,
				display_name => ignore(),
			})
		);
	};
	it "should be able to save changes" => sub {
		$user->display_name('new display name');
		$user->suspended(1);
		$user->save;
		my $sut = $client->get_user(uid => $name);
		cmp_deeply(
			$sut,
			all(
				isa('Ceph::RadosGW::Admin::User'),
				methods(
					user_id      => $name,
					display_name => 'new display name',
					suspended    => 1,
				)
			)
		);
	};
	it "should be able to add a key" => sub {
		my @sut = $user->create_key();
		cmp_deeply(
			\@sut,
			superbagof(
				{
					user         => $name,
					'access_key' => re(qr/\S/),
					'secret_key' => re(qr/\S/),
				},
				{
					user         => $name,
					'access_key' => re(qr/\S/),
					'secret_key' => re(qr/\S/),
				}
			)
		);
	};
	it "should be able to delete a key" => sub {
		$user->delete_key(access_key => $user->keys->[0]{access_key});
		my $sut = $client->get_user(uid => $user->user_id);
		
		cmp_deeply($sut->keys, []);
	};
	it "should know its interaction history" => sub {
		my %sut = $user->get_usage();
		ok(keys %sut);
	};
	it "should know how many resources it is using" => sub {
		lives_ok {
			$user->get_bucket_info();
		};
	};
};


withVCR {
	runtests;
} tape => File::Spec->catfile($FindBin::Bin, "admin_ops.tape");
