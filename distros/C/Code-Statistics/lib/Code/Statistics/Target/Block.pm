use strict;
use warnings;

package Code::Statistics::Target::Block;
{
  $Code::Statistics::Target::Block::VERSION = '1.112980';
}

# ABSTRACT: represents a block in perl code

use Moose;
extends 'Code::Statistics::Target';


sub find_targets {
    my ( $class, $file ) = @_;
    return $file->ppi->find( 'PPI::Structure::Block' );
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Target::Block - represents a block in perl code

=head1 VERSION

version 1.112980

=head2 find_targets
    Returns all PPI::Structure::Block elements found in the given file.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

