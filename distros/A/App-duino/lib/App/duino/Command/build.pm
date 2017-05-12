package App::duino::Command::build;
{
  $App::duino::Command::build::VERSION = '0.10';
}

use strict;
use warnings;

use App::duino -command;

use Text::Template;
use File::Basename;
use File::Find::Rule;
use IPC::Cmd qw(can_run run);
use File::Path qw(make_path);

=head1 NAME

App::duino::Command::build - Build an Arduino sketch

=head1 VERSION

version 0.10

=head1 SYNOPSIS

   # this will find all *.ino, *.c and *.cpp files
   $ duino build --board uno 

   # explicitly provide the sketch file
   $ duino build --board uno some_sketch.ino

=head1 DESCRIPTION

This command can be used to build a sketch for a specific Arduino board. The
sketch file is automatically detected in the current working directory. If this
doesn't work, the path of the sketch file can be explicitly provided on the
command-line.

=cut

sub abstract { 'build an Arduino sketch' }

sub usage_desc { '%c build %o [sketch.ino]' }

sub opt_spec {
	my ($self) = @_;

	return (
		[ 'board|b=s', 'specify the board model',
			{ default => $self -> default_config('board') } ],

		[ 'libs|l=s', 'specify the Arduino libraries to build',
			{ default => $self -> default_config('libs') } ],

		[ 'sketchbook|s=s', 'specify the user sketchbook directory',
			{ default => $self -> default_config('sketchbook') } ],

		[ 'root|d=s', 'specify the Arduino installation directory',
			{ default => $self -> default_config('root') } ],

		[ 'hardware|r=s', 'specify the hardware type to build for',
			{ default => $self -> default_config('hardware') } ],
	);
}

sub execute {
	my ($self, $opt, $args) = @_;

	my $make = can_run('make') or die "Can't find command 'make'.";

	my $board_name    = $opt -> board;
	my $makefile_name = ".build/$board_name/Makefile";

	make_path(dirname $makefile_name);

	open my $makefile, '>', $makefile_name
		or die "Can't create Makefile.\n";

	my $template = Text::Template -> new(
		TYPE => 'FILEHANDLE', SOURCE => \*DATA
	);

	my ($target, @c_srcs, @cpp_srcs, @ino_srcs);

	@c_srcs   = File::Find::Rule -> file -> name('*.c') -> in('./');
	@cpp_srcs = File::Find::Rule -> file -> name('*.cpp') -> in('./');

	if ($args -> [0] and -e $args -> [0]) {
		$target = '$(notdir $(basename $(LOCAL_INO_SRCS)))';
		push @ino_srcs, $args -> [0];
	} elsif ($args -> [0]) {
		die "Can't find file '" . $args -> [0] . "'.\n";
	} else {
		$target = '$(notdir $(CURDIR))';
		@ino_srcs = File::Find::Rule -> file
				-> name('*.ino') -> in('./');
	}

	my $core = $self -> board_config($opt, 'build.core');
	my $hardware = $opt -> hardware;

	my $core_path = "$hardware/cores/$core";

	if ($core =~ /:/) {
		my ($core1, $core2) = split /:/, $core;
		$core_path = "$core1/cores/$core2";
	}

	my $makefile_opts = {
		board   => $board_name,
		variant => $self -> board_config($opt, 'build.variant'),
		mcu     => $self -> board_config($opt, 'build.mcu'),
		f_cpu   => $self -> board_config($opt, 'build.f_cpu'),
		vid     => $self -> board_config($opt, 'build.vid'),
		pid     => $self -> board_config($opt, 'build.pid'),
		core_pth=> $core_path,

		target         => $target,
		local_c_srcs   => join(' ', @c_srcs),
		local_cpp_srcs => join(' ', @cpp_srcs),
		local_ino_srcs => join(' ', @ino_srcs),

		libs       => $opt -> libs,
		root       => $opt -> root,
		sketchbook => $opt -> sketchbook,
		hardware   => $hardware,
	};

	$template -> fill_in(
		OUTPUT => $makefile, HASH => $makefile_opts
	);

	system 'make', '--silent', '-f', $makefile_name;
	die "Failed to build.\n" unless $? == 0;
}

=head1 OPTIONS

=over 4

=item B<--board>, B<-b>

The Arduino board model. The environment variable C<ARDUINO_BOARD> will be used
if present and if the command-line option is not set. If neither of them is set
the default value (C<uno>) will be used.

=item B<--libs>, B<-l>

List of space-separated, non-core Arduino libraries to build. The environment
variable C<ARDUINO_LIBS> will be used if present and if the command-line option
is not set. If neither of them is set no libraries are built.

Example:

    $ duino build --libs "Wire Wire/utility SPI"

=item B<--sketchbook>, B<-s>

The path to the user's sketchbook directory. The environment variable
C<ARDUINO_SKETCHBOOK> will be used if present and if the command-line option is
not set. If neither of them is set the default value (C<$HOME/sketchbook>) will
be used.

=item B<--root>, B<-d>

The path to the Arduino installation directory. The environment variable
C<ARDUINO_DIR> will be used if present and if the command-line option is not
set. If neither of them is set the default value (C</usr/share/arduino>) will
be used.

=item B<--hardware>, B<-r>

The "type" of hardware to target. The environment variable C<ARDUINO_HARDWARE>
will be used if present and if the command-line option is not set. If neither
of them is set the default value (C<arduino>) will be used.

This option is only useful when using MCUs not officially supported by the
Arduino platform (e.g. L<ATTiny|https://code.google.com/p/arduino-tiny/>).

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::duino::Command::build

__DATA__
# Arduino command line tools Makefile
# System part (i.e. project independent)
#
# Copyright (C) 2010,2011,2012 Martin Oldfield <m@mjo.tc>, based on
# work that is copyright Nicholas Zambetti, David A. Mellis & Hernando
# Barragan.
# 
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# Adapted from Arduino 0011 Makefile by Alessandro Ghedini

BOARD_TAG = {$board}

VARIANT   = {$variant}
MCU       = {$mcu}
F_CPU     = {$f_cpu}
USB_VID   = {$vid}
USB_PID   = {$pid}

ARDUINO_ROOT       = {$root}
ARDUINO_LIBS       = {$libs}
ARDUINO_VERSION    = 100
ARDUINO_SKETCHBOOK = {$sketchbook}

ARDUINO_LIB_PATH  = $(ARDUINO_ROOT)/libraries
ARDUINO_CORE_PATH = $(ARDUINO_ROOT)/hardware/{$core_pth}
ARDUINO_VAR_PATH  = $(ARDUINO_ROOT)/hardware/{$hardware}/variants

USER_LIB_PATH = $(ARDUINO_SKETCHBOOK)/libraries

AVR_TOOLS_DIR     = $(ARDUINO_ROOT)/hardware/tools/avr
AVR_TOOLS_PATH    = $(AVR_TOOLS_DIR)/bin

OBJDIR  = .build/$(BOARD_TAG)

LOCAL_C_SRCS    = {$local_c_srcs}
LOCAL_CPP_SRCS  = {$local_cpp_srcs}
LOCAL_INO_SRCS  = {$local_ino_srcs}

LOCAL_OBJ_FILES = $(LOCAL_C_SRCS:.c=.o) $(LOCAL_CPP_SRCS:.cpp=.o) \
		  $(LOCAL_INO_SRCS:.ino=.o)
LOCAL_OBJS      = $(addprefix $(OBJDIR)/, $(LOCAL_OBJ_FILES))

# core sources
CORE_C_SRCS     = $(wildcard $(ARDUINO_CORE_PATH)/*.c)
CORE_CPP_SRCS   = $(wildcard $(ARDUINO_CORE_PATH)/*.cpp)

ifneq ($(strip $(NO_CORE_MAIN_CPP)),)
CORE_CPP_SRCS := $(filter-out %main.cpp, $(CORE_CPP_SRCS))
endif

CORE_OBJ_FILES  = $(CORE_C_SRCS:.c=.o) $(CORE_CPP_SRCS:.cpp=.o)
CORE_OBJS       = $(patsubst $(ARDUINO_CORE_PATH)/%,  \
			$(OBJDIR)/%,$(CORE_OBJ_FILES))

########################################################################
# Rules for making stuff
#

TARGET     = {$target}

# The name of the main targets
TARGET_HEX = $(OBJDIR)/$(TARGET).hex
TARGET_ELF = $(OBJDIR)/$(TARGET).elf
TARGETS    = $(OBJDIR)/$(TARGET).*
CORE_LIB   = $(OBJDIR)/libcore.a

# Names of executables
CC      = $(AVR_TOOLS_PATH)/avr-gcc
CXX     = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
AR      = $(AVR_TOOLS_PATH)/avr-ar
CAT     = cat
ECHO    = echo
MKDIR   = mkdir -p

# General arguments
SYS_LIBS      = $(patsubst %,$(ARDUINO_LIB_PATH)/%,$(ARDUINO_LIBS))
USER_LIBS     = $(patsubst %,$(USER_LIB_PATH)/%,$(ARDUINO_LIBS))

SYS_INCLUDES  = $(patsubst %,-I%,$(SYS_LIBS))
USER_INCLUDES = $(patsubst %,-I%,$(USER_LIBS))

LIB_C_SRCS    = $(wildcard $(patsubst %,%/*.c,$(SYS_LIBS)))
LIB_CPP_SRCS  = $(wildcard $(patsubst %,%/*.cpp,$(SYS_LIBS)))

USER_LIB_CPP_SRCS = $(wildcard $(patsubst %,%/*.cpp,$(USER_LIBS)))
USER_LIB_C_SRCS   = $(wildcard $(patsubst %,%/*.c,$(USER_LIBS)))

LIB_OBJS      = $(patsubst $(ARDUINO_LIB_PATH)/%.c,$(OBJDIR)/%.o,$(LIB_C_SRCS))\
		$(patsubst $(ARDUINO_LIB_PATH)/%.cpp,$(OBJDIR)/%.o,$(LIB_CPP_SRCS))
USER_LIB_OBJS = $(patsubst $(USER_LIB_PATH)/%.cpp,$(OBJDIR)/%.o,$(USER_LIB_CPP_SRCS)) \
		$(patsubst $(USER_LIB_PATH)/%.c,$(OBJDIR)/%.o,$(USER_LIB_C_SRCS))

CPPFLAGS      = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -DARDUINO=$(ARDUINO_VERSION) \
			-I. -I$(ARDUINO_CORE_PATH) -I$(ARDUINO_VAR_PATH)/$(VARIANT) \
			$(SYS_INCLUDES) $(USER_INCLUDES) -g -Os -w -Wall \
			-DUSB_VID=$(USB_VID) -DUSB_PID=$(USB_PID) \
			-ffunction-sections -fdata-sections

CFLAGS        = -std=gnu99
CXXFLAGS      = -fno-exceptions
ASFLAGS       = -mmcu=$(MCU) -I. -x assembler-with-cpp
LDFLAGS       = -mmcu=$(MCU) -Wl,--gc-sections -Os

# library sources
$(OBJDIR)/%.o: $(ARDUINO_LIB_PATH)/%.c
	$(ECHO) 'Building $(notdir $<)'
	$(MKDIR) $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: $(ARDUINO_LIB_PATH)/%.cpp
	$(ECHO) 'Building $(notdir $<)'
	$(MKDIR) $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.o: $(USER_LIB_PATH)/%.cpp
	$(ECHO) 'Building $(notdir $<)'
	$(MKDIR) $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: $(USER_LIB_PATH)/%.c
	$(ECHO) 'Building $(notdir $<)'
	$(MKDIR) $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

# normal local sources
# .o rules are for objects, .d for dependency tracking
# there seems to be an awful lot of duplication here!!!
$(OBJDIR)/%.o: %.c
	$(ECHO) 'Building $(notdir $<)'
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: %.cpp
	$(ECHO) 'Building $(notdir $<)'
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# the ino -> cpp -> o file
$(OBJDIR)/%.cpp: %.ino
	$(ECHO) 'Building $(notdir $<)'
	$(MKDIR) $(dir $@)
	$(ECHO) '#include <Arduino.h>' > $@
	$(CAT)  $< >> $@

$(OBJDIR)/%.o: $(OBJDIR)/%.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# core files
$(OBJDIR)/%.o: $(ARDUINO_CORE_PATH)/%.c
	$(ECHO) 'Building $(notdir $<)'
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: $(ARDUINO_CORE_PATH)/%.cpp
	$(ECHO) 'Building $(notdir $<)'
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# various object conversions
$(OBJDIR)/%.hex: $(OBJDIR)/%.elf
	$(ECHO) 'Generating $(notdir $@)'
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	$(ECHO)

all: 		$(OBJDIR) $(TARGET_HEX)
	$(ECHO) 'Built! Now you can run "duino upload"'

$(OBJDIR):
		$(MKDIR) $(OBJDIR)

$(TARGET_ELF): 	$(LOCAL_OBJS) $(CORE_LIB) $(OTHER_OBJS)
		$(CC) $(LDFLAGS) -o $@ $(LOCAL_OBJS) $(CORE_LIB) $(OTHER_OBJS) -lc -lm

$(CORE_LIB):	$(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)
		$(ECHO) 'Linking $(notdir $(CORE_LIB))'
		$(AR) rcs $@ $(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)

.PHONY: all
