package DBIx::Cookbook::DBIC::Command::stored_proc;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;


# http://www.mail-archive.com/dbix-class@lists.scsys.co.uk/msg00706.html
# This URL shows that it is probably better to simply use DBI for that

# Otherwise dbh_do is possible as well
# http://search.cpan.org/~ribasushi/DBIx-Class-0.08120/lib/DBIx/Class/Storage/DBI.pm#dbh_do

=for future_record

[13:34] <@mst> metaperl_: right
[13:34] <@mst> metaperl_: and mysql's stored procs are a pile of shit
[13:34] <@mst> I'm sorry
[13:34] <@mst> I mistakenly assumed you were doing something stupid
[13:34] <@mst> in this case, it appears there is no non-stupid thing to do
[13:35] <@mst> well, except not use stored procedures on mysql at all
[13:35] <@mst> if you need stored procedures, get yourself a proper database
[13:35] <metaperl_> mst so what is problematic about MySQL's stored procs?
[13:35] <@mst> erm, the API is RETARDED
[13:35] <@mst> you're having to CALL and SELECT as two separate statements
[13:36] <@mst> also, they're not particularly stable and fail at a lot of edge cases
[13:36] <@mst> but really, if you're needing stored procedures at all
[13:36] <@mst> you have exceeded the capabilities of MySQL

=cut

=for comment

It is undesireable for manually developed code to reside in the same place as
automatically produced code.

As it stands, manually developed Resultset classes are expected to be in
::Schema::ResultSet, right next to ::Schema::Result.

So far, so good - the handwritten code is next to the automatic, not in the 
same directory with it.

But now we get to stored procedures. There is a stored procedure named
'film_in_stock' - 

    http://dev.mysql.com/doc/sakila/en/sakila.html#sakila-structure-procedures-film_in_stock

and I have a Result class for it named FilmInStock, which
is developed per the cookbook:

http://search.cpan.org/~ribasushi/DBIx-Class-0.08120/lib/DBIx/Class/Manual/Cookbook.pod#Using_database_functions_or_stored_procedures

But there are a few problems:

1 - it is hard to figure out how to get the Schema to load it.
2 - the one thing which clearly works is to put it in the same directory as the
auto-generated Result classes for the schema. But this is undesirable from a
maintenance standpoint - it is better to have custom code in a different 
directory than auto-generated code
3 - it does not work, and it spews a gigantic error message:

SELECT me.inventory_id FROM (
CALL film_in_stock(?,?,@count);

) me: 'NULL', 'NULL'
DBI Exception: DBD::mysql::st execute failed: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'CALL film_in_stock(NULL,NULL,@count);

) me' at line 2 [for Statement "SELECT me.inventory_id FROM (
CALL film_in_stock(?,?,@count);

) me" with ParamValues: 0=undef, 1=undef] at /usr/local/share/perl/5.10.0/DBIx/Class/Schema.pm line 1026
	DBIx::Class::Schema::throw_exception('DBIx::Cookbook::DBIC::Sakila=HASH(0x8cc58a8)', 'DBI Exception: DBD::mysql::st execute failed: You have an err...') called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage.pm line 123
	DBIx::Class::Storage::throw_exception('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', 'DBI Exception: DBD::mysql::st execute failed: You have an err...') called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 1059
	DBIx::Class::Storage::DBI::__ANON__('DBD::mysql::st execute failed: You have an error in your SQL ...', 'DBI::st=HASH(0x965e480)', undef) called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 1348
	DBIx::Class::Storage::DBI::_dbh_execute('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', 'DBI::db=HASH(0x961e880)', 'select', 'ARRAY(0x95fac60)', 'ARRAY(0x95fb6a0)', 'HASH(0x960c2f0)', 'ARRAY(0x95fb700)', undef, 'HASH(0x9724af8)', ...) called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 627
	DBIx::Class::Storage::DBI::dbh_do('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', '_dbh_execute', 'select', 'ARRAY(0x95fac60)', 'ARRAY(0x95fb6a0)', 'HASH(0x960c2f0)', 'ARRAY(0x95fb700)', undef, 'HASH(0x9724af8)', ...) called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 1358
	DBIx::Class::Storage::DBI::_execute('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', 'select', 'ARRAY(0x95fac60)', 'ARRAY(0x95fb6a0)', 'HASH(0x960c2f0)', 'ARRAY(0x95fb700)', undef, 'HASH(0x9724af8)', undef, ...) called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 1697
	DBIx::Class::Storage::DBI::_select('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', 'ARRAY(0x95fb6a0)', 'ARRAY(0x95fb700)', undef, 'HASH(0x95fb690)') called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI/Cursor.pm line 86
	DBIx::Class::Storage::DBI::Cursor::_dbh_next('DBIx::Class::Storage::DBI::mysql=HASH(0x950fe10)', 'DBI::db=HASH(0x961e880)', 'DBIx::Class::Storage::DBI::Cursor=HASH(0x960bfe0)') called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 637
	eval {...} called at /usr/local/share/perl/5.10.0/DBIx/Class/Storage/DBI.pm line 635

=cut

has 'film_id' => (
	       traits => [qw(Getopt)],
	       isa => "Int",
	       is  => "rw",
	       documentation => "film_id"
	      );

has 'store_id' => (
	       traits => [qw(Getopt)],
	       isa => "Int",
	       is  => "rw",
	       documentation => "store_id"
	      );


sub execute {
  my ($self, $opt, $args) = @_;

  my $rs = do {
    my $where = {};
    my $attr  = { bind => [ $opt->{film_id}, $opt->{store_id} ] };
    $self->app->schema->resultset('FilmInStock')->search($where, $attr);
  };


  while (my $row = $rs->next) {
    use Data::Dumper;
    my %data = $row->get_columns;
    warn Dumper(\%data);
    
  }

}

1;
