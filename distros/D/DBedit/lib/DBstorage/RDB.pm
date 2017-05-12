package DBstorage::RDB;

=head1 NAME
DBstorage::RDB - dbedit driver for /rdb tables

DBstorage::RandRDB - dbedit driver for free version of rdb written by RANDD

=head1 DESCRIPTIONN
This is the RDB driver for dbedit

=head1 TODO
Should encapsulate file headers in objects

=head1 LICENSE

Copyright (C) 2002 Globewide Network Academy
Relased under the SCHEME license see LICENSE.SCHEME.txt for details

=cut

use DBstorage;
use DBfilelock;
use Symbol;
use Carp;

@DBstorage::RDB::ISA = qw(DBstorage);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{'FILEHANDLE'} = undef;
    $self->{'FIELDS'} = [];
    $self->{'TYPE'} = {};

    $self->{'CO'} = `which co`;
    $self->{'CO'} =~ s/\n//g;
    $self->{'CI'} = `which ci`;
    $self->{'CI'} =~ s/\n//g;

    $self->{'tabletolist'} = "tabletolist";
    $self->{'listtotable'} = "listtotable";
    $self->{'firstline'} = 0;
    bless ($self, $class);
    if (@_) {$self->open(@_)};
    return $self;
}

sub find {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $foundref = shift;
    my $lastref = shift;
    my ($key, $value);
    my ($record, %cookie);
    local ($_);
    local (*FILE);

    if ($filename ne $cookie{'filename'}) {
	%cookie = ();
    }

    ${$lastref} = 0;
    $record = 0;
    $self->open($filename, "FILE") || croak;
  loop:
    while ($self->read($foundref)) {
	${$lastref}++;
        my ($restart) = keys %{$keyref};
	while (($key, $value) = each %{$keyref}) {
	    ($value ne $foundref->{$key}) && next loop;
        }

    $record = ${$lastref}; 
    last;
}
#    if (defined($cookie{'nrecords'})) {
#	${$lastref} = $cookie{'nrecords'};
#    } else {
	while (<FILE>) {
	    ($_ ne "\n") && ${$lastref}++;
	}
#   }
    $self->close();
# If we didn't find anything, erase the array
    $record || (%{$foundref} = ());
    return $record;

}

sub get_nth {
    my $self = shift;
    my $filename = shift;
    my $record = shift;
    my $foundref = shift;
    my $lastref = shift;
    my $last;

    local ($_);
    $self->open($filename, "FILE") || return 0;
    $last = 1;

    while ($last < $record) {
	$_ = <FILE>;
	($_ ne "\n") && $last++;
    }

    $self->read($foundref) || ($record = 0);

    while(<FILE>) {
	($_ ne "\n") && $last++;
    }

    $self->close();
    ${$lastref} = $last;
    return $record;
}

sub attrib {
    my $self = shift;
    my $file = shift;
    my (%type, @fields);
	local(*TYPE);
    open(TYPE, $file) || croak;
    $_ = <TYPE>;
    chop;
    if ($_ =~ /^\s*$/) {
	while(<TYPE>) {
	    chop;
	    /^\s*$/ && last;
	    /^([^\t]+)/ && push(@fields, $1);
	}
	if (@fields == 0) {
	    $type{"type"} = "none";
	} else {
	    $type{"type"} = "list";
	$type{'fields'} = \@fields;
	}
	return %type;
    } else {
	@fields = split(/\t/);
	$type{'fields'} = \@fields;
	$type{"type"} ="table";
    }
    close(TYPE);
    $self->{'TYPE'} = \%type;

    return %type;
}

sub delete {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $delete_all = shift;

    my(%keys) = %{$keyref};
    my(@keys) = keys %keys;
    my (%type, @fields, %f);
    local ($_);

    my $lock = DBfilelock->new("${filename}.lck");
    $self->open($filename, "INPUT_TABLE");
    if ($self->type() eq "table") {
	open (OUTPUT_TABLE, ">/tmp/delete1.$$");
    } elsif ($self->type() eq "list") {
	open (OUTPUT_TABLE, "| $self->{'tabletolist'} > /tmp/delete1.$$");
    } else {
	print "Unknown table type $self->type()!!!!";
	exit;
    }
    @fields = @{$self->{'FIELDS'}};

    print OUTPUT_TABLE $self->table_header($self->{'FIELDS'});
  loop:
    while ($self->read(\%f)) {
	foreach (@keys) {
	     if ($keys{$_} ne $f{$_}) {
		 print OUTPUT_TABLE join("\t", @f{@fields}), "\n";
		 next loop;
	     }
	}
	$delete_all || last loop;
    }
    while(<INPUT_TABLE>) {
	print OUTPUT_TABLE;
    }
    close(OUTPUT_TABLE);

    $self->close();
    $self->commit($filename, "/tmp/delete1.$$");
    $lock->release();

}


sub append {
    my $self = shift;
    my $table = shift;
    my $hashref = shift;

    my %inarray = %{$hashref};

    my (%type, @fields, $output);

    foreach (keys %inarray) {
#	remove forward and trailing space
	$inarray{$_} =~ s/^\s+(.*)/$1/g;
	$inarray{$_} =~ s/(.*)\s+$/$1/g;
	$inarray{$_} =~ s/\s+/ /g;
    }

    my $lock = DBfilelock->new("${table}.lck");

    if (!-e $table || -z $table) {
	open("FILE", ">$table") || croak "Cannot open";
	$_ = join("\t", grep(!/^RDB/, sort (keys %inarray)));
	print FILE  "$_\n";
	s/[^\t]/\-/g;
	print FILE  "$_\n";
	close FILE;
    } 

    %type = $self->attrib($table);
    @fields = @{$type{"fields"}};
    if ($type{"type"} eq "list") {
	open (FILE, ">/tmp/file.$$");
	open (INPUT_FILE, $table);
	while (<INPUT_FILE>) {
	    print FILE $_;
	    $output = $_;
	}
	close(INPUT_FILE);
	if ($output !~ /^\s*$/) {	
	    print FILE "\n";
	}
	foreach (@fields) {
	    print FILE "$_\t$inarray{$_}\n";
	}
	close (FILE);
    } elsif($type{"type"} eq "table") {
	`cp $table /tmp/file.$$`;
	chmod 0664, "/tmp/file.$$";
	open (FILE ,">>/tmp/file.$$");
	print FILE join("\t", @inarray{@fields}) . "\n";
	close (FILE);
    } else {
	$lock->release();
	croak;
    }
    $self->commit($table, "/tmp/file.$$");	
    $lock->release();
    %{$hashref} = %inarray;
}

sub replace {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $replace_ref = shift;
    my $replace_all = shift;

    my %keys = %{$keyref};
    my %replace_values = %{$replace_ref};


    my (@keys) = keys %keys;
    my (@replace_keys) = keys %replace_values;
    my (%type, @fields, %f, $invalue, $input_line, %cookie);
    local ($_);
    my ($nrecords);

    my ($lock) = DBfilelock->new("$filename.lck");

    $self->open($filename, "INPUT_TABLE");
    if ($self->type() eq "table") {
	open (OUTPUT_TABLE, ">/tmp/replace1.$$");
    } elsif ($self->type() eq "list") {
	open (OUTPUT_TABLE, "| $self->{'tabletolist'} > /tmp/replace1.$$");
    } else {
	print "Unknown table type $type{'type'}!!!!";
	exit;
    }
    print OUTPUT_TABLE $self->table_header($self->{'FIELDS'});
    @fields = @{$self->{'FIELDS'}};
  loop:

# Break an abstraction barrier for speed
    while ($input_line = <INPUT_TABLE>) {
	chop $input_line;
	if ($input_line ne "") {
	    @f{@fields} = split("\t", $input_line);
	    $nrecords++;
	} else {
	    next loop;
	}

	foreach (@keys) {
	    if ($keys{$_} ne $f{$_}) {
		print OUTPUT_TABLE $input_line, "\n";
		next loop;
	    }
	}


	foreach (@replace_keys) {
	    $invalue = $replace_values{$_};
	    $invalue =~ s/^\s+//;
	    $invalue =~ s/\s+$//;
	    $invalue =~ s/\s+/ /g;
	    $f{$_} = $invalue;
	}
#	if ($cookie{'seek'} == 0) {
#	    $cookie{'seek'} = tell(INPUT_TABLE) - length($input_line) - 1;
#	    if ($cookie{'seek'} < 0) {
#		$cookie{'seek'} = 0;
#	    }
#	    $cookie{'record_num'} = $nrecords;
#	}
	print OUTPUT_TABLE join("\t", @f{@fields}), "\n";
	$replace_all || last loop;
    }
    while(<INPUT_TABLE>) {
	if ($_ ne "\n") {
	    print OUTPUT_TABLE;
	    $nrecords++;
	}
    }
    $cookie{'nrecords'} = $nrecords;

    close(OUTPUT_TABLE);
    $self->close();
    $self->commit($filename, "/tmp/replace1.$$");
   $lock->release();

}

sub replace_regexp {
    my $self = shift;
    my $filename = shift;
    my $keyref = shift;
    my $replace_ref = shift;
    my $replace_all = shift;

    my %keys = %{$keyref};
    my %replace_values = %{$replace_ref};


    my (@keys) = keys %keys;
    my (@replace_keys) = keys %replace_values;
    my (%type, @fields, %f, $invalue, $input_line);
    local ($_);
    my ($nrecords);

    my(%cookie) = ();

    my ($lock) = DBfilelock->new("$filename.lck");
    $self->open($filename, "INPUT_TABLE");
    if ($self->type() eq "table") {
	open (OUTPUT_TABLE, ">/tmp/replace1.$$");
    } elsif ($self->type() eq "list") {
	open (OUTPUT_TABLE, "| $self->{'tabletolist'} > /tmp/replace1.$$");
    } else {
	print "Unknown table type $type{'type'}!!!!";
	exit;
    }


    print OUTPUT_TABLE $self->table_header($self->{'FIELDS'});
    @fields = @{$self->{'FIELDS'}};
  loop:
# Break an abstraction barrier for speed
    while ($input_line = <INPUT_TABLE>) {
	chop $input_line;
	if ($input_line ne "") {
	    @f{$self->fields()} = split("\t", $input_line);
	    $nrecords++;
	} else {
	    next loop;
	}

	foreach (@keys) {
	    if ($f{$_} !~ $keys{$_}) {
		print OUTPUT_TABLE $input_line, "\n";
		next loop;
	    }
	}

	foreach (@replace_keys) {
	    $invalue = $replace_values{$_};
	    $invalue =~ s/^\s+//;
	    $invalue =~ s/\s+$//;
	    $invalue =~ s/\s+/ /g;
	    if ($keys{$_} ne "") {
		eval "\$f{$_} =~ s/$keys{$_}/$invalue/";
	    } else {
		$f{$_} = $invalue;
	    }
	}
	print OUTPUT_TABLE join("\t", @f{@fields}), "\n";
	$replace_all || last loop;
    }
    while(<INPUT_TABLE>) {
	if ($_ ne "\n") {
	    print OUTPUT_TABLE;
	    $nrecords++;
	}
    }
    $cookie{'nrecords'} = $nrecords;

    close(OUTPUT_TABLE);
    $self->close();
    $self->commit($filename, "/tmp/replace1.$$");
    $lock->release();
}

sub commit {
    my $self = shift;
    my $filename = shift;
    my $newfilename = shift;
    my($has_rcs, $checkin, $checkout);
    my(@list) = split(/\//, $filename);
    my($file) = pop @list;
    my($dir) = join("/", @list);
    my($rcsfile) = "$dir/RCS/$file,v";

    if (-z $newfilename) {
	print "$newfilename is a zero length file.  Aborting....";
	croak;
    }

    $has_rcs = ((-e "$filename,v") || (-e $rcsfile));

    if (!-e $filename) {
	`mv $newfilename $filename`;
    }

    if (!-w $filename && $has_rcs) {
	$checkout = $self->checkout($filename, "-l");
	$checkin =  $self->checkin($filename, 
			 "-u", "Checked in by $ENV{'REMOTE_USER'}");
	`$checkout
cp $filename $filename.bak
mv $newfilename $filename
$checkin &`;
    }  elsif (-w $filename && $has_rcs) {
	$checkin = $self->checkin($filename, 
			 "-l", "Checked in by $ENV{'REMOTE_USER'}");
	`cp $filename $filename.bak
mv $newfilename $filename
$checkin &`;
    } elsif (-w $filename && !$has_rcs) {
	`cp $filename $filename.bak
mv $newfilename $filename`;
    } else {
	print "Error cannot write to file $filename";
	croak;
    }
    if (-e "${filename}.bak") {
	chmod 0666, "${filename}.bak";
    }
}

sub checkout {
    my ($self, $filename, $options) = @_;
    return "$self->{'CO'} $options $filename 2> /dev/null";
}

sub checkin {
    my ($self, $filename, $options, $message) = @_;
    return "echo '$message' | $self->{'CI'} $options $filename 2> /dev/null";
}

sub create {
    my ($self, $filename, $fieldref) = @_;
    local (*FILE);
    if (!-e $filename) {
	open(FILE, ">$filename");
	print FILE $self->table_header($fieldref);
	close(FILE);
    }
}

sub table_header {
    my($self, $fieldref) = @_;
    if (!defined($fieldref)) {
       $fieldref = $self->{'FIELDS'};
    }
    my($header) = join("\t", @{$fieldref});
    my($return_value) = $header;
    $return_value .= "\n";
    $header =~ s/\S/\-/g;
    $return_value .= $header;
    $return_value .= "\n";
    return $return_value;
}


sub open {
    my $self = shift;
    my $filename = shift;
    my $filehandle = shift;
    my $line;

    if (!defined($filehandle)) {
	$filehandle = gensym;
    }

    ($filehandle ne "STDIN") &&
	(open($filehandle, $filename) || return 0);
    $line = readline(*$filehandle);
    if ($line =~ /^\s*$/) {
	close($filehandle);
	($filehandle ne "STDIN") &&
	    (open($filehandle, "$self->{'listtotable'} < $filename |") ||
	     return 0);
	$line = <$filehandle>;
	chop;
	$self->{'TYPE'}->{"type"} = "list";
    } else {
	$self->{'TYPE'}->{"type"} = "table";
    }

    $self->{'FILEHANDLE'} = $filehandle;
	chop $line;
	my @fields = split("\t", $line);
    $self->{'FIELDS'} = \@fields;
    $self->{'firstline'} = 1;
    return 1;
}

sub read {
    my $self = shift;
    my $hashref = shift;
    my $line;
    my $filehandle = $self->{'FILEHANDLE'};

    while ($line = readline(*$filehandle)) {
	if ($self->{'firstline'}) {
	    $self->{'firstline'} = 0;
	    if ($line =~ /^\-/) {
		next;
	    } 
	}
	chop $line;
	if ($line ne "") {
	    @{$hashref}{@{$self->{'FIELDS'}}} = split("\t", $line);
	    return 1;
	}
    }
    return 0;
}

sub close {
    my $self = shift;
    if ($self->{'FILEHANDLE'} ne "STDIN") {
	close $self->{'FILEHANDLE'};
    }
    $self->{'FILEHANDLE'} = undef;
}

sub fields {
    my $self = shift;
    return @{$self->{'FIELDS'}};
}

sub type {
    my $self = shift;
    return $self->{'TYPE'}->{"type"};
}

sub exists {
    my $self = shift;
    my $filename = shift;
    return (-r $filename);
}

package DBstorage::RandRDB;
@DBstorage::RandRDB::ISA = qw(DBstorage::RDB DBstorage);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{'FILEHANDLE'} = undef;
    $self->{'FIELDS'} = [];
    $self->{'TYPE'} = {};

    $self->{'tabletolist'} = "tbl2lst";
    $self->{'listtotable'} = "lst2tbl";
    bless ($self, $class);
    if (@_) {$self->open(@_)};
    return $self;
}

1;








