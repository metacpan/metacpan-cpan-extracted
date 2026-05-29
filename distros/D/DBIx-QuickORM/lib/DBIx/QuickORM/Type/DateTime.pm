package DBIx::QuickORM::Type::DateTime;
use strict;
use warnings;

our $VERSION = '0.000022';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/parse_conflate_args load_class/;

use parent 'DBIx::QuickORM::Util::Mask';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::DateTime - Lazy DateTime inflate/deflate type.

=head1 DESCRIPTION

A L<DBIx::QuickORM::Role::Type> implementation for date/time columns. The
inflated value is a L<DBIx::QuickORM::Util::Mask> wrapping a L<DateTime>:
the DateTime is B<not> built until the value is actually used (a method call,
etc.), so reading and re-storing a column you never inspect costs nothing.

Stringification always returns the original database string - it never builds
the DateTime - so printing a value is cheap and predictable.

The affinity is C<string>, and the parse/format comes from the dialect
(C<datetime_formatter>).

=cut

sub qorm_affinity { 'string' }

sub qorm_sql_type { 'DATETIME' }

sub qorm_inflate {
    my $params = parse_conflate_args(@_);
    my $val = $params->{value};
    return undef unless defined $val;

    my $class = $params->{class} // __PACKAGE__;

    # Already a lazy mask - leave it alone.
    return $val if blessed($val) && $val->isa('DBIx::QuickORM::Util::Mask');

    my $dialect = $params->{dialect} or croak "The DateTime type requires a dialect to inflate";
    my $fmt = $class->_formatter($dialect);

    my ($string, $generator);
    if (blessed($val) && $val->isa('DateTime')) {
        my $dt = $val;
        $string    = $fmt->format_datetime($dt);
        $generator = sub { $dt };
    }
    else {
        my $raw = "$val";
        $string    = $raw;
        $generator = sub { $fmt->parse_datetime($raw) };
    }

    return DBIx::QuickORM::Util::Mask->new(
        string     => $string,
        generator  => $generator,
        mask_class => $class,
    );
}

sub qorm_deflate {
    my $params = parse_conflate_args(@_);
    my $val   = $params->{value};
    my $class = $params->{class} // __PACKAGE__;
    return undef unless defined $val;

    # A mask we never built -> its stored db string, no parse needed.
    if (blessed($val) && $val->isa('DBIx::QuickORM::Util::Mask')) {
        return $val->qorm_mask_string unless $val->qorm_mask_inflated;
        $val = $val->qorm_unmask;
    }

    # A plain string is already in database form.
    return "$val" unless blessed($val);

    # A real DateTime object -> format it for the database.
    my $dialect = $params->{dialect} or croak "The DateTime type requires a dialect to deflate a DateTime object";
    return $class->_formatter($dialect)->format_datetime($val);
}

sub qorm_compare {
    my $class = shift;
    my ($a, $b) = @_;
    return $class->_compare_key($a) cmp $class->_compare_key($b);
}

# A dialect-free comparison key: a never-built mask uses its stored db string,
# anything else is stringified.
sub _compare_key {
    my $class = shift;
    my ($val) = @_;
    return '' unless defined $val;
    return $val->qorm_mask_string if blessed($val) && $val->isa('DBIx::QuickORM::Util::Mask');
    return "$val";
}

sub _formatter {
    my $class = shift;
    my ($dialect) = @_;
    my $fmt = $dialect->datetime_formatter;
    load_class($fmt) or croak "Could not load datetime formatter '$fmt': $@";
    return $fmt;
}

sub qorm_register_type {
    my $self = shift;
    my ($types, $affinities) = @_;

    my $class = ref($self) || $self;

    $types->{$_} //= $class for qw/datetime timestamp timestamptz date time year/;

    # Match on the column's SQL type (not its name), so variants like
    # "timestamp without time zone" or "timestamp(6)" are picked up too.
    push @{$affinities->{string}} => sub {
        my %params = @_;
        my $type = $params{type};
        $type = $$type if ref($type) eq 'SCALAR';
        return undef unless defined $type;
        return $class if $type =~ m/\b(?:datetime|timestamptz|timestamp|date|time|year)\b/i;
        return undef;
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
