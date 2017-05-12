package App::SimpleScan::Plugin::TestExpand;

our $VERSION = '0.01';

use warnings;
use strict;
use Carp;
use File::Path;

my($test_expand);

sub import {
  no strict 'refs';
  *{caller() . '::test_expand'}  = \&test_expand;
}

sub filters {
  return \&filter;
}

sub init {
  my ($class, $app) = @_;
  no strict 'refs';
  *{caller() . '::expander'} = \&test_expand;
  $app->{Expander} = "ping!";
}

sub test_expand {
  my($self, $value) = @_;
  $test_expand = $value if defined $value;
  $test_expand;
}

sub options {
  return ('test_expand' => \$test_expand,
         );
}

sub validate_options {
  my($class, $app) = @_;
  if (defined ($app->test_expand)) {
    $app->pragma('test_expand')->($app);
  } 
}

sub pragmas {
  return (['test_expand' => \&test_expand_pragma],
         );
}

sub test_expand_pragma {
  my ($self, $args) = @_;
  $self->stack_code(qq(# Adding test expansion comment\n));
}

sub filter {
  my($app, @code) = @_;
  return @code unless $app->test_expand;
  push @code, qq(# per-test comment\n);
  return @code;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::TestExpand - Dummy plugin to test per-test expansion

=head1 VERSION

This document describes App::SimpleScan::Plugin::TestExpand version 0.01


=head1 SYNOPSIS

    use App::SimpleScan;
    my $app = new App::SimpleScan;
    $app->go; # plugin loaded automatically here

  
=head1 DESCRIPTION

Supports the C<%%test_expand> pragma plus the C<--test_expand> option.

=head1 INTERFACE 

=head2 pragmas

Installs the pragmas into C<App::SimpleScan>.

=head2 options

Installs the command line options into C<App::SimpleScan>.

=head2 test_expand

Accessor allowing pragmas and command line options to share the
variable containing the current value for this combined option.

=head2 test_expand_pragma

Actually implements the C<%%test_expand> pragma, stacking a 
comment indicating that test expansion is happening.

=head2 validate_options

Standard C<App::SimpleScan> callback: validates the command-line
arguments, calling the appropriate pragma methods as necessary.

=head2 per_test

Actually implements the test. If test_expand has been turned on
(either via pragma or command-line), emits a comment following 
every test.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::TextExpand requires no configuration files or environment variables.


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

Copyright (c) 2005,2006 Joe McMahon C<< <mcmahon@yahoo-inc.com > >> and Yahoo!. All rights reserved.

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
