package Acme::Curse;

=head1 NAME

Acme::Curse - Remove the blessing that lay on references

=head1 SYNOPSIS

    use Acme::Curse qw(curse);

    my $unblessed_ref = curse($object);

=head1 DESCRIPTION

Did you ever want to droo the blessing of an object? Well, now you can:
Acme::Curse unblesses reference by returning a shallow, non-blessed copy
of the object.

Currently only references to scalar, hashes, arrays and code objects can
be unblessed.

Exported subs:

=over 4

=item curse

Unblesses a reference to an object.

=back

=head1 BUGS

None known, but surely there are many.

=head1 AUTHOR

Moritz Lenz, L<http://perlgeek.de/>, L<http://perl-6.de/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Moritz Lenz

This module is free software; it can be used under the same terms as perl
itself.

=cut

use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(reftype);

our @EXPORT_OK = qw(curse);

sub curse {
    my ($obj) = @_;
    my $type = reftype($obj);
    if ($type eq 'HASH') {
        return { %$obj };
    } 
    elsif ($type eq 'ARRAY') {
        return [ @$obj ];
    } elsif ($type eq 'SCALAR'){
        my $copy = $$obj;
        return \$copy;
    }
    elsif ($type eq 'CODE') {
        return sub { goto &$obj };
    }
    else {
        die "Don't know how to curse ${type}s";
    }
}

1;
