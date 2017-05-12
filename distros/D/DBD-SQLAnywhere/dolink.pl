# ***************************************************************************
# Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
# ***************************************************************************
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#   While not a requirement of the license, if you do modify this file, we
#   would appreciate hearing about it. Please email
#   sqlany_interfaces@sybase.com
#
#====================================================

use strict;
my $dll = shift;
if( !defined( $dll ) ) {
    die( "Use: %s target [link_args]*\n" );
}
my $cmd = 'link ';
my $arg;
foreach $arg ( @ARGV ) {
    &add_arg( \$cmd, $arg );
}
&run( $cmd );

my $manifest = "$dll.manifest";
if( -e $manifest ) {
    $cmd = "mt.exe ";
    &add_arg( \$cmd, "-outputresource:$dll;2" );
    &add_arg( \$cmd, "-manifest" );
    &add_arg( \$cmd, $manifest );
    &run( $cmd );
}

sub add_arg
{
    my( $dest, $arg ) = @_;
    if( $arg =~ /\s/ ) {
	$$dest .= "\"$arg\" ";
    } else {
	$$dest .= "$arg ";
    }
}
sub run
{
    my( $cmd ) = @_;
    my $status;

    printf( "%s\n", $cmd );
    $status = system( $cmd ) >> 8;
    if( $status != 0 ) {
	printf( STDERR "Command failed with status %d.\n", $status );
	exit( $status );
    }
}

