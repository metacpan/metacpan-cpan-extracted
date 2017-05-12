package Chef;

use Chef::Recipe;
use Chef::Resource;
use Data::Dumper;
use JSON::Any qw(XS JSON DWIW);

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(resource node);

use warnings;
use strict;

=head1 NAME

Chef - Write Chef recipes in Perl instead of Ruby.

Learn more about Chef - L<http://wiki.opscode.com/display/chef>

=head1 VERSION

Version 0.01

=head1 WARNING

This is a proof of concept - it shows the path for future integration, but all the steps are not complete. What remains:

  * You cannot write Attribute or Definition files in Perl.
  * At the moment, all your Perl recipes must live in the same cookbook.
  * There is very little error handling. (ah, who am I kidding - there is none)

=cut

our $VERSION = '0.01';
our $recipe  = Chef::Recipe->new;
our $node_data;

=head1 SYNOPSIS

Example:
  
  use Chef;
  
  resource file => '/tmp/foo', sub {
    my $r = shift;
    $r->owner('adam');
    $r->action('create');
  };
  
  resource file => '/tmp/' . node->{attributes}->{hostname} . "_created_with_perl", sub {
    my $r = shift;
    $r->action('create');
  };
  
Would create a file called /tmp/foo, and one called /tmp/HOSTNAME_created_with_perl. (Where HOSTNAME is, well, your hostname).

To use this module, you will need to install Chef, place the included cookbook in your cookbook repository, and place your perl based recipes in files/default/perl_recipes.

=head1 EXPORT

We export two functions in to your namespace, resource and node.

=head1 FUNCTIONS

=cut

sub INIT {
  load_node();
}

=head2 node

Returns the Chef::Node object.  This allows you to see what recipes are applied to this node via:

  node->{recipes} # Returns an array of recipe names
  
Also allows you to access all the nodes attributes via:

  node->{attributes} # Returns all the nodes attributes
  
Any changes you make to the node object do not currently persist back in to Chef. (ie: you cannot use them in subsequent recipes.)  This is likely to change once integration is complete.

=cut
sub node {
  return $node_data;
}

sub load_node {
  my $data;
  while ( my $line = <STDIN> ) {
    $data = $data . $line;
  }
  $node_data = JSON::Any->jsonToObj($data);
  1;
}

=head2 resource

Create a new Chef Resource.  Valid resources are listed at:

  L<http://wiki.opscode.com/display/chef/Resources>
  
An example of translating from the ruby version to perl:

  # The ruby version
  package "sudo" do
    action :install
  end

  # Make sure sudo is always at the latest version
  resource package => "sudo", sub {
    my $r = shift;
    $r->action("upgrade");
  }
  
Essentially, you create new resources by calling this method with the resource type (package, remote_file, etc.), resource name ("sudo", "/tmp/foo"), and a subroutine which recives a Chef::Resource object.  You can then set attributes of the resource via that object. (Hence, my $r = shift).

=cut
sub resource {
  my $resource_type = shift;
  my $resource_name = shift;
  my $resource_sub  = shift;

  my $resource = Chef::Resource->new(
    {
      resource_type => $resource_type,
      name          => $resource_name,
      resource_sub  => $resource_sub
    }
  );
  $resource->evaluate();
  $recipe->add_resource($resource);
}

sub send_to_chef {
  print JSON::Any->objToJson(
    {
      node                => $node_data,
      resource_collection => $recipe->prepare_json
    }
  );
}

sub END {
  send_to_chef;
}

=head1 AUTHOR

Adam Jacob, C<< <adam at opscode.com> >>

=head1 SOURCE

You can find the source on GitHub at L<http://github.com/adamhjk/chef-perl>

=head1 BUGS

Please report bugs to L<http://tickets.opscode.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chef

You can also look for information at:

=over 4

=item * Opscodes Ticket Tracking System:
    
L<http://tickets.opscode.com>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chef>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chef>

=item * Search CPAN

L<http://search.cpan.org/dist/Chef/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Opscode, Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Chef