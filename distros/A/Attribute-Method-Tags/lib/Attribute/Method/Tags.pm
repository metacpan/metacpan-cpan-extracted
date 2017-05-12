package Attribute::Method::Tags;

use strict;
use warnings;

use Attribute::Handlers;
use Attribute::Method::Tags::Registry;
use Carp qw( croak );

our $VERSION = '0.11';

sub import {
    # add this package to callers @ISA, as attributes only work via inheritance

    no strict 'refs';

    my $caller = caller;
    push @{ "${ caller }::ISA" }, __PACKAGE__;
}

sub Tags : ATTR(CODE,RAWDATA) {
    my ( $class, $symbol, undef, undef, $data, undef, $file, $line ) = @_;

    $data =~ s/^\s+//g;

    my @tags = split /\s+/, $data;

    if ( $symbol eq 'ANON' ) {
        die "Cannot tag anonymous subs at file $file, line $line\n";
    }

    my $method = *{ $symbol }{ NAME };

    {           # block for localising $@
        local $@;

        Attribute::Method::Tags::Registry->add(
            $class,
            $method,
            \@tags,
        );
        if ( $@ ) {
            croak "Error in adding tags: $@";
        }
    }
}

1;

__END__

=head1 NAME

Attribute::Method::Tags - Attribute interface for adding tags to methods.

=head1 SYNOPSIS

 package Bleh;

 # using Attribute::Method::Tags will add to callers ISA
 use Attribute::Method::Tags;

 sub foo : Tags( quick fast loose ) {
     ...
 }

 sub bar : Tags( quick ) {
     ...
 }

 # can use Attribute::Method::Tags::Registry to query tags on all classes.

=head1 DESCRIPTION

This class permits adding arbitrary tags to methods, via an attribute
interface.  The tags can later be queried via the
L<Attribute::Method::Tags::Registry> class.

Note that since attributes only work via inheritance, 'use'ing this class
will add it to the @ISA of the composing class.

=head1 ATTRIBUTES

The only usage of this class is through the 'Tags' attribute against subs.
A list of arbitrary alphanumeric tags can be given as parameters, seperated
by whitespace.  Each of the tags will be added to the registry contained
in L<Attribute::Method::Tags::Registry>, and can be queried via that class.

=head1 CAVEATS

As attributes are handled at compilation time, actions such as requiring
classes or eval'ing code during runtime won't play well when used with
attributes.  This can be gotten around by doing such actions with a
BEGIN block.  If this isn't possible, a workaround is to define your
dynamic methods without any attributes, the use
L<Attribute::Method::Tags::Registry> 'add' method to explicitly tag
the method.

=head1 SEE ALSO

=over 4

=item Attributes::Method::Tags::Registry

Registry class, that permits querying of all tags across all packages/methods.

=item Test::Class::Filter::Tags

The original impetus for this module.  Permits specifying tags on test methods,
and then running only a subset of tests, matching a given tag list.

=back

=head1 AUTHOR

Mark Morgan <makk384@gmail.com>

=head1 BUGS

Please send bugs or feature requests through to
bugs-Attribute-Method-Tags@rt.rt.cpan.org or through web interface
L<http://rt.cpan.org> .

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Mark Morgan, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

