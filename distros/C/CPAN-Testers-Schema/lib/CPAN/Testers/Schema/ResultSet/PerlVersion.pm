use utf8;
package CPAN::Testers::Schema::ResultSet::PerlVersion;
our $VERSION = '0.028';
# ABSTRACT: Query Perl version metadata

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'PerlVersion' );
#pod     $rs->find_or_create({ version => '5.27.0' });
#pod
#pod     $rs = $rs->maturity( 'stable' ); # or 'dev'
#pod
#pod =head1 DESCRIPTION
#pod
#pod This object helps to query Perl version metadata.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Schema::Result::PerlVersion>, L<DBIx::Class::ResultSet>,
#pod L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'ResultSet';
use Log::Any '$LOG';
use Carp ();

#pod =method maturity
#pod
#pod Filter Perl versions of the given maturity. One of C<stable> or C<dev>.
#pod
#pod =cut

sub maturity( $self, $maturity ) {
    if ( $maturity eq 'stable' ) {
        return $self->search({ devel => 0 });
    }
    elsif ( $maturity eq 'dev' ) {
        return $self->search({ devel => 1 });
    }
    Carp::croak "Unknown maturity: $maturity. Must be one of: 'stable', 'dev'";
}


1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::PerlVersion - Query Perl version metadata

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'PerlVersion' );
    $rs->find_or_create({ version => '5.27.0' });

    $rs = $rs->maturity( 'stable' ); # or 'dev'

=head1 DESCRIPTION

This object helps to query Perl version metadata.

=head1 METHODS

=head2 maturity

Filter Perl versions of the given maturity. One of C<stable> or C<dev>.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::PerlVersion>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
