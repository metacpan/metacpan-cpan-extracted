package Boost::Graph::Undirected;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.1';

require XSLoader;
XSLoader::load('Boost::Graph::Undirected', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Boost::Graph::Undirected - Undirected Graph algorithms for Boost::Graph

=head1 SYNOPSIS

  see Boost::Graph documentation 
  

=head1 DESCRIPTION

  Perl wrapper for XS code

=head2 EXPORT

None by default.



=head1 SEE ALSO

=head1 AUTHOR

David Burdick, E<lt>dburdick@systemsbiology.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by David Burdick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
