package Dancer::Plugin::HTML::FormsDj;

use strict;
use warnings;
 
use Carp;
use Dancer ':syntax';
use Dancer::Plugin;

use Data::Dumper;
use HTML::FormsDj;

our $AUTHORITY = 'TLINDEN';
our $VERSION   = '0.01';

register formsdj => sub {
  my ($path, $config) = @_;
  #my $conf = plugin_setting;


  my %dj = (save => 0, get => 0, post => 0, redirect => '/', template => 0);
  foreach my $param (keys %dj) {
    if (exists $config->{$param}) {
      $dj{$param} = $config->{$param};
      delete $config->{$param};
    }
  }

  my $form = HTML::FormsDj->new(%{$config});

  if ($dj{post}) {
    post $path => $dj{post};
  }
  else {
    post $path => sub {
      my %input = params;
      if (exists $config->{csrf}) {
	 $form->csrfcookie(cookie 'csrftoken');
      }
      my %clean = $form->cleandata(%input);

      if ( $form->clean() ) {
	if ($dj{save}) {
	  $dj{save}(%clean);
	}
	redirect $dj{redirect};
      }
      else {
	template $dj{template}, { form => $form };
      }
    };
  }

  if ($dj{get}) {
    get $path => $dj{get};
  }
  else {
    get $path => sub {
      if (exists $config->{csrf}) {
	cookie csrftoken => $form->getcsrf, expires => "15 minutes";
      }

      template $dj{template}, { form => $form };
    };
  }

};


register_plugin;
1;

__END__

=head1 NAME

Dancer::Plugin::HTML::FormsDj - Dancer wrapper module for HTML::FormsDj 

=head1 SYNOPSIS

 use Dancer::Plugin::HTML::FormsDj;

 formsdj '/addbook' => {
      field => {
                title   => {
                            type     => 'text',
                            validate => { # some constraint },
                            required => 1,
                        },
                author  => {
                            type     => 'text',
                            validate => sub { # some constraint },
                            required => 1,
                           },
               },
      name         => 'registerform',
      csrf         => 1,
      save => sub { return; },
      template => 'addbook',
      redirect => '/booklist'
 }; 

=head1 DESCRIPTION

This module is a plugin for L<Dancer> which acts as a handy wrapper
around L<HTML::FormsDj>. It adds a new "route" keyword B<formsdj>,
which requires two parameters: a url path (a route) and a hashref.

The plugin handles GET and POST requests itself (by generating the
routes for it as well) and maintains the CSRF cookie, if this feature
is turned on.

The hashref parameter mostly consists of L<HTML::FormsDj> parameters,
for details about these refer to its documentation. Beside them there
are some parameters unique to B<Dancer::Plugin::HTML::FormsDj>:

=over

=item B<save>

If defined, it has to point to a subroutine (or a closure) which
will be executed if the form data validated successfully.

=item B<template>

The template to be used. Refer to L<HTML::FormsDj> for details
about template functions. Important to note: Inside the template
refer to the form using the variable name B<form>, eg:

 <% form.as_p %>

=item B<redirect>

A url path where to redirect the user after successfull posting
the data.

=item B<get>

If defined, it has to point to a subroutine (or a closure) which
will be executed on a GET request. To access the form use the
perl variable B<$form> inside the sub.

=item B<post>

If defined, it has to point to a subroutine (or a closure) which
will be executed on a POST request. To access the form use the
perl variable B<$form> inside the sub.

B<save> will be ignored if B<post> is defined.

=back

=head1 SEE ALSO

L<HTML::FormsDj>

L<Data::FormValidator>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 T. Linden

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS AND LIMITATIONS

See rt.cpan.org for current bugs, if any.

=head1 INCOMPATIBILITIES

None known.

=head1 DEPENDENCIES

L<Dancer::Plugin::HTML::FormsDj> depends on B<HTML::FormsDj> and L<Data::FormValidator>.

=head1 AUTHOR

T. Linden <tlinden |AT| cpan.org>

=head1 VERSION

0.01

=cut
