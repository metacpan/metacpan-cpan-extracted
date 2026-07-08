package DBIx::QuickORM::Type::UUID;
use strict;
use warnings;

our $VERSION = '0.000028';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

use DBIx::QuickORM::Util qw/parse_conflate_args/;

use Scalar::Util qw/blessed/;
use UUID qw/uuid7 parse unparse/;
use Carp qw/croak/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::UUID - UUID inflate/deflate type.

=head1 DESCRIPTION

A L<DBIx::QuickORM::Role::Type> implementation for UUID columns. Values
inflate to the canonical hyphenated string form. Deflation honors the
column affinity: C<string> produces the hyphenated form, C<binary>
produces the packed 16-byte form.

C<qorm_affinity> picks C<string> for native C<uuid> types (and by default),
C<binary> for binary/blob storage. C<qorm_sql_type> uses a native C<uuid>
type when available, otherwise C<VARCHAR(36)>. When registered for autofill
this type claims the C<uuid> SQL type and any column whose name contains
"uuid".

C<new> returns a fresh v7 UUID string; it is handy as a Perl default for a
UUID column.

=cut

sub new { shift; uuid7() }

sub qorm_inflate {
    my $params = parse_conflate_args(@_);
    my $val    = $params->{value};
    return undef unless defined $val;
    my $class  = $params->{class} // __PACKAGE__;

    return $class->looks_like_uuid($val) // $class->looks_like_bin($val) // croak "'$val' does not look like a UUID";
}

sub qorm_deflate {
    my $params   = parse_conflate_args(@_);
    my $val      = $params->{value};
    return undef unless defined $val;
    my $affinity = $params->{affinity} or croak "Could not determine affinity";
    my $class    = $params->{class} // __PACKAGE__;

    if (my $uuid = $class->looks_like_uuid($val)) {
        return $uuid if $affinity eq 'string';

        my $b;
        parse($val, $b);
        return $b;
    }

    if (my $uuid = $class->looks_like_bin($val)) {
        return $val if $affinity eq 'binary';
        return $uuid;
    }

    croak "'$val' does not look like a uuid";
}

sub qorm_compare {
    my $class = shift;
    my ($a, $b) = @_;

    $a = $class->qorm_inflate($a);
    $b = $class->qorm_inflate($b);

    my $da = defined($a);
    my $db = defined($b);

    # Equality contract: true when the two values are the same.
    return $a eq $b if $da && $db;
    return 1 unless $da || $db;    # both undef: equal
    return 0;                      # exactly one defined: not equal
}

sub qorm_affinity {
    my $class = shift;
    my %params = @_;

    if (my $sql_type = $params{sql_type}) {
        return 'string' if lc($sql_type) eq 'uuid';
        return 'binary' if $sql_type =~ m/(bin(ary)?|bytea?|blob)/i;
    }

    if (my $dialect = $params{dialect}) {
        return 'string' if $dialect->supports_type('uuid');
    }

    return 'string';
}

sub qorm_sql_type {
    my $self = shift;
    my ($dialect) = @_;

    if (my $stype = $dialect->supports_type('uuid')) {
        return $stype;
    }

    # Document how to set up binary(16)
    # Basically use the post_column hook in Autofill
    return 'VARCHAR(36)';
}

# looks_like_bin / looks_like_uuid take their argument via pop so they work
# both as functions (looks_like_uuid($v)) and as methods ($class->looks_like_uuid($v)).
sub looks_like_bin {
    my $in = pop;
    use bytes;
    return undef unless length($in) == 16;
    my $s;
    unparse($in, $s);
    return $s;
}

sub looks_like_uuid {
    my $in = pop;
    # Return the canonical (lowercase) hyphenated form so inflation and
    # comparison are case-insensitive and match the form produced from binary.
    return lc($in) if $in && $in =~ m/^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/i;
    return undef;
}

sub qorm_register_type {
    my $self = shift;
    my ($types, $affinities) = @_;

    my $class = ref($self) || $self;

    $types->{uuid} //= $class;

    push @{$affinities->{binary}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/uuid/i;
        return $class if $params{db_name} =~ m/uuid/i;
        return;
    };

    push @{$affinities->{string}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/uuid/i;
        return $class if $params{db_name} =~ m/uuid/i;
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

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
