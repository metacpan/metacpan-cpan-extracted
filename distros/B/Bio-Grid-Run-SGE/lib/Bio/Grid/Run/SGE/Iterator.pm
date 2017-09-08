package Bio::Grid::Run::SGE::Iterator;

use warnings;
use strict;
use Carp;

our $VERSION = '0.060'; # VERSION

sub new {
    my $class = shift;

    my %args;
    if(@_ == 1 && ref($_[0])) {
        %args = %{$_[0]};
    } else {
        %args = @_;
    }
    
    my $mode = delete $args{'mode'};

    my $module;
    if($mode =~ /^\+/) {
        $module = $mode;
    } else {
        $module = 'Bio::Grid::Run::SGE::Iterator::' . $mode;
    }
    _load_module($module);

    return $module->new(%args);
}

sub _load_module {
    my ( $module ) = @_;

    eval "require $module";
    if ($@) {
        confess "Failed to load module $module. $@";
    }
    return;
}

1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Iterator - Provides an interface to load iterator classes.

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<< $idx = Bio::Grid::Run::SGE::Iterator->new(mode => $mode, ...) >>

Creates a new iterator object. The iterator mode C<$mode> corresponds to the
iterator name in the C<Bio::Grid::Run::SGE::Iterator::*> namespace. With
C<Bio::Grid::Run::SGE::Iterator->new(mode = 'Consecutive')>, one gets a object of
type C<Bio::Grid::Run::SGE::Iterator::Consecutive> back.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut

