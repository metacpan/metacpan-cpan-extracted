package App::Duppy;

# ABSTRACT: a wrapper around casperjs to pass test configurations as json files
use strict;
use warnings;
use Moo;
use MooX::Options;
use IPC::Run qw/run new_chunker/;
use File::Which;
use IO::All;
use JSON;
use DDP;
use Carp;
use Try::Tiny;

option 'test' => (
    is       => 'rw',
    required => 1,
    format   => 's@',
    doc =>
      'Test option: one ore more json file(s) containing the casperjs tests to perform'
);

option 'casper_path' => (
    is        => 'rw',
    format    => 's',
    doc       => 'Path to casperjs, if not standard',
    predicate => 'has_casper_path',
);

has 'tests' => ( is => 'lazy', );

has 'buffer_return' => ( is => 'rw', default => sub {''});

has 'silent_run' => (is => 'rw', default => sub { 0 });

sub _build_tests {
    my $self = shift;
    my $ret  = {};
    foreach my $file ( @{ $self->test } ) {
        if ( io($file)->exists ) {
            my $content = io($file)->slurp;
            try {
                $ret->{$file} = decode_json($content);
            }
            catch {
                carp "'$file' is not valid: $_";
            };
        }
        else {
            carp "'$file' does not exist";
        }
    }
    return $ret;
}

sub run_casper {
    my $self = shift;
    my $full_path;
    $self->buffer_return('') if ($self->buffer_return);
    if ( $self->has_casper_path ) {
        if ( -f $self->casper_path and -x $self->casper_path ) {
            $full_path = $self->casper_path;
        }
        else {
            croak sprintf(
                q{'%s' is not an executable file},
                $self->casper_path
            );
        }
    }
    else {
        $full_path = which('casperjs');
    }
    $self->silent_run (shift @_);
    foreach my $test ( keys %{ $self->tests } ) {
        my $param_spec = $self->transform_arg_spec( $self->tests->{$test} );
        unshift @{ $param_spec->{cmd} }, $full_path;
        push @{ $param_spec->{cmd} }, "test", @{ $param_spec->{paths} };
        print "\n\n\n";
        print "="x10;
        print "> Running test from file $test... \n\n\n";
        run  $param_spec->{cmd}, '>', new_chunker("\n"),$self->lines_handler;
    }

    if ($self->silent_run) {
        return $self->buffer_return;
    }
    else {
        return;
    }
}

sub lines_handler { 
    my ($self,$in_ref,$out_ref) = @_;
    return sub { 
        my ($out) = @_;
        if ($out) { 
            if ($self->silent_run) { 
                $self->buffer_return($self->buffer_return.$out);
            }
            else { 
                print $out;
            }
        }
    }
}

sub transform_arg_spec {
    my $self       = shift;
    my $ref_params = shift;
    my $ret        = {};
    my %params     = %{$ref_params};
    $ret->{paths} = delete $params{paths};
    while ( my ( $k, $v ) = each %params ) {
        if ( ref($v) eq 'ARRAY' ) {
            $v = join( ',', @{$v} );
        }
        else {
            $v = "true"  if ( $v eq '1' );
            $v = "false" if ( $v eq '0' );
        }
        push @{ $ret->{cmd} }, "--$k=$v";
    }
    return $ret;
}



1;

__END__
=pod

=head1 NAME

App::Duppy - a wrapper around casperjs to pass test configurations as json files

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  # will launch casperjs with the options mentionned in the file. See in
  # the fixture directory for an example 
  duppy --test mytestplan.json --test myothertestplan.json 

=head1 DESCRIPTION 

The original idea came from a discussion I had with Nicolas Perriault. I was searching a way to organise my casperjs tests, 
and he came out with this suggestion. 

So I decided to write a little wrapper around casperjs that would be able to launch tests using the format he suggested. 

This script is dead simple: given a json file, it builds out a valid list of parameters that is passed to casperjs.
It then displays the output returned by casperjs.

=head2 JSON File syntax 

The JSON file you use to wrap up your tests consists in valid casperjs command line options, excepted for the path argument, 
which will resolve to the path where your test files are. 

  {
    "auto-exit": false,
    "concise": false,
    "fail-fast": false,
    "includes": ["t/fixtures/inc.js"],
    "log-level": "debug",
    "no-colors": false,
    "paths": ["t/fixtures/main.js", "t/fixtures/main2.js"],
    "post": ["t/fixtures/post.js"],
    "pre": ["t/fixtures/pre.js"],
    "verbose": true,
    "xunit": "results.xml"
  }

  # this will resolve to the following : 
  # casperjs --auto-exit=false --concise=false --fail-fast=false
  # --includes='t/fixtures/inc.js' --log-level='debug' --no-colors=false
  # --post='t/fixtures/post.js' --pre='t/fixtures/pre.js' --verbose=true
  # --xunit='results.xml' test t/fixtures/main.js t/fixtures/main2.js

Note that I assumed that you will always put valid parameters inside a JSON file, so there is no control on that. 

=head1 AUTHORS

=over 4

=item *

Emmanuel "BHS_error" Peroumalnaik

=item *

Fabrice "pokki" Gabolde

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by E. Peroumalnaik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

