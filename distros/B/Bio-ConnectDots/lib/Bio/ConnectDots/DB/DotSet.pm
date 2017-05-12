package Bio::ConnectDots::DB::DotSet;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use DBI;
use Class::AutoClass;
use Bio::ConnectDots::DotSet;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(db);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
Class::AutoClass::declare(__PACKAGE__);

# store one DotSet.  store db_id in object
sub put {
  my($class,$dotset)=@_;
  return if $dotset->db_id;	# object is already in database
  my $db=$dotset->db;
  $class->throw("Cannot put data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot put data: database does not exist") unless $db->exists;
  my $name=$dotset->name;
  my $dbh=$db->dbh;
  my $sql=qq(INSERT INTO dotset (name) VALUES ('$name'));
  $db->do_sql($sql);
  my $db_id=$dbh->selectrow_array(qq(SELECT MAX(dotset_id) FROM dotset));
  $dotset->db_id($db_id);
  $dotset;
}
# fetch one DotSet.  return object
sub get {
  my($class,$dotset)=@_;
  return $dotset if $dotset->db_id; # already fetched
  my $db=$dotset->db;
  $class->throw("Cannot get data: database is not connected") unless $db->is_connected;
  $class->throw("Cannot get data: database does not exist") unless $db->exists;
  my $name=$dotset->name;
  my $dbh=$db->dbh;
  my $sql=qq(SELECT name,dotset_id FROM dotset WHERE name='$name');
  my ($name,$db_id)=$dbh->selectrow_array($sql);
  return undef unless defined $name;
  return new Bio::ConnectDots::DotSet(-name=>$name,-db_id=>$db_id,-db=>$db);
}

1;
