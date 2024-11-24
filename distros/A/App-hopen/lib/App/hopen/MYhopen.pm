# App::hopen::MYhopen - module used by MY.hopen.pl files to perform
# compile-time processing (e.g., setting the phase)
package App::hopen::MYhopen;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

# Docs {{{1

=head1 NAME

App::hopen::MYhopen - compile-time processing by MY.hopen.pl files

=head1 SYNOPSIS

This module is used by MY.hopen.pl files to perform compile-time processing,
such as setting the phase.

=cut

# }}}1

=head1 VARIABLES

=head2 $App::hopen::MYhopen::IsMYH

Must be set truthy before this module's import() function is called, or
import() will croak.  A very rudimentary access control.

=cut

our $IsMYH;

=head1 FUNCTIONS

=head2 import

Set things up!

=cut

sub import {    # {{{1
    my $target = caller;
    croak "Cannot load App::hopen::MYhopen from a file that is not a " .
            "MY.hopen.pl file" unless $App::hopen::MYhopen::IsMYH;
} #import()     # }}}1

1;
__END__
# vi: set fdm=marker: #
