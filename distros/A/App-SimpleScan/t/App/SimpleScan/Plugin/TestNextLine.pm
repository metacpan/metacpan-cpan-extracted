package App::SimpleScan::Plugin::TestNextLine;

our $VERSION = '0.01';

use warnings;
use strict;
use Carp;
use File::Path;

my($test_nextline);

sub import {
  no strict 'refs';
  *{caller() . '::test_nextline'}  = \&test_nextline;
}

sub init {
  my ($class, $app) = @_;
  no strict 'refs';
  my $callbacks_ref = $app->next_line_callbacks();
  push @{ $callbacks_ref }, \&demo_callback;
  $app->next_line_callbacks($callbacks_ref);
  $app->{demo_called} = 0;
}

sub test_nextline {
  my ($self, $value) = @_;
  $test_nextline = $value if defined $value;
  $test_nextline;
}

sub options {
  return ('test_nextline' => \$test_nextline);
}

sub demo_callback {
  my($app) = @_;
  return unless $app->test_nextline();

  my $n = $app->{demo_called} += 1;
  my $s = ($n == 1) ? '' : 's';
  $app->stack_code( qq(# next line plugin called $n time$s\n) );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::TestNextLine - Dummy plugin to test next_line callbacks

=head1 SYNOPSIS

    use App::SimpleScan;
    my $app = new App::SimpleScan;
    $app->go; # plugin loaded automatically here

  
=head1 DESCRIPTION

Adds a simple next_line() callback that just increments an instance variable.

=head1 INTERFACE 

=head2 init

Installs the callback.

=head2 demo_callback

Bumps the "demo_called" slot in the object.

None.

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::TestNextLine requires no configuration files or environment variables.


=head1 DEPENDENCIES

App::SimpleScan, App::SimpleScan::TestSpec.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@cpan.org > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Joe McMahon C<< <mcmahon@yahoo-inc.com > >> and Yahoo!. All rights reserved.

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
