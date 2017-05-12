package Acme::Octarine;

use 5.005;
use strict;

use Acme::Colour;

use vars qw($VERSION @Acmes);
$VERSION = '0.02';

# I need some hooks in Acme::Colour's constructor. But as we all know cut and
# paste is bad. So we are good and don't do that:

use B::Deparse;
use PadWalker 'closed_over';

# Frustratingly, he uses a package lexical %r, which foils a simple re-eval of
# the deparsed method code.
my $deparse = B::Deparse->new("-sC");
my $body = $deparse->coderef2text(\&Acme::Colour::new);
my $r = closed_over(\&Acme::Colour::new)->{'%r'};

# Add a my $sub; declaration at the top level
$body =~ s/([ \t]+)(bless)/$1my \$sub;\n$1$2/ or die $body;
# If colour is defined, look it up in the specials hash
$body =~ s/
  ([ \t]+) # Must get the indent correct
  (unless[ \t]*\(exists[ \t]*\$r)({\$colour})\)
  /$1\$sub = \$Acme::Colour::specials{\$colour};
$1$2->$3 or defined \$sub)/sx or die $body;

# If a specials subroutine was found, call it instead of making a simple return
$body =~ s/
  ([ \t]+) # Most get the indent correct
  (return\s*(\$\w+))\s*;?\s* # Probably the last line of the subroutine.
}/
$1$2 unless \$sub; # default behaviour unless we are a special colour
$1&\$sub($3);
}/sx or die $body;

{
  # Turn off warnings.
  local $^W;
  eval "sub Acme::Colour::new $body";
  die if $@;
}

require CPANPLUS::Backend;
# Currently CPANPLUS only supports one backend per program.

my $cp = CPANPLUS::Backend->new;
$cp->configure_object()->set_conf(verbose=>0);
@Acmes = map {$_->name} $cp->search(type => 'module',
				    allow => [qr/^Acme::/]);

sub random_acme_module {
  $Acmes[rand @Acmes];
}


$Acme::Colour::specials{octarine} = $Acme::Colour::specials{Octarine} =
sub {
  my $object = shift;
  $object->{colour} = 'black';
  my $rv = $cp->install( modules => [ &random_acme_module ]);
  # Ooops. Don't worry if it's OK
  return $object;
};

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Octarine - Provides Octarine support for Acme::Colour

=head1 SYNOPSIS

  use Acme::Octarine;
  $c = Acme::Colour->new("octarine"); # warning - may leak magic

=head1 ABSTRACT

Acme::Octarine - Provides Octarine support for Acme::Colour

There may be some unavoidable leakage of magic whenever an octarine
Acme::Colour object is created.

=head1 DESCRIPTION

The behaviour of "unavoidable leakage of magic" may change without notice
from version to version.

=head1 SEE ALSO

Acme::Orange

The Discworld series of novels by Terry Pratchett.
(IIRC Discworld is a registered trademark of Terry Pratchett)

=head1 AUTHOR

Nicholas Clark, E<lt>nick@talking.bollo.cxE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
