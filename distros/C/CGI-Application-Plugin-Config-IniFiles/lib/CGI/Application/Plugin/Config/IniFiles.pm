#! perl
# $Id:$

package CGI::Application::Plugin::Config::IniFiles;

use 5.008;
use strict;
use warnings;

use CGI::Application;
use Config::IniFiles;

use base "Exporter";

our @EXPORT = qw( config_file config cfg );
our $VERSION = (qw$Revision: $)[1];

sub config_file {
  my($self,$file,%opt) = @_;
  if ( ref($file) eq 'Config::IniFiles' ) {
	# it's not a file after all, it's a Config::IniFiles object
    # useful for persistent environments like FastCGI
    $self->{'__CONFIG_INIFILES'}->{'__CONFIG'} = $file;
  } else {
    $self->{'__CONFIG_INIFILES'}->{'__FILE_NAME'} = $file;
    $self->{'__CONFIG_INIFILES'}->{'__CONFIG'} = Config::IniFiles->new('-file' => $file,%opt);
  }
  return $file;
}

sub config {
  return $_[0]->{'__CONFIG_INIFILES'}->{'__CONFIG'};
}

sub cfg {
  return $_[0]->{'__CONFIG_INIFILES'}->{'__CONFIG'};
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Config::IniFiles - Add Config::IniFiles support to CGI::Application.

=head1 SYNOPSIS

  use CGI::Application::Plugin::Config::IniFiles;
  sub cgiapp_init {
    my($self) = @_;
    $self->config_file("app.conf");
    my $opt = $self->config->val("main","option");
    ...
  }

  sub run_mode {
    my($self) = @_;
    my $opt = $self->config->val("main","option");
    ...
  }

=head1 DESCRIPTION

This module works as plugin for L<Config::IniFiles> to be easily used
inside L<CGI::Application> module.

Module provides tree calls: C<config_file()>, C<config()> and C<cfg()>.

=head1 METHODS

=over 4

=item C<config_file($file[,%options])>

This method reads file I<$file> and create L<Config::IniFiles> object.
Optional arguments has same semantics as in L<Config::IniFiles/new>.
You can also pass a L<Config::IniFiles> object instead of a filename
which is useful for persistent environments like FastCGI.

=item C<config()>

Returns underlying L<Config::IniFiles> object for direct access to its
methods.

=item C<config()>

Same as C<config()> for more convenient.

=back

=head1 SEE ALSO

See L<CGI::Application>, L<Config::IniFiles>.

=head1 AUTHOR

Artur Penttinen, E<lt>artur+perl@niif.spb.suE<gt>, Sven Neuhaus
E<lt>sven-bitcard@sven.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Artur Penttinen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

### That's all, folks!
# $Log:$
#
