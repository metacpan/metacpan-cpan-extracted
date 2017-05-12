use 5.008;
use strict;
use warnings;

package Class::Accessor::Constructor::Base;
BEGIN {
  $Class::Accessor::Constructor::Base::VERSION = '1.111590';
}
# ABSTRACT: Support for an automated dirty flag in hash-based classes
use Data::Inherited;
use Class::Accessor::Complex;
use Tie::Hash;
our @ISA = qw(Tie::StdHash Data::Inherited Class::Accessor::Complex);
__PACKAGE__
    ->mk_boolean_accessors(qw(dirty))
    ->mk_set_accessors(qw(hygienic unhygienic));
use constant HYGIENIC => ( qw(dirty hygienic unhygienic));

# STORE() always gets called with this package as ref($self), not with the
# original class. So we rely on constructor_with_dirty telling us what the
# original class was in order to determine whether or not a key should cause
# the dirty flag to be set.
# Every accessor in an object causes the object's dirty flag to be set, except
# those mentioned in HYGIENIC. If you want only one or a few accessors to use
# the dirty flag and don't want to list all the other ones in HYGIENIC, we
# have an UNHYGIENIC list, just like HYGIENIC. It is also set from within
# constructor_with_dirty. In STORE(), we check whether there the unhygienic
# list is non-empty. If so, only dirty the object with keys from that list.
# Otherwise check hygienic. That is, UNHYGIENIC supersedes HYGIENIC. Obviously
# it doesn't make sense to have both in an object. The mechanism is similar to
# Apache's allow/deny.
sub STORE {
    my ($self, $key, $value) = @_;
    if ($self->size_unhygienic > 0) {
        $self->set_dirty if $self->unhygienic_contains($key);
    } else {
        $self->set_dirty unless $self->hygienic_contains($key);
    }
    $self->{$key} = $value;
}
1;


__END__
=pod

=head1 NAME

Class::Accessor::Constructor::Base - Support for an automated dirty flag in hash-based classes

=head1 VERSION

version 1.111590

=head1 SYNOPSIS

  my $class = '...';
  my %self = ();
  tie %self, 'Class::Accessor::Constructor::Base';
  my $self = bless \%self, $class;

=head1 DESCRIPTION

See L<Class::Accessor::Constructor::Base>'s C<constructor_with_dirty> for a
usage.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Constructor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Class-Accessor-Constructor/>.

The development version lives at L<http://github.com/hanekomu/Class-Accessor-Constructor>
and may be cloned from L<git://github.com/hanekomu/Class-Accessor-Constructor.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

