package Data::Maker::Field::Number;
use Data::Maker::Field::Format;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Aliases;
with 'Data::Maker::Field';
use Data::Dumper;

our $VERSION = '0.24';

subtype 'PositiveInt'
  => as 'Int'
  => where { $_ > 0 }
  => message { "The number you provided, $_, was not a positive number" };

has thousands_separator => ( is => 'rw', default => ',');
has decimal_separator => ( is => 'rw', default => '.');
has separate_thousands => ( is => 'rw', isa => 'Bool', default => 0, alias => 'commafy');
has min => ( is => 'rw', isa => 'Num');
has max => ( is => 'rw', isa => 'Num');
has precision => ( is => 'rw', isa => 'PositiveInt', default => 0);
has static_decimal => ( is => 'rw', isa => 'Num', default => 0);

sub generate_value {
  my $this = shift;
  my $precision = $this->precision;
  my $format = "%.${precision}f";
  my $value = sprintf($format, $this->min + rand($this->max - $this->min));
  if ($this->static_decimal) {
    $value = join('.', int($value), $this->static_decimal);
  }
  unless ($this->decimal_separator eq '.') {
    $value =~ s/\./$this->decimal_separator/e;
  }
  $this->value($value);
  if ($this->commafy) {
    return $this->commafied;
  } else {
    return $this->value;
  }
}

sub commafied {
  my $this = shift;
  my $value = $this->value;
  my ($int, $dec) = split(/$this->decimal_separator/, $value);
  $int = reverse $int;
  my $sep = $this->thousands_separator;
  $int =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1$sep>g;
  $int = reverse $int;
  if ($dec) {
    return join($this->decimal_separator, $int, $dec);  
  } else {
    return $int;
  }
}

1;

__END__

=head1 NAME 

Data::Maker::Field::Number - A L<Data::Maker> field class used for generating numeric data.

=head1 SYNOPSIS

  use Data::Maker;
  use Data::Maker::Field::Number;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'population',
        class => 'Data::Maker::Field::Number',
        args => {
          min => 5000,
          max => 5000000
        }
      }
    ]
  );

=head1 DESCRIPTION 

Data::Maker::Field::Number supports the following L<Moose> attributes:

=over 4

=item * B<thousands_separator> (I<Str>)

The string used to separate the thousands of the integer portion of the 
generated number.  Defaults to ','

=item * B<decimal_separator> (I<Str>)

The string used to separate the integer portion from the decimal portion
of the generated number.  Defaults to '.'

=item * B<separate_thousands> (I<Bool>)

If set to a true value, the thousands of the integer portion of the generated number
will be separated by the string defined by the I<thousands_separator> attribute. Defaults to 0.

=item * B<min> (I<Num>)

The minimum number that is to be generated

=item * B<max> (I<Num>)

The maximum number that is to be generated

=item * B<precision> (I<Num>)

The maximum number of places to which the decimal portion of the number should be generated.

=item * B<static_decimal> (I<Num>)

If this attribute is defined, the decimal portion of the number is always given that value.  
For example, if you want random prices that all end with 99 cents, you could set this attribute to .99

=back

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
