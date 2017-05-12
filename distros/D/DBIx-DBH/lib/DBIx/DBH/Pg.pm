package DBIx::DBH::Pg;

use base qw(DBIx::DBH);
use Params::Validate qw( :all );

my @optional_pg_ = qw(pg_enable_utf8 
		      pg_auto_escape 
		      pg_bool_tf);

sub connect_data {

  my $class = shift;

  my %p = @_;

  %p = validate( @_, { driver => { type => SCALAR },
		       dbname => { type => SCALAR },
		       user => { type => SCALAR | UNDEF,
				 optional => 1 },
		       password => { type => SCALAR | UNDEF,
				     optional => 1 },
		       host => { type => SCALAR | UNDEF,
				 optional => 1 },
		       port => { type => SCALAR | UNDEF,
				 optional => 1 },
		       options => { type => SCALAR | UNDEF,
				    optional => 1 },
		       tty => { type => SCALAR | UNDEF,
				optional => 1 },
		       map { $_ => 0 } (@optional_pg_, @DBIx::DBH::attr)
		     } );

  my $dsn = "dbi:$p{driver}:dbname=$p{dbname}";
  foreach ( qw( host port options tty ) ) {
    $dsn .= ";$_=$p{$_}" if (defined $p{$_});
  }

  foreach my $k ( grep { /^pg_/ } sort keys %p ) {
    $p{attr}{$k} = $p{$k};
  }

  ($dsn, $p{user}, $p{password}, $p{attr});

}



1;

=head1 NAME

  DBIx::DBH::Pg - Pg DBI database handle connection specifics.

=head1 connect()

L<DBIx::DBH> covered the options available to any database driver as 
specified in L<DBI>. Here we
list optional arguments supported by Pg. Please read L<DBD::Pg> for
details

=head2 DSN options

=over 4

=item * options

=item * tty

=back

=head2 Database handle attributes

=over 4

=item * pg_auto_escape

=item * pg_enable_utf8

=item * pg_bool_tf

=back

=cut
