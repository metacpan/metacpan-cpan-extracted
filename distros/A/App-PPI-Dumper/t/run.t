#!/usr/bin/perl

use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

use Test::More 'no_plan';
use Test::Output;

my $class  = 'App::PPI::Dumper';
my $method = 'run';

use_ok( $class );
can_ok( $class, $method );

my @regressions = (
	[ [ qw(corpus/hello.pl) ],      qw(regression/hello.pl)    ],
	[ [ qw(-C corpus/hello.pl) ],   qw(regression/hello-C.pl)  ],
	[ [ qw(-W corpus/hello.pl) ],   qw(regression/hello-W.pl)  ],
	[ [ qw(-P corpus/hello.pl) ],   qw(regression/hello-P.pl)  ],
	[ [ qw(-D corpus/hello.pl) ],   qw(regression/hello-D.pl)  ],
	[ [ qw(-i 1 corpus/hello.pl) ], qw(regression/hello-i1.pl) ],
	[ [ qw(-i 3 corpus/hello.pl) ], qw(regression/hello-i3.pl) ],
	[ [ qw(-l corpus/hello.pl) ],   qw(regression/hello-l.pl) ],
	);

foreach my $regression ( @regressions )
	{
	my( $argv, $output_file ) = @$regression;

	ok( -e $argv->[-1], "Input file $argv->[-1] exists" );

	my $basename = basename( $argv->[-1] );

	ok( -e $output_file, "Regression file $output_file exists" );

	my $expected_output = do { local( @ARGV, $/ ) = $output_file; <> };

	stdout_is(
		sub { $class->run( @$argv ) },
		$expected_output,
		"Trying " . join( " ", @$argv )
		);

	}

# 	[ [ qw(-m corpus/hello.pl) ],   qw(regression/hello-m.pl) ],
