package Class::DBI::View::Having;

use strict;
use vars qw($VERSION);
$VERSION = 0.06;

sub setup_view {
    my($class, $sql) = @_;
    no strict 'refs';

    $class->set_sql('ViewHaving', "$sql %s");
    *{"$class\::retrieve_from_sql"} =  sub {
	my($real_class, $where, @vals) = @_;
	my $sth = $real_class->sql_ViewHaving("HAVING $where");
	return $real_class->sth_to_objects($sth, \@vals);
    };
    *{"$class\::retrieve_all"} = sub {
	my $real_class = shift;
	my $sth = $real_class->sql_ViewHaving('');
	$sth->execute();
	return $real_class->sth_to_objects($sth);
    };
}

1;
__END__

=head1 NAME

Class::DBI::View::SubQuery - View implementation using HAVING clause

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

See L<Class::DBI::View>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::View>

=cut
