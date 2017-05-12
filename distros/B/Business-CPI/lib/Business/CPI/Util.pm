package Business::CPI::Util;
# ABSTRACT: Utilities for Business::CPI
use warnings;
use strict;
use utf8;
use Class::Load ();

our $VERSION = '0.924'; # VERSION

sub load_class {
    my ($driver_name, $class_name) = @_;
    return Class::Load::load_first_existing_class(
        "Business::CPI::${driver_name}::${class_name}",
        "Business::CPI::Base::${class_name}"
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Util - Utilities for Business::CPI

=head1 VERSION

version 0.924

=head1 METHODS

=head2 load_class

Used to load a class, either a custom class of the gateway, or the default one
in Business::CPI core.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
