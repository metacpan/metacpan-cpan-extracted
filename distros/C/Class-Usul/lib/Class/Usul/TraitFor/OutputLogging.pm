package Class::Usul::TraitFor::OutputLogging;

use namespace::autoclean;

use Class::Usul::Constants qw( BRK FAILED FALSE NUL TRUE WIDTH );
use Class::Usul::Functions qw( abs_path emit emit_err throw );
use Class::Usul::Types     qw( Bool SimpleStr );
use Text::Autoformat       qw( autoformat );
use Moo::Role;
use Class::Usul::Options;

requires qw( config log );

# Public attributes
option 'locale'   => is => 'lazy', isa => SimpleStr, format => 's',
   documentation  => 'Loads the specified language message catalogue',
   builder        => sub { $_[ 0 ]->config->locale }, short => 'L';

option 'quiet'    => is => 'ro',   isa => Bool, default => FALSE,
   documentation  => 'Quiet the display of information messages',
   reader         => 'quiet_flag', short => 'q';

# Private attributes
has '_quiet_flag' => is => 'rw', isa => Bool,
   builder        => sub { $_[ 0 ]->quiet_flag },
   lazy           => TRUE, writer => '_set__quiet_flag';

# Private methods
my $_loc = sub {
   my ($self, $text, $opts, $quote) = @_; $opts //= {};

   return $self->localize( $text // '[no message]', {
      locale               => $self->locale,
      no_quote_bind_values => $quote // $opts->{no_quote_bind_values} // FALSE,
      params               => $opts->{args} // [] } );
};

# Public methods
sub add_leader {
   my ($self, $text, $opts) = @_; $text or return NUL; $opts //= {};

   my $leader = $opts->{no_lead} ? NUL : (ucfirst $self->config->name).BRK;

   if ($opts->{fill}) {
      my $width = $opts->{width} // WIDTH;

      $text = autoformat $text, { right => $width - 1 - length $leader };
   }

   return join "\n", map { (m{ \A $leader }mx ? NUL : $leader).$_ }
                     split  m{ \n }mx, $text;
}

sub error {
   my ($self, $text, $opts) = @_; $text = $self->$_loc( $text, $opts );

   $self->log->error( $_ ) for (split m{ \n }mx, "${text}");

   emit_err $self->add_leader( $text, $opts );

   return TRUE;
}

sub fatal {
   my ($self, $text, $opts) = @_; my (undef, $file, $line) = caller 0;

   my $posn = ' at '.abs_path( $file )." line ${line}";

   $text = $self->$_loc( $text, $opts ).$posn;

   $self->log->alert( $_ ) for (split m{ \n }mx, $text);

   emit_err $self->add_leader( $text, $opts );

   exit FAILED;
}

sub info {
   my ($self, $text, $opts) = @_;

   $opts //= {}; $text = $self->$_loc( $text, $opts, TRUE );

   $self->log->info( $_ ) for (split m{ [\n] }mx, $text);

   $self->quiet or $opts->{quiet} or emit $self->add_leader( $text, $opts );

   return TRUE;
}

sub loc {
   my $self = shift; return $self->l10n->localizer( $self->locale, @_ );
}

sub output {
   my ($self, $text, $opts) = @_;

   $opts //= {}; $text = $self->$_loc( $text, $opts, TRUE );

   my $code = sub {
      $opts->{to} && $opts->{to} eq 'err' ? emit_err( @_ ) : emit( @_ );
   };

   $code->() if $opts->{cl};
   $code->( $self->add_leader( $text, $opts ) );
   $code->() if $opts->{nl};
   return TRUE;
}

sub quiet {
   my ($self, $v) = @_; defined $v or return $self->_quiet_flag; $v = !!$v;

   $v != TRUE and throw 'Cannot turn quiet mode off';

   return $self->_set__quiet_flag( $v );
}

sub warning {
   my ($self, $text, $opts) = @_;

   $opts //= {}; $text = $self->$_loc( $text, $opts );

   $self->log->warn( $_ ) for (split m{ \n }mx, $text);

   $self->quiet or $opts->{quiet} or emit $self->add_leader( $text, $opts );

   return TRUE;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::TraitFor::OutputLogging - Localised logging and command line output methods

=head1 Synopsis

   use Moo;

   extends 'Class::Usul';
   with    'Class::Usul::TraitFor::OutputLogging';

=head1 Description

Localised logging and command line output methods

=head1 Configuration and Environment

Requires the following;

=over 3

=item C<config>

=item C<log>

=back

Defines the following command line options;

=over 3

=item C<L locale>

Print text and error messages in the selected language. If no language
catalogue is supplied prints text and errors in terse English. Defaults
to C<en>

=item C<q quiet_flag>

Quietens the usual started/finished information messages

=back

=head1 Subroutines/Methods

=head2 add_leader

   $leader = $self->add_leader( $text, $opts );

Prepend C<< $self->config->name >> to each line of C<$text>. If
C<< $opts->{no_lead} >> exists then do nothing. Return C<$text> with
leader prepended

=head2 error

   $self->error( $text, $opts );

Calls L<Class::Usul::localize|Class::Usul/localize> with
the passed options. Logs the result at the error level, then adds the
program leader and prints the result to I<STDERR>

=head2 fatal

   $self->fatal( $text, $opts );

Calls L<Class::Usul::localize|Class::Usul/localize> with
the passed options. Logs the result at the alert level, then adds the
program leader and prints the result to I<STDERR>. Exits with a return
code of one

=head2 info

   $self->info( $text, $opts );

Calls L<Class::Usul::localize|Class::Usul/localize> with
the passed options. Logs the result at the info level, then adds the
program leader and prints the result to I<STDOUT>

=head2 loc

   $localized_text = $self->loc( $message, @options );

Localises the message. Calls L<localizer|Class::Usul::L10N/localizer>. The
domains to search are in the C<l10n_domains> configuration attribute. Adds
C<< $self->locale >> to the arguments passed to C<localizer>

=head2 output

   $self->output( $text, $opts );

Calls L<Class::Usul::localize|Class::Usul/localize> with
the passed options. Adds the program leader and prints the result to
I<STDOUT>

=head2 quiet

   $bool = $self->quiet( $bool );

Custom accessor/mutator for the C<quiet_flag> attribute. Will throw if you try
to turn quiet mode off

=head2 warning

   $self->warning( $text, $opts );

Calls L<Class::Usul::localize|Class::Usul/localize> with
the passed options. Logs the result at the warning level, then adds the
program leader and prints the result to I<STDOUT>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Options>

=item L<Text::Autoformat>

=item L<Moo::Role>

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
# vim: expandtab shiftwidth=3:
