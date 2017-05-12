package Data::Transform::Meta;
use strict;

sub new {
   my ($type, $data) = @_;

   my $self = { };
   $self->{data} = $data if (defined $data);

   return bless $self, $type
}

sub data {
   my $self = shift;

   return $self->{data};
}

package # hide from PAUSE
        Data::Transform::Meta::SENDBACK;
use base qw(Data::Transform::Meta);

package # hide from PAUSE
        Data::Transform::Meta::EOF;
use base qw(Data::Transform::Meta);

package # hide from PAUSE
        Data::Transform::Meta::Error;
use base qw(Data::Transform::Meta);

1;
