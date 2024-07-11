package Alien::poetry;
 
use strict;
use warnings;
use parent qw( Alien::Base );

use Path::Tiny;
use File::ShareDir::Dist qw( dist_share );

# for now, pull poetry from python-poetry.org
# would bump to v2 and include poetry --version in this if we switch to bundle
our $VERSION = '1.000002';

sub bin_dir { path( dist_share __PACKAGE__ )->child('venv')->child('bin') }
sub poetry { path( (shift)->bin_dir )->child('poetry') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::poetry - Alien package for Python poetry

=cut

=head1 SYNOPSIS

 use Alien::poetry;
 
 # the poetry application
 say Alien::poetry->poetry;

=head1 DESCRIPTION

L<Alien::poetry> downloads and installs poetry.

=head1 METHODS

=head2 poetry

 my $poetry = Alien::poetry->poetry;

Returns the absolute location of the poetry application.

=head2 bin_dir

 my $bin_dir = Alien::poetry->bin_dir;

Returns the location of poetry and other apps (local python, venv, etc).

=head1 AUTHOR

Oliver Gorwits, C<< <oliver at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Oliver Gorwits.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Netdisco Project nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE NETDISCO DEVELOPER TEAM BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
