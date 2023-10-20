package App::Oozie::Deploy::Template::ttree;
$App::Oozie::Deploy::Template::ttree::VERSION = '0.010';
use strict;
use warnings;
use parent qw( App::Oozie::Forked::Template::ttree );

sub new {
    my $class = shift;
    my $log_collector = shift;
    my $self  = $class->SUPER::new(
                    @_,
                );
    $self->{log_collector} = $log_collector,
    $self;
}

sub run {
    my $self = shift;
    my @arg  = @_;
    local @ARGV = @arg;
    $self->SUPER::run();
}

sub emit_warn {
    my $self = shift;
    my $msg  = shift;
    $self->{log_collector}->(
        level => 'warn',
        msg   => $msg,
    );
}

sub emit_log {
    my $self = shift;
    for my $msg ( @_ ) {
        $self->{log_collector}->(
            level => 'info',
            msg   => $msg,
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy::Template::ttree

=head1 VERSION

version 0.010

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
