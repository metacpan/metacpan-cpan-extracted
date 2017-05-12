package DBX::Simple;

use 5.006;
use strict;
use warnings;

=head1 NAME

DBX::Simple - Yet another DBI simplification wrapper.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This is my DBI wrapper. There are many like it, but this one is mine.

I have a horrible memory for syntactic detail. This is one reason I've been developing a semantically oriented programming
language for the past decade, but in the meantime, when I write Perl to manage my accounting or suck data from the Web,
I use SQLite through DBI and I just can't ever remember the syntax. I don't know why. I'm usually fine on SQL syntax, at
least for the basic things I do most of the time, but the actual DBI methods escape me again and again.

This module is the syntax in my head, just so I don't have to keep looking everything up every single time. The class
subclasses DBI anyway, so anything you would do in DBI, you can do here - but with some simplifying alternative methods
as well.

   use DBX::Simple;
   
   my $dbh->DBX::Simple->connect(--DBI syntax--);  # Just so I can support everything DBI supports, after looking it up.
   my $dbh->DBX::Simple->open('sqlite file');      # 99% of my work. ->mysql and ->postgresql would also be reasonable.
   
   my $value = $dbh->get ('select value from table where id=?', $id);  # Single value retrieval in one whack.
   my @rows = $dbh->select ('select * from table'); # Rowset retrieval. Yes, I know about selectrow_array. I just can't remember it.
   my $iter = $dbh->iterate ('select * from table'); # Returns an iterator that returns row arrayrefs.
   my $sth = $dbh->prepare (--DBI syntax--);
   
   $dbh->do ("insert ...");  # Regular insertion, just like in DBI, except the hashref is skipped because I can never remember it.
   my $record = $dbh->insert ("insert ..."); # Calls last_insert_id ('', '', '', ''), which will likely fail except with SQLite.
      
Simple. Like the name says. And exposes DBI anyway for when simple won't cut it, or when DBI is already simple.

One thing to notice: the class structure differs from DBI. DBX::Simple actually subclasses DBI::db - except for the C<connect>
method. So any class-level calls should still be done through DBI, not DBX::Simple. (Easy for me to forget, as I never actually
do class-level stuff, except for those very rare times when I do.)

=cut

use DBI;
use vars qw(@ISA);
@ISA = qw(DBI);

=head1 SUBROUTINES/METHODS

=head2 open

The C<open> method opens an SQLite database file. Uses 'db.sqlt' if no filename is provided.

=cut

sub open {
    my $class = shift;
    my $file = shift || 'db.sqlt';
    $class->connect('dbi:SQLite:dbname=' . $file);
}


package DBX::Simple::db;
use vars qw(@ISA);
@ISA = qw(DBI::db);


=head2 get

The C<get> method retrieves a single value. I do this a I<lot> and it's a pain to bind variables
for one stinking value.

=cut

sub get {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    my $row = $sth->fetchrow_arrayref;
    $row->[0];
}

=head2 select

The C<select> method retrieves an array of arrayrefs for the rows returned from the query.
In scalar mode, returns the arrayref from C<fetchall_arrayref>.

=cut

sub select {
    my $self = shift;
    my $query = shift;
    return unless defined wantarray;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    my $ret = $sth->fetchall_arrayref;
    return wantarray ? @$ret : $ret;
}

=head2 iterate

This could be done from the C<Data::Tab> end as well, but sometimes I already have a perfectly
good dbh and all I want is to iterate rows without the overhead of loading them all at once.

=cut

sub iterate {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    sub {
        $sth->fetchrow_arrayref;
    }
}

=head2 insert

The C<insert> command calls C<last_insert_id> after the insertion. Just a little shorthand.

=cut

sub insert {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
    $self->last_insert_id('', '', '', '');
}

=head2 do

The C<do> command works a little differently; DBI's version wants a hashref of attributes that I never use
and regularly screw up.

=cut

sub do {
    my $self = shift;
    my $query = shift;
    my $sth = $self->prepare($query);
    $sth->execute(@_);
}

package DBX::Simple::st;
use vars qw(@ISA);
@ISA = qw(DBI::st);

# We don't actually have anything to override in the statement, but it has to be defined or the DBI machinery won't work.


=head1 AUTHOR

Michael Roberts, C<< <michael at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbx-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBX-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBX::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBX-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBX-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBX-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/DBX-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DBX::Simple
