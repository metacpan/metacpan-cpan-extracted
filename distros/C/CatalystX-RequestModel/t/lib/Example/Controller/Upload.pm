package Example::Controller::Upload;

use Moose;
use MooseX::MethodAttributes;
use Data::Dumper;

extends 'Catalyst::Controller';

sub upload :POST Chained(/) Args(0) Does(RequestModel) RequestModel(UploadRequest)  {
  my ($self, $c, $request) = @_;
  $c->res->body(Dumper +{
    notes => $request->notes,
    file => $request->file->slurp,
  });
}

__PACKAGE__->meta->make_immutable;

