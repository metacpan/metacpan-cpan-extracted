package Class::DBI::View::TemporaryTable;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

sub setup_view {
    my($class, $sql, %args) = @_;
    for my $method (qw(sql_Retrieve sql_RetrieveAll)) {
	_set_temporary_table($class, $method, $sql, %args);
    }

}

sub _set_temporary_table {
    my($pkg, $method, $sql, %args) = @_;
    no strict 'refs';
    *{"$pkg\::$method"} = sub {
	my $class = shift;
	my $temp_table = $class->table_alias;
	if ($args{cache_for_session}) {
	    $class->db_Main->do("CREATE TEMPORARY TABLE IF NOT EXISTS $temp_table $sql");
	}
	else {
	    $class->db_Main->do("DROP TABLE IF EXISTS $temp_table");
	    $class->db_Main->do("CREATE TEMPORARY TABLE $temp_table $sql");
	}
	$class->table($temp_table);
	return $class->${\"$class\::SUPER::$method"}(@_);
    };
}

1;
__END__

=head1 NAME

Class::DBI::View::TemporaryTable - View implementation using temporary table

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

See L<Class::DBI::View>

=head1 NOTES

This module currently support only MySQL database.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::View>

=cut
