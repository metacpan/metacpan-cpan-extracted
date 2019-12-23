use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Note;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use Data::Validate::CSV::Types -types;
use namespace::autoclean;

has type       => (is => 'ro', isa => Str);
has [qw(
	via canonical rights motivation body target
	creator generator audience
)]             => (is => 'ro', isa => Any);

1;
