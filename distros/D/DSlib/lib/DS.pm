#!perl

# ########################################################################## #
# Title:         Data Stream base package
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Base class for various DS objects. Holds version info as well.
# File:          $Source: /data/cvs/lib/DSlib/lib/DS.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

#TODO Major caveat: it seems that only does lexicographical comparison of version strings when searching for the lastest available module. This is plain wrong and will result in annoying errors. Always specify which version to use when using only.pm.

package DS;

use strict;
use warnings;

use Carp::Assert;
use Exporter 'import';

our( $VERSION, $REVISION, $STATE );

BEGIN {
    # This is THE version of the this package as a whole
    $__PACKAGE__::VERSION = '2.13';
    ($__PACKAGE__::STATE) = '$State: Exp $' =~ /:\s+(.+\S)\s+\$$/;

    # Sets local package version info
    $VERSION = $__PACKAGE__::VERSION;
    ($REVISION) = '$Revision: 1.3.2.1 $' =~ /(\d+\.\d+)/;
    $STATE = $__PACKAGE__::STATE;

    warn("WARNING: this code has been marked as being experimental.") if $STATE eq 'Exp';
}

our @EXPORT_OK = qw( chain_start chain_end );

sub chain_start {
    my( $target ) = @_;
    
    assert( $target->isa('DS::Target'), 'Must provide a DS::Target object' );
    my $result = $target;
    $result = $result->source while( $result->source );    

    return $result;
}

sub chain_end {
    my( $source ) = @_;
    
    assert( $source->isa('DS::Source'), 'Must provide a DS::Source object' );
    my $result = $source;
    $result = $result->target while( $result->target );    

    return $result;
}

1;

__END__
=pod

=head1 NAME

DS - Data Stream module

=head1 SYNOPSIS

  use IO::Handle;
  use DS::Importer::TabFile;
  use DS::Transformer::TabStreamWriter;
  use DS::Target::Sink;
  
  $importer = new DS::Importer::TabFile( "$Bin/price_index.csv" );
  $printer  = new DS::Transformer::TabStreamWriter( 
      new_from_fd IO::Handle(fileno(STDOUT), 'w')
  );
  $printer->include_header;
  
  $importer->attach_target( $printer );
  $printer->attach_target( new DS::Target::Sink );
  
  $importer->execute();
  

=head1 DESCRIPTION

This package provides a framework for writing data processing components
that work on typed streams. A typed stream in DS is a stream of hash 
references where every hashreference obeys certain constraints that is
contained in a type specification.

=head1 BASIC CONCEPTS

The DSlib package draws upon a handful of concepts that are introduced here.

=head2 Base classes

The base classes in DSlib are:

=over

=item L<DS::Source> A source of a data stream. Sometime just called a "source".

=item L<DS::Target> A target of a data stream. Sometime just called "target".

=item L<DS::Transformer> A source and target mixin that receives a data stream
and passes it on (with possible modifications).

=item L<DS::Importer> A source that retrieves data from a source outside DS.

=back

=head2 Processing chains

A processing chain is a linked list starting with a source, any number of 
following transformers and a target at the end of the list. An open processing
chain is a chain where source or target is missing.

Processing chains work by having the source pass data down the chain until it
eventually reaches the target, where the data goes out of DSlibs scope. The
data is passed by having each transformer in the chain call the following 
transformer, passing the data as a parameter. The only data type supported is
hash references.

=head2 End of stream convention

The data type supported by DS is hash references, but to indicate that there
is no more rows in the stream, undef is used as an end of stream-marker.

It is vital that this marker is passed on by all components in the processing 
chain, since some components may need to clean up or pass on more rows at this 
point.

=head2 Type specifications

Any source, target or transformer can have ingoing oand outgoing types that can
be used to ensure that the data passed to any target contains (but not limited 
to) a specified list of fields.

=head1 APIS SUBJECT TO CHANGE

I have decidede to pursue a more general way of writing transformers
which will be available in version 3 of this package. I am certain that
some APIs will be changed in a way that is not backwards compatible.

=head1 MISSING DOCUMENTATION

Some classes in this package are still without documentation. Send me a mail if
you run into trouble or just want clarification of something. That may also
encourage me to write the missing documentation.

=head1 SEE ALSO

L<DS::Importer::TabFile>, L<DS::Importer::Sth>, L<DS::Transformer>, 
L<DS::Transformer::Sub>, L<DS::Target::Sink>.

=head1 AUTHOR

Written by Michael Zedeler.
