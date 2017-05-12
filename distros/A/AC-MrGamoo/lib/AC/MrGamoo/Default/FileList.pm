# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-14 17:04 (EST)
# Function: get list of files to map
#
# $Id: FileList.pm,v 1.1 2010/11/01 18:41:54 jaw Exp $

package AC::MrGamoo::Default::FileList;
use strict;


# return an array of:
#   {
#     filename    => www/2010/01/17/23/5943_prod_5x2N5qyerdeddsNi
#     location    => [ mrm@server1, mrm@server2 ]
#     size        => 10863
#   }

sub get_file_list {
    my $config = shift;

    die "get_file_list not implemented. you need to provide this.\nsee 'class_filelist' in the documentation\n";
}


1;
