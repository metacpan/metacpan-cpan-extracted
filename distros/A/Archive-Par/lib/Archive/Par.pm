# (X)Emacs mode: -*- cperl -*-

package Archive::Par;

=head1 NAME

Archive::Par - use & manipulate par files

=head1 SYNOPSIS

  use Archive::Par qw( $PACKAGE $VERSION );

=head1 DESCRIPTION

Z<>

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

require 5.005_62;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );
our @EXPORT_OK = qw( $PACKAGE $VERSION );

# Utility -----------------------------

use Carp                       qw( carp croak );
use Class::MethodMaker    1.02 qw( );
use Fatal                 1.02 qw( :void close open seek sysopen );
use File::Basename         2.6 qw( dirname );
use File::Spec::Functions      qw( catfile );
use IPC::Run              0.44 qw( harness run );
use Log::Info             1.03 qw( :DEFAULT :log_levels :default_channels );

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

=head1 CLASS CONSTANTS

Z<>

=cut

# Bits used in status bitmask

# File statuses:
#                      FOUND RESTORABLE CORRUPT OK
# OK                   x                        x
# Moved                x
# Corrupt   (Recover)  x     x          x
# Corrupt   (Buggered) x                x
# Not Found (Recover)        x
# Not Found (Buggered)

use constant FILE_FOUND      => 1;
use constant FILE_RESTORABLE => 2;
use constant FILE_CORRUPT    => 4;
use constant FILE_OK         => 8;

# -------------------------------------

our $PACKAGE = 'Archive-Par';
our $VERSION = '1.01';

# -------------------------------------
# CLASS CONSTRUCTION
# -------------------------------------

# -------------------------------------
# CLASS COMPONENTS
# -------------------------------------

=head1 CLASS COMPONENTS

Z<>

=cut

# -------------------------------------
# CLASS HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 CLASS HIGHER-LEVEL FUNCTIONS

Z<>

=cut

## _parse_par_output
#
# Args:
#  -) text
#     Text to parse
#  -) fn
#     Name of file submitted to par (for sanity checking).
#
# Returns:
#  -) status
#     hashref from file name to status
#  -) file_name
#     hashref from file name, as it should be as per par, to file found
#  -) bad_old_files
#     Where new files have been created containing bad data (e.g., old corrupt
#     files being moved out of the way), these files are enumerated here.

sub _parse_par_output {
  my $class = shift;
  my ($text, $fn) = @_;

  my @lines = split /\n/, $text;

  my $lineno = 0;
  croak sprintf("Bad start format on par line %d:\n-->%s<--\n" .
                "Expected:\n-->%s<--\n",
                $lineno, $lines[$lineno], "Checking $fn")
    unless $lines[$lineno] eq "Checking $fn";
  $lineno++;

  my (%status, %file_name, @bad_old_files);

 LINE:
  for ( ; substr($lines[$lineno], 0, 2) eq '  '; $lineno++ ) {
    my ($file, $found, $foundfile);

    if ( ($file, $found, $foundfile) =
         ($lines[$lineno] =~
            /^  (.{40,}) - (OK|NOT FOUND|CORRUPT|FOUND: (.*))$/) ) {
      # Corrupt files are handled by ERROR: RE below
      next LINE
        if $found eq 'CORRUPT';

      $file =~ s! +$!!;

      if ( $found eq 'OK' ) {
        $status{$file} = FILE_FOUND | FILE_OK;
      } elsif ( substr($found, 0, 5) eq 'FOUND' ) {
        # If file is already marked with a status, let the presence of
        # file_name be the only marker of finding it elsewhere
        $status{$file} = FILE_FOUND
          unless exists $status{$file};
        $file_name{$file} = $foundfile;
      } else {
        $status{$file} = 0;
      }
    } elsif ( ($file) =
              ($lines[$lineno] =~ /^ {6}ERROR: (.*): Failed md5 sum$/) ) {
      $status{$file} = FILE_FOUND | FILE_CORRUPT;
    } elsif ( my ($from, $to) =
              ($lines[$lineno] =~ /^ {4}Rename: (.*) -> (.*)$/) ) {
      if ( exists $file_name{$to} ) {
        if ( $file_name{$to} eq $from ) { # If $to is real name (as per par)
                                          # of from file, all is well
          delete $file_name{$to};
          $status{$to} = FILE_FOUND | FILE_OK;
        } else { # Else we know nothing about the incoming file.  Eek!
          croak("Nothing known about incoming file: $from (renaming to $to):" .
                "\n$lines[$lineno]\n");
        }
      } elsif ( exists $status{$from} ) {
        if ( $status{$from} & FILE_CORRUPT ) {
        # If file is corrupt, we're moving it to make way
          $status{$from} = FILE_RESTORABLE;
          push @bad_old_files, $to;
        } else { # Else file is not corrupt; why are we moving it?
          croak("Par is moving file $from to $to; I don't understand why..." .
                "\n$lines[$lineno]\n");
        }
      } else {
        croak("Par is moving file $from to $to; I know not why..." .
              "\n$lines[$lineno]\n");
      }
    } else {
      croak
        sprintf("Don't know how to handle this (on par line %d):\n  %s\n",
                $lineno, $lines[$lineno]);
    }
  }

  if ( $lines[$lineno] eq '' ) {
    # Break into list of PXX volumes and file statuses
    # Getting here is indication of a problem (of the order of a missing or
    # broken source file).
    $lineno++;

    croak "Bad looking format on par c line $lineno: $lines[$lineno]\n"
      unless $lines[$lineno] eq 'Looking for PXX volumes:';
    $lineno++;

#    for ( ; substr($lines[$lineno], 0, 2) eq '  '; $lineno++ ) {
    for ( ; $lines[$lineno] ne ''; $lineno++ ) {
      if ( my ($file) =
           ( $lines[$lineno] =~ /^  (.{40,}) - (OK)$/) ) {
        $file =~ s! +$!!;
        # push @volumes, $file;
      } elsif ( $lines[$lineno] =~ /^(.*)$/ ) {
      } else {
        Log(CHAN_DEBUG, LOG_INFO, "Ignoring line: $lines[$lineno]");
      }
    }

    croak "Bad format on par line $lineno: $lines[$lineno]\n"
      unless $lines[$lineno] eq '';
    $lineno++;

    if ( $lines[$lineno] eq 'Restorable:' ) {
      $lineno++;
      while ( $lineno <= $#lines and
              my ($file) =
              ($lines[$lineno] =~ /^  (.{40,}) - (can be restored)$/) ) {
        $file =~ s! +$!!;
        $status{$file} |= FILE_RESTORABLE;
        $lineno++;
      }
    } elsif ( $lines[$lineno] eq 'Too many missing files:' ) {
      $lineno++;
      while ( $lineno <= $#lines and
              my ($file) =
              ($lines[$lineno] =~ /^ (.*)$/) ) {
        $file =~ s! +$!!;
        $lineno++;
      }
    } elsif ( $lines[$lineno] eq 'Restoring:' ) {
      $lineno++;
      $lineno++
        if $lines[$lineno] eq '0%100%';
    RECOVER_LINE:
      while ( $lineno <= $#lines ) {
        if ( my ($file, $status) =
             ($lines[$lineno] =~ /^  (.{40,}) - (RECOVERED)$/) ) {
          $file =~ s! +$!!;
          $status{$file} = FILE_FOUND | FILE_OK
            if $status eq 'RECOVERED';
        } elsif ( $lines[$lineno] eq '0%100%' ) {
          # Ignore
        } elsif ( my ($from, $to) =
                  ($lines[$lineno] =~ /^    Rename: (.*) -> (.*)$/) ) {
          if ( $status{$from} & FILE_CORRUPT ) {
            # If file is corrupt, we're moving it to make way
            $status{$from} = FILE_RESTORABLE;
            push @bad_old_files, $to;
          } else { # Else file is not corrupt; why are we moving it?
            croak
              ("Par is moving file $from to $to; I do not understand why..." .
               "\n$lines[$lineno]\n");
          }
        } else {
          last RECOVER_LINE;
        }
      } continue {
        $lineno++;
      }
    } else {
      croak "Bad restorable format on par line $lineno: $lines[$lineno]\n";
    }
  } else {
    croak "Bad end format on par line $lineno: $lines[$lineno]\n"
      unless $lines[$lineno] eq 'All files found';
  }

  croak sprintf("Junk after end of par:\n%s\n",
              join("\n", @lines[$lineno+1..$#lines]))
    unless $lineno >= $#lines;

  return \%status, \%file_name, \@bad_old_files;
}

# -------------------------------------
# CLASS HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 CLASS HIGHER-LEVEL PROCEDURES

Z<>

=cut

# INSTANCE METHODS -----------------------------------------------------------

# -------------------------------------
# INSTANCE CONSTRUCTION
# -------------------------------------

=head1 INSTANCE CONSTRUCTION

Z<>

=cut

=head2 new

Create & return a new thing.

=cut

Class::MethodMaker->import (new_with_init => 'new',
                            new_hash_init => 'hash_init',);

sub init {
  my $self = shift;
  my ($fn) = @_;

  $self->hash_init (fn => $fn);
}

# -------------------------------------
# INSTANCE FINALIZATION
# -------------------------------------

# -------------------------------------
# INSTANCE COMPONENTS
# -------------------------------------

=head1 INSTANCE COMPONENTS

Z<>

=cut

Class::MethodMaker->import
  (
   get_set => [qw/ fn /],
   # status is a map from filename to a bitmask.
   hash    => [qw/ status _file_name /],
   boolean => [qw/ _checked /],
  );


# -------------------------------------
# INSTANCE HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL FUNCTIONS

Z<>

=cut

=head2 files

=over 4

=item PRECONDITION

  $self->checked

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item files

List of files known by par, by their names as par believes they should be.

=back

=back

=cut

sub files {
  my $self = shift;
  return $self->status_keys;
}

# -------------------------------------

=head2 files

=over 4

=item PRECONDITION

  $self->checked

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item files

List of files known by par, by their names as found on the filesystem.  Files
not found are not included in the list.  File names are prefixed by the
directory portion of the par filename, so -e should work.

=back

=back

=cut

sub fs_files {
  my $self = shift;

  my $par_dir = dirname($self->fn);

  return
    map catfile($par_dir, $_),
      map(($self->file_moved($_) || $_), grep ($self->status($_) & FILE_FOUND,
                                               $self->files));
}

# -------------------------------------

=head2 file_known

=over 4

=item PRECONDITION

  $self->checked

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item known

Whether this file name is known by par.

=back

=back

=cut

sub file_known {
  my $self = shift;
  my ($fn) = @_;

  return $self->status_exists($fn);
}

# -------------------------------------

=head2 file_found

=over 4

=item PRECONDITION

  $self->file_known($fn)

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item found

Whether this file name is found by par.

=back

=back

=cut

sub file_found {
  my $self = shift;
  my ($fn) = @_;

  return $self->status($fn) & FILE_FOUND;
}

# -------------------------------------

=head2 file_restorable

=over 4

=item PRECONDITION

  $self->file_known($fn)

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item found

Whether this file name is thought by par to be restorable.

=back

=back

=cut

sub file_restorable {
  my $self = shift;
  my ($fn) = @_;

  return $self->status($fn) & FILE_RESTORABLE;
}

# -------------------------------------

=head2 file_moved

=over 4

=item PRECONDITION

  $self->file_known($fn)

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item found

The name this file has apparently moved to as per par; undef if the file has
not moved.

=back

=back

=cut

sub file_moved {
  my $self = shift;
  my ($fn) = @_;

  return $self->_file_name($fn);
}

# -------------------------------------

=head2 file_ok

=over 4

=item PRECONDITION

  $self->file_known($fn)

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item found

Whether this file name is thought by par to be in tip-top condition.

=back

=back

=cut

sub file_ok {
  my $self = shift;
  my ($fn) = @_;

  return $self->status($fn) & FILE_OK;
}

# -------------------------------------

=head2 file_corrupt

=over 4

=item PRECONDITION

  $self->file_known($fn)

=item ARGUMENTS

=over 4

=item fn

Name of file to look up.  This is the name as expected by par, not any
suitable substitute found by par.

=back

=item RETURNS

=over 4

=item found

Whether this file name is thought by par to be corrupt

=back

=back

=cut

sub file_corrupt {
  my $self = shift;
  my ($fn) = @_;

  return $self->status($fn) & FILE_CORRUPT;
}

# -------------------------------------

=head2 file_recoverable

=over 4

=item PRECONDITION

  ! $self->file_ok($fn)

=item ARGUMENTS

=over 4

=item fn

=back

=item RETURNS

Whether the file may be regenerated somehow

=back

=cut

sub file_recoverable {
  my $self = shift;
  my ($fn) = @_;

  return $self->file_moved($fn) || $self->file_restorable($fn);
}

# -------------------------------------

=head2 recoverable

=over 4

=item PRECONDITIONS

  $self->checked

  ! $self->ok

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item recoverable

true if the files can be recovered, false if not

=back

=back

=cut

sub recoverable {
  my $self = shift;

  croak sprintf("PRECONDITION on %s:%s: failed; not checked\n",
                (caller(0))[0,3])
    unless $self->checked;
  croak sprintf("PRECONDITION on %s:%s: failed; par ok\n",
                (caller(0))[0,3])
    if $self->ok;

  grep(! ($self->file_ok($_) || $self->file_recoverable($_)),
       $self->status_keys) == 0
}

# -------------------------------------

=head2 dump_file_status

Convenience method for returning status of files in par.

=cut

sub dump_file_status {
  my $self = shift;

  for my $fn ($self->status_keys) {
    my $status = $self->status($fn);
    my @flags;
    for my $flag (sort grep(substr($_, 0, 5) eq 'FILE_',
                            keys %{*Archive::Par::})) {
      no strict 'refs';
      my $val = &$flag();
      push @flags, substr($flag, 5)
        if $status & $val;
    }
    printf STDERR "FILE:%-20s: (S%2d); %s\n", $fn, $status, join ' ', @flags;
    if ( $self->_file_name_exists($fn) ) {
      printf STDERR "  (found as %s)\n", $self->_file_name($fn);
    }
  }
}

# -------------------------------------

=head2 checked

=over 4

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item checked

Whether the status flags for this instance are meaningful.

=back

=back

=cut

sub checked { $_[0]->_checked }

# -------------------------------------

=head2 ok

=over 4

=item PRECONDITIONS

  $self->checked

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item ok

True if there are no fixes for par to make.

=back

=back

=cut

sub ok { grep(($_ & FILE_OK) == 0, $_[0]->status_values) == 0 }

# -------------------------------------
# INSTANCE HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL PROCEDURES

Z<>

=cut

sub check {
  my $self = shift; my $class = ref $self;

  my $out;
  # OK, there is (possibly) some arguments.  A filename forces that file to be
  # used for the unrar command. A filehandle argument reads from that
  # filehandle to parse, rather than invoking unrar.  If the filehandle isn't
  # a ref, it's treated purely as a text string.  This is for testing.

  my ($fn, $fh) = @_;
  if ( defined $fh ) {
    if ( ref $fh ) {
      local $/ = undef;
      $out = <$fh>;
    } else {
      $out = $fh;
    }
  } else {
    $fn = $self->fn
      unless defined $fn;
    run([par => 'check', $fn], '&>', \$out);
  }

  my ($status, $file_name) = $class->_parse_par_output($out, $fn);
  $self->status_clear;
  $self->_file_name_clear;
  $self->status($status);
  $self->_file_name($file_name);
  $self->_checked(1);
}

# -------------------------------------

=head2 restore

=over 4

=item PRECONDITIONS

  $self->recoverable

=item ARGUMENTS

=over 4

=item remove_old_files

I<Optional> If true, remove (corrupt) old files created by the restore.

=back

=back

=cut

sub restore {
  my $self = shift; my $class = ref $self;
  my ($remove_old_files) = @_;

  croak sprintf("PRECONDITION on %s:%s: failed; not recoverable\n",
                (caller(0))[0,3])
    unless $self->recoverable;

  my $fn = $self->fn;
  my $out;
  run([qw( par -m -f restore), $fn], '&>', \$out);

  my ($status, $file_name, $old_files) = $class->_parse_par_output($out, $fn);
  $self->status_clear;
  $self->_file_name_clear;
  $self->status($status);
  $self->_file_name($file_name);
  if ( $remove_old_files ) {
    for  ( @$old_files ) {
      my $target = catfile(dirname($self->fn), $_);
      unlink $target
        or croak "Failed to remove corrupt old file: $target: $!\n";
    }
  }
  $self->_checked(1);
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

Copyright (c) 2002 Martyn J. Pearce.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
