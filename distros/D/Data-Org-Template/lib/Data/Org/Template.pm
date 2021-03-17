package Data::Org::Template;

use 5.006;
use strict;
use warnings;

use Carp;
use Iterator::Simple;
use Data::Dumper;

=head1 NAME

Data::Org::Template - template engine that plays well with iterators

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

  
=head1 CREATING A TEMPLATE

=head2 new (text, [start, end])

Aside from the text to be loaded as a template, you can also provide delimiters for the fields in C<start> and C<end>. If only one string is provided, it is assumed to encode
both start *and* end, and will be split in equal halves. The default delimiters are C<[[> and C<]]>.

=cut

# [< template_test2|parse_template]
sub new {
   my ($class, $text, $start, $end) = @_;
   my $self = bless ({}, $class);
   
   if (ref($text) eq 'ARRAY') {
      $self->{template} = $text;
   } else {
      $self->{template} = _parse_template ($text, $start, $end);
   }
   $self;
}



sub _parse_template {
   my ($text, $start, $end) = @_;
   if (not defined $end) {
      if (not defined $start) {
         $start = '[[';
         $end = ']]';
      } else {
         if (length ($start) % 2) {
            croak "unmatched template field delimiters $start";
         } else {
            $end = substr($start, length($start)/2);
            $start = substr($start, 0, length($start)/2);
         }
      }
   }
   my $template = [];

   my @pieces = _split_template ($text, $start, $end);
   my @stack = ([0, $template]); # 2018-09-08 the stack for pushing section directives
   my $swallow_nl = 0;
   while (@pieces) {
      my $piece = shift(@pieces);
      my ($type, $what) = @$piece;
      if ($type) {
         if ($what eq '.' or $what =~ /^\.\|/) {
            push @$template, ['?', $what];
         }
         elsif ($what =~ /^\./) { # 2018-09-08 section/subsection tag
            $swallow_nl = 1;
            if ($what eq '..') { # section end
               shift @stack if ($stack[0]->[0]); # Pop top of stack if it's a subsection.
               shift @stack unless scalar (@stack) < 2; # .. pops the stack unless the stack is already at the top
               $template = $stack[0]->[1];
            } elsif ($what =~ /^\.\./) { # new subsection
               shift @stack if ($stack[0]->[0]); # Subsections can't nest.
               my $section = $stack[0]->[1];
               $what =~ s/^\.\.//;
               my ($tag, $parm) = split " ", $what, 2;
               #my $section = node_add_child ($template, defined $parm ? node_from_string ("$tag: " . '"' . quote_escape($parm) . '"')
               #                                                          : node_from_string ($tag));
               my $subsection = [$tag, $parm, []];
               $section->[2]->{$tag} = $subsection;
               unshift @stack, [1, $subsection];
               #$template = $section;
               $template = $subsection->[2];
            } else { # top-level section start
               $what =~ s/^\.//;
               my ($tag, $parm) = split " ", $what, 2;
               #my $section = node_add_child ($template, defined $parm ? node_from_string ("$tag: " . '"' . quote_escape($parm) . '"')
               #                                                          : node_from_string ($tag));
               my $subsection = ['.', undef, []];
               my $section = [$tag, $parm, { '.' => $subsection}];
               push @$template, $section;
               unshift @stack, [0, $section];
               unshift @stack, [1, $subsection];
               #$template = $section;
               $template = $subsection->[2];
            }
         } elsif ($what =~ /^!/) { # 2018-09-09 banged directive
            $swallow_nl = 1;
            $what =~ s/^!//;
            my ($tag, $parm) = split " ", $what, 2;
            #node_add_child ($template, defined $parm ? node_from_string ("$tag: " . '"' . quote_escape($parm) . '"')
            #                                           : node_from_string ($tag));
            push @$template, defined $parm ? [$tag, $parm] : [$tag];
         } else {
            #node_add_child ($template, node_from_string ("insert_value: $what"));
            push @$template, ['?', $what];
         }
      } else { # If there's anything after us, we can't emit a carriage return at the end.
         my @lines = split /^/, $what;
         while (scalar @lines and $lines[0] =~ /^ /) {
            my $line = shift (@lines);
            #node_add_child ($template, node_from_string ('lit "' . quote_escape($line) . (scalar(@lines) ? '\n"' : '"')));
            push @$template, ['lit', $line . (scalar(@lines) ? "\n" : '')];
            $swallow_nl = 0; # any output invalidates the swallow-nl flag
         } # Now we have no leading spaces.
         # We only care about the last line as a lit. This logic below is kind of weird because it evolved from
         # different assumptions (which were wrong). May need to rewrite. Maybe already did?
         if (scalar @lines) {
            # 2018-09-07 - yeah, it was wrong in the case that we have a newline followed immediately by a value field.
            #my $last_line = pop(@lines);
            #node_add_child ($template, tagless_text (join ("", @lines))) if scalar @lines;
            #node_add_child ($template, node_from_string ('lit "' . quote_escape($last_line) . '"'));
            foreach my $line (@lines) {  # 2018-09-07 - just output everything as a lit instead of screwing around with tagless text, which has syntactic issues anyway.
               if ($swallow_nl and $line eq "\n") { # 2018-09-08 - swallow linefeed after section directive if there's no additional text on that line.
               } else {
                  #node_add_child ($template, node_from_string ('lit "' . quote_escape($line) . '"'));
                  push @$template, ['lit', $line];
               }
               $swallow_nl = 0;
            }
         }
      }
   }
   $stack[0]->[1];
}

sub _regexp_escape {
   my $re = shift;
   $re =~ s/([.\^*+?()[{\\|*])/\\$1/g;
   return $re;
}

sub _split_template {
   my ($text, $start, $end) = @_;
   
   $start = _regexp_escape ($start);
   $end   = _regexp_escape ($end);

   my @out = ();
   foreach my $bit (split (/($start.+?$end)/, $text)) {
      if ($bit =~ /$start(.*)$end/) {
         push @out, [1, $1];
      } else {
         push @out, [0, $bit] unless $bit eq '';
      }
   }
   return @out;
}

=head1 EXPRESSING A TEMPLATE

A template can be either fully or partly expressed. If it's only partly expressed, the result is a new template with some of the
fields replaced with values, and others left intact.

If the template uses transducers we don't recognize, it will croak with an appropriate warning.

=head2 iter([data getter])

Starts a token iterator from the template. A token stream, the way I do it, is an iterator for which each value returned is either
a string (plain text) or a token. A token is an arrayref of [type, value, <arbitrary stuff>], so extracting the value is easy.

If no data getter is specified, uses the one registered in the template. If none is registered, croaks because you can't express a template on nothing, can you?

=cut

sub iter {
   my $self = shift;
   
   my $context = undef;
   if (scalar @_) {
      $context = [@_];
   }
   my $data_getter = $self->{data};
   $data_getter = Data::Org::Template::Getter->new ({}) unless defined $data_getter;

   if (not defined $self->{transducer}) {  # Here, do some error checking once we have a transducer scan working.
      $self->{transducer} = {
         ':'    => \&Data::Org::Template::Transducer::text::tt,
         'nl'   => \&Data::Org::Template::Transducer::nl::tt,
         'lit'  => \&Data::Org::Template::Transducer::lit::tt,
         'if'   => \&Data::Org::Template::Transducer::if::tt,
         'with' => \&Data::Org::Template::Transducer::with::tt,
         'list' => \&Data::Org::Template::Transducer::list::tt,
         'else' => 'ignore',
         'alt'  => 'ignore',
         '?'    => \&Data::Org::Template::Transducer::value::tt,
         '*undefined*' => 'ignore',
      };
   }
   my $tags = $self->transducers_requested();
   foreach my $tag (@$tags) {
      croak ("Unknown transducer '$tag' used in template") unless $self->{transducer}->{$tag};
   }

   
   _express_template ($self->{template}, $data_getter, $context, 0, $self->{transducer});
}

sub _express_template {
   my ($template, $data_getter, $context, $indent, $transducer) = @_;
   
   $indent = 0 unless defined $indent;
   
   my @line_queue = ();
   my @token_queue = ();
   my $substream;
   my $local_indent = 0;  # The indent is how many spaces we have to insert after each line break;
                            # the local indent is how many *more* spaces a child would have to indent at the current position.
   my $needs_indent = 0;
   my @child_queue = (@$template); # Take a copy of the template for processing.
   
   return sub {
      if (scalar @line_queue) { # If lines are queued from the last token, return a line
         my $this_indent = $indent+$local_indent;
         if (scalar @line_queue == 1) {
            $local_indent = length($line_queue[0]);
         }
         return (' ' x $this_indent) . shift (@line_queue); # 2018-09-14 - I'm not convinced by this logic. I really need to do some additional testing of indentation.
      }
      
      SUBSTREAM:
      if (defined $substream) {
         my $token = $substream->();
         if (defined $token) {
            my $val = $token;
            if (ref $token) {
               return $token if $token->[0] eq '"'; # Text to be passed through without examination (already indented properly)
               $val = $token->[1];
            }
            if ($val eq "\n") { # 2018-09-14
               # Tokens that are themselves simply a line end get passed through with their type.
               $local_indent = 0;
               return $token;
            } elsif ($val =~ /\n/) {
               # A token that *has* line breaks, though, can't stay a token because we may have to indent it.
               # Split into lines and deal with it as plain text.
               @line_queue = split /^/, $val;
               return shift (@line_queue); # Return first line right now
            } else {
               # No line breaks means we just increment our local indent, then emit this token
               $local_indent += length($val);
               return $token;
            }
         }
         $substream = undef;
         # fall through to next child for another substream if this one is exhausted
      }
      
      NEXT_CHILD:
      if (scalar @child_queue) { # Is there still template to be expressed?
         my $child = shift (@child_queue);
         my $lookup = $child->[0];
         $lookup = ':' if not $lookup; # Tagless text (not actually needed with this AST, but still)
         my $tt = $transducer->{$lookup};
         if (not defined $tt) { # Do we keep this?
            $tt = $transducer->{'*undefined*'};
         }
         if (not defined $tt) {
            croak ("undefined transducer $tt encountered in template");
         }
         goto NEXT_CHILD unless ref $tt; # Skip any "ignore" tags we've explicitly identified
         $substream = $tt->($child, $data_getter, $context, $indent + $local_indent, $transducer);
         goto SUBSTREAM;
      }
      return undef;
   }
}

=head2 _compile_token_stream ($stream)

This is just a helper function - NOT object-oriented in nature (the initial underscore might help you - and me - remember that).

=cut

sub _compile_token_stream { # 2018-09-13
   my $stream = shift;
   
   my $output = '';
   my $tok;
   while (1) {
      $tok = $stream->();
      return $output unless defined $tok;
      if (not ref $tok) {
         $output .= $tok;
      } else {
         $output .= $tok->[1]; # A non-string token is an arrayref with a type, the string content, and arbitrary additional data
      }
   }
}

=head2 text()

Compiles the iterator into an output string for you, using C<_compile_token_stream>.

=cut

sub text {
   my $self = shift;
   _compile_token_stream ($self->iter (@_));
}

# Token stream manipulators.
sub quote_substream {
   my $stream = shift;
   sub {
      my $v = $stream->();
      return $v if not defined $v;
      return $v if ref $v;
      return ['"', $v];
   }
}
sub undef_stream {
   sub { return undef };
}

=head1 REGISTERING A DATA GETTER

A template can be expressed by providing a data getter (a map from name to value) at expression time, but you can also register a default data getter against
the template when you define it, for convenience.

=cut

=head2 data_getter ([data getter])

Sets or gets the current data getter for the template. If you pass one or more data getters (which can be a data getter object, a hashref, or an arrayref of other
data getters) then each will be checked in sequence.

=cut

sub data_getter {
   my $self = shift;
   return $self->{data} unless @_;
   if (scalar @_ eq 1) {
      $self->{data} = Data::Org::Template::Getter->new ($_[0]);
   } else {
      $self->{data} = Data::Org::Template::Getter->new ([@_]);
   }
   $self->{data};
}

#=head2 check_data_requested ()
# Checks the data requested against the current data getter, if any. Returns a list of values I<not> available in the getter.
#=cut


# --------------------------------------------------------------
# Working with custom transducers, only sketched out
# --------------------------------------------------------------
#=head2 data_requested ()  -- this is yet to come
#
#=cut
#
#=head2 transducers_requested ()
#
#This provides a list of the transducers used in the template. It's really only of use if you're using custom transducers.
#
#=cut

# This will really only come in handy once I have a need for custom transducers; it's left over from an earlier prototype where I was playing with exactly that.
sub transducers_requested {
   my $self = shift;
   my $bag = {};
   _list_transducers ($self->{template}, $bag);
   my @list = sort {$a cmp $b} keys %$bag;
   \@list;
}
sub _list_transducers {
   my ($template, $bag) = @_;
   foreach my $item (@$template) {
      $bag->{$item->[0]} = 1;
      if (scalar @$item > 2) {
         while (my ($k, $v) = each (%{$item->[2]})) {
            _list_transducers ($v->[2], $bag);
         }
      }
   }
}

#=head2 register_transducer ()
#
#=cut




# -----------------------------------------------------------------------------------------------------------
# Default getter: Data::Org::Template::Getter
# -----------------------------------------------------------------------------------------------------------

package Data::Org::Template::Getter;
use Scalar::Util qw(blessed);
use Data::Dumper;

sub new {
   my $class = shift;
   if (scalar @_ eq 1) { # If there's a single input and that input is already capable of acting like a getter, don't instantiate anything, just use it.
      my ($candidate) = @_;
      if (blessed($candidate) && $candidate->can('get') && $candidate->can('get_iterated')) {
         return $candidate;
      }
   }
   
   my $self = bless {}, $class;
   $self->{source} = [@_];
   $self->{formatter} = Data::Org::Template::Formatter->new();
   $self->{format} = $self->{formatter}->formatter;
   return $self;
}
sub new_raw {
   my $class = shift;
   my $self = bless {}, $class;
   $self->{source} = [@_];
   $self->{formatter} = undef;
   $self->{format} = sub { return $_[0]; };
   return $self;
}

sub formatter {
   my $self = shift;
   my $formatter = shift;
   if (defined $formatter) {
      $self->{formatter} = $formatter;
      $self->{format} = $self->{formatter}->formatter;
   }
   $self->{formatter};
}

sub get {
   my $self = shift;
   my $what = shift;
   return unless defined $what; # Should this croak?
   my $context = shift || $self->{source};  # A list of data packets in order of search; the first may be a scalar when we're in a list context.
   
   my @formatters;
   ($what, @formatters) = $self->{format}->($what);
   
   my $value = $self->_get($what, $context);
   while (defined $value and ref ($value) eq 'CODE') {
      $value = $value->();
   }
   
   foreach my $f (@formatters) {
      $value = $f->($value);
   }
   return $value;
}

sub _get {
   my $self = shift;
   my $what = shift;
   my $context = shift;
   
   return $context->[0] if $what eq '.'; # Special case for a list context.
   
   foreach my $source (@$context) {
      $source = $self->{source} if $source eq '*';
      next unless ref $source; # Just in case we're in a list and the first "source" is a scalar value.

      my $maybe;
      if (blessed($source)) {
         $maybe = $source->get ($what);
         return $maybe if defined $maybe;
         next;
      }
      
      if (ref($source) eq 'ARRAY') {
         $maybe = $self->_get ($what, $source);
         return $maybe if defined $maybe;
         next; # Here's a subtle error - leave this out. This surprised me.
      }

      # Must be a hash, then.
      return $source->{$what} if defined $source->{$what};
   }
   return undef;
}

sub get_iterated {
   my $self = shift;
   my $what = shift;
   my $context = shift || $self->{source};
   my $src = $self->get ($what, $context);
   
   return if not defined $src;
   
   # If this is a scalar, "iterate" over that single value.
   my $r = ref($src);
   if (not $r) { # -> new subcontext is an iterator that will return a single subframe, consisting of a hash frame and the existing context as a backup
      my $done = 0;
      return sub {
         return undef if $done;
         $done = 1;
         return [{'.' => $src}, {_total => 1, _count => 0}, @$context];
      }
   }
   # If a hash, iterate over the hash as a single child frame.
   if ($r eq 'HASH') { # -> new subcontext is an iterator that will return a single subframe
      return unless scalar keys (%$src); # An empty hash is equivalent to no data found
      my $done = 0;
      return sub {
         return undef if $done;
         $done = 1;
         return [$src, {_total => 1, _count => 0}, @$context];
      }
   }
   # If a list, it's obvious.
   if ($r eq 'ARRAY') {
      return unless scalar $src; # An empty list is equivalent to no data found
      my @queue = @$src;
      my $total = scalar @queue;
      my $count = 0;
      my $query_info = {
         _total => $total,
         _count => $count,
         _remaining => $total
      };
      
      return sub {
         return undef unless scalar @queue;
         $query_info->{_count} = $count;
         $query_info->{_remaining} = $total - $count - 1;
         $count += 1; # For next time
         my $next = shift @queue;
         return [$next, $query_info, @$context];
      }
   }
   if (blessed($src) && $src->can('iter_hash')) { # We have a record stream!
      my $count = 0;
      my $query_info = {
         _count => $count,
      };
      my $iter = $src->iter_hash(); # Might think of ways to pass parameters at some point.
      my $next = $iter->();
      return unless $next;
      
      return sub {
         return unless $next;
         $query_info->{_count} = $count;
         $count += 1; # For next time
         my $this = $next;
         $next = $iter->();
         return [$this, $query_info, @$context];
      }
   }
}

# -----------------------------------------------------------------------------------------------------------
# Formatting framework
# -----------------------------------------------------------------------------------------------------------

package Data::Org::Template::Formatter;

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   $self->{lookup} = {
      html => sub { \&html_encode },
   };
   $self;
}

sub register {
   my $self = shift;
   my $name = shift;
   return unless defined $name;
   my $formatter = shift;
   if (defined $formatter) {
      $self->{lookup}->{$name} = $formatter;
   }
   $self->{lookup}->{$name};
}

sub formatter {
   my $self = shift;
   sub {
      $self->parse(shift);
   }
}

sub parse {
   my $self = shift;
   my $spec = shift;
   
   my @coderefs = ();
   while ($spec =~ /(.*)\| *([[:alnum:]][[:alnum:] \-_.*\/\\]*)$/) {
      my ($new_spec, $format) = ($1, $2);
      $spec = $new_spec;
      $spec =~ s/ *$//; # Drop trailing spaces, if any
      push @coderefs, $self->make_formatter ($format);
   }
   return ($spec, @coderefs);
}

sub make_formatter {
   my $self = shift;
   my $format = shift;
   my $parm = '';
   if ($format =~ /^([[:alnum:]]+)(.*)$/) {
      ($format, $parm) = ($1, $2);
   }
   my $formatter = $self->{lookup}->{$format};
   return sub { $_[0] } unless defined $formatter; # Error handling might be nice here
   return $formatter->($parm);
}

sub html_encode {
   my $str = shift;
   $str =~ s/&/&amp;/g;
   $str =~ s/</&lt;/g;
   $str =~ s/>/&gt;/g;
   $str;
}

# -----------------------------------------------------------------------------------------------------------
# Standard transducers: text, nl, lit, value, if, with, and list.
# -----------------------------------------------------------------------------------------------------------
package Data::Org::Template::Transducer::text;

sub values { () }
sub tt {
   my $source = shift;
   my $done = 0;
   sub {
      return undef if $done;
      $done = 1;
      return $source->[1] . "\n";
   }
}


package Data::Org::Template::Transducer::nl;

sub values { () }
sub tt {
   my $done = 0;
   sub {
      return undef if $done;
      $done = 1;
      return "\n";
   }
}

package Data::Org::Template::Transducer::lit;

sub values { () }
sub tt {
   my $source = shift;
   my $done = 0;
   sub {
      return undef if $done;
      $done = 1;
      return $source->[1];
   }
}

package Data::Org::Template::Transducer::value;

sub values { ($_[0]->[1]) }
sub tt {
   my ($source, $data_getter, $context, $indent, $transducer) = @_;
   my $value = $data_getter->get($source->[1], $context);
   my $done = 0;
   sub {
      return undef if $done;
      $done = 1;
      return $value;
   }
}


package Data::Org::Template::Transducer::if;

sub values { () }
sub tt {
   my ($source, $data_getter, $context, $indent, $transducer) = @_;

   if ($data_getter->get($source->[1], $context)) {
      return Data::Org::Template::quote_substream (Data::Org::Template::_express_template ($source->[2]->{'.'}->[2], $data_getter, $context, $indent, $transducer));
   } else {
      if (exists $source->[2]->{'else'}) {
         return Data::Org::Template::quote_substream (Data::Org::Template::_express_template ($source->[2]->{'else'}->[2], $data_getter, $context, $indent, $transducer));
      } else {
         return Data::Org::Template::undef_stream();
      }
   }
}

package Data::Org::Template::Transducer::with;

sub values { () }
sub tt {
   my ($source, $data_getter, $context, $indent, $transducer) = @_;
   my $ctx = $data_getter->get($source->[1], $context);
   if (defined $ctx) {
      return Data::Org::Template::quote_substream (Data::Org::Template::_express_template ($source->[2]->{'.'}->[2], $data_getter, [$ctx, '*'], $indent, $transducer));
   } else {
      if (exists $source->[2]->{'else'}) {
         return Data::Org::Template::quote_substream (Data::Org::Template::_express_template ($source->[2]->{'else'}->[2], $data_getter, $context, $indent, $transducer));
      } else {
         return Data::Org::Template::undef_stream();
      }
   }
}


package Data::Org::Template::Transducer::list;
use Data::Dumper;

sub values { () }
sub tt {
   my ($source, $data_getter, $context, $indent, $transducer) = @_;
   my $iter = $data_getter->get_iterated ($source->[1], $context);
   my $alt = $source->[2]->{alt};
   
   if (defined $iter) {
      my $subctx;
      my $next_subctx = $iter->();
      my $state = 0; # 0 = expressing row, 1 = expressing alt (if any)
      my $curstream;
      my $empty = 0;
      sub {
         return undef if $empty;
         DO_STREAM:
         if ($curstream) {
            my $tok = $curstream->();
            if (defined $tok) {
               return $tok if ref $tok;
               return ['"', $tok];
            }
            $state = not $state; # We exhausted this stream, so go to the next - alt if we just did a row, row if we just did an alt.
         }
         # No stream active - let's start one.
         NEXT_STATE:
         if ($state) { # We just did a row, so if there's an alt we should do it.
            if ($next_subctx and $alt) {
               $curstream = Data::Org::Template::_express_template ($alt->[2], $data_getter, $subctx, $indent, $transducer);
               goto DO_STREAM;
            } else {
               $state = 0;
               goto NEXT_STATE;
            }
         } else { # Start a new row.
            $subctx = $next_subctx;
            $next_subctx = $iter->();
            if (defined $subctx) {
               $curstream = Data::Org::Template::_express_template ($source->[2]->{'.'}->[2], $data_getter, $subctx, $indent, $transducer);
               goto DO_STREAM;
            }
            $empty = 1;
            return undef;
         }
      }
   } else {
      if (exists $source->[2]->{'else'}) {
         return Data::Org::Template::quote_substream (Data::Org::Template::_express_template ($source->[2]->{'else'}->[2], $data_getter, $context, $indent, $transducer));
      } else {
         return Data::Org::Template::undef_stream();
      }
   }
}



=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-org at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Org-Template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Org::Template


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Org-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Org-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Org-Template>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Org-Template/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::Org::Template
