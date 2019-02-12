## -*- Mode: CPerl -*-
## File: DTA::CAB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: robust morphological analysis: top-level

package DTA::CAB;

use DTA::CAB::Version;
use DTA::CAB::Common;

#use DTA::CAB::Analyzer;           ##-- DEBUG
#use DTA::CAB::Analyzer::Common;   ##-- DEBUG
#use DTA::CAB::Analyzer::Extra;    ##-- DEBUG
eval "use DTA::CAB::Analyzer::Common";

#eval "use DTA::CAB::Server::HTTP";
#eval "use DTA::CAB::Client::HTTP";

#eval "use DTA::CAB::Server::XmlRpc";
#eval "use DTA::CAB::Client::XmlRpc";

use strict;

##==============================================================================
## Constants
##==============================================================================

our @ISA = qw(DTA::CAB::Logger); ##-- for compatibility

##==============================================================================
## Version Information

## \%moduleVersions => DTA::CAB->moduleVersions(%opts)
##  + checks all loaded modules in %::INC for $VERSION
##  + known %opts:
##    (
##     moduleMatch => $regex,   ##-- only report modules matching $regex
##     moduleIgnore => $regex,  ##-- ignore modules matching $regex
##    )
sub moduleVersions {
  no strict 'refs';
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my %opts      = @_;
  my $re_match  = $opts{moduleMatch};
  my $re_ignore = $opts{moduleIgnore};
  $re_match     = qr{$re_match} if (defined($re_match) && !ref($re_match));
  $re_ignore    = qr{$re_ignore} if (defined($re_ignore) && !ref($re_ignore));
  my ($inc,$pkg,$ver,%versions);
  foreach $inc (sort keys %::INC) {
    next if ($inc !~ m/\.pm$/i);
    $pkg = $inc;
    $pkg =~ s{/}{::}g;
    $pkg =~ s{\.pm$}{}i;
    next if (($re_match && $pkg !~ m{$re_match}) || ($re_ignore && $pkg =~ m{$re_ignore}));
    next if ( !($ver = ${"${pkg}::VERSION"}) );
    $versions{$pkg} = "$ver";
  }
  return \%versions;
}




1; ##-- be happy

__END__

##==============================================================================
## PODS
##==============================================================================
=pod

=head1 NAME

DTA::CAB - "Cascaded Analysis Broker" for robust linguistic analysis

=head1 SYNOPSIS

 use DTA::CAB;

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

The DTA::CAB suite provides an object-oriented API for
error-tolerant linguistic analysis of tokenized text.
The DTA::CAB package itself just loads the common API
from
L<DTA::CAB::Common|DTA::CAB::Common> and attempts
to load the common analysis modules from
L<DTA::CAB::Analyzer::Common|DTA::CAB::Analyzer::Common>
if present.

Earlier versions of the DTA::CAB suite used the DTA::CAB
package to represent a default analyzer class.  The corresponding
class now lives in L<DTA::CAB::Chain::DTA|DTA::CAB::Chain::DTA>.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB: Constants
=pod

=head2 Package Constants

=over 4

=item $VERSION

Module version, imported from L<DTA::CAB::Version|DTA::CAB::Version>.

=item $SVNVERSION

SVN version from which this module was built, imported from L<DTA::CAB::Version|DTA::CAB::Version>.

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB: Data Model
=pod

=head2 Data Model

DTA::CAB is designed for processing natural language data which are represented
internally by objects descended from the class L<DTA::CAB::Datum|DTA::CAB::Datum>.
Currently, the DTA::CAB data model explicitly supports the following
datum classes:

=over 4

=item L<DTA::CAB::Token|DTA::CAB::Token>

Represents a single word token as a HASH-ref with at least
a 'text' key, whose value should be a string representing the literal word text.
Additional keys may be defined by L<IO formats|/"I/O Formats">
and/or L<analyzers|/"Processing Model">.

=item L<DTA::CAB::Sentence|DTA::CAB::Sentence>

Represents a single sentence as a HASH-ref with at least
a 'tokens' key, whose value should be an ARRAY-ref of
L<DTA::CAB::Token|DTA::CAB::Token> structures.
Additional keys may be defined by L<IO formats|/"I/O Formats">
and/or L<analyzers|/"Processing Model">.

=item L<DTA::CAB::Document|DTA::CAB::Document>

Represents a text document as a HASH-ref with at least
a 'body' key, whose value should be an ARRAY-ref of
L<DTA::CAB::Sentence|DTA::CAB::Sentence> structures.
Additional keys may be defined by L<IO formats|/"I/O Formats">
and/or L<analyzers|/"Processing Model">.

=back

See the subclass documentation for details.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB: I/O Formats
=pod

=head2 I/O Formats

DTA::CAB supports a number of different I/O formats for
L<document data|/"Data Model">,
including
L<"CSV"|DTA::CAB::Format::CSV>,
L<"JSON"|DTA::CAB::Format::JSON>,
L<"Raw"|DTA::CAB::Format::Raw>,
L<"Text"|DTA::CAB::Format::Text>,
L<"TT"|DTA::CAB::Format::TT>,
L<"YAML"|DTA::CAB::Format::YAML>,
and
L<"XML"|DTA::CAB::Format::XmlNative>.
See L<DTA::CAB::Format> for details on the I/O format API,
and see L<DTA::CAB::Format/SUBCLASSES> for a list of currently
implemented format subclasses.

The command-line utility
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>
is provided for converting between supported I/O formats.

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB: Processing Model
=pod

=head2 Processing Model

Input documents are processed by one or more
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> objects,
each of which may insert, modify, and/or remove
arbitrary properties of the
analyzed L<data|/"Data model">, e.g.
a morphological analyzer (L<DTA::CAB::Analyzer::Morph|DTA::CAB::Analyzer::Morph>)
might insert a token property 'morph'
which could be read in turn by a
part-of-speech tagger (L<DTA::CAB::Analyzer::Moot|DTA::CAB::Analyzer::Moot>).

See
L<DTA::CAB::Analyzer> for a specification of the basic analysis API,
see
L<DTA::CAB::Analyzer::Common> for some common analyzers,
see
L<DTA::CAB::Chain> and/or L<DTA::CAB::Chain::Multi>
for abstract encapsulations of serial analysis "pipelines",
and see
L<DTA::CAB::Chain::DTA> for the analysis chains used
in the I<Deutsches Textarchiv> project.

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>
is a command-line utility for invoking
a local L<persistent|DTA::CAB::Persistent>
analyzer on
a L<document|/"Data Model"> in some supported L<format|/"I/O Formats">.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB: Server/Client
=pod

=head2 Server/Client Architectures

The DTA::CAB suite implements
two different server/client architectures
in order to facilitate shared use of common processing pipelines,
as well as to avoid extraneous overhead for L<analyzers|/"Processing Model">
which require excessive initialization times.
L<DTA::CAB::Server|DTA::CAB::Server> and L<DTA::CAB::Client|DTA::CAB::Client>
define the abstract server/client API.

=head3 XML-RPC Server/Client Protocol

B<DEPRECATED> in favor of raw L<HTTP|/"HTTP Server/Client Protocol">.

L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc> implements a simple
XML-RPC HTTP server which can be used to handle analysis requests for
one of a user-specified set of L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>
objects formulated as XML-RPC procedure calls.
L<DTA::CAB::Client::XmlRpc|DTA::CAB::Client::XmlRpc> provides a wrapper class
for querying such a server.
See L<DTA::CAB::XmlRpcProtocol>
for an brief overview of the procedures available
and an XML-RPCish rehash of the DTA::CAB L<data model|/"Data Model">.

The command-line scripts
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>
and
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>
implement the (deprecated) XML-RPC server/client protocol.

=head3 HTTP Server/Client Protocol

L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> implements a simple
HTTP server which can be used to handle analysis requests for
one of a user-specified set of L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>
objects.  The analysis requests themselves are handled by the
L<DTA::CAB::Server::HTTP::Handler::Query|DTA::CAB::Server::HTTP::Handler::Query>
handler class, which interprets incoming GET and/or POST requests as conventional HTTP
form data, invokes the specified analyzer on the query document, and returns a
formatted document in the HTTP response.
L<DTA::CAB::Client::HTTP|DTA::CAB::Client::HTTP> provides a wrapper class
for querying such a server.  Additionally, both HTTP servers and clients support a
backwards-compatible L<XML-RPC mode|/"XML-RPC Server/Client Protocol">.

The command-line scripts
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>
and
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>
implement the HTTP server/client protocol.

=head3 CLARIN-D WebLicht Protocol

A running L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> server can be used directly
as a CLARIN-D WebLicht web-service by using the "tcf" or "tcf-orth" formats.
The "CAB historical text analysis"
and "CAB orthographic canonicalizer" WebLicht chain components are implemented
in this fashion; see L<http://weblicht.sfs.uni-tuebingen.de/weblichtwiki/> for details.

=cut




##==============================================================================
## Footer
##==============================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
