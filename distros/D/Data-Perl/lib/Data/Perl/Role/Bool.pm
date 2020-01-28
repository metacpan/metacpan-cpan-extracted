package Data::Perl::Role::Bool;
$Data::Perl::Role::Bool::VERSION = '0.002011';
# ABSTRACT: Wrapping class for boolean values.

use strictures 1;

use Role::Tiny;

sub new { my $bool = $_[1] ? 1 : 0; bless(\$bool, $_[0]) }

sub set { ${$_[0]} = 1 }

sub unset { ${$_[0]} = 0 }

sub toggle { ${$_[0]} = ${$_[0]} ? 0 : 1; }

sub not { !${$_[0]} }

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::Bool - Wrapping class for boolean values.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/bool/;

  my $bool = bool(0);

  $bool->toggle; # 1

  $bool->unset; # 0

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with boolean values.

=head1 PROVIDED METHODS

None of these methods accept arguments.

=over 4

=item B<new($value)>

Constructs a new Data::Perl::Collection::Bool object initialized with the passed
in value, and returns it.

=item B<set>

Sets the value to C<1> and returns C<1>.

=item B<unset>

Set the value to C<0> and returns C<0>.

=item B<toggle>

Toggles the value. If it's true, set to false, and vice versa.

Returns the new value.

=item B<not>

Equivalent of 'not C<$value>'.

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

