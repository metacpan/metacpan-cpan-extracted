#
# AI::ExpertSystem::Advanced::Viewer::Terminal
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 12/13/2009 15:44:23 PST 15:44:23
package AI::ExpertSystem::Advanced::Viewer::Terminal;

=head1 NAME

AI::ExpertSystem::Advanced::Viewer::Terminal - Viewer for terminal

=head1 DESCRIPTION

Extends from L<AI::ExpertSystem::Advanced::Viewer::Base> and its main purpose is
to interact with a (console) terminal.

=cut
use Moose;
use Term::UI;
use Term::ReadLine;

extends 'AI::ExpertSystem::Advanced::Viewer::Base';

our $VERSION = '0.02';

=head1 Attribtes

=over 4

=item B<readline>

A L<Term::ReadLine> instance.

=back

=cut
has 'readline' => (
        is => 'ro',
        isa => 'Term::ReadLine');

=head1 Methods

=head2 B<debug($msg)>

Basically just prints the given C<$msg> but prepends the "DEBUG" string to it.

=cut
sub debug {
    my ($self, $msg) = @_;
    print "DEBUG: $msg\n";
}

=head2 B<print($msg)>

Simply prints the given C<$msg>.

=cut
sub print {
    my ($self, $msg) = @_;
    print "$msg\n";
}

=head2 B<print_error($msg)>

Will prepend the "ERROR:" word to the given message and then will call
C<print()>.

=cut
sub print_error {
    my ($self, $msg) = @_;
    $self->print("ERROR: $msg");
}

=head2 B<ask($message, @options)>

Will be used to ask the user for some information. It will receive a string,
the question to ask and an array of all the possible options.

=cut
sub ask {
    my ($self, $msg, $options) = @_;

    my %valid_choices = (
        'Y' => '+',
        'N' => '-',
        'U' => '~');

    my $reply = $self->{'readline'}->get_reply(
            prompt => $msg . ' ',
            choices => [qw|Y N U|]);
    return $valid_choices{$reply};
}

=head2 B<explain($yaml_summary)>

Explains what happened.

=cut
sub explain {
    my ($self, $summary) = @_;

    print $summary;
}


# Called when the object is created
sub BUILD {
    my ($self) = @_;

    $self->{'readline'} = Term::ReadLine->new('questions');
}

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
