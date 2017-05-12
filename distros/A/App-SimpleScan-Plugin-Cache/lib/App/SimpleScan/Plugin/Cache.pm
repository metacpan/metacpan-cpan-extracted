package App::SimpleScan::Plugin::Cache;

our $VERSION = '0.02';

use warnings;
use strict;
use Carp;

sub pragmas {
  no strict 'refs';
  *{caller() . '::_cache'} = \&_do_cache;
  *{caller() . '::_nocache'} = \&_do_nocache;
  return ['cache', \&_do_cache],
         ['nocache', \&_do_nocache];
}

sub _do_nocache {
  my ($self, $rest) = @_;
  $self->stack_code("mech()->nocache();\n");
}
    
sub _do_cache {
  my ($self, $rest) = @_;
  $self->stack_code("mech()->cache();\n");
}


1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::Cache - Adds %%cache/%%nocache pragmas to simple_scan


=head1 VERSION

This document describes App::SimpleScan::Plugin::Cache version 0.01


=head1 SYNOPSIS

    use App::SimpleScan;
    # Automatically loads 

=head1 DESCRIPTION

Adds a C<%%cache> and C<%%nocache> pragma to C<simple_scan>.

=head1 INTERFACE 

=head2 pragmas

C<pragmas> installs the subs in the caller to support the pragmas
and returns a list of installed subs and pragmas to associate them with.

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::Cache requires no configuration files or environment variables.

=head1 DEPENDENCIES

App::SimpleScan, Module::Pluggable, WWW::Mechanize::Pluggable, 
WWW::Mechanize::Plugin::Cache.


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan-plugin-yahoologin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Joe McMahon C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

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
