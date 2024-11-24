# App::hopen::T::MSCL - Microsoft cl.exe toolset
package App::hopen::T::MSCL;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

=head1 NAME

App::hopen::T::MSCL - Microsoft cl.exe toolset for hopen

=head1 SYNOPSIS

This toolset supports any compiler and linker that will accept C<cl.exe>
options.  It provides command lines, so is useful with generators that
use command lines directly (e.g., L<App::hopen::Gen::Make>).

TODO add a separate msbuild toolset, and link to it here.

=cut

1;
__END__
# vi: set fdm=marker: #
