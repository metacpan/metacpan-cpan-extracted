package Bio::Cellucidate::Plot;

use base Bio::Cellucidate::Base;

sub route { '/plots'; }
sub element { 'plot'; }


# Bio::Cellucidate::Plot->series($plot_id);
sub series {
    my $self = shift;
    my $id = shift;
    $self->client->GET($self->route . "/$id" . Bio::Cellucidate::Series->route)->processResponseAsArray(Bio::Cellucidate::Series->element);
}

1;
