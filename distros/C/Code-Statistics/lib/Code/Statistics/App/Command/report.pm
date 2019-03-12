use strict;
use warnings;

package Code::Statistics::App::Command::report;
$Code::Statistics::App::Command::report::VERSION = '1.190680';
# ABSTRACT: the shell command handler for stat reporting

use Code::Statistics::App -command;

sub abstract { return 'create reports on statistics and output them' }

sub opt_spec {
    my @opts = (
        [ 'quiet' => 'prevents writing of report to screen' ],
        [ 'file_ignore=s' => 'list of regexes matching files that should be ignored in reporting ' ],
    );
    return @opts;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    return $self->cstat( %{$opt} )->report;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::App::Command::report - the shell command handler for stat reporting

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
