package Catalyst::View::Template::Lace::Role::ArgsFromStash;

use Moo::Role;

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  my %stash_args = $args->{ctx} ? %{$args->{ctx}->stash} : ();
  $args = +{
    %$args,
    %stash_args};
  return $args;
};

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::ArgsFromStash - fill init args from the stash

=head1 SYNOPSIS

Create a View that does this role:

    package  MyApp::View::User;

    use Moo;
    extends 'Catalyst::View::Template::Lace';
    with 'Catalyst::View::Template::Lace::Role::ArgsFromStash',

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template {q[
      <html>
        <head>
          <title>User Info</title>
        </head>
        <body>
          <dl id='user'>
            <dt>Name</dt>
            <dd id='name'>NAME</dd>
            <dt>Age</dt>
            <dd id='age'>AGE</dd>
            <dt>Motto</dt>
            <dd id='motto'>MOTTO</dd>
          </dl>
        </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', $self);

      ## The following two options all do the same transformation
      ## just maybe a bit more typing (you get a speedup since ->fill
      ## does not need to inspect '$self' for its fields.

      # $dom->dl('#user', +{
      #   age=>$self->age,
      #   name=>$self->name,
      #   motto=>$self->motto
      # });

      # $dom->at('#user')
      #   ->fill({
      #     age=>$self->age,
      #     name=>$self->name,
      #     motto=>$self->motto,
      #   });
    }

    1;

Call the View from a controller that sets stash values;

    package MyApp::Controller::User;

    use Moose;
    use MooseX::MethodAttributes;
    extends 'Catalyst::Controller';

    sub display :Path('') {
      my ($self, $c) = @_;
      $c->stash(
        name => 'John',
        age => 42,
        motto => 'Why Not?');
      $c->view('User')
        ->respond(200);
    }

    __PACKAGE__->meta->make_immutable;

Produces result like:

    <html>
      <head>
        <title>User Info</title>
      </head>
      <body>
        <dl id="user">
          <dt>Name</dt>
          <dd id="name">
            John
          </dd>
          <dt>Age</dt>
          <dd id="age">
            42
          </dd>
          <dt>Motto</dt>
          <dd id="motto">
            Why Not?
          </dd>
        </dl>
      </body>
    </html>

=head1 DESCRIPTION

If you wish to create a view using arguments passed from the L<Catalyst> stash, you can
do so with this role.  You may find this role helpful since its been common to use the
stash to pass values to the view for a long time.  Although I prefer to avoid use of the
stash, in this case at least the stash values are required to match the view type so 
there's less downside here than in other common views.

You might find this useful when you are trying to integrate L<Catalyst::View::Template::Lace>
into an existing project that makes heavy use of the stash, or when you build up data for
the view across actions in an action chain (although also see
L<Catalyst::View::Template::Lace::Role::PerContext>).

Also see L<Catalyst::View::Template::Lace/process> for more support for 'classic' style
template use.

=head1 SEE ALSO
 
L<Catalyst::View::Template::Lace>.

=head1 AUTHOR

Please See L<Catalyst::View::Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Catalyst::View::Template::Lace> for copyright and license information.

=cut
