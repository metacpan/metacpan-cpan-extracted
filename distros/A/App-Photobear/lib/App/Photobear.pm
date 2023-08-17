#ABSTRACT: Photobear API client
package App::Photobear;
use v5.18;
use warnings;
use Carp;
use HTTP::Tiny;
use Data::Dumper;
use JSON::PP;

# Define version
our $VERSION = '0.1.2';

# Define constants
our $PHOTOBEAR_URL = 'https://photobear.io/api/public/submit-photo';
our @MODES = split / /, "background_removal vectorization super_resolution compress";
our $TESTMODE = $ENV{"PHOTOBEAR_TEST"} || 0;

# Export MODES
use Exporter qw(import);
our @EXPORT_OK = qw(loadconfig saveconfig url_exists curl photobear url_type @MODES);
our $TEST_ANSWER = q({"status":"success","data":{"result_url":"https://res.cloudinary.com/dy4s1umzd/image/upload/e_vectorize:colors:20:detail:0.7:corners:20/v1688570702/svg_inp/aia14r/core-people.svg"}});

sub loadconfig {
    my $filename = shift;
    if (! -e "$filename") {
        return {};
    }
    open my $fh, '<', $filename or Carp::croak "Can't open $filename: $!";
    my $config = {};
    while (my $line = readline($fh)) {
        chomp $line;
        next if $line =~ /^[#[]/;
        my ($key, $value) = split /=/, $line;
        $config->{"$key"} = $value;
    }
    return $config;
}

sub writeconfig {
    my ($filename, $config) = @_;
    open my $fh, '>', $filename or Carp::croak "Can't open $filename: $!";
    say $fh '[photobear]';
    foreach my $key (keys %$config) {
        print $fh "$key=$config->{$key}\n";
    }
}

sub url_exists {
    my ($url) = @_;

    # Create an HTTP::Tiny object
    my $http = HTTP::Tiny->new;

    # Send a HEAD request to check the URL
    my $response = $http->head($url);
    
    # If the response status is success (2xx), the URL exists
    if ($response->{success}) {
        return 1;
    } elsif ($response->{status} == 599) {
        # Try anothe method: SSLeay 1.49 or higher required
        
        eval {
            require LWP::UserAgent;
            my $ua = LWP::UserAgent->new;
            $ua->ssl_opts(verify_hostname => 0);  # Disable SSL verification (optional)
            my $response = $ua->get($url);
            
            if ($response->is_success) {
                return 1;
            } else {
                return 0;
            }
        };
        if ($@) {
            my $cmd = qq(curl --silent -L -I $url);
            my @output = `$cmd`;
            for my $line (@output) {
                chomp $line;
                if ($line =~ /^HTTP/ and $line =~ /200/) {
                    return 1;
                }
            }
        }

    } else {
        return 0;
    }
}

sub url_type {
    my $url = shift;
    my $cmd = qq(curl --silent -L -I $url);
    if ($? == -1) {
        Carp::croak("[url_type] ", "Failed to execute: $!\n");
    } elsif ($? & 127) {
        Carp::croak("[url_type] ", sprintf("Child died with signal %d, %s coredump\n"),
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    } elsif ($? >> 8) {
        Carp::croak("[url_type] ", sprintf("Child exited with value %d\n", $? >> 8));
    }
    my @output = `$cmd`;
    for my $line (@output) {
        chomp $line;
        if ($line =~ /^content-type/i) {
            # Strip color codes
            $line =~ s/\e\[[\d;]*[a-zA-Z]//g;
            my ($type) = $line =~ /Content-Type: (.*)/i;
            return $type;
        }
    }
    return undef;
}

sub curl {
    my ($url) = @_;
    

    eval {
        require LWP::UserAgent;
        
        # Create a UserAgent object
        my $ua = LWP::UserAgent->new;
        $ua->ssl_opts(verify_hostname => 0);  # Disable SSL verification (optional)
        
        # Send the initial GET request
        my $response = $ua->get($url);
        
        # Follow redirects if any
        while ($response->is_redirect) {
            my $redirect_url = $response->header('Location');
            $response = $ua->get($redirect_url);
        }
        
        return $response->decoded_content;
    };
    
    if ($@) {
        # Fallback to system curl command
        eval {
            my $output = `curl --silent -L $url`;
            return $output;
        };
        if ($@) {
            die "Can't get content of $url: $@";
        }
    }
}

sub photobear {
    my ($api_key, $mode, $url) = @_;

    # If $mode is not in $MODES, then die
    if (! grep { $_ eq $mode } @MODES) {
        Carp::croak("Invalid mode: $mode (must be one of @MODES)");
    }

    # If no API key, then die
    if (! $api_key or length($api_key) == 0) {
        Carp::croak "No API key provided";
    }
    my $cmd = qq(curl --location --silent --request POST '$PHOTOBEAR_URL' \
        --header 'x-api-key: $api_key' \
        --header 'Content-Type: application/json' \
        --data-raw '{
            "photo_url":"$url", 
            "mode":"$mode"
        }');
    $cmd =~ s/\n//g;
    
    if ($ENV{'DEBUG'}) {
        say STDERR "[DEBUG] $cmd";
    }

    my $output = $ENV{'DEBUG'} ? $TEST_ANSWER : `$cmd`;
    if ($? == -1) {
        Carp::croak("[photobear]", "Failed to execute: $!\n");
    } elsif ($? & 127) {
        Carp::croak("[photobear]", sprintf("Child died with signal %d, %s coredump\n"),
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    } elsif ($? >> 8) {
        Carp::croak("[photobear]", sprintf("Child exited with value %d\n", $? >> 8));
    }
    
    my $decoded_content = decode_json($output);
    return $decoded_content;

}

sub download {
    my ($url, $dest) = @_;
    # Use curl
    my $cmd = qq(curl  -L -o "$dest" "$url");#
    
    if ($TESTMODE) {
        return 1;
    }
    my $output = `$cmd`;
    if ($? == -1) {
        Carp::croak("[download] ", "Failed to execute: $!\n");
    } elsif ($? & 127) {
        Carp::croak("[download] ", sprintf("Child died with signal %d, %s coredump\n"),
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    } elsif ($? >> 8) {
        Carp::croak("[download] ", sprintf("Child exited with value %d\n", $? >> 8));
    } elsif ($? == 0) {
        return 1;
    } else {
        return 0;
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Photobear - Photobear API client

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

  use App::Photobear;
  
  # Load configuration from file
  my $config = App::Photobear::loadconfig($config_file);
  
  # Save configuration to file
  App::Photobear::saveconfig($config_file, $config);
  
  # Check if a URL exists
  my $url_exists = App::Photobear::url_exists($url);

  # Get the content of a URL
  my $content = App::Photobear::curl($url);

  # Perform Photobear API request
  my $result = App::Photobear::photobear($api_key, $mode, $url);

  # Download a file from a URL
  my $success = App::Photobear::download($url, $destination);

=head1 DESCRIPTION

App::Photobear is a Perl module that provides a client for the Photobear API. 
It includes functions to load and save configuration, check if a URL exists, perform API requests, and download files from URLs.

This script is meant to be used as a command-line tool, check L<photobear> for more information.

=head1 FUNCTIONS

=head2 loadconfig($filename)

Load configuration from the specified file. Returns a hash reference containing the configuration.

=head2 saveconfig($filename, $config)

Save the configuration to the specified file.

=head2 url_exists($url)

Check if the specified URL exists. Returns a boolean value indicating whether the URL exists or not.

=head2 curl($url)

Retrieve the content of the specified URL. Returns the content as a string.

=head2 photobear($api_key, $mode, $url)

Perform a request to the Photobear API with the given API key, mode, and URL. Returns the result as a hash reference.

=head2 download($url, $destination)

Download a file from the specified URL to the given destination path. Returns a boolean value indicating the success of the download operation.

=head1 VARIABLES

=head2 C<@MODES>

An array containing the supported modes for the Photobear API requests.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
