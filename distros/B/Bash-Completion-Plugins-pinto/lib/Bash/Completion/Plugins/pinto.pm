## no critic (RequireUseStrict)
package Bash::Completion::Plugins::pinto;
BEGIN {
  $Bash::Completion::Plugins::pinto::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Bash completion for pinto
$Bash::Completion::Plugins::pinto::VERSION = '0.004';
## use critic (RequireUseStrict)
use strict;
use warnings;
use feature 'switch';
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(command_in_path);

my @pinto_commands = qw/commands help add copy
                           delete edit index init
                           install list manual merge
                           new nop pin props pull
                           stacks statistics unpin
                           verify version
                          /;

my @pinto_options = qw/-h --help
                       -r --root
                       -q --quiet
                       -v --verbose
                       --nocolor
                       /;

sub should_activate {
    return [ grep { command_in_path($_) } qw/pinto/ ];
}

sub _extract_stack {
    my ( $stack ) = @_;

    #$stack =~ s/\@.*//;
    return $stack;
}

sub _get_stacks {
    my @stacks = split /\n/, qx(pinto stacks);
    my ( $current_stack ) = grep { /^\*\s*/ } @stacks;
    ( $current_stack )    = $current_stack =~ /^\*\s*(\S+)/;

    $current_stack = _extract_stack($current_stack);

    return ( $current_stack, map { /^\*?\s*(?<name>\S+)/; $+{'name'} } @stacks );
}

sub complete {
    my ( $self, $r ) = @_;

    my $word = $r->word;

    if ($word =~ /^-/) {
            $r->candidates(grep { /^\Q$word\E/ } @pinto_options);
    } else {
            my @args = $r->args;

            my @orig_args = @args;

            shift @args; # get rid of 'pinto'

            # get rid of (-rFOO|-r FOO|--root FOO|--root=FOO)
            if ($args[0] and $args[0] =~ qr/^(?:-r|--root)$/) {
                    if ($args[0] =~ qr/^(?:--root=)$/) {
                            shift @args;
                    } elsif ($args[1]) {
                            shift @args;
                            shift @args;
                    }
            }

            shift @args until @args == 0 || $args[0] !~ /^-/;

            my $command = $args[0] // '';

            my @options = ();
            for ($command) {
                    /^add$/            and do { @options = qw(--author --dryrun --norecurse --pin --stack); last };
                    /^(?:copy|new)$/   and do { @options = qw(--description --dryrun); last };
                    /^edit$/           and do { @options = qw(--default --dryrun --properties -P); last };
                    /^init$/           and do { @options = qw(--source); last };
                    /^install$/        and do { @options = qw(--cpanm-exe --cpanm
                                                        --cpanm-options -o
                                                        -l --local-lib --local-lib-contained
                                                        --pull
                                                        --stack
                                                      ); last };
                    /^list$/           and do { @options = qw(--author -A
                                                        --distributions -D
                                                        --format
                                                        --packages -P
                                                        --pinned
                                                        --stack -s
                                                      ); last };
                    /^merge$/          and do { @options = qw(--dryrun); last };
                    /^nop$/            and do { @options = qw(--sleep); last };
                    /^(?:un)?pin$/     and do { @options = qw(--dryrun --stack); last };
                    /^(props|stacks)$/ and do { @options = qw(--format); last };
                    /^pull$/           and do { @options = qw(--dryrun --norecurse --stack); last };
            }

            for ($command) {
                    $_ eq $word and do {
                            $r->candidates(grep { /^\Q$word\E/ }
                                           ( @pinto_commands, @pinto_options ));
                            last;
                    };
                    ##_get_stacks() is quite slow for my demanding taste (due to slow pinto startup time)
                    /^(?:copy|delete|index|list|merge|pin|unpin)$/ and do {
                            my ( $current_stack, @stacks ) = _get_stacks();
                            $r->candidates(grep { /^\Q$word\E/ } ( @options, @stacks ));
                            last;
                    };
                    /^(?:manual|help)$/ and do {
                            $r->candidates(grep { /^\Q$word\E/ }
                                           ( @pinto_commands ));
                            last;
                    };
                    # all other commands (including unrecognized ones) get
                    # no completions
                    $r->candidates(grep { /^\Q$word\E/ } ( @options ));
            }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bash::Completion::Plugins::pinto - Bash completion for pinto

=head1 DESCRIPTION

L<Bash::Completion> support for L<pinto|App::Pinto>.  Completes pinto
commands and options.

=head1 SEE ALSO

L<Bash::Completion>, L<Bash::Completion::Plugin>, L<App::Pinto>

=head1 ACKNOWLEDGMENTS

Derived from L<Bash::Completion::Plugins::perlbrew> by Rob Hoelz.

=begin comment

=over

=item should_activate

=item complete

=back

=end comment

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
