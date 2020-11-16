=pod

=encoding utf-8

=head1 PURPOSE

Test that App::GhaProve works okay.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use App::GhaProve;

my ( $i, @args, @env ) = ( 0 );

my $callback = sub {
	push @args, [ @_ ];
	push @env, { %ENV };
	0;
};

local $App::GhaProve::QUIET = 1;

for my $mode ( qw( STANDARD standard 0 ) ) {
	subtest "cover=0; mode=$mode" => sub {
		local %ENV;
		$ENV{GHA_TESTING_COVER}     = 0;
		$ENV{GHA_TESTING_MODE}      = $mode;
		$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
		( @args, @env ) = ();
		
		is(
			'App::GhaProve'->go( $callback, qw/ x y z / ),
			0,
		);
		
		ok( @args == 1 );
		is_deeply( $args[0], [ qw/ prove x y z / ] );
		ok( not $env[0]{EXTENDED_TESTING} );
		is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz' );
	};
}

for my $mode ( qw( EXTENDED extended 1 ) ) {
	subtest "cover=0; mode=$mode" => sub {
		local %ENV;
		$ENV{GHA_TESTING_COVER}     = 0;
		$ENV{GHA_TESTING_MODE}      = $mode;
		$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
		( @args, @env ) = ();
		
		is(
			'App::GhaProve'->go( $callback, qw/ x y z / ),
			0,
		);
		
		ok( @args == 1 );
		is_deeply( $args[0], [ qw/ prove x y z / ] );
		ok( $env[0]{EXTENDED_TESTING} );
		is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz' );
	};
}

for my $mode ( qw( BOTH both 2 ) ) {
	subtest "cover=0; mode=$mode" => sub {
		local %ENV;
		$ENV{GHA_TESTING_COVER}     = 0;
		$ENV{GHA_TESTING_MODE}      = $mode;
		$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
		( @args, @env ) = ();
		
		is(
			'App::GhaProve'->go( $callback, qw/ x y z / ),
			0,
		);
		
		ok( @args == 2 );
		is_deeply( $args[0], [ qw/ prove x y z / ] );
		is_deeply( $args[1], [ qw/ prove x y z / ] );
		ok( not $env[0]{EXTENDED_TESTING} );
		is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz' );
		ok( $env[1]{EXTENDED_TESTING} );
		is( $env[1]{HARNESS_PERL_SWITCHES}, 'xyz' );
	};
}

for my $cov ( qw( 1 true TRUE ) ) {
	for my $mode ( qw( STANDARD standard 0 ) ) {
		subtest "cover=$cov; mode=$mode" => sub {
			local %ENV;
			$ENV{GHA_TESTING_COVER}     = $cov;
			$ENV{GHA_TESTING_MODE}      = $mode;
			$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
			( @args, @env ) = ();
			
			is(
				'App::GhaProve'->go( $callback, qw/ x y z / ),
				0,
			);
			
			ok( @args == 1 );
			is_deeply( $args[0], [ qw/ prove x y z / ] );
			ok( not $env[0]{EXTENDED_TESTING} );
			is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz -MDevel::Cover' );
		};
	}

	for my $mode ( qw( EXTENDED extended 1 ) ) {
		subtest "cover=$cov; mode=$mode" => sub {
			local %ENV;
			$ENV{GHA_TESTING_COVER}     = $cov;
			$ENV{GHA_TESTING_MODE}      = $mode;
			$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
			( @args, @env ) = ();
			
			is(
				'App::GhaProve'->go( $callback, qw/ x y z / ),
				0,
			);
			
			ok( @args == 1 );
			is_deeply( $args[0], [ qw/ prove x y z / ] );
			ok( $env[0]{EXTENDED_TESTING} );
			is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz -MDevel::Cover' );
		};
	}

	for my $mode ( qw( BOTH both 2 ) ) {
		subtest "cover=$cov; mode=$mode" => sub {
			local %ENV;
			$ENV{GHA_TESTING_COVER}     = $cov;
			$ENV{GHA_TESTING_MODE}      = $mode;
			$ENV{HARNESS_PERL_SWITCHES} = 'xyz';
			( @args, @env ) = ();
			
			is(
				'App::GhaProve'->go( $callback, qw/ x y z / ),
				0,
			);
			
			ok( @args == 2 );
			is_deeply( $args[0], [ qw/ prove x y z / ] );
			is_deeply( $args[1], [ qw/ prove x y z / ] );
			ok( not $env[0]{EXTENDED_TESTING} );
			is( $env[0]{HARNESS_PERL_SWITCHES}, 'xyz -MDevel::Cover' );
			ok( $env[1]{EXTENDED_TESTING} );
			is( $env[1]{HARNESS_PERL_SWITCHES}, 'xyz -MDevel::Cover' );
		};
	}
}

done_testing;

