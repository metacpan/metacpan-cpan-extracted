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

	multimethod handle => (Window, '#', Mode) => sub
	{};

	multimethod handle => (Window, Command, '*') => sub
	{};

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

	multimethod handle => (MovableWindow, Move, Mode) => sub
	{
		print "Moving window $_[0]->{id}!\n";
	};

	multimethod handle => (MovableWindow, ReshapeCommand, OnMode) => sub
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

	multimethod handle => (ResizableWindow, Command) => sub
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


	package main;

 	use Class::Multimethods;

	Class::Multimethods::analyse spindle;

	Class::Multimethods::analyse handle
	 	=> [ResizableWindow, Command, OnMode],
	 	   [MovableWindow, Move, OnMode];

	Class::Multimethods::analyse handle;

# CHECK 100% success

	multimethod perfect => ('#') => sub { "number\n" };
	multimethod perfect => ('$') => sub { "scalar\n" };

	Class::Multimethods::analyse perfect;

