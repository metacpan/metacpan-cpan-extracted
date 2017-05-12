package App::Presto::Command::HTTP;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::Command::HTTP::VERSION = '0.010';
# ABSTRACT: HTTP-related commands

use strict;
use warnings;
use Moo;
with 'App::Presto::InstallableCommand', 'App::Presto::CommandHasHelp','App::Presto::WithPrettyPrinter';

my %URL_HISTORY;

sub urls_for {
    my $method = shift;
    return $URL_HISTORY{$method} || [];
}
sub add_url {
    my($method, $url) = @_;
    push(@{ $URL_HISTORY{$method} ||= []}, $url);
}

sub install {
    my $self = shift;
    my $client = $self->client;
    $self->term->add_commands(
        {
            form => {
                desc => "helper for formatting URL-encoded strings",
                minargs => 1,
                args => "some-key=some-value",
                proc => sub {
                    my $uri = $client->_append_query_params( '', @_ );
                    $uri =~ s{^\?}{};
                    print "$uri\n";
                  }
            },
            map {
                my $m = $_;
                $m => {
                    desc => "perform a $m HTTP action",
                    args => [ sub { urls_for($m) } ],
                    proc => $self->_mk_proc_for($m)
                  }
              } qw(GET POST PUT DELETE HEAD)
        }
    );
}

sub _mk_proc_for {
    my $self = shift;
    my $method = shift;
    my $client = $self->client;
    return sub {
        add_url($method => $_[0]);
        if($method =~ m/^P/){
            warn " * no content-type header currently set\n" unless $client->get_header('Content-Type');
        }
        my $out;
        if(($out) = $_[-1] =~ /^>(.+)/){
            pop @_;
        }
        $client->$method(@_);
        $self->handle_response($client, $out);
    }
}

sub handle_response {
    my $self = shift;
    my $client = shift;
    my $output_to = shift;
    my $response = $client->response;
    my $config = $self->config;
    if ( $config->get('verbose') ) {
        _dump_request_response( $response->request, $response );
    }
    if ( $client->has_response_content ) {
        if($output_to){
            warn " * sending output to $output_to\n";
            open(my $out_fh, '>', $output_to) or die "unable to open $output_to for writing: $!";
            print $out_fh $response->content;
            close $out_fh or die "unable to close $output_to after writing: $!";
        } elsif ( $config->get('deserialize_response') ) {
            my $data = $client->response_data;
            print ref $data ? $self->pretty_print($data) : "$data\n";
        } elsif ( !$config->get('verbose') ) {    # don't print just the content a second time...
            print readable_content($response);
            print "\n";
        }
    } elsif ( !$config->get('verbose') ) {
        print $response->as_string, "\n";
    }
}

sub _dump_request_response {
    my($request,$response) = @_;
    print "----- REQUEST -----\n";
    print $request->dump;
    print "----- RESPONSE -----\n";
    print $response->dump;
    print "----- END -----\n";
}

sub readable_content {
    my $message = shift;
    return is_human_readable($message) ? $message->decoded_content : sprintf('[ %d bytes of binary data ]', $message->content_length || length($message->decoded_content));
}

sub is_human_readable {
    my $message = shift;
    return $message->content_type =~ m{\b(?:xml|^text|application/json|application/x-www-form-urlencoded)\b} || do {
        my $content = substr($message->decoded_content, 0, 1000);
        my $non_printable =()= $content =~ m/([^[:print:]])/g;
        $content eq '' || ($non_printable / length($content)) > 0.3;
    };
}

sub help_categories {
    return {
        desc => 'Various HTTP verb commands',
        cmds => [qw(GET POST HEAD PUT DELETE)],
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::Command::HTTP - HTTP-related commands

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
