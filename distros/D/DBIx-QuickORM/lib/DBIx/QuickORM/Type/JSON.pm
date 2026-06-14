package DBIx::QuickORM::Type::JSON;
use strict;
use warnings;

our $VERSION = '0.000023';

use DBIx::QuickORM::Util qw/parse_conflate_args/;

use Carp qw/croak/;
use Scalar::Util qw/reftype blessed/;
use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

use Cpanel::JSON::XS qw/decode_json/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::JSON - JSON inflate/deflate type.

=head1 DESCRIPTION

A L<DBIx::QuickORM::Role::Type> implementation that stores Perl data
structures as JSON. Inflation decodes the stored JSON to a Perl reference;
deflation encodes a reference back to JSON. Comparison is done on a
canonical encoding so structurally identical values compare equal.

The affinity is C<string>. C<qorm_sql_type> prefers a native C<jsonb>/
C<json> column type and falls back to C<longtext>/C<text>.

When registered for autofill (C<qorm_register_type>) this type claims the
C<json>/C<jsonb> SQL types and any string column whose name contains
"json".

=cut

# {{{ Shared JSON encoders

my $JSON  = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);
my $CJSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1)->canonical(1);

sub JSON  { shift; $JSON }
sub CJSON { shift; $CJSON }

# }}} Shared JSON encoders

sub qorm_affinity { 'string' }

sub qorm_inflate {
    my $params = parse_conflate_args(@_);
    my $val    = $params->{value};
    return undef unless defined $val;
    my $class  = $params->{class} // __PACKAGE__;

    return $val if ref($val);
    return decode_json($val);
}

sub qorm_deflate {
    my $params   = parse_conflate_args(@_);
    my $val      = $params->{value};
    return undef unless defined $val;
    my $affinity = $params->{affinity} or croak "Could not determine affinity";
    my $class    = $params->{class} // __PACKAGE__;

    if (blessed($val)) {
        my $r = reftype($val) // '';
        if    ($r eq 'HASH')  { $val = {%$val} }
        elsif ($r eq 'ARRAY') { $val = [@$val] }
        else                  { die "Not sure what to do with $val" }
    }

    return $class->JSON->encode($val);
}

sub qorm_compare {
    my $class = shift;
    my ($a, $b) = @_;

    # First decode the json if it is not already decoded
    $a = $class->qorm_inflate($a);
    $b = $class->qorm_inflate($b);

    # Now encode it in canonical form so that identical structures produce identical strings.
    # Another option would be to use Test2::Compare...
    $a = $class->CJSON->encode($a);
    $b = $class->CJSON->encode($b);

    # Equality contract: true when the two values are the same.
    return $a eq $b;
}

sub qorm_sql_type {
    my $self = shift;
    my ($dialect) = @_;

    if (my $stype = $dialect->supports_type('jsonb') // $dialect->supports_type('json')) {
        return $stype;
    }

    my $fallback = $dialect->supports_type('longtext') // $dialect->supports_type('text');
    return $fallback if $fallback;
    die "Could not find usable type for json, no json type, no longtext, and no text";
}

sub qorm_register_type {
    my $self = shift;
    my ($types, $affinities) = @_;

    my $class = ref($self) || $self;

    $types->{json}  //= $class;
    $types->{jsonb} //= $class;

    push @{$affinities->{string}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/json/i;
        return $class if $params{db_name} =~ m/json/i;
        return;
    };
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
