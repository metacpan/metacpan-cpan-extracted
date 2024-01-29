package Database::Abstraction::Error;

=head1 NAME

Database::Abstraction::Error - error object for the database abstraction layer

=cut

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Error qw(:try);

use base 'Error';

1;
