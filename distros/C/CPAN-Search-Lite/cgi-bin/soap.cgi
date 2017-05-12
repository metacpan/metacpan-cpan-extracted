#!D:/Perl/bin/perl

use SOAP::Transport::HTTP;

###############################################################
# Change the following to reflect your setup
our $db = '';             # name of the database
our $user = '';           # user to connect as
our $passwd = '';         # password for this user
our $max_results = 200;   # maximum results to report
###############################################################

SOAP::Transport::HTTP::CGI
    -> dispatch_to('CPAN_Search_CGI')
    -> options({compress_threshold => 10000})
    -> handle;

package CPAN_Search_CGI;
use strict;
use warnings;
use CPAN::Search::Lite::Query;

sub query {
  my ($self, %args) = @_;
  return unless ($args{mode} and $args{name});

  my $query = CPAN::Search::Lite::Query->new(db => $db,
                                             user => $user,
                                             passwd => $passwd,
                                             max_results => $max_results);

  $query->query(mode => $args{mode},
                name => $args{name}, fields => $args{fields});
  my $results = $query->{results};
  if (my $error = $query->{error}) {
    print STDERR $error;
    return;
  }
  return $results;
}

__END__

=head1 NAME

soap.cgi - soap interface to C<CPAN::Search::Lite::Query>

=head1 DESCRIPTION

Place this script in your web server's cgi-bin directory.
The script C<soap.pl> supplied in the source distribution
illustrates how this may be used.

=head1 NOTE

Make sure to check the values of C<$db>, C<$user>, and
C<$passwd> at the top of this file.

=head1 SEE ALSO

L<Apache::CPAN::Search>, L<Apache::CPAN::Query>,
and L<CPAN::Search::Lite::Query>.

=cut

