use utf8;
package CPAN::Testers::Schema::ResultSet::Release;
our $VERSION = '0.023';
# ABSTRACT: Query the per-release summary testers data

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'Release' );
#pod     $rs->by_dist( 'My-Dist', '0.001' );
#pod     $rs->by_author( 'PREACTION' );
#pod     $rs->since( '2016-01-01T00:00:00' );
#pod     $rs->maturity( 'stable' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This object helps to query the per-release test report summaries. These
#pod summaries say how many pass, fail, NA, and unknown results a single
#pod version of a distribution has.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::ResultSet>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'ResultSet';

#pod =method by_dist
#pod
#pod     $rs = $rs->by_dist( 'My-Dist' );
#pod     $rs = $rs->by_dist( 'My-Dist', '0.001' );
#pod
#pod Add a dist constraint to the query (with optional version), replacing
#pod any previous dist constraints.
#pod
#pod =cut

sub by_dist( $self, $dist, $version = undef ) {
    my %search = ( 'me.dist' => $dist );
    if ( $version ) {
        $search{ 'me.version' } = $version;
    }
    return $self->search( \%search );
}

#pod =method by_author
#pod
#pod     $rs = $rs->by_author( 'PREACTION' );
#pod
#pod Add an author constraint to the query, replacing any previous author
#pod constraints.
#pod
#pod =cut

sub by_author( $self, $author ) {
    return $self->search( { 'upload.author' => $author }, { join => 'upload' } );
}

#pod =method since
#pod
#pod     $rs = $rs->since( '2016-01-01T00:00:00' );
#pod
#pod Restrict results to only those that have been updated since the given
#pod ISO8601 date.
#pod
#pod =cut

sub since( $self, $date ) {
    my $fulldate = $date =~ s/[-:T]//gr;
    $fulldate = substr $fulldate, 0, 12; # 12 digits makes YYYYMMDDHHNN
    return $self->search( { 'report.fulldate' => { '>=', $fulldate } }, { join => 'report' } );
}

#pod =method maturity
#pod
#pod     $rs = $rs->maturity( 'stable' );
#pod
#pod Restrict results to only those dists that are stable. Also supported:
#pod 'dev' to restrict to only development dists.
#pod
#pod =cut

sub maturity( $self, $maturity ) {
    my %map = ( 'stable' => 1, 'dev' => 2 );
    $maturity = $map{ $maturity };
    return $self->search( { 'me.distmat' => $maturity } );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::Release - Query the per-release summary testers data

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Release' );
    $rs->by_dist( 'My-Dist', '0.001' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );
    $rs->maturity( 'stable' );

=head1 DESCRIPTION

This object helps to query the per-release test report summaries. These
summaries say how many pass, fail, NA, and unknown results a single
version of a distribution has.

=head1 METHODS

=head2 by_dist

    $rs = $rs->by_dist( 'My-Dist' );
    $rs = $rs->by_dist( 'My-Dist', '0.001' );

Add a dist constraint to the query (with optional version), replacing
any previous dist constraints.

=head2 by_author

    $rs = $rs->by_author( 'PREACTION' );

Add an author constraint to the query, replacing any previous author
constraints.

=head2 since

    $rs = $rs->since( '2016-01-01T00:00:00' );

Restrict results to only those that have been updated since the given
ISO8601 date.

=head2 maturity

    $rs = $rs->maturity( 'stable' );

Restrict results to only those dists that are stable. Also supported:
'dev' to restrict to only development dists.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<CPAN::Testers::Schema>

=head1 AUTHOR

Oriol Soriano <oriolsoriano@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
