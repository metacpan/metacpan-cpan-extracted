package Data::Perl::Role::Code;
$Data::Perl::Role::Code::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl coderefs.

use strictures 1;

use Role::Tiny;

sub new { my $cl = shift; bless $_[0], $cl }

sub execute { $_[0]->(@_[1..$#_]) }

#sub execute_method { $_[0]->($_[0], @_[1..$#_]) }
sub execute_method { die 'This remains unimplemented for now.' }

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::Code - Wrapping class for Perl coderefs.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/code/;

  my $code = code(sub { 'Foo'} );

  $code->execute(); # returns 'Foo';

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with Perl coderefs.

=head1 PROVIDED METHODS

=over 4

=item B<new($coderef)>

Constructs a new Data::Perl::Code object, initialized to $coderef as passed in,
and returns it.

=item B<execute(@args)>

Calls the coderef with the given args.

=item B<execute_method(@args)>

Calls the coderef with the the instance as invocant and given args. B<This is
currently disabled and triggers a die due to implementation details yet to be
resolved.>

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

