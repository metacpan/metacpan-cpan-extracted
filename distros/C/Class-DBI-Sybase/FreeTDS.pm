package Class::DBI::FreeTDS;

=head1 NAME

Class::DBI::FreeTDS - Extensions to Class::DBI for users of FreeTDS

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI::FreeTDS';

  Music::DBI->set_db('Main', 'dbi:Sybase:server=$server', 'username', 'password');

  package Artist;
  use base 'Music::DBI';
  __PACKAGE__->set_up_table('Artist');
  
  # ... see the Class::DBI documentation for details on Class::DBI usage

=head1 DESCRIPTION

This is an extension to Class::DBI that compensates for FreeTDS' current lack of placeholder support.

Instead of setting Class::DBI as your base class, use this.

=head1 BUGS

This is an ugly hack.

=head1 AUTHOR

Dan Sully E<lt>daniel@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::Sybase>, http://www.freetds.org/

=cut

use strict;
use base 'Class::DBI::Sybase';

use vars qw($VERSION);
$VERSION = '0.1';

# This is to fix MSSQL/TDS brokenness with placeholders. Ugh.
# Inline them instead. This overrides a Class::DBI method.
sub _do_search {
        my $proto = shift;
	my $search_type = shift || '';
	my @args  = @_;
        my $class = ref $proto || $proto;

        @args = %{ $args[0] } if ref $args[0] eq "HASH";
        my (@cols, @vals);
        my $search_opts = @args % 2 ? pop @args : {};
	my @frag = ();

        while (my ($col, $val) = splice @args, 0, 2) {
		$col = $class->find_column($col) or $class->croak("$col is not a column of $class");
                $val = $class->_deflated_column($col, $val) || next;

		push @frag, "$col $search_type $val";
        }

	my $frag = join(' AND ', @frag);
        $frag .= " ORDER BY $search_opts->{order_by}" if $search_opts->{order_by};

        return $class->sth_to_objects($class->sql_Retrieve($frag));
}

1;

__END__
