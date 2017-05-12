use 5.008;
use warnings;
use strict;

package Class::Scaffold::Test;
BEGIN {
  $Class::Scaffold::Test::VERSION = '1.102280';
}
# ABSTRACT: Base classes for framework test classes
use Test::More;
use Class::Value;    # see run() below

# Also inherit from Class::Scaffold::Base so we get a delegate; put it first
# so its new() is found, not the very basic new() from Project::Build::Test
use parent qw(
  Class::Scaffold::Base
  Test::CompanionClasses::Base
);
use constant PLAN => 1;

sub obj_ok {
    my ($self, $object, $object_type_const) = @_;
    isa_ok($object, $self->delegate->get_class_name_for($object_type_const));
}

# Override planned_test_count() with a version that uses every_list().
# Project::Build::Test->planned_test_count() couldn't use that because
# every_list() is implemented in Data::Inherited, which in turn uses
# Project::Build.
sub planned_test_count {
    my $self = shift;
    my $plan;

    # so that PLANs can use the delegate:
    $::delegate = $self->delegate;
    $plan += $_ for $self->every_list('PLAN');
    $plan;
}

sub run {
    my $self = shift;
    $self->SUPER::run(@_);

    # check that test prerequisites are ok
    is($Class::Value::SkipChecks, 1, '$Class::Value::SkipChecks is on');
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Test - Base classes for framework test classes

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 obj_ok

FIXME

=head2 planned_test_count

FIXME

=head2 run

FIXME

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

