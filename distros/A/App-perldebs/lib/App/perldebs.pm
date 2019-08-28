package App::perldebs;
$App::perldebs::VERSION = '0.002';
use strict;
use warnings;

use Module::CPANfile;

use Moo;

sub run {
    my ($self) = @_;

    # read perl modules as arguments or from ./cpanfile
    my @modules = @ARGV;

    unless (@ARGV) {
        my $prereqs = Module::CPANfile->load->prereq_specs;

        for my $phase (%$prereqs) {
            push @modules, keys %{ $prereqs->{$phase}->{requires} };
        }
    }

    exit 1 unless @modules;

    # locate Debian packages that include these modules
    my $cmd = 'dh-make-perl locate ' . join( ' ', @modules ) . ' 2>/dev/null';
    open my $fh, "-|", $cmd;
    my @packages;
    foreach (<$fh>) {

        # this ignores core packages
        # see DhMakePerl::Command::locate for details
        push @packages, $2 if m{(.+) is in (.+) package};
    }

    print join( ' ', sort @packages );
}

return 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perldebs

=head1 VERSION

version 0.002

=head2 run

Runs dh-make-perl to locate the Perl modules.  Which modules are to be
located is specified either on the command line or in cpanfile.

=head1 AUTHOR

Gregor Goldbach ☕ <post@gregor-goldbach.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
