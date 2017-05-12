use 5.008;
use strict;
use warnings;

package Data::Semantic::RegexpAdapter;
BEGIN {
  $Data::Semantic::RegexpAdapter::VERSION = '1.101620';
}

# ABSTRACT: Adapter for Regexp::Common patterns
use Regexp::Common;
use parent qw(
  Data::Semantic
  Data::Inherited
);
__PACKAGE__->mk_scalar_accessors(qw(re))->mk_boolean_accessors(qw(keep))
  ->mk_hash_accessors(qw(kept));
use constant LOAD        => '';
use constant REGEXP_KEYS => ();
use constant KEEP_KEYS   => ();

sub init {
    my $self = shift;
    Regexp::Common->import($self->LOAD) if $self->LOAD;
    my @regexp_keys = $self->every_list('REGEXP_KEYS');
    @regexp_keys || die "REGEXP_KEYS is not defined";
    my $re_spec = sprintf '$RE%s', join '' => map { "{$_}" } @regexp_keys,
      $self->flags;
    my $re = eval $re_spec;
    die $@ if $@;
    $self->re($re);
}

# turn the object's settings into a list of flags to be passed to
# Regexp::Common's $RE
sub flags {
    my $self = shift;
    my @flags;
    push @flags => '-keep' if $self->keep;
    @flags;
}

sub is_valid_normalized_value {
    my ($self, $value) = @_;
    my $re = $self->re;
    my $ok = $value =~ /^$re$/;

    # assume {-keep} was given in any case - the user will know whether kept()
    # will return anything useful.
    my %keep;
    @keep{ $self->KEEP_KEYS } =
      map { defined($_) ? $_ : '' } ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
    $self->kept(%keep);
    $ok;
}
1;


__END__
=pod

=head1 NAME

Data::Semantic::RegexpAdapter - Adapter for Regexp::Common patterns

=head1 VERSION

version 1.101620

=head1 METHODS

=head2 LOAD

    use constant LOAD => 'AT::NICAT';

This is the optional name of the Regexp::Common module to load. For example,
if you use a pattern from L<Regexp::Common::AT::NICAT>, you would set this
to C<AT::NICAT>. If you use patterns bundled in the same distribution as
Regexp::Common you can leave it empty.

=head2 REGEXP_KEYS

    use constant REGEXP_KEYS => qw(URI file);

These is the list of keys that you would pass to Regexp::Common's C<$RE>. For
example, if you wanted to match HTTP URIs, you would use C<qw(URI HTTP)>.
Compare with L<Regexp::Common::URI::http>. See L<Regexp::Common> for more
details on this mechanism.

=head2 KEEP_KEYS

    use constant KEEP_KEYS => qw(scheme host port query);

This class supports Regexp::Common's C<-keep> mechanism. C<kept()> returns a
hash of the patterns returned by Regexp::Common. In this list you can specify
the hash keys that C<$1>, C<$2> and so on are mapped to.

=head2 flags

Turns the object's settings into a list of flags to be passed to
Regexp::Common's C<$RE>. For example, Regexp::Common expects a C<{-keep}> key,
but this class has a C<keep()> accessor. If you subclass this class and
add more accessors that correspond to Regexp::Common keys, you need to
override this method and map the attributes to the keys. Be sure to call
C<SUPER::flags()>. See L<Data::Semantic::URI::http> for an example.

=head2 init

FIXME

=head2 is_valid_normalized_value

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
L<http://search.cpan.org/dist/Data-Semantic/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

