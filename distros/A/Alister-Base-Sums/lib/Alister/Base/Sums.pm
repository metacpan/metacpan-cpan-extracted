package Alister::Base::Sums;
use strict;
use vars qw($VERSION $TABLE_NAME $SQL_LAYOUT @ISA @EXPORT_OK %EXPORT_TAGS); #$sth1 $sth0
use Exporter;
use LEOCHARRE::Debug;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;
@EXPORT_OK = qw/sum_add sum_update sum_get sum_delete validate_argument_sum validate_argument_id table_reset_sums/;
%EXPORT_TAGS = ( all => \@EXPORT_OK );
@ISA = qw/Exporter/;
$TABLE_NAME = 'sums';
$SQL_LAYOUT ="CREATE TABLE $TABLE_NAME (
   id int(20) AUTO_INCREMENT PRIMARY KEY,
   sum varchar(32) NOT NULL UNIQUE );";


sub table_create_sums { _dbh_do_sql_layout( $_[0], $SQL_LAYOUT ) }
sub table_reset_sums { $_[0]->do("DROP TABLE IF EXISTS $TABLE_NAME"); table_create_sums($_[0]) }


sub _dbh_do_sql_layout {
   my ($dbh, $layout) = @_;

   $layout =~s/\t+| {2,}/ /g;
   
   for my $sql ( split( /\;/, $layout) ){
      $sql=~/\w/ or next;
      debug("layout [$sql]\n");
      debug('-');
      $dbh->do($sql) 
         or die($dbh->errstr);
   }
   debug("Done.");
   #$self->dbh->commit; should commit at script level instead
   1;
}


# reset


#*sum_add = \&_sum_add_mod;
*sum_add = \&_sum_add_original;



sub _sum_add_original {
   my $dbh = $_[0];
   my $sum = validate_argument_sum($_[1]) 
      or warn("Argument 2 to sum_add() must be a sum digest string")
      and return;


   # NOTE do NOT use REPLACE INTO, that works but it changes the sum_id
   # which is the whole keystone of this whole operation!
   my $sth = $dbh->prepare("INSERT INTO $TABLE_NAME (sum) VALUES (?)")
      or confess($dbh->errstr);
   
   local $sth->{RaiseError}; # stop dying if insert fails
   local $sth->{PrintError}; # stop telling if insert fails

   my $result = $sth->execute($sum);
   $sth->finish;

   !defined $result # then already in.. likely  
      and return (
         _dbh_fetch_one( $dbh, "SELECT id FROM $TABLE_NAME WHERE sum = ?", $sum)
            || die("Could not insert sum:'$sum', and could not fetch either! Something is wrong."));

   
    ($result eq '0E0')
      and confess("could not register sum:'$sum',".$dbh->errstr);
   
   defined wantarray 
      ? ( $dbh->last_insert_id( undef, undef, $TABLE_NAME, undef )
         || confess("can't get last insert id for sum table") )
      : 1;
}



sub sum_delete {
   my ($id, $sql, $dbh, $arg)=(undef,undef,$_[0], $_[1]);
   $arg or confess('missing arg');

   $sql =
      validate_argument_sum($arg) 
         ? "DELETE FROM $TABLE_NAME WHERE sum = ?" 
         : validate_argument_id($arg) 
            ? "DELETE FROM $TABLE_NAME WHERE id = ?"
            : confess("What is argument '$arg'? Not sum or id");
   
   my $sth = $dbh->prepare($sql) or die($dbh->errstr);
   my $affected = $sth->execute($arg);
   $sth->finish;
   return ( $affected eq '0E0' ? 0 : $affected );
}

sub sum_get { # MASTER
   my $dbh = $_[0];

   validate_argument_sum($_[1]) 
      ? _dbh_fetch_one( $dbh, "SELECT id FROM $TABLE_NAME WHERE sum = ?", $_[1] ) 
      : validate_argument_id($_[1]) 
         ? _dbh_fetch_one( $dbh, "SELECT sum FROM $TABLE_NAME WHERE id = ? LIMIT 1", $_[1] )
         : confess("Argument is not a sum or sum id '$_[1]'");
}

sub sum_update {
   # what if we try to change to a md5um that already exists!

   my ($dbh, $arg, $new_sum )= @_;

   # first thing.. the sum must be valid.
   validate_argument_sum($new_sum) or warn("argument is not a real sum: '$arg'") and return;

   no warnings;
   if ( validate_argument_sum($arg) ){
      my $sth = $dbh->prepare("UPDATE $TABLE_NAME SET sum = ? WHERE sum = ?");
      my $r = $sth->execute($new_sum, $arg);
      $sth->finish;     

      debug("result '$r'") if $r;
      return (($r and $r eq '0E0') ? 0 : $r);
   }

   elsif( validate_argument_id($arg) ){
      my $sth = $dbh->prepare("UPDATE $TABLE_NAME SET sum = ? WHERE id = ?");
      my $r = $sth->execute($new_sum, $arg);
      $sth->finish;
      debug("result '$r'") if $r;
      return (($r and $r eq '0E0') ? 0 : $r);

   }

   else {
      confess("Argument is neither sum or id");
   }
}



sub validate_argument_id { ( $_[0] and $_[0]=~/^\d+$/) ? $_[0] : undef } # because can't be '0' for an id
sub validate_argument_sum { ($_[0] and $_[0]=~/^[0-9a-f]{32}$/) ? $_[0] : undef } 


sub _dbh_fetch_one {
   my $dbh = shift;
   my $statement = shift;
   my @args = @_;
   
   my $sth     = $dbh->prepare($statement);
   my $result  = $sth->execute(@args); # dies if error
   
   if ($result eq '0E0'){ # would mean no results
      $sth->finish;
      return;
   }
   my $val = $sth->fetch->[0];
   $sth->finish;
   $val;
}





1;

__END__

# see lib/Alister/Base/Sums.pod

sub _sum_add_mod { # slightly faster, might not be worth the code maintenance
   my $dbh = $_[0];
   my $sum = validate_argument_sum($_[1]) 
      or warn("Argument 2 to sum_add() must be a sum digest string")
      and return;



   # NOTE do NOT use REPLACE INTO, that works but it changes the sum_id
   # which is the whole keystone of this whole operation!
   #my $sth = $dbh->prepare("INSERT INTO $TABLE_NAME (sum) VALUES (?)")
   #   or confess($dbh->errstr);
   $sth0 ||= $dbh->prepare("INSERT INTO $TABLE_NAME (sum) VALUES (?)")
      or confess($dbh->errstr);

   local $sth0->{RaiseError}; # stop dying if insert fails
   local $sth0->{PrintError}; # stop telling if insert fails

   my $result = $sth0->execute($sum);
   $sth0->finish;


   if (!defined $result){ # then already in.. likely
      
      $sth1 ||= $dbh->prepare("SELECT id FROM $TABLE_NAME WHERE sum = ?");
      my $r = $sth1->execute($sum);
      


      if ($r eq '0E0'){ # would mean no results
         $sth1->finish;
         die("Could not insert sum:'$sum', and could not fetch either! Something is wrong.");
         
      }
      else {
         my $val =$sth1->fetch->[0];
         $sth1->finish;
         return $val
      }

   }

   
   ($result eq '0E0')
      and confess("could not register sum:'$sum',".$dbh->errstr);
   
   defined wantarray 
      ? ( $dbh->last_insert_id( undef, undef, $TABLE_NAME, undef )
         || confess("can't get last insert id for sum table") )
      : 1;
}

