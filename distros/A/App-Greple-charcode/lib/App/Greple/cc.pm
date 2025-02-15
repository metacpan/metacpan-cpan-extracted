package App::Greple::cc;

use 5.024;
use warnings;

=encoding utf-8

=head1 NAME

App::Greple::cc - alias module for App::Greple::charcode

=head1 SYNOPSIS

B<greple> B<-Mcc> ...

=head1 SEE ALSO

L<App::Greple::charcode>

=cut

use App::Greple::charcode ':alias';

sub finalize {
    our($mod, $argv) = @_;
    unshift @$argv, '-Mcharcode';
}

1;
