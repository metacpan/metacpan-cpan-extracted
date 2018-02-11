package App::NDTools::NDTool;

use strict;
use warnings FATAL => 'all';

use App::NDTools::INC;
use App::NDTools::Slurp qw(s_dump s_load);
use Encode::Locale qw(decode_argv);
use Getopt::Long qw(GetOptionsFromArray :config bundling);
use Log::Log4Cli;
use Struct::Path 0.80 qw(path);

sub VERSION { "n/a" }

sub arg_opts {
    my $self = shift;

    return (
        'dump-opts' => \$self->{OPTS}->{'dump-opts'},
        'help|h' => sub { $self->usage; exit 0 },
        'ifmt=s' => \$self->{OPTS}->{ifmt},
        'ofmt=s' => \$self->{OPTS}->{ofmt},
        'pretty!' => \$self->{OPTS}->{pretty},
        'verbose|v:+' => \$Log::Log4Cli::LEVEL,
        'version|V' => sub { print $self->VERSION . "\n"; exit 0 },
    );
}

sub check_args {
    my $self = shift;

    unless (@_) {
        log_error { 'At least one argument expected' };
        return undef;
    }

    return $self;
}

sub configure {
    return $_[0];
}

sub defaults {
    return {
        'ofmt' => 'JSON',
        'pretty' => 1,
        'verbose' => $Log::Log4Cli::LEVEL,
    };
}

sub dump_opts {
    my $self = shift;

    delete $self->{OPTS}->{'dump-opts'};
    s_dump(\*STDOUT, undef, undef, $self->{OPTS});
}

sub grep {
    my ($self, $spaths, @structs) = @_;
    my @out;

    for my $struct (@structs) {
        my $tmp;
        for (@{$spaths}) {
            my @found = eval { path($struct, $_, deref => 1, paths => 1) };
            while (@found) {
                my ($p, $r) = splice @found, 0, 2;
                path($tmp, $p, assign => $r, expand => 'append');
            }
        }
        push @out, $tmp if (defined $tmp);
    }

    return @out;
}

sub load_struct {
    my ($self, $uri, $fmt) = @_;

    log_trace { ref $uri ? "Reading from STDIN" : "Loading '$uri'" };
    s_load($uri, $fmt) or return undef;
}

sub new {
    my $self = bless { ARGV => \@_ }, shift;
    $self->{OPTS} = $self->defaults();

    decode_argv(Encode::FB_CROAK);
    unless (GetOptionsFromArray ($self->{ARGV}, $self->arg_opts)) {
        $self->usage;
        die_fatal "Unsupported opts used", 1;
    }

    $self->configure();

    if ($self->{OPTS}->{'dump-opts'}) {
        $self->dump_opts();
        die_info, 0;
    }

    return $self;
}

sub usage {
    require Pod::Usage;
    Pod::Usage::pod2usage(
        -exitval => 'NOEXIT',
        -output => \*STDERR,
        -sections => 'SYNOPSIS|OPTIONS|EXAMPLES',
        -verbose => 99
    );
}

1; # End of App::NDTools::NDTool
