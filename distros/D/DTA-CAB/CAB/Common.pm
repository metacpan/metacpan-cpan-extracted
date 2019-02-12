## -*- Mode: CPerl -*-
## File: DTA::CAB::Common.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: robust morphological analysis: common dependencies

package DTA::CAB::Common;

use DTA::CAB::Version;

use DTA::CAB::Logger;
use DTA::CAB::Persistent;

use DTA::CAB::Datum; #':all';
use DTA::CAB::Token;
use DTA::CAB::Sentence;
use DTA::CAB::Document;

use DTA::CAB::Format;
use DTA::CAB::Format::Builtin;

use strict;

1; ##-- be happy

__END__

##==============================================================================
## PODS
##==============================================================================
=pod

=head1 NAME

DTA::CAB::Common - common dependencies for DTA::CAB suite

=head1 SYNOPSIS

 use DTA::CAB::Common;

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

The DTA::CAB::Common package just includes some common low-level
dependencies for the rest of the DTA::CAB suite, namely:

=over 4

=item L<DTA::CAB::Version|DTA::CAB::Version>

Version information.

=item L<DTA::CAB::Logger|DTA::CAB::Logger>

Abstract base class and utilities for flexible logging via L<Log::Log4perl|Log::Log4perl>.

=item L<DTA::CAB::Persistent|DTA::CAB::Persistent>

Abstract base class for persistent configurable DTA::CAB objects
such as L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> or
L<DTA::CAB::Server|DTA::CAB::Server> objects.

=item L<DTA::CAB::Format|DTA::CAB::Format>

Abstract base class for DTA::CAB data I/O formats.
See L<DTA::CAB::Format::Builtin|DTA::CAB::Format::Builtin>
for a list of built-in formats.

=item L<DTA::CAB::Datum|DTA::CAB::Datum>

Abstract base class for DTA::CAB runtime data objects.
Includes subclasses:

=over 4

=item L<DTA::CAB::Token|DTA::CAB::Token>

=item L<DTA::CAB::Sentence|DTA::CAB::Sentence>

=item L<DTA::CAB::Document|DTA::CAB::Document>

=back

=back

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
