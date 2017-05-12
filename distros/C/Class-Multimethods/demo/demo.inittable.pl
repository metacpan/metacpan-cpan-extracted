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
			foreach my $a1 ( @$arg1 )
			{
			    foreach my $a2 ( @$arg2)
			    {
				foreach my $a3 ( @$arg3)
				{
				    $handler{$a1}{$a2}{$a3} = $handler;
				}
			    }
			}
		}

	my $windows  = [qw(Window ModalWindow MovableWindow ResizableWindow)];
	my $commands = [qw(Command Reshape Accept Move Resize MoveAndResize)];
	my $modes    = [qw(Mode OnMode OffMode ModalMode)];

	initialize $windows, $commands, $modes
		=> sub {
			   print "Window $_[0]->{id} can't handle a ",
				ref($_[1]), " command in ",
				ref($_[2]), " mode\n";
		       };

	initialize $windows, $commands, ['OffMode']
		=> sub { print "No window operations available in OffMode\n" };

	initialize [qw(ModalWindow)],
		   [qw(Reshape Resize Move MoveAndResize)],
		   $modes
		=> sub { print "Modal windows can't ",
			       "handle reshape commands\n"
		       };

	initialize [qw(ModalWindow)], [qw(Accept)], $modes
		=> sub { print "Modal window $_[0]->{id} accepts!\n" };

	initialize [qw(ModalWindow)], [qw(Accept)], [qw(OffMode)]
		=> sub { print "Modal window $_[0]->{id} ",
			       "can't accept in OffMode!\n"
		       };

	initialize [qw(MovableWindow ResizableWindow)],
		   [qw(Move MoveAndResize)],
		   [qw(OnMode)]
		=> sub { print "Moving window $_[0]->{id}!\n" };

	initialize [qw(ResizableWindow)], [qw(Resize)], [qw(OnMode)]
		=> sub { print "Resizing window $_[0]->{id}!\n" };

	initialize [qw(ResizableWindow)], [qw(MoveAndResize)], [qw(OnMode)]
		=> sub { print "Moving and resizing window $_[0]->{id}!\n" };

	sub handle
	{
		my $handler = $handler{ref $_[0]}{ref $_[1]}{ref $_[2]};
		die "No handler defined for " . map {ref} @_
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
