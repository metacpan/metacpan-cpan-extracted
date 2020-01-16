# ABSTRACT: Internal module with the API specification
package Arango::Tango::API;
$Arango::Tango::API::VERSION = '0.011';
#use Arango::Tango::Database;
#use Arango::Tango::Collection;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Clone 'clone';
use MIME::Base64 3.11 'encode_base64url';
use URI::Encode qw(uri_encode);
use JSON::Schema::Fit 0.07;

use Sub::Install qw(install_sub);
use Sub::Name    qw(subname);

sub _install_methods($$) {
    my ($package, $methods) = @_;
    for my $method (keys %$methods) {
        my $value = $methods->{$method};
        install_sub {
            into => $package,
              as => $method,
              code => subname("${package}::$method",
                              sub {
                                  my $self = shift;
                                  my %required = ();
                                  my %optional = ();
                                  if (exists($value->{signature})) {
                                      die sprintf("Arango::Tango | %s | Missing %s", $method, $value->{signature}[scalar(@_)-1]) if scalar(@_) < scalar(grep { !/^\?/ } @{$value->{signature}});
                                      %required = ( map { $_ => shift @_ } grep { !/^\?/ } @{$value->{signature}} );
                                      %optional = ( map {
                                          /^\?(.+)$/ and $a = $1;
                                          ref($_[0]) ? () : ($a => shift @_)
                                      } grep {  /^\?/ } @{$value->{signature}} );
                                      %required = ( %required, %optional );
                                  }
                                  if (exists($value->{inject_properties})) {
                                      foreach my $property (@{$value->{inject_properties}}) {
                                          if (ref($property) eq "HASH") {
                                              die "Property injection without property" unless exists $property->{prop};
                                              die "Property injection without alias"    unless exists $property->{as};
                                              $required{$property->{as}} = $self->{$property->{prop}};
                                          }
                                          else {
                                              $required{$property} = $self->{$property};
                                          }
                                      }
                                  }
                                  die sprintf("Arango::Tango | %s | Odd number of elements on options hash", $method) if scalar(@_) % 2;
                                  my $arango = ref($self) eq "Arango::Tango" ? $self : $self->{arango};
                                  return $arango->__api($method, $value, { @_, %required });
                              }),
                          };
    }
}

my %API = (
    create_document    => { method => 'post',   uri => '{{database}}_api/document/{collection}' },


    list_collections   => { method => 'get',    uri => '{{database}}_api/collection', params => { excludeSystem => { type => 'boolean' } } },
    cursor_next        => { method => 'put',    uri => '{{database}}_api/cursor/{id}'           },
    cursor_delete      => { method => 'delete', uri => '{{database}}_api/cursor/{id}'           },
    accessible_databases => { method =>'get',  uri => '_api/database/user'                   },

    'all_keys' => {
        method => 'put',
        uri    => '{{database}}_api/simple/all-keys',
        params => { type => { type => 'string' }, collection => { type => 'string' } },
    },
    'create_cursor' => {
        method => 'post',
        uri    => '{{database}}_api/cursor',
        params => {
            query       => { type => 'string'  },
            count       => { type => 'boolean' },
            batchSize   => { type => 'integer' },
            cache       => { type => 'boolean' },
            memoryLimit => { type => 'integer' },
            ttl         => { type => 'integer' },
            bindVars => { type => 'object', additionalProperties => 1 },
            options  => { type => 'object', additionalProperties => 0, properties => {
                    failOnWarning               => { type => 'boolean' },
                    profile                     => { type => 'integer', maximum => 2, minimum => 0 }, # 0, 1, 2
                    maxTransactionSize          => { type => 'integer' },
                    stream                      => { type => 'boolean' },
                    skipInaccessibleCollections => { type => 'boolean' },
                    maxWarningCount             => { type => 'integer' },
                    intermediateCommitCount     => { type => 'integer' },
                    satelliteSyncWait           => { type => 'integer' },
                    fullCount                   => { type => 'boolean' },
                    intermediateCommitSize      => { type => 'integer' },
                    'optimizer.rules'           => { type => 'string'  },
                    maxPlans                    => { type => 'integer' },
                 }
            },
        },
      },

      create_user => {
          method => 'post',
          uri => '_api/user',
          params => {
              password => { type => 'string'  },
              active   => { type => 'boolean' },
              user     => { type => 'string'  },
              extra    => { type => 'object', additionalProperties => 1 },
          }
      },
);



sub _check_options {
    my ($params, $properties) = @_;
    my $schema = { type => 'object', additionalProperties => 0, properties => $properties };
    my $prepared_data = JSON::Schema::Fit->new(replace_invalid_values => 1)->get_adjusted($params, $schema);
    return $prepared_data;
}

sub _api {
    my ($self, $action, $params) = @_;

    my $uri = $API{$action}{uri};

    my $params_copy = clone $params;

    $uri =~ s [\{\{database\}\}] [ defined $params->{database} ? "_db/$params->{database}/" : "" ]e;

    $uri =~ s [\{([^}]+)\}] [$params->{$1}]g;

    my $url = "http://" . $self->{host} . ":" . $self->{port} . "/" . $uri;

    my $body = (ref($params) eq "HASH" || ref($params) eq "ARRAY") && exists $params->{body} ? $params->{body} : undef;
    my $opts = ref($params) eq "HASH" ? $params : {};

    $opts = exists($API{$action}{params}) ? _check_options($opts, $API{$action}{params}) : {};

    if ($API{$action}{method} eq 'get' && scalar(keys %$opts)) {
        $url .= "?" . join("&", map { "$_=" . uri_encode($opts->{$_} )} keys %$opts);
    } else {
        if ($body && (ref($body) eq "HASH" || ref($body) eq "ARRAY")) {
            $opts = { content => encode_json $body }
        }
        elsif (defined($body)) { # JSON
            $opts = { content => $body }
        }
        else {
            $opts = { content => encode_json $opts }
        }
    }

#    print STDERR " -- $action | $API{$action}{method} | $url\n\n";
    #print STDERR "\n\nOPTS:\n\n", Dumper($opts);

    my $response = $self->{http}->request(uc $API{$action}{method}, $url, $opts);

    if ($response->{success}) {
        my $ans = decode_json($response->{content});
        if ($ans->{error}) {
            return $ans;
        } elsif (exists($API{$action}{builder})) {
            return $API{$action}{builder}->( $self, %$params_copy );
        } else {
            return $ans;
        }
    }
    else {
#        use Data::Dumper;
 #       print STDERR Dumper($response);
        die "Arango::Tango | ($response->{status}) $response->{reason}";
    }
}


sub __api {
    my ($self, $func, $conf, $params) = @_;

    my ($method, $uri) = @{$conf->{rest}};
    $method = uc $method;

    my $params_copy = clone $params; ## FIXME: decide if this is relevant

    $uri =~ s[\{\{database\}\}]  [ defined $params->{database} ? "_db/$params->{database}/" : "" ]e;
    $uri =~ s[\{([^}]+)\}]  [$params->{$1} // ""]eg;

    my $url = sprintf("http://%s:%d/%s", $self->{host}, $self->{port}, $uri);

    my $body = (ref($params) eq "HASH" || ref($params) eq "ARRAY") && exists $params->{body} ? $params->{body} : undef;
    my $opts = ref($params) eq "HASH" ? $params : {};

    $opts = exists($conf->{schema}) ? _check_options($opts, $conf->{schema}) : {};

    if ($method eq 'GET' && scalar(keys %$opts)) {
        $url .= "?" . join("&", map { "$_=" . uri_encode($opts->{$_} )} keys %$opts);
    } else {
        if ($body && (ref($body) eq "HASH" || ref($body) eq "ARRAY")) {
            $opts = { content => encode_json $body }
        }
        elsif (defined($body)) { # JSON
            $opts = { content => $body }
        }
        else {
            $opts = { content => encode_json $opts }
        }
    }

#use Data::Dumper;
#print STDERR " -- $action | $API{$action}{method} | $url\n";
    #print STDERR "\n\nOPTS:\n\n", Dumper($opts);

    my $response = $self->{http}->request(uc $method, $url, $opts);

    if ($response->{success}) {
        my $ans = decode_json($response->{content});
        if ($ans->{error}) {
            return $ans;
        } elsif (exists($conf->{builder})) {
            return $conf->{builder}->( $self, %$params_copy );
        } else {
            return $ans;
        }
    }
    else {
        die "Arango::Tango | ($response->{status}) $response->{reason}\n    [ $method => $url ]\n";
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::API - Internal module with the API specification

=head1 VERSION

version 0.011

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
