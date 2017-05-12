package Articulate::Error::AlreadyExists;
use strict;
use warnings;

use Moo;
extends 'Articulate::Error';

=head1 NAME

Articulate::Error::AlreadyExists - represent an error arising from an attempt to create content which already exists

=cut

=head3 DESCRIPTION

This class extends Articulate::Error and merely sets two default values:

=head3 simple_message

This defaults to C<'Already exists'>.

=head3 http_code

This defaults to C<409>. This code is shared with other errors which reflect conflicting actions taken on resources.

=cut

has '+simple_message' => ( default => 'Already exists', );

has '+http_code' => ( default => 409, );

1;
