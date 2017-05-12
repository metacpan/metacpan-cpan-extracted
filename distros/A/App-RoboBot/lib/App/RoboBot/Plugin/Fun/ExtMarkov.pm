package App::RoboBot::Plugin::Fun::ExtMarkov;
$App::RoboBot::Plugin::Fun::ExtMarkov::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.extmarkov

Provides access to an external markov chain generating program. Management of
corpora is the responsibility of this external program and its administrator.

=cut

has '+name' => (
    default => 'Fun::ExtMarkov',
);

has '+description' => (
    default => 'Provides access to an external markov chain generating program.',
);

=head2 ext-markov

=head3 Description

Generates and returns a markov chain from the named corpus, by invoking the
external markov generating program. Some effort is made to select a generated
chain which is neither extremely long nor short.

=head3 Usage

<corpus>

=cut

has '+commands' => (
    default => sub {{
        'ext-markov' => { method      => 'generate_external_markov',
                          description => 'Generates and returns a markov chain from the named corpus.',
                          usage       => '<corpus>', },

        'ext-markov-corpora' => { method      => 'external_markov_corpora',
                                  description => 'Returns a list of the known corpora for generating markov chains.', },
    }},
);

sub generate_external_markov {
    my ($self, $message, $command, $rpl, $corpus) = @_;

    unless (defined $corpus && $corpus =~ m{^[a-z0-9-]+$}o) {
        $message->response->raise('Must pass in the name of a valid corpus. Use (ext-markov-corpora) to see valid names.');
        return;
    }

    unless (exists $self->bot->config->plugins->{'extmarkov'}{'markov_bin'} && -r $self->bot->config->plugins->{'extmarkov'}{'markov_bin'}) {
        $message->response->raise('The external markov chain generator is not present on this server. Please contact your administrator.');
        return;
    }

    unless (exists $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'} && -d $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'}) {
        $message->response->raise('This plugin has not been configured properly. Please contact your admin.');
        return;
    }

    unless (-r $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'} . '/' . $corpus . '.db') {
        $message->response->raise('The corpus name %s is not valid. Use (ext-markov-corpora) to see valid names.');
        return;
    }

    my @phrases;

    for (1..5) {
        open(my $fh, '-|:encoding(UTF-8)',
            'python',
            $self->bot->config->plugins->{'extmarkov'}{'markov_bin'},
            'gen',
            $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'} . '/' . $corpus,
            '10') or next;

        while (my $phrase = <$fh>) {
            chomp($phrase);
            push(@phrases, $phrase) if $phrase =~ m{\w+};
        }
        close($fh);

        last if @phrases > 0;
    }

    # Trim off the longest and the shortest responses. Pick a random one from
    # what remain, and return that.
    my $c = @phrases;
    @phrases = (sort { length($a) <=> length($b) } @phrases)[int($c/3)..int($c*0.66)];
    $c = @phrases;

    my $chosen = $phrases[int(rand($c))];

    return $chosen if defined $chosen && $chosen =~ m{\w+};

    $message->response->raise('Could not generate a suitable markov chain. Please try again.');
    return;
}

sub external_markov_corpora {
    my ($self, $message, $command, $rpl) = @_;

    unless (exists $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'} && -d $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'}) {
        $message->response->raise('This plugin has not been configured properly. Please contact your admin.');
        return;
    }

    my @corpora;

    opendir(my $dirh, $self->bot->config->plugins->{'extmarkov'}{'corpora_dir'}) or return;
    while (my $fn = readdir($dirh)) {
        push(@corpora, $1) if $fn =~ m{^([a-z0-9-]+)\.db$}o;
    }
    closedir($dirh);

    return sort { $a cmp $b } @corpora if @corpora > 0;

    $message->response->raise('There are no corpora present on this server. Please contact your administrator.');
    return;
}

__PACKAGE__->meta->make_immutable;

1;
