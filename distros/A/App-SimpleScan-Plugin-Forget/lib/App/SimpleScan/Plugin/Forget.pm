package App::SimpleScan::Plugin::Forget;

our $VERSION = '1.02';

use warnings;
use strict;
use Carp;

sub pragmas {
  no strict 'refs';
  *{ caller() . '::_forget' } = \&_do_forget;
  return [ 'forget', \&_do_forget ];
}

sub _do_forget {
  my ( $self, $rest ) = @_;
  my @names = split( /\s+/, $rest );
  local $_;
  $self->_delete_substitution($_) for @names;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::Forget - forget a variable's value


=head1 VERSION

This document describes App::SimpleScan::Plugin::Forget version 1.00


=head1 SYNOPSIS

   # In a simple_scan input file, after installing this module:

   # Define the variable foo:
   %%var foo baz bar quux

   # Later in the file:
   %%forget foo

   # 'foo' is now undefined, and '<foo>' will not be replaced 

=head1 DESCRIPTION

C<App::SimpleScan::Plugin::Forget> looks through the currently-defined
variables and removes any variables specified as its arguments. If you
try to forget variables that are currently undefined, nothing happens.

=head1 INTERFACE 

=head2 pragmas

Defines the C<%%forget> pragma in C<App::SimpleScan>.

=head2 do_forget

Actually removes the variable from the current definitions.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::Forget requires no configuration files or environment variables.

=head1 DEPENDENCIES

App::SimpleScan.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan-plugin-forget@rt.cpan.org>, or through the 
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, 2006 Yahoo! and Joe McMahon 
C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
