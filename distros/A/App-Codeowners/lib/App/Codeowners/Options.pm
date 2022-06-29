package App::Codeowners::Options;
# ABSTRACT: Getopt and shell completion for App::Codeowners

use v5.10.1;
use warnings;
use strict;

use Encode qw(decode);
use Getopt::Long 2.39 ();
use Path::Tiny;

our $VERSION = '0.51'; # VERSION

sub _pod2usage {
    eval { require Pod::Usage };
    if ($@) {
        my $ref  = $VERSION eq '9999.999' ? 'master' : "v$VERSION";
        my $exit = (@_ == 1 && $_[0] =~ /^\d+$/ && $_[0]) //
                   (@_ % 2 == 0 && {@_}->{'-exitval'})    // 2;
        print STDERR <<END;
Online documentation is available at:

  https://github.com/chazmcgarvey/git-codeowners/blob/$ref/README.md

Tip: To enable inline documentation, install the Pod::Usage module.

END
        exit $exit;
    }
    else {
        Pod::Usage::pod2usage(@_);
    }
}

sub _early_options {
    return {
        'color|colour!'         => (-t STDOUT ? 1 : 0), ## no critic (InputOutput::ProhibitInteractiveTest)
        'format|f=s'            => undef,
        'help|h|?'              => 0,
        'manual|man'            => 0,
        'shell-completion:s'    => undef,
        'version|v'             => 0,
    };
}

sub _command_options {
    return {
        'create'    => {},
        'owners'    => {
            'pattern=s' => '',
        },
        'patterns'  => {
            'owner=s'   => '',
        },
        'projects'  => {},
        'show'      => {
            'owner=s@'          => [],
            'pattern=s@'        => [],
            'project=s@'        => [],
            'patterns!'         => 0,
            'projects!'         => undef,
            'expand-aliases!'   => 0,
        },
        'update'    => {},
    };
}

sub _commands {
    my $self = shift;
    my @commands = sort keys %{$self->_command_options};
    return @commands;
}

sub _options {
    my $self = shift;
    my @command_options;
    if (my $command = $self->{command}) {
        @command_options = keys %{$self->_command_options->{$command} || {}};
    }
    return (keys %{$self->_early_options}, @command_options);
}


sub new {
    my $class = shift;
    my @args  = @_;

    # assume UTF-8 args if non-ASCII
    @args = map { decode('UTF-8', $_) } @args if grep { /\P{ASCII}/ } @args;

    my $self = bless {}, $class;

    my @args_copy = @args;

    my $opts = $self->get_options(
        args    => \@args,
        spec    => $self->_early_options,
        config  => 'pass_through',
    ) or _pod2usage(2);

    if ($ENV{CODEOWNERS_COMPLETIONS}) {
        $self->{command} = $args[0] || '';
        my $cword = $ENV{CWORD};
        my $cur   = $ENV{CUR} || '';
        # Adjust cword to remove progname
        while (0 < --$cword) {
            last if $cur eq ($args_copy[$cword] || '');
        }
        $self->completions($cword, @args_copy);
        exit 0;
    }

    if ($opts->{version}) {
        my $progname = path($0)->basename;
        print "${progname} ${VERSION}\n";
        exit 0;
    }
    if ($opts->{help}) {
        _pod2usage(-exitval => 0, -verbose => 99, -sections => [qw(NAME SYNOPSIS OPTIONS COMMANDS)]);
    }
    if ($opts->{manual}) {
        _pod2usage(-exitval => 0, -verbose => 2);
    }
    if (defined $opts->{shell_completion}) {
        $self->shell_completion($opts->{shell_completion});
        exit 0;
    }

    # figure out the command (or default to "show")
    my $command = shift @args;
    my $command_options = $self->_command_options->{$command || ''};
    if (!$command_options) {
        unshift @args, $command if defined $command;
        $command = 'show';
        $command_options = $self->_command_options->{$command};
    }

    my $more_opts = $self->get_options(
        args    => \@args,
        spec    => $command_options,
    ) or _pod2usage(2);

    %$self = (%$opts, %$more_opts, command => $command, args => \@args);
    return $self;
}


sub command {
    my $self = shift;
    my $command = $self->{command};
    my @commands = sort keys %{$self->_command_options};
    return if not grep { $_ eq $command } @commands;
    $command =~ s/[^a-z]/_/g;
    return $command;
}


sub args {
    my $self = shift;
    return @{$self->{args} || []};
}


sub get_options {
    my $self = shift;
    my $args = {@_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_};

    my %options;
    my %results;
    while (my ($opt, $default_value) = each %{$args->{spec}}) {
        my ($name) = $opt =~ /^([^=:!|]+)/;
        $name =~ s/-/_/g;
        $results{$name} = $default_value;
        $options{$opt}  = \$results{$name};
    }

    if (my $fn = $args->{callback}) {
        $options{'<>'} = sub {
            my $arg = shift;
            $fn->($arg, \%results);
        };
    }

    my $p = Getopt::Long::Parser->new;
    $p->configure($args->{config} || 'default');
    return if !$p->getoptionsfromarray($args->{args}, %options);

    return \%results;
}


sub shell_completion {
    my $self = shift;
    my $type = lc(shift || 'bash');

    if ($type eq 'bash') {
    print <<'END';
# git-codeowners - Bash completion
# To use, eval this code:
#   eval "$(git-codeowners --shell-completion)"
# This will work without the bash-completion package, but handling of colons
# in the completion word will work better with bash-completion installed and
# enabled.
_git_codeowners() {
    local cur words cword
    if declare -f _get_comp_words_by_ref >/dev/null
    then
        _get_comp_words_by_ref -n : cur cword words
    else
        words=("${COMP_WORDS[@]}")
        cword=${COMP_CWORD}
        cur=${words[cword]}
    fi
    local IFS=$'\n'
    COMPREPLY=($(CODEOWNERS_COMPLETIONS=1 CWORD="$cword" CUR="$cur" ${words[@]}))
    # COMPREPLY=($(${words[0]} --completions "$cword" "${words[@]}"))
    if [[ "$?" -eq 9 ]]
    then
        COMPREPLY=($(compgen -A "${COMPREPLY[0]}" -- "$cur"))
    fi
    declare -f __ltrim_colon_completions >/dev/null && \
        __ltrim_colon_completions "$cur"
    return 0
}
complete -F _git_codeowners git-codeowners
END
    }
    else {
        # TODO - Would be nice to support Zsh
        warn "No such shell completion: $type\n";
    }
}


sub completions {
    my $self    = shift;
    my $cword   = shift;
    my @words   = @_;

    my $current = $words[$cword]     || '';
    my $prev    = $words[$cword - 1] || '';

    my $reply;

    if ($prev eq '--format' || $prev eq '-f') {
        $reply = $self->_completion_formats;
    }
    elsif ($current =~ /^-/) {
        $reply = $self->_completion_options;
    }
    else {
        if (!$self->command) {
            $reply = [$self->_commands, @{$self->_completion_options([keys %{$self->_early_options}])}];
        }
        else {
            print 'file';
            exit 9;
        }
    }

    local $, = "\n";
    print grep { /^\Q$current\E/ } @$reply;
    exit 0;
}

sub _completion_options {
    my $self = shift;
    my $opts = shift || [$self->_options];

    my @options;

    for my $option (@$opts) {
        my ($names, $op, $vtype) = $option =~ /^([^=:!]+)([=:!]?)(.*)$/;
        my @names = split(/\|/, $names);

        for my $name (@names) {
            if ($op eq '!') {
                push @options, "--$name", "--no-$name";
            }
            else {
                if (length($name) > 1) {
                    push @options, "--$name";
                }
                else {
                    push @options, "-$name";
                }
            }
        }
    }

    return [sort @options];
}

sub _completion_formats { [qw(csv json json:pretty tsv yaml)] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Options - Getopt and shell completion for App::Codeowners

=head1 VERSION

version 0.51

=head1 METHODS

=head2 new

    $options = App::Codeowners::Options->new(@ARGV);

Construct a new object.

=head2 command

    $str = $options->command;

Get the command specified by args provided when the object was created.

=head2 args

    $args = $options->args;

Get the args provided when the object was created.

=head2 get_options

    $options = $options->get_options(
        args     => \@ARGV,
        spec     => \@expected_options,
        callback => sub { my ($arg, $results) = @_; ... },
    );

Convert command-line arguments to options, based on specified rules.

Returns a hashref of options or C<undef> if an error occurred.

=over 4

=item *

C<args> - Arguments from the caller (e.g. C<@ARGV>).

=item *

C<spec> - List of L<Getopt::Long> compatible option strings.

=item *

C<callback> - Optional coderef to call for non-option arguments.

=item *

C<config> - Optional L<Getopt::Long> configuration string.

=back

=head2 shell_completion

    $options->shell_completion($shell_type);

Print shell code to C<STDOUT> for the given type of shell. When eval'd, the shell code enables
completion for the F<git-codeowners> command.

=head2 completions

    $options->completions($current_arg_index, @args);

Print completions to C<STDOUT> for the given argument list and cursor position, and exit.

May also exit with status 9 and a compgen action printed to C<STDOUT> to indicate that the shell
should generate its own completions.

Doesn't return.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
