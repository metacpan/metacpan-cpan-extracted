use strict;
use warnings;
package Dancer::Logger::Spinner;
BEGIN {
  $Dancer::Logger::Spinner::VERSION = '0.02';
}
# ABSTRACT: Show a spinner in the console on Dancer log messages!

use base 'Dancer::Logger::Abstract';

sub init {
    my $self = shift;
    $self->{'spinner_chars'} = [ '\\', '|', '/', '-', 'x' ];
    $self->{'spinner_count'} = 0;
}

sub _log {
    my $self = shift;
    $self->advance_spinner();
}

sub advance_spinner {
    my $self  = shift;
    my $count = $self->{'spinner_count'};
    my @chars = @{ $self->{'spinner_chars'} };

    # these chars lifted from Brandon L. Black's Term::Spinner
    print STDERR "\010 \010";
    print STDERR $chars[$count];

    # if we reached over the array end, let's get back to the start
    ++$count > $#chars and $count = 0;

    # increment the counter and update the hash
    $self->{'spinner_count'} = $count;
}

sub DESTROY {
    print STDERR "\n";
}

1;



=pod

=head1 NAME

Dancer::Logger::Spinner - Show a spinner in the console on Dancer log messages!

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # in your Dancer app:
    setting logger => 'spinner';

    # or in your Dancer config file:
    logger: 'spinner'

Et voila!

=head1 DESCRIPTION

When using this logger and running your application in the terminal, you will
see a text spinner running on each message it gets. If you have a page with a
lot of request, and they will come in fast, you'll see the spinner running. If
you have an app with very little requests in each page or if it is slow, the
spinner will run slowly.

Each request matches another rotation of the spinner.

=head1 SUBROUTINES/METHODS

=head2 init

Sets the spinner's characters and position.

=head2 advance_spinner

Advanced the spinner onefold by cleaning a terminal line and printing the next
spinner position.

=head2 _log

Gets a message to log and calls C<advance_spinner>.

=head1 SEE ALSO

The Dancer Advent Calendar 2010.

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

