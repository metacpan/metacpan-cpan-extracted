package Business::Shipping::DataTools;

use warnings;
use strict;
use Business::Shipping::Logging;
#use Business::Shipping::Config;
use Carp;
use Fcntl ':flock';
use File::Find;
use File::Copy;
use Config::IniFiles;
use Archive::Zip qw(:ERROR_CODES);
use English;
use Data::Dumper;
use Storable;
use File::Basename;
use Text::CSV::Simple;

=head1 NAME

Business::Shipping::DataTools - Convert tables from original format into usable format.  

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

 bin/update.pl

This is an optional module.  It is used to update Business::Shipping::DataFiles.
These tools convert the original source data obtained from shippers into a 
format that Business::Shipping can use.  It is normally run only once per year
when UPS releases new tables (which explains the poor quality of the source 
code).
 
It will unzip the data UPS data files and create .dat files.  These .dat files
are used by Business::Shipping, you can copy them to the data directory.

=head1 REQUIRED MODULES

 Archive::Zip
 Text::CSV::Simple

=head1 INSTALLATION

All that is necessary to begin using this module is to untar it.  You do not
need to 'perl Makefile.PL' or make or anything else.

=cut

use Class::MethodMaker 2.0 
    [
        new    => [ qw/ -hash new / ],
        scalar => [ qw/ update download unzip convert create_bin / ],
        scalar => [ qw/ pause data_dir / ], # Pause after every event, if enabled.
    ];

=item * do_update

=cut

sub do_update
{
    my ( $self ) = @_;
    
    if ( not $self->data_dir ) {
        $self->data_dir( Business::Shipping::Config::data_dir() );
    }
    
    if ( $self->update ) {
        $self->download( 1 );
        $self->unzip( 1 );
        $self->convert( 1 );
    }
    
    debug "data_dir = " . $self->data_dir();
    
    if ( $self->download ) {
        print "Downloading, please wait...\n";
        $self->do_download;
    }
    
    if ( $self->unzip ) {
        print "Unzipping, please wait...\n";
        $self->do_unzip;
    }
    
    if ( $self->convert ) {
        print "Converting, please wait...\n";
        $self->do_convert_data;
    }
    
    if ( $self->create_bin ) {
        print "Creating storables, please wait...\n";
        $self->do_create_bin if $self->create_bin;
    }
    
    print "Done.\n";
    
    return;
}
    
    
=item * download_to_file( $url, $file )

=cut

sub download_to_file
{
    my ( $url, $file ) = @_;
    trace "( $url, $file )";
    
    return unless $url and $file;
    
    eval {
        use LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        my $req = HTTP::Request->new(GET => $url);
        open( NEW_ZONE_FILE, "> $file" );
        print( NEW_ZONE_FILE $ua->request($req)->content() );        
        close( NEW_ZONE_FILE );
    };
    warn $@ if $@;
    
    return;
}

=item * _unzip_file( $zipName, $destination_directory )

=cut

# Extracts all files from the given zip

sub _unzip_file
{
    my ( $zipName, $destination_directory ) = @_;
    $destination_directory ||= './';
    
    my $zip = Archive::Zip->new();
    my $status = $zip->read( $zipName );
    if ( $status != AZ_OK )  {
        my $error = "Read of $zipName failed";
        #$self->user_error( $error );
        logdie $error;
    }
    if ( $@ ) { logdie "_unzip_file error: $@"; }
    
    $zip->extractTree( '', $destination_directory );
    
    debug( "Done extracting." );
    
    return;
}

=item * filename_only( $path )

  Was filename_only.
  
=cut

sub filename_only_old 
{
    my ( $base, $path ) = fileparse( $_[ 0 ] );
    return $path . $base;
}

=item * split_dir_file( $path )

=cut

# Return ( directory_path, file_name ) from any path.
# TODO: Use correct File:: Module, and be Windows-compatible

sub split_dir_file
{
    my $path = shift;
    
    my @path_components = split( '/', $path );
    my $file = pop @path_components;
    my $dir = join( '/', @path_components );
    return ( $dir, $file ); 
}

=item * remove_extension( $file )

=cut

sub remove_extension
{
    my $file = shift;
    trace "( $file )";
    my ( $base, $path ) = fileparse( $file, ( '.csv', '.tmp' ) );
    return $path . $base;
}

=item * remove_windows_carriage_returns( $path )

=cut

# TODO: Windows compat: call binmode() if Windows.

sub remove_windows_carriage_returns
{
    my $file = shift;
    trace "( $file )";
    
    open(    IN,        $file      ) or die "Could not open file $file: $!";
    open(    OUT,       ">$file.1" ) or die "could not open file $file.1: $!";

    # read it all in at once.
    undef $INPUT_RECORD_SEPARATOR;
    my $contents = <IN>;
    
    $contents =~ s/\r\n/\n/g;
    print OUT $contents;
    
    close(  IN                     );
    close(  OUT                    );
    File::Copy::copy(   "$file.1", $file       );
    unlink( "$file.1"              );
    

    # return to normal line endings.
    # TODO: Use English;

    $INPUT_RECORD_SEPARATOR = "\n";
    return;
}

=head2 * scrub_file( $filename )

Removes blank lines.

=cut

sub scrub_file
{
    my ( $file ) = @_;
    
    #print "writing to >$file.new";
    open(  RATE_FILE, $file ) or logdie $!;
    open(  NEW_FILE,  ">$file.new" ) or logdie $!;
    <RATE_FILE>; # thow away the first line, 
    # because it has the "Registered" symbol in ISO-8859 text, and I can't figure out how to get rid of it.
    # except that the reg also appears in other locations sometimes too.
    while ( defined( my $line = <RATE_FILE> ) ) {
        next unless $line and $line !~ /^\s+$/;
        next if $line =~ /^,+$/;
       
        # Convert ISO-8859 text (like the (R) at the top of 1da.csv) to ASCII text.  iconv couldn't seem to
        # do it, no matter which encoding I selected, so Text::iconv() probably wouldn't work either.
        # I used bin/find_chars.pl to determine the valid character range.
        $line =~ s|[^ "\#\$\%\&'\(\)\*\+\,-\.\/0-9\:a-z\[\]A-Z\t\n]||g;

        print NEW_FILE $line if $line and $line 
    }
    close( RATE_FILE );
    close( NEW_FILE );
    rename( "$file.new", $file ) or die $!;
    
    return;
}

sub convert_ups_rate_file
{
    trace "( $_[0] )";
    
    # aoa = Array of Arrays.  This is the "table" object.
    # meta = Information about the aoa.  This is the "meta" object.
    # These objects are stored after processing each input file in a Storable output file.    
    my $aoa = [];
    my $meta = {};
    
    my ( $self, $file, $opt ) = @_;
    if ( ! -f $file ) { error "Could not convert file $file because it didn't exist."; return; }
    
    
    # Note that not every file is a valid CSV file.  One is a binary XLS file, and others have invalid lines.
    # TODO: Handle files that aren't valid CSV.
    # Here we scrub the file of blank lines, which throw off the CSV module:
    scrub_file( $file );
    
    # need to ISO-8859 text into regular text.
    
    # Format usually follows the following, but not always:
    # Description1
    # Description2
    # Date
    # Surcharge Note
    # Blank
    # Zone
    # Data

    my $c = -1;
    my $row_num = 0;
    my $LIMIT = 99999;
    my $PAUSE = 0;
    my %next_record;
    my $set_max_in_next_record;
    my $next_record_should_be_minimums;
    my $next_line_is_header;
    my $file_basename = File::Basename::basename( $file );
    my $zone_file = $opt->{ zone_file } ? 1 : 0;
    
    debug "zone_file = $zone_file"; #, opt->zone_File = $opt->{zone_file}";
    
    use constant MIN => 0;
    use constant MAX => 1;
    use constant ADD_TO_LAST_RECORD => 1;  # so that the max for, e.g. 150, will be 180 if set to 30.
    
    my $parser = Text::CSV::Simple->new;
    my @all_records = $parser->read_file( $file );
    foreach my $record ( @all_records ) {
        last if ++$c > $LIMIT;
        if ( $PAUSE ) {
            print "Press enter to continue...\n";
            my $enter = <STDIN>;
        }
        
        my $num_elements = scalar( @$record ) - 1;
        debug join( ",", @$record );
        
        next if not $record;
        next if not @$record;
        next if not ( join( "", @$record ) );
        
        
        # Skip the line if it is empty, all spaces, or just has commas.
        #next if $line =~ /^\s+$/; 
        #next if $line =~ /^(,| )+$/;
        
        # Convert thousands into numeric.  "$1,076.59" => 1076.59
        foreach my $c4 ( 0 .. $num_elements ) {
            $record->[ $c4 ] =~ s/(\d+),(\d+)/$1$2/;  # Remove the comma from thousands.
            $record->[ $c4 ] =~ s/\$//; # Remove Dollar signs
            #print "checking '$record->[$c4]'\n";
            if ( $record->[ $c4 ] =~ /^[\d\s\.]+$/ ) {
                $record->[ $c4 ] =~ s/\s+//g;
                #print "changed $record->[$c4]!\n";
            }
            #$record->[ $c4 ] =~ s/^(\d+) $/$1/g;  # Extra space after numerical data "35 " becomes "35"
            #$record->[ $c4 ] =~ s/^ (\d+)$/$1/g;  # Extra space before numerical data " 35" becomes "35"
            #$record->[ $c4 ] =~ s/^ (\d+) $/$1/g;  # Extra space before and after numerical data " 35" becomes "35"
        }
        
        #if ( $line =~ /$1,076.59"/ ) {
        #    debug "line = $line";
        #    $line =~ s/"\$(\d+,\d+)"/$1/g;
        #    print "line after = $line";
        #}
        
        #$line =~ s/\$//g;           
        #$line =~ s/(\d\d) ,/$1,/g;  # Extra space after numerical data "35 ," becomes "35,"
        
        # Remove all the left-over spaces, only if it isn't meta data.
        # $line =~ s/ //g;
        
        my ( $key, @cols ) = ( @$record );
        #print "'$key'\n";
        #chomp( $line );
        #print "$line\n";
        
        #print "key = $key, cols = " . join( ', ', @cols );
        #exit;
        
        # Sometimes the key is in the second column and the first column is empty
        $key = shift @cols if not length $key;
        
        for my $c5 ( 0 .. @cols - 1 ) {
            next unless defined $cols[ $c5 ];
            
            #debug "checking $cols[$c5]...";
            # If it's all numbers and spaces, get rid of the spaces.
            if ( $cols[ $c5 ] =~ /^ \d+$/ ) {
                $cols[ $c5 ] =~ s/\s+//g;
            }
        }
        
        if ( $key eq 'Weight Not To Exceed' 
          or $key eq 'Zone' 
          or $next_line_is_header 
          or $key eq 'Dest. ZIP'       # 986.csv
          or $key eq 'Postal Range'    # wash.csv 
          or $key eq 'Country / Country Code'         # ewwzone.csv 
           )  
        {
            
            debug "This is a Header (zone) line";
            $next_line_is_header = 0;
            # This is the headers
            
            # Remove empty columns
            @cols = grep { $_ } @cols;
            my $cols = [];
            my $min_max_offset; # number of columns that aren't part of the "data" (2 for min, max.  1 for just country.)
            
            # Some tables (e.g. gndcomm) list the headers as "Zone 2" instead of "2".  Remove the "Zone" part.
            for my $c3 ( 0 .. @cols -1 ) {
                $cols[ $c3 ] =~ s/Zone\s+//;
                $cols[ $c3 ] =~ s/\s+//g;
            }
            
            if ( $file_basename eq 'ewwzone.tmp' ) {
                # The column names need to be converted a bit.
                # 0 = UPS Worldwide Express Plus
                # 1 = UPS Worldwide Express
                # 2 = UPS Worldwide Express originating from Dade and Broward Counties, FL.
                # 3 = UPS Worldwide Expedited from Western U.S.
                # 4 = UPS Worldwide Expedited from Eastern U.S.
                # 5 = Extended Area Surcharge
                $cols = [ 'Country', 'ExpressPlus', 'Express', 
                          'Express Originating from Dade and Broward Counties Florida', 
                          'Expedited_WC', 'Expedited_EC', 'Extended Area Surcharge' ];
                $min_max_offset = 1;
            }
            else {
                $cols = [ 'Min', 'Max', @cols ];
                $min_max_offset = 2;
            }
            
            if ( $meta->{ columns } ) {
                # Header already exists, so this is probably a secondary header, which applies only to
                # something else.  Use the line number as a unique identifier
                $meta->{ "columns_$c" } = $cols;
            }
            else {
                # This is commented out because I thought that zone files didn't have min-max, but most of 
                # them actually do.  (zone between ... and ... ).  Use 'lt' and 'gt' for comparing alpha 
                # zones.
                #if ( $zone_file ) {
                #    $meta->{ columns } = [ @cols ];
                #}
                #else {
                #    $meta->{ columns } = [ 'Min', 'Max', @cols ];
                #}
                
                $meta->{ columns } = $cols;
                
                # col_idx is a lookup for which array element the zone corresponds to.
                foreach my $c2 ( 0 .. @$cols - 1 + $min_max_offset ) {  # plus 2 because we ignore 'Min' and 'Max' in the lookup 
                    my $zone_name_or_number = $meta->{ columns }[ $c2 ];
                    next unless $zone_name_or_number;
                    $meta->{ col_idx }->{ $zone_name_or_number } = $c2;
                }
            }
            debug "Column index after setting up header: " . Dumper( $meta->{ col_idx } );
            #$aoa->[ $c ][ 0 ] = 'Header';
        }
        elsif ( grep( /^Counties Florida$/, @cols ) ) {
            # ewwzone
            $next_record{ single_key } = 1;
        }
        elsif ( $key eq 'For shipments from Eastern U.S. in the following states:' ) {
            # ewwzone
            $next_record{ single_key } = 0;
        }
        elsif ( $key eq 'ZONES' ) {
            # This indicates that the next line will be a header for zone files.
            debug "Next record should be a header (for zone files)";
            $next_line_is_header = 1;
        }   
        elsif ( $key eq 'Letter' ) {
            @cols = ( 0, 1, @cols );
            push @{ $aoa->[ $row_num++ ] }, @cols;
        }
        # "35" 
        elsif ( $key =~ /^\d+$/ ) {
            debug "Regular single numeric value";
            
            if ( $file_basename eq 'xarea.tmp' ) {
                # xarea is just a list of zip codes, one per line.  
                # Must add leading zeros to zip codes less than digits.
                # It is so simple to parse that we can do it manually here.
                debug "Special handling for xarea file";
                my $zip = $key;
                while ( length( $zip ) < 5 ) {
                    $zip = '0' . $zip;
                }
                push @$aoa, $zip;
                next;
            }
            
            # Set the previous record's maximum using this record's minimum.
            if ( $set_max_in_next_record ) {
                $aoa->[ $row_num - 1 ][ MAX ] = $key - 1 if $row_num > 0;
                $set_max_in_next_record = 0;
            }
            
            #@cols = ( 0, 1, @cols );
            #push @$aoa, \@cols;

            
            # Set this record's min.
            $aoa->[ $row_num ][ 0 ] = $key;
            # Prepare a spot for the max in this record so that it can be set by the next record.
            $aoa->[ $row_num ][ 1 ] = 0;
            $set_max_in_next_record = 1;
            #debug( "pushing cols " . Dumper( \@cols ) );
            push @{ $aoa->[ $row_num++ ] }, @cols;
        }
        # "35 to 45" or "35 to 45lbs." or "35-45"
        elsif ( 
            $key =~ /^\d+ to \d+ ?(lbs\.)?$/i 
            or $key =~ /^\d+-\d+$/ 
            or $key =~ /^\d+\+? ? ?lbs\.( or more)?$/i ) 
        {
            #debug "key specifies min and max: $key";
            my ( $min, $max );
            ( $min, $max ) = split( ' to ', $key ) if $key =~ /to/i;
            ( $min, $max ) = split( '-', $key ) if $key =~ /-/;
            if ( $key =~ /^(\d+)lbs\. or more/i
              or $key =~ /^(\d+)\+?(\s+)?Lbs./i ) {
                $min = $1;
                $max = 9999;
            }
            if ( ! $max ) {
                error "Max was not specified with key: $key!";
            }
            else {
                $max =~ s/lbs\.//i;
            }
            
            # Set the previous record's maximum using this record's minimum.
            if ( $set_max_in_next_record ) {
                $aoa->[ $row_num - 1 ][ 1 ] = $min - 1 if $row_num > 0;
                $set_max_in_next_record = 0;
            }
            
            # TODO: $c is probably not the right value to be using here, because there are several lines
            # that are skipped.
            
            # Set this record's min.
            $aoa->[ $row_num ][ 0 ] = $min;
            $aoa->[ $row_num ][ 1 ] = $max;
            #debug( "pushing cols " . Dumper( \@cols ) );
            push @{ $aoa->[ $row_num++ ] }, @cols;
        }
        elsif ( $key =~ /[a-zA-Z]/ and length( $key ) <= 3 ) {
            # Canadian Zip code
            debug "canadian";
            my ( $min, $max, @zones ) = @cols;
            # $min = cnv( $min, 36, 10 ); # Don't convert, just use lt and gt.  They are slower, but we don't
            # need math::base cnv
            # $max = cnv( $max, 36, 10 );
            
            if ( $set_max_in_next_record ) {
                $aoa->[ $row_num - 1 ][ 1 ] = $min - 1 if $row_num > 0;
                $set_max_in_next_record = 0;
            }
            
            push @{ $aoa->[ $row_num++ ] }, ( $key, @cols );
        }
        elsif ( $next_record{ single_key } ) {
            # Not using the regex anymore:
            # Name of country (the only country not caught by the regex below is 
            # "Ponape (Federated States of Micronesia+A193)", so we have the length too.
            # $key =~ /^[ a-zA-Z\'\.\(\)\-\+]+$/ or length( $key ) > 35
            
            # Remove the ' / country code' component of the country key.
            # TODO: store the country code in a separate column instead of deleting it, and use it for 
            # lookups.
            $key =~ s| / [A-Z]+$||g;
            push @{ $aoa->[ $row_num++ ] }, ( $key, @cols );
            #die "stopping" if $c > 100;
        }
        elsif ( $key eq 'Multiplier' ) {
            #"Multiplier: if the dimensional weight is more than 150 pounds (but the actual weight still has
            # to be less than 150 pounds, of course), then multiply this factor and the dimensional weight
            # to get the rate.
            $meta->{ Over_max_multiplier } = [ ( $key, @cols ) ];
            
        }
        # This currently conflicts with one above.  Perhaps can differentiate because the amounts in this
        # for the first column are always less than 5.00, and above they are not.
        # 151-199,0.50,0.67,0.79,0.94,1.06,1.19 (as in canstd)
        #elsif ( $key =~ /^\d+-\d+$/ and $cols[ 0 ] < 5 ) {
        #    #Another multiplier
        #    $meta->{ Over_max_multiplier } = [ ( $key, @cols ) ];
        #}
        elsif ( $key eq 'Minimums' ) {
            debug "Setting next_record_should_be_minimums"; 
            $next_record_should_be_minimums = 1;
            #$meta->{ minimum_per_zone } = [ ( $key, @cols ) ];
        }
        elsif ( $next_record_should_be_minimums ) {
            $next_record_should_be_minimums = 0;
            $meta->{ minimum_per_zone } = \@cols;
        }
        elsif ( $key =~ /^"EFFECTIVE/ ) {
            #my $date = substr( $key, 1, 30 ), join( "", @cols );
            my $date = $key . ', ' . $cols[ 0 ];
            push @{ $meta->{ unknown } }, $date;
        }
        elsif ( $key =~ /^\[\d+\]/ ) {
            # This is most likely one of the special messages at the bottom of the zone files.
            # At this time, the effects of these messages must be extracted manually (e.g. the special
            # Hawaii/Alaska zip codes).  So, we don't really want these in the table.  
            last;
        }
        else {
            debug "Unknown key type, adding to meta";
            # Remove empty data from @cols
            my @combined = ( $key, grep { length $_ } @cols );
            if ( @combined == 1 ) {
                push @{ $meta->{ unknown } }, $combined[ 0 ];
            }
            else {
                push @{ $meta->{ unknown } }, [ @combined ];
            }
        }
        #debug Dumper( $aoa );        
    }
    
    if ( ref( $aoa->[ $row_num - 1 ] ) eq 'ARRAY' and $aoa->[ $row_num - 1 ] and $aoa->[ $row_num  - 1 ][ 0 ] =~ /^\d+$/ ) {
        debug "Setting the max on the last record: $row_num  minus one";
        # The last record in the table is the minimum plus one.
        $aoa->[ $row_num  - 1 ][ 1 ] ||= $aoa->[ $row_num  - 1 ][ 0 ] + ADD_TO_LAST_RECORD; 
    }
    else {
        debug "Setting max on the last record not needed.";
    }
    
    if ( $c <= 1 ) {
        error "No records were processed.";
    }
    
    #close(     RATE_FILE                 ) or logdie $@;
    
    my $root_object = { 
        table => $aoa,
        meta  => $meta,
    };
    
    #print Dumper( $aoa );
    #print Dumper( $meta );
    debug Dumper( $root_object );
    
    debug "Storing object to file";
    
    my $new_filename = remove_extension( $file ) . ".dat";
    #debug "going to store to $new_filename";
    Storable::nstore( $root_object, $new_filename ) or die $@;

    
    return;
}



=item * do_download

=cut

sub do_download
{
    my ( $self ) = @_;
    
    my $data_dir = $self->data_dir;
    
    my $us_origin_rates_url = dtcfg()->{ ups_information }->{ us_origin_rates_url };
    my $us_origin_zones_url = dtcfg()->{ ups_information }->{ us_origin_zones_url };
    my $us_origin_rates_filenames = dtcfg()->{ ups_information }->{ us_origin_rates_filenames };
    my $us_origin_zones_filenames = dtcfg()->{ ups_information }->{ us_origin_zones_filenames };
    
    for ( @$us_origin_zones_filenames ) {
        s/\s//g;
        download_to_file( "$us_origin_zones_url/$_", "$data_dir/$_" );
    }
    for ( @$us_origin_rates_filenames ) {
        s/\s//g;
        download_to_file( "$us_origin_rates_url/$_", "$data_dir/$_" ) ;
    }
    
}

=item * do_unzip

=cut

sub do_unzip
{
    my ( $self ) = @_;
    
    for ( 
            @{ dtcfg()->{ ups_information }->{ us_origin_rates_filenames } },
            @{ dtcfg()->{ ups_information }->{ us_origin_zones_filenames } },
        )
    {
        debug( "Going to unzip filename: $_" );
        #
        # Remove any leading spaces.
        #
        s/^\s//g;
        my $data_dir = $self->data_dir;

        # TODO: unzip different types of files into different directories.
        my $src  = "$data_dir/$_";
        my $dest = "$data_dir/";
        
        debug( "Going to unzip: $src into $dest" );
        _unzip_file( $src, $dest );
    }
    
    return;
}


# TODO: Instead of using File::Find, just work from a list of files in the config.
# It wont automatically pick up new files anymore, but it's likely that new files will
# require new programming anyway.

=item * get_files_to_process()

 * Find all *rate* csv files in the data directory (and sub-dirs)
 * Ignore zone files (because they can be used as-is) 
 * Ignore other files (zip files, extented area, residential, domestic, fuel surcharge, etc. files).

=cut

sub get_files_to_process
{
    my ( $self, $opt ) = @_;
    
    my @files_to_process;
    my $find_rates_files_sub = sub {
        
        my ( $base, $path ) = fileparse( $_ );  
        
        # Skip zone files.
        #debug( "File::Find found $_" );
        return unless $File::Find::dir;
        return if ( $File::Find::dir =~ /zone/i );
        return if ( $_ =~ /zone/i );
        return if ( $_ =~ /\d\d\d/ );
        my $cvs_files_skip_regexes = dtcfg()->{ ups_information }->{ csv_files_skip_regexes };
        foreach my $cvs_files_skip_regex ( @$cvs_files_skip_regexes ) {
            $cvs_files_skip_regex =~ s/\s//g;
            return if ( $_ eq $cvs_files_skip_regex );
        }
        
        my $data_dir_test_filename = $Business::Shipping::Config::data_dir_test_filename || 'this_is_the_data_dir';
        return if ( $_ eq $data_dir_test_filename );
        
        # Ignore Dirs
        return unless ( -f $_ );
        
        # Ignore temp files
        return if ( $base =~ /^\#/ );
        
        # Ignore "dot" files?

        # Ignore .zips
        return if ( /\.zip$/ );
        
        # Ignore CVS/svn files
        return if ( $File::Find::dir =~ /\.svn/ );
        return if ( $File::Find::dir =~ /CVS$/ );
        
        debug3( "File::Find adding $_\n" );
        
        push ( @files_to_process, $File::Find::name );
        return;
    };
    
    # TODO: subroutine references, how to pass $opt to find_rates_files_sub?
    my $dir = $self->data_dir;
    debug "calling find with dir $dir";
    
    #File::Find::find( $find_rates_files_sub->( $opt ), $dir );
    File::Find::find( { wanted => $find_rates_files_sub, follow => 1 }, $dir );
    
    my $cannot_convert_at_this_time = dtcfg()->{ ups_information }->{ cannot_convert };
    
    # Add the data dir to each element, convert to a regular array.
    
    my @cannot_convert_at_this_time;
    for ( @$cannot_convert_at_this_time ) {
        s/^\s+//g;
        $_ = $self->data_dir . "/$_";
        push @cannot_convert_at_this_time, $_;
    }
    
    #debug( "cannot_convert_at_this_time = " . join( ', ', @cannot_convert_at_this_time ) );
    #debug( "before grepping, files to process = " . join( ', ', @files_to_process ) );
    
    # Remove all elements of hte @files_to_process array that match any element 
    # in the cannont_convert_at_this_time array.
    
    #debug "files_to_process = " . Dumper( \@files_to_process );
    
    my @new;
    foreach my $file_to_process ( @files_to_process ) {
        my $match = 0;
        foreach my $cannot_convert ( @cannot_convert_at_this_time ) {
            if ( $file_to_process eq $cannot_convert ) {
                $match = 1;
            }
        }
        if ( ! $match ) {
            push @new, $file_to_process;
        }
    }
    @files_to_process = @new;
    
    #@files_to_process = grep { grep( $_, @cannot_convert_at_this_time ) } @files_to_process;

    #debug( "after grepping, files to process = " . join( ', ', @files_to_process ) );

    #
    # Remove the files that we cannot convert at this time.
    #
    #@files_to_process = grep( !/^$cannot_convert_at_this_time$/, @files_to_process );
    
    if ( scalar @files_to_process <= 1 ) {
        error "There are no files to process.  This probably means that File::Find could not "
            . "find any files in the data/ directory becuase it was a symlink, did not exist, "
            . "or was configured incorrectly.";
        exit;
    }
    
    return @files_to_process;
}
=item * do_convert_data()

Find all data .csv files and convert them from the vanilla UPS CSV format
into one that Business::Shipping can use.

=cut

sub do_convert_data
{
    trace '()';
    my ( $self ) = @_;
    
    #my @files_to_process = $self->get_files_to_process;
    # TODO: Remove temporary list
    # rate_files
    
    
    

    #my @files_to_process = qw{
    #     
    #};

=pod
        ./data/gndcomm.csv
        ./data/1da.csv
        ./data/1daeam.csv
        ./data/2da.csv
        ./data/3ds.csv
        ./data/gndcwt.csv
        ./data/canstnd.csv 
        ./data/ww-xpd.csv
        
=cut
    
    #die "files_to_process = " . Dumper( \@files_to_process );
    
    # Only csv files, remove non-.csv files.
    #@files_to_process = grep /.csv$/, @files_to_process;
    #return if $_ !~ /\.csv$/i and not $opt->{ include_csv };

    #debug3( "files_to_process = " . join( "\n", @files_to_process ) );
    

    #$self->process_file( 'ewwzone.csv', { zone_file => 1 } );
    #exit;
    
    my $rate_files = dtcfg()->{ ups_information }->{ us_origin_rates_filenames_individual };
    my $zone_files = dtcfg()->{ ups_information }->{ us_origin_zones_filenames_individual };
    
    # Testing: override the files list if you only want to process some files.
    #$rate_files = [ 'xarea.csv' ];
    #$zone_files = [ '986.csv' ];
    #$zone_files = [  ];
    
    for ( @$rate_files ) {
        $self->process_file( $_, { zone_file => 0 } );
    }
    for ( @$zone_files ) {
        $self->process_file( $_, { zone_file => 1 } );
    }
    return;  
}

sub process_file
{
    my ( $self, $file, $opt ) = @_;
    
    $file = $self->data_dir . '/' . $file;
    print "Processing $file...";
    if ( $self->pause ) {
        print ", press enter to continue...";
        my $keypress = <STDIN>;
    }
    print "\n";

    # Copy to new file, then rename, then process.  That way the originals will stay in place
    # and do not need to be restored from .zip or SCM.
    
    my $new_filename = remove_extension( $file ) . ".tmp";
    File::Copy::copy( $file, $new_filename ) or die "Could not copy $file to $new_filename: $!";
    $file = $new_filename;
    #$file = rename_tables_that_start_with_numbers( $file );  # No longer necessary
    $file = rename_tables_that_have_a_dash( $file );
    
    debug "remove_windows_carriage returns...";
    
    remove_windows_carriage_returns( $file );
    
    $self->convert_ups_rate_file( $file, $opt );
    
    debug "filename after all operations are done: $file";
    return;    
}



=head2 remove_misc()

Removes dollar signs, some extra spaces, empty lines, and lines with just commas.

=cut

sub remove_misc
{
    trace '()';
    my ( $path ) = @_;
    
    my $fh = get_fh( $path );
    
    # Speedy slurp
    undef $INPUT_RECORD_SEPARATOR;
    
    debug "getting file contents...";
    my $file_contents = <$fh>;
    
    if ( not defined $file_contents ) {
        error "file ($path) was empty";
        return;
    }
    
    $file_contents =~ s/\$//g;           # Dollar signs
    $file_contents =~ s/(\d\d) ,/$1,/g; # Extra space after numerical data "35 ," becomes "35,"
    $file_contents =~ s/^,+$//g;         # Just commas
    
    close_fh( $fh );
    write_file( $path, $file_contents );
    
    return;
}

sub write_file
{
    my ( $path, $contents ) = @_;
    
    return unless $path and $contents;
    
    my $fh = get_fh( ">$path" );
    
    print $fh $contents;
    
    close_fh( $fh );
    
    return;    
}

=item * rename_tables_that_start_with_numbers

=cut

sub rename_tables_that_start_with_numbers
{
    my $path = shift;
    trace "( $path )";
    
    if ( ! $path ) { error "No path"; return; }
    
    $_ = $path;
    my $new_file = $_;
    
    my ( $dir, $file ) = split_dir_file( $path );
    
    if ( not $file ) {
        error( "Could not determine filename from path" );
        return;
    }
    
    if ( $file =~ /^\d/ ) {
        $new_file = "$dir/a_$file";
        debug( "renaming $path => $new_file" );
        rename( $path, $new_file );
    }
    
    return $new_file;
}

=item * rename_tables_that_have_a_dash

=cut

sub rename_tables_that_have_a_dash
{
    my $path = shift;
    trace "( $path )";
    
    $_ = $path;
    my $new_file = $_;
    
    my ( $dir, $file ) = split_dir_file( $path );
    
    if ( $file =~ /\-/ ) {
        $file =~ s/\-/\_/g;
        $new_file = "$dir/$file";
        debug( "renaming $path => $new_file" );
        rename( $path, $new_file );
    }
    
    return $new_file;
}

=item * auto_update

=cut

sub auto_update
{
    my ( $self ) = @_;
    $self->update( 1 );
    $self->do_update();
}

=item * get_fh( $filename )

=cut

sub get_fh
{
    my ( $filename ) = @_;

    my $file_handle;
    open $file_handle, "$filename" 
        || carp "could not open file: $filename.  Error: $!";
    
    return $file_handle;
}

=item * close_fh( $file_handle )

=cut

sub close_fh
{
    my ( $file_handle ) = @_;
    
    close $file_handle;
    
    return;
}

# DT stands for DataTools in all the following.

use constant DEFAULT_DT_SUPPORT_FILES_DIR => '.';

my $dt_support_files_dir;
my $dt_config_file;

# Try the current directory first.

if ( -f 'config/DataTools.ini' ) {
    $dt_support_files_dir = '.';
}

# Then try environment variables

$dt_support_files_dir ||= $ENV{ BUSINESS_SHIPPING_SUPPORT_FILES };

# Then fall back on the default.

$dt_support_files_dir ||= DEFAULT_DT_SUPPORT_FILES_DIR;

$dt_config_file = "$dt_support_files_dir/config/DataTools.ini";

if ( ! -f $dt_config_file ) {
    die "Could not open data tools configuration file: $dt_config_file: $!";
}

tie my %dtcfg, 'Config::IniFiles', (      -file => $dt_config_file );
my $dtcfg_obj = Config::IniFiles->new(    -file => $dt_config_file );

sub dtcfg { return \%dtcfg; }

=head1 AUTHOR

Dan Browning, C<< <db@kavod.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-shipping-datatools@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2005 Daniel Browning <db@kavod.com>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
