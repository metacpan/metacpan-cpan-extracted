package BoardStreams::Exception;

use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw/ db_duplicate_error /;

our $VERSION = "v0.0.9";

sub db_duplicate_error {
    BoardStreams::Exception::DbError::Duplicate->throw;
}


package BoardStreams::Exception::DbError;

use Moo;
with 'Throwable';

our $VERSION = "v0.0.9";

has desc => (
    is       => 'ro',
    required => 1,
);


package BoardStreams::Exception::DbError::Duplicate;

use Moo;
extends 'BoardStreams::Exception::DbError';

our $VERSION = "v0.0.9";

has '+desc' => (
    default => 'Attempted to create row with duplicate key.'
);


1;
