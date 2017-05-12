# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package ClearPress::view::error;
use strict;
use warnings;
use base qw(ClearPress::view Class::Accessor);
use English qw(-no_match_vars);
use Template;
use Carp;
use Readonly;

__PACKAGE__->mk_accessors(qw(errstr));

our $VERSION = q[475.3.3];
Readonly::Scalar our $CODEMAP => {
                300 => q[Multiple Choices],
                301 => q[Moved Permanently],
                302 => q[Found],
                303 => q[See Other],
                304 => q[Not Modified],
                306 => q[Switch Proxy],
                307 => q[Temporary Redirect],
                308 => q[Resume Incomplete],
                400 => q[Bad Request],
                401 => q[Unauthorised],
                402 => q[Payment Required],
                403 => q[Forbidden],
                404 => q[Not Found],
                405 => q[Method Not Allowed],
                406 => q[Not Acceptable],
                407 => q[Proxy Authentication Required],
                408 => q[Request Timeout],
                409 => q[Conflict],
                410 => q[Gone],
                411 => q[Length Required],
                412 => q[Precondition Failed],
                413 => q[Request Entity Too Large],
                414 => q[Request-URI Too Long],
                415 => q[Unsupported Media Type],
                416 => q[Requested Range Not Satisfiable],
                417 => q[Expectation Failed],
                500 => q[Internal Server Error],
                501 => q[Not Implemented],
                502 => q[Bad Gateway],
                503 => q[Service Unavailable],
                504 => q[Gateway Timeout],
                505 => q[HTTP Version Not Supported],
                511 => q[Network Authentication Required],
               };

sub safe_errors {
  return 1;
}

sub init {
  my $self = shift;
  my $util = $self->util;
  my $cgi  = $util->cgi;

  $self->{errstr} = $cgi->unescape($cgi->param('errstr') || q[]) || q[];

  return $self->SUPER::init();
}

sub render {
  my $self   = shift;
  my $util   = $self->util;
  my $cgi    = $util->cgi;
  my $aspect = $self->aspect() || q[];
  my $errstr = $self->errstr;
  my $pi     = $ENV{PATH_INFO} || q[];
  my ($code) = $pi =~ m{(\d+)}smix; # Requires Apache ErrorDocument /<application>/<errorcode>. mod_perl can use $ENV{REDIRECT_STATUS} but doesn't work under cgi

  $errstr ||= $CODEMAP->{$code||q[]};
  $errstr ||= q[];

  if(Template->error()) {
    $errstr .= q(Template Error: ) . Template->error();
  }

  if($self->safe_errors) {
    print {*STDERR} "Serving error: $errstr\n" or croak $ERRNO;
    $errstr =~ s/[ ]at[ ]\S+[ ]line[ ][[:digit:]]+//smxg;
    $errstr =~ s/\s+[.]?$//smx;
  }

  #########
  # initialise tt_filters by resetting tt
  #
  delete $util->{tt};
  my $tt      = $self->tt;
  my $content = q[];
  my $decor   = $self->decorator;

#  carp qq[$self view::error: handling error response];
  if($aspect =~ /(?:ajax|xml|rss|atom)$/smx) {
    my $escaped = $self->tt_filters->{xml_entity}->($errstr);
    $content = qq[<?xml version='1.0'?>\n<error>Error: $escaped</error>];

  } elsif($aspect =~ /json$/smx) {
    my $escaped = $self->tt_filters->{js_string}->($errstr);
    $content = qq[{"error":"Error: $escaped"}];

  } else {
    my $escaped = $self->tt_filters->{xml_entity}->($errstr);
    my $message = $CODEMAP->{$code||q[]} || q[An Error Occurred];
    $content = sprintf <<'EOT', $message, $self->actions(), $escaped;
<div id="main">
  <h2 class="error">%s</h2>
  %s
  <p class="error">Error: %s</p>
</div>
EOT
  }

  #########
  # render should return content for non-streamed responses
  #
  return $content;
}

1;

__END__

=head1 NAME

ClearPress::view::error - specialised view for error handling

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 errstr - Get/set accessor for an error string to display

  $oErrorView->errstr($sErrorMessage);
  my $sErrorMessage = $oErrorView->errstr();

=head2 render - encapsulated HTML rather than a template, in case the template has caused the error

  my $sErrorOutput = $oErrorView->render();

=head2 safe_errors - boolean flag, default on - strip strings which look like filenames and line numbers

=head2 init - unstash errstr

=head2 errstr - errstr accessor

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::view

=item Class::Accessor

=item English

=item Template

=item Carp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
