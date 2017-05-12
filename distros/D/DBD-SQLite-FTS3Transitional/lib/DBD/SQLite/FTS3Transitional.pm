package DBD::SQLite::FTS3Transitional;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';
use Exporter ();

our $VERSION   = '1.00';
our @ISA       = 'Exporter';
our @EXPORT_OK = qw/fts3_convert/;

sub fts3_convert {
  my $in  = shift;
  my $out = "";

  # decompose input string into tokens
  my @tokens = $in =~ / -       # minus sign
                      | \bOR\b  # OR keyword
                      | ".*?"   # phrase query
                      | \S+     # term
                      /xg;

  # build the output string
  while (@tokens) {

    # -a => (NOT a)
    if ($tokens[0] eq '-') {
      my (undef, $right) = splice(@tokens, 0, 2);
      $out .= " (NOT $right)";
    }

    # a OR b => (a OR b)
    elsif (@tokens >= 2 && $tokens[1] eq 'OR') {
      my ($left, undef, $right) = splice(@tokens, 0, 3);
      if ($right eq '-') {
        $right = "NOT " . shift @tokens;
      }
      $out .= " ($left OR $right)";
    }

    # plain term
    else {
      $out .= " " . shift @tokens;
    }
  }

  return $out;
}


1;

__END__

=head1 NAME

DBD::SQLite::FTS3Transitional - helper function for migrating FTS3 applications

=head1 SYNOPSIS

  use DBD::SQLite::FTS3Transitional qw/fts3_convert/;
  my $new_match_syntax = fts3_convert($old_match_syntax);
  my $sql = "SELECT ... FROM ... WHERE col MATCH $new_match_syntax";

=head1 DESCRIPTION

Starting from version 1.31, C<DBD::SQLite> uses the new, recommended
"Enhanced Query Syntax" for binary set operators in fulltext FTS3 queries
(AND, OR, NOT, possibly nested with parenthesis). 

Previous versions of C<DBD::SQLite> used the
"Standard Query Syntax" (see L<http://www.sqlite.org/fts3.html#section_3_2>).
Applications built with the old  "Standard Query" syntax,
have to be migrated, because the precedence of the C<OR> operator
has changed. 

This module helps in the migration process : it provides a function
to automatically translate from old to new syntax.

=head1 FUNCTIONS

=head2 fts3_convert

Takes as input a string for the MATCH clause in a FTS3 fulltext search;
returns the same clause rewritten in new, "Extended" syntax.

=head1 AUTHOR

Laurent Dami E<lt>dami@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 Laurent Dami.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut



package DBD::SQLite::FTS3Transitional;

use warnings;
use strict;

=head1 NAME

DBD::SQLite::FTS3Transitional - The great new DBD::SQLite::FTS3Transitional!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBD::SQLite::FTS3Transitional;

    my $foo = DBD::SQLite::FTS3Transitional->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbd-sqlite-fts3transitional at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBD-SQLite-FTS3Transitional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBD::SQLite::FTS3Transitional


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-SQLite-FTS3Transitional>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBD-SQLite-FTS3Transitional>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBD-SQLite-FTS3Transitional>

=item * Search CPAN

L<http://search.cpan.org/dist/DBD-SQLite-FTS3Transitional/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DBD::SQLite::FTS3Transitional
