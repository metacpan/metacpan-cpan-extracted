package Convert::Addressbook::Mozilla2Blackberry;

use 5.008004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Convert::Addressbook::Mozilla2Blackberry ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.




#TODO a version of this module that checks state - Mozilla addr's LastModifiedDate


my ($field_names);
my (@data);
my (@Blackberry_Fields);
my (%field, %Conversion_Filter);

#Blackberry file format;
@Blackberry_Fields =
    ("First Name",
    "Middle Name",
    "Last Name",
    "Title",
    "Company Name",
    "Work Phone",
    "Home Phone",
    "Fax",
    "Mobile Phone",
    "PIN",
    "Pager",
    "Email Address 1",
    "Email Address 2",
    "Email Address 3",
    "Address1",
    "Address2",
    "City",
    "State/Prov",
    "Zip/Postal Code",
    "Country",
    "Notes",
    "Interactive Handheld",
    "1-way Pager",
    "User Defined 1",
    "User Defined 2",
    "User Defined 3",
    "User Defined 4");

#the 'master' map of how to convert between Mozilla fields and the
# Blackberry fields, above.  The Blackberry field is the key, Mozilla the
# value, so we can iterate through @Blackberry_Fields and work on each
# element in turn, while preserving the correct order
# also needs blank "filler" lines including to map fields that don't exist in Mozilla
# to blackberry
%Conversion_Filter = (
    "First Name" => "FirstName",
    "Middle Name" => "",
    "Last Name" => "LastName",
    "Title" => "",
    "Company Name" => "Company",
    "Work Phone" => "WorkPhone",
    "Home Phone" => "HomePhone",
    "Fax" => "FaxNumber",
    "Mobile Phone" => "CellularNumber",
    "PIN" => "",
    "Pager" => "",
    "Email Address 1" => "PrimaryEmail",
    "Email Address 2" => "DefaultEmail",
    "Email Address 3" => "SecondEmail",
    "Address1" => "WorkAddress",
    "Address2" => "WorkAddress2",
    "Address3" => "",	#no corresponding field
    "City" => "WorkCity",
    "State\/Prov" => "WorkState",
    "Zip\/Postal Code" => "WorkZipCode",
    "Country" => "WorkCountry",
    "Notes" => "",
    "Interactive Handheld" => "",
    "1-way Pager" => "",
    "User Defined 1" => "Custom1",
    "User Defined 2" => "Custom2",
    "User Defined 3" => "Custom3",
    "User Defined 4" => "", #no corresponding field
);

###########################
# create the new() object for the instance
###########################
sub new {
    my $class = shift;  # works on @_ by default

    my $ConversionInfo = {};  #create a blank hash

    #setup the OO Object.  Don't mind the man behind the curtain..
    bless $ConversionInfo, $class;

    #give the blackberry header information to the object
    $ConversionInfo->{'BlackberryHeaders'} = \@Blackberry_Fields;
    #get the filename we were given, if any
    #if (defined ($file)) { $ConversionInfo->{'file'}; }
     #allow the object to reference the @FileData array
    #$ConversionInfo->{'FileData'} = \@FileData;

    #allow the object to reference the converted data hash
    $ConversionInfo->{'field'} = \%field;

    #give the calling routine access to our data and routines
    return $ConversionInfo;
}

###########################
#print the blackberry field headers -
# iterate over ever instance and print
# it, basically..
###########################
sub PrintBlackberryHeaders
{

    map({ print "$_,"; } @Blackberry_Fields);
    print "\n";
}

############################
# return a list of the Header fields
# that Blackberry uses in its .CSV import file
# mostly just to be nice, but it might help if I CPAN this..
#############################
sub ReturnBlackberryHeaders
{
    #get the ojbect refernce to the instance thats calling us
    my ($obj) = shift;
    #return the details as requested above
    return $obj->{@Blackberry_Fields};
}

#########################
# convert each record passed, from each line in an array
# expects a hash reference which contains a set of data to convert
# note: unlike the original script, this only converts one set of records
# at a time, to convert the entire file, you must call it repeatedly.
# returns a single scalar containing the CSV record set of the converted record
#########################
sub StreamConvert
{
    #get the ojbect refernce to the instance thats calling us
    (my ($obj) = shift) || carp ("No object - did you call new() first?\n");
    #setup a scalar to hold the processed record data
    my $converted_record;
    # get the reference to the hash from the calling routine, and dereference
    (my $hashref = shift) || carp("No hash passed to StreamConvert\n");
    my %record_to_import = %$hashref;

#    # fields on the left are the Blackberry fields, the right; Mozilla
#    #TODO  prevent warning messages if the mozilla var is undef - eval block?
#    #this is rather painful, but I can't think of a way to iterate over
#    #these and keep the record match correct without using a hash
    my %blackberry_records;
    $blackberry_records{"First Name"} = $record_to_import{"FirstName"};
    $blackberry_records{"Last Name"} = $record_to_import{"LastName"};
    $blackberry_records{"Company Name"} = $record_to_import{"Company"};
    $blackberry_records{"Work Phone"} = $record_to_import{"WorkPhone"};
    $blackberry_records{"Home Phone"} = $record_to_import{"HomePhone"};
    $blackberry_records{"Fax"} = $record_to_import{"FaxNumber"};
    $blackberry_records{"Mobile Phone"} = $record_to_import{"CellularNumber"};
    $blackberry_records{"Email Address 1"} = $record_to_import{"PrimaryEmail"};
    $blackberry_records{"Email Address 2"} = $record_to_import{"DefaultEmail"};
    $blackberry_records{"Email Address 3"} = $record_to_import{"SecondEmail"};
    $blackberry_records{"Address1"} = $record_to_import{"WorkAddress"};
    $blackberry_records{"Address2"} = $record_to_import{"WorkAddress2"};
    $blackberry_records{"City"} = $record_to_import{"WorkCity"};
    $blackberry_records{"State/Prov"} = $record_to_import{"WorkState"};
    $blackberry_records{"Zip/Postal Code"} = $record_to_import{"WorkZipCode"};
    $blackberry_records{"Country"} = $record_to_import{"WorkCountry"};
    $blackberry_records{"User Defined 1"} = $record_to_import{"Custom1"};
    $blackberry_records{"User Defined 2"} = $record_to_import{"Custom2"};
    $blackberry_records{"User Defined 3"} = $record_to_import{"Custom3"};
#TODO try and create the firstName and LastName fields from other Mozilla fields e.g. DisplayName
    #create a default name if it doesn't exist
    #not perfect, but if theres sufficient need, I'll look into some regex to split the 
    # DisplayName up, and seperate the email address
    if ( (!defined($record_to_import{"FirstName"})) && (!defined($record_to_import{"LastName"})))
	{
		$blackberry_records{"First Name"} = $record_to_import{"DisplayName"};
	} 
    
#TODO return the data to the calling program as a scalar
#TODO convert the print statements into additions to $converted_record
        #iterate through the blackberry field list to generate the correct
        #sequence of CSV fields
        for $field_names (@Blackberry_Fields)
        {
		#my $testvar = $record_to_import{$Conversion_Filter{$field_names}};
            #if the field is already propulated, add it to the hash
            if ( defined($record_to_import{$Conversion_Filter{$field_names}}) )
            {
                print $record_to_import{$Conversion_Filter{$field_names}} . ",";
            }
            #otherwise, just print the delimiter
            else
            {
                print ",";
            }
        }
        #once we're done, print the end of line to move to the next record
        print "\n";
    #}#end of 
    return $converted_record;
}#end of StreamConvert()

#end of module
1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Convert::Addressbook::Mozilla2Blackberry - Perl extension for converting a CSV comma delimited addressbook from Mozilla to Blackbery csv import format

=head1 SYNOPSIS

	use Mozilla::Mork;
  	use Convert::Addressbook::Mozilla2Blackberry;
	
	#get the file from the command line or quit with an error
	$file = $ARGV[0];
	unless ($file) { die "Useage: $0 <filename>\n"; }

	#access the address book and setup the memory structure
	my $MorkDetails = Mozilla::Mork->new($file);

	#get a reference to an array of hash's
	my $results = $MorkDetails->ReturnReferenceStructure();
	#create an instance of the converter code
	my $converter = Convert::Addressbook::Mozilla2Blackberry->new();
	#print the Blackberry File headers
	$converter->PrintBlackberryHeaders();

	#process those results
	# for each line in the database
	# each line in the database corresponds to an address book record
	# pass this reference to the StreamConvert routine which will 
	# convert and print it
	
	for my $record_array ( @{$results} )
	{
		$converter->StreamConvert($record_array);
	}

=head1 DESCRIPTION

This is a module that builds on the Mozilla::Mork module to translate the
Mozilla address book to a CSV format suitable for importing into a
Blackberry via the Desktop Manager (i.e. even the CSv fields are in the correct order).

=head3  Assumptions

 1. the calling routine knows the correct format to send it in.
 2. the 'right format' is a hash containing a set of records to convert as produced by Mozilla::Mork
 3. this is not a full file conversion - some fields are missing, if there is no corresponding field, also, some fields are created from, or imported from others
 4. You want to print the results so you can capture the output to a file of of your choice.

=head3  Caveats
 
 It turns out that the import engine that comes with the Blackberry Desktop (I tested with version 4.0) will happily import duplicates, even if you tell it not to; so I suggest this for a bulk load only, rather than multiple import runs.  For a ongoing conversion I suggest using the Sync with Outlool/Outlook Express and using Dawn (See Also, below) to manage the combining and conversion.
 I might write a conversion routine, but so far I've shaved my particular yak.

Also, the correct place for this code, if I am being honest is an addtion to the Mail::Addressbook::Convert suite.  However, my time to work on this is limited and by releasing in this way I can get it 'out there' for others to use.  If someone wants to incorporate it in athe abobe namespace, good for them.  I plan to, but no idea when I'll actually get round to it..

=head3 Routines

B<new()>

create the new() OO Object.  Don't mind the man behind the curtain..


B<PrintBlackberryHeaders()>

print the blackberry field headers - iterate over ever instance and print it, basically.


B<ReturnBlackberryHeaders()>

return a list of the Header fields that Blackberry uses in its .CSV import file


B<StreamConvert()>

Convert each record passed, from each line in an array
expects a hash reference which contains a set of data to convert
This only converts one set of records at a time, to convert the entire file, 
you must call it repeatedly.
Returns a single scalar containing the CSV record set of the converted record, along with printing the record to STDOUT.
#TODO seperate the printing and returning routines


=head3 Formats

 not that its needed here, but the Mozilla 'export' file format is:
 First,Last,Display,Nickname,email,screen name,Work Phone,home phone,fax
 pager,mobile

 Blackberry import format is reachable with ReturnBlackberryHeaders(), above.


=head2 EXPORT

None by default.



=head1 SEE ALSO

Also see Mozilla::Mork

Dawn is a decent Windows addressbook converter program thar handles Mozilla Mork formats (unusually);
http://www.joshie.com/projects/dawn/

Thanks to my company for giving me time work on this and release it to the public domain (http://www.ipaccess.com)

Thanks to Brian d Foy who took the time to assist me with the name convention.

I'll probably put up a web page here eventually: http://www.kript.net

=head1 AUTHOR

John Constable, E<lt>cpan@kript.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by John Constable

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
