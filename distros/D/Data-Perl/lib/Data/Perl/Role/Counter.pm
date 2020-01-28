package Data::Perl::Role::Counter;
$Data::Perl::Role::Counter::VERSION = '0.002011';
# ABSTRACT: Wrapping class for a simple numeric counter.

use strictures 1;

use Role::Tiny;

sub new { bless \(my $n = $_[1]), $_[0] }

sub inc { ${$_[0]} += ($_[1] ? $_[1] : 1) }

sub dec { ${$_[0]} -= ($_[1] ? $_[1] : 1) }

sub reset { ${$_[0]} = 0 }

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::Counter - Wrapping class for a simple numeric counter.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/counter/;

  my $c = counter(4);

  $c->inc;   # $c == 5

  $c->reset; # $c == 0

=head1 DESCRIPTION

This class provides a wrapper and methods for a simple numeric counter.

=head1 PROVIDED METHODS

=over 4

=item B<new($value)>

Constructs a new Data::Perl::Collection::Counter object initialized with the passed
in value, and returns it.

=item B<set($value)>

Sets the counter to the specified value and returns the new value.

This method requires a single argument.

=item B<inc>

=item B<inc($arg)>

Increases the attribute value by the amount of the argument, or by 1 if no
argument is given. This method returns the new value.

This method accepts a single argument.

=item B<dec>

=item B<dec($arg)>

Decreases the attribute value by the amount of the argument, or by 1 if no
argument is given. This method returns the new value.

This method accepts a single argument.

=item B<reset>

Resets the value stored in this slot to its default value, and returns the new
value.

=back

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<MooX::HandlesVia>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

