package Data::Dump::AutoEncode;

use strict;
use warnings;
use Carp;
use Data::Dump;
use Encode;
use Term::Encoding;
use parent 'Exporter';

our $VERSION = '0.02';
our @EXPORT = qw/edump/;
our @EXPORT_OK = qw/dump/;
our $ENCODER;

sub set_encoding {
  my $encoding = shift;

  $encoding ||= eval { Term::Encoding::get_encoding() } or croak "Can't find encoding: $@";
  $ENCODER = find_encoding($encoding) or croak "Can't find encoding: $encoding";
}

sub edump {
  set_encoding() unless $ENCODER;
  local @Data::Dump::FILTERS = sub {
    my ($ctx, $ref) = @_;
    if ($ctx->is_scalar && !$ctx->is_blessed) {
      if (Encode::is_utf8($$ref)) {
        return { dump => $ENCODER->encode($$ref) };
      }
    }
  };
  return &Data::Dump::dump;
}

*dump = \&edump;

1;

__END__

=encoding utf-8

=head1 NAME

Data::Dump::AutoEncode - dumps encoded data structure for debugging

=head1 SYNOPSIS

    use Data::Dump::AutoEncode;
    print edump(...); # encoded into the encoding your terminal uses

    # if you really need to change encoding
    Data::Dump::AutoEncode::set_encoding('utf-8');

    print edump(...); # encoded into utf-8

=head1 DESCRIPTION

This module encodes each (unblessed) string in data structure into
the encoding your terminal uses (or into the encoding you specified
explicitly) recursively, and without escaping.

You may find it useful when you dump a result of some API access
with one-liner, etc.

=head1 EXPORTED FUNCTION

=head2 edump(...)

Returns a recursively-encoded string of a Perl data structure.

=head1 FUNCTIONS

=head2 dump(...)

You can explicitly export C<edump> function as C<dump>.

=head2 set_encoding( encoding )

By default, Data::Dump::AutoEncode encodes strings into the encoding
your terminal uses (via Term::Encoding). If you need to change this
behavior, you can set other encoding with this function.

=head1 SEE ALSO

L<Data::Dump>

L<Data::Dumper::AutoEncode>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
