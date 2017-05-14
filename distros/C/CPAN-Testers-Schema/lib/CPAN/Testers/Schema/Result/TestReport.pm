package CPAN::Testers::Schema::Result::TestReport;
our $VERSION = '0.008';
# ABSTRACT: Raw reports as JSON documents

#pod =head1 SYNOPSIS
#pod
#pod     my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );
#pod
#pod     # Retrieve a row
#pod     my $row = $schema->resultset( 'TestReport' )->first;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table contains the raw reports as submitted by the tester. From this,
#pod the L<statistics table|CPAN::Testers::Schema::Result::Stats> is generated
#pod by L<CPAN::Testers::Backend::ProcessReports>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::Row>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';
use Data::UUID;
use DateTime;
table 'test_report';

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

#pod =attr id
#pod
#pod The UUID of this report stored in standard hex string representation.
#pod
#pod =cut

primary_column 'id', {
    data_type => 'char',
    size => 36,
    is_nullable => 0,
};

#pod =attr created
#pod
#pod The ISO8601 date/time of when the report was inserted into the database.
#pod Will default to the current time.
#pod
#pod =cut

column created => {
    data_type => 'datetime',
    is_nullable => 0,
};

#pod =attr report
#pod
#pod The full JSON report.
#pod
#pod XXX: Describe the format a little and link to the main schema OpenAPI
#pod format on http://api.cpantesters.org
#pod
#pod =cut

column 'report', {
    data_type            => 'JSON',
    is_nullable          => 0,
    'serializer_class'   => 'JSON',
    'serializer_options' => { allow_blessed => 1, convert_blessed => 1 }
};

#pod =method new
#pod
#pod Create a new object. This is called automatically by the ResultSet
#pod object and should not be called directly.
#pod
#pod This is overridden to provide sane defaults for the C<id> and C<created>
#pod fields.
#pod
#pod =cut

sub new( $class, $attrs ) {
    $attrs->{report}{id} = $attrs->{id} ||= Data::UUID->new->create_str;
    $attrs->{report}{created} = $attrs->{created} ||= DateTime->now( time_zone => 'UTC' )->datetime . 'Z';
    return $class->next::method( $attrs );
};

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::TestReport - Raw reports as JSON documents

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );

    # Retrieve a row
    my $row = $schema->resultset( 'TestReport' )->first;

=head1 DESCRIPTION

This table contains the raw reports as submitted by the tester. From this,
the L<statistics table|CPAN::Testers::Schema::Result::Stats> is generated
by L<CPAN::Testers::Backend::ProcessReports>.

=head1 ATTRIBUTES

=head2 id

The UUID of this report stored in standard hex string representation.

=head2 created

The ISO8601 date/time of when the report was inserted into the database.
Will default to the current time.

=head2 report

The full JSON report.

XXX: Describe the format a little and link to the main schema OpenAPI
format on http://api.cpantesters.org

=head1 METHODS

=head2 new

Create a new object. This is called automatically by the ResultSet
object and should not be called directly.

This is overridden to provide sane defaults for the C<id> and C<created>
fields.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

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
