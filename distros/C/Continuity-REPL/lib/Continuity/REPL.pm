package Continuity::REPL;

our $VERSION = '0.01';

=head1 NAME

Continuity::REPL - Use a Devel::REPL on a Continuity server

=head1 SYNOPSYS

  use strict;
  use Continuity;
  use Continuity::REPL;

  use vars qw( $repl $server );

  $repl = Continuity::REPL->new;
  $server = Continuity->new( port => 8080 );
  $server->loop;

  sub main {
    my $request = shift;
    my $count = 0;
    while(1) {
      $count++;
      $request->print("Count: $count");
      $request->next;
    }
  }

The command line interaction looks like this:

  main:001:0> $server
  $Continuity1 = Continuity=HASH(0x86468c8);

  main:002:0> $server->{mapper}->{sessions}
  $HASH1 = {
             19392613106888830468 => Coro::Channel=ARRAY(0x8d82038),
             58979072056380208100 => Coro::Channel=ARRAY(0x8d78890)
           };

  main:003:0> Coro::State::list()                                                
  $ARRAY1 = [
              Coro=HASH(0x8d82208),
              Coro=HASH(0x8d78aa0),
              Coro=HASH(0x8d38b98),
              Coro=HASH(0x8d38a38),
              Coro=HASH(0x8b99248),
              Coro=HASH(0x825d6c8),
              Coro=HASH(0x81d7568),
              Coro=HASH(0x81d7518),
              Coro=HASH(0x81d7448)
            ];

=head1 DESCRIPTION

This provides a Devel::REPL shell for Continuity applications.

For now it is just amusing, but it will become useful once it can run the shell
within the context of individual sessions. Then it might be a nice diagnostic
or perhaps even development tool. Heck... maybe we can throw in a web interface
to it...

Also, this library forces the PERL_RL environment variable to 'Perl' since I
haven't been able to figure out how to hack Term::ReadLine::Gnu yet.

=cut

use Moose;

# For now we'll force Term::ReadLine::Perl since GNU doesn't work here
BEGIN { $ENV{PERL_RL} = 'Perl' }

use Devel::REPL;
use Coro;
use Coro::Event;
use Term::ReadLine::readline;

has repl => (is => 'rw');

{
  package readline;

  no warnings 'redefine';
  sub rl_getc {
    my $key;
    $Term::ReadLine::Perl::term->Tk_loop
      if $Term::ReadLine::toloop && defined &Tk::DoOneEvent;
      my $timer = Coro::Event->timer(interval => 0);
    until($key = Term::ReadKey::ReadKey(-1, $readline::term_IN)) {
      $timer->next;
    }
  }

  $readline::rl_getc = \&rl_getc;
}


# Someday maybe something like this will work for the GNU backend
 # $repl->term->{getc_function} = sub {
  # print STDERR "Here in getc!\n";
      # my $timer = Coro::Event->timer(interval => 0);
      # $timer->next;
  # my $FILE = $repl->term->{instream};
  # # print STDERR "file: $FILE\n";
   # return Term::ReadLine::Gnu::XS::rl_getc($FILE);
# };

=head1 METHODS

=head2 $c_repl = Continuity::REPL->new( repl => $repl );

Create and start a new REPL on the command line. Optionally pass your own Devel::REPL object. If you don't pass in $repl, a default is created.

=cut

sub BUILD {
  my $self = shift;
  unless($self->repl) {
    $self->repl( $self->default_repl );
  }
     my $timer = Coro::Event->timer(interval => 0 );
  async {
     while ($timer->next) {
       $self->repl->run_once;
     }
  };
  return $self;
}

=head2 default_repl

This internal method creates the default REPL if one isn't specified.

=cut

sub default_repl {
  my $self = shift;

  my $repl = Devel::REPL->new;
  $repl->load_plugin($_) for qw(
    History
    LexEnv
    Completion CompletionDriver::LexEnv
    CompletionDriver::Keywords
    Colors MultiLine::PPI
    FancyPrompt
    DDS Refresh Interrupt Packages
    ShowClass
  );

  $repl->fancy_prompt(sub {
    my $self = shift;
    sprintf '%s:%03d%s> ',
      $self->can('current_package') ? $self->current_package : 'main',
      $self->lines_read,
      $self->can('line_depth') ? ':' . $self->line_depth : '';
  });

  $repl->fancy_continuation_prompt(sub {
    my $self = shift;
    my $pkg = $self->can('current_package') ? $self->current_package : 'main';
    $pkg =~ s/./ /g;
    sprintf '%s     %s* ',
      $pkg,
      $self->lines_read,
      $self->can('line_depth') ? $self->line_depth : '';
  });

  $repl->current_package('main');

  return $repl;
}

=head1 SEE ALSO

L<Continuity>, L<Devel::REPL>, L<Coro::Debug>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2008 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or modify
  it under the same terms as Perl 5.10 or later.

=cut

1;

