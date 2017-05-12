#$Id: LoadDB.pm,v 1.30 2009/09/30 07:37:09 dinosau2 Exp $
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

package ACME::QuoteDB::LoadDB;

use 5.008005;        # require perl 5.8.5, re: DBD::SQLite Unicode
use warnings;
use strict;

#use criticism 'brutal'; # use critic with a ~/.perlcriticrc

use version; our $VERSION = qv('0.1.1');

# with Text::CSV only use 'perl csv loader'
# 'one time' db load performance not a concern
BEGIN {local $ENV{PERL_TEXT_CSV} = 0}

use aliased 'ACME::QuoteDB::DB::Attribution' => 'Attr';
use aliased 'ACME::QuoteDB::DB::QuoteCatg'  => 'QuoteCatg';
use aliased 'ACME::QuoteDB::DB::Category'  => 'Catg';
use aliased 'ACME::QuoteDB::DB::Quote'    => 'Quote';
use aliased 'ACME::QuoteDB::DB::DBI'     => 'QDBI';
use File::Basename qw/dirname basename/;
use File::Glob qw(:globally :nocase);
use Encode qw/is_utf8 decode/;
use Data::Dumper qw/Dumper/;
use Carp qw/carp croak/;
use Text::CSV;
use Readonly;
use DBI;

# if not in utf8 latin1 is assumed
my $FILE_ENCODING = 'iso-8859-1';

Readonly my @QUOTE_FIELDS => qw/quote name source catg rating/;

# XXX refactor
sub new {
    my ($class, $args) = @_;

    # TODO encapsulation
    my $self = bless {}, $class;

    # store each record we extract - keys map to database fields
    # TODO proper encapsulation
    $self->{record} = {};
    $self->{record}->{quote}  = q{};
    $self->{record}->{rating} = q{};
    $self->{record}->{name}   = q{};
    $self->{record}->{source} = q{};
    $self->{record}->{catg}   = q{};

    $self->{file}        = $args->{file};
    $self->{dir}         = $args->{dir};
    $self->{data}        = $args->{data};
    $self->{file_format} = $args->{file_format};
    $FILE_ENCODING       = $args->{file_encoding} || $FILE_ENCODING;
    $self->{delim}       = $args->{delimiter};
    $self->{verbose}     = $args->{verbose};
    $self->{category}    = $args->{category};
    $self->{rating}      = $args->{rating};
    $self->{attr_source} = $args->{attr_source};
    $self->{orig_args}   = $args;
    $self->{success}     = undef;

    # start with if set
    $self->{record}->{rating} = $self->{rating};
    $self->{record}->{name}   = $self->{attr_source};
    $self->{record}->{source} = $self->{attr_source};
    if (ref $self->{category} eq 'ARRAY') {
       $self->{record}->{catg} = ();
       foreach my $c (@{$self->{category}}){
         push @{$self->{record}->{catg}}, $c;
       }
    }
    else {
       $self->{record}->{catg} = $self->{category};
    }

    # db connection info
    if ($ENV{ACME_QUOTEDB_DB}) {
        $self->{db}   = $ENV{ACME_QUOTEDB_DB};
        $self->{host} = $ENV{ACME_QUOTEDB_HOST};
        $self->{user} = $ENV{ACME_QUOTEDB_USER};
        $self->{pass} = $ENV{ACME_QUOTEDB_PASS};
    }

    if (!$args->{dry_run}){$self->{write_db} = 1};
    #if ($args->{create_db}) {$self->create_db};
    if ($args->{create_db}) {$self->create_db_tables};

    return $self;
}

sub set_record {
  my ($self, $field, $value) = @_;

  # TODO support mult-field simultanous loading

  if ($value) {
      $self->{record}->{$field} = $value;
  }

  return $self;
}

sub debug_record {
  my ($self) = @_;

  print Dumper $self->{record};

  return;
}

sub get_record {
  my ($self, $field) = @_;

  if (not $field){return $self}

  return $self->{record}->{$field};
}

sub data_to_db {
    my ($self) = @_;

    if ($self->{file} and $self->{data} and $self->{dir}){
        croak 'only file, data or dir as arg but not both'
    }
    elsif (! ($self->{file} or $self->{data} or $self->{dir})) {
        croak 'file, data or dir needed as arg'
    }

    if ($self->{file}) {
        $self->_parse_file($self->{file});
    }
    elsif ($self->{data}) {
        $self->_parse_data($self->{data});
    }
    elsif ($self->{dir}) {
        my $dir = $self->{dir};
        my $e = q{};
        foreach my $f (<$dir*>) {
           #if (! (-e $f) || -z $f) # no worky - need path info
           $self->_parse_file($f);
           $e++;
        }
        if (! $e){croak 'no files to parse in: ', Dumper $dir;};
    }
    else {
      croak 'no file source in args!', Dumper $self;
    }

    return;
}

sub _parse_file {
  my ($self, $file) = @_;

  if (!-f $file) { croak "file not found: $file" }

  if ($self->{verbose}){warn "processing file: $file\n"};

  if (($self->{file_format} eq 'csv') || ($self->{file_format} eq 'tsv')){
      $self->dbload_from_csv($file);
  }
  elsif (($self->{file_format} eq 'html') || ($self->{file_format} eq 'custom')){
      # not supported, too many possibilities
      # supply your own
      $self->dbload($file);
  }
  else {
      croak 'unsupported file format requested, format must be csv or tsv';
  }

  return;
}

sub _parse_data {
  my ($self, $data) = @_;

  if (!$data) {croak "data empty $data"}

  if ($self->{verbose}){carp 'processing data:'};

  if ($self->{file_format} =~ /(?:csv|tsv)/sm) {
      croak 'TODO: not yet supported';
      #$self->dbload_from_csv($data);
  }
  elsif (($self->{file_format} eq 'html') || ($self->{file_format} eq 'custom')){
      # not supported, too many possibilities
      # supply your own
      $self->dbload($data);
  }
  else {
      croak 'unsupported file format requested, '
             .'format must be csv, tsv. html, custom also possible';
  }

  return $self;
}

sub _confirm_header_order {
  my ($hr) = @_;

  return ($hr->{quote}  eq 'Quote'
      and $hr->{name}   eq 'Attribution Name',
      and $hr->{source} eq 'Attribution Source',
      and $hr->{catg}   eq 'Category',
      and $hr->{rating} eq 'Rating')
      or croak 'incorrect headers or header order';
}

sub dbload_from_csv {
  my ($self, $file) = @_;

  my $delim = $self->{delim} || ',';
  my $csv = Text::CSV->new({
     sep_char => $delim,
     binary => 1
  });
  $csv->column_names (@QUOTE_FIELDS);

  open my $source, '<:encoding(utf8)', $file || croak $!;

  _confirm_header_order($csv->getline_hr($source));

  while (my $hr = $csv->getline_hr($source)) {
      next unless $hr->{quote} and $hr->{name};

      if ($self->{verbose}){
          print "\n",
                'Quote:   ', $hr->{quote},"\n",
                'Name:    ', $hr->{name},"\n",
                'Source:  ', $hr->{source},"\n",
                'Category:', $hr->{catg},"\n",
                'Rating:  ', $hr->{rating},"\n\n";
      };

      $self->set_record(quote  => $hr->{quote});
      $self->set_record(name   => $hr->{name});
      $self->set_record(source => ($self->{attr_source} || $hr->{source}));
      # take user defined first
      # TODO support multi categories
      $self->set_record(catg   => ($self->{category} || $hr->{catg}));
      $self->set_record(rating => ($self->{rating} || $hr->{rating}));
      $self->write_record;
  }
  close $source or carp $!;

  return $self;
}

# sub class this - i.e. provide this method in your code (see test
# 01-load_quotes.t)
sub dbload {
  croak 'Override this. Provide this method in a sub class (child) of this object';
  # see tests: t/01-load_quotes.t for examples
}

sub _to_utf8 {
    my ($self) = @_;

    RECORD:
    foreach my $r (@QUOTE_FIELDS){
        my $val = $self->{record}->{$r};
        if (ref $val eq 'ARRAY'){
         foreach my $v (@{$val}){
           if (!is_utf8($v)){
             push @{$self->{record}->{$r}}, decode($FILE_ENCODING, $v);
           }
         }
        }
        else {
          if (!is_utf8($val)){
            $self->{record}->{$r} = decode($FILE_ENCODING, $val);
          }
        }
    }

    return $self;
}

# XXX refactor (the following 3 methods)

# one person can have many quotes, is this person in our attribution table
# already?
sub _get_id_if_attr_name_exist {
    my ($self) = @_;

    my $attr_id = q{};

    RECS:
    foreach my $c_obj (Attr->retrieve_all){
        next RECS if not $c_obj->name;
        if ($c_obj->name eq $self->get_record('name')){
          # use attribution id if already exists
          $attr_id = $c_obj->attr_id;
        }
    }
    return $attr_id;
}

sub _get_id_if_catg_exist {
    my ($self, $ctg) = @_;

    my $catg_id = q{};
    # get category id
    RECS:
    foreach my $c_obj (Catg->retrieve_all){
        next RECS if not $c_obj->catg;
        if ($c_obj->catg eq $ctg){
          # use cat_id if already exists
          $catg_id = $c_obj->catg_id;
        }
    }
    return $catg_id;
}

#TODO : refactor
sub write_record {
    my ($self) = @_;

    $self->_to_utf8;

    if ($self->{verbose} and $self->get_record('name')){
        print 'Attribution Name: ',$self->get_record('name'),"\n";
    };

    my $attr_id = $self->_get_id_if_attr_name_exist;
    # nope, ok, add them
    if (not $attr_id) { # attribution record does not already exist, 
                        # create new entry
        if ($self->{write_db}) {
            $attr_id = Attr->insert({
                          name   => $self->get_record('name'),
                       });
        }
    }

    my $catg_ids = ();
    if ($self->{write_db}) {
      my ($catg) = $self->get_record('catg');
      if (! ref $catg){ # 'single' value
        my $catg_id = $self->_get_id_if_catg_exist($catg);
        if (!$catg_id) {
          # category does not already exist, 
          # create new entry
          $catg_id = Catg->insert({catg => $catg});
        }
        push @{$catg_ids}, $catg_id;
      } # support multi catg
      elsif (ref $catg eq 'ARRAY'){
          foreach my $c (@{$catg}){
            my $catg_id = $self->_get_id_if_catg_exist($c);
            if (!$catg_id) { # category does not already exist, 
               # create new entry
               $catg_id = Catg->insert({catg => $c});
            }
            push @{$catg_ids}, $catg_id;
          }
      }
    }

    $self->_display_vals_if_verbose;

    if ($self->{write_db}) {
       my $qid = Quote->insert({
               attr_id  => $attr_id,
               quote    => $self->get_record('quote'),
               source   => $self->get_record('source'),
               rating   => $self->get_record('rating')
       }) or croak $!;

       if ($qid) {
         my $id;
         foreach my $cid (@{$catg_ids}){
           $id =   QuoteCatg->insert({
                 quot_id  => $qid,
                 catg_id  => $cid,
            }) or croak $!;
         }
       }
    }
    # confirmation?
    # TODO add a test for failure
    if ($self->{write_db} and not $attr_id) {croak 'db write not successful'}

    #$self->set_record(undef);
    $self->{record} = {};
    $self->_reset_orig_args;

    if ($self->{write_db}) {
        $self->success(1);
    }

    return $self->success;
}

sub _reset_orig_args {
  my ($self) = @_;

  $self->{record}->{rating} = $self->{orig_args}->{rating};
  $self->{record}->{name}   = $self->{orig_args}->{attr_source};
  $self->{record}->{source} = $self->{orig_args}->{attr_source};
  if (ref $self->{orig_args}->{category} eq 'ARRAY') {
     foreach my $c (@{$self->{orig_args}->{category}}){
       push @{$self->{record}->{catg}}, $c;
     }
  } 
  else {
    $self->{record}->{catg} = $self->{orig_args}->{category};
  }

}

sub success {
  my ($self, $flag) = @_;

  $self->{success} ||= $flag;

  return $self->{success};
};

sub _display_vals_if_verbose {
    my ($self) = @_;

    if ($self->{verbose}){
        #print 'Quote: ',   $self->get_record('quote'),"\n";
        #print 'Source: ',  $self->get_record('source'),"\n";
        #print 'Category: ',$self->get_record('catg'),"\n";
        #print 'Rating: ',  $self->get_record('rating'),"\n";
        print Dumper $self->{record};
    }

    return $self;
}

#sub create_db {
#    my ($self) = @_;
#
#    if ($self->{db} and $self->{host}) {
#      $self->create_db_mysql();
#    }
#}

sub create_db_tables {
    my ($self) = @_;

    if ($self->{db} and $self->{host}) {
      #$self->create_db_mysql();
      $self->create_db_tables_mysql();
    }
    else {
      create_db_tables_sqlite();
    }

    return $self;

}

# XXX  we want the user to supply a pre created database.
# created as such 'CREATE DATABASE $dbn CHARACTER SET utf8 COLLATE utf8_general_ci'
# this get's into too many isseuwith privs and database creation
#Sat Aug 22 13:42:37 PDT 2009
# did this:
#mysql> CREATE DATABASE acme_quotedb CHARACTER SET utf8 COLLATE utf8_general_ci;
#mysql> grant usage on *.* to acme_user@localhost identified by 'acme';
#mysql> grant all privileges on acme_quotedb.* to acme_user@localhost ;

#sub create_db_mysql {
#    my ($self) = @_;
#
#     # hmmmm, what about priv's access, etc
#     # maybe user need to supply a db, they have 
#     # access to, already created (just the db though)
#     ## create our db
#     #my $dbhc = DBI->connect('DBI:mysql:database=mysql;host='
#     #                           .$self->{host}, $self->{user}, $self->{pass})
#     #      || croak "db cannot be accessed $! $DBI::errstr";
#
#     #my $dbn = $self->{db};
#     #my $db = qq(CREATE DATABASE $dbn CHARACTER SET utf8 COLLATE utf8_general_ci);
#     # eval {
#     #     $dbhc->do($db) or croak $dbhc->errstr;
#     # };
#     # $@ and croak 'Cannot create database!';
#     # $dbhc->disconnect; $dbhc = undef;
#
#     my $drh = DBI->install_driver('mysql');
#     my $rc = $drh->func("dropdb", $self->{db}, 
#                    [$self->{host}, $self->{user}, $self->{password}],
#                    'admin'
#                );
#
#        $rc = $drh->func("createdb", $self->{db}, 
#                    [$self->{host}, $self->{user}, $self->{password}],
#                    'admin'
#                );
#}

# XXX refactor with sqlite
sub create_db_tables_mysql {
    my ($self) = @_;

     # connect to our db
     my $c = $self->{db}.';host='.$self->{host};
     my $dbh = DBI->connect(
             "DBI:mysql:database=$c", $self->{user}, $self->{pass})
               || croak "db cannot be accessed $! $DBI::errstr";

    eval {
        $dbh->do('DROP TABLE IF EXISTS quote;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS quote (
            quot_id        INTEGER NOT NULL AUTO_INCREMENT, 
            attr_id        INTEGER,
            quote          TEXT,
            source         TEXT,
            rating         REAL,
            PRIMARY KEY(quot_id)
            );')
            #)CHARACTER SET utf8 COLLATE utf8_general_ci;
            #) ENGINE = MYISAM CHARACTER SET utf8 COLLATE utf8_general_ci; 
            or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS attribution;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS attribution (
            attr_id  INTEGER NOT NULL AUTO_INCREMENT,
            name     TEXT,
            PRIMARY KEY(attr_id)
            );') or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS category;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS category (
            catg_id    INTEGER NOT NULL AUTO_INCREMENT, 
            catg       TEXT,
            PRIMARY KEY(catg_id)
            );') or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS quote_catg;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS quote_catg (
            id    INTEGER NOT NULL AUTO_INCREMENT, 
            catg_id    INTEGER, 
            quot_id    INTEGER, 
            PRIMARY KEY(id)
            );') or croak $dbh->errstr;


       $dbh->disconnect or warn $dbh->errstr;

       $dbh = undef;
    };

    return $@ and croak 'Cannot create database tables!';

}

sub create_db_tables_sqlite {

     my $db = QDBI->get_current_db_path;

     #XXX is there really no way to do this with the existing 
     # connection?!(class dbi)
     my $dbh = DBI->connect('dbi:SQLite:dbname='.$db, '', '')
       || croak "$db cannot be accessed $! $DBI::errstr";

    #-- sqlite does not have a varchar datatype: VARCHAR(255)
    #-- A column declared INTEGER PRIMARY KEY will autoincrement.
    eval {
        $dbh->do('DROP TABLE IF EXISTS quote;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS quote (
            quot_id        INTEGER PRIMARY KEY, 
            attr_id        INTEGER,
            quote          TEXT,
            source         TEXT,
            rating         REAL
            );')
            or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS attribution;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS attribution (
            attr_id  INTEGER PRIMARY KEY,
            name     TEXT
            );') or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS category;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS category (
            catg_id    INTEGER PRIMARY KEY, 
            catg       TEXT
            );') or croak $dbh->errstr;

        $dbh->do('DROP TABLE IF EXISTS quote_catg;') or croak $dbh->errstr;

        $dbh->do('CREATE TABLE IF NOT EXISTS quote_catg (
            id         INTEGER PRIMARY KEY,
            catg_id    INTEGER,
            quot_id    INTEGER
            );') or croak $dbh->errstr;

        $dbh->disconnect or carp $dbh->errstr;

        $dbh = undef;
    };

    return $@ and croak 'Cannot create database tables!';

}

q(My cat's breath smells like cat food. --Ralph Wiggum);


__END__

=head1 NAME

ACME::QuoteDB::LoadDB - Database loader for ACME::QuoteDB

=head1 VERSION

Version 0.1.1

=head1 SYNOPSIS

load a csv file to quotes database 

  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file => '/home/me/data/simpsons_quotes.csv',
                              file_format => 'csv',
                          });
  
  $load_db->data_to_db;

  print $load_db->success; # bool

header columns of the csv file as follows:

"Quote", "Attribution Name", "Attribution Source", "Category", "Rating"


=head1 DESCRIPTION

This module is part of L<ACME::QuoteDB>. This is a Database loader, it
takes (quotes) data and loads into a database 
(currently L<sqlite3 or mysql|/'CONFIGURATION AND ENVIRONMENT'>),
which is then accessed by L<ACME::QuoteDB>.


There are several ways to get quote data into the db via this loader:
(There are more aimed towards 'batch' operations, i.e load a bunch of 
records quickly)

=over 4

=item 1

* csv file (pre determined format)

     pros: quick and easy to load.
     cons: getting the quotes data into the correct format need by this module

=item 2

* any source.

    One can take quote data from any source, override
    L<ACME::QuoteDB::LoadDB/dbload> loader methods to populate a record
    and write it to the db.
     pros: can get any quote data into the db.
     cons: you supply the method. depending on the complexity of the data
           source and munging required this will take longer then the other 
           methods.

=back

=head3 load from csv file

The pre defined csv file format is:

format of file is as follows: (headers)
"Quote", "Attribution Name", "Attribution Source", "Category", "Rating"
  
   for example:
   "Quote", "Attribution Name", "Attribution Source", "Category", "Rating"
   "I hope this has taught you kids a lesson: kids never learn.","Chief Wiggum","The Simpsons","Humor",9
   "Sideshow Bob has no decency. He called me Chief Piggum. (laughs) Oh wait, I get it, he's all right.","Chief Wiggum","The Simpsons","Humor",8


   my $load_db = ACME::QuoteDB::LoadDB->new({
                               file => dirname(__FILE__).'/data/simpsons_quotes.csv',
                               file_format => 'csv',
                           });
   
   $load_db->data_to_db;

   if (!$load_db->success){print 'failed'}


=head3 load from any source

If those dont catch your interest, ACME::QuoteDB::LoadDB is sub-classable, 
so one can extract data anyway they like and populate the db themselves. 
(there is a test that illustrates overriding the stub method, 'dbload')

you need to populate a record data structure:

    $self->set_record(quote  => q{}); # mandatory
    $self->set_record(name   => q{}); # mandatory
    $self->set_record(source => q{}); # optional but useful
    $self->set_record(catg   => q{}); # optional but useful
    $self->set_record(rating => q{}); # optional but useful

    # then to write the record you call
    $self->write_record;

NOTE: this is a one record at a time operation, so one would perform 
this within a loop. there is no bulk write operation currently.


=head1 OVERVIEW

You have a collection of quotes (adages/sayings/quips/epigrams, etc) for
whatever reason, you use these quotes for whatever reason, you want to 
access these quotes in a variety of ways,...

This module is part of L<ACME::QuoteDB>. 

This is a Database loader, it takes data (quotes) and loads into a database, 
which is then accessed by L<ACME::QuoteDB>.

See L<ACME::QuoteDB>.


=head1 USAGE

General usage, csv/tsv file in the expected format loaded to the database

  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file => '/home/me/data/sorta_funny_quotes.tsv',
                              file_format => 'tsv',
                              delimiter => "\t",
                              # provide a attr_source for all (if not in data)
                              # data is used first, if not defined use below
                              attr_source => 'Things Randomly Overheard',
                              # provide a category for all (if not in data)
                              category => 'Humor',
                              # provide a rating for all
                              rating   => 5, # scale 1-10
                          });
  $load_db->data_to_db;

  if (!$load_db->success){print 'failed'}

Also see t/01-load_quotes.t included with the distribution.

(available from the CPAN if not included on your system)


=head1 SUBROUTINES/METHODS 

This is an Object Oriented module. There is no proceedural interface.

=head2 new

  Instantiate a ACME::QuoteDB::LoadDB object.

  Argument is a hash ref. Params below 


=head4 Data Related Parameters

=over 4

=item  file or directory - one or the other required (not both)

if file, must be in our defined format, full path is needed.

if directory, full path is needed, can supply a basic glob type filter.

example:

{ file  => '/home/me/data/simpsons_quotes.csv' }

{ dir  => '/home/me/data/*.csv' }
 

=item  file_format - required

can be one of: 'csv', 'tsv', 'custom', or 'html'

if 'html' or 'custom' you must supply the method for parsing. 
(see tests for examples)

example:

{ file_format => 'csv' }


=item  delimiter - optional, default is a comma for csv

csv/tsv options tested: comma(,) and tab(\t)

'html' - not applicable

example:

{ delimiter => "\t" }

=item  category - optional, extracted from data if exists, otherwise will use what you
specify

TODO one quote to multiple categories

=item  attr_source - extracted from data if exists, otherwise will use what you
specify

example:

{attr_source => 'The Simpsons'}

=item  file_encoding - optional

Files being loaded are assumed to be utf8 encoded. if utf8 flag is not detected,
falls back to latin1 (iso-8859-1). If neither of these is correct, set this
option to the encoding your file is in.

=back

=head4 Operation Related Parameters

=over 4

=item  dry_run - optional

do not write to the database. Use with verbose flag to see what would have beed
written.

This can be helpful for testing the outcome of Loading results. 

i.e. like to confirm that the parsing of your data is correct

example:

{
 dry_run => 1,
 verbose => 1
}

=item  verbose  - optional

display to STDOUT what is being done

This can be helpful for testing quotes extraction from file parsing

example:

{verbose => 1}

=item  create_db  - optional (boolean)

L<ACME::QuoteDB::LoadDB> default behaviour is to always assume there is a
database and append new data to that. (It is usually only needed the first 
time one load's data)

setting this parameter to a true value will create a new database.
(so while this is an optional param, it is required at least once ;)

B<NOTE: it is not intelligent, if you hand it a populated database,
it will happily overwrite all data>

B<AGAIN: setting this param will destroy the current database, creating a new
empty one>

example:

{create_db => 1}


=back 

=head2 data_to_db

takes the data input provided to new, process' it and writes to the database.
should appropriatly blow up if not successful

=head2 dbload_from_csv

takes a csv file (in our defined format) as an argument, parses it and writes
the data to the database. (uses L<Text::CSV> with pure perl parser)
utf-8 safe. (opens file as utf8)

will croak with message if not successful


=head2 dbload

if your file format is set to 'html' or 'custom' you must 
define this method to do your parsing in a sub class.

Load from html is not supported because there are too many 
ways to represt the data. (same with 'custom')
(see tests for examples - there is a test for loading a 'fortune' file format)

One can subclass ACME::QuoteDB::LoadDB and override dbload,
to do our html parsing

=head2 debug_record

dump record (show what is set on the internal data structure) 

e.g. Data::Dumper

=head2 set_record

only needed it one plans to sub-class this module.
otherwise, is transparent in usage.

if you are sub-classing this module, you would have to populate 
this record. (L</write_record> knows about/uses this data structure)

possible fields consist of:

$self->set_record(quote  => q{});
$self->set_record(rating => q{});
$self->set_record(name   => q{});
$self->set_record(source => q{});
$self->set_record(catg   => q{});

currently can only set one attribute at a time.

ie. you cant do this:

 $self->set_record(
            name   => $name,
            source => $source
 );

 # or this even
 $self->set_record({
            name   => $name,
            source => $source
 });

=head2 get_record

only useful it one plans to sub-class this module.
otherwise, is transparent in usage.

if you are sub-classing this module, you would have to populate 
this record. [see L</set_record>] 

(L</write_record> knows about/uses this data structure)

possible fields consist of:

$self->get_record('quote');
$self->get_record('rating');
$self->get_record('name');
$self->get_record('source');
$self->get_record('catg');
 
=head2 success

indicates that the database load was successfull 

is undef on failure or if trying a L</dry_run>

 
=head2 write_record

takes the data structure 'record' '$self->get_record'
(which must exist). checks if attribution name ($self->get_record('name')) exists, 
if so, uses existing attribution name, otherwsie creates a new one

Load from html is not supported because there are too many 
ways to represt the data. (see tests for examples)

One can subclass ACME::QuoteDB::LoadDB and override dbload,
to do our html parsing

=head2 create_db_tables
 
create an empty quotes database (with correct tables). 

(usually only performed the first time you load data)

B<NOTE: will overwrite ALL existing data>

Set 'create_db' parameter (boolean) to a true value upon instantiation 
to enable.

The default action is to assume the database (and tables) exist and just
append new L<ACME::QuoteDB::LoadDB> loads to that.

=begin comment
 
    keep pod coverage happy.

    # Coverage for ACME::QuoteDB::LoadDB is 71.4%, with 3 naked subroutines:
    # Catg
    # Quote
    # Attr
    # QuoteCatg

    pod tests incorrectly state, Catg, Quote and Attr are subroutines, well they
    are,... (as aliases) but are imported into here, not defined within
    
    TODO: explore the above (is this a bug, if so, who's?, version effected, 
    create use case, etc) 
   
 
=head2 Attr

=head2 Catg

=head2 Quote

=head2 QuoteCatg

=head2 QDBI

=end comment

=begin comment

    These methods are more or less private.
    I may use them in another modules but You don't need to use or
    know about them, so I will obfuscate them here

=head2 create_db_tables_sqlite

=head2 create_db_tables_mysql

=end comment

=head1 DIAGNOSTICS

An error such as:

C<DBD::SQLite::db prepare_cached failed: no such table: ,...>

probably means that you do not have a database created in the correct format.

basically, you need to create the database, usually, on a first run

you need to add the flag:

create_db => 1, # first run, create the db

appending to an existing database is the default behaviour

see L</create_db_tables>


=head1 CONFIGURATION AND ENVIRONMENT

if you are running perl > 5.8.5 and have access to
install cpan modules, you should have no problem installing this module
(utf-8 support in Text::CSV not avaible until 5.8 - we don't support 'non
utf-8 mode)

=over 1

=item * By default, the quotes database used by this module installs in the 
system path, 'lib', (See L<Module::Build/"INSTALL PATHS">)
as world writable - i.e. 0666 (and probably owned by root)
If you don't like this, you can modify Build.PL to not chmod the file and it
will install as 444/readonly, you can also set a chown in there for whoever
you want to have RW access to the quotes db.

Alternativly, one can specify a location to a quotes database (file) to use.
(Since the local mode is sqlite3, the file doesn't even need to exist, just
needs read/write access to the path)

Set the environmental variable:

$ENV{ACME_QUOTEDB_PATH} (untested on windows)

(this has to be set before trying a database load and also (everytime) before 
using this module, obviouly)

Something such as:

BEGIN {
    # give alternate path to the DB
    # doesn't need to exist, will create
    $ENV{ACME_QUOTEDB_PATH} = '/home/me/my_stuff/my_quote_db'
}

* (NOTE: be sure this (BEGIN) exists *before* the 'use ACME::QuoteDB' lines)

The default is to use sqlite3.

In order to connect to a mysql database, several environmental variables
are required.

BEGIN {
    # have to set this to use remote database
    $ENV{ACME_QUOTEDB_REMOTE} =  'mysql';
    $ENV{ACME_QUOTEDB_DB}     =  'acme_quotedb';
    $ENV{ACME_QUOTEDB_HOST}   =  'localhost';
    $ENV{ACME_QUOTEDB_USER}   =  'acme_user';
    $ENV{ACME_QUOTEDB_PASS}   =  'acme';
}

Set the above in a begin block and all operations are the same but now
you will be writing to the remote mysql database specified.

(The user will need read/write permissions to the db/tables)
(mysql admin duties are beyond the scope of this module)

The only supported databases at this time are sqlite and mysql.

It is trivial to add support for others


see: L<LOADING QUOTES|ACME::QuoteDB/LOADING QUOTES>


=back 


=head1 DEPENDENCIES

L<Carp>

L<Data::Dumper>

L<criticism> (pragma - enforce Perl::Critic if installed)

L<version>(pragma - version numbers)

L<aliased>

L<Test::More>

L<DBD::SQLite>

L<DBI>

L<Class::DBI>

L<File::Basename>

L<Readonly>

L<Module::Build>


=head1 INCOMPATIBILITIES

none known of

=head1 SEE ALSO

man fortune (unix/linux)

L<Fortune>

L<fortune>

L<ACME::QuoteDB>


=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-acme-quotedb-loaddb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-QuoteDB::LoadDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ACME::QuoteDB::LoadDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-QuoteDB::LoadDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ACME-QuoteDB::LoadDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ACME-QuoteDB::LoadDB>

=item * Search CPAN

L<http://search.cpan.org/dist/ACME-QuoteDB::LoadDB/>

=back

=head1 ACKNOWLEDGEMENTS

The construction of this module was guided by:

Perl Best Practices - Conway

Test Driven Development

Object Oriented Programming

Gnu is Not Unix

vim 

Debian Linux

Mac OSX

The collective wisdom and code of The CPAN

=head1 LICENSE AND COPYRIGHT

Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ACME::QuoteDB::LoadDB
