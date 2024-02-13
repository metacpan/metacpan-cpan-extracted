use v5.30;
use experimental qw(signatures);

my $program = 'blib/script/bcrypt';

subtest 'sanity' => sub {
	ok( -e $program, "$program exists" );
	SKIP: {
		skip "Windows doesn't think about 'executable'", 1 if $^O eq 'MSWin32';
		ok( -x $program, "$program is executable" );
		}
	};

sub dumper {
	state $rc = require Data::Dumper;
	Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump
	}

sub run_command ( %hash ) {
	state $rc = require IPC::Open3;
	state $rc2 = require Symbol;

	my @command = ( $^X, $program, exists $hash{args} ? $hash{args}->@* : () );

	my $pid = IPC::Open3::open3(
		my $input_fh,
		my $output_fh,
		my $error_fh = Symbol::gensym(),
		@command
		);

	if( $hash{input} ) {
		print { $input_fh } $hash{input};
		}
	close $input_fh;

	my $output = do { local $/; <$output_fh> };
	my $error  = do { local $/; <$error_fh> };

	waitpid $pid, 0;
	my $exit = $? >> 8;

	return {
	    command => \@command,
		output  => $output,
		error   => $error,
		'exit'  => $exit,
		};
	}

1;
