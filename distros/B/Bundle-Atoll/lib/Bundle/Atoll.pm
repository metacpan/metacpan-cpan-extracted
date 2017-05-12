package Bundle::Atoll;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.03';

1;
__END__

=head1 NAME

Bundle::Atoll - Perl extension for ALPAGE Linguistic Processing Chain

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::ATOLL'>

=head1 DESCRIPTION

This bundle regroups all Perl modules needed to install and run 
ALPAGE Linguistic Processing chain.

=head2 EXPORT

None by default.

=head1 CONTENTS

AppConfig          - Reading configuration files and parsing command line arguments 

CGI                - Simple Common Gateway Interface Class 

DBI                - Database independent interface for Perl 

Data::Compare      - Compare perl data structures 

Data::Dumper       - Convert data structure into perl code 

Data::Grove        - Support for deeply nested structures 

Event              - Fast, generic event loop 

File::Temp         - Create temporary files safely 

IO::All

IO::Socket         - Methods for socket input/output handles 

IPC::Open2         - Open a process for both reading and writing 

IPC::Open3         - Like IPC::Open2 but with error handling 

IPC::Run           - Child procs w/ piping, redir and psuedo-ttys 

List::Compare      - Compare elements of two or more lists 

Net::Server        - Extensible (class) oriented internet server 

Net::Telnet        - Interact with TELNET port or other TCP ports 

Parse::RecDescent  - Recursive descent parser generator 

Parse::Yapp        - Generates OO LALR parser modules 

Term::Report       - Easy way to create dynamic 'reports' from within scripts 

Tie::IxHash        - Indexed hash (ordered array/hash composite) 

Time::HiRes        - High resolution time, sleep, and alarm 

XML::Generator     - Generates XML documents 

XML::LibXML        - Interface to the libxml library 

XML::Parser        - Flexible fast parser with plug-in styles 

=head1 SEE ALSO

Check web page of ALPAGE Linguistic Processing Chain for information: 
L<http://alpage.inria.fr/installatoll.en.html>

=head1 AUTHOR

Isabelle Cabrera, E<lt>Isabelle.Cabrera@inria.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2008 INRIA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
