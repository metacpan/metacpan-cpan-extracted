package Bash::Completion::Plugins::BashComplete;
{
  $Bash::Completion::Plugins::BashComplete::VERSION = '0.008';
}

# ABSTRACT: Plugin for bash-complete

use strict;
use warnings;
use parent 'Bash::Completion::Plugin';
use Bash::Completion::Utils
  qw( command_in_path match_perl_modules prefix_match );


sub should_activate {
  my @commands = ('bash-complete');
  return [grep { command_in_path($_) } @commands];
}



my @commands = qw{ setup complete };
my @options = ('--help', '-h');

sub complete {
  my ($class, $req) = @_;
  my $word  = $req->word;
  my @args  = $req->args;
  my $count = $req->count;

  my @c;
  if (index($word, '-') == 0) {
    @c = prefix_match($word, @options);
  }
  elsif ($count >= 2 && $args[1] eq 'complete') {
    @c = match_perl_modules("Bash::Completion::Plugins::$word");
  }
  elsif ($count <= 2) {
    @c = prefix_match($word, @commands, @options);
  }

  $req->candidates(@c);
}

1;



=pod

=head1 NAME

Bash::Completion::Plugins::BashComplete - Plugin for bash-complete

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    ## not to be used directly

=head1 DESCRIPTION

A plugin for the C<base-complete> command. Completes options and
sub-commands.

For the C<complete> sub-command, it completes with the plugin names.

=head1 METHODS

=head2 should_activate

Makes sure we only activate this plugin if we can find C<bash-complete>
in our PATH.

=head2 complete

Completion logic for C<bash-complete>

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

