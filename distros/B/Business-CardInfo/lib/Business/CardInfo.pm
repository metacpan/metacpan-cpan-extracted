package Business::CardInfo;
{
  $Business::CardInfo::VERSION = '0.12';
}
use Moose;
use Moose::Util::TypeConstraints;

subtype 'CardNumber'
  => as 'Int'
   => where { validate($_) };

coerce 'CardNumber'
  => from 'Str'
   => via {
    my $cc = shift;
    $cc =~ s/\s//g;
    return $cc;
   };

no Moose::Util::TypeConstraints;

has 'country' => (
  isa => 'Str',
  is  => 'rw',
  default => 'UK'
  );

has 'number' => (
  isa => 'CardNumber',
  is  => 'rw',
  required => 1,
  coerce => 1,
  trigger => sub { shift->clear_type }
);

has 'type' => (
  isa => 'Str',
  is  => 'rw',
  lazy_build => 1,
);

sub _build_type {
  my $self = shift;
  my $number = $self->number;
  #my @grp = (substr($number,0,1), substr($number,0,4),substr($number,0,6));
  return "Visa Debit" if $self->_search([
    400626, 409400 .. 409402, 412285,412286, 413733 .. 413737,
    413787 .. 413787, 418760, 419176 .. 412279, 419772, 420672, 421592 .. 421594, 
    422793, 423769, 431072, 444001, 444005 .. 444008, 446200 .. 446211,
    446213 .. 446254, 446257 .. 446272,446274 .. 446283, 446286, 446294, 450875, 
    453978, 453979, 454313, 454432 .. 454435, 454742, 456725 .. 456745, 
    465830 .. 465879, 465901 .. 465950,475110 .. 475159, 475710 .. 475759, 
    476220 .. 476269, 476340 .. 476389, 484427, 
    490960 .. 490979, 492181 .. 492182, 492186, 498824, 499902, 465942,
    407704, 407705, 408367, 456705, 456706, 474503,
    474551, 475183, 499844 .. 499846, 460024, 421682, 441078, 
    458046, 480240, 499806, 484412, 484415, 484417, 495065, 495067, 
    495090 .. 495094, 446291, 446292, 408456, 408457, 459338, 459339,
    459340, 459362, 459364, 459364, 459389, 459499, 459500, 459501,
    459511, 459512, 459566, 459567, 459568, 489342, 459600 .. 459799
  ]);
  return "Visa Electron" if $self->_search([
    417500, 400115, 400837 .. 400839, 412921 .. 412923, 417935, 419740, 
    419741, 419773 .. 419776, 424519, 424962, 424963, 444000,
    484428 .. 484455, 491730 .. 491759, 491880, 4917, 4913,
    4508, 4844,  484406 .. 484411, 484413, 484414, 484418 .. 484426,
    437860, 459472]);
  return "MasterCard Debit" if $self->_search([
    512499, 512746, 516001, 516730, 516979, 517000, 517049, 524342, 527591,
    535110 .. 535309, 535420 .. 535819, 537210 .. 537609, 557347 .. 557496,
    557498 .. 557547]);
  return "Visa" if $self->_search([qw/4/]);
  return "MasterCard" if $self->_search([51 .. 55]);
  return "Maestro"
    if $self->_search([ 6759, 490303, 493698, 493699, 
                        633302 .. 633349 ]);
  return "International Maestro"
    if $self->_search([ 500 .. 509,5600 .. 5899, 60 .. 69, 676770, 676774 ]);
  return "AMEX" if $self->_search([qw/34 37/]);
  return "Diners Club" if $self->_search([2014,2149,46,55,3600]);
  return "Discover" if $self->_search([622126 .. 622925,6011, 644 .. 649, 65]);
  return "JCB" if $self->_search([3528 .. 3589]);
  return "Laser" if $self->_search([qw/6304 6706 6771 6709/]);
  return "Unknown";
}

sub _search {
  my ($self,$arr) = @_;
  foreach(@{$arr}) {
    return 1 if $self->number =~ /^$_/;
  }
  return 0;
}

sub validate {
  my $number = shift;
  my $num_length = length($number);
  return unless $num_length > 12;
  my ($i, $sum, $weight);
  for ($i = 0; $i < $num_length - 1; $i++) {
    $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
    $sum += (($weight < 10) ? $weight : ($weight - 9));
  }
  return substr($number, -1) == (10 - $sum % 10) % 10 ? 1 : 0;
}

=head1 NAME

Business::CardInfo - Get/Validate data from credit & debit cards

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use Business::CardInfo;

  my $card_info = Business::CardInfo->new(number => '4917 3000 0000 0008');
  print $card_info->type, "\n"; # prints Visa Electron

  $card_info->number('5404 0000 0000 0001');
  print $card_info->type, "\n"; # prints MasterCard

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 country

=head2 number

=head2 type

Possible return values are:

  Visa Electron
  Visa Debit
  Visa
  MasterCard
  MasterCard Debit
  Diners Club
  Maestro
  International Maestro
  AMEX
  Discover
  JCB
  Unknown

=head1 METHODS

=head2 validate

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-cardtype at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-CardInfo>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::CardInfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-CardInfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-CardInfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-CardInfo>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-CardInfo>

=back

=head1 AUTHORS

  purge: Simon Elliott <cpan@browsing.co.uk>

  wreis: Wallace Reis <reis.wallace@gmail.com>

=head1 ACKNOWLEDGEMENTS

  To Airspace Software Ltd <http://www.airspace.co.uk>, for the sponsorship.

=head1 LICENSE

  This library is free software under the same license as perl itself.

=cut

1;
