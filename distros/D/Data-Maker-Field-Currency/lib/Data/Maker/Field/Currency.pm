package Data::Maker::Field::Currency;
use Moose;
use MooseX::Aliases;
extends 'Data::Maker::Field::Number';
use Data::Money;

our $VERSION = '0.22';

has '+precision' => ( default => 2 );
has '+separate_thousands' => ( default => 1 );
has 'as_float' => ( is => 'rw', isa => 'Bool', default => 0 );
has iso_code => ( is => 'rw', default => 'USD', alias => 'code');
has with_code => ( is => 'rw', isa => 'Bool', default => 0);

sub generate_value {
  my $this = shift;
  my $thousands = $this->separate_thousands;
  $this->separate_thousands(0) if $thousands;
  my $money = Data::Money->new(
    value => $this->SUPER::generate_value(@_),
    code => $this->iso_code,
    format => 'FMT_COMMON'
  );
  my $out;
  if ($this->as_float) {
    $out = $money->as_float;
  } elsif ($thousands) {
    $this->separate_thousands(1);
    $out = $money;
  } else {
    $out = $money->as_float;
  }
  if ($this->with_code) {
    #$out =~ s/[^\d\.\,]//g;
    #$out =~ s/^\.//;
    $out = join(' ', $this->iso_code, $out);
  }
  return $out;
}

1;

__END__

=head1 NAME 

Data::Maker::Field::Currency - A L<Data::Maker> field class used for generating random currency values.

=head1 SYNOPSIS

  use Data::Maker;
  use Data::Maker::Field::Currency;
  
  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'price',
        class => 'Data::Maker::Field::Currency',
        args => {
          min => 200,
          max => 3000,
          iso_code => 'USD'
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::Currency is a subclass of L<Data::Maker::Field::Number>, with the C<precision> attribute set to 2 and the C<separate_thousands> attribute defined as true.

This class also supports the following L<Moose> attributes:

=over 4

=item * B<iso_code>

A valid currency code, as defined by ISO 4217.  Defaults to USD.

=item * B<code>

An alias for C<iso_code>

=item * B<as_float> (I<Bool>)

If set to a true value, the generated value will be returned as a float, without any currency formatting.

=item * B<with_code> (I<Bool>)

If set to a true value, the generated value will be returned, prefixed by the country code

=back

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

