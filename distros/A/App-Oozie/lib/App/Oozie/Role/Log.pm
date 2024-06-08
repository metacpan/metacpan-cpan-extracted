package App::Oozie::Role::Log;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Util::Log4perl;
use Log::Log4perl;
use Moo::Role;

sub logger {
    state $init;
    state $logger;

    my $self = shift;

    return $logger if $logger;

    if ( ! $init ) {
        Log::Log4perl->init( App::Oozie::Util::Log4perl->new->find_template );
        $init++;
    }

    $logger //= Log::Log4perl->get_logger;

    return $logger;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Log

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use Moo::Role;
    with 'App::Oozie::Role::Log';

    sub some_method {
        my $self = shift;
        $self->logger->info("Hello");
    }

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 NAME

App::Oozie::Role::Log - Internal logger.

=head1 Methods

=head2 logger

=head1 SEE ALSO

L<App::Oozie>.

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
