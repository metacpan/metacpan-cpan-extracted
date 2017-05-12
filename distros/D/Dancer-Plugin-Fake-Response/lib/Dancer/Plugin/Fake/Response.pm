package Dancer::Plugin::Fake::Response;

use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::REST;

=head1 NAME

Dancer::Plugin::Fake::Response - The great new Dancer::Plugin::Fake::Response!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

in your Dancer project, use this plugin and register  :

    package MyDancer::Server;

    use Dancer::Plugin::Fake::Response;

    catch_fake_exception();

In your config file :

    plugins:
      Fake::Response:
        GET:
          "/rewrite_fake_route/:id.:format":
            response:
              id: ":id"
              test: "get test"
          "/rewrite_fake_route2/:id.:format":
            response:
              id: 2
              test: "get test 2"
        PUT:
          "/rewrite_fake_route/:id.:format":
            response:
              id: ":id"
              test: "put test"
        POST:
          "/rewrite_fake_route/:format":
            response:
              id: 4
              test: "post test"
        DELETE:
          "/rewrite_fake_route/:id.:format":
            response:
              id: ":id"
              test: "delete test"

For each defined route in Dancer plugin config are catched and return data and code configured.

For example for : GET http://localhost/rewrite_fake_route/12.json
return code : 200
return body : {"id":12,"test":"get test"}

In configuation, if you put parameter name with ':' before, it will return value of parameter send.

new step :
* add possibility to return params set like id : :id
* add possibility to request data store in a file like response_file: file/get_answer.json

=head1 INIT MODULE ROUTE

Each route configured in dancer plugin configuration are declare fakly.

=cut

#get "/rewrite_fake_route/:id.:format" => sub {return halt{value => "KO"};};
foreach my $route (keys %{plugin_setting->{GET}})
{
    get $route => sub {return halt{value => "KO"};};
}

foreach my $route (keys %{plugin_setting->{POST}})
{
    post $route => sub {return halt{value => "KO"};};
}

foreach my $route (keys %{plugin_setting->{PUT}})
{
    put $route => sub {return halt{value => "KO"};};
}

foreach my $route (keys %{plugin_setting->{DELETE}})
{
    del $route => sub {return halt{value => "KO"};};
}

=head1 SUBROUTINES/METHODS

=head2 catch_fake_exception

Before filter for dancer

Catch if route match with configured route to answer fake data.

Codes return are :
  - 200 for GET
  - 201 for POST
  - 202 for PUT
  - 202 for DELETE

=cut

use Data::Dumper;
register 'catch_fake_exception' => sub {
    hook before => sub {
        my $req = request;
        my %req_params = params;
        return if !defined plugin_setting->{$req->method()};
        foreach my $route (keys %{plugin_setting->{$req->method()}})
        {
          if ($route eq $req->{_route_pattern})
          {
            set serializer => uc($req_params{format}) || 'JSON';
            my $response = plugin_setting->{$req->method()}->{$route}->{response};
            foreach my $key (keys %{$response})
            {
                if ( $response->{$key} =~ m/^:[A-Za-z\_\-]+/)
                {
                    my $param_name = $response->{$key};
                    $param_name =~ s/^://;
                    if (defined params->{$param_name})
                    {
                        $response->{$key} = params->{$param_name};
                    }
                }
            }
            return halt(status_ok($response)) if $req->method() eq 'GET'; #code = 200
            return halt(status_created($response)) if $req->method() eq 'POST'; #code = 201
            return halt(status_accepted($response)) if $req->method() eq 'PUT'; #code = 202
            return halt(status_accepted($response)) if $req->method() eq 'DELETE'; # code = 202
            return halt(status_not_found( "Method not found" )); # code = 404
          }
        }
    };
};


=head1 AUTHOR

Nicolas Oudard, C<< <noudard at weborama.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-fake-response at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Fake-Response>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Fake::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Fake-Response>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Fake-Response>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Fake-Response>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Fake-Response/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nicolas Oudard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

register_plugin;
1; # End of Dancer::Plugin::Fake::Response
