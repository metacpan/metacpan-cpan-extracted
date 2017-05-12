use utf8;
package CPAN::Testers::Schema::ResultSet::Upload;
our $VERSION = '0.005';
# ABSTRACT: Query the CPAN uploads data

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'Upload' );
#pod     $rs->by_dist( 'My-Dist' );
#pod     $rs->by_author( 'PREACTION' );
#pod     $rs->since( '2016-01-01T00:00:00' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This object helps to query the CPAN uploads table. This table tracks
#pod uploads to CPAN by distribution, version, and author, and also flags
#pod distributions that have been deleted from CPAN (and are thus only
#pod available on BackPAN).
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<CPAN::Testers::Schema::Result::Upload>
#pod
#pod =item L<DBIx::Class::ResultSet>
#pod
#pod =item L<CPAN::Testers::Schema>
#pod
#pod =item L<http://github.com/cpan-testers/cpantesters-project>
#pod
#pod For an overview of how the CPANTesters project works, and for information about
#pod project goals and to get involved.
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'ResultSet';
use DateTime::Format::ISO8601;

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
    return $self->search( { 'me.author' => $author } );
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
    my $dt = DateTime::Format::ISO8601->parse_datetime( $date );
    return $self->search( { released => { '>=' => $dt->epoch } } );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::Upload - Query the CPAN uploads data

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Upload' );
    $rs->by_dist( 'My-Dist' );
    $rs->by_author( 'PREACTION' );
    $rs->since( '2016-01-01T00:00:00' );

=head1 DESCRIPTION

This object helps to query the CPAN uploads table. This table tracks
uploads to CPAN by distribution, version, and author, and also flags
distributions that have been deleted from CPAN (and are thus only
available on BackPAN).

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

=over

=item L<CPAN::Testers::Schema::Result::Upload>

=item L<DBIx::Class::ResultSet>

=item L<CPAN::Testers::Schema>

=item L<http://github.com/cpan-testers/cpantesters-project>

For an overview of how the CPANTesters project works, and for information about
project goals and to get involved.

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
