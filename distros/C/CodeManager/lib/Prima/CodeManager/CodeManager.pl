#!/usr/bin/perl -w
################################################################################
# This is CodeManager
# Copyright 2009-2013 by Waldemar Biernacki
# http://codemanager.sao.pl\n" .
#
# License statement:
#
# This program/library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# Last modified (DMYhms): 13-01-2013 09:41:15.
################################################################################

use strict;
use warnings;

use Prima::CodeManager::CodeManager;

our $project = Prima::CodeManager-> new();

$project-> open( 'CodeManager.cm' );

foreach ( @ARGV ) {
	if ( -f $_ ) {
		$project-> file_edit( $_ )
	} else {
		$project-> open( $_ );
	}
}

$project-> loop;

__END__
