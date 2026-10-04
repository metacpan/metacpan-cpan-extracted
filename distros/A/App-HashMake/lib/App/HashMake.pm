package App::HashMake;

use 5.008003;
use strict;
use warnings;

use Env qw(HASH_MAKEFILE);

use File::Spec;
use Digest::MD5;

use autodie;

=head1 NAME

App::HashMake - Perform make-like actions based on target file's MD5 hash value

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $default_hash_makefile = 'Hash.Makefile';
our $index_file = '.hash_index';

=head1 SYNOPSIS

This module executes the logic of hashmake, based on the input arguments.
Hashmake operates just like make(1), except it looks at the MD5 hash value of a
target file, using a hidden file (.hash_index) to store and check these hash
values for each target. If the hash value of a file has changed, the action is
executed.

Instead of Makefile, hashmake looks for Hash.Makefile to decide what to do.
An alternative makefile can be provided using the -f argument.

The hash values are stored in a hidden file called .hash_index, located in the
same directory as the makefile. The caller can also provide an alternate
working directory if the target directory's not writable.

A sample Hash.Makefile could look like this:

    foo.txt
        echo "I found foo!"

When hashmake is run for the first time, no MD5 is known for this file, so the
action is completed, and the MD5 hash value for the file is stored. Running the
same command a moment later will do nothing, since the MD5 of the file hasn't
changed.

Here's an example of how it would be called from the command line.

    $ hashmake
    (Hashmake does it's thing with the default build file Hash.Makefile)
    $ hashmake -d
    (Hashmake dumps all of the current settings.)
    $

The variable $@ in a Hash.Makefile line will be replaced with the target. So
the Hash.Makefile line

    foo.txt bar.txt
        echo "Found $@"

should produce output like this:

    echo foo.txt
    echo bar.txt

If both of the files had no MD5s or different MD5s.

=head1 ARGUMENTS

    -B    Force rebuild / ignores the 'has it changed' element and just rebuild
          everything.

    -d    Debug / This outputs useful information about what steps are being
          taken during processing.

    -f FILE
          Specify the hash makefile if the standard Hash.Makefile is not being
          used. The environment variable HASH_MAKEFILE can also be used for
          this.

    -h    Display information on the command line arguments.

    -n    Print only / This just prints out what commands would have been run.

    -s    Silent / Don't output anything that would normally be output. Error
          messages are still output.

    -t    Touch only / Mark all targets as being the latest.

    -v    Display version information.

    -y DIR
          Specify a work directory for the index file if the hash makefile's
          directory is not writable.

=head1 SUBROUTINES/METHODS

=head2 run

Run the make procedure. Returns the exit status, along with the output from
STDOUT and STDERR. Called from the hashmake executable.

=cut

our $verb = 1;      #  Verbosity. 0 - quiet, 1 - normal, 2 - debug.
our ( @out, @err ); #  Output and Error lists to be returned to caller.

sub run
{
    my ( $args ) = @_;

    my $debug         = exists $args->{d} ? 1 : 0;
    my $print_only    = exists $args->{n} ? 1 : 0;
    my $makefile      = exists $args->{f} ?
      $args->{f} : ( $HASH_MAKEFILE // $default_hash_makefile );
    my $work_dir      = $args->{y};
    my $force_rebuild = exists $args->{B} ? 1 : 0;
    my $touch_only    = exists $args->{t} ? 1 : 0;

    my $something = 0;  #  Signals if we did (our would have done) something.

    if ($debug) {

      my @output;
      $verb++;

      my @opts = (
        { name => 'debug',         value => $debug },
        { name => 'print_only',    value => $print_only },
        { name => 'makefile',      value => $makefile },
        { name => 'force_rebuild', value => $force_rebuild },
        { name => 'touch_only',    value => $touch_only },
      );

      push ( @output, "Settings:",
        ( map { "--> $_->{ name }: $_->{ value }" } @opts ) );

      if ( defined $work_dir ) {

        push( @output, "--> working_dir: $work_dir" );
      }
      msg ( @output );
    }

    if ( ! -e $makefile ) {

      err ( "$0: ERROR: Makefile $makefile not found, done." );

      return ( $something, { out => \@out, err => \@err } );
    }

    #  The file we're versioning may be in a directory that we can't write to,
    #  so the caller will have set up a working directory for us to use
    #  instead.

    my ( $vol, $dir, $file );
    if ( defined $work_dir ) {

      #  Check that this directory exists.

      if ( ! -e $work_dir ) {

        err ( "$work_dir doesn't exist" );
        return ( $something, { out => \@out, err => \@err } );
      }

      $dir = $work_dir;

    } else {

      #  OK, at this point we do have a makefile, so we need to locate the index
      #  file, which should be in the same directory. If it's there, we'll load
      #  up the hash values.

      ( $vol, $dir, $file ) = File::Spec->splitpath ( $makefile );

    }
    if ( $dir eq '' ) { $dir = '.'; }

    my $full_index_file = File::Spec->catfile ( $dir, $index_file );

    #  Let's check that we can write to this directory -- if not, exit with an
    #  error.

    if ( length $dir && ! -w $dir ) {

      err ( "$0: $dir is not writable" );

      return ( $something, { out => \@out, err => \@err } );
    }

    #  OK, we've dealt with all of the input parameters, and now we're ready to
    #  start actually doing The Thing.

    my %hash_values = ();

    #  If the force_rebuild flag is set, it doesn't matter if the index file
    #  exists, because we're going to act like it's not there.

    if ( ! $force_rebuild && -e $full_index_file ) {

      dbg ( "Reading index file $full_index_file" );

      open ( my $fh, '<', $full_index_file );
      while ( <$fh> ) {

        #  Ths file format is going to be filename, followed by at least one
        #  space, followed by the hash value (shown as an MD5 here). This will
        #  allow us to handle files with embedded spaces. I hope. This file is
        #  going to be a data file only, and will not have comments.

        my ( $target, $md5 ) = /^(.+)\s+(.+)$/;
	    $hash_values{ $target } = $md5;
      }
      close ( $fh );
    }

    #  Read the makefile, so that we can undeerstand the targets.

    dbg ( "Reading makefile $makefile" );

    open ( my $fh, '<', $makefile );
    my ( %config, %targets );

    undef %targets;

    while ( <$fh> ) {

      next if ( /^#/ );        	#  Skip comments

      my $line = $_;
      if ( $line =~ /^\s+$/ ) {

        #  Blank line means we're doing with this target's commands if we had a
        #  target to begin with.

        undef %targets;
        next;
      }
      
      #  Strip leading spaces and trailing new lines.

      $line =~ s/^\s+x$//;
      $line =~ s/\s+$//;

      if ( keys %targets ) {

        #  We have targets, so this is a command line for them.

        foreach my $k ( keys %targets ) {

          push ( @{ $config{ $k } }, $line );
        }

      } else {

        #  Allow a list of targets.

        undef %targets;
        my @targets;
        my @words = split ( /\s/, $line );

        foreach my $w ( @words ) {

          #  If there are wild-card characters, glob will fetch the possible
          #  file names. If not, not.

          push ( @targets, glob ( $w ) );
        }

        @config{ @targets } = ();	#  No commands for these targets yet.
        @targets{ @targets } = undef;
      }
    }
    close ( $fh );

    dbg ( "Targets found are: " . join ( '/', keys %config ) );

    #  Nothing actionable in the makefile? Get out.

    if ( !keys %config ) {

      msg ( "$0: WARN: No targets found, done." );
      return ( $something, { out => \@out, err => \@err } );
    }

    # Now it's time to check out each target. At this point, we're going to be
    # checking them in heap order (so, random). I assume that's going to be
    # fine.

    dbg ( "Checking targets" );

    my $action_count = 0;
    foreach my $t ( keys %config ) {

      dbg ( "Checking target $t" );

      #  Find the MD5 of the target, and see if our value matches the one from
      #  the index file.

      if ( ! -e $t ) {

        msg ( "$0: WARN: Target $t does not exist." );
        next;
      }

      my %digests;

      open ( my $fh, '<', $t );
      my $md5 = Digest::MD5->new;
      $md5->addfile ( $fh );
      close ( $fh );

      my $digest = $md5->hexdigest;
      my $action = 0;        #  No action yet;

      #  If this is a forced rebuild -- we have to do the action OR If a key
      #  does exist, but it doesn't match the current value -- we have to do
      #  the action.  Otherwise -- the key exists and matches, and there's no
      #  action.

      if ( !$force_rebuild &&
           ( exists $hash_values{ $t } && $hash_values{ $t } eq $digest ) ) {

        dbg ( "Key up to date for $t -- no action" );

      } else {

        $action = 1;
        $hash_values{ $t } = $digest;

        dbg ( "Target $t needs action" );
      }

      #  If we're going to do the actions, this is where it happens. Later,
      #  we update the index file before we exit.

      if ( $action ) {

        #  See if the magic variable $@ is on any of the lines -- and if so,
        #  replace it with the current target.

        my @cmds = map { s/\$\@/$t/ge; $_ } @{ $config{ $t } };

        if ( $print_only ) {

          msg ( map { "Would run this --> $_" } @cmds );

        } else {

          #  Unless it's a touch only situation, run the commands.

          if ( !$touch_only ) {

            foreach my $cmd ( @cmds ) {

              system ( $cmd );        #  Run the command. Yikes.
            }
          }
          $action_count++;
        }
        $something = 1;     #  Whether we actually did anything or not.

      } else {

        dbg ( "Nothing to do for the target $t." );
      }
    }

    if ( $action_count ) {

      #  We did some actions, time to update the index.

      open ( my $fh, '>', $full_index_file );
      print $fh join ( "\n",
        map { "$_ $hash_values{ $_ }" } keys %hash_values ) . "\n";
      close ( $fh );

      dbg ( "Updated full_index file $full_index_file." );
      dbg ( "--> keys updated: " . join ( '/', keys %hash_values ) );
    }
    return ( $something, { out => \@out, err => \@err } );
}

=head2 dbg

Internal routine:
Debug messages are output when the verbosity level is 2.

=cut

sub dbg
{
    my ( @msg ) = @_;

   if ( $verb > 1 ) { push ( @out, @msg ); }
}

=head2 msg

Internal routine:
Regular messages are output when the verbosity level is 1.

=cut

sub msg
{
    my ( @msg ) = @_;

   push ( @out, @msg );
}

=head2 err

Internal routine:
Error messages always get output.

=cut

sub err
{
    my ( @msg ) = @_;

   push ( @err, @msg );
}

=head1 AUTHOR

T. Alex Beamish <talexb@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-hashmake at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-HashMake>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::HashMake


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-HashMake>

=item * GitHub issue tracker

L<https://github.com/talexb/App-HashMake/issues>

=item * Search CPAN

L<https://metacpan.org/release/App-HashMake>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by T. Alex Beamish <talexb@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::HashMake
