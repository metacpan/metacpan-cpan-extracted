package App::GHPT::WorkSubmitter::Role::Question;

use App::GHPT::Wrapper::OurMoose::Role;

our $VERSION = '1.000012';

use Term::CallEditor qw( solicit );
use Term::Choose qw( choose );

requires 'ask';

has changed_files => (
    is       => 'ro',
    isa      => 'App::GHPT::WorkSubmitter::ChangedFiles',
    required => 1,
);

sub ask_question ( $self, $question, @responses ) {
    my $choice = choose(
        [
            @responses,
            'Launch Editor'
        ],
        { prompt => $question }
    ) or exit;    # user hit 'q' or ctrl-d to stop

    return $self->format_qa_markdown( $question, $choice )
        unless $choice eq 'Launch Editor';

    # todo: It would be nice if the notes persisted to disk for a given PT so
    # that I could ctrl-c out of a later question and still not have to retype
    # previously asked questions.  That's a task for another day however.

    my $prompt = <<"ENDOFTEXT";
$question

Complete your answer below the line in markdown.
---
ENDOFTEXT
    my $fh = solicit($prompt);

    my $answer = do { local $/ = undef; <$fh> };
    $answer =~ s/\A\Q$prompt//;

    return $self->format_qa_markdown( $question, $answer );
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _trim ($text) {
    return $text =~ s/\A\s+//r =~ s/\s+\z//r;
}
## use critic

sub format_qa_markdown ( $self, $question, $answer ) {
    return <<"ENDOFMARKDOWN";
### Question ###
@{[ _trim( $question )]}

### Answer ###
@{[ _trim( $answer ) ]}
ENDOFMARKDOWN
}

1;

# ABSTRACT: Role for writing interactive questions about the commits

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GHPT::WorkSubmitter::Role::Question - Role for writing interactive questions about the commits

=head1 VERSION

version 1.000012

=head1 SYNOPSIS

    package App::GHPT::WorkSubitter::Question::WarnAboutPasswordFile;
    use App::GHPT::Wrapper::OurMoose;
    with 'App::GHPT::WorkSubmitter::Role::Question';

    sub ask($self) {
        # skip the question unless there's a password file
        return unless $self->changed_files->changed_files_match(qr/password/);

        # ask the user if that's okay
        return $self->ask_question(<<'ENDOFTEXT',"I'm okay with the risk");
    You've committed a file with a name matching 'password'.  Are you nuts?
    ENDOFTEXT
    }

    __PACKAGE__->meta->make_immutable;
    1;

=head1 DESCRIPTION

This role allows you to write questions to ask someone when creating pull
request.

You want to create these questions classes in the
C<App::GHPT::WorkSubmitter::Question::*> namespace where
L<App::GHPT::WorkSubmitter::Questioner> will automatically detect them and ask
them each time C<gh-pt.pl> is run.

Each class must supply an C<ask> method which should prompt the user as needed
and return any markdown to be placed in the pull request body.

=head1 ATTRIBUTES

=head2 changed_files

The files that have changed in this branch.  This is the primary attribute
you want to examine.

=head1 METHODS

=head2 $question->ask_question($question, @optional_responses)

Interactively ask a question and return markdown suitable for including in the
pull request body.

The question that should be asked must be passed as the first argument, and
all other arguments are treated as stock answers the user can select when
asked the question.  The user will also have a final option C<Launch Editor>
which will launch their editor and allow them free-form text input.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-GHPT/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
