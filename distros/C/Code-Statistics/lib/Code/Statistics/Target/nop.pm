use strict;
use warnings;

package Code::Statistics::Target::nop;
{
  $Code::Statistics::Target::nop::VERSION = '1.112980';
}

# ABSTRACT: represents nothing

use Moose;
extends 'Code::Statistics::Target';


sub find_targets {}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Target::nop - represents nothing

=head1 VERSION

version 1.112980

=head2 find_targets
    Returns nothing.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

