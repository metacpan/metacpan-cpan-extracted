package BusyBird::Main::PSGI;
use v5.8.0;
use strict;
use warnings;
use BusyBird::Util qw(set_param future_of);
use BusyBird::Main::PSGI::View;
use Router::Simple;
use Plack::Request;
use Plack::Builder ();
use Plack::App::File;
use Try::Tiny;
use JSON qw(decode_json);
use Scalar::Util qw(looks_like_number);
use List::Util qw(min);
use Carp;
use Exporter 5.57 qw(import);
use URI::Escape qw(uri_unescape);
use Encode qw(decode_utf8);
use Future::Q;
use POSIX qw(ceil);


our @EXPORT_OK = qw(create_psgi_app);

sub create_psgi_app {
    my ($main_obj) = @_;
    my $self = __PACKAGE__->_new(main_obj => $main_obj);
    return $self->_to_app;
}

sub _new {
    my ($class, %params) = @_;
    my $self = bless {
        router => Router::Simple->new,
        view => undef, ## lazy build
    }, $class;
    $self->set_param(\%params, "main_obj", undef, 1);
    $self->_build_routes();
    return $self;
}

sub _to_app {
    my $self = shift;
    my $sharedir = $self->{main_obj}->get_config("sharedir_path");
    $sharedir =~ s{/+$}{};
    return Plack::Builder::builder {
        Plack::Builder::enable 'ContentLength';
        Plack::Builder::mount '/static' => Plack::App::File->new(
            root => File::Spec->catdir($sharedir, 'www', 'static')
        )->to_app;
        Plack::Builder::mount '/' => $self->_my_app;
    };
}

sub _my_app {
    my ($self) = @_;
    return sub {
        my ($env) = @_;
        $self->{view} ||= BusyBird::Main::PSGI::View->new(main_obj => $self->{main_obj}, script_name => $env->{SCRIPT_NAME});
        if(my $dest = $self->{router}->match($env)) {
            my $req = Plack::Request->new($env);
            my $code = $dest->{code};
            my $method = $dest->{method};
            return defined($code) ? $code->($self, $req, $dest) : $self->$method($req, $dest);
        }else {
            return $self->{view}->response_notfound();
        }
    };
}

sub _build_routes {
    my ($self) = @_;
    my $tl_mapper = $self->{router}->submapper(
        '/timelines/{timeline}', {}
    );
    $tl_mapper->connect('/statuses.{format}',
                        {method => '_handle_tl_get_statuses'}, {method => 'GET'});
    $tl_mapper->connect('/statuses.json',
                        {method => '_handle_tl_post_statuses'}, {method => 'POST'});
    $tl_mapper->connect('/ack.json',
                        {method => '_handle_tl_ack'}, {method => 'POST'});
    $tl_mapper->connect('/updates/unacked_counts.json',
                        {method => '_handle_tl_get_unacked_counts'}, {method => 'GET'});
    $tl_mapper->connect($_, {method => '_handle_tl_index'}) foreach "", qw(/ /index.html /index.htm);
    $self->{router}->connect('/updates/unacked_counts.json',
                             {method => '_handle_get_unacked_counts'}, {method => 'GET'});
    foreach my $path ("/", "/index.html") {
        $self->{router}->connect($path, {method => '_handle_get_timeline_list'}, {method => 'GET'});
    }
}

sub _get_timeline_name {
    my ($dest) = @_;
    my $name = $dest->{timeline};
    $name = "" if not defined($name);
    $name =~ s/\+/ /g;
    return decode_utf8(uri_unescape($name));
}

sub _get_timeline {
    my ($self, $dest) = @_;
    my $name = _get_timeline_name($dest);
    my $timeline = $self->{main_obj}->get_timeline($name);
    if(!defined($timeline)) {
        die qq{No timeline named $name};
    }
    return $timeline;
}

sub _handle_tl_get_statuses {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        my $timeline;
        my $only_statuses = !!($req->query_parameters->{only_statuses});
        my $format = !defined($dest->{format}) ? ""
            : (lc($dest->{format}) eq "json" && $only_statuses) ? "json_only_statuses"
            : $dest->{format};
        Future::Q->try(sub {
            $timeline = $self->_get_timeline($dest);
            my $count = $req->query_parameters->{count} || 20;
            if(!looks_like_number($count) || int($count) != $count) {
                die "count parameter must be an integer\n";
            }
            my $ack_state = $req->query_parameters->{ack_state} || 'any';
            my $max_id = decode_utf8($req->query_parameters->{max_id});
            return future_of($timeline, "get_statuses",
                             count => $count, ack_state => $ack_state, max_id => $max_id);
        })->then(sub {
            my $statuses = shift;
            $responder->($self->{view}->response_statuses(
                statuses => $statuses, http_code => 200, format => $format,
                timeline_name => $timeline->name
            ));
        })->catch(sub {
            my ($error, $is_normal_error) = @_;
            $responder->($self->{view}->response_statuses(
                error => "$error", http_code => ($is_normal_error ? 500 : 400), format => $format,
                ($timeline ? (timeline_name => $timeline->name) : ())
            ));
        });
    };
}

sub _handle_tl_post_statuses {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        Future::Q->try(sub {
            my $timeline = $self->_get_timeline($dest);
            my $posted_obj = decode_json($req->content);
            if(ref($posted_obj) ne 'ARRAY') {
                $posted_obj = [$posted_obj];
            }
            return future_of($timeline, "add_statuses", statuses => $posted_obj);
        })->then(sub {
            my $added_num = shift;
            $responder->($self->{view}->response_json(200, {count => $added_num + 0}));
        })->catch(sub {
            my ($e, $is_normal_error) = @_;
            $responder->($self->{view}->response_json(($is_normal_error ? 500 : 400), {error => "$e"}));
        });
    };
}

sub _handle_tl_ack {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        Future::Q->try(sub {
            my $timeline = $self->_get_timeline($dest);
            my $max_id = undef;
            my $ids = undef;
            if($req->content) {
                my $body_obj = decode_json($req->content);
                if(ref($body_obj) ne 'HASH') {
                    die "Response body must be an object.\n";
                }
                $max_id = $body_obj->{max_id};
                $ids = $body_obj->{ids};
            }
            return future_of($timeline, "ack_statuses", max_id => $max_id, ids => $ids);
        })->then(sub {
            my $acked_num = shift;
            $responder->($self->{view}->response_json(200, {count => $acked_num + 0}));
        })->catch(sub {
            my ($e, $is_normal_error) = @_;
            $responder->($self->{view}->response_json(($is_normal_error ? 500 : 400), {error => "$e"}));
        });
    };
}

sub _handle_tl_get_unacked_counts {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        Future::Q->try(sub {
            my $timeline = $self->_get_timeline($dest);
            my $query_params = $req->query_parameters;
            my %assumed = ();
            if(defined $query_params->{total}) {
                $assumed{total} = delete $query_params->{total};
            }
            foreach my $query_key (keys %$query_params) {
                next if !looks_like_number($query_key);
                next if int($query_key) != $query_key;
                $assumed{$query_key} = $query_params->{$query_key};
            }
            my $ret_future = Future::Q->new;
            $timeline->watch_unacked_counts(assumed => \%assumed, callback => sub {
                my ($error, $w, $unacked_counts) = @_;
                $w->cancel(); ## immediately cancel the watcher to prevent multiple callbacks
                if($error) {
                    $ret_future->reject($error, 1);
                }else {
                    $ret_future->fulfill($unacked_counts);
                }
            });
            return $ret_future;
        })->then(sub {
            my ($unacked_counts) = @_;
            $responder->($self->{view}->response_json(200, {unacked_counts => $unacked_counts}));
        })->catch(sub {
            my ($e, $is_normal_error) = @_;
            $responder->($self->{view}->response_json(($is_normal_error ? 500 : 400), {error => "$e"}));
        });
    };
}

sub _handle_get_unacked_counts {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        Future::Q->try(sub {
            my $query_params = $req->query_parameters;
            my $level = $query_params->{level};
            if(not defined($level)) {
                $level = "total";
            }elsif($level ne 'total' && (!looks_like_number($level) || int($level) != $level)) {
                die "level parameter must be an integer\n";
            }
            my %assumed = ();
            foreach my $query_key (keys %$query_params) {
                next if substr($query_key, 0, 3) ne 'tl_';
                $assumed{decode_utf8(substr($query_key, 3))} = $query_params->{$query_key};
            }
            my $ret_future = Future::Q->new;
            $self->{main_obj}->watch_unacked_counts(
                level => $level, assumed => \%assumed, callback => sub {
                    my ($error, $w, $tl_unacked_counts) = @_;
                    $w->cancel(); ## immediately cancel the watcher to prevent multiple callbacks
                    if($error) {
                        $ret_future->reject($error, 1);
                    }else {
                        $ret_future->fulfill($tl_unacked_counts);
                    }
                }
            );
            return $ret_future;
        })->then(sub {
            my ($tl_unacked_counts) = @_;
            $responder->($self->{view}->response_json(200, {unacked_counts => $tl_unacked_counts}));
        })->catch(sub {
            my ($e, $is_normal_error) = @_;
            $responder->($self->{view}->response_json(($is_normal_error ? 500 : 400), {error => "$e"}));
        });
    };
}

sub _handle_tl_index {
    my ($self, $req, $dest) = @_;
    return $self->{view}->response_timeline(_get_timeline_name($dest));
}

sub _handle_get_timeline_list {
    my ($self, $req, $dest) = @_;
    return sub {
        my $responder = shift;
        Future::Q->try(sub {
            my $num_per_page = $self->{main_obj}->get_config('timeline_list_per_page');
            my @timelines = grep {
                !$self->{main_obj}->get_timeline_config($_->name, "hidden")
            } $self->{main_obj}->get_all_timelines();
            if(@timelines == 0) {
                die "No visible timeline. Probably you must configure config.psgi to create a timeline.";
            }
            my $page_num = ceil(scalar(@timelines) / $num_per_page);
            my $cur_page = 0;
            my $query = $req->query_parameters;
            if(defined $query->{page}) {
                if(!looks_like_number($query->{page}) || $query->{page} < 0 || $query->{page} >= $page_num) {
                    die "Invalid page parameter\n";
                }
                $cur_page = $query->{page};
            }
            my @target_timelines = @timelines[($cur_page * $num_per_page) .. min(($cur_page+1) * $num_per_page - 1, $#timelines)];
            return Future::Q->needs_all(map { future_of($_, "get_unacked_counts") } @target_timelines)->then(sub {
                my (@unacked_counts_list) = @_;
                my @timeline_unacked_counts = map {
                    +{ name => $target_timelines[$_]->name, counts => $unacked_counts_list[$_] }
                } 0 .. $#target_timelines;
                $responder->( $self->{view}->response_timeline_list(
                    timeline_unacked_counts => \@timeline_unacked_counts,
                    total_page_num => $page_num,
                    cur_page => $cur_page
                ) );
            });
        })->catch(sub {
            my ($error, $is_normal_error) = @_;
            $responder->($self->{view}->response_error_html(
                ($is_normal_error ? 500 : 400), $error
            ));
        });
    };
}

1;


__END__

=pod

=head1 NAME

BusyBird::Main::PSGI - PSGI controller for BusyBird::Main

=head1 SYNOPSIS

    use BusyBird::Main;
    use BusyBird::Main::PSGI qw(create_psgi_app);
    
    my $main = BusyBird::Main->new();
    my $psgi_app = create_psgi_app($main);

=head1 DESCRIPTION

This is the controller object for L<BusyBird::Main>.
It creates a L<PSGI> application from a L<BusyBird::Main> object.

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $psgi_app = create_psgi_app($main_obj)

Creates a L<PSGI> application object.

C<$main_obj> is a L<BusyBird::Main> object.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
