use strict;
use warnings;

package Code::Statistics::Target::RootDocument;
{
  $Code::Statistics::Target::RootDocument::VERSION = '1.112980';
}

# ABSTRACT: represents the root PPI document of a perl file

use Moose;
extends 'Code::Statistics::Target';


sub find_targets {
    my ( $class, $file ) = @_;
    return [ $file->ppi ];
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Target::RootDocument - represents the root PPI document of a perl file

=head1 VERSION

version 1.112980

=head2 find_targets
    Returns the root PPI document of the given perl file.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

