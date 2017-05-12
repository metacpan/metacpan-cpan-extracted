package DBIx::DBH::SQLite;

use base qw(DBIx::DBH);
use Params::Validate qw( :all );

sub connect_data {
  my $class = shift;
  my %p = validate_with( 
            params => \@_,
            spec   => { 
                driver   => { type => SCALAR },
                dbname   => { type => SCALAR },
                attr     => { type => SCALAR | UNDEF, optional => 1 },
                user     => { type => SCALAR | UNDEF, optional => 1 },
                password => { type => SCALAR | UNDEF, optional => 1 },
                host     => { type => SCALAR | UNDEF, optional => 1 },
                port     => { type => SCALAR | UNDEF, optional => 1 },
		     },
             # allow_extra => 1,  
         );

  my $dsn = "DBI:$p{driver}:$p{dbname}";

  return ($dsn, $p{user}, $p{password}, $p{attr});

}


1;

=head1 NAME

  DBIx::DBH::SQLite - SQLite DBI database handle connection specifics.

=head1 connect()

dbname is probably the only one param you need. We pass through C<user>, C<password>,
and C<attr>, ignoring other attributes.

=head1 SEE ALSO

L<DBIx::DBH>
L<DBD::SQLite>

=head1 AUTHOR

Mark Stosberg, mark@summersault.com

=cut
