#!/usr/bin/env perl -w

use 5.005;

# SET UP A WINDOW HIERARCHY

	package Window;
		my $ids = 1;
		sub new   { bless { id=>$ids++ }, ref($_[0])||$_[0] }

 	use Class::Multimethods;

	multimethod handle => (Window, Command, OffMode) => sub
	{
		print "No window operations available in OffMode\n";
	};

	multimethod handle => (Window, Command, Mode) => sub
	{
		print "Window $_[0]->{id} can't handle a ",
			ref($_[1]), " command in ",
			ref($_[2]), " mode\n";
	};


	package ModalWindow;     @ISA = qw( Window );
 	use Class::Multimethods;

	multimethod handle => (ModalWindow, ReshapeCommand, Mode) => sub
	{
		print "Modal windows can't handle reshape commands\n";
	};

	multimethod handle => (ModalWindow, Accept, OffMode) => sub
	{
		print "Modal window $_[0]->{id} can't accept in OffMode!\n";
	};

	multimethod handle => (ModalWindow, Accept, Mode) => sub
	{
		print "Modal window $_[0]->{id} accepts!\n";
	};


	package MovableWindow;   @ISA = qw( Window );
 	use Class::Multimethods;

	multimethod handle => (MovableWindow, Move, OnMode) => sub
	{
		print "Moving window $_[0]->{id}!\n";
	};

	package ResizableWindow; @ISA = qw( MovableWindow );
 	use Class::Multimethods;

	multimethod handle => (ResizableWindow, Resize, OnMode) => sub
	{
		print "Resizing window $_[0]->{id}!\n";
	};

	multimethod handle => (ResizableWindow, MoveAndResize, OnMode) => sub
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
