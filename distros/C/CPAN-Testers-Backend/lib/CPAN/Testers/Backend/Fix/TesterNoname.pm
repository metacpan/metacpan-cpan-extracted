package CPAN::Testers::Backend::Fix::TesterNoname;
our $VERSION = '0.004';
# ABSTRACT: Fix a tester with "NONAME" as a name

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service> <email> <name>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This task fixes a tester who has C<NONAME> as a name by editing all the
#pod right places.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 email
#pod
#pod The email address of the tester to fix.
#pod
#pod =head2 name
#pod
#pod The full name of the tester to change to. Only test reports marked as
#pod C<NONAME> will be fixed.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Backend>, L<CPAN::Testers::Schema>, L<Beam::Runnable>
#pod
#pod =cut

use CPAN::Testers::Backend::Base 'Runnable';
with 'Beam::Runnable';
use Getopt::Long qw( GetOptionsFromArray );
use Data::Dumper;

#pod =attr schema
#pod
#pod A L<CPAN::Testers::Schema> object to access the database.
#pod
#pod =cut

has schema => (
    is => 'ro',
    isa => InstanceOf['CPAN::Testers::Schema'],
    required => 1,
);

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

sub run( $self, @args ) {
    my ( $email, @name ) = @args;
    die "Email and name are required" unless $email && @name;
    my $name = join " ", @name;

    $self->schema->resultset( 'MetabaseUser' )
        ->search({ email => $email, fullname => 'NONAME' })
        ->update({ fullname => $name });

    $self->schema->resultset( 'Stats' )
        ->search({ tester => sprintf '"%s" <%s>', 'NONAME', $email })
        ->update({ tester => sprintf '"%s" <%s>', $name, $email });

    $self->schema->resultset( 'TestReport' )
        ->search({ report => [
                    \q{->>"$.reporter.name"='NONAME'},
                    \qq{->>"\$.reporter.email"='$email'},
                ]})
        ->update({ report => \qq{JSON_SET( report, '\$.reporter.name', '$email' )} });

    # Update old testers_email
    $self->metabase_dbh->do(
        q{UPDATE testers_email SET fullname=? WHERE fullname='NONAME' && email=?},
        {},
        $name, $email,
    );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend::Fix::TesterNoname - Fix a tester with "NONAME" as a name

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    beam run <container> <service> <email> <name>

=head1 DESCRIPTION

This task fixes a tester who has C<NONAME> as a name by editing all the
right places.

=head1 ATTRIBUTES

=head2 schema

A L<CPAN::Testers::Schema> object to access the database.

=head2 metabase_dbh

The L<DBI> object connected to the C<metabase> database.

=head1 ARGUMENTS

=head2 email

The email address of the tester to fix.

=head2 name

The full name of the tester to change to. Only test reports marked as
C<NONAME> will be fixed.

=head1 SEE ALSO

L<CPAN::Testers::Backend>, L<CPAN::Testers::Schema>, L<Beam::Runnable>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
