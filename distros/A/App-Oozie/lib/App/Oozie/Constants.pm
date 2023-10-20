## no critic (RequireStrictDeclarations ProhibitUselessNoCritic)
package App::Oozie::Constants;
$App::Oozie::Constants::VERSION = '0.010';
use 5.014;
use strict;
use warnings;
use parent qw( Exporter );

use constant OOZIE_STATES_RERUNNABLE => qw(
    KILLED
    SUSPENDED
    FAILED
);

use constant OOZIE_STATES_RUNNING => qw(
    RUNNING
    SUSPENDED
    PREP
);

use constant HDFS_COMPARE_SKIP_FILES => qw(
    .deployment
);

use constant SHORTCUT_METHODS => qw(
    today
    tomorrow
    yesterday
);

use constant {
    DATE_PATTERN                            => '%Y-%m-%d',
    DEFAULT_CLUSTER_NAME                    => 'MyCluster',
    DEFAULT_END_DATE_DAYS                   => 180,
    DEFAULT_HDFS_WF_PATH                    => '/oozie_wfs',
    DEFAULT_META_FILENAME                   => 'meta.yml',
    DEFAULT_NAMENODE_RPC_PORT               => 8020,
    DEFAULT_START_DATE_DAY_FRAME            => 7,
    DEFAULT_TIMEOUT                         => 60 * 3,
    DEFAULT_TZ                              => 'CET',
    DEFAULT_WEBHDFS_PORT                    => 14000,
    EMPTY_STRING                            => q{},
    FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES => 2,
    RE_LINEAGE_DATA_ITEM                    => qr{
        \A
            hive     # Data source type
            [/]      # Separator
            [\w^.]+  # Database name
            [.]      # Separator
            [\w^.]+  # Table name
        \z
    }xms,
    RE_OOZIE_ID => qr{
        [0-9]+     -
        [0-9]+     -
        oozie-oozi -
    }xms,
    SPACE_CHAR      => q{ },
    VALID_JOB_TYPES => [qw(
        bundle
        coord
        wf
    )],
    TEMPLATE_DEFINE_VAR       => q{%s='%s'},
    WEBHDFS_CREATE_CHUNK_SIZE => 1024**1024 * 2,

};

our @EXPORT_OK = qw(
    DATE_PATTERN
    DEFAULT_CLUSTER_NAME
    DEFAULT_END_DATE_DAYS
    DEFAULT_HDFS_WF_PATH
    DEFAULT_META_FILENAME
    DEFAULT_NAMENODE_RPC_PORT
    DEFAULT_START_DATE_DAY_FRAME
    DEFAULT_TIMEOUT
    DEFAULT_TZ
    DEFAULT_WEBHDFS_PORT
    EMPTY_STRING
    FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES
    HDFS_COMPARE_SKIP_FILES
    OOZIE_STATES_RERUNNABLE
    OOZIE_STATES_RUNNING
    RE_LINEAGE_DATA_ITEM
    RE_OOZIE_ID
    SHORTCUT_METHODS
    SPACE_CHAR
    TEMPLATE_DEFINE_VAR
    VALID_JOB_TYPES
    WEBHDFS_CREATE_CHUNK_SIZE
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Constants

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use App::Oozie::Constants qw( DEFAULT_CLUSTER_NAME );
    printf 'Default cluster name is %s', DEFAULT_CLUSTER_NAME;

=head1 DESCRIPTION

Internal constants.

=head1 NAME

App::Oozie::Constants - Internal constants.

=head1 Constants

=head2 DATE_PATTERN

=head2 DEFAULT_CLUSTER_NAME

=head2 DEFAULT_END_DATE_DAYS

=head2 DEFAULT_HDFS_WF_PATH

=head2 DEFAULT_META_FILENAME

=head2 DEFAULT_NAMENODE_RPC_PORT

=head2 DEFAULT_START_DATE_DAY_FRAME

=head2 DEFAULT_TIMEOUT

=head2 DEFAULT_TZ

=head2 DEFAULT_WEBHDFS_PORT

=head2 EMPTY_STRING

=head2 FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES

=head2 HDFS_COMPARE_SKIP_FILES

=head2 OOZIE_STATES_RERUNNABLE

=head2 OOZIE_STATES_RUNNING

=head2 RE_LINEAGE_DATA_ITEM

=head2 RE_OOZIE_ID

=head2 SHORTCUT_METHODS

=head2 SPACE_CHAR

=head2 TEMPLATE_DEFINE_VAR

=head2 VALID_JOB_TYPES

=head2 WEBHDFS_CREATE_CHUNK_SIZE

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
