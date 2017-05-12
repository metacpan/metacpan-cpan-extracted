package t::SimpleUsage;
use strict;
use warnings;

use Class::Enum qw(
    Left
    Right
);

1;
__END__

=pod

'use Class::Enum qw(Left Right)' install some method.

  package t::SimpleUsage;
  use strict;
  use warnings;
  
  use overload (
      '<=>' => sub { $_[0]->{ordinal} <=> $_[1]->{ordinal} }
      'cmp' => sub { $_[0]->{name} cmp $_[1]->{name} },
      '""'  => sub { $_[0]->{name} },
      '+0'  => sub { $_[0]->{ordinal} },
  );
  use Exporter qw(import);
  our @EXPORT_OK = qw(Left Right);
  our %EXPORT_TAGS = (all => \@EXPORT_OK);
  
  sub name { shift->{name} }
  sub ordinal { shift->{ordinal} }
  
  my $Left = bless { name => 'Left', ordinal => 0 }, t::SimpleUsage;
  sub Left { $Left }
  sub is_left { shift == $Left }
  
  my $Right = bless { name => 'Right', ordinal => 1 }, t::SimpleUsage;
  sub Right { $Right }
  sub is_right { shift == $Right }

  my %value_of = (
      Left => $Left,
      Right => $Right,
  );
  sub value_of {
      my ($class, $name) = @_;
      return $value_of{$name};
  }
  sub values { sort { $a <=> $b } values(%value_of) }
  sub names { map { $_->name } values }

  1;

=cut
