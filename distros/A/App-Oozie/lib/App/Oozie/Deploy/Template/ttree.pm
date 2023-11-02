package App::Oozie::Deploy::Template::ttree;

use strict;
use warnings;
use parent qw( App::Oozie::Forked::Template::ttree );

our $VERSION = '0.015'; # VERSION

sub new {
    my($class, $log_collector, @pass_through) = @_;
    my $self  = $class->SUPER::new(
                    @pass_through,
                );
    $self->{log_collector} = $log_collector;
    return $self;
}

sub run {
    my($self, @args) = @_;
    local @ARGV = @args;
    return $self->SUPER::run();
}

sub emit_warn {
    my($self, $msg) = @_;
    return$self->{log_collector}->(
        level => 'warn',
        msg   => $msg,
    );
}

sub emit_log {
    my($self, @msgs) = @_;
    for my $msg ( @msgs ) {
        $self->{log_collector}->(
            level => 'info',
            msg   => $msg,
        );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Template::ttree

=head1 VERSION

version 0.015

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
