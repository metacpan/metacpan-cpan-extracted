# -*- mode: perl; coding: us-ascii-unix; -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2010-05-26 13:12:29 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

=pod

=head1 NAME

Acme::Cow::Interpreter - Cow programming language interpreter

=head1 SYNOPSIS

    use Acme::Cow::Interpreter;

    my $cow = Acme::Cow::Interpreter -> new();
    $cow -> parse_file($file);
    $cow -> execute();

=head1 ABSTRACT

This module implements an interpreter for the Cow programming language.

=head1 DESCRIPTION

This module implements an interpreter for the Cow programming language. The
Cow programming language is a so-called esoteric programming language, with
only 12 commands.

=cut

package Acme::Cow::Interpreter;

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable UTF-8 in source code

use Carp;

our $VERSION = '0.01';

# This hash maps each of the 12 command (used in the source code) to the
# corresponding numerical code, from 0 to 11.

my $cmd2code =
  {
   moo =>  0,
   mOo =>  1,
   moO =>  2,
   mOO =>  3,
   Moo =>  4,
   MOo =>  5,
   MoO =>  6,
   MOO =>  7,
   OOO =>  8,
   MMM =>  9,
   OOM => 10,
   oom => 11,
  };

# This array maps each of the 12 numerical codes to the corresponding
# command (used in source code).

my $code2cmd =
  [
   'moo',
   'mOo',
   'moO',
   'mOO',
   'Moo',
   'MOo',
   'MoO',
   'MOO',
   'OOO',
   'MMM',
   'OOM',
   'oom',
  ];

# This regular expression matches all the 12 valid commands.

my $cmd_regex = '(?:[Mm][Oo][Oo]|MMM|OO[MO]|oom)';

=pod

=head1 METHODS

=over 4

=item new ()

Return a new Cow interpreter.

=cut

sub new {
    my $proto    = shift;
    my $protoref = ref $proto;
    my $class    = $protoref || $proto;
    my $name     = 'new';

    # Check how the method is called.

    croak "$name() is a class method, not an instance/object method"
      if $protoref;

    # The new self.

    my $self = {};

    # Bless the reference into an object.

    bless $self, $class;

    # Initialize it.  The return value of init() is the object itself.

    $self -> init();
}

=pod

=item init ()

Initialize an object instance. Clears the memory and register and sets the
memory pointer to zero. Also, the internally stored program source is
cleared.

=cut

sub init {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'init';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    $self -> {prog}     = [];            # program; array of codes
    $self -> {mem}      = [0];           # memory
    $self -> {reg}      = undef;         # register
    $self -> {prog_pos} = 0;             # index of current program code
    $self -> {mem_pos}  = 0;             # index of current memory block

    return $self;
}

=pod

=item copy ()

Copy (clone) an Acme::Cow::Interpreter object.

=cut

sub copy {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'copy';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    my $copy = {};
    for my $key (keys %$self) {
        my $ref = ref $self -> {$key};
        if ($ref eq 'ARRAY') {
            @{ $copy -> {$key} } = @{ $self -> {$key} };
        } else {
            $copy -> {$key} = $self -> {$key};
        }
    }

    # Bless the copy into an object.

    bless $copy, $class;
}

=pod

=item parse_string ( STRING )

Parses the given string and stores the resulting list of codes in the
object.  The return value is the object itself.

=cut

sub parse_string {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'parse_string';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    croak "$name(): Not enough input arguments" if @_ < 1;
    croak "$name(): Too many input arguments"   if @_ > 1;

    # There is no way the parser can fail. The worst thing that could happen
    # is that there are no commands in the string.

    my $string = shift; croak "$name(): Input argument is undefined"
      unless defined $string;

    # Reset, i.e., initialize, the invocand object.

    $self -> init();

    # Find the string commands, and convert them to numerical codes.

    $self -> {prog} = [
                        map { $cmd2code -> {$_} }
                          $string =~ /($cmd_regex)/go
                      ];

    return $self;
}

=pod

=item parse_file ( FILENAME )

Parses the contents of the given file and stores the resulting list of codes
in the object. The return value is the object itself.

=cut

sub parse_file {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'parse_file';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    croak "$name(): Not enough input arguments" if @_ < 1;
    croak "$name(): Too many input arguments"   if @_ > 1;

    # Reset, i.e., initialize, the invocand object.

    $self -> init();

    # Get the file name argument.

    my $file = shift;

    open FILE, $file or croak "$file: can't open file for reading: $!";

    # Iterate over each line, find the string commands, and convert them to
    # numerical codes.

    while (<FILE>) {
        push @{ $self -> {prog} },
          map { $cmd2code -> {$_} }
            /($cmd_regex)/go;
    }

    close FILE or croak "$file: can't close file after reading: $!";

    return $self;
}

=pod

=item dump_mem ( )

Returns a nicely formatted string showing the current memory state.

=cut

sub dump_mem {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'dump_mem';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    my $mem     = $self -> {mem};
    my $mem_pos = $self -> {mem_pos};
    my $reg     = $self -> {reg};

    my $str = '';

    # Print the contents of the memory, showing the block which the memory
    # points at.

    for (my $i = $#$mem ; $i >= 0 ; -- $i) {
        $str .= sprintf "Memory block %6u: %12d", $i, $mem->[$i];
        if ($i == $mem_pos) {
            $str .= " <<<";
        }
        $str .= "\n";
    }

    # Print the contents of the register.

    $str .= "\n";
    $str .= sprintf "Register block: %17s", defined $reg ? $reg : '<undef>';
    $str .= "\n";

    return $str;
}

=pod

=item dump_obj ( )

Returns a text version of object structure.

=cut

sub dump_obj {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'dump';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    my $prog     = $self -> {prog};
    my $mem      = $self -> {mem};
    my $reg      = $self -> {reg};
    my $prog_pos = $self -> {prog_pos};
    my $mem_pos  = $self -> {mem_pos};

    my $str;

    $str .= '$obj -> {prog}     = [';
    $str .= join(', ', @$prog);
    $str .= "];\n";

    $str .= '$obj -> {prog_pos} = ';
    $str .= $prog_pos;
    $str .= ";\n";

    $str .= '$obj -> {mem}      = [';
    $str .= join(', ', @$mem);
    $str .= "];\n";

    $str .= '$obj -> {mem_pos}  = ';
    $str .= $mem_pos;
    $str .= ";\n";
    $str .= '$obj -> {reg}      = ';
    $str .= defined $reg ? $reg : '<undef>';
    $str .= ";\n";

    return $str;
}

=pod

=item execute ( )

Executes the source code. The return value is the object itself.

=cut

sub execute {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'execute';

    # Check how the method is called.

    croak "$name() is an instance/object method, not a class method"
      unless $selfref;

    # Check number of arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    # These variables are merely for convenience. They make the code below a
    # bit cleaner.

    my $prog     =  $self -> {prog};
    my $mem      =  $self -> {mem};
    my $prog_pos = \$self -> {prog_pos};
    my $mem_pos  = \$self -> {mem_pos};
    my $reg      = \$self -> {reg};

    # Quick exit if there are no commands (program is void).

    return 1 unless @$prog;

    # The code to be executed.

    my $code = $prog -> [$$prog_pos];

    # Main loop. Each round executes one instruction.

    {

        #print "-" x 72, "\n";
        #print "prog ...:";
        #printf " %3s", $code2cmd -> [$_] for @$prog;
        #print "\n";
        #print "ppos ...:", "    " x $$prog_pos, " ^^^\n";
        ##print "ppos ...: $$prog_pos\n";
        #print "code ...: $code ($code2cmd -> [$code])\n";
        #print "\n";
        #print "mem ....:";
        #printf " %4d", $_ for @$mem;
        #print "\n";
        #print "mpos ...:", "     " x $$mem_pos, " ^^^^\n";
        #print "reg ....: ", defined $$reg ? $$reg : "", "\n";
        #<STDIN>;

        # Code: moo

        if ($code == 0) {

            # Remember where we started searching for matching 'MOO'.

            my $init_pos = $$prog_pos;

            # Skip previous instruction when looking for matching 'MOO'.

            $$prog_pos --;

            my $level = 1;
            while ($level > 0) {

                if ($$prog_pos == 0) {
                    croak "No previous 'MOO' command matching 'moo'",
                      " command. Failed at instruction number $init_pos.";
                    #last;
                    #return 0;
                }

                $$prog_pos --;

                if ($prog -> [$$prog_pos] == 0) {             # if "moo"
                    $level ++;
                } elsif ($prog -> [$$prog_pos] == 7) {        # if "MOO"
                    $level --;
                }
            }

            # This if-test is necessary if we use 'last' rather than 'croak'
            # in the if-test inside the while-loop above.
            #
            #if ($level != 0) {
            #    croak "No previous 'MOO' command matching 'moo'",
            #      " command (instruction number $init_pos).";
            #}

            $code = $prog -> [$$prog_pos];

        }

        # Code: mOo

        elsif ($code == 1) {

            if ($$mem_pos == 0) {
                croak "Can't move memory pointer behind memory block 0.",
                  " Failed at command number $$prog_pos.";
            }
            $$mem_pos --;

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: moO

        elsif ($code == 2) {

            $$mem_pos ++;
            if ($$mem_pos > $#$mem) {
                push @$mem, 0;
            }

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: mOO

        elsif ($code == 3) {

            if ($mem -> [$$mem_pos] == 3) {
                croak "Invalid instruction at this point (would cause",
                  " infinite loop). Failed at instruction number $$prog_pos.";
            }

            # We don't need to check for any other invalid instruction
            # (which exits the program), since this will be taken care of in
            # the next round.

            $code = $mem -> [$$mem_pos];

        }

        # Code: Moo

        elsif ($code == 4) {

            if ($mem -> [$$mem_pos] == 0) {
                my $chr;
                read(STDIN, $chr, 1);
                $mem -> [$$mem_pos] = ord($chr);
            } else {
                printf "%c", $mem -> [$$mem_pos];
            }

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: MOo

        elsif ($code == 5) {

            $mem -> [$$mem_pos] --;

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: MoO

        elsif ($code == 6) {

            $mem -> [$$mem_pos] ++;

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: MOO

        elsif ($code == 7) {

            if ($mem -> [$$mem_pos] == 0) {

                # Remember where we started searching for matching 'moo'.

                my $init_pos = $$prog_pos;

                # Skip next instruction when looking for matching 'moo'.

                $$prog_pos ++;

                my $level = 1;
                my $prev_code;

                while ($level > 0) {

                    if ($$prog_pos == $#$prog) {
                        croak "No following 'moo' command matching 'MOO'",
                          " command. Failed at instruction number $init_pos.";
                    }

                    $prev_code = $prog -> [$$prog_pos];
                    $$prog_pos ++;

                    if ($prog -> [$$prog_pos] == 7) {         # if "MOO"
                        $level ++;
                    } elsif ($prog -> [$$prog_pos] == 0) {    # if "moo"
                        $level --;
                        if ($prev_code == 7) {
                            $level --;
                        }
                    }
                }

                # This if-test is necessary if we use 'last' rather than
                # 'croak' in the if-test inside the while-loop above.
                #
                #if ($level != 0 ) {
                #    croak "No following 'moo' command matching 'MOO'",
                #      " command. Failed at instruction number $init_pos.";
                #}

                last if $$prog_pos == $#$prog;
                $$prog_pos ++;
                $code = $prog -> [$$prog_pos];

            } else {

                last if $$prog_pos == $#$prog;
                $$prog_pos ++;
                $code = $prog -> [$$prog_pos];

            }

        }

        # Code: OOO

        elsif ($code == 8) {

            $mem -> [$$mem_pos] = 0;

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: MMM

        elsif ($code == 9) {

            if (defined $$reg) {
                $mem -> [$$mem_pos] = $$reg;
                $$reg = undef;
            } else {
                $$reg = $mem -> [$$mem_pos];
            }

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: OOM

        elsif ($code == 10) {

            printf "%d\n", $mem -> [$$mem_pos];

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # Code: oom

        elsif ($code == 11) {

            my $input = <STDIN>;
            croak "Input was undefined\n"
              unless defined $input;
            $input =~ s/^\s+//;
            $input =~ s/\s+$//;
            croak "Input was not an integer -- $input\n"
              unless $input =~ /^[+-]?\d+/;

            $mem -> [$$mem_pos] = $input;

            last if $$prog_pos == $#$prog;
            $$prog_pos ++;
            $code = $prog -> [$$prog_pos];

        }

        # An invalid instruction exits the running program.

        else {
            return 1;
        }

        redo;
    }

    return $self;
}

=pod

=back

=head1 NOTES

=head2 The Cow Language

The Cow language has 12 instruction. The commands and their corresponding
code numbers are:

=over 4

=item moo (0)

This command is connected to the B<MOO> command. When encountered during
normal execution, it searches the program code in reverse looking for a
matching B<MOO> command and begins executing again starting from the found
B<MOO> command. When searching, it skips the command that is immediately
before it (see B<MOO>).

=item mOo (1)

Moves current memory position back one block.

=item moO (2)

Moves current memory position forward one block.

=item mOO (3)

Execute value in current memory block as if it were an instruction. The
command executed is based on the instruction code value (for example, if the
current memory block contains a 2, then the B<moO> command is executed). An
invalid command exits the running program. Value 3 is invalid as it would
cause an infinite loop.

=item Moo (4)

If current memory block has a 0 in it, read a single ASCII character from
the standard input and store it in the current memory block. If the current
memory block is not 0, then print the ASCII character that corresponds to
the value in the current memory block to the standard output.

=item MOo (5)

Decrement current memory block value by 1.

=item MoO (6)

Increment current memory block value by 1.

=item MOO (7)

If current memory block value is 0, skip next command and resume execution
after the next matching B<moo> command. If current memory block value is not
0, then continue with next command. Note that the fact that it skips the
command immediately following it has interesting ramifications for where the
matching B<moo> command really is. For example, the following will match the
second and not the first B<moo>: B<OOO> B<MOO> B<moo> B<moo>

=item OOO (8)

Set current memory block value to 0.

=item MMM (9)

If no current value in register, copy current memory block value. If there
is a value in the register, then paste that value into the current memory
block and clear the register.

=item OOM (10)

Print value of current memory block to the standard output as an integer.

=item oom (11)

Read an integer from the standard input and put it into the current memory
block.

=back

=head1 TODO

Add more tests. The module is far from being tested thoroughly.

=head1 BUGS

There are currently no known bugs.

Please report any bugs or feature requests to
C<bug-acme-cow-interpreter at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Acme-Cow-Interpreter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Acme::Cow::Interpreter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Cow-Interpreter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Cow-Interpreter>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Cow-Interpreter>

=item * CPAN Testers PASS Matrix

L<http://pass.cpantesters.org/distro/A/Acme-Cow-Interpreter.html>

=item * CPAN Testers Reports

L<http://www.cpantesters.org/distro/A/Acme-Cow-Interpreter.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Acme-Cow-Interpreter>

=back

=head1 REFERENCES

=over 4

=item * L<http://www.bigzaphod.org/cow/>

=back

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam@online.noE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Peter John Acklam.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
