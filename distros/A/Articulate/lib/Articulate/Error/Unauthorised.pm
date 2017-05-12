package Articulate::Error::Unauthorised;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::Unauthorised - represent an error indicating the authorisation header field is missing.

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Unauthorised'>.

=head3 http_code

This defaults to C<401>.

=cut

has '+simple_message' => ( default => 'Unauthorised', );

has '+http_code' => ( default => 401, );

1;
