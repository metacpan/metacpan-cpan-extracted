package CCCP::SQLiteWrap;

use 5.010000;
use strict;

our $VERSION = '0.01';

use DBI;
use File::Temp;
use File::Copy;
use Data::UUID;
use Digest::MD5 qw(md5_hex);    
    
    $CCCP::SQLiteWrap::OnlyPrint = 0;

use warnings;
    
    my $t_create_pattern = 'CREATE TABLE IF NOT EXISTS %s (%s)';
    my $i_create_pattern = 'CREATE INDEX %s ON %s(%s)';
    my $tr_create_pattern = ['DROP TRIGGER IF EXISTS %s','CREATE TRIGGER IF NOT EXISTS %s %s %s ON %s FOR EACH ROW BEGIN %s; END;'];

# one argument - abs path to sqolite base
sub connect {
    my ($class,$path) = @_;    
    
    if (ref $class) {
        # reconnect
        $class->{db} = DBI->connect('dbi:SQLite:dbname='.$class->path, '', '',{RaiseError => 1, InactiveDestroy => 1});
    } else {
        # init new handler
        my $obj = bless( 
            {
                db => DBI->connect('dbi:SQLite:dbname='.$path, '', '',{RaiseError => 1, InactiveDestroy => 1}),
                path => $path  
            },
            $class
        );
        
        # check connect error
        if ($DBI::errstr) {
            die $DBI::errstr;
        };
        
        return $obj;
    }
}

sub check {
    my ($obj) = @_;    
        
    # check live connection
    unless ($obj->db->ping()) {
        return "Can't ping SQLite base from ".$obj->path."\n";
    };
    
    # check database structure
    my $need_rebackup = 0;
    my @table = $obj->show_tables;
    foreach my $table (@table) {
        next unless $table;
        eval{$obj->db->selectall_arrayref("SELECT * FROM $table LIMIT 1")};
        if ($DBI::errstr) {
            $need_rebackup++;
            last;
        };
    };
    if ($need_rebackup) {
        return "SQLite base from ".$obj->path." return error like 'database disk image is malformed' and goto re-dump";
        return "Bug in re-dump SQLite" unless $obj->redump();       
    };
    
    return;    
}

sub db {$_[0]->{'db'}}
sub path {$_[0]->{'path'}}

# return [{'field1'=>'some_value1',...},{'field1'=>'some_value2',...}]
sub select2arhash {
    my ($obj,$query,@param) = @_;
    my $sth = $obj->db->prepare($query);
    $sth->execute(@param);
    return $sth->fetchall_arrayref({});
}

sub create_table {
    my $obj = shift;
    return unless (@_ or scalar @_ % 2 == 0);
    
    my $exisis_table = $obj->show_tables;
    my @new_table = ();
    my @create_table = ();
    my $can_fk = $obj->db->selectrow_arrayref('PRAGMA foreign_keys');
    while (my ($name,$param) = splice(@_,0,2)) {
        next if (not $name or ref $name or not $param or ref $param ne 'HASH' or not exists $param->{fields}); 
        $name = lc($name);
        next if $exisis_table->{$name}++;
        
        my $desc = ''; my @index = ();
        if (exists $param->{meta}) {
            # set default value         
            if (exists $param->{meta}->{default} and scalar @{$param->{meta}->{default}} % 2) {
                while (my ($fild,$defval) = splice(@{$param->{meta}->{default}},0,2)) {
                    if (exists $param->{fields}->{$fild}) {                       
                       $param->{fields}->{$fild} .= ' DEFAULT '.$obj->db->quote($defval);
                    };
                }
            };
            
            # set not null
            if (exists $param->{meta}->{not_null}) {
                map {
                    if (exists $param->{fields}->{$_}) {                       
                       $param->{fields}->{$_} .= ' NOT NULL';
                    };
                } @{$param->{meta}->{not_null}}; 
            };
            
            # set unique
            if (exists $param->{meta}->{unique}) {
                map {
                    if (exists $param->{fields}->{$_}) {                       
                       $param->{fields}->{$_} .= ' UNIQUE';
                    };
                } @{$param->{meta}->{unique}}; 
            };

            # set primary key
            if (exists $param->{meta}->{pk}) {
                $param->{fields}->{'PRIMARY KEY'} = "(".join(',',map {$obj->db->quote($_)} @{$param->{meta}->{pk}}).")";
            };          
            
            # set fk
            if ($can_fk and exists $param->{meta}->{fk}) {
                unless ($can_fk->[0]) {
                    $obj->db->do('PRAGMA foreign_keys = ON');
                    $can_fk->[0] = 1;
                };
                my @fk = @{$param->{meta}->{fk}}; 
                if (@fk and scalar @fk % 2 == 0 ) {
                    while (my ($fk_field,$fk_param) = splice(@fk,0,2)) {
                        # REFERENCES artist(artistid) ON DELETE SET DEFAULT
                        next if (not $fk_field or ref $fk_field or ref $fk_param ne 'HASH' or not exists $param->{fields}->{$fk_field});
                        $param->{fields}->{$fk_field} .= sprintf(' REFERENCES %s(%s)',$fk_param->{table},$fk_param->{field});
                        $param->{fields}->{$fk_field} .= ' ON UPDATE '.$fk_param->{on_update} if exists $fk_param->{on_update};
                        $param->{fields}->{$fk_field} .= ' ON DELETE '.$fk_param->{on_delete} if exists $fk_param->{on_delete};
                    };
                };
            };
            
            # set index
            if (exists $param->{meta}->{index}) {
                my $index = {};
                @index = grep {$_} map {                    
                    my $ind_md5 = md5_hex(join(',',sort {$a cmp $b} @{$_}));
                    $index->{$ind_md5}++ ? 
                        undef :
                        sprintf(
                           $i_create_pattern,
                           sprintf('_%s',Data::UUID->new()->create_hex()),
                           $name,
                           join(',',map {$obj->db->quote($_)} @{$_})
                        );
                } @{$param->{meta}->{index}};                
            };          
            
        };
        
        my $create_table = sprintf(
            $t_create_pattern,
            $name,
            join(',',
                grep {$_}
                map {
                    exists $param->{fields}->{$_} ?
                    join(' ',$_ eq 'PRIMARY KEY' ? $_ : $obj->db->quote($_),$param->{fields}->{$_}) :
                    undef
                } ((grep {!/^PRIMARY KEY$/} keys %{$param->{fields}}), 'PRIMARY KEY')
            )
        );
        
        if ($CCCP::SQLiteWrap::OnlyPrint) {
            print join("\n",$create_table,@index);
            print "\n------------------------------\n";
        } else {
            $obj->do_transaction($create_table,@index)
        };
        push @new_table,$name;
    }
    
    return wantarray() ? @new_table : scalar @new_table;
}

# do over transaction
sub do_transaction {
    my ($obj, @query) = @_;
    return unless @query;     
    $obj->db->begin_work or die $obj->db->errstr;
    map {$obj->db->do($_) if $_} @query;
    $obj->db->commit;
    return;
};

sub show_tables {
    if (wantarray() ){
        return grep {$_!~/^sqlite_/} map {$_=~s/"//g; $_;} $_[0]->db->tables;
    } else {
        my $tab_hash = {};
        map {$tab_hash->{$_}++} grep {$_!~/^sqlite_/} map {$_=~s/"//g; $_;} $_[0]->db->tables;
        return $tab_hash;
    };
}

sub close {
    my ($obj) = @_;
    $obj->db->disconnect;    
}

# re-dump need for
# fix error like "database disk image is malformed"
# shutdown server (or kill process) while go insert itnto sqlite-base
sub redump {
    my ($obj) = @_;
    $obj->close();
    if (-e $obj->path and -s _) {
        my $tmp_file = File::Temp->new()->filename;
        my $dump_command = sprintf('sqlite3 %s ".dump" | sqlite3  %s',$obj->path,$tmp_file);
        system($dump_command);
        move($tmp_file,$obj->path);        
    } else {
        unlink $obj->path;
        my $create_command = sprintf('sqlite3 %s "select 1"',$obj->path);
        system($create_command);
    };
    $obj->connect();        
    return -e $obj->path ? 1 : 0;
}

# $obj->create_index('tablename' => [asfd,asfds,sdf], 'safasf' => [asfdsf,asfd])
sub create_index {
    my $obj = shift;
    return unless (@_ or scalar @_ % 2 == 0);
    
    my $exisis_table = $obj->show_tables;
    my $ret = 0;
    
    # geting param
    my $new_index = {};    
    while (my ($t_name,$ind_array) = splice(@_,0,2)) {
        next if (not $t_name or not exists $exisis_table->{$t_name} or not $ind_array); 
        push @{$new_index->{$t_name}}, $ind_array;
    };
    
    # check exists index
    foreach my $table (keys %$new_index) {
        my @index = ();
        my $exists_index = {};
        my $index_name = $obj->db->selectall_arrayref('PRAGMA index_list('.$obj->db->quote($table).')');
        next unless $index_name;
        map {
            my $i_name = $_->[1];
            my $index_fields = $obj->db->selectrow_arrayref('PRAGMA index_info('.$obj->db->quote($i_name).')');
            $exists_index->{md5_hex(join(',',sort {$a cmp $b} @$index_fields))}++ if $index_fields;         
        } @$index_name;
        # create new index sql
        foreach my $new_index_fields (@{$new_index->{$table}}) {
            next if (not $new_index_fields or ref $new_index_fields ne 'ARRAY');
            next if $exists_index->{md5_hex(join(',',sort {$a cmp $b} @$new_index_fields))}++;
            my $unic_name = sprintf('_%s',Data::UUID->new()->create_hex());
            push @index, sprintf(
                            $i_create_pattern,
                            $unic_name,
                            $table,
                            join(',',map {$obj->db->quote($_)} @$new_index_fields)
            );
            $ret++;
        };
        
        # create new index in base
        if ($CCCP::SQLiteWrap::OnlyPrint) {
            print join("\n",@index);
            print "\n------------------------------\n";
        } else {
            $obj->do_transaction(@index);
        };      
    };
    
    return $ret;
}

# check table on exists (bool)
sub table_exists {
    my ($obj,$table) = @_;
    return unless $table;
    
    return scalar(grep {/^\Q$table\E$/i} map {$_=~s/"//g; $_;} $obj->db->tables) ? 1 : 0; 
}

# $obj->index_exists('name' => ['field1','field2']);
# return name index if exists for whis fields
sub index_exists {
    my ($obj,$table,$ind_fields) = @_;
    
    return unless ($table and $ind_fields and ref $ind_fields eq 'ARRAY');  
    return unless $obj->table_exists($table);   
        
    my $index_name = $obj->db->selectall_arrayref('PRAGMA index_list('.$obj->db->quote($table).')');
    return unless $index_name;
    my $exists_index = {};
    map {
        my $i_name = $_->[1];
        my $index_fields = $obj->db->selectall_arrayref('PRAGMA index_info('.$obj->db->quote($i_name).')');
        if ($index_fields) {
            $index_fields = [map {$_->[2]} @$index_fields];
            $exists_index->{md5_hex(join(',',sort {$a cmp $b} @$index_fields))} = $i_name;         
        };
    } @$index_name; 
    
    my $ind_fields_md5 = md5_hex(join(',',sort {$a cmp $b} @$ind_fields));
    
    return exists $exists_index->{$ind_fields_md5} ? $exists_index->{$ind_fields_md5} : 0;
}

sub create_trigger {
    my $obj = shift;
    return unless (@_ or scalar @_ % 2 == 0);
    
    my @transaction_query = ();
    
    my $exisis_table = $obj->show_tables;
    # cycle for table
    while (my ($t_name,$param) = splice(@_,0,2)) {  
       next if (not $t_name or not exists $exisis_table->{$t_name} or not $param or ref $param ne 'HASH' or not keys %$param);
           # cycle for event listener
           while (my ($t_event_1,$event_param) = each %$param) {
                next if (not $t_event_1 or not $event_param or ref $event_param ne 'HASH' or not keys %$event_param);
                # last cycle
                while (my ($t_event_2,$sql) = each %$event_param) {
                    next unless ($t_event_2 and $sql and ref $sql eq 'ARRAY' and scalar @$sql);
                    $sql = [map {s/;\s*$//s; $_} @$sql];
                    my $tr_name = join('_',map {lc($_)} ('trigger',$t_name,$t_event_1,$t_event_2,md5_hex(lc(join('',@$sql)))));
                    # delete trigger
                    push @transaction_query,sprintf(
                        $tr_create_pattern->[0],
                        $tr_name
                    );
                    # create trigger
                    push @transaction_query,sprintf(
                        $tr_create_pattern->[1],                                
                        $tr_name,
                        uc($t_event_1),
                        uc($t_event_2),
                        $t_name,
                        join(';',@$sql)
                    );
                };
           };
    };
    
    # create transaction in base
    if ($CCCP::SQLiteWrap::OnlyPrint) {
            print join("\n",@transaction_query);
            print "\n------------------------------\n";
    } else {
            $obj->do_transaction(@transaction_query);
    };    
}


1;
__END__

=encoding utf-8

=head1 NAME

B<CCCP::SQLiteWrap> - wrapper on SQLite (only for nix)

=head1 SYNOPSIS

    use CCCP::SQLiteWrap;
    
    my $db_path = '/abs/path/to/my/sqlite/base.db';
    
    my $dbh = CCCP::SQLiteWrap->connect($db_path);
    $dbh->check();
    
    $dbh->create_table(
        
        # description table artist 
        'artist' => {
            
            # fields on table artist
            fields => {
             'artist_id' => 'INTEGER',
             'name' => 'TEXT',
             'photo' => 'BLOB',
             'country'  => 'TEXT',
             'drags' => 'INTEGER'
            },
            
            # meta info about table artist
            meta => {
                default => [
                    'country' => 'Europe',
                    'drags' => 0
                ],
                not_null => [
                   'name'
                ],
                pk => ['artist_id'],
                unique => ['name'],
                index => [
                   ['name'],
                   ['name','country']
                ]
            }
        },

        # another table
        'albums' => {
            fields => {
             'album_id' => 'INTEGER',
             'album_name' => 'TEXT',
             'artist_id' => 'INTEGER',
             'photo' => 'BLOB',
             'style'  => 'TEXT'
            },
            
            meta => {
                not_null => [
                   'album_name'
                ],
                pk => ['album_id'],
                unique => ['album_name'],
                index => [
                   ['style'],
                ]            
            }
        },
        
        # and another table
        'dvd' => {
            fields => {
             'album_id' => 'INTEGER',
             'artist_id' => 'INTEGER',
             'dvd_name' => 'TEXT',         
            },
            
            meta => {
                not_null => [
                   'dvd_name'
                ],
                unique => ['dvd_name'],
                index => [
                   ['dvd_name'],
                   ['album_id','artist_id']
                ]            
            }       
        }
           
    );
    
    $dbh->create_trigger(
        'artist' => {
                'AFTER' => {
                    'DELETE' => [
                        'DELETE FROM dvd WHERE artist_id = OLD.artist_id',
                        'DELETE FROM albums WHERE artist_id = OLD.artist_id'
                    ],
                }
                
        },
        'albums' => {
                'AFTER' => {
                    'DELETE' => ['DELETE FROM dvd WHERE album_id = OLD.album_id'],
                }
        }       
    );
    
    $dbh->db->do('INSERT INTO ....');

=head1 IN SQL

    CREATE TABLE IF NOT EXISTS artist (
       'country' TEXT,
       'photo' BLOB,
       'artist_id' INTEGER,
       'name' TEXT NOT NULL UNIQUE,
       'drags' INTEGER,
       PRIMARY KEY ('artist_id')
    );
    CREATE INDEX _0x2ff7833b3b8d4334bc14bb74ac3769fc ON artist('name');
    CREATE INDEX _0x3d77f29481f34489a10b61be3da3602b ON artist('name','country');
    
    CREATE TABLE IF NOT EXISTS albums (
       'album_name' TEXT NOT NULL UNIQUE,
       'album_id' INTEGER,
       'photo' BLOB,
       'artist_id' INTEGER,
       'style' TEXT,
       PRIMARY KEY ('album_id')
    );
    CREATE INDEX _0xf1aa03bc417f467586b88eb676b125fc ON albums('style');
    
    CREATE TABLE IF NOT EXISTS dvd (
       'album_id' INTEGER,
       'artist_id' INTEGER,
       'dvd_name' TEXT NOT NULL UNIQUE
    );
    CREATE INDEX _0xd109df2d70fb4fe88332257e0c327446 ON dvd('dvd_name');
    CREATE INDEX _0xb324a617fe6b466685d3a9a9f0d4addc ON dvd('album_id','artist_id');
    
    DROP TRIGGER IF EXISTS trigger_artist_after_delete_5a7d596032b6cbc214cf64c48eddfad9;
    CREATE TRIGGER IF NOT EXISTS trigger_artist_after_delete_5a7d596032b6cbc214cf64c48eddfad9 
       AFTER DELETE ON artist FOR EACH ROW 
       BEGIN 
           DELETE FROM dvd WHERE artist_id = OLD.artist_id;
           DELETE FROM albums WHERE artist_id = OLD.artist_id; 
       END;
       
    DROP TRIGGER IF EXISTS trigger_albums_after_delete_911a284c6b402e9e87a67669a128d6cd;
    CREATE TRIGGER IF NOT EXISTS trigger_albums_after_delete_911a284c6b402e9e87a67669a128d6cd 
       AFTER DELETE ON albums FOR EACH ROW 
       BEGIN 
           DELETE FROM dvd WHERE album_id = OLD.album_id; 
       END;

=head1 DESCRIPTION

This is simple wrapper, for easy create database structure in SQLite.
Faster DBI is only DBI ;) therefore you can access to DBI::db over "db" method.
 
Now, create table, index, trigger in SQLite is very simple.

=head2 Package METHODS

=head3 connect($abs_path)

Return CCCP::SQLiteWrap object.

=head2 Object METHODS

=head3 db

Access to DBI::db object.

=head3 check

This is very important method. If server is down, while some process write in your SQLite base, after restart, you can get
error like "database disk image is malformed".
This method re-dump (over sqlite3) your database if needed.

=head3 close

Close connect to base.

=head3 create_table(table1 => $param1, ..., tableN => $paramN)

Create table. 
For sqlite version version 3.6.19+ you can add foreign key:

    $dbh->create_table(
        
        ....
                
        'albums' => {
            fields => {
             'album_id' => 'INTEGER',
             'album_name' => 'TEXT',
             'artist_id' => 'INTEGER',
             'photo' => 'BLOB',
             'style'  => 'TEXT'
            },
            
            meta => {
                not_null => [
                   'album_name'
                ],
                pk => ['album_id'],
                unique => ['album_name'],
                index => [
                   ['style'],
                ],
                fk => [
                   'artist_id' => {
                       table => 'artist',
                       field => 'artist_id',
                       on_update => 'CASCADE',
                       on_delete => 'SET DEFAULT' 
                   },
                ]            
            }
        },
        
        ....
           
    );

=head3 create_trigger(table1 => $param1, ..., tableN => $paramN)

    $dbh->create_trigger(
        'table_name' => {
                'AFTER' => {
                    'DELETE' => [$query1,...,$queryN],
                    'INSERT' => [...],
                    'UPDATE' => [...]
                },
                'BEFORE' => {
                    ...
                }
        },
        
        ....       
    );

=head3 index_exists('table_name' => ['field1',...,'fieldN'])

If index exist return name or 0.

=head3 table_exists('table_name')

Bool

=head3 create_index('table_name' => [field1,...,fieldN], ...)

Create index for table

=head3 redump

Re-init database over dump (which make over sqlite3) 

=head3 do_transaction(@query)

Like method "do" from DBI over transaction 

=head3 path

Return path to your database

=head2 PACKAGE VARIABLES

=head3 $CCCP::SQLiteWrap::OnlyPrint

Default is false.
If true, methods "create_table", "create_trigger", "create_index" return raw sql in stdout and nothing do in base.

=head1 SEE ALSO

=over 4

=item *

C<DBI>

=item *

http://www.sqlite.org

=back

=head1 AUTHOR

Ivan Sivirinov

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
