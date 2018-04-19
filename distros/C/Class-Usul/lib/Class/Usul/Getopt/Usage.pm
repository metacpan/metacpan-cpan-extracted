package Class::Usul::Getopt::Usage;

use strict;
use warnings;
use parent 'Getopt::Long::Descriptive::Usage';

use List::Util      qw( max );
use Term::ANSIColor qw( color );

my $NUL = q(); my $SPC = q( ); my $USAGE_CONF = {};

# Private functions
my $_tabstop = sub {
   my $v = $USAGE_CONF->{tabstop} // 3; return $v; # Eight is too much
};

my $_split_description = sub {
   my ($length, $desc) = @_; my $width = $USAGE_CONF->{width} // 78;
   # Length of a tab plus 2 for the space between option & desc;
   my $max_length = $width - ( $_tabstop->() + $length + 2 );

   length $desc <= $max_length and return $desc; my @lines;

   while (length $desc > $max_length) {
      my $idx = rindex( substr( $desc, 0, $max_length ), $SPC );

      $idx >= 0 or last;

      push @lines, substr $desc, 0, $idx; substr( $desc, 0, 1 + $idx ) = $NUL;
   }

   push @lines, $desc;
   return @lines;
};

my $_types = sub {
   my $k = shift; my $option_type = $USAGE_CONF->{option_type} // 'short';

   $option_type eq 'none'    and return;       # Old behaviour
   $option_type eq 'verbose' and return uc $k; # New behaviour

   my $types = $USAGE_CONF->{type_map}
            // { int => 'i', key => 'k', num => 'n', str => 's', };
   my $type  = $types->{ $k } // $NUL;         # Prefered behaviour

   return $type;
};

my $_parse_assignment = sub {
   my $assign_spec = shift; $assign_spec or return $NUL;

   length $assign_spec < 2 and return $NUL; # Empty, ! or +

   my $argument = substr $assign_spec, 1, 2;
   my $result   = $_types->( 'str' );

   if    ($argument eq 'i' or $argument eq 'o') { $result = $_types->( 'int' ) }
   elsif ($argument eq 'f') { $result = $_types->( 'num' ) }

   if (length $assign_spec > 2) {
      my $desttype = substr $assign_spec, 2, 1;

      # Imply it can be repeated
      if    ($desttype eq '@') { $result .= '...' }
      elsif ($desttype eq '%') {
         $result = $result ? $_types->( 'key' )."=${result}..." : $NUL;
      }
   }

   substr $assign_spec, 0, 1 eq ':' and return "[=${result}]";
   # With leading space so it can just blindly be appended.
   return $result ? " $result" : $NUL;
};

my $_assemble_spec = sub {
   my ($length, $spec) = @_;

   my $stripped  = [ Getopt::Long::Descriptive->_strip_assignment( $spec ) ];
   my $assign    = $_parse_assignment->( $stripped->[ 1 ] );
   my $plain     = join $SPC, reverse
                   map    { length > 1 ? "--${_}${assign}" : "-${_}${assign}" }
                   split m{ [|] }mx, $stripped->[ 0 ];
   my $pad       = $SPC x ($length - length $plain);
   my $highlight = $USAGE_CONF->{highlight} // 'bold';

   $highlight eq 'none' and return $plain.$pad; # Old behaviour

   $assign = color( $highlight ).$assign.color( 'reset' );

   my $markedup  = join $SPC, reverse
                   map    { length > 1 ? "--${_}${assign}" : "-${_}${assign}" }
                   split m{ [|] }mx, $stripped->[ 0 ];

   return $markedup.$pad; # Prefered behaviour works well with short types
};

my $_option_length = sub {
   my $fullspec         = shift;
   my $number_opts      = 1;
   my $last_pos         = 0;
   my $number_shortopts = 0;
   my ($spec, $assign)
      = Getopt::Long::Descriptive->_strip_assignment( $fullspec );
   my $length           = length $spec;
   my $arglen           = length $_parse_assignment->( $assign );
   # Spacing rules:
   # For short options we want 1 space (for '-'), for long options 2
   # spaces (for '--').  Then one space for separating the options,
   # but we here abuse that $spec has a '|' char for that.

   # For options that take arguments, we want 2 spaces for mandatory
   # options ('=X') and 4 for optional arguments ('[=X]').  Note we
   # consider {N,M} cases as "single argument" atm.

   # Count the number of "variants" (e.g. "long|s" has two variants)
   while ($spec =~ m{ [|] }gmx) {
      $number_opts++;
      (pos( $spec ) - $last_pos) == 2 and $number_shortopts++;
      $last_pos = pos( $spec );
   }

   # Was the last option a "short" one?
   # Getopt::Long::Descriptive has a 2 here and thats wrong
   ($length - $last_pos) == 1 and $number_shortopts++;
   # We got $number_opts options, each with an argument length of
   # $arglen.  Plus each option (after the first) needs 3 a char
   # spacing.  $length gives us the total length of all options and 1
   # char spacing per option (after the first).  It does not account
   # for argument length and we want (at least) one additional char
   # for space before the description.  So the result should be:
   my $number_longopts = $number_opts - $number_shortopts;
   my $total_arglen    = $number_opts * $arglen;
   my $total_optsep    = 2 * $number_longopts + $number_shortopts;
   my $total           = $length + $total_optsep + $total_arglen;

   return $total;
};

# Public methods
sub option_text {
   my $self     = shift;
   my @options  = @{ $self->{options} // [] };
   my @specs    = map { $_->{spec} } grep { $_->{desc} ne 'spacer' } @options;
   my $length   = max( map { $_option_length->( $_ ) } @specs ) || 0;
   my $tab      = $SPC x $_tabstop->(); # Originally an actual tab char
   my $spec_fmt = "${tab}%-${length}s";
   my $string   = $NUL;

   while (defined (my $opt = shift @options)) {
      my $spec  = $opt->{spec}; my $desc = $opt->{desc};

      if ($desc eq 'spacer') { $string .= sprintf "${spec_fmt}\n", $spec; next }

      if (exists $opt->{constraint}->{default} and $self->{show_defaults}) {
         my $default = $opt->{constraint}->{default} // '[undef]';

         length $default or $default = '[null]';
         # Add the default to the description before splitting into lines
         $desc .= " (default value: ${default})";
      }

      my @desc  = $_split_description->( $length, $desc );

      $spec     = $_assemble_spec->( $length, $spec );
      $string  .= sprintf "${tab}${spec}  %s\n", shift @desc;

      for my $line (@desc) {
         $string .= $tab.($SPC x ( $length + 2 ))."${line}\n";
      }
   }

   return $string;
}

sub usage_conf {
   my ($self, $v) = @_; defined $v or return $USAGE_CONF;

   ref $v eq 'HASH' or die 'Usage configuration must be a hash reference';

   return $USAGE_CONF = $v;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::Getopt::Usage - The usage description for Getopt::Long::Descriptive

=head1 Synopsis

   use parent 'Getopt::Long::Descriptive';

   use Class::Usul::Getopt::Usage;
   use Getopt::Long 2.38;

   sub usage_class {
      return 'Class::Usul::Getopt::Usage';
   }

=head1 Description

The usage description for L<Getopt::Long::Descriptive>. Inherits from
L<Getopt::Long::Descriptive::Usage>

See L<Class::Usul::Options> for more usage information

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<option_text>

Returns the multiline string which is the usage text

=head2 C<usage_conf>

A class accessor / mutator for the configuration hash reference. Supported
attributes are;

=over 3

=item C<highlight>

Defaults to C<bold> which causes the option argument types to be displayed
in a bold font. Set to C<none> to turn off highlighting

=item C<option_type>

One of; C<none>, C<short>, or C<verbose>. Determines the amount of option
type information displayed by the L<option_text|Class::Usul::Usage/option_text>
method. Defaults to C<short>

=item C<tabstop>

Defaults to 3. The number of spaces to expand the leading tab in the usage
string

=item C<type_map>

A hash reference keyed by option type. By default maps C<int> to C<i>, C<key>
to C<k>, C<num> to C<n>, and C<str> to C<s>

=item C<width>

The total line width available for displaying usage text, defaults to 78

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Getopt::Long::Descriptive::Usage>

=item L<List::Util>

=item L<Term::ANSIColor>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Usul.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
