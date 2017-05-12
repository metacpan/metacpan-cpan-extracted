package Apache::AntiSpam;

use strict;
use vars qw($VERSION);
$VERSION = 0.05;

use Apache::Constants qw(:common);
use Apache::File;
use Carp ();
use Email::Find 0.04;

sub handler ($$) {
    my($class, $r) = @_;

    my $filtered = uc($r->dir_config('Filter')) eq 'ON';

    # makes Apache::Filter aware
    # snippets stolen from Geoffrey Young's Apache::Clean 
    $r = $r->filter_register if $filtered;

    # AntiSpam filtering is done on text/* files
    return DECLINED unless ($r->content_type =~ m,^text/, && $r->is_main);

    my($fh, $status);
    if ($filtered) {
	($fh, $status) = $r->filter_input;
	undef $fh unless $status == OK;
    } else {
	$fh = Apache::File->new($r->filename);
    }

    return DECLINED unless $fh;

    # finds and replaces e-mail addresses
    # if-statement should be outside the sub for efficiency
    my $replacer;
    if (uc($r->dir_config('AntiSpamFormat')) eq 'SPACES') {
	$replacer = sub {
	    my($email, $orig) = @_;
	    $orig =~ s/\@/ at /g;
	    $orig =~ s/\./ dot /g;
	    $orig =~ s/\-/ bar /g;
	    $orig =~ s/  */ /g;
	    return $orig;
	};
    } else {
	$replacer = sub {
	    my($email, $orig) = @_;
	    $orig =~ s/\@/-nospam\@/;
	    return $orig;
	};
    }

    $r->send_http_header;

    local $/;		# slurp
    my $input = <$fh>;
    find_emails($input, sub { $class->antispamize(@_) });
    $r->print($input);

    return OK;
}

sub antispamize {
    my($class, $email, $orig) = @_;
    Carp::carp "Apache::AntiSpam should be subclassed. I'll do nothing";
    return $orig;
}

1;
__END__

=head1 NAME

Apache::AntiSpam - AntiSpam filter for web pages

=head1 SYNOPSIS

  # You can't use this class directry
  # see Apache::AntiSpam::* 

  # or ... if you want your own AntiSpam Filter,
  package Your::AntiSpamFilter;
  use base qw(Apache::AntiSpam);

  sub antispamize {
      my($class, $email, $orig) = @_;
      # do some filtering with $orig, and
      return $orig;
  }

  # in httpd.conf
  <Location /antispam>
  SetHandler perl-script
  PerlHandler Your::AntiSpamFilter
  </Location>

  # filter aware
  PerlModule Apache::Filter
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Your::AntiSpamFilter Apache::Compress

=head1 DESCRIPTION

Apache::AntiSpam is a filter module to prevent e-mail addresses
exposed as is on web pages. The way to hide addresses from spammers
are implemented in each of Apache::Antispam::* subclasses.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 SUBCLASSING

Here is how to make your own filter.

=over 4

=item *

Declare your class

=item *

Inherit from Apache::AntiSpam

=item *

define antispamize() method

=back

That's all. Template of antispamize() method will be like this:

  sub antispamize {
      my($class, $email, $orig) = @_;
      # do some stuff..
      return $orig;
  }

where C<$class> is your class, C<$email> is an instance of
Mail::Address, and C<$orig> is an original e-mail address string. See
L<Email::Find> for details.

=head1 TODO

=over 4

=item *

remove mailto: tags using HTML::Parser.

=back

=head1 ACKNOWLEDGEMENTS

The idea of this module is stolen from Apache::AddrMunge by Mark J
Dominus. See http://perl.plover.com/AddrMunge/ for details.

Many thanks to Michael G. Schwern for kindly improving the matching
speed of Email::Find.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Email::Find>, L<Apache::Filter>, L<Apache::AntiSpam::NoSpam>,
L<Apache::AntiSpam::Heuristic>, L<Apache::AntiSpam::HTMLEncode>.

=cut
