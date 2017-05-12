package App::Prove::Plugin::SetEnv;
{
  $App::Prove::Plugin::SetEnv::VERSION = '0.001';
}

# ABSTRACT: a prove plugin to set environment variables

use strict;
use warnings;

sub load {
    my ($class, $p) = @_;
    foreach my $arg (@{$p->{args}}) {
        my ($var, $val) = split '=', $arg, 2;
        $ENV{$var} = $val;
    }
}


1;

__END__
=pod

=head1 NAME

App::Prove::Plugin::SetEnv - a prove plugin to set environment variables

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # command-line usage
    prove -PSetEnv=TZ=UTC,PATH="./bin:$PATH"

=head1 DESCRIPTION

This L<prove> plugin lets you set environment variables for your test
scripts.  It is particularly handy in C<.proverc>.

=head1 BUGS

Due to the way L<App::Prove> splits argumets to plugins, it is not
possible to set values containing commas.

=head1 SEE ALSO

L<prove>, L<App::Prove/PLUGINS>.

=head1 AUTHOR

Dagfinn Ilmari Mannsåker <ilmari@photobox.com>;

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by PhotoBox Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

