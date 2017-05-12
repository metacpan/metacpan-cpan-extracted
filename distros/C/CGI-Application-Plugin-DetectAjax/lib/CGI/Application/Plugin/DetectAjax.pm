package CGI::Application::Plugin::DetectAjax;

use strict;
use vars qw($VERSION @EXPORT);

require Exporter;

@CGI::Application::Plugin::DetectAjax::ISA = qw(Exporter);

$VERSION = '0.06';

@EXPORT = qw(
  is_ajax
);

sub is_ajax {

  my $self = shift;


  my $header = 'HTTP_X_REQUESTED_WITH';

  if (exists $ENV{$header} && lc $ENV{$header} eq 'xmlhttprequest') {
    return 1;
  }
  else {
    return 0;
  }

}


1;

__END__
=encoding utf8

=head1 NAME

CGI::Application::Plugin::DetectAjax - check for XMLHttpRequest in CGI::Application based modules


=head1 SYNOPSIS

 package My::App;

 use base qw/CGI::Application/;

 use CGI::Application::Plugin::DetectAjax;

 ...

 sub myrunmode {
   my $self = shift;

   my $object = MyClass->new;

   my $result = $object->do_work();

   if ($self->is_ajax) {

    return to_json($result);

   }
   else {

     my $t = $self->load_tmpl('myrunmode.tmpl');

     $t->param(RESULT => $result);
     return $t->output;

   }
 }



=head1 DESCRIPTION

CGI::Application::Plugin::DetectAjax adds is_ajax method to your L<CGI::Application>
modules which detects whether the current request was made by XMLHttpRequest.


=head1 METHODS

=head2 is_ajax

This method will return true if the current request was made by XMLHttpRequest and false otherwise.
It works by checking for 'X-Requested-With' header and its value.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-ajax@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

L<CGI::Application>, L<CGI>, perl(1)


=head1 AUTHOR

Jiří Pavlovský <jira@getnet.cz>


=head1 LICENSE

Copyright (C) 2010 Jiří Pavlovský <jira@getnet.cz>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

