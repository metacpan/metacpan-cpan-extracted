package App::PAIA::Command;
use strict;
use v5.10;

our $VERSION = '0.30';

use App::Cmd::Setup -command;
use App::PAIA::Agent;
use App::PAIA::JSON;
use App::PAIA::File;
use URI::Escape;
use URI;

# TODO: move option handling to App::PAIA

# Implements lazy accessors just like Mo, Moo, Moose...
sub has {
    my ($name, %options) = @_;
    my $coerce  = $options{coerce} || sub { $_[0] };
    my $default = $options{default};
    no strict 'refs'; ## no critic 
    *{__PACKAGE__."::$name"} = sub {
        if (@_ > 1) {
            $_[0]->{$name} = $coerce->($_[1]);
        } elsif (!exists $_[0]->{$name} && $default) {
            $_[0]->{$name} = $coerce->($default->($_[0]));
        } else {
            $_[0]->{$name}
        }
    }
}

sub option {
    my ($self, $name) = @_;
    $self->app->global_options->{$name} # command line
        // $self->config->get($name)    # config file
        // $self->session->get($name); # session file
}

has config => ( 
    default => sub {
        App::PAIA::File->new(
            logger => $_[0]->logger,
            type   => 'config',
            file   => $_[0]->app->global_options->config,
        ) 
    }
);

has session => ( 
    default => sub { 
        App::PAIA::File->new(
            logger => $_[0]->logger,
            type   => 'session',
            file   => $_[0]->app->global_options->session,
        ) 
    }
);

has agent => (
    default => sub {
        App::PAIA::Agent->new(
            insecure => $_[0]->option('insecure'),
            logger   => $_[0]->logger,
            dumper   => $_[0]->dumper,
        );
    }
);

has logger => (
    default => sub {
        ($_[0]->app->global_options->verbose || $_[0]->app->global_options->debug)
            ? sub { say "# $_" for split "\n", $_[0]; }
            : sub { };
    }
);

has dumper => (
    default => sub {
        $_[0]->app->global_options->debug
            ? sub { say "> $_" for split "\n", $_[0]; }
            : sub { };
    }
);

sub base_url {
    my ($self, $name) = @_;
   
    # command line
    if ( defined $self->app->global_options->{$name} ) {
        return $self->app->global_options->{$name}; 
    }

    my $base = $self->app->global_options->{base};
    if (defined $base) {
        $base =~ s{/$}{}; 
        return "$base/$name";
    }

    # session file or config file
    foreach ( $self->session, $self->config ) {
        if ( defined $_->get($name) ) {
            return $_->get($name);
        }
    }
    
    # config file with base
    if ( defined $self->config->get('base') ) {
        my $base = $self->config->get('base');
        $base =~ s{/$}{}; 
        return $base . "/$name";
    }

    return;
}

has auth => (
    default => sub {
        $_[0]->base_url('auth');
    }
);

has core => (
    default => sub {
        $_[0]->base_url('core');
    }
);

has base => (
    default => sub { $_[0]->option('base') },
    coerce  => sub { my ($b) = @_; $b =~ s!/$!!; $b; }
);

has patron => (
    default => sub { $_[0]->option('patron') }
);

has scope => (
    default => sub { $_[0]->option('scope') }
);

has token => (
    default => sub { $_[0]->option('access_token') }
);

has username => (
    default => sub {
        $_[0]->option('username') // $_[0]->usage_error("missing username")
    }
);

has password => (
    default => sub {
        $_[0]->option('password') // $_[0]->usage_error("missing password")
    }
);

sub expired {
    my ($self) = @_;

    my $expires = $self->session->get('expires_at');
    return $expires ? $expires <= time : 0;
}

sub not_authentificated {
    my ($self, $scope) = @_;

    my $token = $self->token // return "missing access token";

    return "access token expired" if $self->expired;

    if ($scope and $self->scope and !$self->has_scope($scope)) {
        return "current scope '{$self->scope}' does not include $scope!\n";
    }

    return;
}

sub has_scope {
    my ($self, $scope) = @_;
    my $has_scope = $self->scope // '';
    return index($has_scope, $scope) != -1;
}

sub request {
    my ($self, $method, $url, $param) = @_;

    my %headers;
    if ($url !~ /login$/) {
        my $token = $self->token // die "missing access_token - login required\n";
        $headers{Authorization} = "Bearer $token";
    }

    my ($response, $json) = $self->agent->request( $method, $url, $param, %headers );

    # handle request errors
    if (ref $json and defined $json->{error}) {
        my $msg = $json->{error};
        if (defined $json->{error_description}) {
            $msg .= ': '.$json->{error_description};
        }
        die "$msg\n";
    }

    if ($response->{status} ne '200') {
        my $msg = $response->{content} // 'HTTP request failed: '.$response->{status};
        die "$msg\n";
    }

    if (my $scopes = $response->{headers}->{'x-oauth-scopes'}) {
        $self->session->set( scope => $scopes );
    }

    return $json;
}

sub login {
    my ($self, $scope) = @_;

    if ($self->session->purge) {
        $self->session->file(undef);
        $self->logger->("deleted session file");
    }

    my $auth = $self->auth or $self->usage_error("missing PAIA auth server URL");

    # take credentials from command line or config file only
    my %params = (
        username   => $self->username,
        password   => $self->password,
        grant_type => 'password',
    );

    if (defined $scope) {
        $scope =~ s/,/ /g;
        $params{scope} = $scope;
    }

    my $response = $self->request( "POST", "$auth/login", \%params );

    $self->{$_} = $response->{$_} for qw(expires_in access_token token_type patron scope);

    $self->session->set( $_, $response->{$_} ) for qw(access_token patron scope);
    $self->session->set( expires_at => time + $response->{expires_in} );
    $self->session->set( auth => $auth );
    $self->session->set( core => $self->core ) if defined $self->core;

    $self->store_session;
    
    return $response;
}


our %required_scopes = (
    patron  => 'read_patron',
    items   => 'read_items',
    request => 'write_items',
    renew   => 'write_items',
    cancel  => 'write_items',
    fees    => 'read_fees',
    change  => 'change_password',
);

sub auto_login_for {
    my ($self, $command) = @_;

    my $scope = $required_scopes{$command};

    if ( $self->not_authentificated($scope) ) {
        # add to existing scopes (TODO: only if wanted)
        my $new_scope = join ' ', split(' ',$self->scope // ''), $scope;
        $self->logger->("auto-login with scope '$new_scope'");
        $self->login( $new_scope );
        if ( $self->scope and !$self->has_scope($scope) ) {
            die "current scope '{$self->scope}' does not include $scope!\n";
        }
    }
}

sub store_session {
    my ($self) = @_;

    $self->session->store;

    $self->token($self->session->get('access_token'))
        if defined $self->session->get('access_token');
    $self->scope($self->session->get('scope'))
        if defined $self->session->get('scope');
    $self->patron($self->session->get('patron'))
        if defined $self->session->get('patron');
    # TODO: expires_at?
}

sub core_request {
    my ($self, $method, $command, $params) = @_;

    my $core  = $self->core // $self->usage_error("missing PAIA core server URL");

    $self->auto_login_for($command);

    my $patron = $self->patron // $self->usage_error("missing patron identifier");

    my $url = "$core/".uri_escape($patron);
    $url .= "/$command" if $command ne 'patron';

    # save PAIA core URL in session
    if ( ($self->session->get('core') // '') ne $core ) {
        $self->session->set( core => $core );
        $self->store_session;
        # TODO: could we save new expiry as well? 
    }

    my $json = $self->request( $method => $url, $params );

    if ($json->{doc}) {
        # TODO: more details about failed documents
        my @errors = grep { defined $_ } map { $_->{error} } @{$json->{doc}};
        if (@errors) {
            die join("\n", @errors)."\n";;
        }
    }

    return $json;
}

# used in command::renew and ::cancel
sub uri_list {
    my $self = shift;
    map {
        /^((edition|item)=)?(.+)/;
        my $uri = URI->new($3);
        $self->usage_error("not an URI: $3") unless $uri and $uri->scheme;
        my $d = { ($2 // "item") => "$uri" };
        $d;
    } @_;
}

# TODO:

sub description {
    my ($class) = @_;
    $class = ref $class if ref $class;

    # classname to filename
    (my $pm_file = $class) =~ s!::!/!g;
    $pm_file .= '.pm';
    $pm_file = $INC{$pm_file} or return '';
    
    open my $input, "<", $pm_file or return '';

    my $descr = "";
    open my $output, ">", \$descr;

    use Pod::Usage;
    pod2usage( -input => $input,
               -output => $output, 
               -exit => "NOEXIT", -verbose => 99, 
               -sections => "DESCRIPTION",
               indent => 0,
    );           
    $descr =~ s/Description:\n//m;
    chomp $descr;

    return $descr;
}

# TODO: Think about making this part of App::Cmd
#       see https://github.com/rjbs/App-Cmd/issues/30
sub execute {
    my $self = shift;

    if ($self->app->global_options->version) {
        $self->app->execute_command( $self->app->prepare_command('version') );
        exit;
    } elsif ($self->app->global_options->help) {
#        $self->app->execute_command( $self->app->prepare_command('help', @ARGV) );
#        exit;
    }

    my $response = $self->_execute(@_);
    if (defined $response and !$self->app->global_options->quiet) {
        print encode_json($response);
    }
}

1;
__END__

=head1 NAME

App::PAIA::Command - common base class of PAIA client commands

=head1 SEE ALSO

L<App::Cmd::Setup>

=cut
