#!/usr/bin/env perl -w

use 5.005;
use NewMultimethods;

# SET UP A WINDOW HIERARCHY

	package Window;
		my $ids = 1;
		sub new   { bless { id=>$ids++ }, ref($_[0])||$_[0] }


	multi handle (Window, Command, OffMode) 
	{
		print "No window operations available in OffMode\n";
	};

	multi handle (Window, Command, Mode)
	{
		print "Window $_[0]->{id} can't handle a ",
			ref($_[1]), " command in ",
			ref($_[2]), " mode\n";
	};


	package ModalWindow;     @ISA = qw( Window );

	multi handle (ModalWindow, ReshapeCommand, Mode)
	{
		print "Modal windows can't handle reshape commands\n";
	}

	multi handle (ModalWindow, Accept, OffMode)
	{
		print "Modal window $_[0]->{id} can't accept in OffMode!\n";
	}

	multi handle (ModalWindow, Accept, Mode)
	{
		print "Modal window $_[0]->{id} accepts!\n";
	}


	package MovableWindow;   @ISA = qw( Window );

	multi handle (MovableWindow, Move, OnMode) 
	{
		print "Moving window $_[0]->{id}!\n";
	};

	package ResizableWindow; @ISA = qw( MovableWindow );

	multi handle (ResizableWindow, Resize, OnMode)
	{
		print "Resizing window $_[0]->{id}!\n";
	};

	multi handle (ResizableWindow, MoveAndResize, OnMode)
	{
		print "Moving and resizing window $_[0]->{id}!\n";
	};


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


# SET UP SOME MULTIMETHODS TO HANDLE THE VARIOUS INTERESTING CASES

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
