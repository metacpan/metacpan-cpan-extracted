package DBIC::Violator::Collector::DbConn;

use strict;
use warnings;

# ABSTRACT: Collector connection object for DBIC::Violator

use Moo;
use Types::Standard qw(:all);
use Path::Class qw(file dir);
use Try::Tiny;

use DBI;

use RapidApp::Util ':all';

has 'Collector', is => 'ro', isa => InstanceOf['DBIC::Violator::Collector'], required => 1;

has 'db_file', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  
  my $C = $self->Collector;
  
  return $C->log_db_file if ($C->log_db_file);
  
  my $dir = $C->log_db_dir or die "DBIC::Violator::Collector: Must supply either log_db_file or log_db_dir";
  -d $dir or die "DBIC::Violator::Collector: log_db_dir '$dir' not exist or not a directory";
  
  my $Dir = dir($dir);
  
  my $pfx = $C->log_db_file_pfx;
  my $sfx = $C->log_db_file_sfx;
  my $num = 1;
  
  # We want to come after existing files, even if earlier inc files don't exist
  for my $Child ($Dir->children) {
    my $fn = $Child->basename;
    if($fn =~ /^${pfx}(\d+)${sfx}$/) {
      my $inc = $1 or next;
      $inc =~ s/^0+//;
      $num = $inc if ($inc > $num);
    }
  }
  
  my $fn = join('',$pfx,sprintf('%06s',$num),$sfx);
  $fn = join('',$pfx,sprintf('%06s',++$num),$sfx) while (-e $Dir->file($fn));
  
  return $Dir->file($fn)->absolute->stringify;
};

has 'db_filename', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  file($self->db_file)->basename
};

has 'connected_for_pid', is => 'rw', default => sub { 0 };

sub BUILD {
  my $self = shift;
  $self->_ensure_created_db_file;
}

sub DEMOLISH {
  my ($self, $in_global_destruction) = @_;
  try{$self->dbh->disconnect} if ($self->connected_for_pid && ! $in_global_destruction);
}

sub invalid {
  my $self = shift;
  if(my $pid = $self->connected_for_pid) {
    return 1 if (
         ! -f $self->db_file
      || $pid != $$
      || ! $self->dbh
      || $self->dbh->err
      || ! $self->dbh->ping
    );
  }
  return 0;
}


has 'dbh', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  $self->_ensure_created_db_file;
  
  my $dbh = $self->_call_connect;
  
  $self->connected_for_pid($$) if ($dbh);

  $dbh
};


sub _call_connect {
  my $self = shift;
  DBI->connect(join(':','dbi','SQLite',$self->db_file),'','', {
    AutoCommit => 1,
    sqlite_use_immediate_transaction => 0,
  });
}

sub _ensure_created_db_file {
  my $self = shift;
  return if (-f $self->db_file);
  
  warn "[DBIC::Violator($$)]: creating log db " . $self->db_filename . "\n";
  
  my $dbh = $self->_call_connect;
  $dbh->do($_) for (split(/;/,$self->_sqlite_ddl));
  
  $dbh->disconnect
}



sub _sqlite_ddl {
  my $self = shift;
  
  # Seed the auto inc based on the date/time in order to make it easier
  # to merge databases later on -- this should mostly prevent PK overlap
  #my $seed_autoinc = time - 1620604718;
  my $seed_autoinc = 0; # because of threads, this is pointless
  my $app_name = $self->Collector->application_name || 'unknown';

join('',
q~
CREATE TABLE [db_info] (
  [name]  varchar(64) primary key not null,
  [value] varchar(1024) default null
);
INSERT INTO [db_info] VALUES ('schema_deploy_datetime', datetime('now'));
INSERT INTO [db_info] VALUES ('application','~,$app_name,q~');
INSERT INTO [db_info] VALUES ('DBIC::Violator::VERSION','~,$DBIC::Violator::VERSION,q~');
INSERT INTO [db_info] VALUES ('seed_autoinc','~,$seed_autoinc,q~');
INSERT INTO [db_info] VALUES ('db_filename','~,$self->db_filename,q~');
INSERT INTO [db_info] VALUES ('db_directory','~,file($self->db_file)->parent->absolute,q~');

CREATE TABLE [request] (
  [id]                INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [start_ts]          integer NOT NULL,
  [remote_addr]       varchar(16) NOT NULL,
  [username]          varchar(32) DEFAULT NULL,
  [uri]               varchar(512) NOT NULL,
  [method]            varchar(8) NOT NULL,
  [user_agent]        varchar(1024) DEFAULT NULL,
  [referer]           varchar(512) DEFAULT NULL, 
  [status]            char(3) DEFAULT NULL,
  [res_length]        INTEGER DEFAULT NULL,
  [res_content_type]  varchar(64) DEFAULT NULL,
  [end_ts]            integer DEFAULT NULL,
  [elapsed_ms]        INTEGER DEFAULT NULL  
);
INSERT INTO sqlite_sequence (name,seq) VALUES ('request',~,$seed_autoinc,q~);

CREATE TABLE [query] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [unix_ts] integer NOT NULL,
  [request_id] INTEGER DEFAULT NULL,
  [dbi_driver] varchar(32) DEFAULT NULL,
  [schema_class] varchar(128) default NULL,
  [source_name] varchar(128) default NULL,
  [operation] varchar(6) DEFAULT NULL,
  [statement] text,
  [elapsed_ms]  INTEGER NOT NULL, 
  FOREIGN KEY ([request_id]) REFERENCES [request] ([id]) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO sqlite_sequence (name,seq) VALUES ('query',~,$seed_autoinc,q~);

~)}



1;

__END__

=head1 NAME

DBIC::Violator::Collector::DbConn - Collector connection object for DBIC::Violator

=head1 DESCRIPTION

This is an internal object class used by L<DBIC::Violator> and should not be used directly.

=head1 SEE ALSO

=over

=item * 

L<DBIC::Violator>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut