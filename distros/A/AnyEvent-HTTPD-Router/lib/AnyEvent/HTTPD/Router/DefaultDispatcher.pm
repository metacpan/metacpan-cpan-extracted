package AnyEvent::HTTPD::Router::DefaultDispatcher;

use common::sense;
use Carp;

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {
        routes => {}
    };

    return bless $self, $class;
}

sub add_route {
    my $self  = shift;
    my $verbs = shift;
    my $path  = shift;
    my $cb    = shift;

    unless (exists $self->{routes}->{$path}) {
        my @segments = split /\//, $path;
        $self->{routes}->{$path} = {
            segments  => \@segments, # something to improve speed
            callbacks => {},         # method/path => cb mapping
        };
    }

    my $dispatch_entry = $self->{routes}->{$path};
    foreach my $verb (@$verbs) {
        $dispatch_entry->{callbacks}->{$verb} = $cb;
    }
}

sub match {
    my $self    = shift;
    my $httpd   = shift;
    my $req     = shift;
    my $matched = 0;
    my @path    = $req->url->path_segments;
    my $method  = $req->method;

    if ( $method eq 'GET' or $method eq 'POST' ) {
        if ( @path[-1] =~ s/:(\w+)$// ) {    # TODO regex for verbs
            $method = $1;
        }
    }

    # sort because we want to have reproducable
    # behaviour for match
    foreach my $path ( sort keys %{ $self->{routes} } ) {
        my $dispatch_entry = $self->{routes}->{$path};

        # step 1: match the method/verb
        if ( my $cb = $dispatch_entry->{callbacks}->{$method} ) {
            # step 2: match the path
            if ( my $variables = _match_paths( \@path, $dispatch_entry->{segments} ) ) {
                $matched = 1;
                $cb->( $httpd, $req, $variables );
                last;
            }
        }
    }
    return $matched;
}

sub _match_paths {
    # copies
    my @request_path_seq = @{ +shift };
    my @routing_path_seq = @{ +shift };

    my $request_seq;
    my $routing_seq;
    my %variables;

    while (@request_path_seq or @routing_path_seq) {
        $request_seq = shift @request_path_seq; # maybe undef
        $routing_seq = shift @routing_path_seq; # maybe undef

        if ($routing_seq eq '*') {
            # done with all matching,
            # * slurps all the $request_seq that still might come
            $variables{'*'} = join('/', $request_seq, @request_path_seq);
            last;
        } elsif ($routing_seq eq $request_seq) {
            # go on with matching
        } elsif ($routing_seq =~ m/^\:(.+)$/ and defined $request_seq) {
            # remember the variable
            my $var_name = $1;
            $variables{$var_name} = $request_seq;
        } else {
            ## mismatch
            # if they are not equal
            # this includes if one of them is undef
            return;
        }
    }

    return \%variables;
}

1;
