package DBIx::QuickORM::Util::Mask;
use strict;
use warnings;

our $VERSION = '0.000027';

use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;
use Carp qw/croak/;
$Carp::Internal{(__PACKAGE__)}++;

use constant STR          => 0;
use constant GEN          => 1;
use constant INFLATED_REF => 2;

use overload(
    fallback => 1,
    '""'   => sub { $_[0]->[STR] },               # never inflates - always the display string
    '0+'   => sub { 0 + $_[0]->qorm_unmask },
    'bool' => sub { 1 },                          # a mask is always a defined wrapper
    '%{}'  => sub { $_[0]->qorm_unmask },          # hash deref delegates to the wrapped object
);

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Util::Mask - Lazily-built wrapper that hides a heavy object
from dumps and stack traces while delegating to it.

=head1 DESCRIPTION

Wraps an object so it does not bloat L<Data::Dumper> output or L<Carp> stack
traces (a single masked L<DateTime>, for example, would otherwise dump
hundreds of lines), while still behaving like the object for method calls.

The wrapped object is built lazily: the generator is not run until the value
is actually used (a method call, numification, etc.). Stringification is the
exception - it returns a fixed display string and never triggers the
generator, so printing a value is always cheap.

The real object lives inside the generator closure, never in a visible slot,
so it stays hidden from dumps even after it has been built.

=head1 SYNOPSIS

    use DBIx::QuickORM::Util::Mask;

    my $mask = DBIx::QuickORM::Util::Mask->new(
        string    => "2026-05-24 12:00:00",   # what it stringifies to
        generator => sub { expensive_parse(...) },
        mask_class => 'My::Subclass',          # optional, defaults to this class
    );

    print "$mask";        # the display string, nothing is built
    $mask->some_method;   # builds the object (once) and delegates

=cut

sub new {
    my $class = shift;
    my %params = @_;

    my $raw = $params{generator} or croak "'generator' is required";
    croak "'generator' must be a coderef" unless ref($raw) eq 'CODE';
    croak "'string' is required" unless defined $params{string};

    my $mask_class = $params{mask_class} // $class;

    # Memoize inside the closure so the built object never lives in a visible
    # slot (keeps it out of dumps even after inflation). INFLATED_REF points at
    # the same lexical flag so callers can peek without forcing a build.
    my $built = 0;
    my $obj;
    my $gen = sub { $built ||= do { $obj = $raw->(); 1 }; $obj };

    return bless(["$params{string}", $gen, \$built], $mask_class);
}

sub qorm_unmask        { $_[0]->[GEN]->() }
sub qorm_mask_string   { $_[0]->[STR] }
sub qorm_mask_inflated { ${$_[0]->[INFLATED_REF]} ? 1 : 0 }

sub isa {
    my $self = shift;

    return 1 if $self->UNIVERSAL::isa(@_);
    return 0 unless blessed($self);

    my $obj = $self->qorm_unmask // return 0;
    return $obj->isa(@_);
}

sub can {
    my $self = shift;

    if (my $sub = $self->UNIVERSAL::can(@_)) { return $sub }
    return undef unless blessed($self);

    my $obj = $self->qorm_unmask // return undef;
    my ($meth) = @_;
    return undef unless $obj->can($meth);

    return set_subname($meth => sub { my $s = shift; $s->qorm_unmask->$meth(@_) });
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;

    (my $meth = $AUTOLOAD) =~ s/.*:://;
    return if $meth eq 'DESTROY';

    my $class = blessed($self) // $self;
    croak qq{Can't locate object method "$meth" via package "$class"}
        unless blessed($self);

    my $obj = $self->qorm_unmask;
    my $sub = $obj->can($meth)
        or croak qq{Can't locate object method "$meth" via package "$class"};

    unshift @_ => $obj;
    goto &$sub;
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
