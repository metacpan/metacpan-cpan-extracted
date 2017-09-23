use strict;
use warnings;
use utf8;

## no critic (ProhibitSubroutinePrototypes)

package Async::Trampoline::Describe;

=head1 NAME

Async::Trampoline::Describe - describe/it testing function

=head1 DESCRIPTION

=cut

use Test::More;

use Exporter 'import';

our @EXPORT = qw/
    describe
    it
/;

our $_PATH;

=head2 describe

    describe q(name) => sub {
        ...
    };

=cut

sub describe($&) {
    my ($what, $test) = @_;
    local $_PATH = (defined $_PATH) ? "$_PATH\::$what" : $what;
    @_ = ($_PATH, $test);
    goto &subtest;
}

=head2 it

    it q(does something interesting) => sub {
        ...
    };

=cut

sub it($&) {
    my ($behaves, $test) = @_;
    local $_PATH = (defined $_PATH) ? "$_PATH $behaves" : "it $behaves";
    @_ = ($_PATH, $test);
    goto &subtest;
}

1;

__END__

=head1 NAME

Async::Trampoline::Describe - describe/it testing functions



=cut
