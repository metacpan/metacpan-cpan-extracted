use strict;
use warnings;

package Code::Statistics::App::Command::collect;
$Code::Statistics::App::Command::collect::VERSION = '1.190680';
# ABSTRACT: the shell command handler for stat collection

use Code::Statistics::App -command;

sub abstract { return 'gather measurements on targets and write them to disk' }

sub opt_spec {
    my ( $self ) = @_;
    my @opts = (
        [ 'dirs=s' => 'the directories in which to to search for perl code files' ],
        [ 'no_dump' => 'prevents writing of measurements to disk' ],
        [ 'relative_paths' => 'switches file paths in dump from absolute to relative format' ],
        [ 'foreign_paths=s' => 'file paths in dump are printed in indicated system format; see File::Spec' ],
        [ 'targets=s' => 'specifies targets that will be looked for inside of files; see C::S::Target::*' ],
        [ 'metrics=s' => 'specifies metrics that be tried to be measured on targets; see C::S::Metric::*' ],
    );
    return @opts;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    return $self->cstat( %{$opt} )->collect;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::App::Command::collect - the shell command handler for stat collection

=head1 VERSION

version 1.190680

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
