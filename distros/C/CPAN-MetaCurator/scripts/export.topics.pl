#!/usr/bin/env perl

my($db_path)	= 'data/cpan.metacurator.sqlite';
my($log_path)	= '/tmp/topics.txt';

# To get \n recognized we need to pipe text into sqlite3 via `...`.

`echo 'Table name: constants' > $log_path`;
`echo ".headers on\n.mode csv\nselect id,name,value from constants order by id" | sqlite3 $db_path >> $log_path`;
`echo 'Table name: modules' >> $log_path`;
`echo ".headers on\n.mode csv\nselect id,name,timestamp from modules order by id" | sqlite3 $db_path >> $log_path`;
`echo 'Table name: topics' >> $log_path`;
`echo ".headers on\n.mode csv\nselect id,parent_id,title,text,timestamp from topics order by id" | sqlite3 $db_path >> $log_path`;
