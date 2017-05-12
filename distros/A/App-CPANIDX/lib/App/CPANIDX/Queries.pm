package App::CPANIDX::Queries;

use strict;
use warnings;
use Module::CoreList::DBSchema;
use vars qw[$VERSION];

$VERSION = '0.40';

my $mcdbs = Module::CoreList::DBSchema->new();

my %queries = (
  'mod' => [ 'select mods.mod_name,mods.mod_vers,mods.cpan_id,dists.dist_name,dists.dist_vers,dists.dist_file from mods,dists where mod_name = ? and mods.dist_name = dists.dist_name and mods.dist_vers = dists.dist_vers', 1 ],
  'dist' => [ 'select * from dists where dist_name = ?', 1 ],
  'auth' => [ 'select * from auths where cpan_id = ?', 1 ],
  'dists' => [ 'select * from dists where cpan_id = ?', 1 ],
  'perms' => [ 'select * from perms where mod_name = ?', 1 ],
  'timestamp' => [ 'select * from timestamp', 0 ],
  'firstmod' => [ 'select mod_name from mods order by mod_name limit 1', 0 ],
  'nextmod' => [ 'select mod_name from mods order by mod_name limit ?,1', 1 ],
  'firstauth' => [ 'select cpan_id from auths order by cpan_id limit 1', 0 ],
  'nextauth' => [ 'select cpan_id from auths order by cpan_id limit ?,1', 1 ],
  'modkeys'  => [ 'select mod_name from mods order by mod_name', 0 ],
  'authkeys' => [ 'select cpan_id from auths order by cpan_id', 0 ],
  'topten' => [ 'select cpan_id, count(*) as "dists" from dists group by cpan_id order by count(*) desc limit 10', 0 ],
  'mirrors', => [ 'select * from mirrors', 0 ],
);

foreach my $query ( $mcdbs->queries() ) {
  $queries{ $query } = $mcdbs->query( $query );
}

sub query {
  return unless @_;
  my $query = shift;
  $query = shift if $query->isa(__PACKAGE__);
  return unless $query;
  return unless exists $queries{ $query };
  my $sql = $queries{ $query };
  return @{ $sql } if wantarray;
  return $sql;
}

sub queries {
  return keys %queries;
}

1;

__END__

=head1 NAME

App::CPANIDX::Queries - Provide SQL queries for App::CPANIDX

=head1 SYNOPSIS

  my $aref = App::CPANIDX::Queries->query('mod');

  my ($sql,$flag) = App::CPANIDX::Queries->query('auth');

  my @types = App::CPANIDX::Queries->queries();

=head1 DESCRIPTION

App::CPANIDX::Queries provides the SQL queries that App::CPANIDX uses to query
the CPANIDX.

=head1 FUNCTIONS

=over

=item C<queries>

Returns a list of the available queries.

=item C<query>

Takes one argument, the name of a query to lookup.

Returns in list context a list consisting of a SQL string and a flag indicating whether the
SQL string includes placeholders.

In scalar context returns an array reference containing the same as above.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<App::CPANIDX>

=cut
