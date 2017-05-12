package Data::ID::URL::Shrink;

use strict;
use warnings;

use base 'Exporter';
use POSIX qw(floor);

our @EXPORT_OK = qw(shrink_id stretch_id random_id);
our %EXPORT_TAGS = (
  encoding => [qw(shrink_id stretch_id)],
  all => [qw(shrink_id stretch_id random_id)]
);
our $VERSION = '0.02';

use constant SHRINKB50 => '023456789BCDFGHJKLMNPQRSTVWXYZbcdfghjkmnpqrstvwxyz';
use constant SHRINKSIZE => length SHRINKB50;

# Get an indexed character from the base dictionary.
sub get_char_by_index { return substr(SHRINKB50, $_[0], 1); }

sub shrink_id {
  my $dividend = shift;
  return undef unless $dividend =~ /^\d+$/;
  return get_char_by_index(0) if $dividend == 0;
  my $id = '';
  while($dividend >= SHRINKSIZE) {
    my $remainder = $dividend % SHRINKSIZE;
    $id = get_char_by_index($remainder) . $id;
    $dividend = floor($dividend / SHRINKSIZE);
  }
  $id = get_char_by_index($dividend) . $id;
  return $id;
}

sub stretch_id {
  my $id = shift;
  return undef unless defined $id;
  my @id_chars = split //, $id;
  do { return undef unless (index(SHRINKB50, $_) >= 0) } for @id_chars;
  my $val = 0;
  while( scalar(@id_chars) ) {
    my $char_val = index SHRINKB50, shift(@id_chars);
    my $size = scalar(@id_chars);;
    $val += $char_val * (SHRINKSIZE ** $size);
  }
  return $val;
}

sub random_id {
  my $length = shift;
  $length = defined $length ? $length : 11;
  return undef unless $length =~ /^\d+$/ && $length > 2;
  my $id = '';
  $id .= get_char_by_index( int(rand(SHRINKSIZE)) ) for 1 .. $length;
  return $id;
}

1;

=pod

=head1 NAME

Data::ID::URL::Shrink - Shorten numeric IDs, for nicer URLs and more.

=head1 SYNOPSIS

  use Data::ID::URL::Shrink qw(:all);
  -- or --
  use Data::ID::URL::Shrink qw(:encoding);

  my $id = shrink_id(123456789);    # shorten your numeric ID.
  my $numeric_id = stretch_id($id); # get your numeric ID back.

=head1 DESCRIPTION

L<Data::ID::URL::Shrink> will shorten a numeric ID, and can randomly generate
IDs for you, based on its own Base50 character set.
  
By default, a random_id() call will return an 11-character id. Optionally, you can
generate IDs of specific character lengths, but no shorter than 3 characters.

This module DOES NOT GUARANTEE unique IDs. It supplements them.

=head1 FUNCTIONS

Export functions individually or use tags -- ':encoding' or ':all'.

=head2 shrink_id

  my $id = shrink_id(123456789);

Give this function a numeric ID and get a shorter, encoded one in return.

=head2 stretch_id

  my $numeric_id = stretch_id($id);

Get a numeric value back from a previously encoded id.

=head2 random_id

  # NOTE: If argument is passed, must be n > 2.
  my $id = random_id(); # Generate a random 11-character ID.
  my $id = random_id(n); # Generate a random n-character ID.

Just remember: the lower the character length value, the smaller the set of
possible unique IDs.

=head1 ACKNOWLEDGEMENTS

=head2 mst

Thanks for help with the module name and answering PAUSE and CPAN questions.

=head2 internets

Thanks to the authors of the articles, Q&A posts, etc. which I read to get
this module working.

=head1 AVAILABILITY

GitHub L<https://github.com/yakubori/Data-ID-URL-Shrink>

=head1 COPYRIGHT

Copyright (C) 2013 Rick Yakubowski (yakubori) <yakubori@cpan.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Rick Yakubowski (yakubori) <yakubori@cpan.org>

=cut
