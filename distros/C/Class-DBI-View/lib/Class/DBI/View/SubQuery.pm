package Class::DBI::View::SubQuery;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

sub setup_view {
    my($class, $sql) = @_;
    $class->table("($sql)");	# Sweet
}

1;
__END__

=head1 NAME

Class::DBI::View::SubQuery - View implementation using sub-selects

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

See L<Class::DBI::View>

=head1 NOTES

This module can be used with a database which supports
sub-selects. You know you can usually use VIEWs in such databases
which supports sub-selects, but at the time of this writing, MySQL 4.1
beta supports sub-selects, but no VIEWs.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::View>

=cut
