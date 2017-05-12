# (X)Emacs mode: -*- cperl -*-

package test2;

=head1 NAME

test2 - tools for helping in test suites, including running external programs.

=head1 SYNOPSIS

  use FindBin               1.42 qw( $Bin );
  use Test                  1.13 qw( ok plan );

  BEGIN { unshift @INC, $Bin };

  use test                   qw( DATA_DIR
                                 evcheck );
  use test2                  qw( runcheck );

  BEGIN {
    plan tests  => 3,
         todo   => [],
         ;
  }

  {
    my $outcount = 1;
    my ($out, $err) = '';
    my $teststring = "\n__FOO__\n\n";
    ok runcheck
        ( [[':psreplace',
            -v => 'TEST=Cholet', -D => 'TEST', ],
           '<', \$teststring,
           '>', \$out, '2>', \$err],
          "psreplace -D",
          \$err,
        ), 1, 'runcheck -D';
    ok $out, "\nCholet\n\n", 'outputcheck -D';
  }

  ok evcheck(sub {
               open my $fh, '>', 'foo';
               print $fh "$_\n"
                 for 'Bulgaria', 'Cholet';
               close $fh;
             }, 'write foo'), 1, 'write foo';

  save_output('stderr', *STDERR{IO});
  warn 'Hello, Mum!';
  print restore_output('stderr');

=head1 DESCRIPTION

This package provides tests to help run external programs; if you do not need this
facility, you can use C<test.pm> by itself.

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

use 5.00503;
use strict;
use vars qw( @EXPORT_OK );

# Inheritance -------------------------

use base qw( Exporter );

=head2 EXPORTS

The following symbols are exported upon request:

=over 4

=item runcheck

=item simple_run_test

=back

=cut

@EXPORT_OK = qw( runcheck simple_run_test );

# Utility -----------------------------

use Carp                          qw( carp croak );
use Data::Dumper            2.101 qw( );
use Fatal                    1.02 qw( close open seek sysopen unlink );
use Fcntl                    1.03 qw( :DEFAULT );
use File::Basename            2.6 qw( basename );
use File::Spec                0.6 qw( );
use IO::File              1.06021 qw( );
use POSIX                    1.02 qw( :sys_wait_h );
use Test                    1.122 qw( ok );

use test                          qw( BIN_DIR REF_DIR compare only_files );

# ----------------------------------------------------------------------------

sub catdir {
  File::Spec->catdir(@_);
}

sub catfile {
  File::Spec->catfile(@_);
}

sub updir {
  File::Spec->updir(@_);
}

# -------------------------------------
# PACKAGE CONSTANTS
# -------------------------------------

use constant DEBUG => 0;

# -------------------------------------
# PACKAGE ACTIONS
# -------------------------------------

my $ipc_run = 1;
sub import {
  my $class = shift;
  my (@bad_names, @export_symbols);
  my %export_ok = map {; $_ => 1 } @EXPORT_OK;
  for (@_) {
    if ( $_ eq '-no-ipc-run' ) {
      $ipc_run = 0;
    } elsif ( exists $export_ok{$_} ) {
      push @export_symbols, $_;
    } else {
      push @bad_names, $_;
    }
  }

  croak ("Arguments to " . __PACKAGE__ .
         " import  not recognized: ",
         join (', ', @bad_names), "\n")
    if @bad_names;

  $class->export_to_level(2, $class, @export_symbols);

  if ( $ipc_run ) {
    eval "use IPC::Run 0.44 qw( harness run );";
    croak "use IPC::Run failed: $@\n"
      if $@;
  } else {
    eval "use IO::Pipe 1.090 qw( );";
    croak "use IO::Pipe failed: $@\n"
      if $@;
    eval "use IO::Select 1.10 qw( );";
    croak "use IO::Select failed: $@\n"
      if $@;
  }
}

# -------------------------------------
# PACKAGE FUNCTIONS
# -------------------------------------

=head2 runcheck

Run an external command, check the results.

=over 4

=item ARGUMENTS

=over 4

=item runargs

An arrayref of arguments as for L<IPC::Run/run>, excepting that array ref
arguments with an initial C<:> character on the first member will be
considered as perl scripts in the module built to run.

For example, an invocation of

  runcheck([[':reverse'], '<', '/etc/passwd'], "bob", \$err);

will convert the initial reverse to treat it as a perl script called
F<reverse> to find in the module, and execute that with the current running
perl.  The remaining arguments are left as is.

=item name

The name of the program to refer to in error messages

=item errref

Reference to a scalar to read in case of error.  Normally, this is bound to a
scalar where is deposited the stderr out of the command, using arguments

  '2>', $err

in L</runargs>.

=item exitcode

I<Optional>.  If defined, the exitcode to expect from the run program.
Defaults to zero.

=back

=item RETURNS

=over 4

=item success

1 if the command executed without failure; false otherwise.

=back

=back

=cut

sub runcheck {
  my ($runargs, $name, $errref, $exitcode) = @_;

  $exitcode ||= 0;

  my @args = map({ ( ref $_ eq 'ARRAY' and substr($_->[0],0,1) eq ':') ?
                     [ $^X, catfile(BIN_DIR, substr($_->[0],1)),
                       @{$_}[1..$#$_] ]                                :
                     $_ }
                 @$runargs);

  print STDERR Data::Dumper->new([\@args],[qw(args)])->Indent(0)->Dump, "\n"
    if defined $ENV{TEST_DEBUG} and $ENV{TEST_DEBUG} > 1;
  my $rv = $ipc_run ? _ipc_run(@args) : _nonipc_run(@args);

  if ( $rv >> 8 != $exitcode ) {
    if ( $ENV{TEST_DEBUG} ) {
      print STDERR
        sprintf("$name failed (expected %d) : exit/sig/core %d/%d/%d\n",
                $exitcode, $rv >> 8, $rv & 127, ( $rv & 128 ) >> 7);
      print STDERR
        "  $$errref\n"
          if defined $errref and defined $$errref and $$errref !~ /^\s*$/;
    }
    return;
  } else {
    return 1;
  }
}

sub _ipc_run {
  my @args = @_;
  my $harness = harness(@args);
  run $harness;
  return $harness->full_result;
}

sub _nonipc_run {
  my @args = @_;
  croak "Non-IPC::Run only handles single commands\n"
    for grep UNIVERSAL::isa($_, 'ARRAY'), @args[1..$#args];
  croak "Non-IPC::Run requires first argument is an arrayref\n"
    unless UNIVERSAL::isa($args[0], 'ARRAY');
  croak "Non-IPC::Run only handles 'n<>', \\\$foo pairs of redirects\n"
    unless @args % 2; # 1 for cmd, n*2 for pairs

  my ($cmd, %redirects) = @args;
  my @names;

  my (@redirects, @values);
  while ( my ($redirect, $value) = each %redirects ) {
    if ( my ($num, $direction) = ($redirect =~ /^(\d*)([<>])$/) ) {
      unless ( length $num ) {
        $num = $redirect eq '<' ? 0 : 1;
      }

      croak "Multiple redirects for fd $num\n"
        if defined $redirects[$num];

      $redirects[$num] = $direction;
      if ( UNIVERSAL::isa($value, 'SCALAR') ) {
        $values[$num]    = $value;
      } elsif ( ! ref $value ) {
        my $flags = $direction eq '<' ? O_RDONLY : O_WRONLY | O_CREAT;
        {
          $values[$num] = IO::File->new($value, $flags)
            or croak "Couldn't open $value ($direction): $!\n";# \*FOO;
          $names[$num]  = "$direction $value";
        }
      } else {
        croak "Couldn't understand value for fd $num: -->$value<--\n";
      }
    } else {
      croak "Didna understand redirect: $redirect\n";
    }
  }

  my @pipes = map defined $_ ? IO::Pipe->new : undef, @redirects;

  my $kidstatus;
  local $SIG{CHLD} = local $SIG{PIPE} =
    sub {
      my ($sig) = @_;
      my $pid = waitpid(-1,WNOHANG);
      $kidstatus = $?;
    };
  my $pid = fork;
  croak "fork failed: $!\n"
    unless defined $pid;

  unless ( $pid ) {      # Child
    select(undef, undef, undef, 0.1); # Yield to papa
    my @fhs = ( *STDIN{IO}, *STDOUT{IO}, *STDERR{IO} );

    for my $fd (grep defined $redirects[$_], 0..$#redirects) {
      croak "Don't know how to redirect fd #$fd\n"
        unless defined $fhs[$fd];
      my ($pipe, $redirect, $fh) = ($pipes[$fd], $redirects[$fd], $fhs[$fd]);
      if ( $redirect eq '<' ) {
        $pipe->reader;
        open $fh, '<&' . $pipe->fileno;
      } elsif ( $redirect eq '>' ) {
        $pipe->writer;
        open $fh, '>&' . $pipe->fileno;
      } else {
        croak "Internal error: redirect $fd should not be -->$redirect<--\n";
      }
    }

    exec @$cmd;
    die join(' ', @$cmd), " failed to exec: $!\n";
  }

  # Parent
  my $selector = IO::Select->new;

  for my $fd (grep defined $redirects[$_], 0..$#redirects) {
    my ($pipe, $redirect) = ($pipes[$fd], $redirects[$fd]);
    if ( $redirect eq '<' ) {
      $pipe->writer;
    } elsif ( $redirect eq '>' ) {
      $pipe->reader;
    } else {
      croak "Internal Error: redirect $fd should not be -->$redirect<--\n";
    }
    $selector->add($pipe);
  }

  my $pipe_no =
    sub {
      my ($pipe) = @_;
      for(0..$#redirects) {
        return $_
          if defined $pipes[$_] and $pipe == $pipes[$_];
      }

      return;
    };

  my @writepos = (0) x @pipes;
  my $did_something = 0;
 SELECT:
  while (
         $selector->count ) {
    printf STDERR "Selecting reads from choice of %d...\n", $selector->count
      if DEBUG;
    $did_something--;
    my @can_read = grep($redirects[$_] eq '>',
                        map $pipe_no->($_),
                        $selector->can_read(0));

    if ( @can_read ) {
      $did_something = 2;
      for (@can_read) {
        my $value = $values[$_];
        my ($readref, $writeref);
        if ( UNIVERSAL::isa($value, 'SCALAR') ) {
          $readref = $value;
        } elsif ( UNIVERSAL::isa($value, 'GLOB') ) {
          my $buffy = '';
          $readref = \$buffy;
          $writeref = $value;
        } else {
          croak sprintf("Internal Error: Can't handle value: %s\n",
                        ref $value || 'simple value');
        }

        my $offset = defined $$readref ? length $$readref : 0;
        printf STDERR "Reading from fd $_\n"
          if DEBUG;
        my $readcount =
          sysread($pipes[$_], $$readref, 8196, $offset);
        printf STDERR "Read %d bytes from fd %d: -->%s<--\n",
                      $readcount, $_, substr($$readref,$offset)
          if DEBUG;

        if ( $readcount ) {
          if ( defined $writeref ) {
            my $written = syswrite($writeref, $$readref);
            croak
              sprintf
                ("Couldn't write all bytes to output for fd %d " .
                 "(%s) (%d/%d): $!\n",
                 $_, $names[$_], $written, length $$readref)
                unless $written == length $$readref;
          }
        } else {
          $selector->remove($pipes[$_]);
        }
      }
    } elsif ( $kidstatus ) {
      # Take an early bath --- but only if reading is done (so we can collect 
      # up any output so far e.g., for diagnostic assistance
      last SELECT;
    } else {
      printf STDERR "Selecting write from choice of %d...\n",
                    $selector->count
        if DEBUG;
      my @can_write = grep($redirects[$_] eq '<',
                           map $pipe_no->($_),
                           $selector->can_write(0));
      if ( @can_write && ! $kidstatus ) {
        $did_something = 2;
        for (@can_write) {
          printf STDERR "Writing to fd %d\n", $_
            if DEBUG;
          my $value = $values[$_];
          my $buffy;
          my $buffy_afterlife = 0;

          if ( UNIVERSAL::isa($value, 'SCALAR') ) {
            printf STDERR ("Using string value -->%s<-- for writing to fd%d\n",
                           $$value, $_)
              if DEBUG;
            $buffy = $value;
          } elsif ( UNIVERSAL::isa($value, 'GLOB') ) {
            local $/ = "\n";
            my $dawn = <$value>;
            printf STDERR
              ("Using line -->%s<-- (from %s) for writing to fd %d\n",
               $dawn, $names[$_], $_)
              if DEBUG;
            $buffy = \$dawn;
            $writepos[$_] = 0;
            $buffy_afterlife = 1
              unless eof $value;
          } else {
            croak sprintf("Internal error: Can't handle value: %s\n",
                          ref $value || sprintf('simple value: -->%s<--',
                                                defined $value ?
                                                $value : '*undef*'));
          }

          if ( defined $$buffy and length $$buffy ) {
            # This writing in lines and the above reading in lines (if $value
            # is a GLOB are symbiotic.  If either changes without handling the
            # other, then data will be lost.
            my $line_end = index $$buffy, "\n", $writepos[$_];
            if ( $line_end > -1 ) {
              # Index found, but we want the length up to the end of the next
              # line
              $line_end++;
            } else {
              $line_end = length $$buffy
            }
            my $writebytes = $line_end - $writepos[$_];

            printf STDERR "Writing to fd $_\n"
              if DEBUG;

            {
              local $SIG{ALRM} =
                sub {
                  die
                    sprintf("Timed out writing to file handle $_\n  -->%s<--",
                            substr($$buffy,
                                   $writepos[$_],
                                   $writebytes));
                };
              alarm 5;
              my $writecount = syswrite($pipes[$_],
                                        $$buffy,
                                        $writebytes,
                                        $writepos[$_]);
              alarm 0;

# Incomplete writes should be okay on refs, but not on filerefs (since we just
# read in the next line to write next time 'round)
croak
sprintf("Incomplete write (wrote %d bytes, should've been %d) on fd %d\n",
        $writecount, $writebytes, $_)
  unless $writecount == $writebytes;

              printf STDERR "Wrote %d bytes to fd %d: -->%s<--\n",
                $writecount, $_, substr($$buffy,
                                        $writepos[$_],
                                        $writebytes)
                  if DEBUG;
              $writepos[$_] += $writecount;
            }

            if ( $writepos[$_] == length $$buffy and ! $buffy_afterlife ) {
              printf STDERR "Closing write pipe %d (finished writing)\n", $_
                if DEBUG;
              $selector->remove($pipes[$_]);
              $pipes[$_]->close;
            }
            croak sprintf("Overwrite on fd $_: wrote %d, length %d\n",
                          $writepos[$_], length $$buffy)
              if $writepos[$_] > length $$buffy;
          } else {
            printf STDERR "Closing write pipe %d (nothing more to write)\n", $_
              if DEBUG;
            $selector->remove($pipes[$_]);
            $pipes[$_]->close;
          }
        }
      } else {
        unless ( $did_something > 0 ) {
#          print STDERR ("Sleeping...\n");
#          select(undef, undef, undef, 0.1);
        }
      }
    }
  }

  if ( ! defined $kidstatus ) {
    # Log::Info tests (trap.t) on Solaris fail with WNOHANG --- the child 
    # process seems to hang around for a shade longer that one might expect
    my $waitpid = waitpid $pid, 0; #WNOHANG;
    my $kidstatus = $?;
  }
  return $kidstatus;
}

# -------------------------------------

=head2 simple_run_test

This is designed to simplify the job of running a program, and testing the
output.  It performs 2+n tests; that the command executed without error, that
the n files named in the C<checkfiles> argument are each as expected, and that
no other files exist.

All files in the current directory are wiped after the test in preparation for
the next test.

=over 4

=item ARGUMENTS

The arguments are considered as name/value pairs.

=over 4to
L<runcheck|/runcheck>.

=item runargs

B<Mandatory>.  This is an arrayref; as for the runargs argument to
L<runcheck|/runcheck>.

=item name

B<Mandatory>.  The name to use in error messages.

=item checkfiles

This is an arrayref of files to check.  The named files are considered
relative to the working directory, and are checked against files taken
relative to the F<testref> directory of the build.  Therefore, absolute file
names are non-sensical, and will raise an exception.

=item errref

A ref to a scalar potentially containing any error output.  Typically, the
stderr of the command run is redirected to this by the runargs argument.

=item testref_subdir

A subdirectory of the testref directory in which to find the files to check
against.

=item exitcode

The exit code to expect from the program run.  Defaults to 0.  Obviously.

=back

=item RETURNS

I<None>

However, 2+n tests are performed, with ok/not ok sent to stdout.

=back

=cut

sub simple_run_test {
  my (%arg) = @_;

  die sprintf("%s: missing mandatory argument: %s\n", (caller(0))[3], $_)
    for grep ! exists $arg{$_}, qw( runargs name );

  ${$arg{errref}} = ''
    if exists $arg{errref};
  $arg{exitcode} = 0
    unless exists $arg{exitcode};
  my $runok = runcheck(@arg{qw(runargs name errref exitcode)});

  ok $runok, 1, $arg{name};

  my $ref_dir = (exists $arg{testref_subdir}           ?
                 catdir(REF_DIR, $arg{testref_subdir}) :
                 REF_DIR);

  if ( exists $arg{checkfiles} ) {
    for (@{$arg{checkfiles}}) {
      my $target = catfile($ref_dir, basename $_);
      if ( -e $target ) {
        ok compare($_, $target), 1, "$arg{name}: check file $_";
      } else {
        ok 0, 1, "$arg{name}: missing reference file $target";
      }
    }
  }

  ok(only_files($arg{checkfiles}), 1, "$arg{name}: no extra files");
  # Clean up files for next test.
  local *MYDIR;
  opendir MYDIR, '.';
  unlink $_
    for grep !/^\.\.?$/, readdir MYDIR;
  closedir MYDIR;
}

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2001, 2002 Martyn J. Pearce.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
