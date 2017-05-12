package App::SCM::Digest::SCM::Factory;

use strict;
use warnings;

use App::SCM::Digest::SCM::Git;
use App::SCM::Digest::SCM::Hg;

sub new
{
    my ($class, $name) = @_;

    my $pkg = 'App::SCM::Digest::SCM::'.(ucfirst (lc $name));
    return $pkg->new();
}

1;

__END__

=head1 NAME

App::SCM::Digest::SCM::Factory

=head1 DESCRIPTION

Factory class for L<App::SCM::Digest::SCM> implementations.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Takes an implementation name (e.g. 'git', 'hg') as its single
argument.  Returns an instance of the specified implementation.

=back

=cut
