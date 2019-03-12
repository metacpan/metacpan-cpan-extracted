use strict;
use warnings;

package Code::Statistics::App::Command;
$Code::Statistics::App::Command::VERSION = '1.190680';
# ABSTRACT: base class for commands

use App::Cmd::Setup -command;


sub cstat {
    return shift->app->cstat( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Statistics::App::Command - base class for commands

=head1 VERSION

version 1.190680

=head2 cstat
    Dispatches to the Code::Statistics object creation routine.

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
