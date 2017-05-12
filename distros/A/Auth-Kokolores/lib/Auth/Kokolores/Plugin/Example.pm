package Auth::Kokolores::Plugin::Example;

use Moose;

# ABSTRACT: example for a kokolores plugin
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';


sub init {
  my ( $self ) = @_;
  # code to be executed by main process
  # load modules and initialize global parameters here
  return;
}

sub child_init {
  my ( $self ) = @_;
  # code to ve executed in the child process after forking
  # setup connections etc. here
  return;
}

sub authenticate {
  my ( $self, $r ) = @_;
  # parameters are passed within $r (Auth::Kokolores::Request)
  # just return a true value on success
  # or a false value on failure
 
  if( $r->password eq 'secret' ) {
    return 1;
  }

  return 0;
}

sub shutdown {
  my ( $self ) = @_;
  # code to be executed before the child is shutdown
  # close connections, files, etc.
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::Example - example for a kokolores plugin

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This plugin checks if the supplied password is "secret".

If you want to start a kokolores plugin. You can use this
plugin as a start.

=head1 USAGE

  <Plugin myauth>
    module="Example"
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
