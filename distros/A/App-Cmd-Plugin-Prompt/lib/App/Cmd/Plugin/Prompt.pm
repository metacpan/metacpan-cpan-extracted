use strict;
use warnings;
package App::Cmd::Plugin::Prompt;
{
  $App::Cmd::Plugin::Prompt::VERSION = '1.005';
}
# ABSTRACT: plug prompting routines into your commands
use App::Cmd::Setup -plugin => {
  exports => [ qw(prompt_str prompt_yn prompt_any_key) ],
};

use Term::ReadKey;


sub prompt_str {
  my ($plugin, $cmd, $message, $opt) = @_;
  if ($opt->{default} && $opt->{valid} && ! $opt->{no_valid_default}) {
    Carp::croak(
      $opt->{invalid_default_error} || "'default' must pass 'valid' parameter"
    ) unless $opt->{valid}->($opt->{default});
  }
  $opt->{input}  ||= sub { scalar <STDIN> };
  $opt->{valid}  ||= sub { 1 };
  $opt->{output} ||= sub {
    if (defined $_[1]) {
      printf "%s [%s]: ", @_;
    } else {
      printf "%s: ", $_[0];
    }
  };

  my $response;
  while (!defined($response) || !$opt->{valid}->($response)) {
    $opt->{output}->(
      $message,
      ($opt->{choices} || $opt->{default} || undef),
    );
    $response = $opt->{input}->();
    chomp($response);
    if ($opt->{default} && ! length($response)) {
      $response = $opt->{default};
    }
  }
  return $response;
}


sub prompt_yn {
  my ($plugin, $cmd, $message, $opt) = @_;

  Carp::croak("default must be y or n or 0 or 1")
    if defined $opt->{default}
    and $opt->{default} !~ /\A[yn01]\z/;

  my $choices = (not defined $opt->{default}) ? 'y/n'
              : $opt->{default} eq 'y'        ? 'Y/n'
              : $opt->{default} eq 'n'        ? 'y/N'
              : $opt->{default}               ? 'Y/n'
              :                                 'y/N';

  my $default = ($opt->{default}||'') =~ /\A\d\z/
              ? ($opt->{default} ? 'y' : 'n')
              : $opt->{default};

  my $response = $plugin->prompt_str(
    $cmd,
    $message,
    {
      choices => $choices,
      valid   => sub { lc($_[0]) eq 'y' || lc($_[0]) eq 'n' },
      default => $default,
    },
  );

  return lc($response) eq 'y';
}


sub prompt_any_key {
  my ($plugin, $cmd, $prompt) = @_;

  $prompt ||= "press any key to continue";
  print $prompt;
  Term::ReadKey::ReadMode 'cbreak';
  Term::ReadKey::ReadKey(0);
  Term::ReadKey::ReadMode 'normal';
  print "\n";
}


1;

__END__

=pod

=head1 NAME

App::Cmd::Plugin::Prompt - plug prompting routines into your commands

=head1 VERSION

version 1.005

=head1 SYNOPSIS

In your app:

  package MyApp;
  use App::Cmd::Setup -app => {
    plugins => [ qw(Prompt) ],
  };

In your command:

  package MyApp::Command::dostuff;
  use MyApp -command;

  sub run {
    my ($self, $opt, $args) = @_;

    return unless prompt_yn('really do stuff?', { default => 1 });

    ...
  }

=head1 SUBROUTINES

=head2 prompt_str

  my $input = prompt_str($prompt, \%opt)

This prompts a user for string input.  It can be directed to
persist until input is 'acceptable'.

Valid options are:

=over 4

=item *

B<input:> optional coderef, which, when invoked, returns the
user's response; default is to read from STDIN.

=item *

B<output:> optional coderef, which, when invoked (with two
arguments: the prompt and the choices/default), should
prompt the user; default is to write to STDOUT.

=item *

B<valid:> an optional coderef which any input is passed into
and which must return true in order for the program to
continue

=item *

B<default:> may be any string; must pass the 'valid' coderef
(if given)

=item *

B<choices:> what to display after the prompt; default is
either the 'default' parameter or nothing

=item *

B<no_valid_default:> do not test the 'default' parameter
against the 'valid' coderef

=item *

B<invalid_default_error:> error message to throw when the
'default' parameter is not valid (does not pass the 'valid'
coderef)

=back

=head2 prompt_yn

  my $bool = prompt_yn($prompt, \%opt);

This prompts the user for a yes or no response and won't give up until it gets
one.  It returns true for yes and false for no.

Valid options are:

 default: may be yes or no, indicating how to interpret an empty response;
          if empty, require an explicit answer; defaults to empty

=head2 prompt_any_key($prompt)

  my $input = prompt_any_key($prompt);

This routine prompts the user to "press any key to continue."  (C<$prompt>, if
supplied, is the text to prompt with.

=head1 SEE ALSO

L<App::Cmd>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
