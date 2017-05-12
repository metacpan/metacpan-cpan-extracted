package Articulate::Error::BadRequest;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::BadRequest - represent an error arising from unacceptable input

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Bad Request'>.

=head3 http_code

This defaults to C<400>.

=cut

has '+simple_message' => ( default => 'Bad Request', );

has '+http_code' => ( default => 400, );

1;
