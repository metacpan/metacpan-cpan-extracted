package App::NDTools::NDTool;

use strict;
use warnings FATAL => 'all';

use App::NDTools::INC;
use App::NDTools::Slurp qw(s_dump s_load);
use Encode::Locale;
use Encode qw(decode);
use Getopt::Long qw(GetOptionsFromArray :config bundling noignore_case);
use Log::Log4Cli;
use Struct::Path 0.80 qw(path);

our $VERSION = '0.33';

sub arg_opts {
    my $self = shift;

    return (
        'dump-opts' => \$self->{OPTS}->{'dump-opts'},
        'help|h' => sub {
            $self->{OPTS}->{help} = 1;
            die "!FINISH";
        },
        'ifmt=s' => \$self->{OPTS}->{ifmt},
        'ofmt=s' => \$self->{OPTS}->{ofmt},
        'pretty!' => \$self->{OPTS}->{pretty},
        'verbose|v:+' => \$Log::Log4Cli::LEVEL,
        'version|V' => sub {
            $self->{OPTS}->{version} = 1;
            die "!FINISH";
        },
    );
}

sub check_args {
    my $self = shift;

    die_fatal 'At least one argument expected', 1 unless (@_);

    return $self;
}

sub configure {
    my $self = shift;

    return $self->check_args(@{$self->{ARGV}});
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
        my (%map_idx, $path, $ref, $grepped);

        for (@{$spaths}) {
            my @found = eval { path($struct, $_, deref => 1, paths => 1) };

            while (($path, $ref) = splice @found, 0, 2) {
                # remap array's indexes
                my $map_key = "";
                my $map_path = [];

                for my $step (@{$path}) {
                    if (ref $step eq 'ARRAY') {
                        $map_key .= "[]";
                        unless (exists $map_idx{$map_key}->{$step->[0]}) {
                            $map_idx{$map_key}->{$step->[0]} =
                                keys %{$map_idx{$map_key}};
                        }

                        push @{$map_path}, [$map_idx{$map_key}->{$step->[0]}];
                    } else { # HASH
                        $map_key .= "{$step->{K}->[0]}";
                        push @{$map_path}, $step;
                    }
                }

                path($grepped, $map_path, assign => $ref, expand => 1);
            }
        }

        push @out, $grepped if (defined $grepped);
    }

    return @out;
}

sub load_struct {
    my ($self, $uri, $fmt) = @_;

    log_trace { ref $uri ? "Reading from STDIN" : "Loading '$uri'" };
    s_load($uri, $fmt);
}

sub new {
    my $self = bless {}, shift;

    $self->{OPTS} = $self->defaults();
    $self->{ARGV} =
        [ map { decode(locale => "$_", Encode::FB_CROAK) } @_ ? @_ : @ARGV ];

    $self->{TTY} = -t STDOUT;

    unless (GetOptionsFromArray ($self->{ARGV}, $self->arg_opts)) {
        $self->usage;
        die_fatal "Unsupported opts used", 1;
    }

    if ($self->{OPTS}->{help}) {
        $self->usage;
        die_info, 0;
    }

    if ($self->{OPTS}->{version}) {
        print $self->VERSION . "\n";
        die_info, 0;
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
