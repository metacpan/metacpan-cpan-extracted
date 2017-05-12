package App::redisp::EvalWithLexicals;

use Moo;
use Sub::Quote;

our $VERSION = '1.000000'; # 1.0.0
$VERSION = eval $VERSION;

has lexicals => (is => 'rw', default => quote_sub q{ {} });

{
  my %valid_contexts = map +($_ => 1), qw(list scalar void);

  has context => (
    is => 'rw', default => quote_sub(q{ 'list' }),
    isa => sub {
      my ($val) = @_;
      die "Invalid context type $val - should be list, scalar or void"
        unless $valid_contexts{$val};
    },
  );
}

has in_package => (
  is => 'rw', default => quote_sub q{ 'App::redisp::EvalWithLexicals::Scratchpad' }
);

sub eval {
  my ($self, $to_eval) = @_;
  local *App::redisp::EvalWithLexicals::Cage::current_line;
  local *App::redisp::EvalWithLexicals::Cage::pad_capture;
  local *App::redisp::EvalWithLexicals::Cage::grab_captures;
  my $setup = Sub::Quote::capture_unroll('$_[2]', $self->lexicals, 2);
  my $package = $self->in_package;
  local our $current_code = qq!
${setup}
sub App::redisp::EvalWithLexicals::Cage::current_line {
package ${package};
#line 1 "(eval)"
${to_eval}
;sub App::redisp::EvalWithLexicals::Cage::pad_capture { }
BEGIN { App::redisp::EvalWithLexicals::Util::capture_list() }
sub App::redisp::EvalWithLexicals::Cage::grab_captures {
  no warnings 'closure'; no strict 'vars';
  package App::redisp::EvalWithLexicals::VarScope;!;
  $self->_eval_do(\$current_code, $self->lexicals, $to_eval);
  my @ret;
  my $ctx = $self->context;
  if ($ctx eq 'list') {
    @ret = App::redisp::EvalWithLexicals::Cage::current_line();
  } elsif ($ctx eq 'scalar') {
    $ret[0] = App::redisp::EvalWithLexicals::Cage::current_line();
  } else {
    App::redisp::EvalWithLexicals::Cage::current_line();
  }
  $self->lexicals({
    %{$self->lexicals},
    %{$self->_grab_captures},
  });
  @ret;
}

sub _grab_captures {
  my ($self) = @_;
  my $cap = App::redisp::EvalWithLexicals::Cage::grab_captures();
  foreach my $key (keys %$cap) {
    my ($sigil, $name) = $key =~ /^(.)(.+)$/;
    my $var_scope_name = $sigil.'App::redisp::EvalWithLexicals::VarScope::'.$name;
    if ($cap->{$key} eq eval "\\${var_scope_name}") {
      delete $cap->{$key};
    }
  }
  $cap;
}

sub _eval_do {
  my ($self, $text_ref, $lexicals, $original) = @_;
  local @INC = (sub {
    if ($_[1] eq '/eval_do') {
      open my $fh, '<', $text_ref;
      $fh;
    } else {
      ();
    }
  }, @INC);
  do '/eval_do' or die $@;
}

{
  package App::redisp::EvalWithLexicals::Util;

  use B qw(svref_2object);

  sub capture_list {
    my $pad_capture = \&App::redisp::EvalWithLexicals::Cage::pad_capture;
    my @names = map $_->PV, grep $_->isa('B::PV'),
      svref_2object($pad_capture)->OUTSIDE->PADLIST->ARRAYelt(0)->ARRAY;
    $App::redisp::EvalWithLexicals::current_code .=
      '+{ '.join(', ', map "'$_' => \\$_", @names).' };'
      ."\n}\n}\n1;\n";
  }
}


1;
__END__
=pod

=head1 NAME

App::redisp::EvalWithLexicals

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  # file: bin/tinyrepl

  #!/usr/bin/env perl

  use strictures 1;
  use App::redisp::EvalWithLexicals;
  use Term::ReadLine;
  use Data::Dumper;

  $SIG{INT} = sub { warn "SIGINT\n" };

  { package Data::Dumper; no strict 'vars';
    $Terse = $Indent = $Useqq = $Deparse = $Sortkeys = 1;
    $Quotekeys = 0;
  }

  my $eval = App::redisp::EvalWithLexicals->new;
  my $read = Term::ReadLine->new('Perl REPL');
  while (1) {
    my $line = $read->readline('re.pl$ ');
    exit unless defined $line;
    my @ret; eval {
      local $SIG{INT} = sub { die "Caught SIGINT" };
      @ret = $eval->eval($line); 1;
    } or @ret = ("Error!", $@);
    print Dumper @ret;
  }

  # shell session:

  $ perl -Ilib bin/tinyrepl 
  re.pl$ my $x = 0;
  0
  re.pl$ ++$x;
  1
  re.pl$ $x + 3;
  4
  re.pl$ ^D
  $

=head1 NAME

App::redisp::EvalWithLexicals - pure perl eval with persistent lexical variables

=head1 VERSION

version 0.11

=head1 METHODS

=head2 new

  my $eval = App::redisp::EvalWithLexicals->new(
    lexicals => { '$x' => \1 },      # default {}
    in_package => 'PackageToEvalIn', # default App::redisp::EvalWithLexicals::Scratchpad
    context => 'scalar',             # default 'list'
  );

=head2 eval

  my @return_value = $eval->eval($code_to_eval);

=head2 lexicals

  my $current_lexicals = $eval->lexicals;

  $eval->lexicals(\%new_lexicals);

=head2 in_package

  my $current_package = $eval->in_package;

  $eval->in_package($new_package);

=head2 context

  my $current_context = $eval->context;

  $eval->context($new_context); # 'list', 'scalar' or 'void'

=head1 AUTHOR

Matt S. Trout <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None required yet. Maybe this module is perfect (hahahahaha ...).

=head1 COPYRIGHT

Copyright (c) 2010 the Eval::WithLexicals L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the terms of the Beerware license.

=cut

