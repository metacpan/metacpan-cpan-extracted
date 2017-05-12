package Attribute::Context;

use strict;

no warnings 'redefine';
use Attribute::Handlers;
use vars qw($VERSION);
$VERSION = '0.042';

my $_setup = sub {
    my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;

    my $subroutine;
    {
        no strict 'refs';
        $subroutine = $package . '::' . *{$symbol}{NAME};
    }
    if ( 'ARRAY' eq ref $data ) {
        if ( @$data % 2 ) {
            die
              "$attr arguments to $subroutine must be a single argument or an even sized list";
        }
        my %hash = @$data;
        $data = \%hash;
    }
    elsif ( 'Custom' eq $attr ) {
        $data = { class => $data };
    }
    else {
        $data = $data ? { $data => 1 } : {};
    }
    return $package, $subroutine, $symbol, $referent, $data;
};

my $_hash_branch_exists;
$_hash_branch_exists = sub {
    my ( $hash, $branch ) = @_;
    return 1 unless @$branch;   # we got to the end of the branch successfully
    my $key = shift @$branch;
    return unless exists $hash->{$key};
    return $_hash_branch_exists->( $hash->{$key}, $branch );
};

my $_void_handler = sub {
    my ( $subroutine, $data ) = @_;
    if ( $data->{NOVOID} ) {
        die "You may not call $subroutine() in void context";
    }
    elsif ( $data->{WARNVOID} ) {
        warn "Useless use of $subroutine() in void context";
    }
    return;
};

sub Arrayref : ATTR(CODE) {
    my ( $package, $subroutine, $symbol, $referent, $data ) = $_setup->(@_);

    *$symbol = sub {
        local *__ANON__ = '__ANON__Arrayref_wrapper';
        my @results = $referent->(@_);
        return $_void_handler->( $subroutine, $data )
          unless defined wantarray;
        return wantarray ? @results : \@results;
    };
}

sub Last : ATTR(CODE) {
    my ( $package, $subroutine, $symbol, $referent, $data ) = $_setup->(@_);

    *$symbol = sub {
        local *__ANON__ = '__ANON__Last_wrapper';
        my @results = $referent->(@_);
        return $_void_handler->( $subroutine, $data )
          unless defined wantarray;
        if (wantarray) {
            return @results;
        }
        elsif (@results) {
            return $results[-1];
        }
        else {
            return;
        }
    };
}

sub First : ATTR(CODE) {
    my ( $package, $subroutine, $symbol, $referent, $data ) = $_setup->(@_);

    *$symbol = sub {
        local *__ANON__ = '__ANON__First_wrapper';
        my @results = $referent->(@_);
        return $_void_handler->( $subroutine, $data )
          unless defined wantarray;
        if (wantarray) {
            return @results;
        }
        elsif (@results) {
            return $results[0];
        }
        else {
            return;
        }
    };
}

sub Count : ATTR(CODE) {
    my ( $package, $subroutine, $symbol, $referent, $data ) = $_setup->(@_);

    *$symbol = sub {
        local *__ANON__ = '__ANON__Count_wrapper';
        my @results = $referent->(@_);
        return $_void_handler->( $subroutine, $data )
          unless defined wantarray;
        return wantarray ? @results : scalar @results;
    };
}

sub Custom : ATTR(CODE) {
    my ( $package, $subroutine, $symbol, $referent, $data ) = $_setup->(@_);
    my $class = $data->{class};
    unless ($class) {
        die "No class specified for $subroutine Custom attribute";
    }

   # we walk the symbol table because a package declaration in another package
   # won't necessarily be reflected in %INC
    my $sym_table_package = "${class}::";
    my @keys = split /(?<=::)/, $sym_table_package;
    unless ( $_hash_branch_exists->( \%::, \@keys ) ) {
        eval "use $class";
        die $@ if $@;
    }
    unless ( $class->can('new') ) {
        die "Cannot find constructor 'new' for $class";
    }

    *$symbol = sub {
        local *__ANON__ = '__ANON__Count_wrapper';
        my @results = $referent->(@_);
        return $_void_handler->( $subroutine, $data )
          unless defined wantarray;
        return wantarray ? @results : $class->new( \@results );
    };
}

1;

__END__

=head1 NAME

Attribute::Context - Perl extension for automatically altering subroutine behavior
based upon context

=head1 SYNOPSIS

  use base 'Attribute::Context';

  sub foo    : Arrayref(NOVOID)  {...}
  sub bar    : Arrayref          {...}
  sub baz    : First(NOVOID)     {...}
  sub quux   : Count             {...}
  sub thing  : Custom(My::Class) {...}
  sub script : Custom(class => 'My::Class', NOVOID => 1) {...}

=head1 DESCRIPTION

C<Attribute::Context> creates attributes for subroutines to alter their behavior
based upon their calling context.  Three contexts are recognized:

=head2 Contexts

=over 4

=item * list

 my @array = foo();

Currently it is assumed that subroutines returning using these attributes will
by default return a list.  A scalar or void context will alter their return
values.

=item * scalar

 my $scalar = foo();

Scalar context assumes that the result of the function call are being assigned
to a scalar value.

=item * void

 foo();

Void context is a dangerous thing, so all attributes may have a C<NOVOID>
specification.  If defined as C<NOVOID>, calling the function in void context
will be fatal.

Alteranately, a C<WARNVOID> specification may be given.  A C<WARNVOID> function
called in void context will only emit a warning.

=back

=head2 Attributes

=over 4

=item * Arrayref

Functions with this attribute are assumed to return an array.  If called in
scalar context, they will return a reference to that array.

For example, the following function will return the reverse of an array, or a
reference to the reverse of that array.  Calling it in void context will be 
fatal:

 sub reverse_me : Arrayref(NOVOID)
 {
     return reverse @_;
 }

 my $reversed_reference = reverse_me(qw(1 2 3));
 reverse_me(qw(1 2 3)); # this is fatal

To allow this function to be called in void context, simply remove the
C<NOVOID> designation:

 sub reverse_me : Arrayref
 {
     return reverse @_;
 }
 reverse_me(qw(1 2 3)); # a no-op, but not fatal

=item * Last

Same as C<Arrayref> but returns the last item in the array when called in 
scalar context.

=item * First

Same as C<Arrayref> but returns the first item in the array when called in 
scalar context (like C<CGI::param>).

=item * Count

Same as C<Arrayref> but returns the number of items in the array when called in
scalar context.

=item * Custom

This is a very experimental feature which is likely to change.

This attribute expects a class name.  The class will be loaded, if required.
The class must have a constructor named C<new> and it must take an array
reference.

 sub thing : Custom(My::Class) {
     return  @_;
 }
 my $thing = thing(@array);

The above method will result in the return value of C<My::Class-E<gt>new(\@_)>
being assingned to I<$thing>.

Note that the Custom attribute typically takes a single argument of a class
name.  If you need to specify C<NOVOID> or C<WARNVOID>, use named arguments as
follows:

 sub foo : Custom(class => 'Some::Class', NOVOID => 1)   {...}
 sub bar : Custom(class => 'Some::Class', WARNVOID => 1) {...}

=back

=head1 CAVEATS

Your subroutines are expected to return a list or an array.  Do not use
wantarry in your subroutines as wantarray will always return true.

=head1 EXPORT

Nothing.

=head1 SEE ALSO

C<Attribute::Handlers>

=head1 AUTHOR

Curtis "Ovid"  Poe, E<lt>eop_divo_sitruc@yahoo.comE<gt>

Reverse "eop_divo_sitruc" to send me email.

=head1 BUGS

Probably.  This is B<alpha> software.  The interface may change, the available
attributes may change and the name may even change.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
