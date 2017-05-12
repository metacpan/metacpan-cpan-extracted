#!/usr/bin/perl
################################################################################
#
#  Script Name : UPS_XML.pm
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description: A custom self contained module to calculate UPS rates using the
#               newer XML method.  This module properly calulates rates between
#               and within other non-US countries including Canada.
#               
#  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/interchange_upsxml/lib/Business/Shipping/UPS_XML/Parser.pm,v 1.1 2004/06/27 13:53:20 dlhinkley Exp $
#
#  $Log: Parser.pm,v $
#  Revision 1.1  2004/06/27 13:53:20  dlhinkley
#  Rename module to UPS_XML
#
#  Revision 1.3  2004/06/10 02:03:16  dlhinkley
#  Fixed bugs from breaking up code and putting in CPAN format
#
#  Revision 1.2  2004/06/01 02:48:25  dlhinkley
#  Changes to make work
#
#  Revision 1.5  2004/05/21 21:28:36  dlhinkley
#  Add Currency
#
#  Revision 1.4  2004/04/20 01:28:00  dlhinkley
#  Added option for dimensions
#
#  Revision 1.3  2004/03/14 18:50:31  dlhinkley
#  Working version
#
#
################################################################################

package Business::Shipping::UPS_XML::Parser;
use strict;

use vars qw($VERSION);

$VERSION = "0.07";

sub new {
   my $type  = shift;
   my ($xml,$level) = @_;
   my $self  = {};
   # print "Start Level $level\n";
   $level++;
   $self->{'_name'} = undef;
   $self->{'_contents'} = undef;
   $self->{'_xml'} = $xml;
   $self->{'_level'} = $level;
   $self->{'_true'} = 1;
   $self->{'_false'} = 0;

   bless $self, $type;
}


sub xml {

   my $self = shift;

   my ($xml)= @_;

   if ($xml ne "") {

	   $self->{'_xml'} = $xml;
   }
   return $self->{'_xml'};
}
sub name {

   my $self = shift;

   my ($v)= @_;

   if ($v ne "") {

	   $self->{'_name'} = $v;
   }
   return $self->{'_name'};
}
sub contents {

   my $self = shift;

   my ($v)= @_;

   if ($v ne "") {

	   $self->{'_contents'} = $v;
   }
   return $self->{'_contents'};
}
sub have_children {

   my $self = shift;
   my $children;
   my $contents = $self->{'_contents'};

   if ($contents && $contents =~ /<.*>/sm) {

	   $children = $self->{'_true'};
   }
   else {

	   $children = $self->{'_false'};
   }
   return $children;
}
sub have_more_xml {

   my $self = shift;
   my $children;
   my $xml = $self->{'_xml'};
   my $more;

   if ($xml =~ /<.*>/sm) {

	   $more = $self->{'_true'};
   }
   else {

	   $more = $self->{'_false'};
   }
   return $more;
}
sub remove_xml_type {

	my $self = shift;

	my $xml = $self->{'_xml'};

	$xml =~ s/<\?xml version="[0-9]\.[0-9]"\?>//;

	$self->{'_xml'} = $xml;
}
sub parse {

   my $self = shift;
   my $contents;
   my $name;
   my $no_children;
   
   $self->remove_xml_type();

   while ( $self->have_more_xml() ) {

      $self->set_name();
	  # print "Set Name " . $self->{'_name'} . "\n";
      $self->set_contents();
	  # print "Set Contents " . $self->{'_contents'} . "\n";
	  # print "xml " . $self->{'_xml'} . "\n";

	  $no_children = 0;

      while ( $self->have_children() ) {

	      $self->spawn_new_object();

		  $no_children++;
      }
	  # If there was no children assign the contents to a variable
	  #
	  if ( $no_children == 0 ) {
         # print "child\n";

         $contents = $self->{'_contents'};
         $name = $self->{'_name'};
         $self->{$name} = $contents;
	  }
	  $self->{'_name'} = undef;
	  $self->{'_contents'} = undef;
   }
   # print "End Level " . $self->{'_level'} . "\n";
}
sub spawn_new_object() {

   my $self = shift;

   my $contents = $self->{'_contents'};
   my $name = $self->{'_name'};
   $self->{'_name'} = undef;
   $self->{'_contents'} = undef;

   my $x = new Business::Shipping::UPS_XML::Parser($contents,$self->{'_level'});
   $x->parse();
   $self->{$name} = $x;
}
sub set_name {

   my $self = shift;

	my $xml = $self->{'_xml'};

	$xml =~ /<([A-Za-z]*)>/sm;

	$self->{'_name'} = $1;
}
sub set_contents {

    my $self = shift;
	my $xml = $self->{'_xml'};

	my $name = $self->{'_name'};

	# Save the contents of the tag
	#
	#$xml =~ s/<$name>(.*)<\/$name>{1}//s;

	# Matches the contents of the named tag and removes the tag set from xml
	#
    $xml =~ s/<$name>( ( ?: (?!<\/$name>).)*)<\/$name>//sx;
    $self->{'_contents'} = $1;
	$self->{'_xml'} = $xml;
}

#########################################################################################33
# End of class

1;

__END__

=head1 NAME

Business::Shipping::UPS_XML::Parser - UPS XML Parser


=head1 DESCRIPTION

This module is a simple way of parsing the UPS XML without downloading
a bunch of modules.  Not designed to be used independently.


=back


=head1 AUTHOR

Duane Hinkley, <F<duane@dhwd.com>>

L<http://www.DownHomeWebDesign.com>

Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

If you have any questions, comments or suggestions please feel free 
to contact me.


=cut

1;

