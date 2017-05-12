package Apache::TaintRequest;

use strict;
use warnings;

use Apache;
use Apache::Util qw(escape_html);
use Taint qw(tainted);

$Apache::TaintRequest::VERSION = '0.10';
@Apache::TaintRequest::ISA = qw(Apache);

sub new {
  my ($class, $r) = @_;

  $r ||= Apache->request;

  tie *STDOUT, $class, $r;

  return tied *STDOUT;
}


sub print {
  my ($self, @data) = @_;

  foreach my $value (@data) {
    # Dereference scalar references.
    $value = $$value if ref $value eq 'SCALAR';

    # Escape any HTML content if the data is tainted.
    $value = escape_html($value) if tainted($value);
  }

  $self->SUPER::print(@data);
}

sub TIEHANDLE {
  my ($class, $r) = @_;

  return bless { r => $r }, $class;
}

sub PRINT {
  shift->print(@_);
}

1;

__END__

=head1 NAME

Apache::TaintRequest - HTML Escape tainted data to prevent CSS Attacks

=head1 SYNOPSIS

  use Apache::TaintRequest ();

  sub handler {
    my $r = shift;
    $r = Apache::TaintRequest->new($r);

    my $querystring = $r->query_string();
    $r->print($querystring);   # html is escaped...

    $querystring =~ s/<script>//;
    $r->print($querystring);   # html is NOT escaped...
  }

=head1 DESCRIPTION

=over 15

=item Note:

This code is derived from the I<Cookbook::TaintRequest> module,
available as part of "The mod_perl Developer's Cookbook".

=back

One of the harder problems facing web developers involves dealing with
potential cross site scripting attacks.  Frequently this involves many
calls to Apache::Util::escape_html().

This module aims to automate this tedious process.  It overrides the
print mechanism in the mod_perl Apache module.  The new print method
tests each chunk of text for taintedness.  If it is tainted we assume
the worst and html-escape it before printing.

Note that this module requires that you have the line 

  PerlTaintCheck on

in your httpd.conf.  This may have other unintended side effects, so
be warned.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Taint

=head1 AUTHORS

Paul Lindner E<lt>paul@modperlcookbook.orgE<gt>

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

Randy Kobes E<lt>randy@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2001, Paul Lindner, Geoffrey Young, Randy Kobes.

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::TaintRequest> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
