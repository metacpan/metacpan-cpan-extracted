#!/usr/bin/env perl -w

# SET UP A WINDOW HIERARCHY

	package Window;
		my $id = 1;
		sub new   { bless { id=>$id++ }, ref($_[0])||$_[0] }

		sub handle
		{
			if ($_[2]->isa(OffMode))
			{
				print "No window operations available in OffMode\n";
			}
			else
			{
				print "Window $_[0]->{id} can't handle a ",
					ref($_[1]), " command in ",
					ref($_[2]), " mode\n";
			}
		}

	package ModalWindow;     @ISA = qw( Window );

		sub handle
		{
			if ($_[1]->isa(Accept))
			{
				if ($_[2]->isa(OffMode))
				{
					print "Modal window $_[0]->{id} can't accept in OffMode!\n";
				}
				else
				{
					print "Modal window $_[0]->{id} accepts!\n";
				}
			}
			elsif ($_[1]->isa(ReshapeCommand))
			{
				print "Modal windows can't handle reshape commands\n";
			}
			else
			{
				$_[0]->SUPER::handle(@_[1,2]);
			}
		}

	package MovableWindow;   @ISA = qw( Window );

		sub handle
		{
			if ($_[1]->isa(Move) && $_[2]->isa(OnMode))
			{
				print "Moving window $_[0]->{id}!\n";
			}
			else
			{
				$_[0]->SUPER::handle(@_[1,2]);
			}
		}

	package ResizableWindow; @ISA = qw( MovableWindow );

		sub handle
		{
			if ($_[1]->isa(MoveAndResize) && $_[2]->isa(OnMode))
			{
				print "Moving and resizing window $_[0]->{id}!\n";
			}
			elsif ($_[1]->isa(Resize) && $_[2]->isa(OnMode))
			{
				print "Resizing window $_[0]->{id}!\n";
			}
			else
			{
				$_[0]->SUPER::handle(@_[1,2]);
			}
		}


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
	for (1..10000)
	{
		$w = $window[rand @window];
		$c = $command[rand @command];
		$m = $mode[rand @mode];
		print "handle(",ref($w),",",ref($c),",",ref($m),")...\n\t";
		eval { $w->handle($c,$m) } or print $@;
	}
