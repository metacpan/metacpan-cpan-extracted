use 5.008;
use strict;
use warnings;

package Data::Conveyor::Environment_TEST;
BEGIN {
  $Data::Conveyor::Environment_TEST::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Test 'throws2_ok';
use parent 'Data::Conveyor::Test';
use constant PLAN => 1;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $env = $self->make_real_object;
    throws2_ok { $env->make_stage_object('foobar'); }
    'Error::Hierarchy::Internal::ValueUndefined',
      qr/no stage class name found for \[foobar\]/,
      'make a stage object for a nonexistent stage';

    # We release the cache for stage class names here. The bug which prompted
    # this is a bit involved. We ran all inline pod tests - via
    # 00podtests.t -, and this test ran first, so $env was of ref
    # Data::Conveyor::Environment. The above code calls
    # make_stage_object(), which indirectly caches the stage class name
    # results, so only ST_TXSEL is cached - since that's the only thing
    # defined in the environment's STAGE_CLASS_NAME_HASH().
    #
    # The next test (from another pod test file) used the config file
    # mechanism, which pointed to a config file from a different package,
    # and that config file uses a different environment. However, the
    # settings from that environment weren't seen because of the cached.
    $env->release_stage_class_name_hash;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Environment_TEST - Stage-based conveyor-belt-like ticket handling system

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

