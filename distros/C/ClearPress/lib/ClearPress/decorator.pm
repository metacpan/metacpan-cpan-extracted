# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:  rmp
# Created: 2007-06-07
#
package ClearPress::decorator;
use strict;
use warnings;
use CGI qw(param);
use base qw(Class::Accessor);
use Readonly;
use Carp;

our $VERSION = q[477.1.4];

our $DEFAULTS = {
		 meta_content_type => 'text/html',
		 meta_version      => '0.2',
		 meta_description  => q[],
		 meta_author       => q[],
		 meta_keywords     => q[],
		 username          => q[],
		 charset           => q[iso8859-1],
                 lang              => [qw(en)],
		};

Readonly::Scalar our $PROCESS_COMMA_YES => 1;
Readonly::Scalar our $PROCESS_COMMA_NO  => 2;
our $ARRAY_FIELDS = {
		     'jsfile'     => $PROCESS_COMMA_YES,
		     'rss'        => $PROCESS_COMMA_YES,
		     'atom'       => $PROCESS_COMMA_YES,
		     'stylesheet' => $PROCESS_COMMA_YES,
		     'script'     => $PROCESS_COMMA_NO,
		     'lang'       => $PROCESS_COMMA_YES,
		    };
__PACKAGE__->mk_accessors(__PACKAGE__->fields());

sub fields {
  return qw(title stylesheet style jsfile script atom rss
            meta_keywords meta_description meta_author meta_version
            meta_refresh meta_cookie meta_content_type meta_expires
            onload onunload onresize username charset headers
            lang);
}

sub get {
  my ($self, $field) = @_;

  if($ARRAY_FIELDS->{$field}) {
    my $val = $self->{$field} || $DEFAULTS->{$field} || [];
    if(!ref $val) {
      $val = [$val];
    }

    if($ARRAY_FIELDS->{$field} == $PROCESS_COMMA_YES) {
      return [map { split /,/smx } @{$val}];

    } else {
      return $val;
    }


  } else {
    return $self->{$field} || $DEFAULTS->{$field};
  }
}

sub defaults {
  my ($self, $key) = @_;
  return $DEFAULTS->{$key};
}

sub new {
  my ($class, $ref) = @_;
  if(!$ref) {
    $ref = {};
  }
  bless $ref, $class;
  return $ref;
}

sub header {
  my ($self) = @_;

  return $self->site_header();
}

sub cookie {
  my ($self, @cookies) = @_;

  if(scalar @cookies) {
    $self->{cookie} = \@cookies;
  }

  return @{$self->{cookie}||[]};
}

sub site_header {
  my ($self) = @_;
  my $cgi    = $self->cgi();

  my $ss = <<"EOT";
@{[map {
    qq(    <link rel="stylesheet" type="text/css" href="$_" />);
} grep { $_ } @{$self->stylesheet()}]}
EOT

  if($self->style()) {
    $ss .= q(<style type="text/css">). $self->style() .q(</style>);
  }

  my $rss = <<"EOT";
@{[map {
    qq(    <link rel="alternate" type="application/rss+xml" title="RSS" href="$_" />\n);
} grep { $_ } @{$self->rss()}]}
EOT

  my $atom = <<"EOT";
@{[map {
    qq(    <link rel="alternate" type="application/atom+xml" title="ATOM" href="$_" />\n);
  } grep { $_ } @{$self->atom()}]}
EOT

  my $js = <<"EOT";
@{[map {
    qq(    <script type="text/javascript" src="@{[$cgi->escapeHTML($_)]}"></script>\n);
} grep { $_ } @{$self->jsfile()}]}
EOT

  my $script = <<"EOT";
@{[map {
    qq(    <script type="text/javascript">$_</script>\n);
} grep { $_ } @{$self->script()}]}
EOT

  my $onload   = (scalar $self->onload())   ? qq( onload="@{[  join q(;), $self->onload()]}")   : q[];
  my $onunload = (scalar $self->onunload()) ? qq( onunload="@{[join q(;), $self->onunload()]}") : q[];
  my $onresize = (scalar $self->onresize()) ? qq( onresize="@{[join q(;), $self->onresize()]}") : q[];
  return <<"EOT";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="@{[join q[,], @{$self->lang}]}" lang="@{[join q[,], @{$self->lang}]}">
  <head>
    <meta http-equiv="Content-Type" content="@{[$self->meta_content_type() || $self->defaults('meta_content_type')]}" />
@{[(scalar $self->meta_cookie())?(map { qq( <meta http-equiv="Set-Cookie" content="$_" />\n) } $self->meta_cookie()):q[]]}@{[$self->meta_refresh()?qq(<meta http-equiv="Refresh" content="@{[$self->meta_refresh()]}" />):q[]]}@{[$self->meta_expires()?qq(<meta http-equiv="Expires" content="@{[$self->meta_expires()]}" />):q[]]}    <meta name="author"      content="@{[$self->meta_author()      || $self->defaults('meta_author')]}" />
    <meta name="version"     content="@{[$self->meta_version()     || $self->defaults('meta_version')]}" />
    <meta name="description" content="@{[$self->meta_description() || $self->defaults('meta_description')]}" />
    <meta name="keywords"    content="@{[$self->meta_keywords()    || $self->defaults('meta_keywords')]}" />
    <title>@{[$self->title || 'ClearPress Application']}</title>
$ss$rss$atom$js$script  </head>
  <body$onload$onunload$onresize>
EOT
}

sub footer {
  return <<'EOT';
  </body>
</html>
EOT
}

sub cgi {
  my ($self, $cgi) = @_;

  if($cgi) {
    $self->{cgi} = $cgi;

  } elsif(!$self->{cgi}) {
    $self->{cgi} = CGI->new();
  }

  return $self->{cgi};
}

sub session {
  return {};
}

sub save_session {
  return;
}

1;
__END__

=head1 NAME

ClearPress::decorator - HTML site-wide header & footer handling

=head1 VERSION

$LastChangeRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 defaults - Accessor for default settings used in HTML headers

  my $sValue = $oDecorator->defaults($sKey);

=head2 fields - All generic get/set accessors for this object

  my @aFields = $oDecorator->fields();

=head2 cookie - Get/set cookies

  $oDecorator->cookie(@aCookies);
  my @aCookies = $oDecorator->cookie();

=head2 header - construction of HTTP and HTML site headers

=head2 site_header - construction of HTML site headers

i.e. <html>...<body>

  Subclass and extend this method to provide consistent site-branding

  my $sHTMLHeader = $oDecorator->site_header();

=head2 footer - pass-through to site_footer

=head2 site_footer - construction of HTML site footers

i.e. </body></html> by default

  my $sHTMLFooter = $oDecorator->site_footer

=head2 username - get/set username of authenticated user

  my $sUsername = $oDecorator->username();

=head2 cgi - get/set accessor for a CGI object

  $oDecorator->cgi($oCGI);

  my $oCGI = $oDecorator->cgi();

=head2 session - Placeholder for a session hashref

  my $hrSession = $oDecorator->session();

 This will not do any session handling until subclassed and overridden for a specific environment/service.

=head2 save_session - Placeholder for session saving

 This will not do any session handling until subclassed and overridden for a specific environment/service.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head2 title - HTML page title

=head2 stylesheet - External CSS URL (arrayref permitted)

=head2 style - Embedded CSS content

=head2 jsfile - External Javascript URL (arrayref permitted)

=head2 script - Embedded Javascript content (arrayref permitted)

=head2 atom - External ATOM feed URL (arrayref permitted)

=head2 rss - External RSS feed URL (arrayref permitted)

=head2 meta_keywords - HTML meta keywords

=head2 meta_description - HTML meta description

=head2 meta_author - HTML meta author

=head2 meta_version - HTML meta version

=head2 meta_refresh - HTML meta refresh

=head2 meta_cookie - HTML meta cookie

=head2 meta_content_type - HTML meta content-type

=head2 meta_expires - HTML meta expires

=head2 onload - body onload value (javascript)

=head2 onunload - body onunload value (javascript)

=head2 onresize - body onresize value (javascript)

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item CGI

=item base

=item Class::Accessor

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
