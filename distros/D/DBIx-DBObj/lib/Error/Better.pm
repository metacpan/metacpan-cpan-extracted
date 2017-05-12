package Error::Better; 

# Copyright (C) 2003 Matt Knopp <mhat@cpan.org>
# This library is free software released under the GNU Lesser General Public
# License, Version 2.1.  Please read the important licensing and disclaimer
# information included in the LICENSE file included with this distribution.

use strict;
use Error; 
our @ISA = qw (Error::Simple); 

sub nice_text {
  my $self  = shift;
  my $text  = sprintf("Class: %s\n", ref($self)); 
  $text    .= sprintf("Text : %s\n", $self->text()); 
  $text    .= sprintf("File : %s\n", $self->file()); 
  $text    .= sprintf("Line : %d\n", $self->line()); 
  return($text); 
}

package Error::Better::InvalidArguments; 
our @ISA = qw (Error::Better); 

package Error::Better::OperationFailed; 
our @ISA = qw (Error::Better); 

package Error::Better::ObjectIncomplete;
our @ISA = qw (Error::Better); 

package Error::Better::ObjectExists;
our @ISA = qw (Error::Better); 

package Error::Better::ObjectNotFound;
our @ISA = qw (Error::Better);

1; 
