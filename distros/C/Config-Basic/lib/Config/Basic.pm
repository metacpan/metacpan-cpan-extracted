###########################################################
# Tie::Countloop package
# Gnu GPL2 license
#
# $Id:: Basic.pm 85 2007-06-13 14:12:01Z fabrice         $
# $Revision:: 85                                         $
#
# Fabrice Dulaunoy <fabrice_at_dulaunoy_dot_com>
###########################################################
# ChangeLog:
#
###########################################################=

=head1 SYNOPSIS

=over 3

B<Config::Basic>

	A basic config parser
	for file where a section start at first column and end when a new section appear

=back

=cut

package Config::Basic;
use strict;
use Carp;
use IO::All;

use fields qw{ sections target traillers headers };
use vars qw($VERSION);

#$VERSION = do { my @rev = ( q$Revision: 85 $ =~ /\d+/g ); sprintf "%d." . "%d" x $#rev, @rev };
$VERSION = do { my @rev = ( q$Revision: 85 $ =~ /\d+/g ); sprintf "1.%02d", @rev };

use Data::Dumper;
###########################################################################

###########################################################################
### 			class creator					###
###########################################################################

=head1 METHODS
	
	OO interface

=head2 new

=over

Create a new parser 

=over

"-sections" = an ARRAY with all possible section
"-target"	a file name to parse or a ref ARRAY with the data to parse
"-data"	  	is a synonym of "-target"
"-file"	  	is a synonym of "-target"

t
"-traillers"	is an  ARRAY with all regular expresiion allowed for a trailler (to skip in the preceding section )
"-headers"	is an  ARRAY with all regular expresiion allowed for a headers (to add to the following section)

the trailler and headers could be retrived into the parsed data
these 2 parameters are optionals

my $a  = B<Config::Basic>->new(
    	-data => \@data,
    	-sections => [ 'global', 'listen', 'defaults' ],
);	

=back

=back

=cut

sub new
{
    my $self = shift;
    no strict "refs";
    $self = fields::new( $self );
    $self->{ sections }  = { @_ }->{ -sections };
    $self->{ traillers } = { @_ }->{ -traillers };
    $self->{ headers }   = { @_ }->{ -headers };
    $self->{ target }    = { @_ }->{ -file } || { @_ }->{ -data } || { @_ }->{ -target };
    return $self;
}
###########################################################################

###########################################################################
### 			get/set method for the target object 		###
###########################################################################

=head2 target

	get/set the target in use

	my $target = $a->target(  ) ;			# return the current target	
	my $target =  $a->target( "new.cfg" ) ;		# change the target to the file "new.cfg" 
							# and return the new target (here the file name)
	my $target = $a->target( \@data );		# change the target to the a ARRAY ref 
							# and return the new target (here the ARRAY ref)

=cut	

sub target
{
    my $self   = shift;
    my $object = shift;
    if ( $object )
    {
        $self->{ target } = $object;
    }
    return $self->{ target };
}
###########################################################################

###########################################################################
### 			get/set  method for the sections		###
##"		sections are a ARRAY  of all possible section		###
###########################################################################

=head2 sections

	get/set the sections to use


	my $sect = $a->sections(  ) ;				# return  a ARRAY ref with the current sections	
	my $new_sect = $a->sections( [ 'all', 'server' ]  );   	# create a new set of sections and 
								# return a ARRAY ref with the current sections

=cut	

sub sections
{
    my $self   = shift;
    my $object = shift;
    if ( $object )
    {
        $self->{ sections } = $object;
    }
    return $self->{ sections };
}
###########################################################################

###########################################################################
### 		get/set  method for the traillers to skip		###
##"		traillers are a ARRAY  of all possible section		###
###########################################################################

=head2 traillers

	get/set the traillers to skip
	if at the end of a section, lines match one of these REGEX 
	these lines are not include in the section.
	This allow to keep blank line and comment inside a section 
	and get the real ending of the section (e.g. to allow an insert) 

	my $sect = $a->trailler(  ) ;				# return  a ARRAY ref with the current traillers	
	my $new_sect = $a->trailler( [ '^\s*$', '^#' ]  ) ;     # create a new set of traillers and 
								# return a ARRAY ref with the current traillers

=cut	

sub traillers
{
    my $self   = shift;
    my $object = shift;
    if ( $object )
    {
        $self->{ traillers } = $object;
    }

    return $self->{ traillers };
}
###########################################################################

###########################################################################
### 		get/set  method for the header to add			###
###		header with the following section section		###
###		this allow to  keep comment with the section		###
###########################################################################

=head2 traillers

	get/set the headers to at
	if before of a  section, lines match one of these REGEX 
	these lines are add in the section (under the tag "start_headers").
	This allow to keep comment to belong to a following section 
	and get the real starting of the section (e.g. to allow an insert) 

	my $sect = $a->header(  );				# return  a ARRAY ref with the current headers	
	my $new_sect = $a->headers( [ '^\s*$', '^#' ]  ) ;     	# create a new set of headers and 
								# return a ARRAY ref with the current headers

=cut	

sub headers
{
    my $self   = shift;
    my $object = shift;
    if ( $object )
    {
        $self->{ headers } = $object;
    }

    return $self->{ headers };
}
###########################################################################

###########################################################################
### 		method to retrieve a section				###
###			Param: a ref hash with start and end line	###
###			 {						###
###			        'end' => 25,				###
###			         start' => 8				###
###			 }						###
###									###
###########################################################################

=head2 get_section

	method to retrieve a section.
	the method expect a ref to a HASH with { start => "start_line" , end => "end_line" }


	my $se = $a->get_section( $res->{ listen }[1] );   # return 3 elements:
			start line (sithout headers)
			end line (without traillers)
			ARRAY ref with the content of the section

=cut	

sub get_section
{
    my $self   = shift;
    my $object = shift;
    my @all;
    if ( !( ref $self->{ target } ) )
    {
        @all = io( ( $self->{ target } ) )->chomp->slurp;
    }
    else
    {
        @all = @{ $self->{ target } };
    }
    my @section = splice @all, $object->{ start }, $object->{ end } - $object->{ start } + 1;

    return $object->{ start }, $object->{ end }, \@section;

}
###########################################################################

###########################################################################
### 			parse the target and return a ref to a hash 	###
###			where each section contain a array of hash 	###
###			with start  and end line (fisrt line = 0)	###
###									###
###	   { 	 'global' => [						###
###                        {						###
###                          'end' => 8,				###
###                          'start' => 0				###
###                        }						###
###                      ]						###
###        }								###
###########################################################################

=head2 parse

	method to parse a target
	the method return a ref to a HASH. 
	Each key are a section.
	Each value contain a ref to an ARRAY with a ref to a HASH for each section seen in the target
	There are for key in each section descrition
		start 		= the line where the section start 
		end   		= the line where the section end without the traillers part if defined
		start_header 	= the line where the section start included the header if defined
		end_trailler	= the line where the section end with the traillers part if defined
		
	my $se = $a->get_section( $res->{ listen }[1] );   # return ARRAY ref with the content of the second section 'listen'

=cut	

sub parse
{
    my $self = shift;
    my %sect;
    foreach ( @{ ( $self->{ sections } ) } )
    {
        $sect{ $_ } = [];
    }

    my @all;
    if ( !( ref $self->{ target } ) )
    {
        @all = io( ( $self->{ target } ) )->chomp->slurp;

    }
    else
    {
        @all = @{ $self->{ target } };
    }

    my $line_nbr = -1;
    my $seen;
    my $start;
    my $end;
    my $seen_regex;
    my $traillers = 1;
    my $headers   = 0;
    my $traillers_regex;
    my $headers_regex;
    my $head;
    my $head_start;
    my $head_end;

    if ( defined $self->{ traillers } )
    {
        $traillers_regex = "(" . ( join ")|(", @{ $self->{ traillers } } ) . ")";
    }
    if ( defined $self->{ headers } )
    {
        $headers_regex = "(" . ( join ")|(", @{ $self->{ headers } } ) . ")";
    }
    my $old_headers = 0;
    foreach my $line ( @all )
    {
        $line_nbr++;
        foreach my $regex ( @{ $self->{ sections } } )
        {
            if ( $line =~ m/^($regex)/g )
            {

                if ( $seen )
                {
                    $end = $line_nbr;
                    my @tmp = @{ $sect{ $seen_regex } };
                    my %range;
                    $range{ start }         = $start;
                    $range{ end }           = $end - $traillers;
                    $range{ end_traillers } = $end - 1;
                    $range{ start_headers } = $start - $old_headers;
                    $traillers              = 1;
                    push @tmp, \%range;
                    $sect{ $seen_regex } = \@tmp;
                    $start               = $line_nbr;
                    $seen_regex          = $regex;
                    $old_headers         = $headers;
                }
                else
                {
                    $seen_regex = $regex;
                    $start      = $line_nbr;
                    $seen ^= 1;
                }
            }

        }

        if ( defined $self->{ headers } )
        {
            my $line_tmp = $line;
            if ( ( $line_tmp =~ /($headers_regex)/g ) )
            {
                $headers++;
            }
            else
            {
                $headers = 0;
            }
        }

        if ( defined $self->{ traillers } )
        {
            my $line_tmp = $line;
            if ( $seen && ( $line_tmp =~ m/($traillers_regex)/g ) )
            {
                $traillers++;
            }
            else
            {
                $traillers = 1;
            }
        }
    }

    if ( $seen )
    {
        $line_nbr++;
        my @tmp = @{ $sect{ $seen_regex } };
        my %range;
        $range{ start }         = $start;
        $range{ end }           = $line_nbr - $traillers;
        $range{ end_traillers } = $line_nbr - 1;
        $range{ start_headers } = $start - $old_headers;
        push @tmp, \%range;
        $sect{ $seen_regex } = \@tmp;
    }
    return \%sect;
}
###########################################################################

1;

__END__

=head1 EXAMPLES

Parse a file like this (named here test1.cfg)


###########################################################################

	global
		daemon
		max		10000    
		log 127.0.0.1 local0 notice
		pidfile  /var/run/running.pid
		nbproc	2
	
	defaults
		mode	application
		option	dontlognull
		option	closeonexit
		retries	1
		contimeout	5000
	#	
	special  extra value
	# comment 1
		item	1
	#comment 2
	#
	
		item	2
		
	#####	
	# test header
	#####	
	server	192.168.1.2
		log	global
		option	test
		type	ping 750
		
	server	192.168.1.3
		log	local
		option	test
		type	udp 800
	
	## other
	server	192.168.1.5
		log	global
		option	test2
		type	tcp 4000
	
	

		
###########################################################################	

## First example: ##

	#!/usr/bin/perl
	
	use strict;
	
	use Config::Basic;
	use Data::Dumper;
	use Config::General;
	
	print "#" x 30;
	print "\n First example\n";
	print "#" x 30;
	print "\n";
	
	my $data_file = "test1.cfg";
	
	# Instantiate a new Config::Basic object
	# the input file is "test1.cfg"
	# we expect 3 sections tag
	# and each trailling part of the section matching one of the regular "traillers" REGEX is skipped
	# this allow to skip trailling blank line or comment at the end,
	# but keep blank line and comment inside the section
	
	my $a = Config::Basic->new(
	    -file     => $data_file,
	    -sections => [ 'global', 'server', 'defaults', 'special' ],
	    -traillers => [ '^\s*$' , '^#' ],
	    -headers => [ '^#' ],
	);
	
	print "\nPrint the 'sections' set\n";
	print Dumper( $a->sections );
	
	print "\nPrint the parsed data\n";
	print "look at the value start_headers and end_traillers\n";
	print "for the section 'special' and the first section 'server'\n";
	my $res = $a->parse();
	print Dumper( $res );
	
	my $se = $a->get_section( $res->{ server }[1] );
	
	print "\nPrint Config::General result for the second 'server' section\n";
	my %re = ParseConfig( -String => $se );
	print Dumper( \%re );
	
	print "\nSet a new sections set and print it\n";
	print Dumper( $a->sections( [ 'global', 'server', 'special', 'defaults' ] ) );
	
	
	print "\nParse the data and print\n";
	$res = $a->parse();
	print Dumper( $res );
	
	
	print "\nExtract the second firts 'server'\n";
	$se = $a->get_section( $res->{ server }[0] );
	print Dumper( $se );
	
	
	print "\nPrint the 'traillers' set\n";
	$se = $a->traillers( );
	print Dumper( $se );
	
	print "\nPrint the 'headers' set\n";
	$se = $a->headers( );
	print Dumper( $se );
	
	
	print "\n";
	print "#" x 30;
	print "\n Second example\n";
	print "#" x 30;
	print "\n";
	
	use IO::All;
	
	
	my @data = io( $data_file )->chomp->slurp;
	my $a    = Config::Basic->new(
	    -file     => \@data,
	    -sections => [ 'global', 'server', 'defaults' ],
	    -traillers => [ '^\s*$', '^#' ],
	);
	
	my $res = $a->parse();
	
	# Get the second 'server' section and use start , end and real data
	my ( $start, $end, $sect ) = $a->get_section( $res->{ server }[1] );
	
	# set the line counter to the start of the section
	my $line_nbr = $start;
	foreach my $line ( @{ $sect } )
	{
	# increment the line counter
	    $line_nbr++;
	    
	# made some test onthe line data
	    if ( $line =~ /type/ )
	    {
	        print "$line_nbr $line\n";
		
	# directly modify the line in the real data
	        $data[ $line_nbr -1 ] =~ s/udp/UDP/;
	    }
	}
	
	# show the result (or save, or  ...)
	print Dumper( \@data );
	

=end readme

=head1 AUTHOR

Fabrice Dulaunoy <fabrice[at]dulaunoy[dot]com>

07 december 2006

=head1 LICENSE

Under the GNU GPL2

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public 
License as published by the Free Software Foundation; either version 2 of the License, 
or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; 
if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

B<Config::Basic> Copyright (C) 2006,2007 DULAUNOY Fabrice. B<Config::Basic> comes with ABSOLUTELY NO WARRANTY; 
for details See: L<http://www.gnu.org/licenses/gpl.html> 
This is free software, and you are welcome to redistribute it under certain conditions;

