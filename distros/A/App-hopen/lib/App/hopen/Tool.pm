# App::hopen::Tool - base class for a hopen tool.  DEPRECATED.
package App::hopen::Tool;
#use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'App::hopen::G::Cmd';
#use Class::Tiny;

# Docs {{{1

=head1 NAME

Data::Hopen::Tool - Base class for packages that know how to process files

=head1 SYNOPSIS

A tool knows how to generate a command or other text that will cause
a build system to perform a particular action on a file belonging to a
particular language.

A tool is an L<App::hopen::G::Cmd>, so may interact with the current generator
(L<App::hopen::BuildSystemGlobals/$Generator>).  Moreover, the generator will
get a chance to visit the op after it is processed.

Maybe TODO:
    - Each Generator must specify a list of Content-Types (media types)
        it can consume.  Each Tool must specify a specific content-type
        it produces.  Mismatches are an error unless overriden on the
        hopen command line.

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
