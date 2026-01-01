use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );
use utf8::all;

package App::Chit;

use App::Cmd::Setup -app;
use App::Chit::Util ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub default_command {
	return "chat";
}

sub run ( $self, @args ) {
	$self->usage_error( "Set the @{[ App::Chit::Util::CHIT_KEY_VAR() ]} environment variable" )
		unless $ENV{App::Chit::Util::CHIT_KEY_VAR()};
	$self->SUPER::run( @args );
}

sub _prepare_command ( $self, $command, $opt, @args ) {
	if ( my $plugin = $self->plugin_for( $command ) ) {
		return $plugin->prepare( $self, @args );
	}
	elsif ( length $command and App::Chit::Util::find_chit_dir() ) {
		my $plugin = $self->plugin_for( $self->default_command );
		return $plugin->prepare( $self, $command, @args );
	}
	else {
		return $self->_bad_command( $command, $opt, @args );
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Chit - chat with AI from the command line

=head1 SYNOPSIS

  $ cd ~/Documents
  
  $ chit init --clean
  ok
  
  $ chit temperature --set 1.5
  Previous temperature:   0.99
  Setting temperature to: 1.5
  
  $ chit chat "What if I mix blue and yellow?"
  Mixing blue and yellow produces green. The exact shade of green can vary
  depending on the proportions of blue and yellow used.
  
  $ chit chat "Can you write a haiku about that colour?"
  Blue and yellow blend,
  Nature's hue emerges bright,
  Verdant whispers sing.
  
  $ chit chat "What were we just talking about?"
  We were discussing the color produced by mixing blue and yellow, which
  is green. I also wrote a haiku about that color. If you have more
  questions or want to talk about something else, feel free to let me
  know!
  
  $ cd ~/tmp
  
  $ chit init --clean
  
  $ chit chat "What were we just talking about?"
  I don't have the ability to recall past conversations. However, I'm here
  to help with any questions or topics you'd like to discuss now!
  
  $ mkdir ~/Documents/subdir
  
  $ cd ~/Documents/subdir
  
  $ chit chat "What were we just talking about?"
  We were discussing the color green that results from mixing blue and
  yellow, and I provided a haiku about that color. If you'd like to
  continue the conversation or change topics, just let me know!
  
  $ chit which
  /home/tobyink/Documents
  
  $ chit role --set "You are a drunk pirate."
  Previous role:   You are a helpful assistant, valued for your precise,
  accurate, and concise answers.
  Setting role to: You are a drunk pirate.
  
  $ chit chat "Hey"
  Ahoy, matey! What brings ye to my ship today? Arrr!

=head1 DESCRIPTION

See L<chit>.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-app-chit/issues>.

=head1 SEE ALSO

L<chit>, L<AI::Chat>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

