package Catalyst::Plugin::CGI::Untaint;

use 5.008001;
use strict;
use warnings;
use NEXT;
use CGI::Untaint;

our $VERSION = '0.05';

sub prepare {
    my $class = shift;
    my $c = $class->NEXT::prepare( @_ );

    # $c->log->debug("Creating CGI::Untaint instance");
    my $untaint = CGI::Untaint->new( $c->req->parameters );
    $c->config->{__PACKAGE__}->{handler} = $untaint;
    $c->config->{__PACKAGE__}->{errors} = {};

    return $c;
}

sub untaint {
    my ($c, @params) = @_;

    if ($params[0] eq '-last_error') {
        return $c->config->{__PACKAGE__}{error}{$params[1]};
    }

    my $value = $c->config->{__PACKAGE__}{handler}->extract(@params);

    $c->config->{__PACKAGE__}{errors}{$params[1]} =
        $c->config->{__PACKAGE__}{handler}->error;

    return $value;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::CGI::Untaint - Plugin for Catalyst

=head1 SYNOPSIS

  # In your MainApp.pm:
  use Catalyst qw/CGI::Untaint/;
  
  # Put into your form handler:
  my $email = $c->untaint(-as_email => 'email');
  # Will extract only a valid email address from $c->req->params->{email}

  # Use -last_error to get the rejection reason:
  if (not $email) {
      $error = $c->untaint(-last_error => 'email');
  }

  # (note, you will need to have CGI::Untaint and CGI::Untaint::email installed
  # in order for the above example to work)

=head1 DESCRIPTION

This module wraps CGI::Untaint up into a Catalyst plugin.

For info on using CGI::Untaint, see its own documentation.

=head1 SEE ALSO

L<Catalyst>

L<CGI::Untaint>

=head1 AUTHOR

Toby Corkindale, E<lt>cpan@corkindale.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Toby Corkindale

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
