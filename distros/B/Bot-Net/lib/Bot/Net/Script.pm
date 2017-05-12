use strict;
use warnings;

package Bot::Net::Script;
use base qw/ App::CLI /;

=head1 NAME

Bot::Net::Script - implementation of the Bot::Net command-line interface

=head1 SYNOPSIS

  bin/botnet <command> <options>

=head1 DESCRIPTION

This is a command-line interface handler based on L<App::CLI>. This module doesn't really do a lot more than just inherit from L<App::CLI> and handle a few special cases.

=cut

sub prepare {
    my $self = shift;

    if ($ARGV[0] =~ /--?h(elp?)/i) {
        $ARGV[0] = 'help';
    }

    return $self->SUPER::prepare(@_);
}

=head1 SEE ALSO

L<App::CLI>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified or distributed under the same terms as Perl itself.

=cut

1;
