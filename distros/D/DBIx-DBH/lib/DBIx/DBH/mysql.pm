package DBIx::DBH::mysql ;

use base qw(DBIx::DBH);
use Params::Validate qw( :all );

@optional_mysql_ = qw(mysql_client_found_rows
		      mysql_compression
		      mysql_connect_timeout
		      mysql_read_default_file
		      mysql_read_default_group
		      mysql_socket
		      mysql_ssl
		      mysql_ssl_client_key
		      mysql_ssl_client_cert
		      mysql_ssl_ca_file
		      mysql_ssl_ca_path
		      mysql_ssl_cipher
		      mysql_local_infile);


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
		       map { $_ => 0 } (@optional_mysql_, @DBIx::DBH::attr)
		     } );

  my $dsn = "DBI:$p{driver}:$p{dbname}";
  foreach ( qw( host port ) ) {
    $dsn .= ";$_=$p{$_}" if (defined $p{$_});
  }


  foreach my $k ( grep { /^mysql/ } sort keys %p )
    {
      $dsn .= ";$k=$p{$k}";
    }


  ($dsn, $p{user}, $p{password}, $p{attr});

}


1;

=head1 NAME

  DBIx::DBH::mysql - mysql DBI database handle connection specifics.

=head1 connect()

L<DBIx::DBH> covered the options available to any database driver. Here we
list optional arguments supported by MySQL. Please read L<DBD::mysql> for 
details. All of these arguments apply to the DSN.

=over 4

=item * mysql_client_found_rows
=item * mysql_compression
=item * mysql_connect_timeout
=item * mysql_read_default_file
=item * mysql_read_default_group
=item * mysql_socket
=item * mysql_ssl
=item * mysql_ssl_client_key
=item * mysql_ssl_client_cert
-item * mysql_ssl_ca_file
-item * mysql_ssl_ca_path
-item * mysql_ssl_cipher
-item * mysql_local_infile


=back

=cut
