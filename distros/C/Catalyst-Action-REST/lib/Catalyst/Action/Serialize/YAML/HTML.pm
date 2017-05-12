package Catalyst::Action::Serialize::YAML::HTML;
$Catalyst::Action::Serialize::YAML::HTML::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use YAML::Syck;
use URI::Find;

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'} 
        ) || 'rest';
    my $app = $c->config->{'name'} || '';
    my $output = "<html>";
    $output .= "<title>" . $app . "</title>";
    $output .= "<body><pre>";
    my $text = HTML::Entities::encode(Dump($c->stash->{$stash_key}));
    # Straight from URI::Find
    my $finder = URI::Find->new(
                              sub {
                                  my($uri, $orig_uri) = @_;
                                  my $newuri;
                                  if ($uri =~ /\?/) {
                                      $newuri = $uri . "&content-type=text/html";
                                  } else {
                                      $newuri = $uri . "?content-type=text/html";
                                  }
                                  return qq|<a href="$newuri">$orig_uri</a>|;
                              });
    $finder->find(\$text);
    $output .= $text;
    $output .= "</pre>";
    $output .= "</body>";
    $output .= "</html>";
    $c->response->output( $output );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
