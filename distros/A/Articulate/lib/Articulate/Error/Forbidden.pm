package Articulate::Error::Forbidden;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::Unauthorised - represent an error arising from a forbidden action

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Forbidden'>.

=head3 http_code

This defaults to C<403>.

=cut

has '+simple_message' => ( default => 'Forbidden', );

has '+http_code' => ( default => 403, );

1;
