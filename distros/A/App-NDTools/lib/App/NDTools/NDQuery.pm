package App::NDTools::NDQuery;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDTool';

use Digest::MD5 qw(md5_hex);
use JSON qw();
use Log::Log4Cli;
use App::NDTools::Slurp qw(s_dump);
use Struct::Path 0.80 qw(list_paths path path_delta);
use Struct::Path::PerlStyle 0.80 qw(str2path path2str);
use Term::ANSIColor qw(colored);

our $VERSION = '0.32';

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'colors!' => \$self->{OPTS}->{colors},
        'delete|ignore=s@' => \$self->{OPTS}->{delete},
        'depth|d=i' => \$self->{OPTS}->{depth},
        'grep=s@' => \$self->{OPTS}->{grep},
        'items' => \$self->{OPTS}->{items},
        'list|l' => \$self->{OPTS}->{list},
        'md5' => \$self->{OPTS}->{md5},
        'path|p=s' => \$self->{OPTS}->{path},
        'raw-output' => sub { $self->{OPTS}->{ofmt} = 'RAW' },
        'replace' => \$self->{OPTS}->{replace},
        'strict!' => \$self->{OPTS}->{strict},
        'values|vals' => \$self->{OPTS}->{values},
    );
}

sub check_args {
    my $self = shift;

    if ($self->{OPTS}->{replace}) {
        die_fatal "--replace opt can't be used with --items", 1
            if ($self->{OPTS}->{items});
        die_fatal "--replace opt can't be used with --list", 1
            if ($self->{OPTS}->{list});
        die_fatal "--replace opt can't be used with --md5", 1
            if ($self->{OPTS}->{md5});
    }

    return $self;
}

sub configure {
    my $self = shift;

    $self->SUPER::configure();

    $self->{OPTS}->{colors} = -t STDOUT ? 1 : 0
        unless (defined $self->{OPTS}->{colors});

    for (
        @{$self->{OPTS}->{grep}},
        @{$self->{OPTS}->{delete}}
    ) {
        my $tmp = eval { str2path($_) };
        die_fatal "Failed to parse '$_'", 4 if ($@);
        $_ = $tmp;
    }

    return $self;
}

sub defaults {
    my $self = shift;

    return {
        %{$self->SUPER::defaults()},
        'color-common' => 'bold black',
        'strict' => 1, # exit with 8 if unexisted path specified
        'ofmt' => 'JSON',
    };
}

sub dump {
    my ($self, $uri, $data) = @_;

    $uri = \*STDOUT unless ($self->{OPTS}->{replace});
    s_dump($uri, $self->{OPTS}->{ofmt}, {pretty => $self->{OPTS}->{pretty}}, @{$data});
}

sub exec {
    my $self = shift;

    for my $uri (@{$self->{ARGV}} ? @{$self->{ARGV}} : \*STDIN) {
        my @data = $self->load_struct($uri, $self->{OPTS}->{ifmt});

        if (defined $self->{OPTS}->{path}) {
            my $spath = eval { str2path($self->{OPTS}->{path}) };
            die_fatal "Failed to parse '$self->{OPTS}->{path}'", 4 if ($@);

            unless (@data = path($data[0], $spath, deref => 1)) {
                die_fatal "Failed to lookup path '$self->{OPTS}->{path}'", 8
                    if ($self->{OPTS}->{strict});
                next;
            }
        }

        @data = $self->grep($self->{OPTS}->{grep}, @data)
            if (@{$self->{OPTS}->{grep}});

        for my $spath (@{$self->{OPTS}->{delete}}) {
            map { path($_, $spath, delete => 1) if (ref $_) } @data;
        }

        if ($self->{OPTS}->{items}) {
            $self->items(\@data);
        } elsif ($self->{OPTS}->{list}) {
            $self->list($uri, \@data);
        } elsif ($self->{OPTS}->{md5}) {
            $self->md5($uri, \@data);
        } else {
            $self->dump($uri, \@data);
        }
    }

    die_info "All done", 0;
}

my $JSON = JSON->new->canonical->allow_nonref;

sub items {
    my ($self, $data) = @_;
    my @out;

    for (@{$data}) {
        if (ref $_ eq 'HASH') {
            push @out, sort keys %{$_};
        } elsif (ref $_ eq 'ARRAY') {
            push @out, "0 .. " . $#{$_};
        } else {
            push @out, $JSON->encode($_);
        }
    }

    print join("\n", @out) . "\n";
}

sub list {
    my ($self, $uri, $data) = @_;

    for (@{$data}) {
        my @list = list_paths($_, depth => $self->{OPTS}->{depth});
        my ($base, @delta, $line, $path, $prev, $value, @out);

        while (@list) {
            ($path, $value) = splice @list, 0, 2;

            @delta = path_delta($prev, $path);
            $base = [ @{$path}[0 .. @{$path} - @delta - 1] ];
            $line = $self->{OPTS}->{colors}
                ? colored(path2str($base), $self->{OPTS}->{'color-common'})
                : path2str($base);
            $line .= path2str(\@delta);

            if ($self->{OPTS}->{values}) {
                $line .= " = ";
                if ($self->{OPTS}->{ofmt} eq 'RAW' and not ref ${$value}) {
                    $line .= ${$value};
                } else {
                    $line .= $JSON->encode(${$value});
                }
            }

            push @out, $line;
            $prev = $path;
        }

        print join("\n", @out) . "\n";
    }
}

sub md5 {
    my ($self, $uri, $data) = @_;

    print md5_hex($JSON->encode($_)) .
        (ref $uri ? "\n" : " $uri\n")
            for (@{$data});
}

1; # End of App::NDTools::NDQuery
