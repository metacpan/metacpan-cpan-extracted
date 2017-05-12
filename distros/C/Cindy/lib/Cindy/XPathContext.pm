# $Id: Functions.pm 66 2010-04-01 17:22:24Z jo $
# Cindy::Functions - XPath extension functions to use in CIS 
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Cindy::XPathContext ;

use strict;
use warnings;
 
use base qw(XML::LibXML::XPathContext);


sub new {
  my $class = shift;
  my $self  = XML::LibXML::XPathContext->new(@_);

  $self->registerFunction('current', 
            sub {return $self->getContextNode();});

  return bless($self, $class);  
}

#sub DESTROY
#{
#  my ($self) = @_;
#  $self->unregisterFunction('current');
#  $self->SUPER::DESTROY();
#}

1;

