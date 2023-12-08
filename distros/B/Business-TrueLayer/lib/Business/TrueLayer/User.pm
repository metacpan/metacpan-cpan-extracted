package Business::TrueLayer::User;

=head1 NAME

Business::TrueLayer::User - class representing a user
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $User = Business::TrueLayer::User->new(
        name => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use DateTime::Format::DateParse;

=head1 ATTRIBUTES

=over

=item id (Str)

=item name (Str)

=item email (Str)

=item phone (Str)

=item date_of_birth (DateTime, coerced via DateTime::Format::DateParse)

=back

=cut

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has [ qw/ name email phone / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

class_type 'DateTime';

coerce 'DateTime'
    => from 'Str'
    => via {
        DateTime::Format::DateParse->parse_datetime( $_ );
    }
;

has 'date_of_birth' => (
    is       => 'ro',
    isa      => 'DateTime',
    coerce   => 1,
    required => 0,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

=cut

1;
