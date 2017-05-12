use 5.008;
use warnings;
use strict;

package Class::Scaffold::ConstantImporter;
BEGIN {
  $Class::Scaffold::ConstantImporter::VERSION = '1.102280';
}
# ABSTRACT: Import environment constants as simple functions
use Devel::Caller qw(caller_args);

sub import {
    shift;  # we don't need the package name
    my $callpkg = caller(0);
    no strict 'refs';

    # For each requested symbol, install a proxy sub into the caller's
    # namespace. When invoked, it will get the caller's $self and retrieve the
    # symbol's value from the caller's delegate. It will then replace itself
    # with a sub that just returns that value.
    #
    # The value is cached so that if the same constant is imported in
    # different packages we still only make one call to the delegate.
    #
    # That way the symbol can be used without the $self->delegate->... part.
    # You have to make sure that when the symbol is first used, you do it from
    # within a method whose $self has access to the delegate.
    #
    # The delegate is cached so that later this mechanism can be used even
    # from within subs that don't have access to the delegate.
    our %cache;
    for my $symbol (@_) {
        *{"${callpkg}::${symbol}"} = sub {
            unless (exists $cache{$symbol}) {
                my $caller_self = (caller_args(1))[0];
                our $delegate ||= $caller_self->delegate;
                $cache{$symbol} = $delegate->$symbol;
            }
            no warnings 'redefine';
            *{"${callpkg}::${symbol}"} = sub { $cache{$symbol} };
            $cache{$symbol};
        };
    }
}
1;

__END__
=pod

=head1 NAME

Class::Scaffold::ConstantImporter - Import environment constants as simple functions

=head1 VERSION

version 1.102280

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

