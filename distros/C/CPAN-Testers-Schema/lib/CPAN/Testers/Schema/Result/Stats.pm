use utf8;
package CPAN::Testers::Schema::Result::Stats;
our $VERSION = '0.028';
# ABSTRACT: The basic statistics information extracted from test reports

#pod =head1 SYNOPSIS
#pod
#pod     my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );
#pod
#pod     # Retrieve a row
#pod     my $row = $schema->resultset( 'Stats' )->first;
#pod     # pass from doug@example.com (Doug Bell) using Perl 5.20.1 on darwin
#pod     say sprintf "%s from %s using Perl %s on %s",
#pod         $row->state,
#pod         $row->tester,
#pod         $row->perl,
#pod         $row->osname;
#pod
#pod     # Create a new row
#pod     my %new_row_data = (
#pod         state => 'fail',
#pod         guid => '00000000-0000-0000-0000-000000000000',
#pod         tester => 'doug@example.com (Doug Bell)',
#pod         postdate => '201608',
#pod         dist => 'My-Dist',
#pod         version => '0.001',
#pod         platform => 'darwin-2level',
#pod         perl => '5.22.0',
#pod         osname => 'darwin',
#pod         osvers => '10.8.0',
#pod         fulldate => '201608120401',
#pod         type => 2,
#pod         uploadid => 287102,
#pod     );
#pod     my $new_row = $schema->resultset( 'Stats' )->insert( \%new_row_data );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table (C<cpanstats> in the database) hold the basic, vital statistics
#pod extracted from test reports. This data is used to generate reports for the
#pod web application and web APIs.
#pod
#pod See C<ATTRIBUTES> below for the full list of attributes.
#pod
#pod This data is built from the Metabase by the L<CPAN::Testers::Data::Generator>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::Row>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';
use Mojo::Util qw( html_unescape );
table 'cpanstats';

#pod =attr id
#pod
#pod The ID of the row. Auto-generated.
#pod
#pod =cut

primary_column 'id', {
    data_type         => 'int',
    extra             => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable       => 0,
};

#pod =attr guid
#pod
#pod The UUID of this report from the Metabase, stored in standard hex string
#pod representation.
#pod
#pod =cut

# Must be unique for foreign keys to work
column 'guid', {
    data_type   => 'char',
    is_nullable => 0,
    size        => 36,
};
unique_constraint guid => [qw( guid )];

#pod =attr state
#pod
#pod The state of the report. One of:
#pod
#pod =over 4
#pod
#pod =item C<pass>
#pod
#pod The tests passed and everything went well.
#pod
#pod =item C<fail>
#pod
#pod The tests ran but failed.
#pod
#pod =item C<na>
#pod
#pod This dist is incompatible with the tester's Perl or OS.
#pod
#pod =item C<unknown>
#pod
#pod The state could not be determined.
#pod
#pod =back
#pod
#pod C<invalid> reports, which are marked that way by dist authors when the
#pod problem is on the tester's machine, are handled by the L</type> field.
#pod
#pod =cut

column 'state', {
    data_type   => 'enum',
    extra       => { list => ['pass', 'fail', 'unknown', 'na'] },
    is_nullable => 0,
};

#pod =attr postdate
#pod
#pod A truncated date, consisting only of the year and month in C<YYYYMM>
#pod format.
#pod
#pod =cut

column 'postdate', {
    data_type      => 'mediumint',
    extra          => { unsigned => 1 },
    is_nullable    => 0,
};

#pod =attr tester
#pod
#pod The e-mail address of the tester who sent this report, optionally with
#pod the tester's name as a comment (C<doug@example.com (Doug Bell)>).
#pod
#pod =cut

column 'tester', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr dist
#pod
#pod The distribution that was tested.
#pod
#pod =cut

column 'dist', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr version
#pod
#pod The version of the distribution.
#pod
#pod =cut

column 'version', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr platform
#pod
#pod The Perl C<platform> string (from C<$Config{archname}>).
#pod
#pod =cut

column 'platform',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr perl
#pod
#pod The version of Perl that was used to run the tests (from
#pod C<$Config{version}>).
#pod
#pod =cut

column 'perl',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr osname
#pod
#pod The name of the operating system (from C<$Config{osname}>).
#pod
#pod =cut

column 'osname',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr osvers
#pod
#pod The version of the operating system (from C<$Config{osvers}>).
#pod
#pod =cut

column 'osvers',  {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 255,
};

#pod =attr fulldate
#pod
#pod The full date of the report, with hours and minutes, in C<YYYYMMDDHHNN>
#pod format.
#pod
#pod =cut

column 'fulldate', {
    data_type   => 'varchar',
    is_nullable => 0,
    size        => 32,
};

#pod =attr type
#pod
#pod A field that declares the status of this row. The only current
#pod possibilities are:
#pod
#pod =over 4
#pod
#pod =item 2 - This is a valid Perl 5 test report
#pod
#pod =item 3 - This report was marked invalid by a user
#pod
#pod =back
#pod
#pod =cut

column 'type', {
    data_type   => 'tinyint',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

#pod =attr uploadid
#pod
#pod The ID of the upload that created this dist. Related to the C<uploadid>
#pod field in the C<uploads> table (see
#pod L<CPAN::Testers::Schema::Result::Uploads>).
#pod
#pod =cut

column 'uploadid', {
    data_type   => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

#pod =method upload
#pod
#pod Get the related row in the `uploads` table. See L<CPAN::Testers::Schema::Result::Upload>.
#pod
#pod =cut

belongs_to upload => 'CPAN::Testers::Schema::Result::Upload' => 'uploadid';

#pod =method perl_version
#pod
#pod Get the related metadata about the Perl version this report is for. See
#pod L<CPAN::Testers::Schema::Result::PerlVersion>.
#pod
#pod =cut

might_have perl_version => 'CPAN::Testers::Schema::Result::PerlVersion' =>
    { 'foreign.version' => 'self.perl' };

#pod =method dist_name
#pod
#pod The name of the distribution that was tested.
#pod
#pod =cut

sub dist_name( $self ) {
    return $self->dist;
}

#pod =method dist_version
#pod
#pod The version of the distribution that was tested.
#pod
#pod =cut

sub dist_version( $self ) {
    return $self->version;
}

#pod =method lang_version
#pod
#pod The language and version the test was executed with
#pod
#pod =cut

sub lang_version( $self ) {
    return sprintf '%s v%s', 'Perl 5', $self->perl;
}

#pod =method platform
#pod
#pod The platform the test was run on
#pod
#pod =cut

sub platform( $self ) {
    return $self->get_inflated_column( 'platform' );
}

#pod =method grade
#pod
#pod The report grade. One of 'pass', 'fail', 'na', 'unknown'.
#pod
#pod =cut

sub grade( $self ) {
    return $self->state;
}

#pod =method tester_name
#pod
#pod The name of the tester who sent the report
#pod
#pod =cut

sub tester_name( $self ) {
    # The name could either be in quotes before the e-mail, or in
    # parentheses after.
    for my $re ( qr{"([^"]+)"}, qr{\(([^)]+)\)} ) {
        if ( $self->tester =~ $re ) {
            # And it may have high-byte characters HTML-escaped
            return html_unescape $1;
        }
    }
    # Can't find just the name, so send it all for now...
    return html_unescape $self->tester;
}

#pod =method datetime
#pod
#pod Get a L<DateTime> object for the date/time this report was generated.
#pod
#pod =cut

sub datetime( $self ) {
  my ( $y, $m, $d, $h, $n, $s ) = $self->fulldate =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?$/;
  return DateTime->new(
    year => $y,
    month => $m,
    day => $d,
    hour => $h,
    minute => $n,
    second => $s // 0,
  );
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::Stats - The basic statistics information extracted from test reports

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $schema = CPAN::Testers::Schema->connect( $dsn, $user, $pass );

    # Retrieve a row
    my $row = $schema->resultset( 'Stats' )->first;
    # pass from doug@example.com (Doug Bell) using Perl 5.20.1 on darwin
    say sprintf "%s from %s using Perl %s on %s",
        $row->state,
        $row->tester,
        $row->perl,
        $row->osname;

    # Create a new row
    my %new_row_data = (
        state => 'fail',
        guid => '00000000-0000-0000-0000-000000000000',
        tester => 'doug@example.com (Doug Bell)',
        postdate => '201608',
        dist => 'My-Dist',
        version => '0.001',
        platform => 'darwin-2level',
        perl => '5.22.0',
        osname => 'darwin',
        osvers => '10.8.0',
        fulldate => '201608120401',
        type => 2,
        uploadid => 287102,
    );
    my $new_row = $schema->resultset( 'Stats' )->insert( \%new_row_data );

=head1 DESCRIPTION

This table (C<cpanstats> in the database) hold the basic, vital statistics
extracted from test reports. This data is used to generate reports for the
web application and web APIs.

See C<ATTRIBUTES> below for the full list of attributes.

This data is built from the Metabase by the L<CPAN::Testers::Data::Generator>.

=head1 ATTRIBUTES

=head2 id

The ID of the row. Auto-generated.

=head2 guid

The UUID of this report from the Metabase, stored in standard hex string
representation.

=head2 state

The state of the report. One of:

=over 4

=item C<pass>

The tests passed and everything went well.

=item C<fail>

The tests ran but failed.

=item C<na>

This dist is incompatible with the tester's Perl or OS.

=item C<unknown>

The state could not be determined.

=back

C<invalid> reports, which are marked that way by dist authors when the
problem is on the tester's machine, are handled by the L</type> field.

=head2 postdate

A truncated date, consisting only of the year and month in C<YYYYMM>
format.

=head2 tester

The e-mail address of the tester who sent this report, optionally with
the tester's name as a comment (C<doug@example.com (Doug Bell)>).

=head2 dist

The distribution that was tested.

=head2 version

The version of the distribution.

=head2 platform

The Perl C<platform> string (from C<$Config{archname}>).

=head2 perl

The version of Perl that was used to run the tests (from
C<$Config{version}>).

=head2 osname

The name of the operating system (from C<$Config{osname}>).

=head2 osvers

The version of the operating system (from C<$Config{osvers}>).

=head2 fulldate

The full date of the report, with hours and minutes, in C<YYYYMMDDHHNN>
format.

=head2 type

A field that declares the status of this row. The only current
possibilities are:

=over 4

=item 2 - This is a valid Perl 5 test report

=item 3 - This report was marked invalid by a user

=back

=head2 uploadid

The ID of the upload that created this dist. Related to the C<uploadid>
field in the C<uploads> table (see
L<CPAN::Testers::Schema::Result::Uploads>).

=head1 METHODS

=head2 upload

Get the related row in the `uploads` table. See L<CPAN::Testers::Schema::Result::Upload>.

=head2 perl_version

Get the related metadata about the Perl version this report is for. See
L<CPAN::Testers::Schema::Result::PerlVersion>.

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

=head2 tester_name

The name of the tester who sent the report

=head2 datetime

Get a L<DateTime> object for the date/time this report was generated.

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
