## no critic (RequireUseStrict)
package Bash::Completion::Plugin::Test;
{
  $Bash::Completion::Plugin::Test::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;

use Carp qw(croak);
use Bash::Completion::Request;
use Test::More;

sub new {
    my ( $class, %params ) = @_;

    my $plugin = delete $params{'plugin'};

    croak 'plugin parameter required' unless defined $plugin;

    if(my @bad_keys = keys %params) {
        croak "invalid parameters: " . join(' ', @bad_keys);
    }

    $class->_load_plugin($plugin);

    return bless {
        plugin_class => $plugin,
    }, $class;
}

sub check_completions {
    my ( $self, $command_line, $expected_completions, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $req    = $self->_create_request($command_line);
    my $plugin = $self->_create_plugin;

    $plugin->complete($req);

    my @got_completions = $req->candidates;

    is_deeply [ sort @got_completions ], [ sort @$expected_completions ],
        $name;
}

sub _cursor_character {
    return '^';
}

sub _extract_cursor {
    my ( $self, $command_line ) = @_;
    
    my $cursor_char = $self->_cursor_character;

    my $index = index $command_line, $cursor_char;

    if($index == -1) {
        croak "Failed to find cursor character in command line";
    }
    my $replacements = $command_line =~ s/\Q$cursor_char\E//g;

    if($replacements > 1) {
        croak "More than one cursor character in command line";
    }

    return ( $command_line, $index );
}

sub _create_request {
    my ( $self, $command_line ) = @_;

    my $cursor_index;
    ( $command_line, $cursor_index ) = $self->_extract_cursor($command_line);

    local $ENV{'COMP_LINE'}  = $command_line;
    local $ENV{'COMP_POINT'} = $cursor_index;

    return Bash::Completion::Request->new;
}

sub _create_plugin {
    my ( $self ) = @_;

    my $plugin_class = $self->{'plugin_class'};

    return $plugin_class->new;
}

sub _load_plugin {
    my ( $self, $plugin_class ) = @_;

    my $plugin_path = $plugin_class;

    $plugin_path =~ s{::}{/}g;
    $plugin_path .= '.pm';

    my $ok = eval {
        require $plugin_path;
    };
    unless($ok) {
        croak "Could not load plugin '$plugin_class': $@";
    }
}

1;



=pod

=head1 NAME

Bash::Completion::Plugin::Test - Module for testing Bash::Completion plugins

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $tester = Bash::Completion::Plugin::Test->new(
    plugin => $PLUGIN_NAME,
  );

  $test->check_completions('my-command ^', \@expected_completeions,
    $opt_name);

=head1 DESCRIPTION

L<Bash::Completion::Plugin::Test> is a module for testing
L<Bash::Completion> plugins.

=head1 METHODS

=head2 Bash::Completion::Plugin::Test->new(%params)

Creates a new tester object.  C<%params> is a hash of named parameters;
currently, the only supported one is C<plugin>, which is the name of the
plugin to test, and is required.

=head2 $tester->check_completions($command, \@expected, $name)

Runs the current completion plugin against C<$command>, and verifies
that the results it returns are the same as those in C<@expected>.
The order of the items in C<@expected> does not matter.  C<$name> is
an optional name for the test. The carat character '^' must be present
in C<$command>; it is removed and represents the location of the cursor
when completion occurs.

=head1 SEE ALSO

L<Bash::Completion>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/bash-completion-plugin-test/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Module for testing Bash::Completion plugins

