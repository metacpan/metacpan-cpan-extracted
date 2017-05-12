package Articulate::Validation::NoScript;
use strict;
use warnings;
use Moo;

=head1 NAME

Articulate::Validation::NoScript

=head1 DESCRIPTION

An example validator to do a rudimentary check to see if the content has the text "<script" in it, to prevent users from injecting scripts directly into your application.

It doesn't thoroughly prevent Javascript injection, an onload attribute might do just as well.

=head1 METHODS

=head3 validate

Returns true if the content contains qr/<script/i; false otherwise.

It does not look at the meta to determine content type so might behave unexpectedly, e.g. if called on plain text.

=cut

sub validate {
  my $self = shift;
  my $item = shift;
  return ( $item->content !~ /<script/i );
}

1;
