package DBIx::ParseDSN;

use v5.8.8;

use warnings;
use strict;
use Carp;
use Module::Load::Conditional qw/can_load/;
use Class::Load qw/is_class_loaded/;
use DBIx::ParseDSN::Default;
use base 'Exporter';
our @EXPORT = qw/parse_dsn/;

use version; our $VERSION = qv('0.9.3');

## this is really a utility function, but there is no ::Util module
## yet, so it's here for now
sub _split_dsn {

    my $dsn = shift;
    my @parts = split /:/, $dsn, 3;

    return @parts;

}

## a method to check health status of parsers DSN
sub _dsn_sanity_check {

    my $self = shift;

    ## it should have three groups, separated by two colons, ie:
    ## group1:group2:group3
    ##
    ## group1 is probably only ever "dbi"
    ## group2 will be the driver followed by attributes
    ## group3 will be driver specific options. group3 may include colons

    if ( not defined $self->dsn ) {
        carp "DSN isn't set";
        return;
    }

    if ( _split_dsn($self->dsn) != 3 ) {
        carp "DSN does not contain the expected pattern with 2 separating colons.";
    }

}

sub _default_parser {
    return __PACKAGE__ . "::Default";
}

sub parse_dsn {

    my($dsn,$user,$pass,$attr) = @_;

    ## decide driver
    my($scheme,$driver) = _split_dsn($dsn);

    my $parser_module = __PACKAGE__ . "::" . $driver;

    if ( not is_class_loaded($parser_module) ) {

        if ( not can_load modules => { $parser_module=>0 } ) {
            $parser_module = _default_parser;
        }

    }

    return $parser_module->new($dsn);

}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

DBIx::ParseDSN - Parse DSN's, DBI connection strings.

=head1 VERSION

This document describes DBIx::ParseDSN version 0.9.3

=head1 SYNOPSIS

    use DBIx::ParseDSN;

    my $dsn = parse_dsn("dbi:SQLite:database=/var/foo.db");

    $dsn->scheme; ## dbi
    $dsn->driver; ## SQLite
    $dsn->database; ## /var/foo.db

    $dsn->dbd_driver; ## DBD::SQLite

    ## information in user string
    my $dsn2 = parse_dsn( 'dbi:Oracle:host=foobar;port=1521', 'scott@DB/tiger' )
    $dsn2->database; ## DB
    $dsn2->port; ## 1521
    $dsn2->host; ## foobar

    ## uri connector
    my $dsn3 = parse_dsn( 'dbi:Oracle://myhost:1522/ORCL' )
    $dsn3->database; ## ORCL
    $dsn3->port; ## 1522
    $dsn3->host; ## myhost

=head1 DESCRIPTION

Exports parse_dsn that parses a DSN. It returns a
L<DBIx::ParseDSN::Default> that has attributes from the dsn.

This module looks for parser classes of the form DBIx::ParseDSN::Foo,
where Foo literally matches the DSN driver, ie the 2nd part of the DSN
string. Case sensitive.

Example: dbi:SQLite:database=/foo/bar would look for
DBIx::ParseDSN::SQLite and use that as a parser, if found.

If DBIx::ParseDSN::Foo is loaded, it uses that. If the module can be
loaded, it will load it.

It falls back to L<DBIx::ParseDSN::Default> if no specific parser is
found.

To implement not supported DBI driver strings, subclass
L<DBIx::ParseDSN::Default> and reimplement C<sub parse> or change for
example C<sub names_for_database> if database is just called something
else.

=head1 INTERFACE

=head2 parse_dsn( $dsn );

Parses a DSN and returns a L<DBIx::ParseDSN::Default> object that has
properties reflecting the parameters found in the DSN.

See L<DBIx::ParseDSN::Default/DSN ATTRIBUTES> for details.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-parsedsn@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<DBI>
L<DBIx::ParseDSN::Default>

=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
