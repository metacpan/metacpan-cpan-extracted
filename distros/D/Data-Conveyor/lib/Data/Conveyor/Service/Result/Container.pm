use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Result::Container;
BEGIN {
  $Data::Conveyor::Service::Result::Container::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

#
# Contains a list of other result objects, which can include other
# containers, since they derive from the same subclass as "normal" service
# result objects such as scalars and tables.
use YAML;
use parent 'Data::Conveyor::Service::Result';

# don't subclass Data::Container, since we have a slightly different API - we
# use 'result' instead of 'items', for example.
__PACKAGE__->mk_array_accessors(qw(result));

# concatenate the stringifications of the result list
sub result_as_string {
    my $self = shift;
    join "\n" => map { "$_" } $self->result;
}

# Here exception() is a method, not an attribute. You can't set an exception
# on a container directly; rather, if elements of the result list have
# exceptions, they will be returned in an exception container. If there are no
# exceptions in the results, undef will be returned.
sub exception {
    my $self = shift;
    my @exception = grep { defined } map { $_->exception } $self->result;
    return unless @exception;
    my $container = $self->delegate->make_obj('exception_container');
    $container->items(@exception);
    $container;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Result::Container - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 result_as_string

FIXME

=head2 exception

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

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

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

