use v5.36;

package DBIx::Squirrel::Util;

use Data::Dumper qw();
use Exporter     qw(import);
use Ref::Util    qw(is_arrayref is_coderef is_hashref is_ref);
use Sub::Util    qw(set_subname subname);

use DBIx::Squirrel::Errors qw(croakf);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    canonical
    install_sub
    is_name
    iterator_going
    shift_attrs
    split_attrs
    split_stages
    unwrap_values
);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Return options as a string, the same for the same options.
sub canonical ($options) {
    return Data::Dumper->new([$options])->Indent(0)->Sortkeys(1)->Terse(1)->Dump;
}

# Install a subroutine by its full name. An anonymous one is given that
# name, for stack traces; a named one keeps its own.
sub install_sub ($name, $code) {
    set_subname($name, $code)
        if subname($code) =~ m( :: __ANON__ \z )x;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    *{ $name } = $code;
    return;
}

# Return true if a name can be a subroutine's.
sub is_name ($name) {
    return $name =~ m( \A [^\W\d] \w* \z )x;
}

# Return the iterator going through a statement handle's results, if one
# has results left to hand out.
sub iterator_going ($sth) {
    my $iterator = $sth->{private_ekorn}{Iterator} or return;
    return $iterator->{done} ? () : $iterator;
}

# Take the attributes off the front of a list of arguments, if they're
# there: a hash reference, or undef, as the DBI allows. An array reference
# or a plain value there is a bind value, and is left in place.
sub shift_attrs ($args) {
    return unless @$args;
    my $first = $args->[0];
    return shift @$args if !defined $first || is_hashref($first);
    croakf 'Expected a reference to a HASH or ARRAY'
        if is_ref($first) && !is_arrayref($first);
    return;
}

# Split attributes into the DBI's and DBIx::Squirrel's own, those starting
# "ekorn_", and return a reference to each. With no attributes, there are
# none for the DBI: undef, as the DBI takes.
sub split_attrs ($attrs) {
    my %dbi   = %{ $attrs // {} };
    my %ekorn = map { ($_ => delete $dbi{$_}) } grep { m( \A ekorn_ )x } keys %dbi;
    return $attrs && \%dbi, \%ekorn;
}

# Take the code references off the end of a list of arguments, and return
# them.
sub split_stages ($args) {
    my $n = @$args;
    $n -= 1 while $n && is_coderef($args->[$n - 1]);
    return splice @$args, $n;
}

# Return the bind values given, or those in an array reference given
# alone, unless it's a value itself: given to a statement taking one
# value, it's that value if the statement takes a list, as a list
# placeholder does, or if the driver is DBD::Pg, which binds an array
# reference as a PostgreSQL array, as it would with the DBI. The driver's
# name is given, code returning how many values the statement takes, and
# the statement's map of its list placeholders, if it has any.
sub unwrap_values ($driver, $taken, $lists, @args) {
    return @args
        unless @args == 1 && is_arrayref($args[0]);
    return @args
        if ($lists || $driver eq 'Pg') && $taken->() == 1;
    return @{ $args[0] };
}

1;
__END__

=encoding utf8

=for stopwords PostgreSQL

=head1 NAME

DBIx::Squirrel::Util - helpers shared by DBIx::Squirrel's modules

=head1 DESCRIPTION

Functions DBIx::Squirrel's modules share, exported on request. They're
for DBIx::Squirrel itself, not for use elsewhere, and may change without
notice.

=head1 FUNCTIONS

=over

=item canonical

    $string = canonical(\%options);

Returns options as a string, the same for the same options, for the
DBI's caches to key on.

=item install_sub

    install_sub($full_name, $code);

Installs a subroutine by its full name, naming an anonymous one so.

=item is_name

    $bool = is_name($name);

Returns true if a name can be a subroutine's.

=item iterator_going

    $iterator = iterator_going($sth);

Returns the iterator going through a statement handle's results, if one
has results left to hand out, or nothing.

=item shift_attrs

    $attrs = shift_attrs(\@args);

Takes the attributes off the front of a list of arguments, if they're
there: a hash reference, or C<undef>.

=item split_attrs

    ($dbi_attrs, $ekorn_attrs) = split_attrs(\%attrs);

Splits attributes into the DBI's and DBIx::Squirrel's own, those
starting C<ekorn_>.

=item split_stages

    @stages = split_stages(\@args);

Takes the code references off the end of a list of arguments, and
returns them.

=item unwrap_values

    @values = unwrap_values($driver, $taken, $lists, @values);

Returns the bind values given, or those in an array reference given
alone, unless it's the one value of a statement taking one: a list, for
a list placeholder, or, with DBD::Pg, a PostgreSQL array.

=back

=head1 DIAGNOSTICS

=over

=item Expected a reference to a HASH or ARRAY

The first argument after a statement was a reference, but not to a hash
or an array, as L<DBIx::Squirrel::db/do> describes.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
