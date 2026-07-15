# ABSTRACT: Role providing option-aware CLI positional-argument parsing

package App::karr::Role::CliArgs;
our $VERSION = '0.401';
use Moo::Role;


# Extract the real positional arguments from the argv MooX::Cmd echoes back
# into execute(). Because MooX::Options runs with protect_argv (its default),
# the array handed to execute() still holds every original token in order:
# recognised option flags, the values they consumed, and --opt=value forms
# included (e.g. `move --claim tester 1 in-progress` arrives verbatim as
# [--claim, tester, 1, in-progress]). This gives cobra-style freedom to place
# flags before, between, or after positionals -- we just have to subtract the
# option tokens back out.
#
# We do that by walking the argv against the command's own %{_options_data}:
# a dash token is an option; if that option takes a value (has a 'format') and
# is given in space form (no inline '='), it also swallows the following token
# as its value -- even a flag-shaped value like `--append-body --weird`.
# Everything not eaten as an option or an option value is a positional, in
# order. Option-name matching mirrors how the token reaches us: leading dashes
# stripped, '-' folded to '_' to hit the underscore keys in _options_data, plus
# a reverse map of short aliases (e.g. -a => append_body, -t => timestamp).
# An unrecognised dash token is treated defensively as non-consuming: a genuine
# typo would already have been rejected upstream by MooX::Options, so the only
# accepted-but-unmatched shape here is a Getopt::Long abbreviation, and karr's
# abbreviatable flags (e.g. --jso for --json) consume nothing anyway.
sub positional_args {
    my ($self, $args_ref) = @_;

    my %options_data = $self->_options_data;
    my %by_name;
    for my $name (keys %options_data) {
        $by_name{$name} = $options_data{$name};
        my $short = $options_data{$name}{short};
        next unless defined $short;
        $by_name{$_} = $options_data{$name} for split /\|/, $short;
    }

    my @positional;
    my @args = @$args_ref;
    while (@args) {
        my $arg = shift @args;
        if ($arg =~ /^-/) {
            (my $name = $arg) =~ s/^-+//;        # drop leading dashes
            my $has_inline = $name =~ s/=.*//s;  # --opt=value carries its value
            $name =~ tr/-/_/;                    # match underscore keys
            my $data = $by_name{$name};
            shift @args if $data && $data->{format} && !$has_inline && @args;
            next;
        }
        push @positional, $arg;
    }
    return @positional;
}

# Reject surplus positional arguments before a command does any work, matching
# kanban-md's cobra Args validators (ExactArgs/RangeArgs/MaximumNArgs) which
# refuse extra positionals ahead of RunE. The comma list stays the one and only
# batch syntax; there is no space-separated id batch. Counting is done against
# positional_args (the real positionals with option tokens subtracted out), not
# a leading run of non-dash tokens, so `archive 1 --json 99` correctly rejects
# the trailing "99" instead of silently dropping it.
sub check_positional_args {
    my ($self, $args_ref, $max) = @_;

    my @positional = $self->positional_args($args_ref);
    return if @positional <= $max;

    my @extra   = @positional[$max .. $#positional];
    my %config  = $self->_options_config;
    my $usage   = $config{usage_string};

    die sprintf "unexpected extra argument%s: %s\n%s",
        (@extra == 1 ? '' : 's'),
        join(', ', map { "'$_'" } @extra),
        ($usage ? "$usage\n" : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::CliArgs - Role providing option-aware CLI positional-argument parsing

=head1 VERSION

version 0.401

=head1 DESCRIPTION

This role recovers the real positional arguments from the argv MooX::Cmd echoes
back into a command's C<execute()>. Because MooX::Options runs with protect_argv,
that argv still holds every original token -- option flags, the values they
consumed, and the positionals -- in their original order. C<positional_args>
subtracts the option tokens back out (using the consuming command's own
C<_options_data>) to yield the positionals, and C<check_positional_args> rejects
surplus positionals before a command does any work.

Command classes provide C<_options_data> and C<_options_config> via MooX::Options.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
