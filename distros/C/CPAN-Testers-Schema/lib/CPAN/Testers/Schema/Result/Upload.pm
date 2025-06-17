use utf8;
package CPAN::Testers::Schema::Result::Upload;
our $VERSION = '0.028';
# ABSTRACT: Information about uploads to CPAN

#pod =head1 SYNOPSIS
#pod
#pod     my $upload = $schema->resultset( 'Upload' )
#pod         ->search( dist => 'My-Dist', version => '0.01' )->first;
#pod
#pod     say $row->author . " released as " . $row->filename;
#pod     say scalar localtime $row->released;
#pod     if ( $row->type eq 'backpan' ) {
#pod         say "Deleted from CPAN";
#pod     }
#pod
#pod     my $new_upload = $schema->resultset( 'Upload' )->create({
#pod         type => 'cpan',
#pod         dist => 'My-Dist',
#pod         version => '1.001',
#pod         author => 'PREACTION',
#pod         filename => 'My-Dist-1.001.tar.gz',
#pod         released => 1366237867,
#pod     });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table contains information about uploads to CPAN, including who
#pod uploaded it, when it was uploaded, and when it was deleted (and thus
#pod only available to BackPAN).
#pod
#pod B<NOTE>: Since files can be deleted from PAUSE, and new files uploaded
#pod with the same name, distribution, and version, there may be duplicate
#pod C<< dist => version >> pairs in this table. This table does not
#pod determine which packages were authorized and indexed by PAUSE for
#pod installation by CPAN clients.
#pod
#pod This data is read directly from the local CPAN mirror by
#pod L<CPAN::Testers::Data::Uploads> and written to this table.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::Row>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';
__PACKAGE__->load_components( 'InflateColumn' );
table 'uploads';

#pod =attr uploadid
#pod
#pod The ID of this upload. Auto-generated.
#pod
#pod =cut

primary_column uploadid => {
    data_type => 'int',
    extra     => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
};

#pod =attr type
#pod
#pod This column indicates where the distribution is. It can be one of three values:
#pod
#pod =over 4
#pod
#pod =item cpan
#pod
#pod This distribution is on CPAN
#pod
#pod =item backpan
#pod
#pod This distribution has been deleted from CPAN and is only available on BackPAN
#pod
#pod =item upload
#pod
#pod This distribution has been reported via NNTP (nntp.perl.org group perl.cpan.uploads),
#pod but has not yet been seen on CPAN itself.
#pod
#pod =back
#pod
#pod =cut

column type => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

#pod =attr author
#pod
#pod The PAUSE ID of the user who uploaded this distribution.
#pod
#pod =cut

column author => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

#pod =attr dist
#pod
#pod The distribution name, parsed from the uploaded file's name using
#pod L<CPAN::DistnameInfo>.
#pod
#pod =cut

column dist => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

#pod =attr version
#pod
#pod The version of the distribution, parsed from the uploaded file's name
#pod using L<CPAN::DistnameInfo>.
#pod
#pod =cut

column version => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

#pod =attr filename
#pod
#pod The full file name uploaded to CPAN, without the author directory prefix.
#pod
#pod =cut

column filename => {
    data_type         => 'varchar',
    is_nullable       => 0,
};

#pod =attr released
#pod
#pod The date/time of the dist release. Calculated from the file's modified
#pod time, as synced by the CPAN mirror sync system, or from the upload
#pod notification message time from the NNTP group.
#pod
#pod Inflated from a UNIX epoch into a L<DateTime> object.
#pod
#pod =cut

column released => {
    data_type         => 'bigint',
    is_nullable       => 0,
    inflate_datetime  => 1,
};

__PACKAGE__->inflate_column(
    released => {
        deflate => sub( $value, $event ) {
            ref $value ? $value->epoch : $value
        },
        inflate => sub( $value, $event ) {
            DateTime->from_epoch(
                epoch => $value,
                time_zone => 'UTC',
                formatter => 'CPAN::Testers::Schema::DateTime::Formatter',
            );
        },
    },
);

unique_constraint(
  dist_version => [ qw/dist version/ ],
);

#pod =method report_metrics
#pod
#pod The linked report metrics rows for this distribution, a L<CPAN::Testers::Schema::ResultSet::Release>
#pod object.
#pod
#pod =cut

has_many report_metrics => 'CPAN::Testers::Schema::Result::Release',
    {
        'foreign.dist' => 'self.dist',
        'foreign.version' => 'self.version',
    };

#pod =method report_stats
#pod
#pod The linked report stats rows for this distribution, a L<CPAN::Testers::Schema::ResultSet::Stats>
#pod object.
#pod
#pod =cut

has_many report_stats => 'CPAN::Testers::Schema::Result::Stats',
    {
        'foreign.dist' => 'self.dist',
        'foreign.version' => 'self.version',
    };

package
    CPAN::Testers::Schema::DateTime::Formatter {
    sub format_datetime( $self, $dt ) {
        # XXX Replace this with DateTime::Format::ISO8601 when
        # https://github.com/jhoblitt/DateTime-Format-ISO8601/pull/2
        # is merged
        my $cldr = $dt->nanosecond % 1000000 ? 'yyyy-MM-ddTHH:mm:ss.SSSSSSSSS'
                 : $dt->nanosecond ? 'yyyy-MM-ddTHH:mm:ss.SSS'
                 : 'yyyy-MM-ddTHH:mm:ss';

        my $tz;
        if ( $dt->time_zone->is_utc ) {
            $tz = 'Z';
        }
        else {
            my $offset = $dt->time_zone->offset_for_datetime( $dt );
            $tz = DateTime::TimeZone->offset_as_string( $offset );
            substr $tz, 3, 0, ':';
        }

        return $dt->format_cldr( $cldr ) . $tz;
    }
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::Upload - Information about uploads to CPAN

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $upload = $schema->resultset( 'Upload' )
        ->search( dist => 'My-Dist', version => '0.01' )->first;

    say $row->author . " released as " . $row->filename;
    say scalar localtime $row->released;
    if ( $row->type eq 'backpan' ) {
        say "Deleted from CPAN";
    }

    my $new_upload = $schema->resultset( 'Upload' )->create({
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.001',
        author => 'PREACTION',
        filename => 'My-Dist-1.001.tar.gz',
        released => 1366237867,
    });

=head1 DESCRIPTION

This table contains information about uploads to CPAN, including who
uploaded it, when it was uploaded, and when it was deleted (and thus
only available to BackPAN).

B<NOTE>: Since files can be deleted from PAUSE, and new files uploaded
with the same name, distribution, and version, there may be duplicate
C<< dist => version >> pairs in this table. This table does not
determine which packages were authorized and indexed by PAUSE for
installation by CPAN clients.

This data is read directly from the local CPAN mirror by
L<CPAN::Testers::Data::Uploads> and written to this table.

=head1 ATTRIBUTES

=head2 uploadid

The ID of this upload. Auto-generated.

=head2 type

This column indicates where the distribution is. It can be one of three values:

=over 4

=item cpan

This distribution is on CPAN

=item backpan

This distribution has been deleted from CPAN and is only available on BackPAN

=item upload

This distribution has been reported via NNTP (nntp.perl.org group perl.cpan.uploads),
but has not yet been seen on CPAN itself.

=back

=head2 author

The PAUSE ID of the user who uploaded this distribution.

=head2 dist

The distribution name, parsed from the uploaded file's name using
L<CPAN::DistnameInfo>.

=head2 version

The version of the distribution, parsed from the uploaded file's name
using L<CPAN::DistnameInfo>.

=head2 filename

The full file name uploaded to CPAN, without the author directory prefix.

=head2 released

The date/time of the dist release. Calculated from the file's modified
time, as synced by the CPAN mirror sync system, or from the upload
notification message time from the NNTP group.

Inflated from a UNIX epoch into a L<DateTime> object.

=head1 METHODS

=head2 report_metrics

The linked report metrics rows for this distribution, a L<CPAN::Testers::Schema::ResultSet::Release>
object.

=head2 report_stats

The linked report stats rows for this distribution, a L<CPAN::Testers::Schema::ResultSet::Stats>
object.

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
