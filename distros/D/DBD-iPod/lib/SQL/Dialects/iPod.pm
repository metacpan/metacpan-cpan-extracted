package SQL::Dialects::iPod;
use strict;
our $VERSION = '0.01';

=pod

=head1 NAME

 SQL::Dialects::iPod -- iPod config file for SQL::Parser

=head1 SYNOPSIS

See L<SQL::Parser>.

=head1 DESCRIPTION

This module defines the SQL syntax supported by DBD::iPod.
We allow only SELECT commands (iPod is read-only), and
comparison operators may be one of (=, E<lt>, E<gt>, E<lt>=,
E<gt>=, LIKE).

=cut

sub get_config {
return <<EOC;
[VALID COMMANDS]
SELECT

[VALID COMPARISON OPERATORS]
=
>
<
>=
<=
LIKE

[VALID DATA TYPES]

[RESERVED WORDS]
EOC
}

1;
