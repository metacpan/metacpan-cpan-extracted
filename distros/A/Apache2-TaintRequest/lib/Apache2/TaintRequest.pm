package Apache2::TaintRequest;

use strict;
use warnings;

=head1 NAME

Apache2::TaintRequest - HTML Escape tainted data to prevent CSS Attacks

=head1 SYNOPSIS

 use Apache2::TaintRequest ();

sub handler {
    my $r = shift;
    $r = Apache2::TaintRequest->new($r);

    my $querystring = $r->query_string();
    $r->print($querystring);    # html is escaped...

    $querystring =~ s/<script>//;
    $r->print($querystring);    # html is NOT escaped...
}

=cut

use Apache2::RequestRec;
use HTML::Entities ();
use Taint qw(tainted);

our $VERSION = '0.01';

use base 'Apache2::RequestRec';

sub new {
    my ( $class, $r ) = @_;

    my %self;
    bless \%self, $class;
    $self{request} = $r;

    return \%self;
}

*escape_html = \&HTML::Entities::encode_entities;

sub print {
    my ( $self, @data ) = @_;

    foreach my $value (@data) {

        # Dereference scalar references.
        $value = $$value if ref $value eq 'SCALAR';

        # Escape any HTML content if the data is tainted.
        $value = escape_html($value) if tainted($value);
    }

    $self->{request}->SUPER::print(@data);
}

1;

__END__


=head1 DESCRIPTION

=over 15

=item Note:

This code is derived from the I<Apache::TaintRequest> module,
available as part of "The mod_perl Developer's Cookbook".

=back

One of the harder problems facing web developers involves dealing with
potential cross site scripting attacks.  Frequently this involves many
calls to HTML::Entities::escape_html().

This module aims to automate this tedious process.  It overrides the
print mechanism in the mod_perl Apache module.  The new print method
tests each chunk of text for taintedness.  If it is tainted we assume
the worst and html-escape it before printing.

Note that this module requires that you have the line 

  PerlSwitches -T

in your httpd.conf.  This may have other unintended side effects, so
be warned.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Taint, Apache::TaintRequest

http://perl.apache.org/docs/2.0/user/porting/compat.html#C_PerlTaintCheck_

=head1 AUTHORS

Fred Moyer E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT

Apache2::TaintRequest Copryright (c) 2012, Fred Moyer

Apache::TaintRequest Copyright (c) 2001, Paul Lindner, Geoffrey Young, Randy Kobes.

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Apache::TaintRequest> module,
available on the CPAN.

=cut



