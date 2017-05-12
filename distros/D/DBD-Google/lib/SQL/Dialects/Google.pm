package SQL::Dialects::Google;

use strict;
use vars qw($VERSION);

$VERSION = 0.51;

=pod

=head1 NAME

 SQL::Dialects::Google -- Google config file for SQL::Parser

=head1 SYNOPSIS

See L<SQL::Parser>.

=head1 DESCRIPTION

This module defines the SQL syntax supported by DBD::Google.

=cut

sub get_config {
return <<EOC;
[VALID COMMANDS]
SELECT

[VALID COMPARISON OPERATORS]
=

[VALID DATA TYPES]
VARCHAR

[RESERVED WORDS]
EOC
}
1;
