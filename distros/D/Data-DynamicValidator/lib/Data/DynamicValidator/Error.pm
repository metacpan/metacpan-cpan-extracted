package Data::DynamicValidator::Error;
{
  $Data::DynamicValidator::Error::VERSION = '0.03';
}
# ABSTRACT: Class holds validation error: reason and location

use strict;
use warnings;

use overload fallback => 1, q/""/ => sub { $_[0]->to_string };

sub new {
    my ($class, $reason, $path) = @_;
    my $self = {
        _reason => $reason,
        _path   => $path,
    };
    bless $self => $class;
}


sub to_string{ $_[0]->{_reason} };


sub reason { $_[0]->{_reason} };



sub path { $_[0]->{_path} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DynamicValidator::Error - Class holds validation error: reason and location

=head1 VERSION

version 0.03

=head1 METHODS

=head2 to_string

Stringizes to reason by default

=head2 reason

Returns the human-readable error description

=head2 path

Returns the path object, pointing to the error location

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
