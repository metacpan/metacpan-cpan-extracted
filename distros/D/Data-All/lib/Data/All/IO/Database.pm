package Data::All::IO::Database;

#   $Id: Database.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $


use strict;
no warnings;

use Data::All::IO::Base;
use DBI;

our $VERSION = 0.16;

attribute '__DBH';
attribute '__STH';

attribute 'format';
attribute 'fields';
attribute 'ioconf';
attribute   'path';

attribute 'is_open'             => 0;

sub open($)
{
    my $self = shift;
    my $query = $self->path()->[3];
    
    unless ($self->is_open())
    {
        #warn " -> Opening database connection for ", $self->ioconf()->{'perm'};
        #warn " -> path:", join ', ', @{ $self->path() };
        #warn " -> format:", $self->format()->{'type'};
        #warn " -> io:", $self->ioconf->{'type'};
        
        $self->_create_dbh();               #   Open DB connection
        if ($self->ioconf()->{'perm'} =~ /r/)
        {
            #warn " -> Executing query";
            
            my $sth = $self->__DBH()->prepare($query);
            $sth->execute() or die "Can't execute statement: $DBI::errstr";
            $self->__STH($sth);
            $self->_extract_fields();
        }
        
        $self->is_open(1);
    }
    
    return $self->is_open();
}

sub close()
{
    my $self = shift;

    $self->__STH()->finish()
    , $self->__DBH()->commit()     #   NOTE: uncomment this if autocommit = 0
        if ($self->__STH());

    $self->__DBH()->disconnect();
    $self->is_open(0);
    
    return;
}

sub nextrecord() { $_[0]->__STH()->fetchrow_hashref() }

sub getrecord_hash()
{
    my $self = shift; 
    my $sth = $self->__STH();

    return $sth->fetchrow_hashref();
}

sub getrecord_array() 
{ 
    my $self = shift; 
    my $record = $self->__STH()->fetchrow_arrayref();

    return !wantarray ? $record : @{ $record };
}

sub getrecords
{ 
    my $self = shift;
    
    return undef unless ($self->__STH()->rows);
    
    my (@records);
    while (my $ref = $self->__STH()->fetchrow_hashref())
    {
        push (@records, $ref);
    }

    return !wantarray ? \@records : @records;
    
}

sub putfields()
{
    my $self = shift;
    
    #   We don't do nothin' with fields for the database
    
    #   IDEA: Maybe we could use this call for creating a table
}


sub putrecord($;\%)
{
    my $self = shift;
    my ($record, $options) = @_;

    
    my @vars = $self->_generate_query_vars(
                            $options, $self->hash_to_array($record));
   
    #print join(':', @vars), "\n";
    
    $self->__STH($self->__DBH()->prepare($self->path()->[3]))
        unless $self->__STH();

    $self->__STH()->execute(@vars);
    
    return 1;
}


sub putrecords()
{
    my $self = shift;
    my ($records, $options) = @_;
    
    my $query = $self->path()->[3];

    
    die("$self->putrecords() needs records") unless ($#{ $records }+1);
        
    $self->__STH($self->__DBH()->prepare($query));
    
    my $record;
    foreach my $rec (@{ $records })
    {
        $self->putrecord($rec, $options);
    }
    
    #   Close the statement handle
    $self->__STH()->finish();
    
}

sub count()
#   TODO: Refactor this count() functionality.
#   What about INSERT queries. We could keep track of how many were
#   successfully inserted. 
{
    my $self = shift;
    my $query = $self->path()->[3];
    my ($sth, $ref, $count);
    
    return $count unless($self->ioconf()->{'perm'} =~ /^r/);
    
    $query =~ s/SELECT\s.+?\sFROM/SELECT COUNT(*) as cnt FROM/im;
    
    return undef unless ($sth = $self->__DBH()->prepare($query));
    
    $count = $self->__STH()->execute() or return undef;
    
    $self->__STH()->finish();
    
    return $count;
}





sub _generate_query_vars($$)
#   Create an ordered array of values to use in a DBI->execute() call to
#   replace '?' in the query.
{
    my $self = shift;
    my ($options, $vars) = @_;
    my @vars;
    
    #   TODO: Move arrayref checking to some form of option parser 
    
    if (defined($options->{'extra_pre_vars'}))
    {
        my @pre_vars = (ref($options->{'extra_pre_vars'}) eq 'ARRAY')
            ? @{ $options->{'extra_pre_vars'} }
            : ($options->{'extra_pre_vars'});
            
        #   Add the prefix values to the beginning of the array
        push(@vars, @pre_vars); 
    }
    
    #   Put the actual values into the array (in an INSERT, putrecord() will 
    #   send the ordered field values here)
    push(@vars, @{ $vars });
    
    #   Complete the array with the suffix values
    if (defined($options->{'extra_post_vars'}))
    {
        my @post_vars = (ref($options->{'extra_post_vars'}) eq 'ARRAY')
            ? @{ $options->{'extra_post_vars'} }
            : ($options->{'extra_post_vars'});
            
        #   Add the prefix values to the beginning of the array
        push(@vars, @post_vars); 
    }
         
    return wantarray ? @vars : \@vars; 
}

sub _create_dbh()
{
    my $self = shift;
    my $dbh = $self->__DBH() || $self->_db_connect();
    
    ($dbh)
        ? $self->__DBH($dbh)
        : die("Cannot create DB Connection");
        
    #$self->__DBH()->trace(2);
}

sub _create_sth()
{
    my $self = shift;
    my $sth = $self->__DBH()->prepare();
    
    ($sth)
        ? $self->__STH($sth)
        : die("Cannot prepare statement handle");
}

sub _db_connect()
{
    my $self = shift;
    return if ($self->is_open());
    #   NOTE: See line 53 if you want to set autocommit = 0
    return DBI->connect($self->_create_connect(), { PrintWarn=>1,PrintError=>1, RaiseError => 1, AutoCommit => 0 });
}

sub _create_connect()
{
    my $self = shift;
    return ($self->path()->[0],$self->path()->[1],$self->path()->[2]);
}

sub _extract_fields()
{
    my $self = shift;
    return if ($self->fields());
    
    $self->fields($self->__STH()->{'NAME'});
}



1;