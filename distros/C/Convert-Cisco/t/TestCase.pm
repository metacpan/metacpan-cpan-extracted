#===========================================================================

=head1 t::TestCase

=head1 Methods

=cut

package t::TestCase;
use base qw(Test::Unit::TestCase);

use strict;
use Log::Log4perl;
use FileHandle;
use File::Compare qw(compare_text);

#----------------------------------------

=head2 new

=cut

sub new {
   my $self = shift()->SUPER::new(@_);

   Log::Log4perl->init(\q(
log4perl.logger=INFO, Test

log4perl.appender.Test = Log::Log4perl::Appender::TestBuffer
log4perl.appender.Test.layout = PatternLayout
log4perl.appender.Test.layout.ConversionPattern = %p> %m;
   ));

   return $self;
}

#----------------------------------------

=head2 set_up

=cut

sub set_up {
   my $self = shift;

   ### Reset test variables
   $self->{register_files} = [];
}

#----------------------------------------

=head2 tear_down

=cut

sub tear_down {
   my $self = shift;

   ### Reset the TestBuffer appender
   undef $self->{Test_log};
   Log::Log4perl::Appender::TestBuffer->by_name("Test")->buffer("");

   ### Remove test files
   foreach my $file ( @{$self->{register_files}} ) {
      unlink $file;
   }
}

#----------------------------------------

=head2 register_file

=cut

sub register_file {
   my $self = shift;
   my ($file) = @_;

   push @{$self->{register_files}}, $file;
}

#----------------------------------------

=head2 assert_log

=cut

sub assert_log {
   my $self = shift;
   my ($msg) = @_;
   local $Error::Depth = $Error::Depth + 1;

   $self->{Test_log} = [split /;/, Log::Log4perl::Appender::TestBuffer->by_name("Test")->buffer] unless $self->{Test_log};

   if (defined $msg) {
      $self->assert_str_equals($msg, shift @{$self->{Test_log}});
   }
   else {
      $self->assert_null(shift @{$self->{Test_log}});
   }
}

#----------------------------------------

=head2 assert_file_contents_identical

Tests that the contents of two files are identical.

=cut

sub assert_file_contents_identical {
   my $self = shift;
   my ($testFile, $expectedFile) = @_;

   local $Error::Depth = $Error::Depth + 1;

   $self->assert(-f $testFile, "Test file does not exist: $testFile");
   $self->assert(-f $expectedFile, "Expected file does not exist: $expectedFile");

   my $line = 0;
   my $func = sub {
      $line++;
      if ($_[0] eq $_[1]) {
         return 0;
      }
      else {
# HarnessUnit: test runner does not print annotations
#         $self->annotate("Line $line\n");
#         $self->annotate("\nExpected:\n'".$_[1]."'");
#         $self->annotate("\nGot:\n'".$_[0]."'");
         print("Line $line\n");
         print("\nExpected:\n'".$_[1]."'");
         print("\nGot:\n'".$_[0]."'");
         return 1;
      }
   }; 

   $self->assert_num_equals(0, compare_text($testFile, $expectedFile, $func), "Unexpected file content");

   return $self;
}

#----------------------------------------

=head2 assert_file_contents_is

Checks for an exact match on the file's contents.

=cut

sub assert_file_contents_is {
   my $self = shift;
   my ($testFile, $expectedStr) = @_;
   my $tmpFile = $testFile.".tmp";

   local $Error::Depth = $Error::Depth + 1;

   $self->register_file($tmpFile); 

   my $file = FileHandle->new($tmpFile, "w");
   $file->print($expectedStr);
   $file->close;

   $self->assert_file_contents_identical($testFile, $tmpFile);

   return $self;
}

1;
