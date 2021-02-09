package Data::QuickMemoPlus::Reader;
use 5.010;
use strict;
use warnings;
use Carp;
use JSON;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

our $VERSION = "0.06";

use Exporter qw(import);
 
our @EXPORT_OK = qw( lqm_to_str lqm_to_txt );
our $IncludeHeader = 1;

sub lqm_to_txt {
    my ( $lqm ) = @_;
    my $files_converted = 0;
    if (-d $lqm){
        $lqm =~ s![/\\]+$!!;
        foreach(glob qq("$lqm/*.lqm")){
            $files_converted += _lqm_file_to_txt($_);
        }
    } else {
        $files_converted = _lqm_file_to_txt($lqm);
    }
    return $files_converted;
}
sub _lqm_file_to_txt {
    my ( $lqm_file ) = @_;
    my $text = lqm_to_str($lqm_file);
    
    return 0 if not length($text);
    
    my $outfile = $lqm_file;
    $outfile =~ s/lqm$/txt/i;
    open my $fh, ">", $outfile or do {
        carp "couldn't open $outfile\n";
        
        return 0;
    };
    print $fh $text;
    
    return 1;
}

sub lqm_to_str {
    my ( $lqm_file ) = @_;
    if (not -f $lqm_file){
        carp "$lqm_file is not a file";
        
        return '';
    }
    my $note_created_time = "";
    if ( $lqm_file =~ /(QuickMemo\+_(\d{6}_\d{6})(\(\d+\))?)/i) {
        $note_created_time = $2;
    }
    my $json_str = extract_json_from_lqm( $lqm_file );
    
    return '' if not $json_str;
    
    my ($extracted_text, $note_category) = extract_text_from_json($json_str);
    my $header = "Created date: $note_created_time\n";
    $header .= "Category:   $note_category\n";
    $header .= "-"x79 . "\n";
    $header = '' if not $IncludeHeader;
    
    return $header . $extracted_text;
}

#####################################
#
sub extract_json_from_lqm {
    my $lqm_file = shift;
    my $lqm_zip = Archive::Zip->new();
    unless ( $lqm_zip->read( $lqm_file ) == AZ_OK ) {
        carp "Error reading $lqm_file";
        ####### to do: add the zip error to the warning?
        
        return "";
    }
    my $jlqm_filename = "memoinfo.jlqm";
    my $member = $lqm_zip->memberNamed( $jlqm_filename );
    if( not $member ){
        carp "File not found: $jlqm_filename in archive $lqm_file";
        
        return "";
    }
    my ( $string, $status ) = $member->contents();
    if(not $status == AZ_OK){
        carp "Error extracting $jlqm_filename from $lqm_file : Status = $status";
        
        return "";
    }
    
    return $string;
}

###############################################
#
sub extract_text_from_json {
    my $json_string = shift;
    
    ############# To do: eval this and trap errors.
    my $href_memo  = decode_json $json_string;
    if (not $href_memo){
        carp "Error decoding JSON file in lqm archive.";
        return '','';
    }
    my $text = "";
    foreach( @{$href_memo->{MemoObjectList}} ) {
        $text .= $_->{DescRaw};
        $text .= "\n";
    }
    my $category = $href_memo->{Category}->{CategoryName};
    $category //= '';
    $category =~ s/[^\w-]/_/g;
    return $text, $category;
}
1;
__END__

=encoding utf-8

=head1 NAME

Data::QuickMemoPlus::Reader - Extract text from QuickMemo+ LQM export files.

=head1 SYNOPSIS

    use Data::QuickMemoPlus::Reader qw(lqm_to_str);
    my $memo_text = lqm_to_str('QuickMemo+_191208_220400.lqm');

    use Data::QuickMemoPlus::Reader qw(lqm_to_txt);
    my $files_converted1 = lqm_to_txt('QuickMemo+_191208_220400.lqm');
    my $files_converted2 = lqm_to_txt('path/to/lqm_files');
    
    ## Omit the header text by setting setting this package variable to false:
    local $Data::QuickMemoPlus::Reader::IncludeHeader;

=head1 DESCRIPTION

C<Data::QuickMemoPlus::Reader> is a module that will extract the 
text contents from archived QuickMemo+ memos. QuickMemo+ is a memo 
application that comes with LG smartphones.

QuickMemo+ F<lqm> files are in Zip format. This module unzips them, 
parses the json file inside, then extracts the category and memo text 
from the Json file.

If the filename of the lqm file contains the original timestamp then that
is placed in a text header in the text along with the category name. The header
can be disabled by setting the package variable C<$IncludeHeader> to false.

The following functions are available:

=head2 lqm_to_txt('directory or filename')

Creates a text file with the same name as each original lqm file but with a txt extension.
Return value is the number of files successfully converted.

=head2 lqm_to_str('filename')

Returns the text extracted from the lqm file.

=head1 LICENSE

Copyright (C) Brent Shields.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Brent Shields E<lt>bshields@cpan.orgE<gt>

=cut

