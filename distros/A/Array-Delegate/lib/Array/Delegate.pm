package Array::Delegate;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.01';

use vars '$AUTOLOAD';

sub new {
    my $class = shift;
    my @self  = @{+shift};
    bless \@self, $class;
};

sub AUTOLOAD {
    my $method = (split '::', $AUTOLOAD)[-1];
    [map { $_->$method(@_) } @{+shift}];
}

1;
__END__

=head1 NAME

Array::Delegate - Perl extension for delegating methods calls on a ArrayRef to its elements

=head1 SYNOPSIS

    package Employee;

    sub new { my $class = shift; return bless {@_}, $class; }

    sub pay_salary { print "Yay, fresh money for", shift->{name}, "\n" }

    package Company;

    sub employees {
        return Array::Delegate->new( [Employee->new( name => 'Tim' ), Employee->new( name => 'Bob' )] );
    }

    package SomeModule;

    Company->new()->employees()->pay_salary(); # pays all employees

=head1 DESCRIPTION

This is just to create a bit of syntactict sugar for OO interfaces.

In a a method that normally returns an ArrayRef of Objects, you can return an instance of Array::Delegate,
which is still and array, just blessed. Then, the caller can use

    $results = $array->foo

Instead of

	$results = [ map $_->foo, @$array ];

=head2 METHODS

=head3 new( $arrayRef )

Simply blesses $arrayRef to be a Array::Delegate object.

=head1 AUTHOR

Alaska Saedelere, E<lt>alaska.saedelere@googlemail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alaska Saedelere

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
