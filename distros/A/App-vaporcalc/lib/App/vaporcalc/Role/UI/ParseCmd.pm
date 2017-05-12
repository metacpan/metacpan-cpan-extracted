package App::vaporcalc::Role::UI::ParseCmd;
$App::vaporcalc::Role::UI::ParseCmd::VERSION = '0.005004';
use Defaults::Modern;

use App::vaporcalc::Exception;

use Text::ParseWords;

use Role::Tiny;
requires 'subject_list';


method parse_cmd (Str $str) {
  # e.g.:
  #   set nic base 100
  #   nic base set 100  
  my ($subj, $verb);
  my $params = array;

  my @subjs = array(@{ $self->subject_list })
    ->nsort_by(sub { length })
    ->reverse
    ->all;
  SUBJ: for my $maybe (@subjs) {
    my $idx = index $str, $maybe;
    next SUBJ if $idx == -1;
    no warnings 'substr';
    if ($idx > 0) {
      my $prevchar = substr $str, ($idx - 1), 1;
      next SUBJ unless $prevchar eq ' ';
    }
    if ( (my $pos = $idx + length($maybe)) < length $str ) {
      my $nextchar = substr $str, $pos, 1;
      next SUBJ unless $nextchar eq ' ';
    }
    $subj = $maybe;
    substr $str, $idx, length($maybe), ' ';
    my $pieces = array( split ' ', $str );
    $verb = $pieces->shift;
    $params = array( 
      Text::ParseWords::parse_line('\s+', 0, $pieces->join(' '))
    );
    last SUBJ
  }

  unless ($subj) {
    App::vaporcalc::Exception->throw(
      message => "No subject to operate on",
    )
  }

  hash(
    subject => $subj,
    verb    => $verb,
    params  => $params
  )->inflate
}


1;

=pod

=head1 NAME

App::vaporcalc::Role::UI::ParseCmd

=head1 SYNOPSIS

  package MyCmdParser;
  use Moo;
  has subject_list => (
    is      => 'ro',
    builder => sub {
      [ 'nic base', 'flavor' ]
    },
  );
  with 'App::vaporcalc::Role::UI::ParseCmd';

  package main;
  my $parser = MyCmdParser->new;
  # Same as:
  # my $result = $parser->parse_cmd("nic base set 100");
  my $result = $parser->parse_cmd("set nic base 100");
  my $subj = $result->subject;  # 'nic base'
  my $verb = $result->verb;     # 'set'
  my $params = $result->params; # params as a List::Objects::WithUtils::Array

=head1 DESCRIPTION

A L<Moo::Role> for parsing command strings based on a list of valid subjects
(command targets).

=head2 REQUIRES

=head3 subject_list

The C<subject_list> method is expected to return an ARRAY or ARRAY-type object
containing a list of valid subjects.

=head2 METHODS

=head3 parse_cmd

Given a string, returns an inflated L<List::Objects::WithUtils::Hash>
with C<subject>, C<verb>, and C<params> accessors (see SYNOPSIS).

Used by L<App::vaporcalc::CmdEngine> to parse B<vaporcalc> commands.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
