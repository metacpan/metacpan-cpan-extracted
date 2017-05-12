#
# AI::ExpertSystem::Advanced::Viewer::Base
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 12/13/2009 15:23:47 PST 15:23:47
package AI::ExpertSystem::Advanced::Viewer::Base;

=head1 NAME

AI::ExpertSystem::Advanced::Viewer::Base - Base class for all views.

=head1 DESCRIPTION

All views that L<AI::ExpertSystem::Advanced> can use should extend from this
class (or from parents that extend from it).

Please note that the methods of this class should not be called in an abstract
context cause otherwise L<AI::ExpertSystem::Advanced> will die.

=cut
use Moose;

our $VERSION = '0.02';

use constant NO_ABSTRACT_CLASS_MSG =>
    qq#Sorry, you can't call the abstract class!#;

=head2 B<debug($msg)>

Will be used to debug any task done by L<AI::ExpertSystem::Advanced>. It only
receives one parameter that is the message to print.

=cut
sub debug {
    confess NO_ABSTRACT_CLASS_MSG;
}

=head2 B<print($msg)>

Will be used to print anything that is not a debug messages. It only receives
one parameter that is the message to print.

=cut
sub print {
    confess NO_ABSTRACT_CLASS_MSG;
}

=head2 B<print_error($msg)>

Will be used to print any error of L<AI::ExpertSystem::Advanced>. It only
receives one parameter that is the message to print.

=cut
sub print_error {
    confess NO_ABSTRACT_CLASS_MSG;
}

=head2 B<ask($message, @options)>

Will be used to ask the user for some information. It will receive a string,
the question to ask and an array of all the possible options.

Please return only one option and this should be any of the ones listed in
C<@options> cause otherwise L<AI::ExpertSystem::Advanced> will die.

=cut
sub ask {
    confess NO_ABSTRACT_CLASS_MSG;
}

=head2 B<explain($yaml_summary)>

Used to explain what happened. The passed argument is a YAML string that has
all the information required to make a good explanation.

=cut
sub explain {
    confess NO_ABSTRACT_CLASS_MSG;
}

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

