package App::cloudconvert;
use strict;

use 5.008_005;
our $VERSION = '0.01';

use LWP;
use HTTP::Request::Common qw(POST);

sub new {
    my ($class, %config) = @_;
    bless \%config, $class;
}

sub convert {
    my ($self, $inputfile, $outputfile) = @_;

    my $ua = LWP::UserAgent->new( 
        timeout => $self->{wait},
        $self->{agent} ? (agent => $self->{agent}) : (),
    ); # TODO: check SSL ?

    my %params = (
        inputformat => $self->{from},
        outputformat => $self->{to},
        apikey => $self->{apikey},
        input => "upload",
        download => "inline",
        file => [ $inputfile ]
    );

    if ($self->{dry}) {
        foreach (keys %params) {
            print "$_: ".(ref $params{$_} ? $params{$_}->[0] : $params{$_}) . "\n"
        }
        print "inputfile: $inputfile\n";
        print "outputfile: $outputfile\n";
        return 0;
    }

    my $response = $ua->request(POST $self->{url},
        Content_Type => 'multipart/form-data',
        Content => \%params
    );
    
    if ($response->code == '303') {
        $response = $ua->mirror( $response->header('location'), $outputfile );
    } else { 
        my $error = "conversion failed";
        if (!$response->is_success) {
            if ($response->header('content-type') eq 'application/json') {
                my $content = from_json($response->decoded_content);
                $error = $content->{error};
            }
        }
        say STDERR $response->code, ": ", $error;
        return 1;
    }

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::cloudconvert - Convert files via cloudconvert.org

=head1 SYNOPSIS

  use App::cloudconvert;
  my $app = App::cloudconvert->new( from => "gif", to => "png" );
  $app->convert( "sample.gif", "sample.png" );

=head1 DESCRIPTION

See the command line client L<cloudconvert> for usage.

=head1 AUTHOR

Jakob Voß E<lt>jakob.voss@gbv.deE<gt>

=head1 COPYRIGHT

Copyright 2014- Jakob Voß

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
