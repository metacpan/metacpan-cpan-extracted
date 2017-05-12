use strict;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types
$Data::Rx::CoreType::VERSION = '0.200007';
use parent 'Data::Rx::CommonType::EasyNew';

use Carp ();

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType - base class for core Rx types

=head1 VERSION

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
