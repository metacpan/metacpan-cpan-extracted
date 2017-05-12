#!/usr/bin/env perl -w

# SET UP A WINDOW HIERARCHY

	package Window;
		my $id = 1;
		sub new   { bless { id=>$id++ }, ref($_[0])||$_[0] }

# SET UP DISPATCH TABLE

		my %handler;

		sub initialize
		{
			my ($arg1,$arg2,$arg3,$handler) = @_;
			$handler{$arg1}{$arg2}{$arg3} = $handler;
		}

	initialize "Window", "Command", "Mode"
		=> sub {
			   print "Window $_[0]->{id} can't handle a ",
				ref($_[1]), " command in ",
				ref($_[2]), " mode\n";
		       };

	initialize "Window", "Command", "OffMode"
		=> sub { print "No window operations available in OffMode\n" };

	initialize "ModalWindow", "Reshape", "Mode"
		=> sub { print "Modal windows can't ",
			       "handle reshape commands\n"
		       };

	initialize "ModalWindow", "Accept", "Mode"
		=> sub { print "Modal window $_[0]->{id} accepts!\n" };

	initialize "ModalWindow", "Accept", "OffMode"
		=> sub { print "Modal window $_[0]->{id} ",
			       "can't accept in OffMode!\n"
		       };

	initialize "MovableWindow", "Move", "OnMode"
		=> sub { print "Moving window $_[0]->{id}!\n" };

	initialize "ResizableWindow", "Resize", "OnMode"
		=> sub { print "Resizing window $_[0]->{id}!\n" };

	initialize "ResizableWindow", "MoveAndResize", "OnMode"
		=> sub { print "Moving and resizing window $_[0]->{id}!\n" };

	my %ancestors = ();

	sub ancestors
	{
		no strict "refs";
		my ($class) = @_;
		return @{$ancestors{$class}} if $ancestors{$class};

		my @ancestry = ( $class );
		foreach my $parent ( @{$class."::ISA"} )
		{
			push @ancestry, $parent, ancestors($parent);
		}

		$ancestors{$class} = \@ancestry;
		return @ancestry;
	}

	sub handle
	{
		my ($arg1, $arg2, $arg3) = (ref($_[0]),ref($_[1]),ref($_[2]));
		my $handler = $handler{$arg1}{$arg2}{$arg3};
		if (!$handler)
		{
			my @ancestors1 = ancestors($arg1);
			my @ancestors2 = ancestors($arg2);
			my @ancestors3 = ancestors($arg3);

			SEARCH:
			foreach my $anc3 (@ancestors3)
			{
			    foreach my $anc2 (@ancestors2)
			    {
			        foreach my $anc1 (@ancestors1 )
			        {
				    $handler = $handler{$anc1}{$anc2}{$anc3};
				    next unless $handler;
				    $handler{$arg1}{$arg2}{$arg3} = $handler;
				    last SEARCH;
			        }
			    }
			}
		}
		die "No handler defined for " . join ',', map {ref} @_
			unless $handler;
		$handler->(@_);
	}

	package ModalWindow;     @ISA = qw( Window );
	package MovableWindow;   @ISA = qw( Window );
	package ResizableWindow; @ISA = qw( MovableWindow );

# SET UP A COMMAND HIERARCHY

	package Command;
		sub new   { bless {}, ref($_[0])||$_[0] }

	package ReshapeCommand; @ISA = qw( Command );

	package Accept; @ISA = qw( Command );

	package Move;   @ISA = qw( ReshapeCommand );
	package Resize; @ISA = qw( ReshapeCommand );

	package MoveAndResize; @ISA = qw( Move Resize );


# SET UP A MODE HIERARCHY

	package Mode;
		sub new   { bless {}, ref($_[0])||$_[0] }

	package OnMode;    @ISA = qw( Mode );
	package ModalMode; @ISA = qw( Mode );
	package OffMode;   @ISA = qw( Mode );


	package main;


# CREATE SOME WINDOWS...

	@window = (
			new ModalWindow,
			new MovableWindow,
			new ResizableWindow,
		  );

# ...AND SOME COMMANDS...

	@command = (
			new Move,
			new Resize,
			new MoveAndResize,
			new Accept,
		   );

# ...AND SOME MODES...

	@mode = (
			new OffMode,
			new ModalMode,
			new OnMode,
			new OnMode,
			new OnMode,
		   );

# AND INTERACT THEM ALL...

	srand(0);
	for (1..100000)
	{
		$w = $window[rand @window];
		$c = $command[rand @command];
		$m = $mode[rand @mode];
		print "handle(",ref($w),",",ref($c),",",ref($m),")...\n\t";
		eval { $w->handle($c,$m) } or print $@;
	}
