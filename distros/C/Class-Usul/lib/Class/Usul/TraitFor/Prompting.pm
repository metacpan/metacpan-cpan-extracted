package Class::Usul::TraitFor::Prompting;

use namespace::autoclean;

use Class::Usul::Constants qw( BRK FAILED FALSE NO NUL QUIT SPC TRUE YES );
use Class::Usul::Functions qw( arg_list emit_to is_hashref pad throw );
use English                qw( -no_match_vars );
use IO::Interactive;
use Term::ReadKey;
use Moo::Role;

requires qw( add_leader config loc output );

# Private functions
my $_default_input = sub {
   my ($fh, $args) = @_;

   ($ENV{PERL_MM_USE_DEFAULT} or $ENV{PERL_MB_USE_DEFAULT})
      and return $args->{default};
   $args->{onechar} and return getc $fh;
   return scalar <$fh>;
};

my $_get_control_chars = sub {
   # Returns a string of pipe separated control
   # characters and a hash of symbolic names and values
   my $handle = shift; my %cntl = GetControlChars $handle;

   return ((join '|', values %cntl), %cntl);
};

my $_justify_count = sub {
   return pad $_[ 1 ], int log $_[ 0 ] / log 10, SPC, 'left';
};

my $_map_prompt_args = sub { # IO::Prompt equiv. sub has an obscure bug so this
   my $args = shift; my %map = ( qw(-1 onechar -d default -e echo -p prompt) );

   for (grep { exists $map{ $_ } } keys %{ $args }) {
       $args->{ $map{ $_ } } = delete $args->{ $_ };
   }

   return $args;
};

my $_opts = sub {
   my ($type, @args) = @_; is_hashref $args[ 0 ] and return $args[ 0 ];

   my $attr = { default => $args[ 0 ], quit => $args[ 1 ], width => $args[ 2 ]};

   if    ($type eq 'get_line') {
      $attr->{multiline} = $args[ 3 ]; $attr->{noecho} = $args[ 4 ];
   }
   elsif ($type eq 'get_option') { $attr->{options} = $args[ 3 ] }
   elsif ($type eq 'yorn')       { $attr->{newline} = $args[ 3 ] }

   return $attr;
};

my $_raw_mode = sub { # Puts the terminal in raw input mode
   my $handle = shift; ReadMode 'raw', $handle; return;
};

my $_restore_mode = sub { # Restores line input mode to the terminal
   my $handle = shift; ReadMode 'restore', $handle; return;
};

my $_prompt = sub {
   # This was taken from L<IO::Prompt> which has an obscure bug in it
   my $args    = $_map_prompt_args->( arg_list @_ );
   my $default = $args->{default};
   my $echo    = $args->{echo   };
   my $onechar = $args->{onechar};
   my $OUT     = \*STDOUT;
   my $IN      = \*STDIN;
   my $input   = NUL;

   my ($len, $newlines, $next, $text);

   IO::Interactive::is_interactive() or return $_default_input->( $IN, $args );

   my ($cntl, %cntl) = $_get_control_chars->( $IN );
   local $SIG{INT}   = sub { $_restore_mode->( $IN ); exit FAILED };

   emit_to $OUT, $args->{prompt}; $_raw_mode->( $IN );

   while (TRUE) {
      if (defined ($next = getc $IN)) {
         if ($next eq $cntl{INTERRUPT}) {
            $_restore_mode->( $IN ); exit FAILED;
         }
         elsif ($next eq $cntl{ERASE}) {
            if ($len = length $input) {
               $input = substr $input, 0, $len - 1; emit_to $OUT, "\b \b";
            }

            next;
         }
         elsif ($next eq $cntl{EOF}) {
            $_restore_mode->( $IN );
            close $IN or throw 'IO error: [_1]', [ $OS_ERROR ];
            return $input;
         }
         elsif ($next !~ m{ $cntl }mx) {
            $input .= $next;

            if ($next eq "\n") {
               if ($input eq "\n" and defined $default) {
                  $text = defined $echo ? $echo x length $default : $default;
                  emit_to $OUT, "[${text}]\n"; $_restore_mode->( $IN );

                  return $onechar ? substr $default, 0, 1 : $default;
               }

               $newlines .= "\n";
            }
            else { emit_to $OUT, $echo // $next }
         }
         else { $input .= $next }
      }

      if ($onechar or not defined $next or $input =~ m{ \Q$RS\E \z }mx) {
         chomp $input; $_restore_mode->( $IN );
         defined $newlines and emit_to $OUT, $newlines;
         return $onechar ? substr $input, 0, 1 : $input;
      }
   }

   return;
};

# Private methods
my $_prepare = sub {
   my ($self, $question) = @_; my $add_leader;

   '+' eq substr $question, 0, 1 and $add_leader = TRUE
      and $question = substr $question, 1;
   $question = $self->loc( $question );
   $add_leader and $question = $self->add_leader( $question );
   return $question;
};

# Public methods
sub anykey {
   my ($self, $prompt) = @_;

   $prompt = $self->$_prepare( $prompt // 'Press any key to continue' );

   return $_prompt->( -p => "${prompt}...", -d => TRUE, -e => NUL, -1 => TRUE );
}

sub get_line { # General text input routine.
   my ($self, $question, @args) = @_; my $opts = $_opts->( 'get_line', @args );

   $question = $self->$_prepare( $question // 'Enter your answer' );

   my $default  = $opts->{default} // NUL;
   my $advice   = $opts->{quit} ? $self->loc( '([_1] to quit)', QUIT ) : NUL;
   my $r_prompt = $advice.($opts->{multiline} ? NUL : " [${default}]");
   my $l_prompt = $question;

   if (defined $opts->{width}) {
      my $total  = $opts->{width} || $self->config->pwidth;
      my $left_x = $total - (length $r_prompt);

      $l_prompt = sprintf '%-*s', $left_x, $question;
   }

   my $prompt  = "${l_prompt} ${r_prompt}"
               . ($opts->{multiline} ? "\n[${default}]" : NUL).BRK;
   my $result  = $opts->{noecho}
               ? $_prompt->( -d => $default, -p => $prompt, -e => '*' )
               : $_prompt->( -d => $default, -p => $prompt );

   $opts->{quit} and defined $result and lc $result eq QUIT and exit FAILED;

   return "${result}";
}

sub get_option { # Select from an numbered list of options
   my ($self, $prompt, @args) = @_; my $opts = $_opts->( 'get_option', @args );

   $prompt //= '+Select one option from the following list:';

   my $no_lead = ('+' eq substr $prompt, 0, 1) ? FALSE : TRUE;
   my $leader  = $no_lead ? NUL : '+'; $prompt =~ s{ \A \+ }{}mx;
   my $max     = @{ $opts->{options} // [] };

   $self->output( $prompt, { no_lead => $no_lead } ); my $count = 1;

   my $text = join "\n", map { $_justify_count->( $max, $count++ )." - ${_}" }
                            @{ $opts->{options} // [] };

   $self->output( $text, { cl => TRUE, nl => TRUE, no_lead => $no_lead } );

   my $question = "${leader}Select option";
   my $opt      = $self->get_line( $question, $opts );

   $opt !~ m{ \A \d+ \z }mx and $opt = $opts->{default} // 0;

   return $opt - 1;
}

sub is_interactive {
   my $self = shift; return IO::Interactive::is_interactive( @_ );
}

sub yorn { # General yes or no input routine
   my ($self, $question, @args) = @_; my $opts = $_opts->( 'yorn', @args );

   $question = $self->$_prepare( $question // 'Choose' );

   my $no = NO; my $yes = YES; my $result;

   my $default  = $opts->{default} ? $yes : $no;
   my $quit     = $opts->{quit   } ? QUIT : NUL;
   my $advice   = $quit ? "(${yes}/${no}, ${quit}) " : "(${yes}/${no}) ";
   my $r_prompt = "${advice}[${default}]";
   my $l_prompt = $question;

   if (defined $opts->{width}) {
      my $max_width = $opts->{width} || $self->config->pwidth;
      my $right_x   = length $r_prompt;
      my $left_x    = $max_width - $right_x;

      $l_prompt = sprintf '%-*s', $left_x, $question;
   }

   my $prompt = "${l_prompt} ${r_prompt}".BRK.($opts->{newline} ? "\n" : NUL);

   while ($result = $_prompt->( -d => $default, -p => $prompt )) {
      $quit and $result =~ m{ \A (?: $quit | [\e] ) }imx and exit FAILED;
      $result =~ m{ \A $yes }imx and return TRUE;
      $result =~ m{ \A $no  }imx and return FALSE;
   }

   return;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Class::Usul::TraitFor::Prompting - Methods for requesting command line input

=head1 Synopsis

   use Moo;

   with q(Class::Usul::TraitForPrompting);

=head1 Description

Methods that prompt for command line input from the user

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 anykey

   $key = $self->anykey( $prompt );

Prompt string defaults to 'Press any key to continue...'. Calls and
returns L<prompt|/__prompt>. Requires the user to press any key on the
keyboard (that generates a character response)

=head2 get_line

   $line = $self->get_line( $question, $default, $quit, $width, $newline );

Prompts the user to enter a single line response to C<$question> which
is printed to I<STDOUT> with a program leader. If C<$quit> is true
then the options to quit is included in the prompt. If the C<$width>
argument is defined then the string is formatted to the specified
width which is C<$width> or C<< $self->pwdith >> or 40. If C<$newline>
is true a newline character is appended to the prompt so that the user
get a full line of input

=head2 get_option

   $option = $self->get_option( $question, $default, $quit, $width, $options );

Returns the selected option number from the list of possible options passed
in the C<$question> argument

=head2 is_interactive

   $bool = $self->is_interactive( $optional_filehandle );

Exposes L<IO::Interactive/is_interactive>

=head2 yorn

   $self->yorn( $question, $default, $quit, $width );

Prompt the user to respond to a yes or no question. The C<$question>
is printed to I<STDOUT> with a program leader. The C<$default>
argument is C<0|1>. If C<$quit> is true then the option to quit is
included in the prompt. If the C<$width> argument is defined then the
string is formatted to the specified width which is C<$width> or
C<< $self->pwdith >> or 40

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<IO::Interactive>

=item L<Term::ReadKey>

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

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
