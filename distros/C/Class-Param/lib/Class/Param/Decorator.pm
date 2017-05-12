package Class::Param::Decorator;

use strict;
use warnings;
use base 'Class::Param::Base';

our $AUTOLOAD;

use Params::Validate qw[];

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self  = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            {
                type      => Params::Validate::OBJECT,
                isa       => 'Class::Param::Base',
                optional  => 0
            }
        ],
        called  => "$class\::new"
    );

    return bless( $self, $class )->initialize(@_);
}

sub initialize {
    return $_[0];
}

sub decorated {
    return $_[0]->[0];
}

sub get    { return shift->decorated->get    (@_) }
sub set    { return shift->decorated->set    (@_) }
sub has    { return shift->decorated->has    (@_) }
sub count  { return shift->decorated->count  (@_) }
sub clear  { return shift->decorated->clear  (@_) }
sub names  { return shift->decorated->names  (@_) }
sub remove { return shift->decorated->remove (@_) }

sub AUTOLOAD {
    my $self   = shift;
    my $method = substr( $AUTOLOAD, rindex( $AUTOLOAD, ':' ) + 1 );
    return $self->decorated->$method(@_);
}

sub DESTROY { }

1;

__END__

=head1 NAME

Class::Param::Decorator - Class Param Decorator Class

=head1 SYNOPSIS

    package MyDecorator;
    use base 'Class::Param::Decorator';

    sub get {
        # do something
    }

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Constructor. Takes one argument, an instance of L<Class::Param::Base>.

=item initialize

Called after construction with same arguments given to constructor, should return the instance.

=item decorated

Returns the decorated L<Class::Param::Base> instance.

=item get

This method simply performs C<$self->decorated->get> and returns the result.

=item set

This method simply performs C<$self->decorated->set> and returns the result.

=item has

This method simply performs C<$self->decorated->has> and returns the result.

=item count

This method simply performs C<$self->decorated->count> and returns the result.

=item clear

This method simply performs C<$self->decorated->clear> and returns the result.

=item names

This method simply performs C<$self->decorated->names> and returns the result.

=item remove

This method simply performs C<$self->decorated->remove> and returns the result.

=back

=head1 SEE ASLO

L<Class::Param>.

L<Class::Param::Base>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
