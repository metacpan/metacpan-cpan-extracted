package Apache::Clickable;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

use Apache::Constants qw(:common);
use Apache::File;
use Carp ();

sub handler {
    my $r = shift;

    my $filtered = uc($r->dir_config('Filter')) eq 'ON';
    $r = $r->filter_register if $filtered;

    # only for text/html
    return DECLINED unless ($r->content_type eq 'text/html' && $r->is_main);

    my($fh, $status);
    if ($filtered) {
	($fh, $status) = $r->filter_input;
	undef $fh unless $status == OK;
    } else {
	$fh = Apache::File->new($r->filename);
    }

    return DECLINED unless $fh;

    $r->send_http_header;

    local $/;			# slurp
    my $input = <$fh>;
    my $output = make_it_clickable($r, $input);
    $r->print($output);
    return OK;
}

sub make_it_clickable {
    my($r, $input) = @_;
    my $parser = Apache::Clickable::Parser->new(apr => $r);
    $parser->parse($input);
    return $parser->{output};
}

package Apache::Clickable::Parser;

require HTML::Parser;
@Apache::Clickable::Parser::ISA = qw(HTML::Parser);

use Email::Find 0.04;
use URI::Find;

sub new {
    my($class, %args) = @_;

    my $self = $class->SUPER::new;
    $self->{apr} = $args{apr};
    $self->{currently_in_a} = 0;
    return $self;
}

sub comment {
    my($self, $comment) = @_;
    $self->{output} .= "<!--$comment-->";
}

sub declaration {
    my($self, $declaration) = @_;
    $self->{output} .= "<!$declaration>";
}

sub start {
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    if ($tag eq 'a') {
	$self->{currently_in_a}++;
    }
    $self->{output} .= $origtext;
}

sub end {
    my($self, $tag, $origtext) = @_;
    if ($tag eq 'a') {
	$self->{currently_in_a}--;
    }
    $self->{output} .= $origtext;
}

sub text {
    my($self, $origtext) = @_;
    if ($self->{currently_in_a}) {
	$self->{output} .= $origtext;
	return;
    }

    $self->{output} .= $self->replace_sub->($origtext);
}

my $sub;			# closure
sub replace_sub {
    my $self = shift;
    unless ($sub) {
	$sub = sub {
	    my $input = shift;
	    # replace URLs
	    my $target = $self->{apr}->dir_config('ClickableTarget') || undef;
	    find_uris($input, sub {
			  my($uri, $orig_uri) = @_;
			  return sprintf(qq(<a href="%s"%s>%s</a>),
					 $orig_uri,
					 ($target ? qq( target="$target") : ''),
					 $orig_uri);
		      });

	    # replace Emails
	    unless (uc($self->{apr}->dir_config('ClickableEmail')) eq 'OFF') {
		find_emails($input, sub {
				my($email, $orig_email) = @_;
				return sprintf(qq(<a href="mailto:%s">%s</a>),
					       $orig_email, $orig_email);
			    });
	    }

	    return $input;
	};
    }
    return $sub;
}

1;
__END__

=head1 NAME

Apache::Clickable - Make URLs and Emails in HTML clickable

=head1 SYNOPSIS

  # in httpd.conf
  <Location /clickable>
  SetHandler perl-script
  PerlHandler Apache::Clickable
  </Location>

  # filter aware
  PerlModule Apache::Clickable
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::Clickable Apache::AntiSpam Apache::Compress

=head1 DESCRIPTION

Apache::Clickable is a filter to make URLs in HTML clickable. With
URI::Find and Email::Find, this module finds URL and Email in HTML
document, and automatically constructs hyperlinks for them.

For example,

  <body>
  Documentation is available at http://www.foobar.com/ freely.<P>
  someone@foobar.com  
  </body>

This HTML would be filtered to:
    
  <body>
  Documentation is available at <a href="http://www.foobar.com/">http://www.foobar.com</a> freely.<P>
  <a href="mailto:someone@foobar.com">someone@foobar.com</a>
  </body>

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 CONFIGURATION

  PerlSetVar ClickableTarget _blank
  PerlSetVar ClickableEmail Off

=over 4

=item ClickableTarget

  PerlSetVar ClickableTarget _blank

specifies target window name of hyperlinks. If set "_blank" for
example, it filters to:

  <a href="http://www.foobar.com/" target="_blank">http://www.foobar.com/</a>

None by default.

=item ClickableEmail

  PerlSetVar ClickableEmail Off

specifies whether it makes email clickable. On by default. See
L<Apache::AntiSpam> for more.

=back

=head1 TODO

=over 4

=item *

Configurable hyperlink construction using subclass.

=item *

Currently, this module requires HTML::Parser, not to make duplicate
hyperlinks. Maybe this can be done without HTML::Parser.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Filter>, L<Apache::AntiSpam>, L<URI::Find>, L<Email::Find>, L<HTML::Parser>

=cut
