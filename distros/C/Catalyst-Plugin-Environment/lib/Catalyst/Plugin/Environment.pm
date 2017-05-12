package Catalyst::Plugin::Environment;

use namespace::autoclean;
use Moose::Role;

our $VERSION = '0.02';


after setup_finalize => sub {
  my $class = shift;

  my $config = $class->config->{'Plugin::Environment'} || { };
  $ENV{$_} = $config->{$_}
    for keys %$config;
};


1
__END__

=pod

=head1 NAME

Catalyst::Plugin::Environment - Catalyst plugin to modify C<%ENV> via your application configuration

=head1 SYNOPSIS

  # in MyApp.pm

  use Catalyst qw( ... Environment ... );

  __PACKAGE__->config->{'Plugin::Environment'} = {
    Foo => 'Bar',
    Baz => 'Qux',
  };

=head1 DESCRIPTION

Catalyst::Plugin::Environment allows you to specify environment variable
values that should be set during application startup.  This is useful if
you rely on modules that use environment variables but don't want these
to be managed outside of your application.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2012-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
