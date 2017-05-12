#!/usr/bin/env perl -w

# SET UP A WINDOW HIERARCHY

	package Window;
		my $id = 1;
		sub new   { bless { id=>$id++ }, ref($_[0])||$_[0] }

# SET UP DISPATCH TABLE

		my %handler;

		sub generic_handler
		{
			print "Window $_[0]->{id} can't handle a ",
				ref($_[1]), " command in ",
				ref($_[2]), " mode\n";
		}

		sub OffMode_handler
		{
			print "No window operations available in OffMode\n";
		}

		sub ModalWindow_Accept_OffMode_handler
		{
			print "Modal window $_[0]->{id} can't accept in OffMode!\n";
		}
		
		sub ModalWindow_Accept_handler
		{
			print "Modal window $_[0]->{id} accepts!\n";
		}

		sub ModalWindow_Reshape_handler
		{
			print "Modal windows can't handle reshape commands\n";
		}

		sub MovableWindow_Move_OnMode_handler
		{
			print "Moving window $_[0]->{id}!\n";
		}

		sub ResizableWindow_MoveAndResize_OnMode_handler
		{
			print "Moving and resizing window $_[0]->{id}!\n";
		}

		sub ResizableWindow_Resize_OnMode_handler
		{
			print "Resizing window $_[0]->{id}!\n";
		}

$handler{Window}{Command}{Mode} = \&generic_handler;
$handler{Window}{Command}{OnMode} = \&generic_handler;
$handler{Window}{Command}{OffMode} = \&OffMode_handler;
$handler{Window}{Command}{ModalMode} = \&generic_handler;
$handler{Window}{Reshape}{Mode} = \&generic_handler;
$handler{Window}{Reshape}{OnMode} = \&generic_handler;
$handler{Window}{Reshape}{OffMode} = \&OffMode_handler;
$handler{Window}{Reshape}{ModalMode} = \&generi_handler;
$handler{Window}{Accept}{Mode} = \&generic_handler;
$handler{Window}{Accept}{OnMode} = \&generic_handler;
$handler{Window}{Accept}{OffMode} = \&OffMode_handler;
$handler{Window}{Accept}{ModalMode} = \&generic_handler;
$handler{Window}{Move}{Mode} = \&generic_handler;
$handler{Window}{Move}{OnMode} = \&generic_handler;
$handler{Window}{Move}{OffMode} = \&OffMode_handler;
$handler{Window}{Move}{ModalMode} = \&generic_handler;
$handler{Window}{Resize}{Mode} = \&generic_handler;
$handler{Window}{Resize}{OnMode} = \&generic_handler;
$handler{Window}{Resize}{OffMode} = \&OffMode_handler;
$handler{Window}{Resize}{ModalMode} = \&generic_handler;
$handler{Window}{MoveAndResize}{Mode} = \&generic_handler;
$handler{Window}{MoveAndResize}{OnMode} = \&generic_handler;
$handler{Window}{MoveAndResize}{OffMode} = \&OffMode_handler;
$handler{Window}{MoveAndResize}{ModalMode} = \&generic_handler;

$handler{ModalWindow}{Command}{Mode} = \&generic_handler;
$handler{ModalWindow}{Command}{OnMode} = \&generic_handler;
$handler{ModalWindow}{Command}{OffMode} = \&OffMode_handler;
$handler{ModalWindow}{Command}{ModalMode} = \&generic_handler;
$handler{ModalWindow}{Reshape}{Mode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Reshape}{Mode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Reshape}{OnMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Reshape}{OffMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Accept}{Mode} = \&ModalWindow_Accept_handler;
$handler{ModalWindow}{Accept}{OnMode} = \&ModalWindow_Accept_handler;
$handler{ModalWindow}{Accept}{OffMode} = \&ModalWindow_Accept_OffMode_handler;
$handler{ModalWindow}{Accept}{ModalMode} = \&ModalWindow_Accept_handler;
$handler{ModalWindow}{Move}{Mode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Move}{OnMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Move}{OffMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Move}{ModalMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Resize}{Mode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Resize}{OnMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Resize}{OffMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{Resize}{ModalMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{MoveAndResize}{Mode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{MoveAndResize}{OnMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{MoveAndResize}{OffMode} = \&ModalWindow_Reshape_handler;
$handler{ModalWindow}{MoveAndResize}{ModalMode} = \&ModalWindow_Reshape_handler;

$handler{MovableWindow}{Command}{Mode} = \&generic_handler;
$handler{MovableWindow}{Command}{OnMode} = \&generic_handler;
$handler{MovableWindow}{Command}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{Command}{ModalMode} = \&generic_handler;
$handler{MovableWindow}{Reshape}{Mode} = \&generic_handler;
$handler{MovableWindow}{Reshape}{OnMode} = \&generic_handler;
$handler{MovableWindow}{Reshape}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{Reshape}{ModalMode} = \&generic_handler;
$handler{MovableWindow}{Accept}{Mode} = \&generic_handler;
$handler{MovableWindow}{Accept}{OnMode} = \&generic_handler;
$handler{MovableWindow}{Accept}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{Accept}{ModalMode} = \&generic_handler;
$handler{MovableWindow}{Move}{Mode} = \&generic_handler;
$handler{MovableWindow}{Move}{OnMode} = \&MovableWindow_Move_OnMode_handler;
$handler{MovableWindow}{Move}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{Move}{ModalMode} = \&generic_handler;
$handler{MovableWindow}{Resize}{Mode} = \&generic_handler;
$handler{MovableWindow}{Resize}{OnMode} = \&generic_handler;
$handler{MovableWindow}{Resize}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{Resize}{ModalMode} = \&generic_handler;
$handler{MovableWindow}{MoveAndResize}{Mode} = \&generic_handler;;
$handler{MovableWindow}{MoveAndResize}{OnMode} = \&MovableWindow_Move_OnMode_handler;
$handler{MovableWindow}{MoveAndResize}{OffMode} = \&OffMode_handler;
$handler{MovableWindow}{MoveAndResize}{ModalMode} = \&generic_handler;

$handler{ResizableWindow}{Command}{Mode} = \&generic_handler;
$handler{ResizableWindow}{Command}{OnMode} = \&generic_handler;
$handler{ResizableWindow}{Command}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{Command}{ModalMode} = \&generic_handler;
$handler{ResizableWindow}{Reshape}{Mode} = \&generic_handler;
$handler{ResizableWindow}{Reshape}{OnMode} = \&generic_handler;
$handler{ResizableWindow}{Reshape}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{Reshape}{ModalMode} = \&generic_handler;
$handler{ResizableWindow}{Accept}{Mode} = \&generic_handler;
$handler{ResizableWindow}{Accept}{OnMode} = \&generic_handler;
$handler{ResizableWindow}{Accept}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{Accept}{ModalMode} = \&generic_handler;
$handler{ResizableWindow}{Move}{Mode} = \&generic_handler;
$handler{ResizableWindow}{Move}{OnMode} = \&MovableWindow_Move_OnMode_handler;
$handler{ResizableWindow}{Move}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{Move}{ModalMode} = \&generic_handler;
$handler{ResizableWindow}{Resize}{Mode} = \&generic_handler;
$handler{ResizableWindow}{Resize}{OnMode} = \&ResizableWindow_Resize_OnMode_handler;
$handler{ResizableWindow}{Resize}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{Resize}{ModalMode} = \&generic_handler;
$handler{ResizableWindow}{MoveAndResize}{Mode} = \&generic_handler;
$handler{ResizableWindow}{MoveAndResize}{OnMode} = \&ResizableWindow_MoveAndResize_OnMode_handler;
$handler{ResizableWindow}{MoveAndResize}{OffMode} = \&OffMode_handler;
$handler{ResizableWindow}{MoveAndResize}{ModalMode} = \&generic_handler;

		sub handle
		{
			$handler{ref $_[0]}{ref $_[1]}{ref $_[2]}->(@_);
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
	for (1..10000)
	{
		$w = $window[rand @window];
		$c = $command[rand @command];
		$m = $mode[rand @mode];
		print "handle(",ref($w),",",ref($c),",",ref($m),")...\n\t";
		eval { $w->handle($c,$m) } or print $@;
	}
