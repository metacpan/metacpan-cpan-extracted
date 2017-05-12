package AccessorGroups;
use strict;
use warnings;
use base 'AccessorGroupsParent';

__PACKAGE__->mk_group_accessors('simple', [ fieldname_torture => join ('', reverse map { chr($_) } (0..255) ) ]);

sub get_simple {
  my $v = shift->SUPER::get_simple (@_);
  $v =~ s/ Extra tackled on$// if $v;
  $v;
}

sub set_simple {
  my ($self, $f, $v) = @_;
  $v .= ' Extra tackled on' if $f eq 'singlefield';
  $self->SUPER::set_simple ($f, $v);
  $_[2];
}

# a runtime Class::Method::Modifiers style around
# the eval/our combo is so that we do not need to rely on Sub::Name being available
my $orig_ra_cref = __PACKAGE__->can('runtime_around');
our $around_cref = sub {
  my $self = shift;
  if (@_) {
    my $val = shift;
    $self->$orig_ra_cref($val . ' Extra tackled on');
    $val;
  }
  else {
    my $val = $self->$orig_ra_cref;
    $val =~ s/ Extra tackled on$// if defined $val;
    $val;
  }
};
{
  no warnings qw/redefine/;
  eval <<'EOE';
    sub runtime_around { goto $around_cref };
    sub _runtime_around_accessor { goto $around_cref };
EOE
}

1;
