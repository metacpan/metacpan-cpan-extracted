package App::Ordo::Command::Base;
use Moo;
use feature qw(say);
use utf8;
use open ':std', ':utf8'; 
use Getopt::Long qw(GetOptionsFromArray);
use Term::ANSIColor qw(colored);

has 'api' => (is => 'ro', required => 1);

# Override in subclasses
sub name        { die "override name()" }
sub summary     { "no summary" }
sub usage       { "override usage" }
sub option_spec { {} }  # MUST return hashref: 'opt=s' => 'description'

sub run {
    my ($self, @args) = @_;

    if (@args && ($args[0] eq '--help' || $args[0] eq '-h')) {
        $self->show_help;
        return;
    }

    my %opt;
    my $ok = GetOptionsFromArray(
        \@args,
        \%opt,
        keys %{$self->option_spec},
    );

    unless ($ok) {
        say colored(["bold red"], "Invalid options — use --help");
        return;
    }

    $self->execute(\%opt, @args);
}

sub execute {
    my ($self, $opt, @args) = @_;
    die "execute() not implemented in " . ref($self);
}

sub show_help {
    my ($self) = @_;
    say colored(["bold cyan"], "ordo @{[lc $self->name]} " . $self->usage);
    say $self->summary;

    my $spec = $self->option_spec;
    return unless $spec && keys %$spec;

    say "\nOptions:";
    for my $key (sort keys %$spec) {
        my $desc = $spec->{$key} || '';
        (my $clean = $key) =~ s/[=:!+].*//;
        $clean =~ s/\|/ | /g;
        printf "  %-30s %s\n", $clean, $desc;
    }
}

1;
