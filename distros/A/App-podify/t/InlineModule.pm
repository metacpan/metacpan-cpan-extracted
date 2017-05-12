package Some::Module;

use strict;
use warnings;

=head1 NAME

Some::Module - Should be moved to bottom

=cut

our $VERSION = '0.2';

=head1 ATTRIBUTES

=head2 cool

Aweful documentation.

=cut

has cool => 123;

=head1 METHODS

=head2 too_cool

=cut

sub too_cool {
}

sub not_documented {
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

__DATA__
This should be the last line
