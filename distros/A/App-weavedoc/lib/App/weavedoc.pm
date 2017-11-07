package App::weavedoc;
our $VERSION = '0.003';
# ABSTRACT: Show documentation for a module using Pod::Weaver

#pod =head1 SYNOPSIS
#pod
#pod     weavedoc [--license <license>] [--version <version>] [--author <author>] <file>
#pod     weavedoc -h|--help
#pod
#pod =head1 DESCRIPTION
#pod
#pod This distribution contains a command line utility to take a file
#pod with L<Pod::Weaver> directives and render it to the terminal like
#pod L<the perldoc utility|perldoc> does.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Pod::Weaver>, L<App::podweaver>, L<perldoc>
#pod
#pod =cut

use strict;
use warnings;



1;

__END__

=pod

=head1 NAME

App::weavedoc - Show documentation for a module using Pod::Weaver

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    weavedoc [--license <license>] [--version <version>] [--author <author>] <file>
    weavedoc -h|--help

=head1 DESCRIPTION

This distribution contains a command line utility to take a file
with L<Pod::Weaver> directives and render it to the terminal like
L<the perldoc utility|perldoc> does.

=head1 SEE ALSO

L<Pod::Weaver>, L<App::podweaver>, L<perldoc>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
