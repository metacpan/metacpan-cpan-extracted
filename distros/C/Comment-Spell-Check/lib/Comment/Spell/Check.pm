use 5.006;
use strict;
use warnings;

package Comment::Spell::Check;

our $VERSION = '0.002001';

# ABSTRACT: Check words from Comment::Spell vs a system spell checker.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has extends around );
use Carp qw( croak carp );
use Devel::CheckBin qw( can_run );
use IPC::Run qw( run timeout );
use Text::Wrap qw( wrap );
use File::Spec;

extends 'Comment::Spell';

has 'spell_command'            => ( is => 'ro', lazy => 1, builder => '_build_spell_command' );
has 'spell_command_exec'       => ( is => 'ro', lazy => 1, builder => '_build_spell_command_exec' );
has 'spell_command_args'       => ( is => 'ro', lazy => 1, default => sub { [] } );
has '_spell_command_base_args' => ( is => 'ro', lazy => 1, builder => '_build_spell_command_base_args' );
has '_spell_command_all_args'  => ( is => 'ro', lazy => 1, builder => '_build_spell_command_all_args' );

my $arg_defaults = {
  'spell'    => [],
  'aspell'   => [ 'list', '-l', 'en', '-p', File::Spec->devnull, ],
  'ispell'   => [ '-l', ],
  'hunspell' => [ '-l', ],
};

sub _run_spell {
  my ( $command, $words ) = @_;
  my @badwords;
  local $@ = undef;
  my $ok = eval {
    my ( $results, $errors );
    run $command, \$words, \$results, \$errors, timeout(10);
    @badwords = split /\n/msx, $results;
    croak 'spellchecker had errors: ' . $errors if length $errors;
    1;
  };
  chomp for @badwords;
  return ( $ok, \@badwords, $@ );
}

sub _can_spell {
  my ($name) = @_;
  return unless my $bin = can_run($name);
  my ( $ok, $words, ) = _run_spell( [ $bin, @{ $arg_defaults->{$name} || [] } ], 'iamnotaword' );
  return unless $ok;
  return unless @{$words};
  return unless 'iamnotaword' eq $words->[0];
  return $bin;
}

sub _build_spell_command_exec {
  my @candidates = (qw( spell aspell ispell hunspell ));
  for my $candidate (@candidates) {
    return $candidate if _can_spell($candidate);
  }
  return croak <<"EOF";
Cant determine a spell checker automatically. Make sure one of: @candidates are installed or configure manually.
EOF
}

sub _build_spell_command_base_args {
  my ($self) = @_;
  my $cmd = $self->spell_command_exec;
  return ( $arg_defaults->{$cmd} || [] );
}

sub _build_spell_command_all_args {
  my ($self) = @_;
  return [ @{ $self->_spell_command_base_args }, @{ $self->spell_command_args } ];
}

sub _build_spell_command {
  my ($self) = @_;
  return [ can_run( $self->spell_command_exec ), @{ $self->_spell_command_all_args } ];
}

sub _spell_text {
  my ( $self, $text ) = @_;
  my @command = @{ $self->spell_command };
  my ( $ok, $words, $err ) = _run_spell( \@command, $text );
  if ( not $ok ) {
    carp $err;
  }
  return @{$words};
}

around 'parse_from_document' => sub {
  my ( $orig, $self, $document, @rest ) = @_;
  local $self->{fails} = [];    ## no critic (Variables::ProhibitLocalVars)
  my %counts;
  local $self->{counts}     = \%counts;    ## no critic (Variables::ProhibitLocalVars)
  local $self->{line_cache} = [];          ## no critic (Variables::ProhibitLocalVars)

  $document->index_locations;
  $self->$orig( $document, @rest );
  $self->_process_line_cache() if @{ $self->{line_cache} };

  if ( keys %counts ) {

    # Invert k => v to v => [ k ]
    my %values;
    push @{ $values{ $counts{$_} } }, $_ for keys %counts;

    my $labelformat = q[%6s: ];
    my $indent      = q[ ] x 10;

    $self->_print_output( qq[\nAll incorrect words, by number of occurrences:\n] . join qq[\n],
      map { wrap( ( sprintf $labelformat, $_ ), $indent, join q[, ], sort @{ $values{$_} } ) }
      sort { $a <=> $b } keys %values );
    $self->_flush_output;
  }
  return { fails => $self->{fails}, counts => $self->{counts} };
};

sub _report_badwords {
  my ( $self, $start_line, $stop_line, @badwords ) = @_;    ## no critic (Variables::ProhibitUnusedVarsStricter)
  my %counts;
  $counts{$_}++ for @badwords;
  $self->{counts}->{$_}++ for @badwords;
  my $fail = {
    line   => $start_line,
    counts => \%counts,
  };
  push @{ $self->{fails} }, $fail;
  my $label = sprintf q[line %6s: ], q[#] . $start_line;
  my $indent = q[ ] x 13;
  local $Text::Wrap::huge = 'overflow';                     ## no critic (Variables::ProhibitPackageVars)
  my @printwords;

  for my $key ( sort keys %counts ) {
    if ( $counts{$key} > 1 ) {
      push @printwords, $key . '(x' . $counts{$key} . ')';
      next;
    }
    push @printwords, $key;
  }
  $self->_print_output( wrap( $label, $indent, join q[ ], @printwords ) );
  $self->_print_output(qq[\n]);
  return;
}

sub _process_line_cache {
  my ($self) = @_;
  my $text = join qq[\n], map { $_->[1] } @{ $self->{line_cache} };
  my (@badwords) = split /[ ]/sxm, $self->stopwords->strip_stopwords( join q[ ], $self->_spell_text($text) );
  my $start      = $self->{line_cache}->[0]->[0];
  my $stop       = $self->{line_cache}->[-1]->[0];

  @{ $self->{line_cache} } = ();

  return unless @badwords;
  $self->_report_badwords( $start, $stop, @badwords );
  return;
}

sub _push_line_cache {
  my ( $self, $line, $text ) = @_;
  if ( not @{ $self->{line_cache} } ) {
    push @{ $self->{line_cache} }, [ $line, $text ];
    return;
  }

  # If there is any gap between lines, consider it a new paragraph.
  if ( ( $line - $self->{line_cache}->[-1]->[0] ) > 1 ) {
    $self->_process_line_cache;
  }
  push @{ $self->{line_cache} }, [ $line, $text ];
  return;
}

sub _handle_comment {
  my ( $self, $comment ) = @_;
  $self->_push_line_cache( $comment->line_number, $self->_comment_text($comment) );
  return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Comment::Spell::Check - Check words from Comment::Spell vs a system spell checker.

=head1 VERSION

version 0.002001

=head1 OVERVIEW

This module is similar to Test::Spelling and Pod::Spell, except it uses Comment::Spell,
and is more oriented for use as a library, that could be used to write a test.

It also does something neither Test::Spelling or Pod::Spell presently can do: report line numbers
and per-line error counts for each source file read.

  # Spelling report to STDOUT by default
  perl -MComment::Spell::Check -E'Comment::Spell::Check->new->parse_from_file(q[Foo.pm])'

  # Advanced Usage

  my $speller = Comment::Spell::Check->new(
    spell_command_exec => 'aspell'  # override auto-detected default spelling engine
    spell_command_args => [ '--lang=en_GB' ], # pass additional commands to spell checker
  );

  my $buf;
  $speller->set_output_string($buf);
  my $result = $speller->parse_from_file("path/to/File.pm");
  # $buf now contains report
  # $result contains structured data that could be useful
  # Example:
  # {
  #   'counts' => {
  #     'abstraktion' => 4,
  #     'bsaic' => 1,
  #     'hmubug' => 2,
  #     'incpetion' => 1,
  #     'kepe' => 1,
  #     'ssshtuff' => 1,
  #     'thsi' => 1,
  #     'tset' => 1,
  #     'voreflow' => 1,
  #     'warppying' => 1,
  #     'wrods' => 1
  #   },
  #   'fails' => [
  #     {
  #       'counts' => {
  #         'abstraktion' => 1
  #       },
  #       'line' => 8
  #     },
  #     {
  #       'counts' => {
  #         'abstraktion' => 2
  #       },
  #       'line' => 9
  #     },
  #     {
  #       'counts' => {
  #         'abstraktion' => 1,
  #         'bsaic' => 1,
  #         'hmubug' => 2,
  #         'incpetion' => 1,
  #         'kepe' => 1,
  #         'ssshtuff' => 1,
  #         'thsi' => 1,
  #         'tset' => 1,
  #         'voreflow' => 1,
  #         'warppying' => 1,
  #         'wrods' => 1
  #       },
  #       'line' => 10
  #     }
  #   ]
  # }

I may eventually work out how to bolt line number parsing into Pod::Spell family, but at
present its hard due to the Pod::Parser underpinnings.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
