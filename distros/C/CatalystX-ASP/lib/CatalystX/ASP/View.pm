package CatalystX::ASP::View;

use namespace::autoclean;
use Moose;
use CatalystX::ASP;
use Scalar::Util qw(blessed);
use HTTP::Date qw(time2str);
use Try::Tiny;

extends 'Catalyst::View';

has 'asp' => (
    is  => 'rw',
    isa => 'CatalystX::ASP',
);

=head1 NAME

CatalystX::ASP::View - Catalyst View for processing ASP scripts

=head1 SYNOPSIS

  package MyApp::Controller::Foo;

  sub 'asp' : Regex('\.asp$') {
    my ($self, $c, @args) = @_;
    $c->forward( $c->view( 'ASP' ), \@args );
  }

=head1 DESCRIPTION

This is the Catalyst View to handle ASP scripts. Given a C<$path> to the ASP
script, this will render the ASP script and populate C<< $c->response >> with
the computed headers and body.

=head1 METHODS

=over

=item $self->process($c, @args)

Takes a C<$path> or guesses base off C<< $c->request->path >>. After ASP
renders the output, this will populate C<< $c->response >> accordingly

=cut

sub process {
    my ( $self, $c, @args ) = @_;

    my $path = join '/', @args;

    try {
        $self->render( $c, $path );

        my $resp   = $self->asp->Response;
        my $status = $resp->Status;
        if ( $status >= 500 ) {
            $c->error( "Erroring out because HTTP Status set to $status" );
        } else {
            my $charset      = $resp->Charset;
            my $content_type = $resp->ContentType;
            $content_type .= "; charset=$charset" if $charset;
            $c->response->content_type( $content_type );
            $resp->_flush_Cookies( $c );
            $c->response->header( Cache_Control => $resp->CacheControl );
            $c->response->header( Expires => time2str( time + $resp->Expires ) ) if $resp->Expires;
            $c->response->status( $resp->Status || 200 );
            $c->response->body( $resp->Body );
        }
    } catch {

        # Passthrough $c->detach
        $_->rethrow if blessed( $_ ) && $_->isa( 'Catalyst::Exception::Detach' );

        # If error in other ASP code, return HTTP 500
        if ( blessed( $_ ) && !$_->isa( 'CatalystX::ASP::Exception::End' ) && !$c->has_errors ) {
            $c->error( "Encountered application error: $_" );
        }
    } finally {

        # Ensure destruction!
        $self->asp->cleanup;
    };

    return 1;
}

=item $self->render($c, $path)

This does the bulk work of ASP processing. First parse file, the compile. During
execution, kick off any hooks configured. Finally, properly handle errors,
passing through C<< $c->detach >> if called as a result of
C<< $Response->Redirect >> or C<< $Response->End >> if called in ASP script.

=cut

sub render {
    my ( $self, $c, $path ) = @_;

    # Create localized ENV because ASP modifies and assumes ENV being populated
    # with Request headers as in CGI
    local %ENV = %ENV;

    my $asp = $self->asp;
    if ( $asp ) {
        $asp->c( $c );
    } else {
        $asp = CatalystX::ASP->new( %{ $c->config->{'CatalystX::ASP'} }, c => $c );
        $self->asp( $asp );
    }

    my $compiled = $asp->compile_file( $c, $c->path_to( 'root', $path || $c->request->path ) );

    $asp->GlobalASA->Script_OnStart;
    $asp->execute( $c, $compiled->{code} );
    $asp->GlobalASA->Script_OnFlush;
}

__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

=over

=item * L<CatalystX::ASP>

=item * L<CatalystX::ASP::Role>

=back
