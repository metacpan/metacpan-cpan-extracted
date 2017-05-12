package Search::Elasticsearch::Plugin::Langdetect;
use Moo;
with 'Search::Elasticsearch::Plugin::Langdetect::API';
with 'Search::Elasticsearch::Role::Client::Direct';
__PACKAGE__->_install_api('langdetect');

use Search::Elasticsearch 2.00 ();

use vars '$VERSION';
$VERSION = '0.06';

=head1 SYNOPSIS

        use Search::Elasticsearch;
        use Search::Elasticsearch::Plugin::Langdetect;
        
        use Search::Elasticsearch();
        my $es = Search::Elasticsearch->new(
            nodes   => \@nodes,
            plugins => ['Langdetect']
        );
        
        my $e = Search::Elasticsearch->new(...);
        my $ld = $e->langdetect;

        my $lang = $ld->detect_language( "Hello World" );
        # en

=cut

sub _init_plugin {
    my ( $class, $params ) = @_;

    Moo::Role->apply_roles_to_object( $params->{client},
        qw(Search::Elasticsearch::Plugin::Langdetect::Namespace) );
}

package Search::Elasticsearch::Plugin::Langdetect::Namespace;
use Moo::Role;

has 'langdetect' => ( is => 'lazy', init_arg => undef );

sub _build_langdetect {
    shift->_build_namespace('+Search::Elasticsearch::Plugin::Langdetect');
}

1;

__END__

=head1 METHODS

=head2 C<< ->detect_languages $content >>

    my $languages = $ld->detect_languages( $content );

Returns an arrayref of all detected languages together with
their propabilities.

=head2 C<< ->detect_language $content >>

    my $language = $ld->detect_language( $content );

Returns the ISO-two-letter code for the detected language.
This method is mostly a shorthand for retrieving the most likely
language from C<< ->detect_languages >>.

-=cut

