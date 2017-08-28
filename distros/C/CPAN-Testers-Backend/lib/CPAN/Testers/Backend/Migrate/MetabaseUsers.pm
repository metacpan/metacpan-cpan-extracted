package CPAN::Testers::Backend::Migrate::MetabaseUsers;
our $VERSION = '0.002';
# ABSTRACT: Migrate old metabase users to new table for metabase lookups

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This task migrates the users in the C<metabase.tester_emails> table to the
#pod C<cpanstats.metabase_user> table. This makes these users available to the
#pod L<CPAN::Testers::Schema> for when new Metabase reports come in.
#pod
#pod Only the latest name and e-mail address for a given Metabase resource GUID
#pod will be migrated.
#pod
#pod =cut

use CPAN::Testers::Backend::Base 'Runnable';
with 'Beam::Runnable';

#pod =attr metabase_dbh
#pod
#pod The L<DBI> object connected to the C<metabase> database.
#pod
#pod =cut

has metabase_dbh => (
    is => 'ro',
    isa => InstanceOf['DBI::db'],
    required => 1,
);

#pod =attr schema
#pod
#pod The L<CPAN::Testers::Schema> to write users to.
#pod
#pod =cut

has schema => (
    is => 'ro',
    isa => InstanceOf['CPAN::Testers::Schema'],
    required => 1,
);

sub run( $self, @args ) {
    my @from_users = $self->metabase_dbh->selectall_array( 'SELECT resource,fullname,email FROM testers_email ORDER BY id ASC', { Slice => {} } );

    # Save the last user for this GUID
    my %users;
    for \my %user ( @from_users ) {
        $users{ $user{resource} } = \%user;
    }

    # Update the user in the mapping table
    for \my %user ( values %users ) {
        $self->schema->resultset( 'MetabaseUser' )->update_or_create( \%user );
    }
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend::Migrate::MetabaseUsers - Migrate old metabase users to new table for metabase lookups

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    beam run <container> <service>

=head1 DESCRIPTION

This task migrates the users in the C<metabase.tester_emails> table to the
C<cpanstats.metabase_user> table. This makes these users available to the
L<CPAN::Testers::Schema> for when new Metabase reports come in.

Only the latest name and e-mail address for a given Metabase resource GUID
will be migrated.

=head1 ATTRIBUTES

=head2 metabase_dbh

The L<DBI> object connected to the C<metabase> database.

=head2 schema

The L<CPAN::Testers::Schema> to write users to.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
