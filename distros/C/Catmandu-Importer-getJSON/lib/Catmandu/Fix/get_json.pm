package Catmandu::Fix::get_json;

our $VERSION = '0.51';

use Catmandu::Sane;
use Catmandu::Util;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Importer::getJSON;

with "Catmandu::Fix::Base";

has url => ( fix_arg => 1, default => sub { "url" } );

has dry     => ( fix_opt => 1 );
has cache   => ( fix_opt => 1 );
has timeout => ( fix_opt => 1, default => sub { 10 } );
has agent   => ( fix_opt => 1 );
has proxy   => ( fix_opt => 1 );
has wait    => ( fix_opt => 1 );

has vars => ( fix_opt => 1 );
has path => ( fix_opt => 1 );

has importer => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_importer {
    my ($self) = @_;

    my %options = (
        dry     => $self->dry,
        cache   => $self->cache,
        timeout => $self->timeout,
        agent   => $self->agent,
        proxy   => $self->proxy,
        wait    => $self->wait,
    );

    # URL template or plain URL
    if ( $self->url =~ qr{^https?://} ) {
        $options{ $self->vars ? 'url' : 'from' } = $self->url;
    }
    Catmandu::Importer::getJSON->new(%options);
}

sub BUILD {
    my ($self) = @_;
    unless ( defined $self->path ) {
        $self->{path} = $self->url =~ qr{^https?://} ? '' : $self->url;
    }
}

sub emit {
    my ( $self, $fixer ) = @_;
    my $path     = $fixer->split_path( $self->path );
    my $importer = $fixer->capture( $self->importer );

    # plain URL
    if ( $self->importer->from ) {
        return $fixer->emit_create_path(
            $fixer->var,
            $path,
            sub {
                sprintf '%s = %s->request(%s->from) // { };',
                  shift, $importer, $importer;
            }
        );
    }

    # URL template or base URL
    if ( $self->importer->url ) {
        my $tpl = $fixer->split_path( $self->vars );
        my $url = $fixer->generate_var;

        return $fixer->emit_create_path(
            $fixer->var,
            $tpl,
            sub {
                my $tpl = shift;
                "my $url;"
                  . "if (is_hash_ref($tpl) or is_string($tpl) and $tpl !~ qr{^https?://}) {"
                  . "  $url = ${importer}->construct_url($tpl) " . "}"
                  . $fixer->emit_create_path(
                    $fixer->var,
                    $path,
                    sub {
                        sprintf '%s = %s ? %s->request(%s) // {} : {};',
                          shift, $url, $importer, $url;
                    }
                  );
            }
        );
    }

    # URL from field
    my $url = $fixer->split_path( $self->url );

    return $fixer->emit_create_path(
        $fixer->var,
        $url,
        sub {
            if ( $self->vars ) {
                my $base = shift;
                my $tpl  = $fixer->split_path( $self->vars );
                my $url  = $fixer->generate_var;

                return $fixer->emit_create_path(
                    $fixer->var,
                    $tpl,
                    sub {
                        my $tpl = shift;
                        "my $url;"
                          . "if (is_hash_ref($tpl) or is_string($tpl) and $tpl !~ qr{^https?://}) {"
                          . "  $url = ${importer}->construct_url($base, $tpl); "
                          . "}"
                          . $fixer->emit_create_path(
                            $fixer->var,
                            $path,
                            sub {
                                sprintf '%s = %s ? %s->request(%s) // {} : {};',
                                  shift, $url, $importer, $url;
                            }
                          );
                    }
                );
            }
            else {
                my $url = shift;
                return $fixer->emit_create_path(
                    $fixer->var,
                    $path,
                    sub {
                        sprintf '%s = %s->request(%s) // { };',
                          shift, $importer, $url;
                    }
                );
            }
        }
    );

}

1;
__END__

=head1 NAME

Catmandu::Fix::get_json - get JSON data from an URL as fix function

=head1 SYNOPSIS

	# fetches a hash or array
	get_json("http://example.com/json")

	# stores it in path.key
	get_json("http://example.com/json", path: path.key)

    # add URL query parameters or URL path from config
	get_json("http://example.com/", vars: config)

    # fill URL template fields from config
	get_json("http://example.com/{name}.json", vars: config)

  	# get URL or URL template from a field
	get_json(field.name)
 
=head1 DESCRIPTION

This L<Catmandu::Fix> provides a method to fetch JSON data from an URL. The
response is added as new item or to a field of the current item.

=head1 OPTIONS

The first argument must be an URL, an URL template, or a field where to take
an URL or URL template from. Additional options include:

=over

=item path

Field to store result JSON in. If not given or set to the empty string, the
whole item is replaced by the fetched JSON response. If the first argument is a
field, the same field is used as C<path> by default.

=item vars

Field to get URL template variables, URL query parameters or an URL path
expression from. This option is required if the first argument is an URL
template. 

=back

The fix function also supports options C<dry>, C<cache>, C<timeout>, C<agent>,
C<proxy>, and C<wait> as documented in L<Catmandu::Importer::getJSON>.  Options
C<client>, C<headers>, and C<warn> are not supported.

=cut
