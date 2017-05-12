package AnyEvent::EditText;
no warnings;
use strict;

use IO::Handle;
use File::Temp qw/tempfile/;
use AnyEvent;

our %PIDS;
our %READER;
our @EDITOR = ("rxvt", "-e", "vim");

=head1 NAME

AnyEvent::EditText - An easy way to startup a text editor

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

   my $content = "Hello There!";

   AnyEvent::EditText::edit ($content, sub {
      my ($newcontent, $has_changed) = @_;

      if ($has_changed) {
         print "the content was edited";
      }
   });

=head1 DESCRIPTION

This little module will start a text editor in a seperate process without
stopping the current process. Usually something like a terminal with a vim
instance running in it will be started, but also a graphical editor could be
used (like I<gedit> or I<gvim>).

The editor will get the content passed to the C<edit> routine as temporary
file, and after you are done editing it (closed the editor) the callback
will be called with the possibly new content.

=head1 FUNCTIONS

=head2 set_editor (@sysargs)

This function configures the editor used. C<@sysargs> is a list of
arguments for the C<system> function, which will be called like this
by C<edit>:

   system (@sysargs, $filename);

The default editor used will be:

   AnyEvent::EditText::set_editor ("rxvt", "-e", "vim");

=cut

sub set_editor {
   @EDITOR = @_;
}

=head2 edit ($content, $callback)

This routine will write C<$content> to a temporary file, fork
and call the editing process. After the process terminates the
temporary file is read and erased.

After that the content is sent back to the calling process, where the
C<$callback> is called with two arguments: The first will be the new content
and the second a flag indicating whether the content has changed.

=cut

sub edit {
   my ($content, $finish) = @_;
   pipe (my $par_rdr, my $child_wtr);
   $par_rdr->autoflush (1);
   $child_wtr->autoflush (1);

   my $pid;
   if ($pid = fork) {
      $child_wtr->close;

      my $buffer = '';
      $READER{$pid} = AnyEvent->io (fh => $par_rdr, poll => 'r', cb => sub {
         my $l = sysread $par_rdr, my $data, 1024;
         if ($l) {
            $buffer .= $data;
         } elsif (defined $l) {
            delete $READER{$pid};
            if ($buffer =~ s/^(.+?)\n\n//) {
               $finish->(undef, undef, $1);
            } else {
               $buffer =~ s/^\n\n//;
               $finish->($buffer, $content ne $buffer);
            }
         } else {
            warn "couldn't read from child: $!";
            delete $READER{$pid};
            $finish->(undef, undef);
         }
      });

      $PIDS{$pid} = AnyEvent->child (pid => $pid, cb => sub {
         delete $PIDS{$pid};
      });

   } else {
      $par_rdr->close;
      die "couldn't fork: $!" unless defined $pid;
      my ($fh, $filename) = tempfile ("text_edit_XXXXX", DIR => "/tmp");
      print $fh $content;
      close $fh;

      my $ex = system (@EDITOR, $filename);
      unless ($ex == 0) {
         my $err;
         if ($? == -1) {
            $err = "system call failed: $!\n";
         } elsif ($? & 127) {
            $err = sprintf "system call died with signal %d, %s coredump\n",
                           ($? & 127), ($? & 128) ? 'with' : 'without';
         }
         $err =~ s/\n//g;
         print $child_wtr "$err\n\n";
         close $child_wtr;
         unlink $filename;
         exit;
      }

      open $fh, "<$filename"
         or do {
            my $err = "Couldn't open '$filename' for reading: $!\n\n";
            $err =~ s/\n//g;
            print $child_wtr "$err\n\n";
            close $child_wtr;
            unlink $filename;
            exit;
         };

      $content = do { local $/; <$fh> };
      close $fh;

      print $child_wtr "\n\n$content";
      close $child_wtr;

      unlink $filename;
      exit;
   }
}

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>

=head1 TODO

This module should probably first look in the environment to determine
which editor and terminal to use. This will be fixed in the next release.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-edit at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Edit>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::EditText

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Edit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Edit>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Edit>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Edit>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robin Redeker, all rights reserved.
Copyright 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::EditText
