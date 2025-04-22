package Data::Pageset::Exponential;

# ABSTRACT: Page numbering for very large page numbers

use v5.20;

use Moo;

use List::Util 1.33 qw( all min );
use PerlX::Maybe    qw( maybe );
use POSIX           qw( ceil floor );
use MooX::Aliases;
use MooX::TypeTiny;
use Types::Common 2.000000 qw( is_Int Int ArrayRef is_HashRef PositiveOrZeroInt PositiveInt );

use experimental qw( postderef signatures );


use asa 'Data::Page';

use namespace::autoclean;

# RECOMMEND PREREQ: Type::Tiny::XS
# RECOMMEND PREREQ: Ref::Util::XS

our $VERSION = 'v0.4.1';


has total_entries => (
    is      => 'rw',
    isa     => PositiveOrZeroInt,
    default => 0,
);


has entries_per_page => (
    is      => 'rw',
    isa     => PositiveInt,
    default => 10,
);


has first_page => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);


has current_page => (
    is      => 'rw',
    isa     => Int,
    lazy    => 1,
    default => \&first_page,
    coerce  => sub($val) { floor( $val // 0 ) },
);


has exponent_base => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 10,
);


has exponent_max => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 3,
);


has pages_per_exponent => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 3,
);


has pages_per_set => (
    is      => 'lazy',
    isa     => PositiveInt,
    alias   => 'max_pages_per_set',
    builder => sub($self) {
        use integer;
        my $n = $self->pages_per_exponent * ( $self->exponent_max + 1 );
        return ( $n - 1 ) * 2 + 1;
    },
);


has series => (
    is      => 'lazy',
    isa     => ArrayRef [Int],
    builder => sub($self) {
        use integer;

        my @series;

        my $n = $self->exponent_base;
        my $m = $self->exponent_max;

        my $j = 0;
        while ( $j <= $m ) {

            my $i = $n**$j;
            my $a = $i;
            my $p = $self->pages_per_exponent;

            while ( $p-- ) {
                push @series, $a - 1;
                $a += $i;
            }

            $j++;

        }

        my @prevs = map { -$_ } reverse @series[ 1 .. $#series ];

        return [ @prevs, @series ];
    },
);

around current_page => sub( $next, $self, @args ) {

    # N.B. unlike Data::Page, setting a value outside the first_page
    # or last_page will not return that value.

    my $page = $self->$next(@args);

    return $self->first_page if $page < $self->first_page;

    return $self->last_page if $page > $self->last_page;

    return $page;
};


sub entries_on_this_page($self) {
    if ( $self->total_entries ) {
        return $self->last - $self->first + 1;
    }
    else {
        return 0;
    }
}


sub last_page($self) {
    return $self->total_entries
      ? ceil( $self->total_entries / $self->entries_per_page )
      : $self->first_page;
}


sub first($self) {
    if ( $self->total_entries ) {
        return ( $self->current_page - 1 ) * $self->entries_per_page + 1;
    }
    else {
        return 0;
    }
}


sub last($self) {
    if ( $self->current_page == $self->last_page ) {
        return $self->total_entries;
    }
    else {
        return $self->current_page * $self->entries_per_page;
    }
}


sub previous_page($self) {
    my $page = $self->current_page;

    return $page > $self->first_page
      ? $page - 1
      : undef;
}


sub next_page($self) {
    my $page = $self->current_page;

    return $page < $self->last_page
      ? $page + 1
      : undef;
}


sub splice( $self, $items ) {
    my $last = min( $self->last, scalar( $items->@* ) );

    return $last
      ? @{$items}[ $self->first - 1 .. $last - 1 ]
      : ();
}


sub skipped($self) {
    return $self->total_entries
      ? $self->first - 1
      : 0;
}

# Ideally, we'd use a trigger instead, but Moo does not pass the old
# value to a trigger.

around entries_per_page => sub( $next, $self, @args ) {
    if (@args) {

        my ($value) = @args;

        my $first = $self->first;

        $self->$next($value);

        $self->current_page( $self->first_page + $first / $value );

        return $value;
    }
    else {

        return $self->$next;

    }
};


sub pages_in_set($self) {
    use integer;

    my $first = $self->first_page;
    my $last  = $self->last_page;
    my $page  = $self->current_page;

    return [
        grep { $first <= $_ && $_ <= $last }
        map  { $page + $_ } @{ $self->series }
    ];
}


sub previous_set($self) {
    my $page = $self->current_page - ( 2 * $self->pages_per_exponent ) - 1;
    return $page < $self->first_page
      ? undef
      : $page;
}


sub next_set($self) {
    my $page = $self->current_page + ( 2 * $self->pages_per_exponent ) - 1;
    return $page > $self->last_page
      ? undef
      : $page;
}


sub change_entries_per_page( $self, $value ) {
    $self->entries_per_page($value);

    return $self->current_page;
}


sub BUILDARGS( $class, @args ) {

    if ( @args == 1 && is_HashRef(@args) ) {
        return $args[0];
    }

    if ( @args && ( @args <= 3 ) && all { is_Int($_) } @args ) {

        return {
            total_entries => $args[0],
            maybe
              entries_per_page => $args[1],
            maybe current_page => $args[2],
        };

    }

    return {@args};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Pageset::Exponential - Page numbering for very large page numbers

=head1 VERSION

version v0.4.1

=head1 SYNOPSIS

  my $pager = Data::Pageset::Exponential->new(
    total_entries => $total_entries,
    entries_per_page => $per_page,
  );

  $pager->current_page( 1 );

  my $pages = $pager->pages_in_set;

  # Returns
  # [ 1, 2, 3, 10, 20, 30, 100, 200, 300, 1000, 2000, 3000 ]

=head1 DESCRIPTION

This is a pager designed for paging through resultsets that contain
hundreds if not thousands of pages.

The interface is similar to L<Data::Pageset> with sliding pagesets.

=head1 ATTRIBUTES

=head2 C<total_entries>

This is the total number of entries.

It is a read/write attribute.

=head2 C<entries_per_page>

This is the total number of entries per page. It defaults to C<10>.

It is a read/write attribute.

=head2 C<first_page>

This returns the first page. It defaults to C<1>.

=head2 C<current_page>

This is the current page number. It defaults to the L</first_page>.

It is a read/write attribute.

=head2 C<exponent_base>

This is the base exponent for page sets. It defaults to C<10>.

=head2 C<exponent_max>

This is the maximum exponent for page sets. It defaults to C<3>, for
pages in the thousands.

It should not be greater than

    ceil( log( $total_pages ) / log(10) )

however, larger numbers will increase the size of L</pages_in_set>.

=head2 C<pages_per_exponent>

This is the number of pages per exponent. It defaults to C<3>.

=head2 C<pages_per_set>

This is the maximum number of pages in L</pages_in_set>. It defaults
to

  1 + 2 * ( $pages_per_exponent * ( $exponent_max + 1 ) - 1 )

which for the default values is 23.

This should be an odd number.

This was renamed from L</max_pages_per_set> in v0.3.0.

=head2 C<max_pages_per_set>

This is a deprecated alias for L</pages_per_set>.

=head1 METHODS

=head2 C<entries_on_this_page>

Returns the number of entries on the page.

=head2 C<last_page>

Returns the number of the last page.

=head2 C<first>

Returns the index of the first entry on the L</current_page>.

=head2 C<last>

Returns the index of the last entry on the L</current_page>.

=head2 C<previous_page>

Returns the number of the previous page.

=head2 C<next_page>

Returns the number of the next page.

=head2 C<pages_in_set>

Returns an array reference of pages in the page set.

=head2 C<previous_set>

This returns the first page number of the previous page set, for the
first exponent.

It is added for compatability with L<Data::Pageset>.

=head2 C<next_set>

This returns the first page number of the next page set, for the first
exponent.

It is added for compatability with L<Data::Pageset>.

=for Pod::Coverage isa

=for Pod::Coverage series

=for Pod::Coverage splice

=for Pod::Coverage skipped

=for Pod::Coverage change_entries_per_page

=for Pod::Coverage BUILDARGS

=head1 KNOWN ISSUES

=head2 Differences with Data::Page

This module is intended as a drop-in replacement for L<Data::Page>.
However, it is based on a complete rewrite of L<Data::Page> using
L<Moo>, rather than extending it.  Because of that, it needs to fake
C<@ISA>.  This may break some applications.

Otherwise, it has the following differences:

=over

=item *

The attributes have type constraints.  Invalid data may throw a fatal
error instead of being ignored.

=item *

Setting the L</current_page> to a value outside the L</first_page> or
L</last_page> will return the first or last page, instead of that
value.

=back

=head2 Differences with Data::Pageset

This module can behave like L<Data::Pageset> in C<slide> mode if the
exponent is set to C<1>:

  my $pager = Data::Pageset::Exponential->new(
    exponent_max       => 1,
    pages_per_exponent => 10,
    pages_per_set      => 10,
  );

=head1 SUPPORT FOR OLDER PERL VERSIONS

Since v0.8.0, the this module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

=over

=item *

L<Data::Page>

=item *

L<Data::Pageset>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Data-Pageset-Exponential>
and may be cloned from L<git://github.com/robrwo/Data-Pageset-Exponential.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Data-Pageset-Exponential/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.  Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Test code was adapted from L<Data::Page> to ensure compatability.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
