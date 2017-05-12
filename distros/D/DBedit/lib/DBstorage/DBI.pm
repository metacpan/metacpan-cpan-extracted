package DBstorage::DBI;

=head1 NAME
DBstorage::DBI - dbedit driver using DBI interfaces

=head1 DESCRIPTIONN
This is the DBI SQL driver for dbedit

=head1 TODO
Should encapsulate file headers in objects

=head1 LICENSE

Copyright (C) 2002 Globewide Network Academy
Relased under the SCHEME license see LICENSE.SCHEME.txt for details
=cut

use DBI;
use DBstorage;
use Symbol;

@DBstorage::DBI::ISA = qw(DBstorage);

use strict;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $connect = shift;
    my $self  = {};
    bless ($self, $class);
    $self->{'dbh'} = DBI->connect($connect);
    $self->{'nocursor'} = 1;
    return $self;
}

sub DESTROY {
    my($self) = @_;
    $self->{'dbh'}->disconnect();
}

sub find {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $foundref = shift;
    my $lastref = shift;
    my($field);
    my(@field_list) = ();
    %{$foundref} = ();
    my ($predicate_list) = $self->predicate_list($keyref, " and ");
    my ($command);
    if ($filename !~ /^select /i) {
	$command = "select * from " . $filename;
    } else {
	$command = $filename;
    }

    if ($command !~ / where /i) {
	$command .= " where " . $predicate_list;
    } else {
	$command .= " and " . $predicate_list;
    }
    
    if ($self->{'debug'}) {
	print "SQL Command: $command";
    }
    $self->{'sth'} = $self->{'dbh'}->prepare($command);
    $self->{'sth'}->execute;
    if (defined($self->{'sth'})) { 
	%{$foundref} = %{$self->{'sth'}->fetchrow_hashref};
    }
    $self->{'sth'}->finish;
}

sub get_nth {
    my $self = shift;
    my $filename = shift;
    my $record = shift;
    my $foundref = shift;
    my $lastref = shift;
    $self->{'sth'} = $self->{'dbh'}->prepare($filename);
    $self->{'sth'}->execute;
    $self->{'sth'}->fetchrow_arrayref;
    %{$foundref} = %{$self->{'sth'}->fetchrow_hashref};
    $self->{'sth'}->finish;
}

sub attrib {
    my $self = shift;
    my $file = shift;
}

sub delete {
    my $self = shift;
    my $table = shift;
    my $keyref = shift;
    my $delete_all = shift;
    my($command) = "delete from $table where ";
    $command .= $self->predicate_list($keyref, " and ");
    if ($self->{'debug'}) {
	print "SQL Command: $command<br>";
    }
    $self->{'dbh'}->do($command);

}

sub append {
    my $self = shift;
    my $table = shift;
    my $keyref = shift;
    my($command) = "insert into $table ";
    my($key);
    foreach $key (keys %{$keyref}) {
	if ($keyref->{$key} eq "") {
	    delete $keyref->{$key};
	}
    }
    my(@fields) = keys %{$keyref}; 
    my(@values) = map {$self->quote($_);}  @{$keyref}{@fields};

    $command .= "(" . join (", ", @fields) . ")";
    $command .= " values ";
    $command .= "(" . join (", ", @values) . ")";
    $| = 1;
    if ($self->{'debug'}) {
	print "SQL Command: $command<br>\n";
   }
    return $self->{'dbh'}->do($command);
}

sub replace {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $replace_ref = shift;
    my $replace_all = shift;
    my($command) = "update $filename ";
    $command .= " set " . $self->predicate_list_with_null($replace_ref, " , ");
    $command .= " where " . $self->predicate_list($keyref, " and ");
    if ($self->{'debug'}) {
	print "SQL Command: $command<br>";
    }
    $self->{'dbh'}->do($command);    
}

sub replace_regexp {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $replace_ref = shift;
    my $replace_all = shift;
}

sub create {
    my ($self, $filename, $fieldref) = @_;
    my ($command) = "create table $filename ";
    my ($field, @field_list);
    if ($self->{'debug'}) {
	print "SQL Command: $command<br>";
    }
    
    foreach $field (keys %{$fieldref}) {
	push (@field_list, "$field $fieldref->{$field}");
    }

    $command .= "(" . join (", ", @field_list) . ")";
    $self->{'dbh'}->do($command);    
}


sub open {
    my $self = shift;
    my $filename = shift;
    my $filehandle = shift;
    my $line;
    my $command;

    if ($filename =~ /^select/i) {
	$command = $filename;
    } else {
	$command = "select * from $filename";
    }
    if ($self->{'debug'}) {
	print "SQL Command: $command<br>";
    }

    $self->{'sth'} = $self->{'dbh'}->prepare($command);
    $self->{'sth'}->execute;
    $self->{'FIELDS'} = $self->{'sth'}->{'NAME'};

    if ($self->{'sth'} eq undef) {
	return 0;
    } else {
	return 1;
    }
}

sub read {
    my $self = shift;
    my $hashref = shift;
    my($ref) = $self->{'sth'}->fetchrow_hashref;

    if ($ref eq undef) {
	return 0;
    } else {
	%{$hashref} = %{$ref};
	return 1;
    }
}

sub read_array {
    my $self = shift;
    my $arrayref = shift;
    my $ref = $self->{'sth'}->fetchrow_arrayref;

    if ($ref eq undef) {
	return 0;
    } else {
	@{$arrayref} = @{$ref};
	return 1;
    }
}


sub close {
    my $self = shift;
    $self->{'sth'}->finish();
}

sub fields {
    my $self = shift;
    return @{$self->{'FIELDS'}};
}

sub type {
    my $self = shift;
}

sub predicate_list {
    my $self = shift;
    my $hashref = shift;
    my $join = shift;
    my(@field_list) = ();
    my($field);

    foreach $field (keys %{$hashref}) {
	if ($field ne "") {
	    if ($hashref->{$field} ne "") {
		push(@field_list, "$field = "  . 
		     $self->quote($hashref->{$field}));;
	    } else {
		push(@field_list, "($field = '' or $field is null)");
	    }
	}
    }
    return join($join, @field_list);
}    


sub predicate_list_with_null {
    my $self = shift;
    my $hashref = shift;
    my $join = shift;
    my(@field_list) = ();
    my($field);

    foreach $field (keys %{$hashref}) {
	if ($hashref->{$field} ne "") {
	    push(@field_list, "$field = "  . 
		 $self->quote($hashref->{$field}));;
	} else {
	    push(@field_list, "$field = NULL");
	}
    }
    return join($join, @field_list);
}    

sub errstr {
    my $self = shift;
    return $self->{'dbh'}->errstr();
}

sub quote {
    my $self = shift;
    my $item = shift;
    return $self->{'dbh'}->quote($item);
}

sub do {
    my $self = shift;
    my $command = shift;
    return $self->{'dbh'}->do($command);
}

sub commit {
    my $self = shift;
    my $ofile = shift;
    my $nfile = shift;

    my ($dbh) = $self->{'dbh'};
    my ($old_auto_commit) = $dbh->{'AutoCommit'}; 
    my ($old_raise_error) = $dbh->{'RaiseError'}; 
    $dbh->{'AutoCommit'} = 0;
    $dbh->{'RaiseError'} = 1;
    eval {
	$dbh->do("drop table $ofile");
	$dbh->do("alter table $nfile rename to $ofile");
	$dbh->commit();
    };
    if ($@) {
	warn "Transaction aborted because $@";
	$dbh->rollback();
    }
    $dbh->{'AutoCommit'} = $old_auto_commit;
    $dbh->{'RaiseError'} = $old_raise_error;
}

1;






