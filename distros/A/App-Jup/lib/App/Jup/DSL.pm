package App::Jup::DSL;
$App::Jup::DSL::VERSION = '1.01';
# ABSTRACT: heart of jup, dsl for executing a deployment

use Modern::Perl;
use DDP;
use Carp qw(croak);
use charm;
use Import::Into;

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

    croak qq{"$_" is not exported by the $class module} for @args;

    charm->import::into($caller);

    # APIS
    no strict 'refs';
    *{caller() . '::link'} = \&link;

}


sub link {
    my $code = shift;
    for my $link (keys %{$code}) {
        say "Linking application $link";
    }
}

1;

__END__

=pod

=head1 NAME

App::Jup::DSL - heart of jup, dsl for executing a deployment

=head1 link

Links application to project

    set destdir => '/srv/app';
    set workdir => cwd;
    link { nginx => { app_path => get 'destdir' } }

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
