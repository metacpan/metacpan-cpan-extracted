package DBIx::Brev;

use strict;
use warnings;

use DBI;

our $use_config  = eval q{use Config::General;1};
our $use_sqlsplit = eval q{use SQL::SplitStatement;1};
our $use_connector = eval q{use DBIx::Connector;1};

use Scalar::Util qw(looks_like_number);

our $VERSION = '0.02';

use base 'Exporter';

our @EXPORT = our @EXPORT_OK = qw(
sql_exec 
sql_value 
sql_query
sql_map 
sql_hash 
sql_query_hash 
sql_in
inserts
db_use
dbc
quote
);

my ($dbh,$dbc);

sub dbc {
    $dbc = $_[0] if @_;
    $dbh = $dbc unless $use_connector;
    $dbc;
}

sub dbh {
    $dbh = $_[0] if @_;
    $dbc = $dbh unless $use_connector;
    $dbh;
}

sub shift_params(&\@) {
    my ($predicate,$params) = @_;
    local $_ = shift(@$params);
    my $p = $_;
    if (eval {$predicate->($_) && 1}) {
        return $p;
    } else {
        unshift @$params,$p;
        return;
    }
}

my %config;
{
my $config_loaded;
sub load_config {
    #return if $config_loaded; $config_loaded = 1;
    return unless $use_config;
    my $config = shift_params {ref($_) eq 'HASH'} @_;
    if ($config) {
         %config = %$config;
        return;
    }
    my $mswin = $^O eq 'MSWin32';
    my @path = $mswin?map( {exists $ENV{$_}?$ENV{$_}:()} qw(
        USERPROFILE HOME ALLUSERSPROFILE APPDATA ProgramData SYSTEMROOT WINDIR
    )) : ($ENV{HOME},'/etc');
    my $fd = $mswin?q{\\}:q{/};
    my ($config_file) = grep defined && -f,@_,$ENV{DBI_CONF},map $_.$fd.q{dbi.conf},@path;
    %config = Config::General->new($config_file)->getall if $config_file;
}
}

my %dbc; # cache of dbx connections for fast switching between handles
sub db_use {    
    my ($db_alias,%options) = @_;
    my @connect = ($db_alias,@options{qw(username password)});
    my $options = $options{options};
    $options ||= {RaiseError => 1,AutoCommit => 1};
    # subroutine changes default dbc if it is called in void context or $dbc is undefined
    my $keep_default = $dbc && defined(wantarray); 
    my $connection_mode = delete $options->{connection_mode} || 'fixup';
    my ($local_dbc) = $dbc{$db_alias};
    unless ($local_dbc) {
        load_config() if $use_config && keys(%config)==0;
        my ($alias,$mode) = split /:/,$db_alias;
        my $databases = $config{database};
        die "wrong config" unless $databases;
        my @keys = qw(data_source username password);        
        @connect = @{$databases->{$alias}}{map $mode."_$_",@keys} if exists $databases->{$alias} && $mode;
        @connect = @{$databases->{$db_alias}}{@keys} if exists $databases->{$db_alias};
        push @connect,$options;
        $local_dbc = $use_connector?DBIx::Connector->new(@connect):DBI->connect(@connect);
        $local_dbc->mode($connection_mode) if $use_connector;
        $dbc{$db_alias} = $dbc;
    }
    return $local_dbc if $keep_default;
    dbc($local_dbc);
}

sub quote {
    die "connect to db first!" unless $dbc;
    ($use_connector?$dbc->dbh():$dbh)->quote(@_);
}

sub import { my ($class,$db_alias,@options) = @_;
    db_use($db_alias,@options) if $db_alias;
    $class->export_to_level(1);
}

sub shift_connection(\@) {
    my $c = shift;
    my $local_dbc = shift_params {UNIVERSAL::isa($_,$use_connector?'DBIx::Connector':'DBI::db')} @$c;
    unless ($local_dbc) {
        my $db_alias = shift_params {!ref($_) && !m{\s}} @$c;
        if ($db_alias) {
            my $db_options = shift_params {ref($_) eq 'HASH'} @$c;
            $local_dbc = db_use($db_alias,$db_options);
        }
    }
    return $local_dbc || $dbc;
}

sub get_sth
{
    my $dbc = shift_connection(@_);
    my ($sql,@bind_values) = @_;
    my $executed;
    my $sth;
    if ($use_connector) {
        $dbc->run(sub {$executed = ($sth = $_->prepare($sql)) && $sth->execute(@bind_values);});
    } else {
        $executed = ($sth = $dbc->prepare($sql)) && $sth->execute(@bind_values);
    }
    my $err = $@ or $sth->errstr;
    die "$err\n[$sql]" if $err;
    unless  ($executed) {
        die "Error:$DBI::errstr\nSQL::$sql\n";
    };
    return $sth;
}

sub sql_query
{
    my $sth = &get_sth;
    my $r = $sth->fetchall_arrayref;
    if (@$r && (@{$r->[0]}==1)) {        
        $_ = $_->[0] for @$r; #scalarize rows if row is single-dimension array
    }
    return wantarray?@$r:$r;
}

sub sql_in {
    my $dbc = shift_connection(@_);
    my $dbh = $use_connector?$dbc->dbh():$dbc;
    my $list = join ",",map {looks_like_number($_)?$_:$dbh->quote($_)} sql_query($dbc,@_);    
    sprintf(" in (%s)",$list || 'NULL');
}

sub sql_value
{
    my $sth = &get_sth;
    my @row_ary  = $sth->fetchrow_array;
    wantarray()?@row_ary:$row_ary[0];
}

sub sql_hash
{
    my $sth = &get_sth;
    my $hash  = $sth->fetchrow_hashref;
    return undef unless $hash;
    wantarray()?%$hash:$hash;
}

sub sql_query_hash
{
    my $sth = &get_sth;
    my @result;
    while (my $row  = $sth->fetchrow_hashref) { push @result,$row; }
    wantarray()?@result:\@result;
}

sub sql_map(&@)
{
    my $callback = shift;
    my $sth = get_sth(@_);
    my @result = ();
    my $wantresult = defined wantarray;
    local $_;
    while (defined($_ = $sth->fetch)) {
        # do copy because fetch uses the same buffer
        $_ = @$_>1?[@$_]:$_->[0];
        my @r = $callback->($_);
        last unless @r;
        if ($wantresult) {
            push @result, @r;
        }
    }
    return unless $wantresult;
    return wantarray?@result:\@result;
}

sub sql_exec
{
    my $dbc = shift_connection(@_);
    my ($attr) = grep ref($_) eq 'HASH', @_,{};
    my ($sql_code,@bind_values) = grep ref($_) ne 'HASH', @_;
    my $rows_affected = 0;
    my $dbh = $use_connector?$dbc->dbh():$dbc;
    if ($use_sqlsplit) {    
        my $splitter_options = delete $attr->{splitter_options}||{};
        my $no_commit = delete $attr->{no_commit};
        my $splitter = SQL::SplitStatement->new($splitter_options);
        my ( $statements, $placeholders ) = $splitter->split_with_placeholders( $sql_code );
        $dbh->{AutoCommit} = 0;  # enable transactions, if possible
        $dbh->{RaiseError} = 1;
        die $@ unless eval {
            for my $statement (@$statements) {
                my $placeholders_count = shift(@$placeholders);
                my @sbind_values = splice @bind_values, 0, $placeholders_count;
                $rows_affected += $dbh->do($statement,$attr,@sbind_values);
            }
            $dbh->commit unless $no_commit;
            1;
        };    
    } else {
        $rows_affected += $dbh->do($sql_code,$attr,@bind_values);
    }
    return $rows_affected;
}
    

sub inserts {
    my $dbc = shift_connection(@_);
    my ($sprintf_sql,$data,%opts) = @_;
    $sprintf_sql .= ' %s' unless $sprintf_sql =~ m{%s};
    # set default step 500 for smooth sqlite experience (see http://stackoverflow.com/questions/15858466/limit-on-multiple-rows-insert)
    my $step = $opts{step} || 500; # split batch into bunches of $step records
    my $delay = ($opts{delay} || 0) / 1000; # delay between statements in milliseconds
    my $last = $#$data;
    my $offset = 0;
    my $updated = 0;
    # make fixup for dbh
    #$dbc->run(fixup => sub {$_->do(q{SELECT 1});});
    # do all inserts in one transaction
    my $dbh = $use_connector?$dbc->dbh():$dbc;
    $dbh->{AutoCommit} = 0;  # enable transactions, if possible
    $dbh->{RaiseError} = 1;
    die $@ unless eval {
        while ($offset <= $last) {
            my $limit = $offset + $step - 1;
            $limit = $last if $limit > $last;
            my $records = join "\nunion all\n",
                map sprintf("select %s",
                    ref($_) eq 'ARRAY'?                                           
                    join(",", map $dbh->quote($_), @$_)
                    :
                    $_
                ), @{$data}[$offset..$limit];
            $offset += $step;
            sleep($delay) if $updated;
            my $time = time;
            my $sql = sprintf($sprintf_sql,$records);
            $updated += $dbh->do($sql);
            # make next delay twice time of sql_exec if it was not explicitly specified
            $delay = (time - $time) * 2 unless exists $opts{delay};
        }
        $dbh->commit;
        1;
    };    
    return $updated;
}


1;
__END__

=head1 NAME

DBIx::Brev - Brevity is the soul of wit. 
Swiss-Army chainsaw for perl-DB one liners and to make code laconic and focused :).
Very handy and very perlish set of subroutines to make you happy while working with database!

=head1 SYNOPSIS

  perl -MDBIx::Brev=mydb -e"printf q{profit: %s\n},sql_value(q{select sum(amount) from Profit})"
  
  %car_price = map @$_, sql_query q{select id,price from Cars};
  

=head1 DESCRIPTION

DBIx::Brev provides framework for using DBI in more convenient way:
 
1) Establish connection using db aliases, setup in config file provided by Config::General (apache style) 

2) Keep & reestablish connection automatically using DBIx::Connector facilities.

3) Using default connection paradigm to make DBI code laconic.

4) Switch easily & instantly between databases using cached connections

5) You can switch context by db_use($db_alias) or you can execute each
of sql_xxx/inserts subroutines by specifiing explicit db alias as a first parameter
without switching default database connection.


To make it work put to ~/dbi.conf or /etc/dbi.conf database aliases and switch easily between databases.
It's suitable for one liners where less code is best approach.
Also it will be good for everyone who likes laconic code.

=head1 PPM
DBIx::Brev is pure perl module and can be used without installation additional modules and without creating dbi.conf with aliases.
This module can be installed and used just by copying it to some PERL5LIB directory.
L<Config::General>, L<DBIx::Connector>, L<SQL::SplitStatement> powerlift it and provide some useful features 
but if you have restricted environment, where you can't deploy those modules, it will work all right without them.

For example
perl -MDBIx::Brev=dbi:SQLite:dbname=~/svn/reponame.sqlite -e'print sql_value(q{select count(*) from commits})'

use DBIx::Brev "dbi:Sybase:server=ENGINEERING",username=>"admin",password=>"ytrewq";

=head1 EXPORT

sql_exec,
sql_map
sql_query,
sql_query_hash,
sql_hash,
sql_value,
db_use,
quote,

=head2 db_use

my $dbc = db_use('test_db'); 

Connects to specified database using alias and switch current dbc to it, 
Then all the sql_ subroutines will work with that database unless explicit db_alias or db connections is specified.
Take into account that unless you call it in void context:
 
  db_use('test_db');

It will NOT switch default database account if it is already set.
It is to force using alias instead of $dbc when you want execute some query with explicit database connection:

  my $profit = sql_value 'mydb', 'select sum(amount) from Profit';
  
Of course you can do it this way as well

  my $dbc = db_use('mydb'); 
  my $profit = sql_value $dbc, 'select sum(amount) from Profit';
  
But what the point?

=head2 sql_value

 my $max = sql_value("select max(id) from B_Hotel");
 my ($min,$max,$count) = sql_value("select min(id),max(id),count(*) from B_Hotel");

sql_value takes only first row of query.
returns value of first column from first row in scalar context or
array of column's values from first row completely in array context.
You can also specify explicit db alias or $dbc as for all other sql_ subroutines.
That way specified db will be used to run the query.
Default database context will not be changed.

=head2 sql_query

 my %car_price = map @$_,sql_query("select id,price from Cars");
 my $germa_car_ids = join ",",sql_query "select id from Cars where Country=?",'Germany';

returns array/ref to array (depending on context) with records for sql query.
if query consists only one column it scalarizes the result so it returns simple array with values.
it can be useful for selecting list of ids.

=head2 sql_map

 my %entity_aggregate = sql_map {$_=>aggregate($_)} q{select id from Entity};

 sql_map {$_} $sql
 
is almost the same as

 map $_,sql_query $sql

But sql_query uses $sth->fetchall_arrayref, while sql_map iterates with $sth->fetch
and then execute callback on fetched record.

=head2 sql_hash

works like sql_value but returns hash with column_names as keys which represents first row from the result of query
it's useful when using * in query:

 my %record=sql_hash("select * from Cars where id=?",$car_id);

=head2 sql_query_hash

It's like sql_query & sql_hash , so it returns array of hashes

=head2 sql_exec

sql_exec [$dbc],$sql,[,$attr],@bind_values

Use it when you need execute update/insert/delete statements
 
 sql_exec "update Car set price=price*? where demand > ?",1.05,1000;
 
It returns total number of affected rows.
 
sql_exec supports execution of multiple SQL statements in single transaction.
It uses L<SQL::SplitStatement> split_with_placeholders to split statements,
so you can use placeholders for each statement.

You can specify options which affects sql_exec:

 sql_exec {splitter_options=>{},no_commit=>1,%sth_prepare_attr},$sql;
 
$no_commit means it will not commit after all statements are executed.

$splitter_options is passed to SQL::SplitStatement->new($splitter_options)

%sth_prepare_attr is passed to each $dbh->do($sql,\%attr,@bind_values)

=head2 inserts

    $records = [[1,'first'],[2,'second']];
    inserts "insert into table_name(id,name)",$records;

Inserts multiple records at one (or few) statements. It uses ANSI SQL syntax to do that

    insert into table_name(id,name)
    select 1,'first'
    union all
    select 2,'second'
    
So it builds that huge sql statement and then executes it.
It splits records into chunks of 500 records per statement.
This can be redefined:
    
    inserts "insert into t",$many_records,{step=>40_000}

Also if you don't want inserts quotize values you can pass array of strings to it
    
    # quote binary values for sqlite as a x'HEX_DIGITS' literals
    $records = [map sprintf("x'%s'",unpack('h*',$_)),@binvalues];
    inserts "insert into table(blob_field)",$records;

=head2 sql_in

  $r = sql_query 'db1','select * from car_details where car_id '.
  sql_in('db2','select id from car where country=?','Germany');
  
  This subroutine executes specified query and then creates IN ($list) part of statement:
  
  IN (1,3,4)
  
  I believe it's more convenient and straightforward then annoying (repetitive)
  
  $dbh = dbc->dbh();
  $ids = join ',', map $dbh->quote($_), sql_query q{select id from Cars};
  $r = sql_query 'select * from car_details where id in (' .
  ($ids?$ids:'NULL') . ')';
  

=head1 CONFIGURATION WITH DATABASE ALIASES

It is simple text file ~/dbi.conf or /etc/dbi.conf with sections which define DB alias this way

 <database dbm>
 data_source=dbi:SQLite:dbname=/home/user/db/mydb
 </database>
 <database mysqldb>
 data_source=DBI:mysql:database=$database;host=$hostname;port=$port
 username=$user
 password=$password
 </database>
 
If you want call it different name you can use environment variable DBI_CONF or call

 DBIx::Brev::load_config($config_file)
 
Before first invocation of

  db_use($db_alias);
  
See DBIx-Brev.t for example. It creates config file on the fly and then use load_config and then db_use.

=head1 SEE ALSO

DBI
DBIx::Connector
Config::General

=head1 AUTHOR

Oleksandr Kharchenko E<lt>okharch@okharch.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Oleksandr Kharchenko E<lt>okharch@okharch.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
