#!/opt/bin/perl
use SOAP::Transport::HTTP;
use CPAN::Search::Lite::Query;

###############################################################
# Change the following to reflect your setup
our $db = '';             # name of the database
our $user = '';           # user to connect as
our $passwd = '';         # password for this user
###############################################################

our $query = CPAN::Search::Lite::Query->new(db => $db,
                                           user => $user,
                                           passwd => $passwd);

SOAP::Transport::HTTP::CGI
    -> dispatch_to('Apache::InfoServer')
    -> options({compress_threshold => 10000})
    -> handle;

package Apache::InfoServer;
use strict;
use warnings;

sub mod_info {
  my ($self, $module) = @_;
  my $ref = ref($module) eq 'ARRAY' ? 1 : 0;
  my @mods = $ref ? (@$module) : ($module);
  my $results;
  foreach my $m (@mods) {
    $m =~ s{-}{::}g;
    return unless ($m and $m =~ m/^[a-zA-Z0-9:_.]+$/);
    my $fields = [qw(mod_name mod_abs mod_vers dist_name 
                   cpanid dist_file fullname email)];
    my $hit = $self->query(mode => 'module', name => $m,
                           fields => $fields);
    next unless $hit;
    if ($ref) {
      $results->{$m} = $hit; 
    }
    else {
      $results = $hit;
      last;
    }
  }
  return $results;
}

sub dist_info {
  my ($self, $dist) = @_;
  my $ref = ref($dist) eq 'ARRAY' ? 1 : 0;
  my @dists = $ref ? (@$dist) : ($dist);
  my $results;
  foreach my $d (@dists) {
    $d =~ s{::}{-}g;
    return unless ($d and $d =~ m/^[a-zA-Z0-9-_.]+$/);
    my $fields = [qw(dist_name dist_abs dist_vers cpanid 
                     fullname email dist_file size birth)];
    my $hit = $self->query(mode => 'dist', name => $d, 
                           fields => $fields);
    next unless $hit;
    if ($ref) {
      $results->{$d} = $hit; 
    }
    else {
      $results = $hit;
      last;
    }
  }
  return $results;
}

sub query {
  my ($self, %args) = @_;
  return unless ($args{mode} and $args{name} and $args{fields});

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

