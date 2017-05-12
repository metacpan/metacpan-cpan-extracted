package Bio::Cellucidate::Book;

use base Bio::Cellucidate::Base;

sub route   { '/books'; }
sub element { 'book';   }


# Bio::Cellucidate::Book->models($book_id);
sub models {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::Model->route, $format)->processResponseAsArray(Bio::Cellucidate::Model->element);
} 

# Bio::Cellucidate::Book->agents($book_id);
sub agents {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::Agent->route, $format)->processResponseAsArray(Bio::Cellucidate::Agent->element);
}

# Bio::Celllucidate::Book->rules($book_id);
sub rules {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::Rule->route, $format)->processResponseAsArray(Bio::Cellucidate::Rule->element);
}

1;
