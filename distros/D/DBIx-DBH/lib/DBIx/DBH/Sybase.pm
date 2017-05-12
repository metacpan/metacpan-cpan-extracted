package DBIx::DBH::Sybase;

use base qw(DBIx::DBH);
use Params::Validate qw( :all );

my @optional_ = qw(
syb_show_sql
syb_show_eed
syb_err_handler
syb_flush_finish
syb_dynamic_supported
syb_chained_txn
syb_quoted_identifier
syb_rowcount
syb_do_proc_status
syb_use_bin_0x
syb_binary_images
syb_oc_version
syb_server_version
syb_server_version_string
syb_failed_db_fatal
syb_no_child_con
syb_bind_empty_string_as_null
syb_cancel_request_on_error
syb_date_fmt
);

sub connect_data {

  my $class = shift;

  my %p = @_;

  %p = validate( @_, { driver => { type => SCALAR },
		       dbname => { type => SCALAR},
		       database => { type => SCALAR | UNDEF, 
				     optional => 1},
		       user => { type => SCALAR | UNDEF,
				 optional => 1 },
		       password => { type => SCALAR | UNDEF,
				     optional => 1 },
		       host => { type => SCALAR | UNDEF,
				 optional => 1 },
		       maxConnect => { type => SCALAR | UNDEF,
				 optional => 1 },
		       language => { type => SCALAR | UNDEF,
				       optional => 1 },
		       charset => { type => SCALAR | UNDEF,
				       optional => 1 },
		       packetSize => { type => SCALAR | UNDEF,
				       optional => 1 },
		       interfaces => { type => SCALAR | UNDEF,
				       optional => 1 },
		       timeout => { type => SCALAR | UNDEF,
				       optional => 1 },
		       loginTimeout => { type => SCALAR | UNDEF,
				    optional => 1 },
		       scriptName  => { type => SCALAR | UNDEF,
				    optional => 1 },
		       hostname  => { type => SCALAR | UNDEF,
				    optional => 1 },
		       tdsLevel  => { type => SCALAR | UNDEF,
				    optional => 1 },
		       encryptPassword   => { type => SCALAR | UNDEF,
				    optional => 1 },
		       kerberos   => { type => SCALAR | UNDEF,
				    optional => 1 },

		       sslCAFile  => { type => SCALAR | UNDEF,
				    optional => 1 },
		       bulkLogin  => { type => SCALAR | UNDEF,
				    optional => 1 },
		       port => { type => SCALAR | UNDEF,
				 optional => 1 },
		     
		       map { $_ => 0 } (@optional_, @DBIx::DBH::attr)
		     } );

  my $dsn = "dbi:$p{driver}:server=$p{host}";

  # optional DSN configuration options. 
  foreach ( qw(port database maxConnect language charset packetSize interfaces timeout loginTimeout scriptName hostname tdsLevel encryptPassword kerberos sslCAFile bulkLogin)) 
  {
      $dsn .= ";$_=$p{$_}" if (defined $p{$_});
  }
  
  # attributes that get passed in via an anonymous hash to the connect routine.
  foreach my $k ( grep { /^syb_/ } sort keys %p ) 
  {
      $p{attr}{$k} = $p{$k};
  }
  
  ($dsn, $p{user}, $p{password}, $p{attr});

}



1;

=head1 NAME

  DBIx::DBH::Sybase - Sybase DBI database handle connection specifics.

=head1 connect()

L<DBIx::DBH> covered the options available to any database driver as 
specified in L<DBI>. Here we
list optional arguments supported by Sybase. Please read L<DBD::Sybase> for
details

=head2 DSN options

=over 4

=item * maxConnect

=item * language

=item * charset

=item * packetSize

=item * interfaces

=item * timeout

=item * loginTimeout

=item * scriptName

=item * hostname

=item * tdsLevel

=item * encryptPassword

=item * kerberos

=item * sslCAFile

=item * bulkLogin


=back

=head2 Database handle attributes

=over 4


=item * syb_show_sql

=item * syb_show_eed

=item * syb_err_handler

=item * syb_flush_finish

=item * syb_dynamic_supported

=item * syb_chained_txn

=item * syb_quoted_identifier

=item * syb_rowcount

=item * syb_do_proc_status

=item * syb_use_bin_0x

=item * syb_binary_images

=item * syb_oc_version

=item * syb_server_version

=item * syb_failed_db_fatal

=item * syb_no_child_con

=item * syb_bind_empty_string_as_null

=item * syb_cancel_request_on_error

=item * syb_date_fmt

=back

=head1 SEE_ALSO

L<DBD::Sybase> to see what all of these options do.

=cut
