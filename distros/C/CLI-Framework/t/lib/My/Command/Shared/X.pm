package My::Command::Shared::X;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

sub run {
    my ($self, $opts, @args) = @_;

    return 'running ' . $self->name() . ' from package ' . __PACKAGE__ . "\n";
}

#-------
1;

__END__

=pod

=head1 PURPOSE

Test/demonstrate a CLIF setup involving a non-standard command search path.

=cut
