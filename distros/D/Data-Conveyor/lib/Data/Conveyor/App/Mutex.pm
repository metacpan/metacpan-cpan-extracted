use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Mutex;
BEGIN {
  $Data::Conveyor::App::Mutex::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system
use Error::Hierarchy::Util 'assert_defined';
use Data::Conveyor::Mutex;
use parent 'Class::Scaffold::App::CommandLine';

# define the 'mutex' accessor via 'get_set_std', not via 'object =>
# Data::Conveyor::Mutex', because we don't always have a mutex object,
# depending on the environment. In DESTROY() we do 'return unless
# $self->mutex', which would still trigger the mutex object constructor - so
# we avoid that.
__PACKAGE__->mk_scalar_accessors(qw(mutex_key))
  ->mk_framework_object_accessors(mutex => 'mutex');

sub app_init {
    my $self = shift;
    $self->SUPER::app_init(@_);
    if ($self->delegate->respect_mutex) {
        assert_defined $self->mutex_key, 'called without set mutex_key.';
        $self->mutex->application($self->mutex_key);
        $self->mutex->mutex_getconf;
        exit 0 unless $self->mutex->get_mutex;
    }
}
DESTROY {
    my $self = shift;
    return unless $self->delegate->respect_mutex && $self->mutex;
    $self->mutex->release_mutex;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::App::Mutex - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

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

