package App::SimpleScan::Substitution;

use warnings;
use strict;
use English qw(-no_match_vars);
use Carp;

our $VERSION = '1.00';

use Carp;
use App::SimpleScan::TestSpec;
use App::SimpleScan::Substitution::Line;
use Graph;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(dictionary find_vars_callback 
                                         insert_value_callback) );

# Define base variable detector: any (possibly-nested) angle-bracketed string.
# Patterns to extract <variables> or >variables< from a string.
my $out_angled;
$out_angled = qr/ < ( [^<>] | (??{$out_angled}) )* > /x;
                  # open angle-bracket then ...
                      # non-angle chars ...
                            # or ...
                               # another angle-bracketed item ...
                                                 # if there are any ...
                                                   # and a close angle-bracket
my $in_angled;
$in_angled  = qr/ > ( [^<>] | (??{$in_angled}) )* < /x;
                  # open angle-bracket then ...
                      # non-angle chars ...
                            # or ...
                               # another angle-bracketed item ...
                                                 # if there are any ...
                                                   # and a close angle-bracket
my $in_or_out_bracketed = qr/ ($out_angled) | ($in_angled) /x;

sub _find_angle_bracketed {
  my ($string) = @_;
  local $_;
  my @artifacted = ( $string =~ /$in_or_out_bracketed/xg );    # match bracketed+artifacts
  my @defed = grep { defined $_ } @artifacted;
  my @angled = grep { ($_) = /^[<>](.*?)[<>]$/ } @defed;
  return @angled;
  #return grep { ($_) = /^[<>](.*?)[<>]$/ }         # true angle-bracketed text
  #       grep { defined $_ }                       # can include undef items
  #       ( $string =~ /($angle_bracketed)/xg );    # match bracketed+artifacts
}

sub _insert_value {
  my ($string, $variable, $value) = @_;
  my $was_inserted;
  $was_inserted ||= ($string =~ s/<$variable>/$value/gs);
  $was_inserted ||= ($string =~ s/>$variable</$value/gs);
  ($was_inserted, $string);
}


################################
# Basic class methods.

# Create object: 
#  empty dictionary, default variable definition.
#  Update with values from the arg ref if they're there.
sub new {
  my ($class, $arg_ref) = @_;
  my $self = {};
  bless $self, $class;

  $self->dictionary({});
  $self->find_vars_callback(\&_find_angle_bracketed);
  $self->insert_value_callback(\&_insert_value);

  if ($arg_ref) {
    if (ref $arg_ref eq 'HASH') {
      if (exists $arg_ref->{dictionary}) {
        if (ref $arg_ref->{dictionary} eq 'HASH') {
         $self->dictionary($arg_ref->{dictionary});
        }
        else {
         croak "'dictionary' must be a hash reference";
        }
      }
      if (exists $arg_ref->{find_vars_callback}) {
        if (ref $arg_ref->{find_vars_callback} eq 'CODE') {
          $self->dictionary($arg_ref->{find_vars_callback});
        }
        else {
          croak "'find_vars_callback' must be a code reference";
        }
      }
    }
    else {
      croak "Argument to new is not a hash reference";
    }
  }
  
  return $self;
}

# We look at the current line and find substitution which is most deeply nested.
sub _deepest_substitution {
  my($self, $string) = @_;
       
  # We absolutely have to localize $_ because we may get called recursively
  # inside the map() below.
  local $_;
      
  # Get the variables in this line. We'll need these and all their
  # dependencies, but nothing else. This speeds up substitution in
  # a major way because we don't try fruitless variations of variables
  # that are not (and can't be) substituted into the line.
  #
  # First, parse the unique substitutions out of the line.
        
  # Extract text corresponding to variables to be substituted.
  my @vars =  $self->find_vars_callback()->($string);

  # There seem to be none.
  return unless @vars;
           
  # It's possible that a variable was mentioned multiple times in a line.
  # Extract only the unique names.
  my %unique_vars = map {$_ => 1} @vars;

  # We only want the simple variables now.
  @vars = keys %unique_vars;
  local $_;

  my %finished;
  while (@vars) {
    my $current = shift @vars;
    my @deeper = $self->_deepest_substitution($current);
    if (@deeper) {
      push @vars, @deeper;
    }
    else {
      $finished{$current}++;
    }
  }
  return keys %finished;
}

# If the current thing has substitutions in it, do them and
# return the line objects created by this. Otherwise, just
# return the lines as they are.
sub expand {
  my($self, @lines) = @_;

  # No lines; do nothing.
  return () if @lines == 0;

  # A single line; find the variables in it and expand them.
  if (@lines == 1) {
    # Nothing to do if no vars found.
    return $lines[0] unless $self->find_vars_callback->($lines[0]);

    return map {"$_" } $self->_expand_variables(
      App::SimpleScan::Substitution::Line->new($lines[0])
    );
  }
  # Multiple lines; do them one at a time and return the results of 
  # doing them all.
  else {
    my @done;
    foreach my $line (@lines) {
      push @done, $self->_expand($line);
    }
    return map { "$_" } @done;
  }
}

# Actually do variable substitutions.
sub _expand_variables {
  # We get a Line object. This object has its own "fixed" dictionary
  # associated with it: this defines the variables that have already
  # been expanded once for this Line. We have this because it's possible
  # that a later expansion may insert one of these variables into the 
  # line again, and we want to have a consistent value for the variable(s)
  # we've already inserted once.
  my ($self, @line_objs) = @_;

  # No objects, no output.
  return unless @line_objs;

  # More than one: process each one separately.
  return map { $self->_expand_variables($_) } @line_objs
   if @line_objs > 1;

  # A single line object; process it.
  my $line_obj = $line_objs[0];

  # Clone the dictionary, because we're going to modify it with the
  # fixed values. This effectively prunes the substitution tree at the
  # points where we've already done substitutions.
  my %dictionary = (%{ $self->dictionary() }, $line_obj->fixed);
 
  # Localize the slot that contains the dictionary and replace it
  # with our newly-constructed, possibly-pruned one.
  local($self->{dictionary}) = \%dictionary;

  # Find the most-deeply-nested substitutions; we need to do those first;
  # prune out anything that looks like a variable, but isn't (because
  # there's no value for it in the dictionary).
  my @var_names = grep { defined $self->dictionary->{$_} }
                  $self->_deepest_substitution("$line_obj");

  # We have none.
  return $line_obj unless @var_names;

  # What we want to do is to get every possible combination of the
  # active variables in this line from the dictionary, and substitute
  # all these into the line.
  #
  # Since we have a situation where we don't know how many variables there
  # are, we can't just code this as a set of nested loops. What we do instead
  # is map each possible combination into a "combination index": think of it
  # as the decimal representation of a number in a number system where each
  # position in this system's representation maps into a specific variable.
  # The number of possible values for this "place" in the number corresponds
  # to the number of possible values for thr variable.
  #
  # It's easy for us to calculate the number of possible combinations: we
  # simply multiply the number of possible values of all of the variables,
  # and we get the maximum possible combination index. We can now iterate
  # from zero to this maxiumum index, converting the decimal number back into
  # a number in the combinatorial number system; the representation we get
  # from doing this exactly maps into the proper indexes into the possible
  # values for each variable.

  # Count the number of items for each substitution,
  # and calculate the maximum combination index from this.
  my %item_count_for;
  my $max_combination = 1;
  for my $var_name (sort @var_names) {
     $max_combination *= 
      $item_count_for{$var_name} = () = 
        $self->substitution_value($var_name);
  }

  # The done queue gets Line objects that don't expand further;
  # the expansion queue gets things that expanded at least once
  # (so they need to be checked again).
  my @done_queue;
  my @expansion_queue;

  for my $i (0 .. $max_combination-1) {

    # Get the values for the variables for the current combination index.
    my %current_value_of = $self->_comb_index($i, %item_count_for);

    # Clone the current line. This keeps the fixed items and copies
    # the line text.
    my $changed_line = $line_obj->clone();
    my $string_to_alter = $changed_line->line();
    my $a_substitution_happened;

    # Try to substitute each of the currently variables into the line.
    for my $var_name (@var_names) {
      my $current_variable_value = $current_value_of{$var_name};
      my($did_change, $new_string) = 
        $self->insert_value_callback->($string_to_alter, 
                                       $var_name, 
                                       $current_variable_value);
      if ($did_change) {
        # Substitution worked. Fix this in the new line object.
        $changed_line->fix($var_name, [$current_variable_value]);
        $changed_line->line( $string_to_alter = $new_string );
      }
    }
    
   
    # Decide which queue to put this object on and put it there.
    my $proper_queue = ($self->find_vars_callback->($string_to_alter)
                          ? \@expansion_queue
                          : \@done_queue
    ); 
    push @{ $proper_queue }, $changed_line;
  }

  if (@expansion_queue) { 
    return @done_queue, $self->_expand_variables(@expansion_queue);
  }
  else {
    return @done_queue;
  }
}

sub _comb_index {
  # this subroutine converts a combination index to a specific set of 
  # values, one for each of the variables in the list.
  my($self, $index, %item_counts) = @_;
  my @indexes = $self->_comb($index, %item_counts);
  my $i = 0;
  my %selection_for;
  my @ordered_keys = sort keys %item_counts;
  local $_;                                                ##no critic
  my %base_map_of = map { $_ => $i++ } @ordered_keys;
  for my $var (@ordered_keys) {
    my $value_ref = $self->substitution_value($var);
    if (defined $value_ref) {
      $selection_for{$var} = 
        $self->substitution_value($var)->[$indexes[$base_map_of{$var}]];
    }
    else {
      $selection_for{$var} = undef;
    }
  }
  return %selection_for;
}

sub _comb {
  # Convert a combination index into a list of indexes into the 
  # value arrays. We don't try to look up tha values, just calculate
  # the indexes.
  my($self, $index, %item_counts) = @_;
  my @base_order = sort keys %item_counts;
  my @comb;
  my $place = 0;

  # All indexes must start at zero.
  my $number_of_items = scalar keys %item_counts;
  foreach my $item (keys %item_counts) {
    push @comb, 0;
  }

  # convert from base 10 to the derived multi-base number
  # that maps into the indexes into the possible values.
  while ($index) {
    $comb[$place] = $index % $item_counts{$base_order[$place]};
    $index = int $index/$item_counts{$base_order[$place]};
    $place++;
  }
  return @comb;
}

# setter/getter for substitution data.
# - setter needs a name and a list of values.
# - getter needs a name, returns a list of values.
sub substitution_value {
  my ($self, $pragma_name, @pragma_values) = @_;
  if (! defined $pragma_name) {
    die 'No pragma specified';
  }
  if (@pragma_values) {
    $self->dictionary->{$pragma_name} = \@pragma_values;
  }
  return 
    wantarray ? ( exists $self->dictionary->{$pragma_name} 
                    ? @{$self->dictionary->{$pragma_name}}
                    : () )
              : $self->dictionary->{$pragma_name};
}

sub delete_substitution {
  my ($self, $substitution_name) = @_;
  return unless defined $substitution_name;
  delete $self->dictionary->{$substitution_name};
  return;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Substitution - simple_scan variable substitution support

=head1 SYNOPSIS

    use App::SimpleScan::Substitution;
    # App::SimpleScan::Substitution->new() will create a new object
    # with an empty dictionary: any string passed to it will be returned
    # unchanged.
    #
    # Create a new object using a dictionary

    my $engine = App::SimpleScan::Substitution( { defs => \%dictionary } );
    my @substituted_strings = $engine->expand($string);

    # Swap dictionaries.
    $engine->dictionary(\%new_hash);
    my @different_strings = $engine->expand($string);

=head1 DESCRIPTION

C<App::SimpleScan::Substitution> encapsulates simple_scan's combinatorial
substitution algorith in a class. This allows us to isolate it from the
rest of simple_scan's code (and potentially reuse it later).

=head1 INTERFACE

=head2 Class methods

=head3 new 

Creates a new instance of the substitution engine. If a dictionary is
supplied, it is stored to be used during calls to expand().

=head2 Instance methods

=head3 dictionary()

Replaces the current dictionary with a new one. The dictionary is passed in
as a hash reference and stored as such. This means if the dictionary hash is
changed externally, then the updates are automatically reflected in the 
dictionary we'll use.

=head3 expand(@strings)

Expands the string (or strings) passed as an argument using the current
dictionary.

=head2 substitution_value($name, @optional_values)

Setter/getter for dictionary entries. If a list of values is supplied,
the substitution value is set. In all cases, the value is returned.

=head3 delete_substitution($name)

Deletes the named substitution from the dictionary. No action if the 
substitution is not found.

=head1 DIAGNOSTICS

=over 4

=item C<< Argument to new is not a hash ref >>

The new() argument must be a hash ref, if any argument is supplied at all.
This is most commonly caused by supplying 'dictionary => /%some hash' and
forgetting to put curly braces around it.

=item C<< dictionary must be a hash reference >>

You passed in a value for dictionary that wasn't a hash reference. Did you
forget to say \%hash?

=item C<< find_vars_callback must be a code reference >>

You passed in a value for find_vars_callback that wasn't a code reference. 
Did you try to just use a regex without sub{} around it?

=back 

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Substitution requires no configuration files or environment variables.

=head1 DEPENDENCIES

None. 

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Joe McMahon C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
