package Dancer2::Plugin::ViewCache;
use Modern::Perl;

our $VERSION = '1.0001'; # VERSION
our $AUTHORITY = 'cpan:CLEARBLT'; # AUTHORITY
# ABSTRACT: Create a code for a guest user to use to view a page
use Dancer2::Plugin;
use Carp;

has base_url => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{base_url};

      return $conf;
   }
);

has delete_after_view => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{delete_after_view} || 0;

      return $conf;
   }
);

has randomize_code_length => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{randomize_code_length} || 0;

      return $conf;
   }
);

has minimum_random_length => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{minimum_random_length} || 0;

      return $conf;
   }
);

has maximum_random_length => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{maximum_random_length} || 128;

      return $conf;
   }
);

has code => (
   is      => 'ro',
   default => sub {
      my $conf = $_[0]->config->{code};

      return $conf;
   }
);

has d2pdb => ( is => 'rwp', );

plugin_keywords qw/
   generate_guest_url
   /;

sub BUILD {
   my $self = shift;
   $self->_set_d2pdb( $self->find_plugin('Dancer2::Plugin::DBIC') )
      or croak
      'Dancer2::Plugin::ViewCache is dependent on Dancer2::Plugin::DBIC!';

   # This will be the proper code once bug with route prefixing is fixed
   #  $self->app->add_route(
   #     method => 'get',
   #     regexp => '/view_by_code/:code',
   #     code   => sub {
   #         my $app = shift;
   #         my $code = $app->request->route_parameters->get('code');

   #         my $view_by_code = $self->d2pdb->resultset('ViewCache')->search(code => $code)->single;
   #         unless ( defined $view_by_code ) {
   #            return "Unable to display content";
   #         }

   #         my $html = $self->template;
   #         if ( $view_by_code->delete_after_view ) {
   #            $view_by_code->delete();
   #         }

   #         return $html;
   #     },
   # );

   my $route = Dancer2::Core::Route->new(
      type_library => $self->config->{type_library},
      method       => 'get',
      regexp       => '/view_by_code/:code',
      prefix       => undef,
      code         => sub {
         my $app          = shift;
         my $code         = $app->request->route_parameters->get('code');
         my $view_by_code = $self->d2pdb->resultset('ViewCache')
            ->search( { code => $code } )->single;
         unless ( defined $view_by_code ) {
            return 'Unable to find content to display';
         }

         if ( $view_by_code->delete_after_view ) {
            $view_by_code->delete();
         }

         return $view_by_code->html;
      }
   );
   my $method = $route->method;
   push @{ $self->app->routes->{$method} }, $route;

}

sub generate_guest_url {
   my $self = shift;

   my $params = { @_, };
   my $del    = $params->{delete_after_view};
   unless ( defined $del ) {
      $del = 0;
   }

   my $html = $params->{html};
   croak 'You must pass "html" into generate_guest_url. No html found.'
      unless ( exists $params->{html}
      && defined $params->{html}
      && $params->{html} ne '' );

   my $length = $self->_randominteger // 128;
   my $code;
   if (  exists $params->{code}
      && defined $params->{code}
      && $params->{code} ne '' ) {
      $code = $params->{code};
   }
   else {
      $code = $self->_randomstring( $length, 'A' .. 'Z', 'a' .. 'z', 0 .. 9 );
   }

   my %code_args = (
      code              => $code,
      delete_after_view => $del,
      html              => $params->{html},
   );

   my $rset = $self->d2pdb->resultset('ViewCache');
   $rset->create( \%code_args );

   my $url = $self->base_url . "/view_by_code/$code";

   return $url;
}

sub _randominteger {
   my ($self) = @_;
   my $min    = $self->minimum_random_length;
   my $max    = $self->maximum_random_length;

   return $min + int( rand( $max - $min + 1 ) );
}

sub _randomstring {
   my $self   = shift;
   my $length = shift;

   my $rand_string = join '', @_[ map { rand @_ } 1 .. $length ];

   # If the code happens to already be in the db, generate another one
   while (
      defined(
         $self->d2pdb->resultset('ViewCache')
            ->find( { code => $rand_string } )
      )
   ) {
      warn
         "Generated code was already in the database, generating another one\n";

      $rand_string
         = $self->_randomstring( 128,, 'A' .. 'Z', 'a' .. 'z', 0 .. 9 );

      last;
   }

   return $rand_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ViewCache - Create a code for a guest user to use to view a page

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

In your L<Dancer2> application configuration:

   plugins:
      ViewCache:
        base_url: 'https://my.server.com'
        template: 'project/order_acknowledgement'

Then in your application:

   package MyApp;
   use Dancer2 appname => 'MyApp';
   # This plugin has been tested with Provider::DBIC, but it should work for others.
   use Dancer2::Plugin::DBIC;
   use Dancer2::Plugin::ViewCache;

=head1 DESCRIPTION

This L<Dancer2> plugin lets you create a url with a unique code that can be given to a guest user to view 
a web page without logging into the site.

If delete_after_view is set, the generated link will be invalidated after being viewed.

=head1 CONFIGURATION

Example configuration

   plugins:
      ViewCache:
         base_url: 'https://my.server.com'         # No default
         delete_after_view: '1'                    # Default '0'
         randomize_code_length: '1'                # Default '0'
         minimum_random_length: '5'                # Default '1'
         maximum_random_length: '5'                # Default '128'
         template: 'project/order_acknowledgement' # No default

=head2 base_url

The base URL that the code will be appended to. E.g.
https://www.servername.com/

=head2 randomize_code_length

Makes the code generated for the guest URL be of random length. Without a random value, the default code length is 128.

=head2 minimum_random_length

Minimum length for randomize_code_length, default of 1

=head2 maximum_random_length

Maximum length for randomize_code_length, default of 128

=head1 SUGGESTED SCHEMA

You'll need a table to store the generated URL data named view_cache. The following example is for Postgres:

=head2 view_cache Table

   CREATE TABLE view_cache (
       cache_id  SERIAL NOT NULL PRIMARY KEY,
       code TEXT NOT NULL UNIQUE,
       html TEXT NOT NULL,
       delete_after_view BOOLEAN NOT NULL DEFAULT FALSE,
       created_dt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
   );

=head1 KEYWORDS

=head2 generate_guest_url([ \%options ])

Stores provided HTML and generates a URL for a guest user to view it with.

The "html" argument is mandatory. This is the HTML that will be displayed by the generated URL.

If the optional $code argument is provided, this will be used in the generated URL. If this is not provided, a random code will be generated and used.

Note: You should not make any calls to this that store values to the database inside a transaction, if you plan to consume them before the transaction ends.

Examples:

   my $url = generate_guest_url({ html => $html});

   my $url = generate_guest_url(
         code => '123abc',
         html => $html
   );

   my $url = generate_guest_url(
         html => $html,
         delete_after_view => '1',
         randomize_code_length => '1'
   );

=head1 REQUIRES

=over 4

=item *
L<Dancer2::Plugin|Dancer2::Plugin>

=item *
L<Dancer2::Plugin::DBIC|Dancer2::Plugin::DBIC>

=back

=head1 ROADMAP

=over 4

=item *
Generate a URL for a PDF or XML file stored on disk

=item *
Specify a number of days for the link to be active before invalidating

=back

=head1 AUTHOR

Tracey Clark <traceyc@clearbuilt.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Clearbuilt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
