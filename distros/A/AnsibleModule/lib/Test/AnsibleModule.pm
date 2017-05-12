package Test::AnsibleModule;

use Mojo::Base -base;
use Test::More;
use Mojo::JSON qw/decode_json encode_json/;
use Mojo::Asset::File;
use Carp qw/croak/;
use Data::Dumper qw/Dumper/;
$Data::Dumper::Sortkeys++;

has 'last_response';
has 'success';

sub fail_ok {
  my $self = shift;
  my $rc   = $self->exec_module(@_);
  $self->_test('ok', $rc, 'Returned non-zero return code');
}

sub is_response {
  my $self = shift;
  my $res  = shift;
  $self->_test('is', Dumper($self->last_response), Dumper($res), @_);
}

sub run_ok {
  my $self = shift;
  my $rc   = $self->exec_module(@_);
  $self->_test('ok', !$rc,
    'Response code is success (' . $self->last_response->{msg} . ')');
}

sub exec_module {
  my $self   = shift;
  my $module = shift;
  my $args   = ref $_[0] ? $_[0] : {@_};

  my $file = Mojo::Asset::File->new;
  $file->add_chunk(encode_json($args));
  my $p;

  open($p, "-|", join(" ", $module, $file->path))
    // croak "Could not run module: $!";
  my $response = "";

  while (my $line = <$p>) {
    $response .= $line;
  }
  my $res = decode_json($response);
  $self->last_response($res);
  close $p;
  return $? >> 8;
}

sub _test {
  my ($self, $name, @args) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return $self->success(!!Test::More->can($name)->(@args));
}


1;

=head1 NAME

Test::AnsibleModule - Test your ansible modules.

=head1 SYNOPSIS

use Test::AnsibleModule;
my $t=Test::AnsibleModule->new();
$t->run_ok('modules/foobar');
is_deeploy($t->last_response,{ changed => 0 });

=head1 DESCRIPTION

Test an Ansible module by running it and passing it input as JSON, and decoding the response.

=head1 ATTRIBUTES

=head2 last_response

The deserialized response from the last module run.

=head1 METHODS

=head2 run_ok <module> [<args>]

Test that the job runs, and returns a 0 error code (succeeds).

=head2 fail_ok <module> [<args>]

Test that the jobs runs, and returns a non-zero error code (fails).

=head2 is_response <hash res>, [<args>]

Compare the last response to the provided struct.

=head2 exec_module <module> [<args>]

Run a module, return it's exit code

=head1 SEE ALSO

L<AnsibleModule>


=cut
