package App::RoboBot::Plugin::Fun::Spellcheck;
$App::RoboBot::Plugin::Fun::Spellcheck::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use File::HomeDir;
use Text::Aspell;

extends 'App::RoboBot::Plugin';

=head1 fun.spellcheck

Randomly and annoyingly corrects (often mistakenly) spelling of other channel
members. You will disable this plugin soon enough.

=cut

has '+name' => (
    default => 'Fun::Spellcheck',
);

has '+description' => (
    default => 'Randomly and annoyingly corrects (often mistakenly) spelling of other channel members.',
);

has '+after_hook' => (
    default => 'check_spelling',
);

=head2 remember

=head3 Description

Add words to the local dictionary to avoid correcting their spelling in future
messages.

=head3 Usage

<word> [<word> ...]

=head3 Examples

    (remember Automtomatromaton)

=head2 forget

=head3 Description

Remove words from the local dictionary. Does not affect words in the global
system dictionary.

=head3 Usage

<word> [<word> ...]

=head3 Examples

    (forget Automtomatromaton)

=cut

has '+commands' => (
    default => sub {{
        'remember' => { method      => 'remember_words',
                        description => 'Add words to the local dictionary to avoid correcting their spelling in future messages.',
                        usage       => '<word> [<word 2> ... <word N>]' },

        'forget' => { method      => 'forget_words',
                      description => 'Remove words from the local dictionary. Does not affect words in the global system dictionary.',
                      usage       => '<word> [<word 2> ... <word N>]' },
    }},
);

# TODO consider moving this to a configuration option
has 'word_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::HomeDir->my_home() . '/.aspell.en.pws' },
);

has 'ts' => (
    is      => 'ro',
    isa     => 'Text::Aspell',
    default => sub { Text::Aspell->new() },
);

sub check_spelling {
    my ($self, $message) = @_;

    # Don't correct spelling on S-Expressions
    return if $message->has_expression;

    # TODO move this into a configuration option
    return unless rand() <= 0.3;

    my @words = split(/\s+/o, $message->raw);
    my @fixed = ();

    WORD:
    foreach my $word (grep { defined $_ && length($_) >= 3 } map { $self->clean_word($_) } @words) {
        my $found = $self->ts->check($word);

        next WORD if $found;

        if (defined $found) {
            my @s = $self->ts->suggest($word);

            if (@s && @s > 0) {
                push(@fixed, $s[0]) unless grep { lc($_) eq lc($s[0]) } @fixed;
            }
        }
    }

    return unless @fixed && @fixed > 0;

    if (@fixed > 1) {
        @fixed = sort { length($b) <=> length($a) } @fixed; # favor longer words in corrections
        @fixed = @fixed[0..6] if @fixed > 7; # limit number of corrections for people who are really terrible at spelling
    }

    $message->response->push(sprintf('%s: %s', $message->sender->name, join(', ', map { '*' . $_ } @fixed)));
}

sub clean_word {
    my ($self, $word) = @_;

    return if $word =~ m{[0-9_@/:;~<>\{\}\[\[\\\]]}o;

    $word =~ s{(^[^a-zA-Z]+|[^a-zA-Z\.]+$)}{}ogs;
    $word =~ s{\.+$}{\.}ogs;
    $word =~ s{\.+$}{}ogs unless $word =~ m{\w+\.\w+}o;

    return $word;
}

sub remember_words {
    my ($self, $message, $command, $rpl, @words) = @_;

    @words = map { $self->clean_word($_) } grep { $_ =~ m{\w}o } @words;
    my @new_words;

    foreach my $word (@words) {
        next if $self->ts->check($word);

        $self->ts->add_to_personal($word);
        push(@new_words, $word);
    }

    $self->ts->save_all_word_lists;

    if (@new_words < 1) {
        $message->response->push('I already knew all of those words.');
    } else {
        $message->response->push(sprintf('Remembered the following new words: %s', join(', ', @new_words)));
    }

    return;
}

sub forget_words {
    my ($self, $message, $command, $rpl, @words) = @_;

    @words = map { $self->clean_word($_) } grep { $_ =~ m{\w}o } @words;

    my @removed_words;
    my @saved_words;

    open(my $word_fh, '<', $self->word_file) || return;
    while (my $word = <$word_fh>) {
        chomp($word);
        next unless $word =~ m{\w}o;

        if (scalar(grep { lc($word) eq lc($_) } @words) > 0) {
            push(@removed_words, $word);
        } else {
            push(@saved_words, $word);
        }
    }
    close($word_fh);

    open($word_fh, '>', $self->word_file) || return;
    print $word_fh join("\n", @saved_words);
    close($word_fh);

    if (@removed_words < 1) {
        $message->response->push('None of those words were in my personal dictionary.');
    } else {
        $message->response->push(sprintf('I have forgotten the following words: %s', join(', ', @removed_words)));
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
