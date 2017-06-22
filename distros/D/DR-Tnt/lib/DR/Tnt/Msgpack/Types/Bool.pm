use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack::Types::Bool;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Scalar::Util ();
use feature 'state';

sub new {
    my ($class, $value) = @_;

    $value = $value ? 1 : 0;
    bless \$value => ref($class) || $class;
}

sub TO_MSGPACK {
    my ($self) = @_;
    return pack 'C', 0xC3 if $$self;
    return pack 'C', 0xC2;
}

sub TO_JSON {
    my ($self) = @_;

    state ($true, $false);

    unless (defined $true) {
        if (eval "require JSON::XS; 1") {
            $true = JSON::XS::true();
            $false = JSON::XS::false();
        } elsif (eval "require JSON; 1") {
            $true = JSON::true();
            $false = JSON::false();
        } else {
            croak "JSON or JSON::XS must be installed";
        }
    }

    return $true if $$self;
    return $false;
}

=head1 NAME

DR::Tnt::Msgpack::Types::Bool - container for bool.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack::Types::Bool;

    my $o = DR::Tnt::Msgpack::Types::Bool->new(1);
    my $blob = msgpack($o);

=head1 DESCRIPTION

See L<DR::Tnt::Msgpack::Types>.

=cut

1;
