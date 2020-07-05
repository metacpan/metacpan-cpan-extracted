#-*- Mode: CPerl -*-

## File: DDC::Concordance.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: top-level
##======================================================================

package DDC::Concordance;
#require 5.10.0;  ##-- for // operator : dependency REMOVED for DDC::Concordance v0.22
use DDC::HitList;
use DDC::Hit;
use DDC::Client;
use DDC::Client::Distributed;
use DDC::Format;
use DDC::Format::Text;
use DDC::Format::Kwic;
use DDC::Format::Dumper;
use DDC::Format::Raw;
use strict;

##======================================================================
## Globals
our $VERSION = '0.48'; ##-- for ddc >= v2.0.21; fixes for ddc >= 2.0.38
our @ISA = qw();


1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Concordance - Query and wrapper utilities for DDC search engine

=head1 SYNOPSIS

 use DDC::Concordance;

 #... stuff happens ...

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

This top-level package doesn't do anything but load all of the
DDC-related submodules.  See submodule documentation for details.

=cut

##======================================================================
## SUBMODULES
=pod

=head1 SUBMODULES

=over 4

=item L<DDC::Client|DDC::Client>

Abstract class for querying a DDC server.

=item L<DDC::Client::Distributed|DDC::Client::Distributed>

Class for querying a distributed DDC server.

=item L<DDC::Hit|DDC::Hit>

Class for a single hit as returned by a DDC server.

=item L<DDC::HitList|DDC::HitList>

Class for a list of hits returned by a DDC server.

=item L<DDC::Filter|DDC::Filter>

Base class for implementing DDC server filters (proxies, wrappers, etc.)

=item L<DDC::Format|DDC::Format>

Abstract class for formatting L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::Dumper|DDC::Format::Dumper>

Class for Data::Dumper formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::JSON|DDC::Format::JSON>

Class for JSON formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::Kwic|DDC::Format::Kwic>

Class for keyword-in-context (KWIC) formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::Raw|DDC::Format::Raw>

Class for raw formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::Template|DDC::Format::Template>

Class for generic template-based formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::Text|DDC::Format::Text>

Class for text-formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Format::YAML|DDC::Format::YAML>

Class for yaml-formatting of L<DDC::HitList|DDC::HitList> objects.

=item L<DDC::Query|DDC::Query>

Class for parsed DDC queries; may be out-of-sync with ddc C++ implementation.
B<DEPRECATED> in favor of the L<DDC::XS::CQuery|DDC::XS::CQuery> hierarchy
from the L<DDC::XS|DDC::XS> distribution.

=item L<DDC::Query::Filter|DDC::Query::Filter>

Class for parsed DDC filters and flags; may be out-of-sync with ddc C++ implementation.
B<DEPRECATED> in favor of L<DDC::XS::Object::mapTraverse()|DDC::XS::Object>
from the L<DDC::XS|DDC::XS> distribution.


=item L<DDC::Query::Parser|DDC::Query::Parser>

Class for parsing DDC queries; may be out-of-sync with ddc C++ implementation.
B<DEPRECATED> in favor of L<DDC::XS::CQueryCompiler|DDC::XS::CQueryCompiler>
from the L<DDC::XS|DDC::XS> distribution.

=item L<DDC::Utils|DDC::Utils>

Various utilities for string-escaping, etc.

=back

=cut

##======================================================================
## SCRIPTS
=pod

=head1 SCRIPTS

The following executable scripts are distributed with the DDC package:

=over 4

=item ddc-query.perl

Simple script for querying a distributed DDC server using the
L<DDC::Client::Distributed|DDC::Client::Distributed> and
L<DDC::Format|DDC::Format> modules.

=item ddc-expand-lts-query.perl

Simple string-manipulation
script for translating a query which may contain a phonetic identity
operator of the form:

 $p~TEXT

(where TEXT is some literal orthographic text) into a valid DDC query string
for a server which indexes a '$p' field with phonetic forms as returned by
a finite-state transducer (in Gfsm format) which must be specified to the
script.

Requires Lingua::LTS and Gfsm.

=item ddc-lts-wrapper.perl

DDC wrapper daemon which transparently
translates phonetic identity queries as for ddc-expand-lts-query.perl.

Requires Lingua::LTS and Gfsm.

=back

=cut


##======================================================================
## Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2016, Bryan Jurish.  All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1)

=cut
