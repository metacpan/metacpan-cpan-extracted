#!/usr/bin/perl -c

package App::soapcli;

=head1 NAME

App::soapcli - SOAP client for CLI with YAML and JSON input and output

=head1 SYNOPSIS

  my $app = App::soapcli->new(argv => [qw( calculator.yml calculator.url )]);
  $app->run;

=head1 DESCRIPTION

This is core module for L<soapcli> utility.

=cut


use v5.10;

use strict;
use warnings;

our $VERSION = '0.0300';

use Log::Report 'soapcli', syntax => 'SHORT';

use XML::LibXML;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP12;
use XML::Compile::Transport::SOAPHTTP;

use Perl6::Slurp              qw(slurp);
use Getopt::Long::Descriptive ();
use HTTP::Tiny                ();
use YAML::Syck                ();
use YAML::XS                  ();
use JSON::PP                  ();


=head1 ATTRIBUTES

=over

=item argv : ArrayRef

Arguments list with options for the application.

=back

=head1 METHODS

=over

=item new (I<%args>)

The default constructor.

=cut

sub new {
    my ($class, %args) = @_;
    return bless {
        argv       => [],
        extra_argv => [],
        %args,
    } => $class;
};


=item new_with_options (%args)

The constructor which initializes the object based on C<@ARGV> variable or
based on array reference if I<argv> option is set.

=cut

sub new_with_options {
    my ($class, %args) = @_;

    my $argv = delete $args{argv};
    local @ARGV = $argv ? @$argv : @ARGV;

    my ($opts, $usage) = Getopt::Long::Descriptive::describe_options(
        "$0 %o data.yml [http://schema | schema.url] [endpoint#port] [operation]",
        [ 'verbose|v',          'verbose mode with messages trace', ],
        [ 'dump-xml-request|x', 'dump request as XML document', ],
        [ 'explain|e',          'explain webservice as Perl code', ],
        [ 'help|h',             'print usage message and exit', ],
        [ 'json|j',             'output result as JSON document', ],
        [ 'yaml|y',             'output result as YAML document', ],
    );

    die $usage->text if $opts->help or @ARGV < 1;

    return $class->new(extra_argv => [@ARGV], %$opts);
};


=item run ()

Run the main job

=back

=cut

sub run {
    my ($self) = @_;

    my $arg_request = $self->{extra_argv}->[0];
    my $servicename = do {
        if ($arg_request =~ /^{/ or $arg_request eq '-') {
            '';
        }
        else {
            my $arg = $arg_request;
            $arg =~ s/\.(url|yml|wsdl)$//;
            $arg;
        };
    };


    my $arg_wsdl = $self->{extra_argv}->[1];

    my $wsdlsrc = do {
        if (defined $self->{extra_argv}->[1]) {
            $self->{extra_argv}->[1];
        }
        else {
            my $name = $servicename;
            LOOP: {
                do {
                    if (-f "$name.wsdl") {
                        $name .= '.wsdl';
                        last;
                    }
                    elsif (-f "$name.url") {
                        $name .= '.url';
                        last;
                    };
                    $name =~ s/[._-][^._-]*$//;
                }
                while ($name =~ /[._-]/);
                $name .= '.wsdl';
            };
            $name;
        };
    };

    my $wsdldata = do {
        if ($wsdlsrc =~ /\.url$/ or $wsdlsrc =~ m{://}) {
            my $url = $wsdlsrc =~ m{://} ? $wsdlsrc : slurp($wsdlsrc, {chomp=>1});
            chomp $url;
            HTTP::Tiny->new->get($url)->{content};
        }
        elsif ($wsdlsrc =~ /\.wsdl$/ and -f $wsdlsrc) {
            slurp($wsdlsrc);
        };
    } or die "Can not read WSDL data from `$wsdlsrc': $!\n";


    my $arg_endpoint = $self->{extra_argv}->[2];


    my $request = do {
        if ($arg_request =~ /^{/) {
            $arg_request =~ s/\n//g;
            JSON::PP->new->utf8->relaxed->allow_barekey->decode($arg_request);
        }
        elsif ($arg_request eq '-') {
            YAML::Syck::LoadFile(\*STDIN);
        }
        elsif ($arg_request =~ /\.json$/) {
            my $content = slurp($arg_request);
            $content =~ s/\n//g;
            JSON::PP->new->utf8->relaxed->allow_barekey->decode($content);
        }
        else {
            YAML::Syck::LoadFile($arg_request);
        }
    };

    die "Wrong request format from `$arg_request'\n" unless ref $request||'' eq 'HASH';


    my $arg_operation = $self->{extra_argv}->[3];

    my $wsdldom = XML::LibXML->load_xml(string => $wsdldata);
    my $imports = eval { $wsdldom->find('/wsdl:definitions/wsdl:types/xsd:schema/xsd:import') };

    my @schemas = eval { map { $_->getAttribute('schemaLocation') } $imports->get_nodelist };

    my $wsdl = XML::Compile::WSDL11->new;

    $wsdl->importDefinitions(\@schemas);
    $wsdl->addWSDL($wsdldom);

    $wsdl->addHook(type => '{http://www.w3.org/2001/XMLSchema}hexBinary', before => sub {
        my ($doc, $value, $path) = @_;
        defined $value or return;
        $value =~ m/^[0-9a-fA-F]+$/ or error __x"{path} contains illegal characters", path => $path;
        return pack 'H*', $value;
    });

    my $port = do {
        if (defined $arg_endpoint and $arg_endpoint =~ /#(.*)$/) {
            $1;
        }
        else {
            undef;
        }
    };

    my $endpoint = do {
        if (defined $arg_endpoint and $arg_endpoint !~ /^#/) {
            my $url = $arg_endpoint =~ m{://} ? $arg_endpoint : slurp($arg_endpoint, {chomp=>1});
            chomp $url;
            $url =~ s/^(.*)#(.*)$/$1/;
            $url;
        }
        else {
            $wsdl->endPoint(
                defined $port ? ( port => $port ) : (),
            );
        }
    };


    my $operation = do {
        if (defined $arg_operation) {
            $arg_operation
        }
        else {
            my $o = (keys %$request)[0];
            $request = $request->{$o};
            $o;
        }
    };


    my $http = XML::Compile::Transport::SOAPHTTP->new(
        address => $endpoint,
    );

    $http->userAgent->agent("soapcli/$VERSION");
    $http->userAgent->env_proxy;

    my $action = eval {
        $wsdl->operation(
            $operation,
            defined $port ? ( port => $port ) : (),
        )->soapAction()
    };

    my $transport = $http->compileClient(
        action => $action,
    );


    $wsdl->compileCalls(
        sloppy_floats   => 1,
        sloppy_integers => 1,
        transport       => $transport,
        defined $port ? ( port => $port ) : (),
        $self->{dump_xml_request} ? ( transport => sub { print $_[0]->toString(1); goto EXIT } ) : (),
    );

    if ($self->{explain}) {
        die $wsdl->explain($operation, PERL => 'INPUT');
    }

    my ($response, $trace) = $wsdl->call($operation, $request);

    my $json = JSON::PP->new->utf8->allow_nonref;

    if ($self->{verbose}) {
        say "---";
        $trace->printRequest;
        if ($self->{yaml}) {
            say YAML::XS::Dump({ Data => { $operation => $request } });
        } else {
            say "---";
            say $json->encode({ $operation => $request });
        }
        say "---";
        $trace->printResponse;
        if ($self->{yaml}) {
            say YAML::XS::Dump({ Data => $response });
        } else {
            say "---";
            say $json->encode($response);
        }
    }
    else {
        if ($self->{yaml}) {
            print YAML::XS::Dump($response);
        } else {
            say $json->encode($response);
        }
    }

    EXIT:
    return 1;
};


1;


=head1 SEE ALSO

L<http://github.com/dex4er/soapcli>, L<soapcli>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2011-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
