=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<App::Filite::Client>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'App::Filite::Client';
use Test2::Tools::Spec;
use Data::Dumper;

use JSON::PP qw( decode_json );

use FindBin qw( $Bin );
my $SHARE = "$Bin/../../../share";

describe "class `$CLASS`" => sub {

	tests 'has a constructor' => sub {
	
		can_ok( $CLASS, 'new' );
		isa_ok( $CLASS, 'Class::Tiny::Object' );
	};
};

describe "method `new_from_config`" => sub {

	tests 'it works' => sub {
		my $object = do {
			local $ENV{'FILITE_CLIENT_CONFIG'} = "$SHARE/config.json";
			$CLASS->new_from_config;
		};
		isa_ok( $object, $CLASS );
		is( $object->password, 'abc123', 'password attribute' );
		is( $object->server, 'example.com', 'server attribute' );
		is( $object->errors, 0, 'errors attribute' );
		isa_ok( $object->useragent, 'HTTP::Tiny' );
	};
};

describe "method `share`" => sub {
	
	my $guard;
	my @calls;
	my @input;
	my @urls;
	my $expected_calls;
	my $expected_result;
	
	before_case setup => sub {
		$guard = mock $CLASS => override => [
			share_file => sub { shift; push @calls, [ share_file => @_ ]; pop @urls; },
			share_text => sub { shift; push @calls, [ share_text => @_ ]; pop @urls; },
			share_link => sub { shift; push @calls, [ share_link => @_ ]; pop @urls; },
		];
	};
	
	after_case teardown => sub {
		@calls = ();
		undef $guard;
	};
	
	case 'simple text' => sub {
		@input = ( "$SHARE/file.txt", {} );
		@urls  = ( 'http://example.net/t/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_text => @input ] ];
	};
	
	case 'simple file' => sub {
		@input = ( "$SHARE/image.png", {} );
		@urls  = ( 'http://example.net/f/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_file => @input ] ];
	};
	
	case 'simple link' => sub {
		@input = ( "http://www.forward.example/", {} );
		@urls  = ( 'http://example.net/l/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_link => @input ] ];
	};
	
	case 'force text' => sub {
		@input = ( "$SHARE/image.png", { text => 1 } );
		@urls  = ( 'http://example.net/t/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_text => @input ] ];
	};
	
	case 'force file' => sub {
		@input = ( "$SHARE/file.txt", { file => 1 } );
		@urls  = ( 'http://example.net/f/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_file => @input ] ];
	};
	
	case 'force link' => sub {
		@input = ( "$SHARE/image.png", { link => 1 } );
		@urls  = ( 'http://example.net/t/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_link => @input ] ];
	};
	
	case 'imply text' => sub {
		@input = ( "$SHARE/image.png", { highlight => 1 } );
		@urls  = ( 'http://example.net/t/foo' );
		$expected_result = $urls[0];
		$expected_calls  = [ [ share_text => @input ] ];
	};
	
	tests 'it works' => sub {
		my $object = $CLASS->new( server => 'example.com', password => 1 );
		my $result = $object->share( @input );
		is( $result, $expected_result, 'result' );
		is( \@calls, $expected_calls, 'calls' );
	};
};

describe "method `share_text`" => sub {
	
	tests 'it works' => sub {
		
		my @args;
		my $mock = mock {}, add => [
			post => sub {
				shift;
				@args = @_;
				return { success => 1, content => 'abc' };
			},
		];
		my $object = $CLASS->new(
			useragent => $mock,
			server    => 'example.org',
			password  => 'xyz',
		);
		
		my $got = $object->share_text( "$SHARE/file.txt", { highlight => 1 } );
		is( $got, 'http://example.org/t/abc', 'result' );
		
		is(
			\@args,
			array {
				item string 'http://example.org/t';
				item hash {
					field content => D();
					field headers => hash {
						field 'Content-Type' => 'application/json';
						end;
					};
					end;
				};
				end;
			},
			'args',
		);
		
		is(
			decode_json( $args[1]{content} ),
			hash {
				field highlight => T();
				field contents => "Hello world.\n";
				end;
			},
			'JSON data',
		);
	};
};

describe "method `share_file`" => sub {
	
	tests 'it works' => sub {
		
		my @args;
		my $mock = mock {}, add => [
			post_multipart => sub {
				shift;
				@args = @_;
				return { success => 1, content => 'abc' };
			},
		];
		my $object = $CLASS->new(
			useragent => $mock,
			server    => 'example.org',
			password  => 'xyz',
		);
		
		my $got = $object->share_file( "$SHARE/image.png", {} );
		is( $got, 'http://example.org/f/abc', 'result' );
		
		is(
			\@args,
			array {
				item string 'http://example.org/f';
				item hash { etc; };
				end;
			},
			'args',
		);
	};
};

describe "method `share_link`" => sub {
	
	tests 'it works' => sub {
		
		my @args;
		my $mock = mock {}, add => [
			post => sub {
				shift;
				@args = @_;
				return { success => 1, content => 'abc' };
			},
		];
		my $object = $CLASS->new(
			useragent => $mock,
			server    => 'example.org',
			password  => 'xyz',
		);
		
		my $got = $object->share_link( 'https://www.forward.example/', {} );
		is( $got, 'http://example.org/l/abc', 'result' );
		
		is(
			\@args,
			array {
				item string 'http://example.org/l';
				item hash {
					field content => D();
					field headers => hash {
						field 'Content-Type' => 'application/json';
						end;
					};
					end;
				};
				end;
			},
			'args',
		);
		
		is(
			decode_json( $args[1]{content} ),
			hash {
				field forward => 'https://www.forward.example/';
				end;
			},
			'JSON data',
		);
	};
};

done_testing;
