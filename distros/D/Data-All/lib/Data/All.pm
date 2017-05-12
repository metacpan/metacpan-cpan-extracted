package Data::All;

#   Data::All - Access to data in many formats source many places

#   TODO: Create Data::All::IO::Hash for internal storage
#   TODO: Add checking for output field names that aren't present in input field names
#   TODO: Auto reset file/db cursors? Call read() then convert() causes error;

use strict;
use warnings;
#use diagnostics;
 
use Data::Dumper;
use Data::All::Base;
use Data::All::IO;

our $VERSION = 0.042;
our @EXPORT = qw(collection);

##  PUBLIC INTERFACE
sub show_fields;    #   returns an arrayref of field names
sub collection;     #   A shortcut for open() and read()
sub getrecord;
sub putrecord;
sub is_open;
sub convert;        #   Change formats
sub store;          #   save in memory records
sub count;          #   Record count
sub close;
sub read;
sub open;

##  PUBLIC ATTRIBUTES
##  i.e. $da->source()
attribute           'source';
attribute           'target';
attribute     'print_fields' => 0;
attribute           'atomic' => 1;


##  PRIVATE ATTRIBUTES

#   Contains Data::All::IO::* object by moniker
internal 'collection'        => {};  

internal 'profile'     =>      
#   Hardcoded/commonly used format configs
{
    csv     => ['delim', "\n", ',', '"', '\\'],
    tab     => ['delim', "\n", "\t", '', '']
};

internal 'a2h_template'  =>    
#   Templates for converting arrayref configurations to 
#   internally used, easy to handle hashref configs. See _parse_args().
#   TODO: move this functionality into a generic arg parsing library
{
    'format.delim'      => ['type','break','delim','quote','escape'],
    'format.fixed'      => ['type','break','lengths'],
    'ioconf.file'       => ['type','perm','with_original'],
    'ioconf.ftp'        => ['type','perm','with_original'],
    'ioconf.db'         => ['type','perm','with_original']
};

internal 'default'     =>
#   Default values for configuration variables
{
    profile => 'csv',
    filters => '',
    ioconf  => 
    { 
        type    => 'file', 
        perm    => 'r', 
        with_original => 0 
    },
    format =>
    {
        type    => 'delim'
    }
};


BEGIN {
    Data::All::IO->register_factory_type(  file => 'Data::All::IO::File');
    #Data::All::IO->register_factory_type(   xml => 'Data::All::IO::XML');
    Data::All::IO->register_factory_type(    db => 'Data::All::IO::Database');
    #Data::All::IO->register_factory_type(   ftp => 'Data::All::IO::FTP');
}


#   CONSTRUCTOR RELATED
sub init()
#   Rekindle all that we are
{
    my $self = shift;
    
    my $args = $self->reinit(@_);
    return $self;
}

sub reinit
{
    my $self = shift;
    my $args;
 
    return undef unless ($_[0]);
    
    #   Allow for hash or hashref args
    $args = (ref($_[0]) eq 'HASH') ? $_[0] : { @_ };
    
    populate($self, $args);
    
    $self->prep_collections();
    
    return $args;
}



sub prep_collections()
#   Prepare and store an instance of Data::All::IO::* for source and to configs 
{
    my $self = shift;
    
    foreach (qw(source target))
    {
        $self->__collection()->{$_} = $self->_load_IO($self->$_())
            if (defined($self->$_()));
    }
}


sub _load_IO(\%)
#   Load an instance of Data::All::IO::? to memory
{
    my $self = shift;
    my $args = shift;

    $self->_parse_args($args);
    my ($ioconf, $format, $path, $fields) = @{ $args }{'ioconf','format','path','fields'};
    

    my $IO = Data::All::IO->new($ioconf->{'type'}, 
        { 
            ioconf  => $ioconf, 
            format  => $format, 
            path    => $path, 
            fields  => $fields
        });
        
    return $IO;
}

sub _parse_args()
#   Convert arrayref args into hashref, process determinable values, 
#   and apply defaults to the rest. We can also through a horrible
#   error at this point if there isn't enoguh info for Data::All to
#   continue.
{
    my $self = shift;
    my $args = shift;
   
    #   TODO: Allow collection('filename.csv', 'profile'); usage
    $self->_apply_profile_to_args($args);
    
    #   Make sure path is an array ref
    $args->{'path'} = [$args->{'path'}]  if (ref($args->{'path'}) ne 'ARRAY');
	
    for my $a (keys %{ $self->__default() })
    #   Apply default values to data collection configuration. Amplify arrayref 
    #   configs into hashref configs using the a2h_templates where appropriate.
    { 
        next if $a eq 'path';

        if (ref($args->{$a}) eq 'ARRAY')
        {
            my (%hash, $templ);
            $templ = join '', $a, '.', $args->{$a}->[0];
			
			$self->error("Wasn't expecting: $templ"), next unless(exists($self->__a2h_template()->{$templ}));
			
            @hash{@{$self->__a2h_template()->{$templ}}} = @{ $args->{$a} };
                        
            $args->{$a} = \%hash;
        }
        
        $self->_apply_default_to($a, $args);
    }
    
    return if ($args->{'moniker'});
    
    $args->{'moniker'} = ($args->{'ioconf'}->{'type'} ne 'db')
        ? join('', @{ $args->{'path'} })
        : '_';
    
}


sub _apply_profile_to_args(\%)
#   Populate format within args based on a preconfigured profile
{
    my $self = shift;
    my $args = shift;
	#print Dumper($args);
    my $p = $args->{'profile'} || $self->__default()->{'profile'};
    
    return if (exists($args->{'format'}));
    
    die("There is no profile for type $p ") 
        unless ($p && exists($self->__profile()->{$p}));
        
    #   Set the format using the requested profile
    $args->{'format'} = $self->__profile()->{$p};
    return;
}

sub _apply_default_to()
#   Set a default value to a particular attribute.
#   TODO: Allow setting of individual attribute fields
{
    my $self = shift;
    my ($a, $args) = @_;
    $args->{$a} = $self->__default()->{$a}
        unless (exists($args->{$a}));
    
    return unless (ref($args->{$a}) eq 'HASH');
    
    foreach my $c (keys %{ $self->__default()->{$a} })
    {
        $args->{$a}->{$c} = $self->__default()->{$a}->{$c}
            unless (defined($args->{$a}->{$c}));
    }

}



sub count(;$)
#   get a record count
{
    my $self = shift;
    my $which = shift || 'source';
    
    $self->open() unless ($self->is_open($which));
    return $self->__collection()->{$which}->count();
}


sub count_to(;$)
#   get a record count for the source config
{
    my $self = shift;
    return $self->count('target');
}


sub count_source(;$)
#   get a record count for the source config
{
    my $self = shift;
    return $self->count('source');
}

sub getrecord(;$$)
#   Get a single, consecutive record
{
    my $self = shift;
    my $type = shift || 'hash';
    my $meth = 'getrecord_' . $type;
    my $record;
    
#    $record = ($self->__collection()->{'source'}->can($meth))
#        ? $self->__collection()->{'source'}->$meth()
#        : undef;

    return $self->__collection()->{'source'}->getrecord_hash();
}

sub putrecord()
#   Put a single, consecutive record
{
    my $self = shift;
    my $record = shift || return undef;
    
    $self->__collection()->{'target'}->putrecord()
}


sub collection(%)
#   Shorthand for creating a Data::All instance, openning, reading
#   and closing the data source
{
    my ($conf1, $conf2) = @_;
    my ($myself, $rec);
    
    #   We can accept standard-arg style, but we will also make provisions
    #   for a single hashref arg which we'll assume is the 'source' config
    $myself = (ref($_[0]) ne 'HASH')
        ? new('Data::All', @_)
        : new('Data::All', source => $_[0]);
        
    $myself->open();
    $rec = $myself->read();
    $myself->close();
    
    return (!wantarray) ? $rec : @{ $rec };
}

sub open(;$)
{
    my $self = shift;
    #my $which = shift || 'source';
    
    foreach my $source (keys %{ $self->__collection() })
    {
        $self->__collection()->{$source}->open();
        
        unless ($self->__collection()->{$source}->is_open())
        {
            $self->__ERROR($self->__collection()->{$source}->__ERROR());
            die "Cannot open ", $self->__collection()->{$source}->create_path();
        }
    }
    
    return;
}

sub close(;$)
{
    my $self = shift;
    #my $which = shift || 'source';
    
    foreach my $source (keys %{ $self->__collection() })
    {
        $self->__collection()->{$source}->close();
    }
    
    return;
}

sub show_fields(;$)
{
    my $self = shift;
    my $which = shift || 'source';
    $self->__collection()->{$which}->fields();
}

sub read(;$$)
{
    my $self = shift; 
    my $which = shift || 'source';
    
    $self->open();
    my $records = $self->__collection()->{$which}->getrecords();
    
    return !wantarray ? $records :   @{ $records };
}

sub store
#   Store data source an array ref (of hashes) into a Data::All enabled source
#    IN: (arrayref) of hashes -- your records
#         [ standard parameters ]
#   OUT: 
{
    my $self = shift;
    my $source = shift;
    my ($target, $bool);
    
    my $args = $self->reinit(@_);
    
    $target = $self->__collection()->{'target'};
    
    $target->open();
    
    $target->fields([keys %{ $source->[0] }])
        unless ($target->fields() && $#{ $target->fields() });
        
    $target->putfields()   if ($self->print_fields);

    #   Convert data in a wholesome fashion (rather than piecemeal)
    #   There is no point in doing it record by record b/c the 
    #   records we are storing are already in memory.
    $bool = $target->putrecords($source, $args) ;
    
    $target->close();
    
    return 1;
}

sub convert
#   Move data source one Data::All collection to another, using a simple 
#   source (source) and to (target) metaphor
#   TODO: need error detection
{
    my $self = shift;
    my ($source, $target, $bool);
    
    my $args = $self->reinit(@_);

    ($source, $target) = @{ $self->__collection() }{'source','target'};

    $source->open();
    $target->open();
    
    # TODO: Get fields source db SELECT before we copy to the $target->fields()
    
    #   Use the source's field names if the target's has none
    $target->fields($source->fields) unless ($target->fields() && $#{ $target->fields() });
 	

    #   Print the field names into the target
    #   TODO: If the field list is in the source collection, then the
    #   fields will appear twice in the target file. 
    $target->putfields()   if ($self->print_fields);
    
    if ($self->atomic) {
        #   Convert data in a wholesome fashion (rather than piecemeal)
        $bool = $target->putrecords([$source->getrecords()], $args) ;
    }
    else {
    #   Convert record by record (great for large family members!!!!!!!)
        while (my $rec = $source->getrecord_hash()) 
        { $bool = $target->putrecord($rec, $args) }
    }
    
    #   BUG: I commented this out for the extract specifically (delano - May 9) 
    #$target->close();
    #$source->close();
    
    return $bool;
}


sub write(;$$)
{
    my $self = shift;
    my $which = shift || 'source';
    my ($start, $count) = (shift || 0, shift || 0); 
        
}


sub is_open(;$)
{ 
    my $self = shift;
    my $which = shift || 'source';
    
    return $self->__collection()->{'source'}->is_open();
}










1;
__END__


=head1 NAME

Data::All - Access to data in many formats source many places

=head1 WARNING! This is a preview release. 
Version 0.040 is the first version to remove the libraries Spiffy and IO::All. 
These changes are fresh and need more testing but I decided to update CPAN since
the previous version 0.036 is broken. This is a preview release and should be
treated as a novelty until the preview status is removed. 


=head1 SYNOPSIS 1 (short)

    use Data::All;

	#   Create an instance of Data::All for database data
	my $input1 = Data::All->new(
	    source => { path => 'sample.csv', profile => 'csv' },
	    target   => { path => 'sample.tab',  profile => 'tab', ioconf  => ['file', 'w']}
	);

	#   $rec now contains an arrayref of hashrefs for the data defined in %db.
	my $rec  = $input1->read();

    #   Convert "source" to "target" and include the field names
    $input1->convert(print_fields => 1); 

    
=head1 SYNOPSIS 2 (long)

    use Data::All;
    
    my $dsn1     = 'DBI:mysql:database=mysql;host=YOURHOST;';
    my $dsn2     = 'DBI:Pg:database=SOMEOTHERDB;host=YOURHOST;';
    my $query1   = 'SELECT `Host`, `User`, `Password` FROM user';
    my $query2   = 'INSERT INTO users (`Password`, `User`, `Host`) VALUES(?,?,?)';
    
    my %db1 = 
    (   path        => [$dsn1, 'user', 'pass', $query1],
        ioconf      => ['db', 'r' ]
    );
    
    #   Notice how the parameters can be sent as a well-ordered arrayref
    #   or as an explicit hashref. 
    my %db2 = 
    (   path        => [$dsn2, 'user', 'pass', $query2],
        ioconf      => { type => 'db', perms => 'w' },
        fields      => ['Password', 'User', 'Host']
    );
    
    #   This is an explicit csv format. This is the same as using 
    #   profile => 'csv'. NOTE: the 'w' is significant as it is passed to 
    #   IO::All so it knows how to properly open and lock the file. 
    my %file1 = 
    (
        path        => ['/tmp/', 'users.csv'],
        ioconf      => ['plain', 'rw'],
        format      => {
            type    => 'delim', 
            breack  => "\n", 
            delim   => ',', 
            quote   => '"', 
            escape  => '\\',
        }
    );
    
    #   The only significantly different here is with_original => 1.
    #   This tells Data::All to include the original record as a field 
    #   value. The field name is _ORIGINAL. This is useful for processing
    #   data when auditing the original source is required.         
    my %file2 = 
    (
        path        => '/tmp/users.fixed',
        ioconf      => {type=> 'plain', perms => 'w', with_original => 1],
        format      => { 
            type    => 'fixed', 
            break   => "\n", 
            lengths => [32,16,64]
        },
        fields      => ['pass','user','host']
    );
    
    #   Create an instance of Data::All for database data.
    #   Note: parameters can also be a hash or hashref
    my $input2 = Data::All->new({
        source => %db1, 
        target => \%db2,
        print_fields => 0,              #   Do not output field name record
        atomic => 1                     #   Load the input completely before outputting
    });
    
    $input2->convert();                 #   Save the mysql data to the postgresql table 
    $input2->convert(target => \%file1);    #   And also save it to a CSV format
    $input2->convert(target => \%file2);    #   And also save it to a fixed format
    
    
=head1 DESCRIPTION

Data::All is based on a few abstracted concepts. The line is a record and a 
group of records is a collection. This allows a common record storing concept
to be used across any number of data sources (delimited file, XML over a socket,
a database table, etc...). 

Supported formats: delimited and fixed (for filesystem types)
Supported sources: local filesystem, database

Similar to AnyData, but more suited towards converting data types 
source and to various sources rather than reading data and playing with it. It is
like an extension to IO::All which gives you access to data sources; Data::All
gives you access to data. 

Conversion now happens record by record by default. You can set this explicitly
by sending atomic => 1 or 0 [default] through to new() or convert(). 


=head1 TODO LIST

Current major development areas are the interface and format 
stability. Upcoming development are breadth of features (more formats, more
sources, ease of use, reliable subclassing, documentation/tests, and speed).

Misc:
TODO:Allow a buffer to give some flexibility between record by record and atomic processing.
TODO:Add ability to create temporary files
TODO:Allow handling record fields with arrayrefs for anon / non-hash access
TODO:Default values for fields (avoid undef db errors)
TODO:Allow modifying data in memory and saving it back to a file
TODO:Consider using a standard internal structure, so every source is converted into this structure (hash, Stone?)
TODO:Add SQL as a readable input and output
TODO:Expose format functions to Data::All users so simple single record conversion can be thoroughly utilized.


=head1 KNOWN BUGS

- The record separator does not currently work properly as it is hardcoded 
to be newline (for delimited and fixed formats). 
- The examples/* aren't always 100% in sync with the latest changes to Data::All.
- If the first column is empty, it may screw up Data::All::Format::Delim (it
will return undef for that column and the remaining columns with shift left)


=head1 AUTHOR

Delano Mandelbaum, E<lt>delano<AT>cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Delano Mandelbaum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
