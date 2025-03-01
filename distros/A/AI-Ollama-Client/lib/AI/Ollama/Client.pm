package AI::Ollama::Client 0.04;
use 5.020;
use Moo 2;
use experimental 'signatures';
use MIME::Base64 'encode_base64';

extends 'AI::Ollama::Client::Impl';

=head1 NAME

AI::Ollama::Client - Client for AI::Ollama

=head1 SYNOPSIS

  use 5.020;
  use AI::Ollama::Client;

  my $client = AI::Ollama::Client->new(
      server => 'https://example.com/',
  );
  my $res = $client->someMethod()->get;
  say $res;

=head1 METHODS

=head2 C<< checkBlob >>

  my $res = $client->checkBlob()->get;

Check to see if a blob exists on the Ollama server which is useful when creating models.

=cut

around 'checkBlob' => sub ( $super, $self, %options ) {
    $super->( $self, %options )->then( sub( $res ) {
        if( $res->code =~ /^2\d\d$/ ) {
            return Future->done( 1 )
        } else {
            return Future->done( 0 )
        }
    });
};

=head2 C<< createBlob >>

  my $res = $client->createBlob()->get;

Create a blob from a file. Returns the server file path.

=cut

=head2 C<< generateChatCompletion >>

  my $res = $client->generateChatCompletion()->get;

Generate the next message in a chat with a provided model.

Returns a L<< AI::Ollama::GenerateChatCompletionResponse >>.

=cut

=head2 C<< copyModel >>

  my $res = $client->copyModel()->get;

Creates a model with another name from an existing model.


=cut

=head2 C<< createModel >>

  my $res = $client->createModel()->get;

Create a model from a Modelfile.

Returns a L<< AI::Ollama::CreateModelResponse >>.

=cut

=head2 C<< deleteModel >>

  my $res = $client->deleteModel()->get;

Delete a model and its data.


=cut

=head2 C<< generateEmbedding >>

  my $res = $client->generateEmbedding()->get;

Generate embeddings from a model.

Returns a L<< AI::Ollama::GenerateEmbeddingResponse >>.

=cut

=head2 C<< generateCompletion >>

  use Future::Utils 'repeat';
  my $responses = $client->generateCompletion();
  repeat {
      my ($res) = $responses->shift;
      if( $res ) {
          my $str = $res->get;
          say $str;
      }

      Future::Mojo->done( defined $res );
  } until => sub($done) { $done->get };

Generate a response for a given prompt with a provided model.

Returns a L<< AI::Ollama::GenerateCompletionResponse >>.

=cut

around 'generateCompletion' => sub ( $super, $self, %options ) {
    # Encode images as base64, if images exist:
    # (but create a copy so we don't over write the input array)
    if (my $images = $options{images}) {

        # Allow { filename => '/etc/passwd' }
        $options{images} = [
            map {
                my $item = $_;
                if( ref($item) eq 'HASH' ) {
                    $item = Mojo::File->new($item->{filename})->slurp();
                };
                encode_base64($item)
            } @$images ];
    }
    return $super->($self, %options);
};

=head2 C<< pullModel >>

  my $res = $client->pullModel(
      name => 'llama',
  )->get;

Download a model from the ollama library.

Returns a L<< AI::Ollama::PullModelResponse >>.

=cut

=head2 C<< pushModel >>

  my $res = $client->pushModel()->get;

Upload a model to a model library.

Returns a L<< AI::Ollama::PushModelResponse >>.

=cut

=head2 C<< showModelInfo >>

  my $info = $client->showModelInfo()->get;
  say $info->modelfile;

Show details about a model including modelfile, template, parameters, license, and system prompt.

Returns a L<< AI::Ollama::ModelInfo >>.

=cut

=head2 C<< listModels >>

  my $info = $client->listModels()->get;
  for my $model ($info->models->@*) {
      say $model->model; # llama2:latest
  }

List models that are available locally.

Returns a L<< AI::Ollama::ModelsResponse >>.

=cut

1;
