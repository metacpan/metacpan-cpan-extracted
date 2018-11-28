package Bio::Grid::Run::SGE::Index;

use warnings;
use strict;
use Carp;

our $VERSION = '0.066'; # VERSION

sub new {
    my $class = shift;

    my %args;
    if(@_ == 1 && ref($_[0])) {
        %args = %{$_[0]};
    } else {
        %args = @_;
    }

    if($args{'approx_chunk_size'}) {
        warn "approx_chunk_size IS DEPRECATED, USE CHUNK SIZE";
        $args{'chunk_size'} = $args{'approx_chunk_size'};
    }
    
    my $format = delete $args{'format'};

    my $module;
    if($format =~ s/^\+//) {
        $module = $format;
    } else {
        $module = 'Bio::Grid::Run::SGE::Index::' . $format;
    }
    _load_module($module);

    return $module->new(%args);
}

sub _load_module {
    my ( $module ) = @_;

    eval "require $module; 1";
    if ($@) {
        confess "Failed to load module $module. $@";
    }
    return;
}

1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Index - Provides an interface to load index classes.

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<< $idx = Bio::Grid::Run::SGE::Index->new(format => $format, ...) >>

Creates a new index object. The index format C<$format> corresponds to the
index name in the C<Bio::Grid::Run::SGE::Index::*> namespace. With
C<Bio::Grid::Run::SGE::Index->new(format = 'General')>, one gets a object of
type C<Bio::Grid::Run::SGE::Index::General> back.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut

