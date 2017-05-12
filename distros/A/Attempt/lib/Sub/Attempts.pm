package Sub::Attempts;

use strict;
#use warnings;
use vars qw($VERSION @EXPORT);

$VERSION = "1.01";

use Exporter;
use base qw(Exporter);
@EXPORT = qw(attempts);
use Sub::Uplevel;

use Carp;

=head1 NAME

Sub::Attempts - alter subroutines to try again on exceptions

=head1 SYNOPSIS

  use Sub::Attempts;

  sub alter_db
  {
    my $dbh = DBI->connect("DBD::Mysql:foo", "mark", "opensaysme")
      or die "Can't connect to database";
    $dbh->{RaiseException} = 1;
    $dbh->do("alter table items change pie pies int(10)");
  }

  # if there's a problem making pies, wait and try again
  attempts("alter_db", tries => 3, delay => 2);


=head1 DESCRIPTION

Sometimes if a subroutine throws an exception the right thing to
do is wait for a while and then call the subroutine again, as the
error conditions that caused the subroutine to have to throw
the exception might have gone away.

This module exports one subroutine C<attempts> which can be used to
modifiy existing subroutines so that whenever that subroutine is
called it will be automatically be called again in the event that it
throws an exception.

   use LWP::Simple qw(get);
   sub journal_rss
   {
     return get("http://use.perl.org/~2shortplanks/journal/rss")
       or die "Couldn't get journal";
   }
   attempts("journal_rss");

By default perl will attempt to run to run the subroutine again
without delay if an exception is thrown.  If on the second run an
exception is again thrown, that exception will be propogated out of
the subroutine as normal.

The particulars of the subroutines re-execution can be changed by
passing extra parameters to C<attempts>. The C<tries> parameter
effects the number of times the subroutne will attempt to be executed.
The C<delay> parameter determines how long perl will wait - sleep -
in seconds (and fractions of a second) between execution attempts.

=head2 Methods

A method can be modified just like any other subroutine, provided the
subroutine defining the method is located in the same package as
C<attempts> is called from.  If this is not the case (i.e. the method
is inherited and not overridden) then you should use the C<method>
parameter:

    attempts("get_pie", tries => 3, method => 1);

This has the same effect as writing:

    sub get_pie
    {
      my $self = shift;
      $self->SUPER::get_pie(@_);
    }

    attempts("get_pie", tries => 3);

If a method is defined by a subroutine in the current package then
the C<method> parameter has no effect

=cut

sub attempts
{
  # here be subroutine magic
  no strict 'refs';

  my $subname = shift;
  my %args = @_;

  # get the ref to the existing subroutine
  my $package = caller || croak "Not in a package";
  my $glob    = \*{"${package}::${subname}"};
  my $old_sub = *{ $glob }{CODE};

  # is it a method?
  if (!defined($old_sub))
  {
    if ($args{method})
    {
      # this eval is here as we need to switch packages to declare a
      # subroutine so SUPER works and with the current limitations of
      # perl, there's no way to do that by mucking about with
      # typeglobs.
      eval qq{package $package;
              sub $subname
              {
                 my \$this = shift;
                 \$this->SUPER::$subname(\@_)
              }
      };
      $old_sub = *{ $glob }{CODE};
    }
    else
    {
      croak "Can't wrap '$subname', doesn't exist in package '$package'"
    }
  }

  # replace the subroutine
  _attempts($old_sub, $glob, %args);
}

sub _attempts
{
  # here be subroutine magic too
  no strict 'refs';

  my $old_sub = shift;
  my $glob    = shift;
  my %args    = @_;

  # create a new subroutine that does the attempt stuff
  my $sub = sub
  {
    # find out how many attempts we're going to take,
    # defaulting to two.
    my $tries = exists($args{tries}) ? $args{tries} : 2;

    # do we want a list?
    my $wantarray = wantarray;

    # try while we've got tries left.
    while (1)
    {
      my $result;
      my @results;

      # try running the code
      eval
      {
	if ($wantarray)
          { @results = uplevel 2, $old_sub, @_ }
        else
          { $result = uplevel 2, $old_sub, @_ }
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
  };

  # place the subroutine into the symbol table
  *{ $glob } = $sub;
}

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Though list and scalar context will be preserved for the call to the
original subroutine, other forms of context (as offered by B<Want>)
will be lost.  Therefore, amongst other things, a subroutine modified
by C<attempts> cannot currently 1be used as a lvalue.

The caller bug is now defeated, thanks to B<Sub::Uplevel> things think
they're in a higher caller frame.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub::Attempts>.

=head1 SEE ALSO

L<Attribute::Attempts>,
L<Attempt>

=cut

1;
