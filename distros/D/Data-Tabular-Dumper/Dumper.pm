# $Id: Dumper.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper;

use strict;
use vars qw( $VERSION @ISA @EXPORT_OK );

use Carp;

$VERSION="0.08";

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( Dump );


###########################################################
sub open
{
    my($package, %writers)=@_;
    my $self=bless {writers=>{}, fields=>[]}, $package;

    $self->{master_key} = delete $writers{master_key};
    $self->{master_key} = '' unless defined $self->{master_key};

    my($object, $one);
    WRITER:
    foreach my $p1 (keys %writers) {
        foreach my $p2 ($p1, __PACKAGE__.'::'.$p1) {
            if($p2->can('open') and $p2->can('close') and $p2->can('write')) {
                $package=$p2 ;
                eval {
                    $object=$package->open($writers{$p1});
                };
                carp $@ if $@;
                if($object) {
                    $self->{writers}{$package}=$object;
                    $one=1;
                }
                next WRITER;
            }
        }
        carp "Could not find a valid package for $p1 (".__PACKAGE__."::$p1)";
    }
    return unless $one;
    return $self;
}

###########################################################
sub master_key
{
    my( $self, $new_master ) = @_;
    my $ret = $self->{master_key};
    $self->{master_key} = $new_master if 2 == @_;
    return $ret;
}

###########################################################
# Perform $name->() on all the writers.
sub _doall
{
    my($name)=@_;
    return sub {
        my $self=shift @_;
        my $n;
        foreach my $o (values %{$self->{writers}}) {
            my $code=$o->can($name);
            if($code) {
                $code->($o, @_);
                $n++ unless $@;
            } else {
                carp "Object $o can not do $name";
            }
            carp $@ if $@;
        }
        return $n;
    };
}

###########################################################
*fields=_doall('fields');
*write=_doall('write');
*page_start=_doall('page_start');
*page_end=_doall('page_end');

###########################################################
sub close
{
    my( $self )= @_;

    my @ret;
    foreach my $o ( values %{$self->{writers}} ) {
        next unless $o->can( 'close' );
        push @ret, $o->close();
    }
    return @ret;
}


###########################################################
sub DESTROY 
{
    $_[0]->close;
}


###########################################################
sub available
{
    my($package)=@_;

    my(%res, $yes);
    foreach my $p (qw(CSV XML Excel)) {
        $yes=0;
        $yes=1 if exists $INC{"Data/Tabular/Dumper/$p.pm"};
        unless($yes) {
            local $SIG{__DIE__}='DEFAULT';
            local $SIG{__WARN__}='IGNORE';
            $yes=eval "require Data::Tabular::Dumper::$p; 1;";
            # warn $@ if $@ and $ENV{PERL_DL_NONLAZY};
        };
        $res{$p}=$yes;
    }
    return \%res unless wantarray;
    return grep {$res{$_}} keys %res;
}

###########################################################
sub Dump
{
    return __PACKAGE__->dump( @_ );
}

###########################################################
sub dump
{
    my( $self, $data ) = @_;

    my $ret;
    unless( ref $self ) {
        require Data::Tabular::Dumper::String;
        $self = $self->open( String => \$ret, master_key=>'KEY' );
    }

    my $state = $self->analyse( $data );
    unless( $state->{pages} ) {
        $self->__dump( $state );
    }    

    my $q1=1;
    foreach my $p ( @{ $state->{pages} } ) {
        my $name = "Page $q1";
        $q1++;
        $name = $p->{name} if exists $p->{name};
        $self->page_start( $name );
        $self->__dump( $p );
        $self->page_end( $name );
    }
    return $ret;
}

###########################################################
sub __dump
{
    my( $self, $data ) = @_;

    $self->fields( $data->{fields} ) if $data->{fields};
    foreach my $d ( @{ $data->{data} } ) {
        $self->write( $d->{data} );
    }
}


###########################################################
# Convert a 2- or 3-dimensional data structure into something we can
# easily use.
# Lowest-level structure is {data=>[ ...scalars...], fields=>[ ...names...]}
#    Other possible : maxdepth, depth (internal use)
# We either have an array of those in {data} (2-D)
#   { data=>[ ...lower-level ], fields=>[....names...] }
#   Otehr possible keys : name (if it's a part of {pages})
# OR we have an array of 2-D structures in {pages}  
sub analyse
{
    my( $self, $data ) = @_;

    my $master = { maxdepth=>0, depth=>0 };
    my $state = $self->__analyse( $master, $data);

    if( $master->{maxdepth} == 4 ) {
        $state->{pages} = delete $state->{data};
    }
    die "ARG!" if $master->{__fields};

    return $state;
}

###########################################################
# Do the heavy lifting.
# Recurse over a data structure
sub __analyse
{
    my( $self, $parent, $data ) = @_;
    my $r = ref $data;    
    return $data unless $r;

    die "Only 2-d and 3-d data is supported" if $parent->{depth} > 2;


    my $state = { depth=>$parent->{depth}+1 };
    $state->{maxdepth} = $state->{depth};

    if( $r eq 'ARRAY' ) {
        $self->__analyse_array( $parent, $data, $state );
    }
    elsif( $r eq 'HASH' ) {
        $self->__analyse_hash( $parent, $data, $state );
    }
    else {
        die "Don't know how to handle $r at level $state->{depth}";
    }

    $self->__analyse_rehash( $state, $data, $parent ) if $state->{__fields};
    $self->__analyse_depth( $state, $parent );

    return $state;
}

###########################################################
# Turns out $data was a HoH or LoH. So we have to change all the
# sub-hashes.
sub __analyse_rehash
{
    my( $self, $state, $data, $parent ) = @_;
    ## If we are here, $data is a LoH...
    my @fields = sort keys %{ delete $state->{__fields} };

    # use Data::Denter;
    # warn "Rehashing ", Denter $data, $state->{data};
    my $first_name;
    unless( 'ARRAY' eq ref $data ) {
        my @names;
        if( $state->{data}[0]{name} ) {         # 3-D
            @names = map { $_->{name} } @{ $state->{data} };
        }
        else {                                  # HoH
            @names = map { $_->{data}[0] } @{ $state->{data} };
        }
        $data = [ map { { %{$data->{$_}} } } @names ];
        $first_name = 1;

        unshift @fields, 'HONK__TITLE__HONK';
        for( my $q=0; $q <= $#$data ; $q++ ) {
            $data->[$q]{$fields[0]} = $names[$q];
        }
    }

    $state->{data} = [];
    foreach my $hash ( @$data ) {
        push @{ $state->{data} }, 
                    { depth=>$parent->{depth}+2, data=>[ @{$hash}{@fields} ] };
    }

    $fields[0] = $self->{master_key} if $first_name;
    $state->{fields} = \@fields;
    return;
}

###########################################################
# Make sure {maxdepth} of the parent is as big as can be
sub __analyse_depth
{
    my( $self, $state, $parent ) = @_;
    if( $state->{depth} > $parent->{maxdepth} ) {
        $parent->{maxdepth} = $state->{depth};
    }

    if( $state->{maxdepth} > $parent->{maxdepth} ) {
        $parent->{maxdepth} = $state->{maxdepth};
    }
}


###########################################################
# Recurse over an arrayref
sub __analyse_array
{
    my( $self, $parent, $data, $state ) = @_;
    $state->{data} = [];

    foreach my $s ( @$data ) {
        my $sub = $self->__analyse( $state, $s );

        if( @{ $state->{data} } ) {
            my $err = (!!ref $state->{data}[0] ^ !!ref $sub);
            $err = 1 if not $err and 
                      ref $state->{data}[0] and
                      ref $state->{data}[0]{data} ne
                      ref $sub->{data};
            # $err = 1 if $state->{fields};
            if( $err ) {
                die "Non-uniform data references at a level $state->{depth}";
            }
        }
        elsif( ref $sub ) {
            $parent->{maxdepth}++;
        }
        push @{ $state->{data} }, $sub
    }
}

###########################################################
# Recurse over a hashref
sub __analyse_hash
{
    my( $self, $parent, $data, $state ) = @_;
    $state->{data} = [];

    if( $parent->{fields} ) {
        foreach my $k ( @{ $parent->{fields} } ) {
            push @{ $state->{data} }, $data->{$k};
        }
        return;
    }

    foreach my $k ( sort keys %$data ) {
        my $sub = $self->__analyse( $state, $data->{$k} );

        unless( ref $sub ) {                # $data is a hash
            $parent->{__fields}{$k} = 1;
            # $fields{$k}=1;
        }
        elsif( $sub->{maxdepth}==3 ) {             # $data is a HoLoL
            $sub->{name} = $k;
        }
        else {                              
            my $r = ref $sub->{data};
            if( $r eq 'ARRAY' ) {               # $data is a HoL
                unshift @{$sub->{data}}, $k;
            }
            elsif( $r eq 'HASH' ) {             # $data is a HoH
                $sub->{name}=$k;
            }
        }
        if( 0== @{ $state->{data} } and ref $sub ) {
            $parent->{maxdepth}++;            
        }
        push @{$state->{data}}, $sub;
    }
}

1;
__END__

=head1 NAME

Data::Tabular::Dumper - Seamlessly dump tabular data to XML, CSV and XLS.

=head1 SYNOPSIS

    use Data::Tabular::Dumper;

    $date=strftime('%Y%m%d', localtime);

    my $dumper = Data::Tabular::Dumper->open(
                            XML => [ "$date.xml", "data" ],
                            CSV => [ "$date.csv", {} ],
                            Excel => [ "$date.xls" ]
                        );

    # $data is a 2-d or 3-d data structure
    $data = {
        '0-monday' => { hits=>30, misses=>5, GPA=>0.42 },
        '1-tuesday' => { hits=>17, misses=>3, GPA=>0.17 },
    };

    $dumper->dump( $data );


    ## If you want more control :
    $dumper->page_start( "My Page" );

    # what each field is called
    $dumper->fields([qw(uri hits bytes)]);

    # now output the data
    foreach my $day (@$month) {
        $dumper->write($day);
    }

    $dumper->page_end( "My Page" );
    # sane shutdown
    $dumper->close();

This would produce the following XML :

    <?xml version="1.0" encoding="iso-8859-1"?>
    <access>
      <My_Page>
        <page>
           <uri>/index.html</uri>
           <hits>4000</hits>
           <bytes>5123412</bytes>
        </page>
        <page>
          <uri>/something/index.html</uri>
          <hits>400</hits>
          <bytes>51234</bytes>
        </page>
      </My_Page>
      <!-- more page tags here -->
    </access>


=head1 DESCRIPTION

Data::Tabular::Dumper aims to make it easy to turn tabular data into as many
file formats as possible.  This is useful when you need to provide data that
folks will then process further.  Because you don't really know what format
they want to use, you can provide as many as possible, and let them choose
which they want.

Tabular data means data that has 2 dimensions, like a list of lists,
a hash of lists, a list of hashes or a hash of hashes.  

You may also dump 3 dimentional data; in this case, each of the top-level
elements are called B<pages> and each sub-element is independent.

While it might seem desirable to give an example for each data type, this
would be onerous to maintain.  Please look at the tests to see what a
given data object yields.





=head1 2 DIMENSIONAL DATA

=head2 List of lists

Simplest type of data; each of the sub-lists is output as-is.  For XML,
the lowest elements are number 0, 1, etc.

=head2 Hash of lists

Each of the sub-lists is output prefixed with the key name.  For XML,
the lowest elements are number 0, 1, etc, with 0 being the key.


=head2 List of hashes

The bottom hashes keyed records, column names are hash keys, column values
are hash values.  Obviously, the list of column names has to be the same for
all records, so all the keys in all the hashes are used. If a given hash
doesn't have a key, it will be blank in the output at that position.

    [   {   camera=>"EOS 2000", price=>12000.00 },
        {   camera=>"FinePix 1300", price=>150 },
    ]

This corresponds to the following table:

    camera       price
    EOS 2000     12000.00
    FinePix 1300   150.00

Note that keys are asciibetically sorted.



=head2 Hash of hashes

Similar to C<List of hashes>, except the first column is the key in the top
hash.  For XML the key is used instead of C<record>, unless you are using
C<master_key> (see L<open>).  Keys are asciibetically sorted.

Example :

    {   monday => { honk => 42, bonk=>17 },
        wednesday => { honk => 12, blurf=>36 }
    }

CSV and Excel would look like:

    ,blurf,bonk,honk
    monday,,17,42
    wednesday,36,12

The XML would look like:

    <DATA>
      <monday>
        <bonk>17</bonk>
        <honk>42</honk>
      </monday>
      <wednesday>
        <blurf>36</blurf>
        <honk>12</honk>
      </wednesday>
    </DATA>





=head1 3 DIMENSIONAL DATA


=head2 List of 2D data

Each element in the top list is a page.  Pages are named I<Page 1>,
I<Page 2> and so on.
Each 2D element is treated seperately as above.


=head2 Hash of lists of lists

=head2 Hash of lists of hashes

=head2 Hash of hashes of hashes

Each value in the top hash is a page.  Pages are named by their keys.
Each 2D element is treated seperately as above, as if you were doing:

    foreach my $key ( sort keys %$HoX ) {
        $dumper->page_start( $key );
        $dumper->dump( $HoX->{$key} );
        $dumper->page_send( $key );
    }



=head2 Hash of hashes of lists

B<NOT SUPPORTED>


=head1 FUNCTIONS

=head2 Dump( $data )

Calls C<dump> as a package method.  In other words, it does the following:

    Data::Tabular::Dumper->dump( $data );

=head1 Data::Tabular::Dumper METHODS

=head2 open(%writers)

Creates the Data::Tabular::Dumper object.  C<%writers> is a hash that
contains the the package of the object (as keys) and the parameters for it's
C<open()> function (as values).  As a convienience, the
Data::Tabular::Dumper::* modules can be specified as XML, Excel or CSV.  The 
example in the L<SYNOPSIS> would create 3 objects, via the following calls :

    $obj0 = Data::Tabular::Dumper::XML->open( ["$date.xml","users", "user"] );
    $obj1 = Data::Tabular::Dumper::Excel->open( ["$date.xls"] );
    $obj2 = Data::Tabular::Dumper::CSV->open( ["$date.xls", {}] );

Note that you must load a given package first.  C<Data::Tabular::Dumper->open>
will not do so for you.

You may also create your own packages.  See WRITER OBJECTS below.

There is one special key in C<%writers> :

=over 4

=item master_key

Sets the column name for the first column when dumping hash of lists, hash
of hashes or the equivalent 3-D structures. The first column corresponds to
the key names of the top hash.

=back


=head2 close()

Does an orderly close of all the writers.  Some of the writers need this to
clean up data and write file footers properly.   Note that DESTROY also
calls close.

=head2 master_key( [$key] )

Sets the C<master_key>, returning old value.  If called without a parameter,
returns current C<master_key>.  


=head2 dump( $data )

Analyses C<$data>, then dumps each of it's component objects to the
configured files.

C<Dump> is not efficient.  It must walk over the data 2 and sometimes 3
times.  It may also modify your data, so watch out.

May also be called as a package method, in which case it returns a CSV
representation of the data.

    print $fh Data::Tabular::Dumper->dump( $data );


=head2 page_start( $name )

Opens a new page in each file named C<$name>.  You must call L<fields()> if
you want it to have a header.


For XML, a page is an XML element that wraps all furthur data.  The
element's name is C<$name> with all non-word characters converted to an
underscore (C<$name =~ s/\W/_/g>.)

=head2 page_end( $name )

Closes the current page.  Please make sure C<$name> is identical to what
was passed to C<page_start>.


=head2 fields($fieldref)

Sets the column headers to the values in the arrayref $fieldref.  Calling
this "fields" might be misdenomer.  Field headers are often concidered a
"special" row of data.

=head2 write($dataref)

Writes a row of data from the arrayref $dataref.




=head1 WRITER OBJECTS

An object must implement 4 methods for it to be useable by
Data::Tabular::Dumper.

=head2 open($package, $p)

Create the object, opening any necessary files.  C<$p> is the data handed to
Data::Tabular::Dumper->open.

=head2 close()

Do any necesssary cleaning up, like outputing a footer, closing files, etc.

=head2 fields($fieldref)

Define the names of the fields.  C<$fieldref> is an arrayref containing all
the field headings.

=head2 write($dataref)

Write a row of data to the output.  C<$dataref> is an arrayref containing a
row of data to be output.

=head2 page_start($name)
=head2 page_end($name)

Start and end a new page in the output.  If it is called from L<dump>, 
all pages are started and ended with the same C<$name>.  If called from
user code, all bets are off.








=head1 PREDEFINED WRITERS

=head2 Data::Tabular::Dumper::XML

Produces an XML file of the tabular data.


=head2 open($package, [$file_or_fh, $top, $record])

Opens the file C<$file_or_fh> for writing if it is a scalar. Otherwise
C<$file_or_fh> is considered a filehandle.  The top element is C<$top> and
defaults to DATA.  Each record is a C<$record> element and defaults to
RECORD.

=head2 fields($fieldref)

Define the tag for each data value.

=head2 write($dataref)

Output a record.  Each item in the arrayref C<$dataref> becomes an element
named by the corresponding name set in C<fields()>.  If there are more items
in C<$dataref> then fields, the last field name is duplicated.  If there
are no fields defined, elementes are named 0, 1, etc.

Example :

    $xml=Data::Tabular::Dumper::XML->open(['something.xml']);
    $xml->fields([qw(foo bar)]);
    $xml->write([0..5]);

Would produce the following XML :

    <?xml version="1.0" encoding="iso-8859-1"?>
    <DATA>
      <RECORD>
        <foo>0</foo>
        <bar>1</bar>
        <bar>2</bar>
        <bar>3</bar>
        <bar>4</bar>
        <bar>5</bar>
      </RECORD>
    </DATA>

Likewise, 

    $xml=Data::Tabular::Dumper::XML->open(['something.xml']);
    $xml->dump( [ [ { up=>1, down=>-1, left=>0.5, right=>-0.5 } ] ] );
    $xml->close

Would produce the following XML :

    <?xml version="1.0" encoding="iso-8859-1"?>
    <DATA>
      <Page_1>
        <down>-1</down>
        <left>0.5</left>
        <right>-0.5</right>
        <up>1</up>
      </Page_1>
    </DATA>





=head2 Data::Tabular::Dumper::CSV

Produces an CSV file of the tabular data.  Each new page is started a row
with the page name on it and ending with a blank line.


=head2 open($package, [$file_or_fh, $CSVattribs])

Opens the file C<$file_or_fh> for writing if it is a scalar. Otherwise
C<$file_or_fh> is considered a filehandle.  Creates a Text::CSV_XS object
using the attributes in the hashref C<$CSVattribs>.

It should be noted that you probably want to set C<eol> to C<\n>, otherwise
all the output will be on one line.  See C<Text::CSV_XS> for details.

Example :

    $xml=Data::Tabular::Dumper::CSV->open(['something.xml', 
                                          {eol=>"\n", binary=>1}]);
    $xml->fields([qw(foo bar)]);
    $xml->write("me,you", "other");

Would produce the following CSV :

    foo,bar
    "me,you",other

=head2 fields( $fieldref )

Outputs a row that contains the names of the fields.  Basically, it's the
same as C<write>.






=head2 Data::Tabular::Dumper::Excel

Produces an Excel workbook of the tabular data.  Each page is a new
worksheet.  

If you want a header on each worksheet, you must call C<fields()> after each
page is started.  If you do not call C<page_start()>, a default empty
worksheet is used.  Note that C<dump()> handles all this for you.



=head2 open($package, [$file])

Creates the workbook C<$file>. 

=head2 fields($fieldref)

Creates a row in bold from the elements in the arrayref C<$fieldref>.


=head1 BUGS

There are no test cases for all C<dump>'s  edge cases, such as
non-heterogeous lower data elements.

There is no verification of the Excel workbooks produced.

No support for RDBMSes.  I'm not fully sure how this would work... each page
would be a table?  What about lists as the lowest data structure?  We'd
need a way to match data columns to table columns.

C<close> should call C<page_end> if there is one pending.


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=head1 SEE ALSO

L<Text::CSV_XS>, L<Spreadsheet::WriteExcel>, L<http://www.xml.org>, L<perl>.

=cut
