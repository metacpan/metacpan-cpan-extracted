package App::AutoCRUD::View::Json;

use 5.010;
use Moose;
extends 'App::AutoCRUD::View';

use JSON::MaybeXS;
use namespace::clean -except => 'meta';

has 'json_args' => ( is => 'bare', isa => 'HashRef',
                     default => sub {{ pretty          => 1,
                                       allow_blessed   => 1,
                                       convert_blessed => 1 }} );


sub render {
  my ($self, $data, $context) = @_;

  # encode output
  my $json_maker = JSON::MaybeXS->new(%{$self->{json_args}});
  my $output     = $json_maker->encode($data);

  return [200, ['Content-type' => 'application/json; charset=UTF-8'],
               [$output] ];
}

1;


__END__



