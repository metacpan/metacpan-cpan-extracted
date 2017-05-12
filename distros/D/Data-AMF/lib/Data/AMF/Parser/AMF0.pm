package Data::AMF::Parser::AMF0;
use strict;
use warnings;

use Data::AMF::IO;
use Data::AMF::Parser::AMF3;

use constant PARSERS => [
    \&parse_number,
    \&parse_boolean,
    \&parse_string,
    \&parse_object,
    \&parse_movieclip,
    \&parse_null,
    \&parse_undefined,
    \&parse_reference,
    \&parse_ecma_array,
    sub { },                    # object end
    \&parse_strict_array,
    \&parse_date,
    \&parse_long_string,
    \&parse_unsupported,
    \&parse_recordset,
    \&parse_xml_document,
    \&parse_typed_object,
	\&parse_avmplus_object,
];

sub parse {
    my ($class, $data) = @_;

    my @res;
    my $io = ref($data) eq 'Data::AMF::IO' ? $data : Data::AMF::IO->new(data => $data);

    while (defined( my $marker = $io->read_u8 )) {
        my $p = PARSERS->[$marker] or die;
        push @res, $p->($io);
    }

    @res;
}

sub parse_one {
    my ($class, $data) = @_;

    my @res;
    my $io = ref($data) eq 'Data::AMF::IO' ? $data : Data::AMF::IO->new($data);

    my $marker = $io->read_u8;
    return unless defined $marker;

    my $p = PARSERS->[$marker] or die;
    $p->($io);
}

sub parse_number {
    my $io = shift;

    $io->read_double;
}

sub parse_boolean {
    my $io = shift;

    $io->read_u8 ? 1 : 0;
}

sub parse_string {
    my $io = shift;

    $io->read_utf8;
}

sub parse_object {
    my $io = shift;

    my $obj = {};
    push @{ $io->refs }, $obj;

    while (1) {
        my $len = $io->read_u16;

        if ($len == 0) {
            $io->read_u8;       # object-end marker
            return $obj;
        }
        my $key   = $io->read($len);
        my $value = __PACKAGE__->parse_one($io);

        $obj->{ $key } = $value;
    }

    $obj;
}

sub parse_movieclip {  }

sub parse_null {
    undef;
}

sub parse_undefined {
    undef;                      # XXX
}

sub parse_reference {
    my $io = shift;
    my $index = $io->read_u16;

    $io->refs->[$index] or return;
}

sub parse_ecma_array {
    my $io = shift;

    my $count = $io->read_u32;
    parse_object($io);
}

sub parse_strict_array {
    my $io = shift;

    my $count = $io->read_u32;

    my @res;
    for (1 .. $count) {
        push @res, __PACKAGE__->parse_one($io);
    }

    my $array = \@res;
    push @{ $io->refs }, $array;

    $array;
}

sub parse_date {
    my $io = shift;

    my $msec = $io->read_double;
    my $tz   = $io->read_s16;

    $msec;
}

sub parse_long_string {
    my $io = shift;

    $io->read_utf8_long;
}

sub parse_unsupported { }
sub parse_recordset { }

sub parse_xml_document {
    parse_long_string(shift)  # XXX
}

sub parse_typed_object {
    my $io = shift;

    my $class = $io->read_utf8;
    parse_object($io);
}

sub parse_avmplus_object {
	my $io = shift;
	
	my $parser = Data::AMF::Parser::AMF3->new;
	$parser->{'io'} = $io;
	$parser->read;
}

1;

__END__

=head1 NAME

Data::AMF::Parser::AMF0 - deserializer for AMF0

=head1 SYNOPSIS

    my $obj = Data::AMF::Parser::AMF0->parse($amf0_data);

=head1 METHODS

=head2 parse

=head2 parse_one

=head2 parse_number

=head2 parse_boolean

=head2 parse_string

=head2 parse_object

=head2 parse_movieclip

=head2 parse_null

=head2 parse_undefined

=head2 parse_reference

=head2 parse_ecma_array

=head2 parse_strict_array

=head2 parse_date

=head2 parse_long_string

=head2 parse_unsupported

=head2 parse_recordset

=head2 parse_xml_document

=head2 parse_typed_object
 
 =head2 parse_avmplus_object

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

