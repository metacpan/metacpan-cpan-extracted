# NAME

Data::QuickMemoPlus::Reader - Extract text from QuickMemo+ LQM export files.

# SYNOPSIS

    use Data::QuickMemoPlus::Reader qw(lqm_to_str);
    my $memo_text = lqm_to_str('QuickMemo+_191208_220400.lqm');

    use Data::QuickMemoPlus::Reader qw(lqm_to_txt);
    my $files_converted1 = lqm_to_txt('QuickMemo+_191208_220400.lqm');
    my $files_converted2 = lqm_to_txt('path/to/lqm_files');
    
    ## Omit the header text by setting setting this package variable to false:
    local $Data::QuickMemoPlus::Reader::IncludeHeader;

# DESCRIPTION

`Data::QuickMemoPlus::Reader` is a module that will extract the 
text contents from archived QuickMemo+ memos. QuickMemo+ is a memo 
application that comes with LG smartphones.

QuickMemo+ `lqm` files are in Zip format. This module unzips them, 
parses the json file inside, then extracts the category and memo text 
from the Json file.

If the filename of the lqm file contains the original timestamp then that
is placed in a text header in the text along with the category name. The header
can be disabled by setting the package variable `$IncludeHeader` to false.

The following functions are available:

## lqm\_to\_txt('directory or filename')

Creates a text file with the same name as each original lqm file but with a txt extension.
Return value is the number of files successfully converted.

## lqm\_to\_str('filename')

Returns the text extracted from the lqm file.

# LICENSE

Copyright (C) Brent Shields.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Brent Shields <bshields@cpan.org>
