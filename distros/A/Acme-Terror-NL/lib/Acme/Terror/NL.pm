package Acme::Terror::NL;
use strict;
use LWP::Simple;

use vars qw($VERSION);
$VERSION = '0.04';

use constant {
   UNKNOWN        => 0,
   CRITICAL       => 1,
   SUBSTANTIAL    => 2,
   LIMITED        => 3,
   MINIMAL        => 4,
};

sub new {
   my ($class, %args) = @_;
   my $self = {};
   bless $self, $class;
   $self->{_level}     =  UNKNOWN;
   $self->{_level_txt} = "UNKNOWN";
   return $self;
}

sub fetch {
   my $self = shift;
   my $uri  = 'http://english.nctb.nl/';
   my $html = get($uri);
   if($html =~ m!href=".+?current_threat_level.+?"[^>]+>\s*(MINIMAL|LIMITED|SUBSTANTIAL|CRITICAL)</a>!is){
      my $lvl = $1;
      if($constant::declared{__PACKAGE__."::".$lvl}) {
         $self->{_level} = eval $lvl;
         $self->{_level_txt} =  $lvl;
      }
   }
   return $self->{_level_txt};
}

sub text {
   my $self = shift;
   $self->fetch unless($self->{_level});
   return $self->{_level_text};
}

sub level {
   my $self = shift;
   $self->fetch unless($self->{_level});
   return $self->{_level};
}

#-------------------------------------------------------------------#

=head1 NAME

Acme::Terror::NL - Fetch the current NL terror alert level

=head1 SYNOPSIS

  use Acme::Terror::NL;

  my $t = Acme::Terror::NL->new();  # create new Acme::Terror::NL object

  my $level = $t->fetch;
  print "Current terror alert level is: $level\n";

=head1 DESCRIPTION

Gets the currrent terrorist threat level in the Netherlands.

The levels are either...

 CRITICAL    - there are strong indications that an attack will occur 
 SUBSTANTIAL - there is a realistic possibility that an attack will occur
 LIMITED     - it appears that attacks can be prevented.
 MINIMAL     - it is unlikely that attacks are being planned.
 UNKNOWN     - cannot determine threat level

There are "only" four levels present in the Netherlands, unlike, e.g. the
United Kingdom and the United States of America, where there are five.
Thats what you get for being a small country.

This module aims to be compatible with the US version, L<Acme::Terror>,
the UK version, L<Acme::Terror::UK> and the AU version, L<Acme::Terror::AU>.

=head1 METHODS

=head2 new()

  use Acme::Terror::NL;
  my $t = Acme::Terror::NL->new(); 

Create a new instance of the Acme:Terror::NL class.

=head2 fetch()

  my $threat_level_string = $t->fetch();
  print $threat_level_string;

Return the current threat level as a string.

=head2 text()

See C<fetch()>, it returns the same.

=head2 level()

  my $level = $t->level();
  if ($level == Acme::Terror::NL::CRITICAL) {
    print "too many L<Acme::Code::FreedomFighter>s!";
  }

Return the level of the current terrorist threat as a comparable value.

The values to compare against are,

  Acme::Terror::NL::CRITICAL
  Acme::Terror::NL::SUBSTANTIAL
  Acme::Terror::NL::LIMITED
  Acme::Terror::NL::MINIMAL

If it can't retrieve the current level, it will return

  Acme::Terror::NL::UNKNOWN

=head1 BUGS

Blame the terrorists! ... or report it to L<http://rt.cpan.org/Public/Dist/Display.html?Name=Acme::Terror::NL>.

=head1 AUTHOR

M. Blom,
E<lt>blom@cpan.orgE<gt>
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

=over 4

=item * L<Acme::Terror>, L<Acme::Terror::UK>, L<Acme::Terror::AU>

=item * L<http://english.nctb.nl/>

=back

=cut

1;
