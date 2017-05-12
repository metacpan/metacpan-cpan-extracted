# $Id: Matcher.pm,v 1.11 2004/06/11 21:50:53 claes Exp $

package Array::Stream::Transactional::Matcher;

use Array::Stream::Transactional::Matcher::Rule;
use Array::Stream::Transactional::Matcher::Logical;
use Array::Stream::Transactional::Matcher::Value;
use Array::Stream::Transactional::Matcher::Flow;

use 5.006001;
use Carp qw(croak confess);
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(mkrule) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '1.00';

sub mkrule {
  my $type = shift;
  $type =~ s/-/::/g;
  unless($type =~ /^Array::Stream::Transactional::Matcher::/) {
    $type = "Array::Stream::Transactional::Matcher::${type}";
  }
  return $type->new(@_);
}

sub new {
  my $class = shift;
  my %args = @_;
  croak "Missing mandatory argument 'rules'" unless(exists $args{rules} && ref $args{rules} eq 'ARRAY');
  my $self = bless {}, $class;

  my $default = undef;
  if(exists $args{call}) {
    croak "Argument 'call' must be a CODE reference" unless(ref $args{call} eq 'CODE');
    $default = $args{call};
  } else {
    $default = sub {};
  }
  
  my @rules;
  foreach(@{$args{rules}}) {
    if(ref $_ eq 'ARRAY') {
      my ($rule, $callback) = @{$_};
      croak "Rule match object must be an Array::Stream::Transactional::Matcher::Rule subclass" unless(UNIVERSAL::isa($rule, 'Array::Stream::Transactional::Matcher::Rule'));
      croak "Rule callback must be a CODE reference" unless(ref $callback eq 'CODE');
      push @rules, [ $rule, $callback ];
    } elsif (UNIVERSAL::isa($_, 'Array::Stream::Transactional::Matcher::Rule')) {
      push @rules, [ $_, $default ];
    } else {
      croak "Rule entry must be an Array::Stream::Transactional::Matcher::Rule or an ARRAY reference";
    }
  }

  $self->{rules} = \@rules;
  return $self;
}

sub rules {
  my $self = shift;
  return $self->{rules} || [];
}

sub match {
  my ($self, $stream) = @_;
  croak "Can't match a non Array::Stream::Transactional stream" unless(UNIVERSAL::isa($stream, 'Array::Stream::Transactional'));

  my @matches;

  my $match = 0;
 MATCH: while($stream->has_more) {
    my $start = $stream->pos;
    for my $rule (@{$self->rules}) {
      $match = $rule->[0]->match($stream);
      if($match) {
	my $end = $start == $stream->pos ? $start : $stream->pos - 1;
	push @matches, { rule => $rule, start => $start, end => $end };
	$rule->[1]->($rule->[0], $start, $end);
	next MATCH;
      }
    }
  } continue {    
    $stream->next unless($match == -1);
    $match = 0;
  }

  return @matches;
}

1;

__END__
=head1 NAME

Array::Stream::Transactional::Matcher - Perl extension for finding content in arrays

=head1 SYNOPSIS

  use Array::Stream::Transactional::Matcher qw(mkrule);
  use Array::Stream::Transactional;
  my $stream = Array::Stream::Transactional->new([1,5,3,2,5,2,4,1,1,2,3,2,2]);
  my $rule = mkrule(Flow::sequence => mkrule(Value::eq => 2), mkrule(Value::gt => 2));
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [$rule]);
  my @matches = $matcher->match($stream);
  for(@matches) {
    print "Found match at $_->{start} to $_->{end}\n";
  }

=head1 DESCRIPTION

Array::Stream::Transactional::Matcher allowes you to search an array for content based on arbitrary complex rules.

=head1 CONSTRUCTOR

=over 4

=item new ( %options )

This is the constructor for a matcher. Options are passed as keyword value pairs. Recognized options are:

=over 4

=item rules => ARRAYREF

Patterns we are looking for. Each element must either be a L<Array::Stream::Transactional::Matcher::Rule> subclass or an ARRAY reference where the first element is an L<Array::Stream::Transactional::Matcher::Rule> subclass and the second element is a CODE reference that is called when a match is found. If no custom handler is supplied, it'll try to use the handler supplied by I<call> or an empty subroutine if that wasn't found either.

=item call => CODEREF

A subroutine reference that is called when a match is made.

=back 

=back

=head1 METHODS

=over 4

=item match ( $STREAM )

Iterates over the L<Array::Stream::Transactional> object $STREAM and tries to match each item with the set of rules that are defined. If a rule matches, it continues with the next item in the stream.

The return value is an array of hashes containing the keys B<rule> which is a reference to the rule that matches, B<start> is the offset within the stream that the match where found and B<end> is the offset whinit the stream where the matching rule ended.

If a handler is supplied a handler or a default handler is supplied it is passed the matching rule, the start offset and end offset.

=item rules ()

Returns an ARRAY reference containing the rules that are defined.

=back

=head1 EXPORT

None by default.

=over 4

=item mkrule ( CLASS => @ARGS )

Shortcut for calling B<new> on Array::Stream::Transactional::Matcher::CLASS. 

=back

=head1 SEE ALSO

Rules implementing logical operators such as and, or, 
xor, not are described in L<Array::Stream::Transactional::Matcher::Logical> 

Rules implementing value tests such as eq, ne, lt 
and so forth are described in L<Array::Stream::Transactional::Matcher::Value>

Rules implementing flow os rules such as sequence, repetitions, optionals, 
switches are described in L<Array::Stream::Transactional::Matcher::Flow>

A short description on how to write custom rules is available in L<Array::Stream::Transactional::Rule>

=head1 AUTHOR

Claes Jacobsson, claesjac@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
