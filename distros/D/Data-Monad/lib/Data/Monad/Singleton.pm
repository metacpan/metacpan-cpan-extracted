package Data::Monad::Singleton;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;
use Exporter qw/import/;

our @EXPORT = qw/singleton/;

sub singleton { __PACKAGE__->new }

my $instance = bless \(my $x = '*'), __PACKAGE__;
sub new { $instance }

sub unit { singleton }

sub flat_map { singleton }

1;

__END__

=head1 NAME

Data::Monad::Singleton - The singleton monad.

=head1 SYNOPSIS

  use Data::Monad::Singleton;

  my $singleton = Data::Monad::Singleton->unit("Hello")
                                        ->flat_map(sub { length $_[0] });

  $singleton == singleton and die "All operations are ignored.";

=head1 DESCRIPTION

Data::Monad::Singleton maps all values to the one value.
It collapses the structure of original computations.

=head1 METHODS

=over 4

=item $m = singleton;

Represents the value of this class.

=item $m = Data::Monad::Singleton->new;

Represents the value of this class.

=item unit

=item flat_map

Overrides methods of Data::Monad::Base::Monad.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

