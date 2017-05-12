
package Data::Visitor::Encode;
use Moose;
use Encode();
use Scalar::Util ();

extends 'Data::Visitor';

our $VERSION = '0.10007';

has 'visit_method' => (
    is => 'rw',
    isa => 'Str'
);

has 'extra_args' => (
    is => 'rw',
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub _object { ref $_[0] ? $_[0] : $_[0]->new }

sub visit_glob
{
    return $_[1];
}

sub visit_scalar
{
    my ($self, $ref) = @_;

    my $ret = $self->visit_value($$ref);
    if (defined $ret) {
        return \$ret;
    }
    return undef;
}

# We care about the hash key as well, so override
sub visit_hash
{
    my ($self, $hash) = @_;

    my %map = map {
        (
            $self->visit_value($_),
            $self->visit($hash->{$_})
        )
    } keys %$hash;
    return \%map;
}

sub visit_object
{
    my ($self, $data) = @_;

    my $type = lc (Scalar::Util::reftype($data));
    my $method = "visit_$type";
    my $ret    = $self->$method($data);

    return bless $ret, Scalar::Util::blessed($data);
}

sub visit_value
{
    my ($self, $data) = @_;

    # return as-is if undefined
    return $data unless defined $data;

    # return as-is if no method
    my $method = $self->visit_method();
    return $data unless $method;

    # return if unimplemented
    $method = "do_$method";
#    return $data if (! $self->can($method));

    return $self->$method($data);
}

sub do_utf8_on
{
    my $self = shift;
    my $data = shift;

    Encode::_utf8_on($data);
    return $data;
}

sub do_utf8_off
{
    my $self = shift;
    my $data = shift;

    Encode::_utf8_off($data);
    return $data;
}

sub utf8_on
{
    my $self = _object(shift);
    $self->visit_method('utf8_on');
    $self->visit($_[0]);
}

sub utf8_off
{
    my $self = _object(shift);
    $self->visit_method('utf8_off');
    $self->visit($_[0]);
}

sub do_encode {
    my $self = shift;
    return $_[0] = $self->{__encoding}->encode($_[0]);
}

sub do_decode {
    my $self = shift;
    return $_[0] = $self->{__encoding}->decode($_[0]);
}

sub decode
{
    my $self = _object(shift);
    my $code = shift;

    my $encoding = Encode::find_encoding( $code );
    if (! $encoding) {
        Carp::confess("Could not find encoding by the name of $encoding");
    }
    local $self->{__encoding} = $encoding;
    $self->extra_args($code);
    $self->visit_method('decode');
    $_[0] = $self->visit($_[0]);
}

sub encode
{
    my $self = _object(shift);
    my $code = shift;

    my $encoding = Encode::find_encoding( $code );
    if (! $encoding) {
        Carp::confess("Could not find encoding by the name of $encoding");
    }
    local $self->{__encoding} = $encoding;
    $self->extra_args($code);
    $self->visit_method('encode');
    $_[0] = $self->visit($_[0]);
}

sub do_decode_utf8 {
    my $self = shift;
    return $_[0] = Encode::decode_utf8($_[0]);
}

sub decode_utf8
{
    my $self = _object(shift);
    $self->visit_method('decode_utf8');
    $_[0] = $self->visit($_[0]);
}

sub do_encode_utf8
{
    my $self = shift;
    return $_[0] = Encode::encode_utf8($_[0]);
}

sub encode_utf8
{
    my $self = _object(shift);
    my $enc  = $_[1];
    $self->visit_method('encode_utf8');
    $_[0] = $self->visit($_[0]);
}

sub do_h2z
{
    my $self = shift;

    my $is_euc = ($self->extra_args =~ /^euc-jp$/i);
    my $utf8_on = Encode::is_utf8($_[0]);
    my $euc_encoding = $self->{__euc};
    my $encoding = $self->{__encoding};
    my $euc  =
        $is_euc ?
            $_[0] :
        $utf8_on ?
            $euc_encoding->encode($_[0]) :
            $euc_encoding->encode($encoding->decode($_[0]))
    ;

    Encode::JP::H2Z::h2z(\$euc);

    return $_[0] = (
        $is_euc ?
            $euc :
        $utf8_on ?
            $euc_encoding->decode($euc) :
            $encoding->encode($euc_encoding->decode($euc))
    );   
}

sub h2z
{
    my $self = _object(shift);
    my $code = shift;

    require Encode::JP::H2Z;

    local $self->{__euc} = Encode::find_encoding('euc-jp');
    my $encoding = Encode::find_encoding( $code );
    if (! $encoding) {
        Carp::confess("Could not find encoding by the name of $encoding");
    }
    local $self->{__encoding} = $encoding;

    $self->visit_method('h2z');
    $self->extra_args($code);
    $self->visit($_[0]);
}

sub do_z2h
{
    my $self = shift;

    my $is_euc = ($self->extra_args =~ /^euc-jp$/i);
    my $utf8_on = Encode::is_utf8($_[0]);
    my $euc_encoding = $self->{__euc};
    my $encoding = $self->{__encoding};
    my $euc  =
        $is_euc ?
            $_[0] :
        $utf8_on ?
            $euc_encoding->encode($_[0]) :
            $euc_encoding->encode($encoding->decode($_[0]))
    ;

    Encode::JP::H2Z::z2h(\$euc);
        
    return $_[0] = (
        $is_euc ?
            $euc :
        $utf8_on ?
            $euc_encoding->decode($euc) :
            $encoding->encode($euc_encoding->decode($euc))
    );   
}

sub z2h
{
    my $self = _object(shift);
    my $code = shift;

    require Encode::JP::H2Z;

    local $self->{__euc} = Encode::find_encoding('euc-jp');
    my $encoding = Encode::find_encoding( $code );
    if (! $encoding) {
        Carp::confess("Could not find encoding by the name of $encoding");
    }
    local $self->{__encoding} = $encoding;

    $self->visit_method('z2h');
    $self->extra_args($code);
    $self->visit($_[0]);
}

1;

__END__

=head1 NAME

Data::Visitor::Encode - Encode/Decode Values In A Structure (DEPRECATED)

=head1 SYNOPSIS

  # THIS MODULE IS NOW DEPRECATED. Use Data::Recursive::Encode instead
  use Data::Visitor::Encode;

  my $dev = Data::Visitor::Encode->new();
  my %hash = (...); # assume data is in Perl native Unicode
  $dev->encode('euc-jp', \%hash); # now strings are in euc-jp
  $dev->decode('euc-jp', \%hash); # now strings are back in unicode
  $dev->utf8_on(\%hash);
  $dev->utf8_off(\%hash);

=head1 DEPRECATION ALERT 

This module has been DEPRECATED in favor of L<Data::Recursive::Encode>. Bug reports will not be acted upon, and the module will cease to exist from CPAN by the end of year 2011.

You've been warned (since 2009)

=head1 DESCRIPTION

Data::Visitor::Encode visits each node of a structure, and returns a new
structure with each node's encoding (or similar action). If you ever wished
to do a bulk encode/decode of the contents of a structure, then this
module may help you.

Starting from 0.09000, you can directly use the methods without instantiating
the object:

  Data::Visitor::Encode->encode('euc-jp', $obj);
  # instead of Data::Visitor::Encode->new->encod('euc-jp', $obj)

=head1 METHODS

=head2 utf8_on

  $dev->utf8_on(\%hash);
  $dev->utf8_on(\@list);
  $dev->utf8_on(\$scalar);
  $dev->utf8_on($scalar);
  $dev->utf8_on($object);

Returns a structure containing nodes with utf8 flag on

=head2 utf8_off

  $dev->utf8_off(\%hash);
  $dev->utf8_off(\@list);
  $dev->utf8_off(\$scalar);
  $dev->utf8_off($scalar);
  $dev->utf8_off($object);

Returns a structure containing nodes with utf8 flag off

=head2 encode

  $dev->encode($encoding, \%hash   [, CHECK]);
  $dev->encode($encoding, \@list   [, CHECK]);
  $dev->encode($encoding, \$scalar [, CHECK]);
  $dev->encode($encoding, $scalar  [, CHECK]);
  $dev->encode($encoding, $object  [, CHECK]);

Returns a structure containing nodes which are encoded in the specified
encoding.

=head2 decode

  $dev->decode($encoding, \%hash);
  $dev->decode($encoding, \@list);
  $dev->decode($encoding, \$scalar);
  $dev->decode($encoding, $scalar);
  $dev->decode($encoding, $object);

Returns a structure containing nodes which are decoded from the specified
encoding.

=head2 decode_utf8

  $dev->decode_utf8(\%hash);
  $dev->decode_utf8(\@list);
  $dev->decode_utf8(\$scalar);
  $dev->decode_utf8($scalar);
  $dev->decode_utf8($object);

Returns a structure containing nodes which have been processed through
decode_utf8.

=head2 encode_utf8

  $dev->encode_utf8(\%hash);
  $dev->encode_utf8(\@list);
  $dev->encode_utf8(\$scalar);
  $dev->encode_utf8($scalar);
  $dev->encode_utf8($object);

Returns a structure containing nodes which have been processed through
encode_utf8.

=head2 h2z

=head2 z2h

  $dev->h2z($encoding, \%hash);
  $dev->h2z($encoding, \@list);
  $dev->h2z($encoding, \$scalar);
  $dev->h2z($encoding, $scalar);
  $dev->h2z($encoding, $object);

h2z and z2h are Japanese-only methods (hey, I'm a little biased like that).
They perform the task of mapping half-width katakana to full-width katakana
and vice-versa.

These methods use Encode::JP::H2Z, which requires us to go from the
original encoding to euc-jp and then back. There are other modules that are 
built to handle exactly this problem, which may come out to be faster than 
using Encode.pm's somewhat hidden Encode::JP::H2Z, but I really don't care
for adding another dependency to this module other than Encode.pm, so
here it is.

If you're significantly worried about performance, I'll gladly accept patches
as long as there are no prerequisite modules or the prerequisite is optional.

=head2 decode_utf8

  $dev->decode_utf8(\%hash);
  $dev->decode_utf8(\@list);
  $dev->decode_utf8(\$scalar);
  $dev->decode_utf8($scalar);
  $dev->decode_utf8($object);

Returns a structure containing nodes which have been processed through
decode_utf8.

=head2 encode_utf8

  $dev->encode_utf8(\%hash);
  $dev->encode_utf8(\@list);
  $dev->encode_utf8(\$scalar);
  $dev->encode_utf8($scalar);
  $dev->encode_utf8($object);

Returns a structure containing nodes which have been processed through
encode_utf8.

=head2 do_decode

=head2 do_encode

=head2 do_utf8_off

=head2 do_utf8_on

=head2 do_h2z

=head2 do_z2h

=head2 do_encode_utf8

=head2 do_decode_utf8

=head2 visit_glob

=head2 visit_hash

=head2 visit_object

=head2 visit_scalar

=head2 visit_value

These methods are private. Only use if it you are subclassing this class.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 SEE ALSO

L<Data::Visitor|Data::Visitor>, L<Encode|Encode>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut