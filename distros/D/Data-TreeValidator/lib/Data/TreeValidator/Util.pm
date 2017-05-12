package Data::TreeValidator::Util;
{
  $Data::TreeValidator::Util::VERSION = '0.04';
}
# ABSTRACT: Helpful utilities for working with tree validators
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw( fail_constraint )]
};

{
    package Data::TreeValidator::ConstraintError;
{
  $Data::TreeValidator::ConstraintError::VERSION = '0.04';
}
    use Moose;
    with 'Throwable';

    # XXX I think Throwable should provide this as a role - submit patch
    use overload
      q{""}    => 'as_string',
      fallback => 1;
    has 'message' => ( is => 'ro' );
    sub as_string { shift->message }
}

sub fail_constraint {
    Data::TreeValidator::ConstraintError->new(
        message => shift )->throw;
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Util - Helpful utilities for working with tree validators

=head1 DESCRIPTION

A collection of helpful utilities for working with tree validators.

All methods below are available for import into calling modules.

=head1 METHODS

=head2 fail_constraint($message)

Raises an exception with the given C<$message>. Avoids extra information such as
a stack trace or line numbers

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

