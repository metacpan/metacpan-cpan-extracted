#!D:/Perl/bin/perl

use SOAP::Transport::HTTP;

################################################################
# Change the following to reflect your setup
our $db = '';             # name of the database
our $user = '';           # user to connect as
our $passwd = '';         # password for this user
our $pod_root = '';       # pod_root
our $max_results = 200;   # max results
###############################################################

SOAP::Transport::HTTP::CGI
  -> dispatch_to('Apache::DocServer')
  -> options({compress_threshold => 10000})
  -> handle;

package Apache::DocServer;
use strict;
use warnings;
use DBI;
use File::Spec::Functions;
use CPAN::Search::Lite::Query;

sub get_doc {
  my ($class, $mod) = @_;
  $mod =~ s!(\.pm|\.pod)$!!;
  return unless ($mod =~ m!^[\w:\.\-]+$!);
  my $query = CPAN::Search::Lite::Query->new(db => $db,
                                             user => $user,
                                             passwd => $passwd,
                                             max_results => $max_results);
  my $fields = [qw(doc dist_name)];
  $query->query(mode => 'module', name => $mod, fields => $fields);
  my $results = $query->{results};
  return unless $results;
  my ($doc, $dist_name) = ($results->{doc}, $results->{dist_name});
  return unless ($doc and $dist_name);
    
  my $base = catfile $pod_root, $dist_name, (split '::', $mod);
  my $file;
  for my $ext ('.pm', '.pod') {
    my $trial = $base . $ext;
    if (-f $trial) {
      $file = $trial;
      last;
    }
  }
  return unless $file;
  open (my $fh, $file) or return;
  my @lines = <$fh>;
  close $fh;
  return \@lines;
}

sub get_readme {
  my ($class, $dist) = @_;
  return unless ($dist =~ m!^[\w:\.\-]+$!);
  my $query = CPAN::Search::Lite::Query->new(db => $db,
                                             user => $user,
                                             passwd => $passwd,
                                             max_results => $max_results);
  my $fields = [qw(readme)];
  $query->query(mode => 'dist', name => $dist, fields => $fields);
  my $results = $query->{results};
  return unless ($results and $results->{readme});
  
  my $file = catfile $pod_root, $dist, 'README';
  return unless (-f $file);
  open (my $fh, $file) or return;
  my @lines = <$fh>;
  close $fh;
  return \@lines;
}

1;

__END__

=head1 NAME

docserver.cgi - soap server for soap-enhanced perldoc

=head1 DESCRIPTION

Place this script in your web server's cgi-bin directory.
This is used by the soap-enhanced C<perldocs> (using C<Pod::Perldocs>)
to view remote pod documentation.

=head1 NOTE

Make sure to check the values of C<$db>, C<$user>,
C<$passwd>, and C<$pod_root> at the top of this file.

=head1 SEE ALSO

L<Pod::Perldocs>.

=cut
