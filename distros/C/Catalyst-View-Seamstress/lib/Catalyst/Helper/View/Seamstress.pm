package Catalyst::Helper::View::Seamstress;

use strict;

=head1 NAME

Catalyst::Helper::View::Seamstress - Helper for Seamstress Views

=head1 SYNOPSIS

    script/create.pl view Seamstress Seamstress [ comp_root skeleton ]

=head1 DESCRIPTION

Helper module for
L<Catalyst::View::Seamstress|Catalyst::View::Seamstress>.
It will create 3 (three) configuration variables in
C<MyApp::View::Seamstress>:

=over

=item * comp_root

C<comp_root> is the directory I<above> the directory where the HTML files 
that Seamstress will process are. This directory is usually a I<sister>
directory to F<root>, F<scripts>, and so forth.

If you don't set this, the helper script will create code that will
come up with a sensible default for this directory.

=item * skeleton


A skeleton is a Seamstress-style Perl class as discussed in
L<HTML::Seamstress/"The_meat-skeleton_paradigm">.

=item * meat_pack

C<meat_pack> is a subroutine which will pack meat into the skeleton.
It is also discussed along with the skeleton at the above link.

=back

Note that although the helper will create B<3> configuration variables, 
only B<2> can be set from the command line. The default C<meat_pack>
routine cannot be over-ridden from the command line helper script because
no sensible substitute routine could be handled well in one-line.


=cut

sub default_comp_root {
  use File::Spec;

  File::Spec->rel2abs('root');
}

sub comp_root_logic {

q/do { my ($appname) = split '::', __PACKAGE__; $appname->config->{root} } /

}

sub mk_compclass {
  my ( $self, $helper, $comp_root, $skeleton ) = @_;
  my $file = $helper->{file};
  unless ($comp_root) {
    $comp_root = comp_root_logic;
    print STDERR '$comp_root not supplied... defaulting to ' . $comp_root;
  }

  $helper->render_file( 
    'compclass', 
    $file, {
      comp_root => $comp_root,
      skeleton  => $skeleton,
     }
   );
}


=head1 SEE ALSO

L<Catalyst::View::Seamstress>,
L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>,


=head1 AUTHOR

Terrence Brannon <metaperl@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
#use base 'Catalyst::Base';
#use base 'Catalyst::View::Seamstress';
#use base qw(Class::Prototyped HTML::Seamstress);
use base qw(Catalyst::View::Seamstress HTML::Seamstress);
use vars qw($comp_root);

BEGIN {
  # edit this to '/ernest/dev/catalyst-simpleapp/root'
  # or something along those lines... wherever the 
  # HTML for Seamstress to rewrite is.
  $comp_root  = [% comp_root %];
  $comp_root .= '/' unless $comp_root =~ m![/]$!;
}

sub comp_root { $comp_root }

__PACKAGE__->config(
  comp_root => $comp_root,
  fixup     => sub { } ,
  skeleton  => '[% skeleton %]',
  meat_pack => sub { 
    my ($self, $c, $stash, $meat, $skeleton) = @_;

    my $body_elem = $skeleton->look_down('_tag' => 'body');
    my $meat_body = $skeleton->look_down(seamstress => 'replace');

    unless ($meat_body) {
      warn "could not find meat_body";
      die $meat->as_HTML;
    }

    $meat_body->replace_content($meat->content_list);
  } # default sub, only runs if skeleton is true
 ) ;

use lib $comp_root;


1;


=head1 NAME

[% class %] - Catalyst Seamstress View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Seamstress View.

=head1 METHODS

=head2 comp_root

This method returns the root of your html file tree which is normally something
like /full/path/to/MyApp/root/


=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
