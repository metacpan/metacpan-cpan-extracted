package Data::PrintUtils;

use 5.9.5;
use strict;
use warnings;
use feature 'say';
use XML::Simple;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use Getopt::CommandLineExports qw(:ALL);
use HTML::Tabulate qw(render);
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
    
=head1 NAME

Data::PrintUtils - A Collection of Pretty Print routines like Data::Dumper

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

Provides a collection of pretty print routines

=head1 PURPOSE

This module is meant to provide some Data::Dumper like print routines tailored to
DBI style tables and hashes along with some debug options


=head1 EXPORT

print_pid 
say_pid 
formatList 
formatOneLineHash 
formatHash        
formatTable 
pivotTable 
joinTable 
$USE_PIDS 
$USE_TIME

=head1 SUBROUTINES/METHODS


=cut
package Data::PrintUtils;
BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    @ISA = qw(Exporter);
    @EXPORT_OK = qw();
    %EXPORT_TAGS = ( ALL => [ qw!&print_pid &say_pid &formatList &formatOneLineHash &formatHash
        &formatTable &pivotTable &joinTable $USE_PIDS $USE_TIME! ], ); # eg: TAG => [ qw!name1 name2! ],

#your exported package globals go here,
#as well as any optionally exported functions
    @EXPORT_OK = qw(&print_pid &say_pid &formatList &formatOneLineHash &formatHash
        &formatTable &pivotTable &joinTable $USE_PIDS $USE_TIME);
}

our $USE_PIDS = 0;
our $USE_TIME = 0;

=head2 print_pid

A replacement for print that will optionally prepend the processID and the timestamp to a line

These two fields are turned off/on with the package variables:

    $Data::PrintUtils::USE_PIDS = 1 or 0;
    $Data::PrintUtils::USE_TIME = 1 or 0;
    

=cut

sub print_pid { CORE::print "$$ : " if $USE_PIDS; CORE::print join(".", gettimeofday()) . " : " if $USE_TIME; CORE::print @_;};

=head2 say_pid

A replacement for say that will optionally prepend the processID and the timestamp to a line

These two fields are turned off/on with the package variables:

    $Data::PrintUtils::USE_PIDS = 1 or 0;
    $Data::PrintUtils::USE_TIME = 1 or 0;
    
=cut

sub say_pid   { CORE::print "$$ : " if $USE_PIDS; CORE::print join(".", gettimeofday()) . " : " if $USE_TIME; CORE::say   @_;};

=head2 formatList

Formats a list as a single line of comma seperated values in '(' ')'

An optional hash may be passed as the first argument to configure the following:

	LIST_START          => "(", # The String denoting the start of the list
	LIST_END            => ")", # The String denoting the end of the list
	ELEMENT_SEPARATOR   => ", ",  # The String seperating elements of the list

Note that these means that the unadorned list may not start with a hash ref :(


=cut

sub formatList
{
    my $argref = undef;
    if (ref $_[0]  eq "HASH" and
        (defined $_[0]->{LIST_START} or
        defined $_[0]->{LIST_END} or
        defined $_[0]->{ELEMENT_SEPARATOR}))
    {
        $argref = shift;
    }
    my %h = (
        LIST_START          => "(",
        LIST_END            => ")",
        ELEMENT_SEPARATOR   => ", ",
    );
    %h = (%h, ( parseArgs [$argref], 'LIST_START=s', 'LIST_END=s','ELEMENT_SEPARATOR=s',),) if defined $argref;
    return $h{LIST_START} . join ($h{ELEMENT_SEPARATOR},@_) . $h{LIST_END};
}


=head2 formatOneLineHash

Formats a hash as a single line of => and comma separated values in '{' '}'

The hash to be printed is passed as a reference in the first parameter
The rest of the arguments are parsed as options in Getopt::CommandLineExports format:

	PRIMARY_KEY_ORDER       => undef, # ordering for the has keys (undef means undefined perl ordering)
	HASH_START              => "{",   # String denoting the start of the hash 
	HASH_END                => "}",   # String denoting the end of the hash 
	ELEMENT_SEPARATOR       => ", ",  # String seperating the key/value pairs of the hash 
	KEY_VALUE_SEPARATOR     => " => ",# String seperating the keys and the values of the hash
	UNDEF_VALUE             => "undef", # String to print if the  value of the hash is undefined or if the key does not exist, but does in the PRIMARY_KEY_ORDER
	NOTEXIST_VALUE          => "notExist", # String to print if the key does not exist, but does in the PRIMARY_KEY_ORDER

=cut

sub formatOneLineHash
{
    my $href = shift;
    my %h = (
        PRIMARY_KEY_ORDER       => undef,
        HASH_START              => "{",
        HASH_END                => "}",
        ELEMENT_SEPARATOR       => ", ", 
        KEY_VALUE_SEPARATOR     => " => ",
        UNDEF_VALUE             => "undef",                
        NOTEXIST_VALUE          => "notExist",
        ( parseArgs \@_, 'PRIMARY_KEY_ORDER=s@', 'HASH_START=s', 'HASH_END=s', 'ELEMENT_SEPARATOR=s', 'KEY_VALUE_SEPARATOR=s', 'UNDEF_VALUE=s', 'NOTEXIST_VALUE=s'),
    );    
    my %x = %$href;
    my $s = $h{HASH_START};
    my @primeKeys  =  defined $h{PRIMARY_KEY_ORDER}    ? @{$h{PRIMARY_KEY_ORDER}}   : keys %$href;    
    my @keyvals = ();
    for( @primeKeys )
    {
        push @keyvals , $_ . $h{KEY_VALUE_SEPARATOR} . $h{NOTEXIST_VALUE} unless exists  $href->{$_};
        push @keyvals , $_ . $h{KEY_VALUE_SEPARATOR} . $href->{$_}        if defined     $href->{$_};
        push @keyvals , $_ . $h{KEY_VALUE_SEPARATOR} . $h{UNDEF_VALUE}    if (not defined $href->{$_} and exists $href->{$_});
    }
    $s = $s . join ($h{ELEMENT_SEPARATOR},  @keyvals) . $h{HASH_END};
}



=head2 formatHash

Formats a Hash with one level deep expansion
Each key/value pair is a single line that may be justified right or left for prettiness

	KEY_JUSTIFCATION    => 'Right', # justifcation (Right or Left) for the key column
	VALUE_JUSTIFICATION => 'Left', # justifcation (Right or Left)  for the Value column
	MAX_KEY_WIDTH       => 10000, # maximum column width for the key column
	MAX_VALUE_WIDTH     => 10000, # maximum column width for the Value column
	PRIMARY_KEY_ORDER   => undef, # ordering for the hash keys (undef means undefined perl ordering)
	SECONDARY_KEY_ORDER => undef, # ordering for the hash keys of any sub keys (undef means undefined perl ordering)
	KEY_VALUE_SEPARATOR     => " => ",# String seperating the keys and the values of the hash
	UNDEF_VALUE             => "undef", # String to print if the  value of the hash is undefined or if the key does not exist, but does in the PRIMARY_KEY_ORDER
	NOTEXIST_VALUE          => "notExist", # String to print if the key does not exist, but does in the PRIMARY_KEY_ORDER

=cut

sub formatHash
{
    my $hash_ref = shift;
    my %h = (
            KEY_JUSTIFCATION    => 'Right',
            VALUE_JUSTIFICATION => 'Left',
            MAX_KEY_WIDTH       => 10000,
            MAX_VALUE_WIDTH     => 10000,
            PRIMARY_KEY_ORDER   => undef,
            SECONDARY_KEY_ORDER => undef,
			UNDEF_VALUE         => "undef\n",                
			NOTEXIST_VALUE      => "notExist\n",
			KEY_VALUE_SEPARATOR => " => ",
        ( parseArgs \@_, 'KEY_JUSTIFCATION=s', 'VALUE_JUSTIFICATION=s', 'MAX_KEY_WIDTH=i', 'MAX_VALUE_WIDTH=i', 'PRIMARY_KEY_ORDER=s@', 'SECONDARY_KEY_ORDER=s@', 'KEY_VALUE_SEPARATOR=s', 'UNDEF_VALUE=s', 'NOTEXIST_VALUE=s'),
    );
    my $maxKeyLen = 0;
    my $maxValLen = 0;
    $maxKeyLen = (length > $maxKeyLen) ? length : $maxKeyLen foreach (keys %$hash_ref);
    $maxValLen = (defined  $_) ? (length > $maxValLen) ? length : $maxValLen : 1 foreach (values %$hash_ref);
    $maxKeyLen = ($maxKeyLen > $h{MAX_KEY_WIDTH})   ? $h{MAX_KEY_WIDTH}   : $maxKeyLen;
    $maxValLen = ($maxValLen > $h{MAX_VALUE_WIDTH}) ? $h{MAX_VALUE_WIDTH} : $maxValLen;
    my $s ="";
    my $keyFormat   = $h{KEY_JUSTIFCATION}      eq 'Right' ? "%*.*s$h{KEY_VALUE_SEPARATOR}" : "%-*.*s$h{KEY_VALUE_SEPARATOR}";
    my $valueFormat = $h{VALUE_JUSTIFICATION}   eq 'Right' ? "%*.*s\n"   : "%-*.*s\n";
    my @primeKeys  =  defined $h{PRIMARY_KEY_ORDER}    ? @{$h{PRIMARY_KEY_ORDER}}   : keys %$hash_ref;
#    my @secondKeys =  defined $h{SECONDARY_KEY_ORDER}  ? @{$h{SECONDARY_KEY_ORDER}} : undef;
    
    for(@primeKeys)
    {
        $s = $s . sprintf($keyFormat,   $maxKeyLen, $h{MAX_KEY_WIDTH},    $_);
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatList(@{$hash_ref->{$_}}))          if  (ref $hash_ref->{$_} eq "ARRAY");
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatOneLineHash(\%{$hash_ref->{$_}}, {PRIMARY_KEY_ORDER => $h{SECONDARY_KEY_ORDER} } )) if  (ref $hash_ref->{$_} eq "HASH" and defined $h{SECONDARY_KEY_ORDER});
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatOneLineHash(\%{$hash_ref->{$_}}))  if  (ref $hash_ref->{$_} eq "HASH" and not defined $h{SECONDARY_KEY_ORDER});
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, $$hash_ref{$_} )                         if  (ref $hash_ref->{$_} eq "" and defined $hash_ref->{$_} );
        $s = $s . sprintf($h{UNDEF_VALUE})                         											      if  (ref $hash_ref->{$_} eq "" and not defined $hash_ref->{$_} and exists $hash_ref->{$_} );
        $s = $s . sprintf($h{NOTEXIST_VALUE})                         										      if  (ref $hash_ref->{$_} eq "" and not exists $hash_ref->{$_});
    }
    return $s;
}


=head2 formatTable

Formats a table (given as an array of hash references (as returned from DBI) ) into
a somewhat pleasant display.  With the Columns argument, you can chose to only
print a subset of the columns (and you can define the column ordering).

=over

=item ROWS

This is a reference to the table (which should be an array of hashes refs)

=item COLUMNS

This is a list of columns (in order) to be displayed

=item UNDEF_VALUE

This is a string value to be displayed whenever an item is "undefined"

=back

=cut

sub formatTable
{
    my %h = (
#        ROWS    => undef,
#        COLUMNS => undef,
        XML_REPORT              => undef,
        HTML_TABLE              => undef,        
        UNDEF_VALUE             => '',
        START_FIELD_DELIMITER   => '',
        END_FIELD_DELIMITER     => ' ',
        ROW_NAME 				=> 'row',
        ( parseArgs \@_, 'ROWS=s@', 'COLUMNS:s{0,99}', 'UNDEF_VALUE=s', 'START_FIELD_DELIMITER=s', 'END_FIELD_DELIMITER=s'),
    );
    my $array_of_hash_ref = $h{ROWS};
    my $listOfColumns = $h{COLUMNS};
    if (defined $h{HTML_TABLE})
    {
		my @List =(defined $listOfColumns ? @$listOfColumns : keys  %{$array_of_hash_ref->[0]});
        my $s ="";
        my @trimedArrayOfHashRefs = ();

        
		foreach my $hash_ref (@$array_of_hash_ref)
		{
	        my %x = ();
			$x{$_} = defined $hash_ref->{$_} ? $hash_ref->{$_} : $h{UNDEF_VALUE} foreach (@List);
			push @trimedArrayOfHashRefs, \%x;
		}
        my %labels;
        my $hr = $trimedArrayOfHashRefs[0];
        foreach my $v (keys %{$hr})
        {
            $labels{$v} = $v;
        }
        
        my $table_defn = { 
            table => { border => 0, cellpadding => 0, cellspacing => 3 },
            th => { class => 'foobar' },
            null => '&nbsp;',
            labels => \%labels,
            stripe => '#cccccc',
            fields => \@List,
        };
		return render(\@trimedArrayOfHashRefs, $table_defn);
    }
  	if (defined $h{XML_REPORT})
	{
		my @List =(defined $listOfColumns ? @$listOfColumns : keys  %{$array_of_hash_ref->[0]});
        my $s ="";
        my @trimedArrayOfHashRefs = ();
		foreach my $hash_ref (@$array_of_hash_ref)
		{
	        my %x = ();
			$x{$_} = defined $hash_ref->{$_} ? $hash_ref->{$_} : $h{UNDEF_VALUE} foreach (@List);
			push @trimedArrayOfHashRefs, \%x;
		}
		$s .= XML::Simple::XMLout($_, NoAttr => 1, RootName => $h{ROW_NAME} ) foreach @trimedArrayOfHashRefs;
		return $s;        
	}

    my %maxColumnWidth;
    foreach my $hash_ref (@$array_of_hash_ref)
    {
        my @List = (keys %$hash_ref, (defined $listOfColumns ? @$listOfColumns : undef ));
        pop @List unless defined $listOfColumns;
        foreach (@List)
        {
            $maxColumnWidth{$_} = (length > (defined $maxColumnWidth{$_} ? $maxColumnWidth{$_} : 0)) ? length : $maxColumnWidth{$_};
            if (defined $$hash_ref{$_})
            {
                $maxColumnWidth{$_} = (length $$hash_ref{$_} > (defined $maxColumnWidth{$_} ? $maxColumnWidth{$_} : 0)) ? length $$hash_ref{$_}: $maxColumnWidth{$_};
            }
        }
    }
    $maxColumnWidth{$_} = $maxColumnWidth{$_} > length $h{UNDEF_VALUE} ? $maxColumnWidth{$_} : length $h{UNDEF_VALUE} foreach (keys %maxColumnWidth);
#print header

    @$listOfColumns = keys %maxColumnWidth if (not defined $listOfColumns);
    my $s = "";
    $s = $s . sprintf("$h{START_FIELD_DELIMITER}%*s$h{END_FIELD_DELIMITER}", (defined $maxColumnWidth{$_}) ? ($maxColumnWidth{$_}) : length , $_) foreach (@$listOfColumns);
    $s = $s . "\n";
    foreach my $hash_ref (@$array_of_hash_ref)
    {
        $s = $s . sprintf("$h{START_FIELD_DELIMITER}%*s$h{END_FIELD_DELIMITER}", $maxColumnWidth{$_}, (defined $$hash_ref{$_} ? $$hash_ref{$_} : $h{UNDEF_VALUE})) foreach (@$listOfColumns);
        $s = $s . "\n";
    }
    return $s;
}

=head2 pivotTable

pivots an attribute-value table (given as an array of hash references (as returned from DBI) ) 
into a new table with a row for each unique PIVOT_KEY and a column for each attribute

example:

	my @table = 
	(
	{COL1 => 1, Name => 'PID',  VALUE => '1a', XTRA1 => '111'},
	{COL1 => 1, Name => 'SID',  VALUE => 's1', XTRA1 => '112'},
	{COL1 => 1, Name => 'XV1',  VALUE => 'YY', XTRA1 => '116'},
	{COL1 => 1, Name => 'XV2',  VALUE => 'XX', XTRA1 => '117'},

	{COL1 => 2, Name => 'PID',  VALUE => '2a', XTRA1 => '221'},
	{COL1 => 2, Name => 'SID',  VALUE => 's2', XTRA1 => '222'},
	{COL1 => 2, Name => 'XV2',  VALUE => 'XX2', XTRA1 => '224'},
	);
	my @newTable1 = pivotTable { ROWS => \@table, PIVOT_KEY => 'COL1', VALUE_HEADER_KEY=> 'Name', VALUE_KEY => 'VALUE'};
	say formatTable { ROWS => \@newTable1, UNDEF_VALUE => 'NULL'} if @newTable1;

results in 

	COL1 PID SID  XV1 XV2
	1  1a  s1   YY  XX
	2  2a  s2 NULL XX2
    
example:

	my @table = 
	(
	{COL1 => 1, Name => 'PID',  VALUE => '1a', XTRA1 => '111'},
	{COL1 => 1, Name => 'SID',  VALUE => 's1', XTRA1 => '112'},
	{COL1 => 1, Name => 'XV1',  VALUE => 'YY', XTRA1 => '116'},
	{COL1 => 1, Name => 'XV1',  VALUE => 'ZZ', XTRA1 => '116'},
	{COL1 => 1, Name => 'XV2',  VALUE => 'XX', XTRA1 => '117'},

	{COL1 => 2, Name => 'PID',  VALUE => '2a', XTRA1 => '221'},
	{COL1 => 2, Name => 'SID',  VALUE => 's2', XTRA1 => '222'},
	{COL1 => 2, Name => 'XV2',  VALUE => 'XX2', XTRA1 => '224'},
	);
	my @newTable1 = pivotTable { ROWS => \@table, PIVOT_KEY => 'COL1', VALUE_HEADER_KEY=> 'Name', VALUE_KEY => 'VALUE', CONCAT_DUPLICATE => 1};
	say formatTable { ROWS => \@newTable1, UNDEF_VALUE => 'NULL'} if @newTable1;

results in 

	COL1 PID SID  XV1      XV2
	1  1a    s1   YY | ZZ  XX
	2  2a    s2   NULL     XX2

=cut

sub pivotTable
{
    my %h = (
#            ROWS                => undef,
            PIVOT_KEY           => undef,
            VALUE_HEADER_KEY    => undef,
            VALUE_KEY           => undef,
            CONCAT_DUPLICATE    => 0,
            INCLUDE_IDENTICAL   => 0,
            SEPARATOR           => " | ",
        ( parseArgs \@_, 'ROWS=s@', 'PIVOT_KEY=s', 'VALUE_HEADER_KEY=s@', 'VALUE_KEY=s@', 'CONCAT_DUPLICATE=i', 'SEPARATOR=s'),
    );
    my $table_ref = $h{ROWS}; 
    my %newKeys;
    my @newTable = ();
    $h{VALUE_HEADER_KEY} = [$h{VALUE_HEADER_KEY}] unless ref( $h{VALUE_HEADER_KEY});
    $h{VALUE_KEY} = [$h{VALUE_KEY}]  unless ref( $h{VALUE_KEY});

    foreach my $row (@{$table_ref} )
    {
        my @ValKeyCopy = @{$h{VALUE_KEY}};
        foreach my $valHeaderKey (@{$h{VALUE_HEADER_KEY}})
        {

            my $newKey      = $row->{ $h{PIVOT_KEY} };
            my $newColKey   = $row->{ $valHeaderKey };
            my $valKey = shift @ValKeyCopy;
            next unless defined $valKey;
            my $newColValue = $row->{ $valKey };
            if (defined $newKeys{ $newKey })
            {
                if (defined $newKeys{ $newKey }->{$newColKey} and $h{CONCAT_DUPLICATE})
                {
                    $newKeys{ $newKey } = {%{$newKeys{ $newKey }}, $newColKey => "$newKeys{ $newKey }->{$newColKey}" . $h{SEPARATOR} . "$newColValue"};
                }
                else
                {            
                    $newKeys{ $newKey } = {%{$newKeys{ $newKey }}, $newColKey => $newColValue};
                }
            }
            else
            {
                $newKeys{ $newKey } = {$newColKey => $newColValue}
            }
        }
        if ($h{INCLUDE_IDENTICAL})
        {
            my $newKey = $row->{ $h{PIVOT_KEY} };
            my $newRow = $newKeys{ $newKey };
            foreach my $key (keys %{$row})
            {
                unless (defined first {$_ eq $key} (@{$h{VALUE_HEADER_KEY}}, @{$h{VALUE_KEY}}))
                {
                    if (exists $newRow->{$key})
                    {
                        if (defined $newRow->{$key})
                        {
                            undef $newRow->{$key} if $newRow->{$key} ne $row->{$key};
                        }
                    }
                    else
                    {
                        $newRow->{$key} = $row->{$key};
                    }
                }
            }
            
        }    
            
    }
    push @newTable, {%{$newKeys{ $_ }}, $h{PIVOT_KEY} => $_} foreach (keys %newKeys) ;
    return @newTable;
}

=head2 joinTable

creates a new table that is either the simple equijoin of the left and right table,
or, if LEFT_JOIN_KEY_UNIQUE is set, then Joins the Right Table to the Left Table (all
rows of the left table are included)


=cut

sub joinTable
{
    my %h = (
            LEFT_TABLE          => undef,
            RIGHT_TABLE         => undef,
            JOIN_KEY            => undef,
            LEFT_JOIN_KEY_UNIQUE     => 0,
        ( parseArgs \@_, 'LEFT_TABLE=s@','RIGHT_TABLE=s@','JOIN_KEY=s','LEFT_JOIN_KEY_UNIQUE'),
    );
    my @newTable = ();
    my %rekeyedTable = ();
    
    if ($h{LEFT_JOIN_KEY_UNIQUE}) {
        foreach (@{$h{LEFT_TABLE}})
        {
            $rekeyedTable{ $_->{$h{JOIN_KEY}}} = \%{$_};
        }
        foreach (@{$h{RIGHT_TABLE}})
        {
            push @newTable, {%{$_}, %{$rekeyedTable{$_->{$h{JOIN_KEY}}}}} if defined $rekeyedTable{$_->{$h{JOIN_KEY}}};
        }
    }
    else 
    {
        foreach my $leftRow (@{$h{LEFT_TABLE}})
        {
            foreach my $rightRow (@{$h{RIGHT_TABLE}})
            { 
                push @newTable, {%{$leftRow}, %{$rightRow}} if $leftRow->{ $h{JOIN_KEY} } eq  $rightRow->{ $h{JOIN_KEY} }
            }        
        }
    }
    return @newTable;
}



END { } # module clean-up code here (global destructor)


=head1 AUTHOR

Robert Haxton, C<< <robert.haxton at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Data-printutils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-PrintUtils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::PrintUtils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-PrintUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-PrintUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-PrintUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-PrintUtils/>

=item * Code Repository

L<https://code.google.com/p/data-printutils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Robert Haxton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::PrintUtils
