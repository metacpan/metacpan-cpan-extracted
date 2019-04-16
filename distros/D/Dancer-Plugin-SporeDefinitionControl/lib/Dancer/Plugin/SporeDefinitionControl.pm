package Dancer::Plugin::SporeDefinitionControl;

use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::REST '0.04';
use YAML qw/LoadFile DumpFile/;
use File::Spec;

=head1 NAME

Dancer::Plugin::SporeDefinitionControl

Dancer Plugin to control validity of route from a Spore configuration file

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

Dancer required version : 1.3002

in your Dancer project, use this plugin and register  :

    package MyDancer::Server;

    use Dancer::Plugin::SporeDefinitionControl;

    check_spore_definition();

In your config file :

    plugins:
      SporeDefinitionControl:
        spore_spec_path: path/to/route_config.yaml

The yaml path file can be relative (root project base) or absolute.

in your file path/to/route_config.yaml, put your SPORE config :

    base_url: http://localhost:4500
    version: 0.2
    format:
      - json
      - xml
      - yml
    methods:
      get_object:
        required_params:
          - id
          - name_object
        optional_params:
          - created_at
        path: /object/:id
        method: GET
      create_object:
        required_params:
          - name_object
        optional_params:
          - created_at
        path: /object/create
        method: POST
      update_object:
        required_params:
          - id
          - name_object
        optional_params:
          - created_at
        path: /object/:id
        method: PUT
      delete_object:
        required_params:
          - id
          - name_object
        optional_params:
          - created_at
        path: /object/:id
        method: DELETE

=head1 INITIALISATION

Load yaml config file

=cut


#Load definition spore file from plugin config

our $path_validation;
#_load_path_validation();
$path_validation =_load_path_validation();
sub _load_path_validation
{
    my $rh_file = {};

    my $path_to_spore_def = plugin_setting->{'spore_spec_path'};
    my $build_options_route = plugin_setting->{'build_options_route'};
    if ($path_to_spore_def)
    {
    $path_to_spore_def = File::Spec->catfile( setting('appdir') , $path_to_spore_def) unless (File::Spec->file_name_is_absolute($path_to_spore_def));
    $rh_file = LoadFile($path_to_spore_def);
    }

    my $path_valid;

    #load validation hash
    foreach my $method_name (keys(%{$rh_file->{'methods'}}))
    {
        my $method = $rh_file->{'methods'}->{$method_name}->{'method'};
        my $complet_path = $rh_file->{'methods'}->{$method_name}->{'path'};
        my ($path, $query_params) = split(/\?/, $complet_path);
        my @additional_params;
        if (defined $query_params)
        {
            @additional_params = map { $_ =~ s/=.*//g; $_ } split( /\&/, $query_params) ;
            push @{$rh_file->{'methods'}->{$method_name}->{'required_params'}}, @additional_params;
        }

        push @{$path_valid->{path}->{$path}}, $method;
        push @{$path_valid->{method}->{$method}->{$path}->{params}},
          {
            required_params => $rh_file->{'methods'}->{$method_name}->{'required_params'},
            optional_params => $rh_file->{'methods'}->{$method_name}->{'optional_params'},
            form_data_params => $rh_file->{'methods'}->{$method_name}->{'form-data'},
          };
        $path_valid->{method}->{$method}->{$path}->{functions}->{$method_name} = 1;

    }
    init_routes_options($path_valid->{path}) if (defined $build_options_route);
    return $path_valid;
};

=head2 init_routes_options

force the routes on options method

=cut



sub init_routes_options(){
    my $paths = shift;
    foreach my $path (keys %{$paths}){
            options $path => sub {
            };

        }
}




=head1 SUBROUTINES/METHODS

=head2 check_spore_definition

define spore validation to do on entered request

=cut

register 'check_spore_definition' => sub {
    hook before => sub {
        my $req = request;
        my %req_params = params;
        die "method request must be defined" unless (defined( $req->method() ) );
        _returned_error( "route pattern request must be defined", 404) unless (defined( $req->{_route_pattern} ) );

#        my $all_route_pattern = $req->{_route_pattern};
#my $detail_route_pattern =  split /?/, $route_pattern;
        $path_validation = _load_path_validation() if !$path_validation;
        unless (defined( $path_validation->{method}->{$req->method()}) || uc($req->method()) eq "OPTIONS" )
        {
          my $req_method = $req->method();
          return _returned_error("no route define with method `$req_method'", 404);
        }

        #TODO : return an error because path does not exist in specification
        unless (defined( $path_validation->{method}->{$req->method()}->{$req->{_route_pattern}} ) 
                        || (uc($req->method()) eq "OPTIONS" && defined($path_validation->{path}->{$req->{_route_pattern}}))
                )
        {
          my $req_route_pattern = $req->{_route_pattern};
          return _returned_error("route pattern `$req_route_pattern' is not defined",404);
        }

        my $is_ok = 0;
        #IF method is OPTIONS list of methods set the headers and return ok
        _returned_options_methods($path_validation->{path}->{$req->{_route_pattern}}) if (uc($req->method()) eq "OPTIONS" );
        my $error;
        foreach my $route_defined (@{$path_validation->{method}->{$req->method()}->{$req->{_route_pattern}}->{params}})
        {
            my $ko;
            my $ra_required_params = $route_defined->{'required_params'};
            my $ra_optional_params = $route_defined->{'optional_params'};
            my $ra_form_data_params;
            if ($route_defined->{'form_data_params'}){
                foreach my $k (keys %{$route_defined->{'form_data_params'}}){
                    push @{$ra_form_data_params}, $k;
                }
            }

            # check if required params are present

            foreach my $required_param (@{$ra_required_params})
            {
                if (!defined params->{$required_param})
                {
                    $error = "required params `$required_param' is not defined";
                    $ko = 1;
                }
            }
            next if $ko;

            my @list_total = ('format');
            @list_total = (@list_total, @{$ra_required_params}) if defined($ra_required_params);
            @list_total = (@list_total, @{$ra_optional_params}) if defined($ra_optional_params);
            @list_total = (@list_total, @{$ra_form_data_params}) if defined($ra_form_data_params);
            # check for each params if they are specified in spore spec
           
            foreach my $param (keys %req_params)
            {
                if (!(grep {/^$param$/} @list_total))
                {
                    $error  = "parameter `$param' is unknown";
                    $ko = 1 ;
                }
            }
            next if $ko;
            $is_ok = 1;
        }
        return _returned_error($error,400) unless $is_ok;
        
        #set the access-control-allow-credentials if needed
        _set_access_control_header($path_validation->{path}->{$req->{_route_pattern}});
      };
};


=head2 get_functions_from_request

return the hash of functions available from method and path.

=cut

register 'get_functions_from_request' => sub {
    my $req = request;

    $path_validation = _load_path_validation() if !$path_validation;
    my $method = $req->method();
    my $path = $req->{_route_pattern};
    my $functions = $path_validation->{method}->{$method}->{$path}->{functions};
    return $functions;
};

# format the error returned
sub _returned_error
{
  my $str_error = shift;
  my $code_error = shift;
  $code_error ||= 400;
  set serializer => 'JSON';
  debug $str_error."\n";
  #return halt(send_error($str_error,400));
  if ($code_error == 400)
  {
    return halt(status_bad_request($str_error));
  }
  elsif ($code_error == 404)
  {
    return halt(status_not_found($str_error));
  }
  else
  {die "Unknown code";}
}

# Format and return the options method
sub _returned_options_methods
{
  my $methods = shift;
  if (defined $methods){
    set serializer => 'JSON';
    _set_access_control_header($methods);
    status 200;
    return halt('{"status":200,"message":"OK"}');
  }
  else{
      set serializer => 'JSON';
      status 404;
      return halt('{"status":404,"message":"no route exists"}');
  }
}

# Set the access control header of each request following the configuration
sub _set_access_control_header
{
  my $methods = shift;
  my $req = request;
  my %seen = ();
  my $build_options_route = plugin_setting->{'build_options_route'};
  my @unique_methods = grep { !$seen{$_}++ } @{$methods};
  my $origin_allowed;
  #check that header contain origin and that url is permit by api
  $origin_allowed = $req->header('Origin') if ( defined $req->header('Origin') 
                                                  && defined $build_options_route->{'header_allow_allow_origins'} 
                                                  &&  $req->header('Origin') ~~ @{$build_options_route->{'header_allow_allow_origins'}}
                                                );
  header 'access-control-allow-credentials' => $build_options_route->{'header_allow_credentials'} || '';
  header 'access-control-allow-headers' => $build_options_route->{'header_allow_headers'} || '';
  header 'access-control-allow-methods' => join(",",@unique_methods,'OPTIONS');
  header 'access-control-allow-origin' => $origin_allowed if defined $origin_allowed;
  header 'access-control-max-age' => $build_options_route->{'header_max_age'}  || '';
}


=head1 AUTHOR

Nicolas Oudard, C<< <nicolas at oudard.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-sporedefinitioncontrol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-SporeDefinitionControl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SporeDefinitionControl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SporeDefinitionControl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SporeDefinitionControl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SporeDefinitionControl>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-SporeDefinitionControl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Nicolas Oudard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

register_plugin;
1; # End of Dancer::Plugin::SporeDefinitionControl
