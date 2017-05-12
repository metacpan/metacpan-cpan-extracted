package AnnoCPAN;

$VERSION = '0.22';

=head1 NAME

AnnoCPAN - Annotated CPAN documentation

=head1 SYNOPSIS

    AnnoCPAN is a web interface for the documentation of all the modules on
    CPAN, where users can add annotations on the margin of specific paragraphs
    throughout the POD.

=head1 DESCRIPTION

This file (AnnoCPAN.pm) is not a real module; it is just the starting point
for the AnnoCPAN documentation. For more details, see the modules listed below.

This distribution has the code that runs on L<http://annocpan.org/>. It is
provided for educational purposes, or in case someone wants to run a local
annocpan server or hack the code to submit patches. In the latter case,
however, it is better to fetch the latest code via anonymous CVS.

    cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/annocpan login
 
    cvs -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/annocpan co -P annocpan2

=head1 SEE ALSO

L<AnnoCPAN::Archive>,
L<AnnoCPAN::Config>,
L<AnnoCPAN::Control>, 
L<AnnoCPAN::DBI>, 
L<AnnoCPAN::Dist>, 
L<AnnoCPAN::PodParser>, 
L<AnnoCPAN::PodToHtml>, 
L<AnnoCPAN::Undump>, 
L<AnnoCPAN::Update>, 
L<AnnoCPAN::XMLCGI>.

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;
