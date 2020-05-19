package Daemonise::Plugin::Paralleliser;

use Mouse::Role;

# ABSTRACT: Daemonise plugin to parallelise certain tasks easily

use Parallel::ForkManager;


has 'worker' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 5 },
);


has 'pm' => (
    is  => 'rw',
    isa => 'Parallel::ForkManager',
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring Paralleliser plugin") if $self->debug;

    return;
};


sub parallelise {
    my ($self, $code, @input) = @_;

    $self->pm(Parallel::ForkManager->new($self->worker));

    foreach my $input (@input) {
        $self->pm->start and next;

        # disable cron locking on configure and unlocking on destruction
        $self->is_cron(0);

        # reconfigure to setup eventually broken connections
        $self->configure(1);

        # do not respond to previously setup TERM and INT signal traps
        $SIG{QUIT} = 'IGNORE';    ## no critic
        $SIG{TERM} = 'IGNORE';    ## no critic
        $SIG{INT}  = 'IGNORE';    ## no critic

        $code->($input);

        $self->pm->finish;
    }
    $self->pm->wait_all_children;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::Paralleliser - Daemonise plugin to parallelise certain tasks easily

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('Paralleliser')
    $d->worker(5);
    $d->configure;
    
    my @input = ('kiwi', 'fern', 'maori', 'marae');
    $d->parallelise(\&loop, @input);
    
    sub loop {
        print shift;
    }

=head1 ATTRIBUTES

=head2 worker

=head2 pm

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 parallelise

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
