package Articulate::Error::NotFound;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::NotFound - represent an error indicating the requested content does not exist.

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Not Found'>.

=head3 http_code

This defaults to C<404>.

=cut

has '+simple_message' => ( default => 'Not found', );

has '+http_code' => ( default => 404, );

1;
