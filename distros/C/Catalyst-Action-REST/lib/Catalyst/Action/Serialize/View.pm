package Catalyst::Action::Serialize::View;
$Catalyst::Action::Serialize::View::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ( $controller, $c, $view ) = @_;

    # Views don't care / are not going to render an entity for 3XX
    # responses.
    return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'} 
        ) || 'rest';

    if ( !$c->view($view) ) {
        $c->log->error("Could not load $view, refusing to serialize");
        return;
    }

    if ($c->view($view)->process($c, $stash_key)) {
      return 1;
    } else {
      # This is stupid. Please improve it.
      my $error = join("\n", @{ $c->error }) || "Error in $view";
      $error .= "\n";
      $c->clear_errors;
      die $error;
    }
}

__PACKAGE__->meta->make_immutable;

1;
