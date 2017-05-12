package Attempt;

use Exporter;
use base qw(Exporter);

use vars qw(@EXPORT $VERSION);
@EXPORT = qw(attempt);

use strict;
#use warnings;

use Carp qw(croak);

$VERSION = "1.01";

=head1 NAME

Attempt - attempt to run code multiple times

=head1 SYNOPSIS

  use Attempt;

  # if the database goes away while we're using it, just try again...
  attempt {

    my $dbh = DBI->connect("DBD::Mysql:foo", "mark", "opensaysme")
      or die "Can't connect to database";
    $dbh->{RaiseException} = 1;
    $dbh->do("alter table items change pie pies int(10)");

  } tries => 3, delay => 2;

=head1 DESCRIPTION

Attempt creates a new construct for things that you might want to
attempt to do more than one time if they throw exceptions, because the
problems they throw exceptions to report might go away.

Exports a new construct called C<attempt>.  The simplest way to use
C<attempt> is to write attempt followed by a block of code to attempt
to run.

  attempt {
    something_that_might_die();
  };

By default perl will attempt to run to run the code again without
delay if an exception is thrown.  If on the second run an exception
is again thrown, that exception will be propogated out of the attempt
block as normal.

The particulars of the run can be changed by passing parameters after
the code block. The C<tries> parameter effects the number of times the
code will attempt to be run.  The C<delay> parameter determines how
often perl will wait - sleep - between runs.

C<attempt> can return values, and you can exit out of an attempt block
at any point with a return statement as you might expect.  List and
scalar context is preserved though-out the call to the block.

=cut

sub attempt (&;@)
{
  my $code = shift;
  my %args = @_;

  my @results;
  my $result;

  # find out how many attempts we're going to take,
  # defaulting to two.
  my $tries = exists($args{tries}) ? $args{tries} : 2;

  # try while we've got tries left.
  while (1)
  {
    # do we want a list?
    my $wantarray = wantarray;

    # try running the code
    eval
    {
      if ($wantarray)
        { @results = $code->() }
      else
        { $result = $code->() }
    };

    # return if we're sucessful
    return ($wantarray ? @results : $result )
      unless $@;

    # we've used up a try
    $tries--;
    last if $tries < 1;

    # sleep if we need to
    select undef, undef, undef, $args{delay}
       if exists $args{delay};
  }

  # got this far and didn't already return, so propogate the error
  croak $@;
}

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Only respects list and scalar context, doesn't replicated
the more complicated forms of context that B<Want> supports.

The caller isn't what you might expect from within the attempt
block (or rather, it is, but isn't what it would have been if
the block wasn't there)

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Attempt>.

=head1 SEE ALSO

L<Sub::Attempts>, L<Attribute::Attempts>

=cut

1;
