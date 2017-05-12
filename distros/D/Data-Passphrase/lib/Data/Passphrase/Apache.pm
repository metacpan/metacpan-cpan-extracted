# $Id: Apache.pm,v 1.5 2007/08/14 15:45:51 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Apache; {

    use Readonly;

    Readonly our $CONFIG_DEBUG       => 'PassphraseDebug';
    Readonly our $CONFIG_LOCATION    => 'PassphraseLocation';
    Readonly our $CONFIG_RULES_FILE  => 'PassphraseRulesFile';
    Readonly our $CONFIG_WSDL_NS     => 'PassphraseWsdlNamespace';
    Readonly my  $ERROR_PREFIX       => 'Data::Passphrase';
    Readonly my  $POST_MAX           => 1024;

    Readonly my %URI_MAP => (
        ''      => \&dispatch_http,
        form    => \&dispatch_form,
        http    => \&dispatch_http,
        soap    => \&dispatch_soap,
        wsdl    => \&dispatch_wsdl,
    );

    use Data::Passphrase qw(validate_passphrase);
    use Data::Passphrase::Ruleset;
    use HTML::Entities;
    use HTTP::Status;
    use LWP::UserAgent;
    use mod_perl;

    # load mod_perl modules based on version
    my $IS_MOD_PERL_2;
    BEGIN {
        $IS_MOD_PERL_2 = exists $ENV{MOD_PERL_API_VERSION}
                             && $ENV{MOD_PERL_API_VERSION} >= 2;

        if ($IS_MOD_PERL_2) {
            require Apache2::RequestRec;
            require Apache2::RequestUtil;
            require Apache2::Response;

            if ($ENV{MOD_PERL}) {
                require Apache2::Request;
            }
        }
        else {
            require Apache;

            if ($ENV{MOD_PERL}) {
                require Apache::Request;
            }
        }
    }

    # export utility routines and configuration directive names
    BEGIN {
        our %EXPORT_TAGS = (
            config => [qw(
                $CONFIG_DEBUG    $CONFIG_LOCATION  $CONFIG_RULES_FILE
                $CONFIG_WSDL_NS
            )],
        );
        $EXPORT_TAGS{all} = $EXPORT_TAGS{config};
        Exporter::export_ok_tags('all');
    }

    # handle all requests and dispatch to other functions based on path
    sub handler {
        my ($r) = @_;

        # object attributes to pass through the dispatch routine
        my %apv;

        # get configuration values
        my $config     = $r->dir_config();
        my $debug      = $config->get($CONFIG_DEBUG);
        my $rules_file = $config->get($CONFIG_RULES_FILE);

        # get ruleset
        if (defined $rules_file) {
            $apv{ruleset}
                = Data::Passphrase::Ruleset->new(file => $rules_file);
        }

        # extract some commonly used query parameters
        my $apreq_class
            = $IS_MOD_PERL_2 ? 'Apache2::Request' : 'Apache::Request';
        my $apreq = $apreq_class->new(
            $r,
            DISABLE_UPLOADS => 1,
            POST_MAX        => $POST_MAX,
        );
        $apv{passphrase} = $apreq->param('passphrase');
        $apv{username  } = $apreq->param('username'  ) || $r->user();

        # decide what to provide based on path info
        my $status = RC_NOT_FOUND;
        (my $path = $r->path_info()) =~ s{^/}{};
        $debug and warn "path info: $path";
        if (exists $URI_MAP{$path}) {
            $status = eval {
                $URI_MAP{$path}->({
                    apv_ref => \%apv,
                    apreq   => $apreq,
                    config  => $config,
                    debug   => $debug,
                    r       => $r,
                });
            };
        }

        # unknown path specified
        else {
            return RC_NOT_FOUND;
        }

        # error calling dispatch method
        if ($@) {
            warn;
            return RC_INTERNAL_SERVER_ERROR;
        }

        return $status;
    }

    sub dispatch_http {
        my ($arg_ref) = @_;

        my $response = validate_passphrase {
            %{$arg_ref->{apv_ref}},
            debug => $arg_ref->{debug},
        };

        # set the response code, message, and a custom document with the score
        my $code    = $response->{code   };
        my $message = $response->{message};
        my $score   = $response->{score  };
        my $r = $arg_ref->{r};
        $r->status_line("$code $message");

        # send header
        $r->content_type("text/plain");

        # send JSON document with score and other results
        $r->send_http_header();
        $r->print(<<"END");
{
    "code":    $code,
    "message": "$message",
    "score":   $score
}
END

        return 0;
    }

    # trivial form handler
    sub dispatch_form {
        my ($arg_ref) = @_;

        # unpack arguments
        my $debug = $arg_ref->{debug};
        my $passphrase = $arg_ref->{apv_ref}{passphrase};
        my $username   = $arg_ref->{apv_ref}{username  };

        # if a passphrase is supplied, validate it
        my ($code, $message, $score);
        if (defined $passphrase) {
            $debug and warn 'validating supplied passphrase';

            # special case for localhost: call subroutine directly
            my $location = $arg_ref->{config}->get($CONFIG_LOCATION);
            if (!defined $location || $location eq 'localhost') {
                my $response = validate_passphrase {
                    %{$arg_ref->{apv_ref}},
                    debug => $arg_ref->{debug},
                };

                $code    = $response->{code   };
                $message = $response->{message};
                $score   = $response->{score  };
            }

            # if location is remote, do an HTTP request
            else {
                $debug and warn "making request to $location";
                my $user_agent = LWP::UserAgent->new();
                my $response   = $user_agent->post(
                    $location,
                    passphrase => $passphrase,
                    username   => $username  ,
                );
                $code    = $response->code   ();
                $message = $response->message();
                $score   = $response->score  ();
            }

            $debug and warn "response: $code $message, score: $score\%";
        }

        $debug and warn 'printing form';

        # print header
        my $r = $arg_ref->{r};
        $r->content_type("text/html");
        if (!$IS_MOD_PERL_2) {
            $r->send_http_header();
        }
        print <<"END";
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head><title>Validate Passphrase</title></head>
<body>
END

        # print validation message if validation occurred
        if (defined $message) {
            print '<p><strong>Passphrase ', encode_entities($message),
                "score: $score\%</strong></p>";
        }

        # print footer
        print <<"END";
<form method="post">
<input name="passphrase" size="127" type="password" />
<input type="submit" value="Check Strength" />
</form>
</body>
</html>
END

        return 0;
    }

    sub dispatch_soap {
        my ($arg_ref) = @_;

        # only allow passphrase & username attributes to be accessed from soap
        my $apreq = $arg_ref->{apreq};
        my $table = $apreq->param();
        $table->clear();
        if (exists $arg_ref->{passphrase}) {
            $table->set(passphrase => $arg_ref->{passphrase});
        }
        if (exists $arg_ref->{username}) {
            $table->set(username => $arg_ref->{username});
        }

        require SOAP::Transport::HTTP;
        return SOAP::Transport::HTTP::Apache
            ->dispatch_to(__PACKAGE__ . '::validate_passphrase')
            ->handle(@_);
    }

    sub dispatch_wsdl {
        my ($arg_ref) = @_;

        # unpack arguments
        my $config = $arg_ref->{config};

        # determine WSDL namespace
        my $wsdl_namespace = $config->get($CONFIG_WSDL_NS);
        if (!defined $wsdl_namespace) {
            (my $path = __PACKAGE__) =~ s{::}{/}g;
            my $r = $arg_ref->{r};
            my $hostname = $r->hostname();
            (my $uri = $r->uri()) =~ s{/$}{};
            $wsdl_namespace = "http://$hostname$uri/$path";
        }

        require Pod::WSDL;
        $arg_ref->{r}->content_type("text/xml");
        print Pod::WSDL->new(
            source   => __PACKAGE__,
            location => $wsdl_namespace,
        )->WSDL;

        return 0;
    }
}

1;
__END__

=head1 NAME

Data::Passphrase::Apache - HTTP service for checking passphrase strength

=head1 SYNOPSIS

In F<httpd.conf>:

    <Location />
        Require valid-user
        SSLRequireSSL
        
        PerlHandler +Data::Passphrase::Apache
        SetHandler  perl-script
        
        # turn on debugging (default: 0)
        PerlSetVar PassphraseDebug 1
        
        # use a remote service for form_handler (default: localhost)
        PerlSetVar PassphraseLocation \
                   "https://example.com/passphrase/validate"
        
        # set location of rules file (default: /etc/passphrase_rules)
        PerlSetVar PassphraseRules \
                   /usr/local/etc/passphrase_rules
    </Location>

HTTP client:

    use constant LOCATION => 'https://itso.iu.edu/validate/http';
    
    use LWP::UserAgent;
    
    my $username = $ENV{LOGNAME};
    for (;;) {
        print 'Passphrase (clear): ';
        chomp (my $passphrase = <STDIN>);

        my $user_agent = LWP::UserAgent->new();
        my $response   = $user_agent->post(LOCATION, {
            passphrase => $passphrase,
            username   => $username,
        });
        $code          = $response->code   ();
        $message       = $response->message();
        $score         = $response->score  ();
    
        print "$code $message, score: $score\%\n";
    }

SOAP client:

    use SOAP::Lite +autodispatch =>
        proxy    => 'http://itso.iu.edu/validate/soap',
        uri      => 'http://passphrase.iu.edu/Data/Passphrase';
    
    my $username = $ENV{LOGNAME};
    for (;;) {
        print 'Passphrase (clear): ';
        chomp (my $passphrase = <STDIN>);
    
        my $response = SOAP::Lite
            ->uri('http://passphrase.iu.edu/Data/Passphrase')
            ->proxy('http://itso.iu.edu/validate/soap')
            ->validate_passphrase({
                username   => $username,
                passphrase => $passphrase,
            })->result()
            or die $!;
        print "$result->{code} $result->{message}, score: $result->{score}\%\n";
    }


=head1 DESCRIPTION

This mod_perl module provides HTTP and SOAP interfaces to
L<Data::Passphrase|Data::Passphrase>.  A trivial form handler is also
included, mostly as an example.  By default, the various interfaces
are accessible by the following URIs:

  Interface     URI
  ---------     ---
  HTTP          https://example.com/http
  SOAP          https://example.com/soap
  WSDL          https://example.com/wsdl
  form example  https://example.com/form

=head2 HTTP Interface

An application or user may submit the passphrase to be checked via the
query parameter C<passphrase>.  The module also supports a C<username>
parameter, which defaults to $r->user().  Sites may wish to configure
rules to check passphrases based on user-related data, so the
C<username> parameter may be useful for testing.

The response consists of an HTTP response code and status message in
the header, and a JSON representation of the code, message, and score
in the body.  If a passphrase is deemed to weak via a certain rule,
the error code associated with that rule is returned.  Usually, these
error codes are in the 4xx range.  If a passphrase passes all rules,
200 is returned.

This module supports GET and POST request methods, but POST is usually
appropriate to avoid passphrases being recorded in server logs.
RESTful URLs are not used for the same reason.

=head2 SOAP Interface

SOAP semantics are provided by L<SOAP::Lite|SOAP::Lite> with a
corresponding WSDL provided by L<Pod::WSDL|Pod::WSDL>.  This interface
exposes only the
L<validate_passphrase()|Data::Passphrase/validate_passphrase()>
procedural method; there is no object-oriented RPC functionality.

=head2 Form Example

The form handler is just a trivial example for use in testing or as a
starting point.

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3), Pod::WSDL(3), SOAP::Lite(3)
