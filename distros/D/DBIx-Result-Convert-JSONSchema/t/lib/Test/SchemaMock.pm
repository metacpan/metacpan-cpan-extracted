package Test::SchemaMock;
use Moo;

use Carp;
use DBD::Mock;
use DBI;
use Types::Standard qw/ :all /;

use Test::Schema;


has mock_data => (
    is => 'lazy',
    isa => HashRef,
);

has schema => (
    is      => 'lazy',
    isa     => InstanceOf['DBIx::Class::Schema'],
    default => sub {
        my ( $self ) = @_;
        return Test::Schema->connect( sub { $self->dbh } );
    },
);

has dbh => (
    is      => 'lazy',
    isa     => InstanceOf['DBI'],
    default => sub {
        my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
            or croak "Cannot create handle: $DBI::errstr\n";
        return $dbh;
    },
);

sub _build_mock_data {
    my ( $self ) = @_;

    return {
        timestamp => {
            minLength => 26,
            type => 'string',
            pattern => '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$',
            maxLength => 26,
        },
        char => {
            type => 'string',
            maxLength => 1,
            minLength => 0,
        },
        bit => {
            maximum => 1,
            minimum => 0,
            type => 'integer',
        },
        int => {
            maximum => 2147483647,
            minimum => '-2147483648',
            type => 'integer',
        },
        text => {
            minLength => 0,
            type => 'string',
            maxLength => 65535,
        },
        smallint => {
            maximum => 32767,
            type => 'integer',
            minimum => -32768,
        },
        decimal => {
            type => 'number',
        },
        time => {
            minLength => 8,
            maxLength => 8,
            type => 'string',
            pattern => '^\\d{2}:\\d{2}:\\d{2}$',
        },
        tinyint => {
            minimum => -128,
            type => 'integer',
            maximum => 127,
        },
        varbinary => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        datetime => {
            minLength => 19,
            maxLength => 19,
            type => 'string',
            pattern => '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$',
        },
        bigint => {
            type => 'integer',
            minimum => '-9.22337203685478e+18',
            maximum => '9.22337203685478e+18',
        },
        year => {
            minLength => 4,
            maxLength => 4,
            pattern => '^\\d{4}$',
            type => 'string',
        },
        json => {
            type => 'object',
        },
        tinytext => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        float => {
            type => 'number',
        },
        mediumtext => {
            minLength => 0,
            type => 'string',
            maxLength => 16777215,
        },
        enum => {
            type => 'enum',
            enum => [
                'X',
                'Y',
                'Z',
            ],
        },
        date => {
            minLength => 10,
            maxLength => 10,
            pattern => '^\\d{4}-\\d{2}-\\d{2}$',
            type => 'string',
        },
        integer => {
            maximum => 2147483647,
            minimum => '-2147483648',
            type => 'integer',
        },
        binary => {
            type => 'string',
            maxLength => 1,
            minLength => 0,
        },
        set => {
            enum => [
                'X',
                'Y',
                'Z',
            ],
            type => 'enum',
        },
        varchar => {
            maxLength => 255,
            type => 'string',
            minLength => 0,
        },
        blob => {
            minLength => 0,
            maxLength => 65535,
            type => 'string',
        },
        longtext => {
            maxLength => 16777215,
            type => 'string',
            minLength => 0,
        },
        double => {
            type => 'number',
        },
        numeric => {
            type => 'number',
        },
        mediumint => {
            minimum => -8388608,
            type => 'integer',
            maximum => 8388607,
        },
    };
}

__PACKAGE__->meta->make_immutable;
