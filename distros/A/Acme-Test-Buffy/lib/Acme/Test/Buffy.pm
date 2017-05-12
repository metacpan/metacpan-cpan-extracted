package Acme::Test::Buffy;

# turn on strict.  If this was perl 5.6.0 I'd turn on warnings too, but
# testing scripts normally work on perls all the way back to 5.004
# so I can't say that.

use strict;
#use warnings;

# declare the global vars for exporter and isa and stuff.  If this
# was 5.6.0 we could use our

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# this is the first version of the module
$VERSION = "0.02";

# load the test builder class.  This class contains all the methods
# that you use to emit test results.

use Test::Builder;

# get the tester.  Despite being called 'new', this simply returns the
# one and only tester object - this is what is known as a singleton
# class.  Essentially this means that all Test::Builder objects are
# one and the same object, and this is what allows all classes that
# make use of Test::Builder to print out "ok 1" "ok 2" etc without
# getting in each other's way and mucking up the order of the numbers

my $Tester = Test::Builder->new();

# this is loading exporter.  Exporter is used to export functions
# from our namespace into the callers.  i.e. it's a way to make
# 'is_buffy' be able to be called from within a testing script

use Exporter;                   # load the class
@ISA         = qw(Exporter);    # set it as the base class
@EXPORT      = qw(is_buffy);    # want to export 'is_buffy'
@EXPORT_OK   = qw();            # no other optional functions
%EXPORT_TAGS = qw();            # no groups of functions

# write some pod documentation

=head1 NAME

Acme::Test::Buffy - example Test::Builder testing module

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Acme::Test::Buffy;

  is_buffy($foo, "test foo is Buffy");

=head1 DESCRIPTION

The reason for writing this module is to demonstrate how you
can write testing modules that work together with B<Test::Builder>.
It also shows how to test such modules with B<Test::Builder::Tester>.
Look at the source code (which is heavily commented) for further
enlightenment.

This module simply exports one testing function that tests if a string
is the same as "Buffy" (case sensitive.)

=cut

# here's where we define the subroutine "is_buffy" that will be
# exported.  Note the prototype that does the right thing.  More
# can be found out about prototypes in the 'perlsub' perldoc.
# This one simply says "one scalar argument and possibly another"

sub is_buffy($;$)
{
  # simply call the other subroutine.  There's no reason why this
  # couldn't be done here, I just want to show how to call other
  # subroutines in this class.  This supplied a default test
  # description
  _do_buffy_test(shift(), shift() || "is 'Buffy'");
}

# this is a second subroutine that's used to demonstrate how you
# should deal with calling subroutines.

sub _do_buffy_test
{
  # as we've entered another subroutine we need to increase the
  # counter that Test::Builder uses to state where the error
  # comes from (so we get an error at the line in your test
  # script not from within the call to this routine in 'is_buffy')
  # we use a local so that the level is returned to the previous
  # value when we exit the subroutine.  Note that we can't use
  # the ++ operator here as it doesn't do what you might think.

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # get the args
  my ($maybe_buffy, $text) = @_;

  # do the test
  if ($maybe_buffy eq "Buffy")
  {
    # print okay with the right text ("ok <number> - <text>")
    $Tester->ok(1,$text);

    # return a true value (don't have to do this but it's nice)
    return 1;
  }
  else
  {
    # We failed. We want to test Test::Builder to print something
    # like:
    #      Failed test at line <line number>
    #    Expected 'Buffy' but got '<what we got>' instead
    # that is to say we print failure first, _then_ the extra diag
    # stuff that will help people debug the code better.

    # print not okay with the right text ("not ok <number> - <text>")
    $Tester->ok(0,$text);

    # print diagnostics of *why* it failed.  Don't just print to
    # STDERR this is bad and wrong as it prevents the test output
    # being properly caught.  Note the "\n" on the end of the
    # line.
    $Tester->diag("Expected 'Buffy' but got '$maybe_buffy' instead\n");

    # return a false value (don't have to do this, but it's nice)
    return 0;
  }
}

=head1 BUGS

None known.  Please report, including documentation bugs to
the author.  You may use the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Test-Buffy>

=head1 AUTHOR

   Copyright Mark Fowler
   E<lt>mark@twoshortplanks.comE<gt> 2002-2004
   All rights reserved.

  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 NOTES

Module also written to annoy Leon Brocard, who will have to update his
YAPC::Europe talk slides to include it a mere ten minutes before his
talk.

=head1 SEE ALSO

L<Test::Builder>, L<Test::Builder::Tester>, L<Test::More>.

=cut

# and return true
1;
