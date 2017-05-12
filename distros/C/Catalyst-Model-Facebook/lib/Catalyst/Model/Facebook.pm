package Catalyst::Model::Facebook;
BEGIN {
  $Catalyst::Model::Facebook::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Catalyst::Model::Facebook::VERSION = '0.101';
}
# ABSTRACT: The Catalyst model for the package Facebook

use Moose;
use Catalyst::Utils;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

use namespace::autoclean;

has 'facebook_class' => (
	is => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { 'Facebook' }
);

has 'facebook_signed_class' => (
	is => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { 'Facebook::Signed' }
);

has 'app_id' => (
	is => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { die "we need an app id" }
);

has 'api_key' => (
	is => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { die "we need an api key" }
);

has 'secret' => (
	is => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub { die "we need your app secret" }
);

sub build_per_context_instance {
	my ( $self, $c ) = @_;
	
	Catalyst::Utils::ensure_class_loaded($self->facebook_class);
	Catalyst::Utils::ensure_class_loaded($self->facebook_signed_class);

# canvas application
	if (exists $c->req->params->{'signed_request'}) {
		return $self->facebook_class->new(
			signed => $self->facebook_signed_class->new(
				canvas_param => $c->req->params->{'signed_request'},
				secret => $self->secret,
			),
			app_id => $self->app_id,
			api_key => $self->api_key,
		);
# website application
	} elsif ($c->req->cookie('fbs_'.$self->app_id)) {
		my $facebook_data = join('&',$c->req->cookie('fbs_'.$self->app_id)->value);
		$facebook_data =~ s/^"|"$//g;
		return $self->facebook_class->new(
			signed => $self->facebook_signed_class->new(
				cookie_param => $facebook_data,
				secret => $self->secret,
			),
			app_id => $self->app_id,
			api_key => $self->api_key,
		);
	} else {
		return $self->facebook_class->new(
			signed => $self->facebook_signed_class->new(
				secret => $self->secret,
			),
			app_id => $self->app_id,
			api_key => $self->api_key,
		);
	}

}

1;


1;

__END__
=pod

=head1 NAME

Catalyst::Model::Facebook - The Catalyst model for the package Facebook

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  #
  # Config
  #
  <Model::MyModel>
    app_id 122038147863143
	api_key e0dd54ae57bcdf6b3cac784bf80243fd
    secret 1b010be5853166ad425683e8d753e0af
    facebook_class Facebook
    facebook_signed_class Facebook::Signed
  </Model::MyModel>

  #
  # Sample controller code
  #
  sub index :Chained('base') :PathPart('') :Args {
    my ( $self, $c ) = @_;

    if ($c->model('MyModel')->uid) {
      $c->stash->{facebook_user_profile} = $c->model('Facebook')->graph->query
        ->find($c->model('MyModel')->uid)
        ->include_metadata
        ->request
        ->as_hashref;
    }

  }

=head1 DESCRIPTION

This package wraps around the L<Facebook> package. It uses the L</facebook_cookie_class> where it gives over L</app_id>, L</secret>
and the text of the facebook cookie of this L</app_id>. This object will be used as cookie attribute for the construction of the
L</facebook_class>. 

=encoding utf8

=head1 CONFIG PARAMETERS

=head2 app_id

The application id you got from your L<http://www.facebook.com/developers/apps.php> application page.

=head2 api_key

The API key you got from your L<http://www.facebook.com/developers/apps.php> application page.

=head2 secret

The application secret you got from your L<http://www.facebook.com/developers/apps.php> application page.

=head2 facebook_class

If you want to extend the L<Facebook> class, or want to use an alternative implementation which is compatible, you can set here the
class that should be used for this adapter.

=head2 facebook_signed_class

With this parameter you can give him a different L<Facebook::Signed> class which he uses for parsing the signed values for
the L<Facebook> object on construction.

=head1 SEE ALSO

L<Catalyst::Helper::Model::Facebook>

L<Facebook>

L<Facebook::Signed>

=head1 SUPPORT

IRC

  Join #facebook on irc.perl.org.

Repository

  http://github.com/Getty/p5-catalyt-model-facebook
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-catalyt-model-facebook/issues

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=item *

Frank Sheiness <syndesis@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software & Facebook Distribution Authors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

