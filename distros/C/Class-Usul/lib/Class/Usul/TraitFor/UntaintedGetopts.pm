package Class::Usul::TraitFor::UntaintedGetopts;

use namespace::autoclean;

use Class::Usul::Constants qw( FAILED NUL QUOTED_RE TRUE );
use Class::Usul::Functions qw( emit_err untaint_cmdline );
use Class::Usul::Getopt    qw( describe_options );
use Data::Record;
use Encode                 qw( decode );
use JSON::MaybeXS          qw( decode_json );
use Scalar::Util           qw( blessed );
use Moo::Role;

my $Extra_Argv = []; my $Untainted_Argv = [];

my $Usage = "Did we forget new_with_options?\n";

# Private functions
my $_extra_argv = sub {
   return $_[ 0 ]->{_extra_argv} //= [ @{ $Extra_Argv } ];
};

my $_extract_params = sub {
   my ($args, $config, $options_data, $cmdline_opt) = @_;

   my $params = { %{ $args } }; my @missing_required;

   my $prefer = $config->{prefer_commandline};

   for my $name (keys %{ $options_data }) {
      my $option = $options_data->{ $name };

      if ($prefer or not defined $params->{ $name }) {
         my $val; defined ($val = $cmdline_opt->$name()) and
            $params->{ $name } = $option->{json} ? decode_json( $val ) : $val;
      }

      $option->{required} and not defined $params->{ $name }
         and push @missing_required, $name;
   }

   return ($params, @missing_required);
};

my $_option_specification = sub {
   my ($name, $opt) = @_;

   my $dash_name   = $name; $dash_name =~ tr/_/-/; # Dash name support
   my $option_spec = $dash_name;

   defined $opt->{short } and $option_spec .= '|'.$opt->{short};
   $opt->{repeatable} and not defined $opt->{format} and $option_spec .= '+';
   $opt->{negateable} and $option_spec .= '!';
   defined $opt->{format} and $option_spec .= '='.$opt->{format};
   return $option_spec;
};

my $_set_usage_conf = sub { # Should be in describe_options third argument
   return Class::Usul::Getopt::Usage->usage_conf( $_[ 0 ] );
};

my $_split_args = sub {
   my $splitters = shift; my @new_argv;

   for (my $i = 0, my $nargvs = @ARGV; $i < $nargvs; $i++) { # Parse all argv
      my $arg = $ARGV[ $i ];

      my ($name, $value) = split m{ [=] }mx, $arg, 2; $name =~ s{ \A --? }{}mx;

      if (my $splitter = $splitters->{ $name }) {
         $value //= $ARGV[ ++$i ];

         for my $subval (map { s{ \A [\'\"] | [\'\"] \z }{}gmx; $_ }
                         $splitter->records( $value )) {
            push @new_argv, "--${name}", $subval;
         }
      }
      else { push @new_argv, $arg }
   }

   return @new_argv;
};

my $_sort_options = sub {
   my ($opts, $a, $b) = @_; my $max = 999;

   my $oa = $opts->{ $a }{order} || $max; my $ob = $opts->{ $b }{order} || $max;

   return ($oa == $max) && ($ob == $max) ? $a cmp $b : $oa <=> $ob;
};

my $_untainted_argv = sub {
   return $_[ 0 ]->{_untainted_argv} //= [ @{ $Untainted_Argv } ];
};

my $_build_options = sub {
   my $options_data = shift; my $splitters = {}; my @options = ();

   for my $name (sort  { $_sort_options->( $options_data, $a, $b ) }
                 keys %{ $options_data }) {
      my $option = $options_data->{ $name };
      my $cfg    = $option->{config} // {};
      my $doc    = $option->{doc   } // "No help for ${name}";

      push @options, [ $_option_specification->( $name, $option ), $doc, $cfg ];
      defined $option->{autosplit} or next;
      $splitters->{ $name } = Data::Record->new( {
         split => $option->{autosplit}, unless => QUOTED_RE } );
      $option->{short}
         and $splitters->{ $option->{short} } = $splitters->{ $name };
   }

   return ($splitters, @options);
};

# Private methods
my $_parse_options = sub {
   my ($self, %args) = @_; my $opt;

   my $class  = blessed $self || $self;
   my %data   = $class->_options_data;
   my %config = $class->_options_config;
   my $enc    = $config{encoding} // 'UTF-8';

   my @skip_options; defined $config{skip_options}
      and @skip_options = @{ $config{skip_options} };

   @skip_options and delete @data{ @skip_options };

   my ($splitters, @options) = $_build_options->( \%data );

   my %gld_conf; my @gld_attr = ('getopt_conf', 'show_defaults');

   my $usage_opt = $config{usage_opt} ? $config{usage_opt} : 'Usage: %c %o';

   @gld_conf{ @gld_attr } = @config{ @gld_attr };
   $config{usage_conf   } and $_set_usage_conf->( $config{usage_conf} );
   $config{protect_argv } and local @ARGV = @ARGV;
   $enc and @ARGV = map { decode( $enc, $_ ) } @ARGV;
   $config{no_untaint   } or  @ARGV = map { untaint_cmdline $_ } @ARGV;
   $Untainted_Argv = [ @ARGV ];
   keys  %{ $splitters  } and @ARGV = $_split_args->( $splitters );
   ($opt, $Usage)  = describe_options( $usage_opt, @options, \%gld_conf );
   $Extra_Argv     = [ @ARGV ];

   my ($params, @missing)
      = $_extract_params->( \%args, \%config, \%data, $opt );

   if ($config{missing_fatal} and @missing) {
      emit_err join( "\n", map { "Option '${_}' is missing" } @missing );
      emit_err $Usage;
      exit FAILED;
   }

   return %{ $params };
};

# Construction
sub new_with_options {
   my $self = shift; return $self->new( $self->$_parse_options( @_ ) );
}

# Public methods
sub extra_argv {
   return defined $_[ 1 ] ? $_extra_argv->( $_[ 0 ] )->[ $_[ 1 ] ]
                          : $_extra_argv->( $_[ 0 ] );
}

sub next_argv {
   return shift @{ $_extra_argv->( $_[ 0 ] ) };
}

sub options_usage {
   return ucfirst $Usage;
}

sub unshift_argv {
   return unshift @{ $_extra_argv->( $_[ 0 ] ) }, $_[ 1 ];
}

sub untainted_argv {
   return defined $_[ 1 ] ? $_untainted_argv->( $_[ 0 ] )->[ $_[ 1 ] ]
                          : $_untainted_argv->( $_[ 0 ] );
}

1;

__END__

=pod

=head1 Name

Class::Usul::TraitFor::UntaintedGetopts - Untaints @ARGV before Getopts processes it

=head1 Synopsis

   use Moo;

   with 'Class::Usul::TraitFor::UntaintedGetopts';

=head1 Description

Untaints C<@ARGV> before Getopts processes it. Replaces L<MooX::Options>
with an implementation closer to L<MooseX::Getopt::Dashes>

=head1 Configuration and Environment

Modifies C<new_with_options> and C<options_usage>

=head1 Subroutines/Methods

=head2 extra_argv

Returns an array ref containing the remaining command line arguments

=head2 new_with_options

Parses the command line options and then calls the constructor

=head2 next_argv

Returns the next value from L</extra_argv> shifting the value off the list

=head2 options_usage

Returns the options usage string

=head2 _parse_options

Untaints the values of the C<@ARGV> array before the are parsed by
L<Getopt::Long::Descriptive>

=head2 unshift_argv

Pushes the supplied argument back onto the C<extra_argv> list

=head2 untainted_argv

Returns all of the arguments passed, untainted, before L<Getopt::Long> parses
them

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Data::Record>

=item L<Encode>

=item L<Getopt::Long>

=item L<Getopt::Long::Descriptive>

=item L<JSON::MaybeXS>

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
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
