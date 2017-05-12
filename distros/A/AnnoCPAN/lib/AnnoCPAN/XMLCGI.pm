package AnnoCPAN::XMLCGI;

$VERSION = '0.22';

use strict;
use warnings;
use XML::Simple qw(XMLin);

=head1 NAME

AnnoCPAN::XMLCGI - Read XML input through a CGI.pm-like interface

=head1 SYNOPSYS

    use AnnoCPAN::XMLCGI;

    my $cgi = AnnoCPAN::XMLCGI->new;

    my $name = $cgi->param('name');
    print $cgi->header;
    print "Hello, $name!\n";    # Hello, Bob!

    # In STDIN...
    <data>
        <name>Bob</name>
        <age>123</age>
    <data>

=head1 DESCRIPTION

This module reads XML from STDIN and makes it available through and interface
that is compatible with a subset of that for L<CGI>. Its purpose is to be used
as a drop-in replacement for CGI for JavaScript XMLHttpRequest handlers that
receive their input in XML instead of the typical CGI form encoding.

Note that only a very minimal subset of L<CGI> is implemented, but it is the
only part that is required for most simple uses.

The input stream is expected to be a very simple XML structure with only one
level of depth, and with no duplicate keys. The root element (<data> in the 
example above) can be have any tag name.

=head1 METHODS

=over

=item AnnoCPAN::XMLCGI->new

Create an AnnoCPAN::XMLCGI object. Doesn't take any parameters. When called,
it slurps everything in STDIN; therefore it's not a very good idea to call it
more than once.

Returns false if there was a parsing error.

=cut

sub new {
    my $self = bless {}, shift;
    $self->init;
}

sub init {
    my ($self) = @_;
    eval {$self->{data} = XMLin('-', suppressEmpty => "") };
    if ($@) {
        $self->{error} = $@;
    }
    $self;
}

=item $cgi->param($name)

Return the value of the parameter $name. Note that, unlike L<CGI>,  it doesn't
handle multiple values.

=cut

sub param {
    my ($self, $name) = @_;
    $self->{data}{$name};
}

=item $cgi->header

Returns a very simple header ("Content-type: text/html; charset=UTF-8\n\n").

=cut

sub header {
    "Content-type: text/html; charset=UTF-8\n\n";
}

=back

=head1 SEE ALSO

L<CGI>, L<XML::Simple>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

