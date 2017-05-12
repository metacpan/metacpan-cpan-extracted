#
# This file is part of CatalystX-Test-Recorder
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Test::Recorder::Controller;
BEGIN {
  $CatalystX::Test::Recorder::Controller::VERSION = '1.0.0';
}

use Moose;
use utf8;
use Template::Alloy;
use Perl::Tidy;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' };

has skip => ( isa => 'ArrayRef[RegexpRef]', is => 'rw' );
has namespace => ( isa => 'Str', is => 'rw' );
has template => ( isa => 'Str', is => 'rw' );

__PACKAGE__->config( namespace => 'recorder', skip => [qr/^static\//, qr/^favicon.ico/] );

our $requests = [];
our $responses = [];
our $record   = 0;

my $template = do { local $/ = undef; <DATA> };

after BUILD => sub {
    my $self = shift;
    my $app = $self->_app;
    my $config = $app->config->{'CatalystX::Test::Recorder'} || {};
    $config = $self->merge_config_hashes($self->config, $config);
    while(my($k,$v) = each %$config) {
        $self->$k($v);
    }
};

sub action_namespace {
    my ( $self, $c ) = @_;
    my $class = ref($self) || $self;
    my $appclass = ref($c) || $c;
    return $appclass->config->{'CatalystX::Test::Recorder'}->{namespace} || $class->config->{namespace};
}

sub start : Local {
    my ( $self, $c ) = @_;
    $requests = []; $responses = [];
    $record   = 1;
    $c->res->body('Recording...');
}

sub stop : Local {
    my ( $self, $c ) = @_;
    if ($record) {
        shift(@$requests);
        shift(@$responses);
    }
    $record = 0;
    my $test = '';
    my $tt   = Template::Alloy->new(
        DUMP    => { html => 0, header => 0 },
        FILTERS => {
            perltidy => sub {
                my $tidy;
                Perl::Tidy::perltidy(
                    source      => \$_[0],
                    destination => \$tidy,
                    argv => [],
                );

                return $tidy;
              }
        }
    );
    $tt->define_vmethod(
        'hash', dump => sub {
            my $dump = Dumper $_[0];
            $dump =~ s/^.*?{(.*)}.*?$/$1/s;
            $dump =~ s/\n//g;
            return $dump;
        });
    $tt->process( $self->template || \$template, { requests => $requests, responses => $responses, app => ref $c }, \$test )
      or die $@;
    $c->res->body($test);

}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->content_type('text/plain');
}

1;



=pod

=head1 NAME

CatalystX::Test::Recorder::Controller

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__DATA__
[% FILTER perltidy -%]
# [% requests.size %] requests recorded.

use Test::More;
use strict;
use warnings;

use URI;
use HTTP::Request::Common qw(GET HEAD PUT DELETE POST);

use Test::WWW::Mechanize::Catalyst '[% app %]';

my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->requests_redirectable([]); # disallow redirects

my ($response, $request, $url);

[% FOREACH request IN requests %]
[% IF request.query_params.size %]$url = URI->new('/[% request.path %]');
$url->query_form( { [% request.query_params.dump %] } );
[% END -%]
$request = [% IF request.body_params.size; 'POST'; ELSE; request.method; END -%] 
[% IF request.query_params.size; '$url'; ELSE; "'/" _ request.path _ "'"; END -%]
[% IF request.body_params.size; ', [' _ request.body_params.dump _ ']'; END %];
[% IF request.body_params.size && request.method != 'POST'; '$request->method(\'' _ request.method _ '\');'; END -%]
$response = $mech->request($request);
is($response->code, [% responses.${loop.index}.code %]);
[% END %]

done_testing;
[%- END -%]
