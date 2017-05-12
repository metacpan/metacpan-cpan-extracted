package Articulate::Error::Internal;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::Internal - represent an error arising due to a fault in the configuration of the server

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Internal Server Error'>.

=head3 http_code

This defaults to C<500>.

=cut

has '+simple_message' => ( default => 'Internal Server Error', );

has '+http_code' => ( default => 500, );

1;
