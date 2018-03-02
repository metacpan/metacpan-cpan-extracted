package Bash::Completion::RequestX::Sqitch;

use Moo;
use List::Util 'any';
use Module::Pluggable
  require     => 0,
  inner       => 0,
  search_path => ['App::Sqitch::Command'],
  sub_name    => '_sqitch_commands';
use Pg::ServiceFile;
use Types::Standard qw/ArrayRef HasMethods Str/;

# ABSTRACT: extended request class for Sqitch completion candidates

has args => (
    is      => 'lazy',
    isa     => ArrayRef,
    builder => sub {
        [$_[0]->request->args]
    }
);

has command => (
    is      => 'lazy',
    isa     => Str,
    builder => sub {
        $_[0]->args->[0] // '';
    }
);

# Ref['Bash::Completion::Request']
has request => (
    is       => 'ro',
    isa      => HasMethods[qw/args word/],
    required => 1,
);

has pg_service_file => (
    is      => 'lazy',
    builder => sub { Pg::ServiceFile->new() }
);

has previous_arg => (
    is      => 'lazy',
    isa     => Str,
    builder => sub {
       shift->stripped_args->[-1] // ''
    }
);

has sqitch_commands => (
    is  => 'lazy',
    isa => ArrayRef,
    builder => sub {
        [map { m/(\w+)$/; $1 } shift->_sqitch_commands];
    }
);

has sqitch_config => (
    is      => 'lazy',
    builder => sub {
        require App::Sqitch::Config;
        return App::Sqitch::Config->new();
    }
);

has sqitch_targets => (
    is  => 'lazy',
    isa => ArrayRef,
);

has stripped_args => (
    is      => 'lazy',
    isa     => ArrayRef,
    builder => sub {
        my $self = shift;
        my $index = 0;
        $index++ if $self->command;
        $index++ if $self->subcommand;
        my @args = $self->request->args;
        return [splice(@args, $index)];
    }
);

has subcommand => (
    is => 'lazy',
    isa => Str,
    builder => sub {
        $_[0]->args->[1] // ''
    }
);

sub candidates {
    my $self = shift;

    # If this method is being called we know what the command is. Default the
    # candidates to the available subcommands.
    my $candidates = $self->sqitch_commands;

    if (any { $_ eq $self->subcommand } @{$self->sqitch_commands}) {
        if ($self->request->word =~ m/^db:/) {
            $candidates = [ map { "db:pg:///?service=$_" }
                @{ $self->pg_service_file->names } ];
        }
        elsif ($self->previous_arg eq '--target') {
            $candidates = $self->sqitch_targets;
        }
        else {
            my $class = 'App::Sqitch::Command::' . $self->subcommand;
            eval "require $class";

            # This could probably do with cleaning up. Several assumptions are
            # made, including the options method existing on the class, and it
            # returning an ARRAY.
            #
            # Additionally, this will return deprecated options and options
            # that don't appear when viewing the command's help.
            $candidates = _getopt_long_options([$class->options]);
        }
    }

    return _remove_list_from_list($candidates, $self->stripped_args);
}

sub _build_sqitch_targets {
    my $self   = shift;
    my $config = $self->sqitch_config;

    # Taken from App::Sqitch::Target (I don't understand Sqitch enough
    # to know if this is good enough for --target at the moment).
    my %dump = $config->dump;
    my %targets;
    for my $key (keys %dump) {
        next if $key !~ /^target[.]([^.]+)[.]uri$/;
        $targets{$1}++;
    }

    return [sort keys %targets];
}

sub _getopt_long_options {
    my $getopts = shift;
    return [
        map { my $first = ( split(qr/[|=!]/) )[0]; $first ? "--$first" : '' }
          @$getopts
    ];
}

sub _remove_list_from_list {
    my ($lista, $listb) = @_;
    my $in = sub { any { $_ eq $_[0] } @$listb };
    return [grep { !$in->($_) } @$lista];
}

1;
