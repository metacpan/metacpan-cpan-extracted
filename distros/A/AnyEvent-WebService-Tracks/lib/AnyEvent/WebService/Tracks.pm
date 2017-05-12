package AnyEvent::WebService::Tracks;

use strict;
use warnings;

use AnyEvent::HTTP qw(http_request);
use Carp qw(croak);
use DateTime;
use DateTime::Format::ISO8601;
use MIME::Base64 qw(encode_base64);
use URI;
use XML::Parser;
use XML::Writer;

use AnyEvent::WebService::Tracks::Context;
use AnyEvent::WebService::Tracks::Project;
use AnyEvent::WebService::Tracks::Todo;

our $VERSION = '0.02';

sub new {
    my ( $class, %params ) = @_;

    return bless {
        url      => URI->new($params{url}),
        username => $params{username},
        password => $params{password},
    }, $class;
}

sub parse_datetime {
    my ( $self, $str ) = @_;

    return DateTime::Format::ISO8601->parse_datetime($str);
}

sub format_datetime {
    my ( $self, $datetime ) = @_;

    my @fields = qw/year month day hour minute second/;
    my %attrs = map { $_ => $datetime->$_() } @fields;
    my $offset = DateTime::TimeZone->offset_as_string($datetime->offset);

    return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s', @attrs{@fields}, $offset;
}

sub handle_error {
    my ( $self, $body, $headers, $cb ) = @_;

    my $message;

    if($body) {
        # context creation serves errors in XML, but project creation in plain text,
        # even though the Content-Type is application/xml...
        if($body =~ /^\s*<\?xml/) {
            my $error = $self->parse_single(undef, $body);
            $message  = $error->{'error'};
        } else {
            $message = $body;
        }
    } else {
        $message = $headers->{'status'};
    }

    $cb->(undef, $message);
}

sub generate_xml {
    my ( $self, $root, $attrs ) = @_;

    my $xml  = '';
    my $w    = XML::Writer->new(OUTPUT => \$xml);
    my @keys = sort keys %$attrs;

    $w->startTag($root);
    foreach my $k (@keys) {
        my $v = $attrs->{$k};
        my @xml_attrs;

        push @xml_attrs, (nil => 'true') unless defined $v;
        if(ref($v) eq 'DateTime') {
            push @xml_attrs, (type => 'datetime');
            $v = $self->format_datetime($v);
        }

        my $nk = $k;
        $nk =~ tr/_/-/;

        $w->startTag($nk, @xml_attrs);
        $w->characters($v) if defined $v;
        $w->endTag($nk);
    }
    $w->endTag($root);
    $w->end;

    return $xml;
}

sub status_successful {
    my ( $self, $status ) = @_;

    return ($status >= 200 && $status < 300);
}

sub do_request {
    my ( $self, $http_method, $uri, $params, $method, $cb ) = @_;

    my ( $username, $password ) = @{$self}{qw/username password/};

    my $auth_token = encode_base64(join(':', $username, $password), '');
    $params->{'headers'} = {
        Authorization => "Basic $auth_token",
        Accept        => 'application/xml',
        Referer       => undef,
    };
    if($params->{'body'}) {
        $params->{'headers'}{'Content-Type'} = 'text/xml';
    }

    my $handle_result = sub {
        my ( $data, $headers ) = @_;

        if($self->status_successful($headers->{'Status'})) {
            $cb->($self->$method($data, $headers));
        } else {
            $self->handle_error($data, $headers, $cb);
        }
    };

    unless(ref($uri) eq 'URI') {
        if(ref($uri) eq 'ARRAY') {
            my $copy = $self->{url}->clone;
            $copy->path_segments($copy->path_segments, @$uri);
            $uri = $copy;
        }
    }

    http_request $http_method, $uri, %$params, $handle_result;
}

sub do_get {
    my ( $self, $uri, $method, $cb ) = @_;

    $self->do_request(GET => $uri, {}, $method, $cb);
}

sub do_delete {
    my ( $self, $uri, $method, $cb ) = @_;

    $self->do_request(DELETE => $uri, {}, $method, $cb);
}

sub do_post {
    my ( $self, $uri, $body, $method, $cb ) = @_;

    $self->do_request(POST => $uri, { body => $body }, $method, $cb);
}

sub do_put {
    my ( $self, $uri, $body, $method, $cb ) = @_;

    $self->do_request(PUT => $uri, { body => $body }, $method, $cb);
}

sub parse_entities {
    my ( $self, $xml, $type, $target_depth ) = @_;

    my @entities;
    my $current_entity;
    my $current_tag;
    my $current_attrs;
    my $depth = 0;

    my $parser = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ( undef, $tag, %attrs ) = @_;

                if($depth == $target_depth) {
                    $current_entity = {};
                } elsif($depth > $target_depth) {
                    $current_tag = $tag;
                    $current_attrs = \%attrs;

                    $current_tag =~ tr/-/_/;

                    my $nil = $attrs{'nil'};
                    $nil = defined($nil) && $nil eq 'true';
                    
                    if($nil) {
                        $current_entity->{$current_tag} = undef;
                    } else {
                        $current_entity->{$current_tag} = '';
                    }
                }

                $depth++;
            },
            End   => sub {
                my ( undef, $tag ) = @_;

                $depth--;

                if($depth == $target_depth) {
                    if(defined $type) {
                        push @entities, $type->new(parent => $self,
                            %$current_entity);
                    } else {
                        push @entities, $current_entity;
                    }

                    undef $current_entity;
                    undef $current_tag;
                    undef $current_attrs;
                } elsif($depth > $target_depth) {
                    my $type = $current_attrs->{'type'};
                    $type = '' unless defined $type;

                    if($type eq 'datetime') {
                        my $value = $current_entity->{$current_tag};

                        if(defined $value) {
                            $current_entity->{$current_tag} =
                                $self->parse_datetime($value);
                        }
                    }
                    undef $current_tag;
                    undef $current_attrs;
                }
            },
            Char  => sub {
                my ( undef, $chars ) = @_;

                if(defined $current_tag) {
                    $current_entity->{$current_tag} .= $chars;
                }
            },
        },
    );

    $parser->parse($xml);

    return \@entities;
}

sub parse_single {
    my ( $self, $type, $xml ) = @_;

    return $self->parse_entities($xml, $type, 0)->[0];
}

sub parse_multiple {
    my ( $self, $type, $xml ) = @_;

    return $self->parse_entities($xml, $type, 1);
}

sub fetch_multiple {
    my ( $self, $path, $type, $cb ) = @_;

    my $uri = $self->{'url'}->clone;
    my @segments = split /\//, $path . '.xml';
    $uri->path_segments($uri->path_segments, @segments);

    $self->do_get($uri, sub {
        my ( undef, $data ) = @_;

        return $self->parse_multiple($type, $data);
    }, $cb);
}

sub fetch_from_location {
    my ( $self, $url, $type, $cb ) = @_;

    $self->do_get($url, sub {
        my ( undef, $data ) = @_;

        return $self->parse_single($type, $data);
    }, $cb);
}

sub fetch_single {
    my ( $self, $path, $id, $type, $cb ) = @_;

    my $uri = $self->{'url'}->clone;
    $uri->path_segments($uri->path_segments, $path, "$id.xml");

    $self->fetch_from_location($uri, $type, $cb);
}

sub create {
    my ( $self, $path, $type, $root, $attrs, $cb ) = @_;

    my $uri = $self->{'url'}->clone;
    $uri->path_segments($uri->path_segments, $path . '.xml');

    my $xml = $self->generate_xml($root, $attrs);

    $self->do_post($uri, $xml, sub {
        # pass the data and headers along to the following callback
        return @_[1, 2];
    }, sub {
        my ( $data, $headers ) = @_;

        # handle errors during the last phase
        unless(defined $data) {
            $cb->($data, $headers);
            return;
        }

        if($self->status_successful($headers->{'Status'})) {
            my $location = $headers->{'location'};

            $self->fetch_from_location($location, $type, $cb);
        } else {
            $self->handle_error($data, $headers, $cb);
        }
    });
}

sub projects {
    my ( $self, $cb ) = @_;

    $self->fetch_multiple('projects', 'AnyEvent::WebService::Tracks::Project', $cb);
}

sub contexts {
    my ( $self, $cb ) = @_;

    $self->fetch_multiple('contexts', 'AnyEvent::WebService::Tracks::Context', $cb);
}

sub todos {
    my ( $self, $cb ) = @_;

    $self->fetch_multiple('todos', 'AnyEvent::WebService::Tracks::Todo', $cb);
}

sub create_context {
    my $self = shift;
    my $cb   = pop;
    my %params;

    if(@_ == 1) {
        ( $params{'name'} ) = @_;
    } else {
        %params = @_;
    }
    if(exists $params{'hide'}) {
        $params{'hide'} = $params{'hide'} ? 'true' : 'false';
    }

    $self->create('contexts', 'AnyEvent::WebService::Tracks::Context',
        context => \%params, $cb);
}

sub create_project {
    my $self = shift;
    my $cb   = pop;
    my %params;

    if(@_ == 1) {
        ( $params{'name'} ) = @_;
    } else {
        %params = @_;
    }
    if(exists $params{'default_context'}) {
        my $ctx = delete $params{'default_context'};
        if(defined $ctx) {
            unless(ref($ctx) eq 'AnyEvent::WebService::Tracks::Context') {
                croak "Parameter 'default_context' is not an AnyEvent::WebService::Tracks::Context";
            }
            $params{'default_context_id'} = $ctx->id;
        }
    }

    $self->create('projects', 'AnyEvent::WebService::Tracks::Project',
        project => \%params, $cb);
}

sub create_todo {
    my $self = shift;
    my $cb   = pop;
    my %params;

    if(@_ == 2) {
        if(ref($_[1]) eq 'AnyEvent::WebService::Tracks::Project') {
            ( @params{qw/description project/} ) = @_;
        } else {
            ( @params{qw/description context/} ) = @_;
        }
    } else {
        %params = @_;
    }
    if(my $context = delete $params{'context'}) {
        unless(ref($context) eq 'AnyEvent::WebService::Tracks::Context') {
            croak "Parameter 'context' is not an AnyEvent::WebService::Tracks::Context";
        }
        $params{'context_id'} = $context->id;
    }
    if(my $project = delete $params{'project'}) {
        unless(ref($project) eq 'AnyEvent::WebService::Tracks::Project') {
            croak "Parameter 'project' is not an AnyEvent::WebService::Tracks::Project";
        }
        $params{'project_id'} = $project->id;
        # naughty...violation of privacy
        if(! exists($params{'context_id'}) && defined($project->{'default_context_id'})) {
            $params{'context_id'} = $project->{'default_context_id'};
        }
    }
    unless(exists $params{'context_id'} || exists $params{'project_id'}) {
        croak "Required parameters 'context' and 'project' not found; you must specify at least one of them";
    }

    if(my $project = delete $params{'project'}) {
        unless(ref($project) eq 'AnyEvent::WebService::Tracks::Project') {
            croak "Parameter 'project' is not an AnyEvent::WebService::Tracks::Project";
        }
        $params{'project_id'} = $project->id;
    }

    $self->create('todos', 'AnyEvent::WebService::Tracks::Todo',
        todo => \%params, $cb);
}

1;

__END__

=head1 NAME

AnyEvent::WebService::Tracks - Access Tracks' API from AnyEvent

=head1 VERSION

0.02

=head1 SYNOPSIS

  use AnyEvent::WebService::Tracks;

  my $tracks = AnyEvent::WebService::Tracks->new(
    url      => 'http://my.tracks.instance/',
    username => 'user',
    password => 'pa55w0rd',
  );

  $tracks->projects(sub {
    my ( $projects ) = @_;

    say foreach @$projects;
  });

  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent::WebService::Tracks talks to Tracks' API from an AnyEvent loop, using
AnyEvent::HTTP.

Before you go ahead and use this module, please make sure you run the test suite
against the Tracks version you'll be using; I developed this module against Tracks
1.7.2, so I can't really guarantee it'll work with any other version.  If you find
a bug when running against another version, please let me know and I'll try to fix
it as long as it doesn't break other versions.

=head1 METHODS

=head2 AnyEvent::WebService::Tracks->new(%params)

Creates a new AnyEvent::WebService::Tracks object.  C<%params> must contain
the url, username, and password parameters.

=head2 $tracks->projects($callback)

Retrieves the list of projects in the given Tracks installation and provides
them to the given callback.  If the call fails, then a falsy value and the
error message are provided to the callback.

=head2 $tracks->create_project($name, $callback)
=head2 $tracks->create_project(%params, $callback)

Creates a new project with the given name (a hash of parameters can be
provided instead of just a scalar name if more flexibility is desired) and
passes the new project object to the given callback.  If the call fails, then
a falsy value and the error message are provided to the callback.

=head2 $tracks->contexts($callback)

Retrieves the list of contexts in the given Tracks installation and provides
them to the given callback.  If the call fails, then a falsy value and the
error message are provided to the callback.

=head2 $tracks->create_context($name, $callback)
=head2 $tracks->create_context(%params, $callback)

Creates a new context with the given name (a hash of parameters can be
provided instead of just a scalar name if more flexibility is desired) and
passes the new context object to the given callback.  If the call fails, then
a falsy value and the error message are provided to the callback.

=head2 $tracks->todos($callback)

Retrieves the list of todos in the given Tracks installation and provides
them to the given callback.  If the call fails, then a falsy value and the
error message are provided to the callback.

=head2 $tracks->create_todo($name, $context, $callback)
=head2 $tracks->create_todo(%params, $callback)

Creates a new todo with the given name and context (a hash of parameters can
be provided instead of just two scalars if more flexibility is desired) and
passes the new todo object to the given callback.  If the call fails, then
a falsy value and the error message are provided to the callback.

=head1 AUTHOR

Rob Hoelz, C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-AnyEvent-WebService-Tracks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-WebService-Tracks>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<http://getontracks.org>


=begin comment

Undocumented methods (for Pod::Coverage)

=over

=item create
=item do_delete
=item do_get
=item do_post
=item do_put
=item do_request
=item fetch_from_location
=item fetch_multiple
=item fetch_single
=item format_datetime
=item generate_xml
=item handle_error
=item parse_datetime
=item parse_entities
=item parse_multiple
=item parse_single
=item status_successful

=back

=end comment

=cut
