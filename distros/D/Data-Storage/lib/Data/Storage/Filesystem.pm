use 5.008;
use strict;
use warnings;

package Data::Storage::Filesystem;
BEGIN {
  $Data::Storage::Filesystem::VERSION = '1.102720';
}
# ABSTRACT: Base class for filesystem-based storages
use parent qw(Data::Storage Class::Accessor::Complex);
use constant DEFAULTS => (mode => '0664');
__PACKAGE__
    ->mk_hash_accessors(qw(trans_cache))
    ->mk_scalar_accessors(qw(fspath mode));

sub connect {
    my $self = shift;
    die sprintf "invalid target directory: '%s'", $self->fspath
      || ''
      unless defined $self->fspath && -d $self->fspath && -w _;
}

# we will keep this very simple and naive for now,
# just fulfilling our current, very limited needs.
# hence: no fooling around, i.e. changing the base
# directory while operating etc.
sub cache_put {
    my ($self, $key, $rec) = @_;
    $self->trans_cache->{$key} = ref $rec ? $rec : [$rec];
}

sub cache_get {
    my ($self, $key) = @_;
    my $rec =
      exists $self->trans_cache->{$key}
      ? $self->trans_cache->{$key}
      : [];
    wantarray ? @$rec : $rec->[0];
}

sub cache_rmv {
    my ($self, $key) = @_;
    delete $self->trans_cache->{$key};
}

sub cache_lst {
    map { @$_ } shift->trans_cache_values;
}

sub rollback {
    shift->trans_cache_clear;
}

sub commit {
    my $self = shift;
    return 1 unless scalar $self->trans_cache_keys;
    my $failed;
    for my $rec ($self->cache_lst) {
        my $handle;
        open($handle, sprintf ">%s", $rec->filename) || do {
            ++$failed;
            last;
        };
        print $handle $rec->data;
        close($handle) || do {
            ++$failed;
            last;
        };
        chmod $rec->mode, $rec->filename;
        $rec->stored(1);
    }
    if ($failed) {
        unlink $_->filename for (grep { $_->stored } $self->cache_lst);
        $self->rollback;
        return 0;
    }
    $self->rollback;
    1;
}

sub signature {
    my $self = shift;
    sprintf "%s,fspath=%s", $self->SUPER::signature(), $self->fspath;
}
1;


__END__
=pod

=head1 NAME

Data::Storage::Filesystem - Base class for filesystem-based storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 cache_get

FIXME

=head2 cache_lst

FIXME

=head2 cache_put

FIXME

=head2 cache_rmv

FIXME

=head2 commit

FIXME

=head2 connect

FIXME

=head2 rollback

FIXME

=head2 signature

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

