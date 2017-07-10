use utf8;
package CPAN::Testers::Schema::ResultSet::Release;
our $VERSION = '0.015';
# ABSTRACT: Query the per-release summary testers data

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'Release' );
#pod     $rs->by_dist( 'My-Dist' );
#pod     $rs->by_author( 'PREACTION' );
#pod     $rs->since( '2016-01-01T00:00:00' );
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
#pod
#pod Add a dist constraint to the query, replacing any previous dist
#pod constraints.
#pod
#pod =cut

sub by_dist( $self, $dist ) {
    return $self->search( { 'me.dist' => $dist } );
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

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::Release - Query the per-release summary testers data

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Release' );
    $rs->by_dist( 'My-Dist' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );

=head1 DESCRIPTION

This object helps to query the per-release test report summaries. These
summaries say how many pass, fail, NA, and unknown results a single
version of a distribution has.

=head1 METHODS

=head2 by_dist

    $rs = $rs->by_dist( 'My-Dist' );

Add a dist constraint to the query, replacing any previous dist
constraints.

=head2 by_author

    $rs = $rs->by_author( 'PREACTION' );

Add an author constraint to the query, replacing any previous author
constraints.

=head2 since

    $rs = $rs->since( '2016-01-01T00:00:00' );

Restrict results to only those that have been updated since the given
ISO8601 date.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
