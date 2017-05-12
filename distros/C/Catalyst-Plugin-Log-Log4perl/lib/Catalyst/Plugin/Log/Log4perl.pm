package Catalyst::Plugin::Log::Log4perl;

use namespace::autoclean;
use Log::Log4perl;
use Moose;

our $VERSION = '0.02';


sub setup {
  my $c = shift;

  my $config = $c->config->{'Plugin::Log::Log4perl'};
  if( exists $config->{conf} ) {
    if( defined $config->{watch_delay} ) {
      Log::Log4perl->init_and_watch( $config->{conf}, $config->{watch_delay} );
    }
    else {
      Log::Log4perl->init( $config->{conf} );
    }
  }
  else {
    $c->log->warn( 'No Log::Log4perl configuration found' );
  }

  $c->next::method( @_ )
}


1
__END__

=pod

=head1 NAME

Catalyst::Plugin::Log::Log4perl - Catalyst plugin to initialize Log::Log4perl from the application's configuration

=head1 SYNOPSIS

  # in MyApp.pm

  use Catalyst qw( ConfigLoader Log::Log4perl );
  use Log::Log4perl::Catalyst;

  ...

  __PACKAGE__->log( Log::Log4perl::Catalyst->new );

  __PACKAGE__->setup;


  # in myapp.yaml

  name: MyApp
  Plugin::Log::Log4perl:
    conf: '__HOME__/log4perl.conf'
    watch_delay: 60 # optional

=head1 DESCRIPTION

This module allows you to initialize L<Log::Log4perl|Log::Log4perl>
within the application's configuration.  This is especially useful
when using L<Catalyst::Plugin::ConfigLoader|Catalyst::Plugin::ConfigLoader>
to load configuration files.  It is meant to be used in conjunction
with L<Log::Log4perl::Catalyst|Log::Log4perl::Catalyst>, but can
also be used stand-alone.

=head1 CONFIGURATION

=head2 conf

This will be passed directly to C<Log::Log4perl-E<gt>init()>, so it can
be anything that that method can support.  This includes the name
of a configuration file or a C<HASH> reference.  See the
L<Log::Log4perl|Log::Log4perl> documentation for more information.

=head2 watch_delay

If this is present, C<Log::Log4perl-E<gt>init_and_watch()> is used
for L<Log::Log4perl|Log::Log4perl> initialization with the given delay.

=head1 BUGS

If L<Log::Log4perl::Catalyst|Log::Log4perl::Catalyst> is used,
this module will re-initialize L<Log::Log4perl|Log::Log4perl>
which is not recommended.  This is unavoidable, though, since your
application's logger is configured prior to running C<MyApp-E<gt>setup()>.

=head1 AUTHOR

jason hord <pravus@cpan.org>

=head1 SEE ALSO

=over 2

=item L<Log::Log4perl|Log::Log4perl>

=item L<Log::Log4perl::Catalyst|Log::Log4perl::Catalyst>

=back

=head1 COPYRIGHT

Copyright (c) 2010-2014, jason hord

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
