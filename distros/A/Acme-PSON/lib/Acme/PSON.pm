package Acme::PSON;

use strict;
use warnings;

our $VERSION = '0.05';

use strict;
use warnings;
use vars qw( @EXPORT_OK );
use Carp;
use Data::Dumper;
use Exporter::Lite;
@EXPORT_OK = qw(obj2pson pson2obj);

use Readonly;
Readonly my $VARNAME => 'PSON_VALUE';

sub obj2pson {
    my $obj = shift;

    local $Data::Dumper::Indent  = 0;
    local $Data::Dumper::Varname = $VARNAME;
    return Dumper($obj);
}

sub pson2obj {
    my $str = shift;

    no strict;

    &_is_dumpeddata($str) ? eval($str) : croak "No PSON Data!";
}

sub _is_dumpeddata {
    my $str = shift;

    return ( $str =~ /^\$$VARNAME/ ) ? 1 : 0;
}

1;

=head1 NAME

Acme::PSON - PSON(PerlScript Object Notation) Module

=head1 SYNOPSIS

 use Acme::PSON qw(obj2pson pson2obj);

 my $data = { x=> 'adfs' , y => 'adf' };

 my $pson = obj2pson( $data );

 my $obj  = pson2obj( $pson );

=head1 DESCRIPTION

Like L<JSON> but use Dumper.

=head1 METHOD

=head2 obj2pson( $object )

get pson data.

=head2 pson2obj( $pson )

get hash_ref or array_ref.

=head1 AUTHOR

Masahiro Funakoshi <masap@cpan.org>

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Tomohiro Teranishi.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  See L<perlartistic>.

=cut
