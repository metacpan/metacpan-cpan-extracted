package DBIx::BulkLoader::Mysql;

use strict;
use warnings;

our $VERSION = '1.006';

use constant key_count=>0;
use constant key_single_insert=>1;
use constant key_bulk_insert=>2;
use constant key_buffer=>3;
use constant key_sql_insert=>4;
use constant key_sql_columns=>5;
use constant key_bulk_sql=>6;
use constant key_single_sql=>7;
use constant key_data=>8;
use constant key_placeholder_count=>9;


# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBIx::BulkLoader::Mysql - Perl extension for mysql bulk loading

=head1 SYNOPSIS

  use DBIx::BulkLoader::Mysql;

  # non repeating portion of the insert statement
  my $insert='insert into bulk_insert (col_a,col_b,col_c) values ';

  # repeating portion of the insert statement
  my $placeholders='(?,?,?)';

  # how many rows to buffer until insert is called
  my $bulk_insert_count=5;

  # db connection
  my $dbh=DBI->connect(db connection info here);
  my $placeholder_count=3;

  my ($bulk,$error)=DBIx::BulkLoader::Mysql->new(
  		dbh=>$dbh
		,sql_insert=>$insert
		,placeholders=>$placeholders
   );
   die $error unless $bulk;

   for( 1 .. 50 ) {
     $bulk->insert(qw(a b c));
   }
   # inserted 50 rows at once

   $bulk->insert(qw(l l x));
   # inserted 0 rows

   $bulk->insert(qw(l l x));
   # inserted 0 rows

   $bulk->flush;
   # inserted 2 rows 1 at a time

=head1 DESCRIPTION

Simple buffering bulk loader interface for mysql.

=head2 EXPORT

None.

=head2 OO Methods

This section covers the OO methods for this package.

=over 4

=item * my ($bulk,$error)=DBIx::BulkLoader::Mysql->new(%hash);

Package constructor.

	$bulk is undef on error
	$error explains why $bulk is undef

Constructor options

                dbh=>$dbh
		 Sets the DBH object

                sql_insert=>$insert
		 Contains the body of the sql statement minus the
		 placeholder segment.

                placeholders=>$placeholders
		 Placeholder segment of the sql statement

                placeholder_count=>3
		 Optional argument
		  If you get strange insert counts or dbi bails
		  set this option manually

                bulk_insert_count=>50
		 Optional argument
		  Sets the number of rows to buffer for insert.

                prepare_args=>{}
		 Optional argument
		  Arguments to be passed to $dbh->prepare
		  See DBD::mysql

=cut

sub new {
	my ($class,%hash)=@_;
	my $s=bless [],$class;
	$s->[key_data]=[];
	$hash{bulk_insert_count}=$hash{bulk_insert_count} 
		? $hash{bulk_insert_count} : 50;

	# stop here if we have some bad arguments
	return (undef,'placeholders=>"" not set!') unless $hash{placeholders};
	return (undef,'sql_insert=>"" not set!') unless $hash{sql_insert};
	return (undef,'dbh=>$dbh not set!') unless $hash{dbh};
	unless($hash{placeholder_count}) {
	  for( $hash{placeholders}=~ /\?/g){ 
	   $hash{placeholder_count}++
	  }
	}
	$s->[key_placeholder_count]=$hash{placeholder_count} ;

	$s->[key_buffer]=
		$hash{placeholder_count} * $hash{bulk_insert_count};

	my $prep_args=$hash{prepare_args} ? $hash{prepare_args} : ({});
	my $single=join ' ',$hash{sql_insert},$hash{placeholders};

	# run the prepare statement
	$s->[key_single_sql]=$single;
	$s->[key_single_insert]=eval {
		$hash{dbh}->prepare(
			$single
			,$hash{prepare_args}
		);
	};
	return undef,"failed to prepare: $single" if $@;
	

	my @placeholders;
	for(1 .. $hash{bulk_insert_count}) { 
		push @placeholders,$hash{placeholders};
	}
	my $bulk=join(' ',$hash{sql_insert},
		join(', ',@placeholders)
	);

	return undef,"failed to prepare: $bulk" if $@;
	$s->[key_bulk_sql]=$bulk;
	$s->[key_bulk_insert]=eval {
		$hash{dbh}->prepare(
			$bulk
			,$hash{prepare_args}
		);
	};
	
	$s,undef;
}

=item * $bulk->flush;

Empties the placeholder buffer

=cut

sub flush () {
	my ($s)=@_;
	my $row=$s->[key_data];
	while(my @single=splice(@$row,0, $s->get_placeholder_count)) {
		$s->get_prepared_single_sth->execute(@single);
	}
}

sub DESTROY { 
	@{$_[0]}=() 
}

=item * $bulk->insert($x,$y,$z);

Inserts the placeholder arguments onto the buffer stack. This does not cause an insert, unless the total number of rows is the same as the constructor call "bulk_insert_count=>50".

=cut

sub insert {
	my ($s,@data)=@_;
	my $row=$s->[key_data];
	push @$row,@data;
	if((1 + $#$row)==$s->get_buffer_size) {
		$s->get_prepared_bulk_sth->execute(@$row);
		@$row=();
	}

}

=item * my $columns=$bulk->get_placeholder_count;

Gets the total number of column placeholders.

=cut

sub get_placeholder_count () { $_[0]->[key_placeholder_count] }

=item * my $buffer_size=$bulk->get_buffer_size;

Gets the total size of the array used for insert.

=cut

sub get_buffer_size () { $_[0]->[key_buffer] }

=item * my $sql_single=$bulk->single_sql;

Gets the raw sql statement used for single row inserts.

=cut

sub single_sql() { $_[0]->[key_single_sql] }

=item * my $bulk_sql=$bulk->bulk_sql;

Gets the raw sql statement used for bulk row inserts.

=cut

sub bulk_sql() { $_[0]->[key_bulk_sql] }

=item * my $single_sth=$bulk->get_prepared_single_sth;

Gets the prepared statement handle for single row inserts.

=cut

sub get_prepared_single_sth () { $_[0]->[key_single_insert] }

=item * my $bulk_sth=$bulk->get_prepared_bulk_sth;

Gets the prepared statement handle for bulk row inserts.

=cut

sub get_prepared_bulk_sth () { $_[0]->[key_bulk_insert] }

=item * my @buffer=$bulk->get_buffered_data;

Returns a list containing the current buffered data

=cut

sub get_buffered_data () { @{$_[0]->[key_data]} }

=back
	
=head1 SEE ALSO

DBI, DBD::mysql

=head1 Source Forge Project

If you find this software usefil please donate to the Source Forge Project.

L<DBIx BulkLoader Mysql|https://sourceforge.net/projects/dbix-bulkloader/>

=head1 AUTHOR

Michael Shipper

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Michael Shipper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

######################################
#
# End of the package
1;
__END__
