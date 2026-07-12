package DBIO::Firebird::DateTime::Format;
# ABSTRACT: DateTime formatter for Firebird / InterBase

use strict;
use warnings;

use base 'DBIO::Storage::DateTimeFormat';

# No preferred_format_class: there is no maintained DateTime::Format::Firebird.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%d %H:%M:%S.%4N'); # %F %T
__PACKAGE__->datetime_format_pattern('%Y-%m-%d %H:%M:%S.%4N');
__PACKAGE__->date_parse_pattern('%Y-%m-%d');
__PACKAGE__->date_format_pattern('%Y-%m-%d');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::DateTime::Format - DateTime formatter for Firebird / InterBase

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
