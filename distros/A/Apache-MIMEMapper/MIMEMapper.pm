package Apache::MIMEMapper;

use Apache::Constants qw(OK DECLINED DECLINE_CMD);
use Apache::ModuleConfig ();

use 5.006;
use DynaLoader ();
use MIME::Types qw(by_suffix);

use strict;

our $VERSION = '0.10';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap($VERSION);

sub handler {

  my $r = shift;

  # Decline if the request is a proxy request.
  return DECLINED if $r->proxyreq;

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  # Also decline if a SetHandler directive is present,
  # which ought to override any AddHandler settings.
  return DECLINED if $cfg->{_set_handler};

  my ($extension) = $r->filename =~ m!(\.[^.]+)$!;

  # Set the PerlHandler stack if we have a mapping for this file extension.
  if (my $handlers = $cfg->{$extension}) {
    $r->handler('perl-script');
    $r->set_handlers(PerlHandler => $handlers);

    # Notify Apache::Filter if we have more than one PerlHandler...
    $r->dir_config->set(Filter => 'On') if @$handlers > 1;

    # ... and take a guess at the MIME type.
    my ($content_type) = by_suffix($extension);
    $r->content_type($content_type) if $content_type;

    return OK;
  }

  # Otherwise, let mod_mime handle things.
  return DECLINED;
}

sub AddHandler ($$@;@) {

  my ($cfg, $parms, $handler, $type) = @_;

  # Intercept the directive if the handler looks like a PerlHandler.
  # This is not an ideal check, but sufficient for the moment.
  if ($handler =~ m/::/) {
    push @{$cfg->{$type}}, $handler;
    return OK;
  }

  # Otherwise let mod_mime handle it.
  return DECLINE_CMD;
}

sub SetHandler ($$$) {

  my ($cfg, $parms, $handler) = @_;

  $cfg->{_set_handler} = 1;

  # We're just marking areas governed by SetHandler.
  return DECLINE_CMD;
}

sub DIR_CREATE {
  return bless {}, shift;
}

sub DIR_MERGE {
  my ($parent, $current) = @_;

  my %new = (%$parent, %$current);

  return bless \%new, ref($parent);
}
1;

__END__
=head1 NAME

Apache::MIMEMapper - associate file extensions with PerlHandlers

=head1 SYNOPSIS

PerlModule Apache::MIMEMapper
PerlTypeHandler Apache::MIMEMapper

AddHandler Apache::RegistryFilter .pl
AddHandler Apache::SSI .html .pl

Alias /perl-bin/ /usr/local/apache/perl-bin/
<Location /perl-bin/>
  SetHandler perl-script
  PerlHandler Apache::Registry
  Options +ExecCGI
  PerlSendHeader On
</Location>

=head1 DESCRIPTION

Apache::MIMEMapper extends the core AddHandler directive to allow you
to dispatch different PerlHandlers based on the file extension of the
requested resource.  This means that you can now have .pl
scripts under htdocs/ (or wherever) without resorting to a
<Files> based configuration.  

Apache::MIMEMapper also adds the ability to stack PerlHandlers
transparently using Apache::Filter.  Handlers are added to the
PerlHandler stack in the order they appear in the httpd.conf file -
PerlSetVar Filter On is set if more than one extension is associated
with a specific Perl module.

=head1 EXAMPLE

PerlModule Apache::MIMEMapper
PerlTypeHandler Apache::MIMEMapper

AddHandler Apache::RegistryFilter .pl
AddHandler Apache::SSI .html .pl

Alias /perl-bin/ /usr/local/apache/perl-bin/
<Location /perl-bin/>
  SetHandler perl-script
  PerlHandler Apache::Registry
  Options +ExecCGI
  PerlSendHeader On
</Location>

In this example, .html files are scheduled for processing with
Apache::SSI.  Additionally, .pl files outside of /perl-bin are
handled by Apache::RegistryFilter and Apache::SSI (in that order).

Because the SetHandler directive supercedes all other mod_mime
directives, all files inside of /perl-bin are processed using 
Apache::Registry.

=head1 NOTES

The current logic checks AddHandler for something that looks like
a Perl module, so

AddHandler server-parsed .shtml

still works.  The criterion for deciding if Apache::MIMEMapper
intercepts the request is whether the handler is in the form
Foo::Bar - it checks for '::'.  This is not ideal, but simple
and sufficient for most cases.

=head1 FEATURES/BUGS

Apache::MIMEMapper is a PerlTypeHandler.  It does just about
everything that mod_mime does (via MIME::Types).  The only
place where it interferes is for content-negotiated requests,
where the AddLanguage and associated directives are 
necessary.  Should you need these directives, you can install
Apache::MIMEMapper as a PerlFixupHandler instead.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3)

=head1 AUTHORS

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

Paul Lindner E<lt>paul@modperlcookbook.orgE<gt>

Randy Kobes E<lt>randy@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2001, Geoffrey Young, Paul Lindner, Randy Kobes.  

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::MIMEMapper> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
