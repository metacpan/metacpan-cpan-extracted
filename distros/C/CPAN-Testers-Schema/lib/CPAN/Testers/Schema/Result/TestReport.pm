package CPAN::Testers::Schema::Result::TestReport;
our $VERSION = '0.028';
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
use JSON::MaybeXS;
use Mojo::Util qw( html_unescape );
table 'test_report';

__PACKAGE__->load_components('InflateColumn::DateTime', 'Core');

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
#pod The JSON report also contains a C<created> field. This is the date/time
#pod that the report was created on the reporter's machine.
#pod
#pod =cut

column created => {
    data_type => 'datetime',
    is_nullable => 0,
    format_datetime => 1,
};

#pod =attr report
#pod
#pod The full JSON report.
#pod
#pod XXX: Describe the format a little and link to the main schema OpenAPI
#pod format on http://api.cpantesters.org
#pod
#pod The serializer for this column will convert UTF-8 characters into their
#pod corresponding C<\u####> escape sequence, so this column is safe for
#pod tables with Latin1 encoding.
#pod
#pod =cut

column 'report', {
    data_type            => 'JSON',
    is_nullable          => 0,
};

my %JSON_OPT = (
    allow_blessed => 1,
    convert_blessed => 1,
    ascii => 1,
);
__PACKAGE__->inflate_column( report => {
    deflate => sub {
        my ( $ref, $row ) = @_;
        JSON::MaybeXS->new( %JSON_OPT )->encode( $ref );
    },
    inflate => sub {
        my ( $raw, $row ) = @_;
        JSON::MaybeXS->new( %JSON_OPT )->decode(
            $raw =~ s/([\x{0000}-\x{001f}])/sprintf "\\u%v04x", $1/reg
        );
    },
} );

#pod =method new
#pod
#pod Create a new object. This is called automatically by the ResultSet
#pod object and should not be called directly.
#pod
#pod This is overridden to provide sane defaults for the C<id> and C<created>
#pod fields.
#pod
#pod B<NOTE:> You should not supply a C<created> unless you are creating
#pod reports in the past. Reports created in the past will be hidden from
#pod many feeds, and may cause failures to not be reported to authors.
#pod
#pod =cut

sub new( $class, $attrs ) {
    $attrs->{report}{id} = $attrs->{id} ||= Data::UUID->new->create_str;
    $attrs->{created} ||= DateTime->now( time_zone => 'UTC' );
    $attrs->{report}{created} ||= $attrs->{created}->datetime . 'Z';
    return $class->next::method( $attrs );
};

#pod =method upload
#pod
#pod     my $upload = $row->upload;
#pod
#pod Get the associated L<CPAN::Testers::Schema::Result::Upload> object for
#pod the distribution tested by this test report.
#pod
#pod =cut

sub upload( $self ) {
    my ( $dist, $vers ) = $self->report->{distribution}->@{qw( name version )};
    return $self->result_source->schema->resultset( 'Upload' )
        ->search({ dist => $dist, version => $vers })->single;
}

#pod =method dist_name
#pod
#pod The name of the distribution that was tested.
#pod
#pod =cut

sub dist_name( $self ) {
    return $self->report->{distribution}{name};
}

#pod =method dist_version
#pod
#pod The version of the distribution that was tested.
#pod
#pod =cut

sub dist_version( $self ) {
    return $self->report->{distribution}{version};
}

#pod =method lang_version
#pod
#pod The language and version the test was executed with
#pod
#pod =cut

sub lang_version( $self ) {
    return sprintf '%s v%s',
        $self->report->{environment}{language}->@{qw( name version )};
}

#pod =method platform
#pod
#pod The platform the test was run on
#pod
#pod =cut

sub platform( $self ) {
    return join ' ', $self->report->{environment}{language}{archname};
}

#pod =method grade
#pod
#pod The report grade. One of 'pass', 'fail', 'na', 'unknown'.
#pod
#pod =cut

sub grade( $self ) {
    return $self->report->{result}{grade};
}

#pod =method text
#pod
#pod The full text of the report, either from the phased sections or the
#pod "uncategorized" section.
#pod
#pod =cut

my @output_phases = qw( configure build test install );
sub text( $self ) {
    return $self->report->{result}{output}{uncategorized}
        || join "\n\n", grep defined, $self->report->{result}{output}->@{ @output_phases };
}

#pod =method tester_name
#pod
#pod The name of the tester who sent the report
#pod
#pod =cut

sub tester_name( $self ) {
    return html_unescape $self->report->{reporter}{name};
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::TestReport - Raw reports as JSON documents

=head1 VERSION

version 0.028

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

The JSON report also contains a C<created> field. This is the date/time
that the report was created on the reporter's machine.

=head2 report

The full JSON report.

XXX: Describe the format a little and link to the main schema OpenAPI
format on http://api.cpantesters.org

The serializer for this column will convert UTF-8 characters into their
corresponding C<\u####> escape sequence, so this column is safe for
tables with Latin1 encoding.

=head1 METHODS

=head2 new

Create a new object. This is called automatically by the ResultSet
object and should not be called directly.

This is overridden to provide sane defaults for the C<id> and C<created>
fields.

B<NOTE:> You should not supply a C<created> unless you are creating
reports in the past. Reports created in the past will be hidden from
many feeds, and may cause failures to not be reported to authors.

=head2 upload

    my $upload = $row->upload;

Get the associated L<CPAN::Testers::Schema::Result::Upload> object for
the distribution tested by this test report.

=head2 dist_name

The name of the distribution that was tested.

=head2 dist_version

The version of the distribution that was tested.

=head2 lang_version

The language and version the test was executed with

=head2 platform

The platform the test was run on

=head2 grade

The report grade. One of 'pass', 'fail', 'na', 'unknown'.

=head2 text

The full text of the report, either from the phased sections or the
"uncategorized" section.

=head2 tester_name

The name of the tester who sent the report

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

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
