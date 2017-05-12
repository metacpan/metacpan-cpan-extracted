package Authorization::RBAC;
$Authorization::RBAC::VERSION = '0.10';
use utf8;
use Moose;
with 'MooseX::Object::Pluggable';

use Moose::Util::TypeConstraints;
use Config::JFDI;
use Carp qw/croak/;

subtype MyConf => as 'HashRef';
coerce 'MyConf'
  => from 'Str' => via {
    my $conf = shift;
    my ($jfdi_h, $jfdi) = Config::JFDI->open($conf)
      or croak "Error (conf: $conf) : $!\n";
    return $jfdi->get;
  };

has conf => ( is => 'rw',
              isa => 'MyConf',
              coerce => 1,
              trigger  => sub {
                my $self = shift;
                my $args = shift;

                croak "Error: Can not find " . $self->ns . " in your conf !"
                  if ( ! $args->{$self->ns});

                $self->config($args->{$self->ns});

                $self->debug($self->config->{'debug'}) if ( defined $self->config->{'debug'} );

                $self->_load_backend if ! $self->can('backend');
              }
            );

# optional (used by DBIX backend )
has 'schema'     => (
                     is        => 'rw',
                     predicate => 'has_schema',
                 );

has 'debug' => (
                is       => 'rw',
               );

has _plugin_ns => (
  is => 'rw',
  required => 1,
  isa => 'Str',
  default => sub{ 'Backend' },
);

# namespace
has 'ns' => (
                is       => 'rw',
                default => sub { __PACKAGE__ },
               );

has config => (
               isa      => "HashRef",
               is       => "rw",
);

has cache => (
               is       => "rw",
               required => 0,
);


sub _load_backend {
  my $self = shift;
  my $backend = $self->config->{'backend'}->{name};

  $self->_log("Loading $backend backend ...");
  $self->load_plugin( $backend );
}


# can_access check if user or roles have permissions on all operations
# of a object or more.
sub can_access {
  my ( $self, $roles, $objects, $additional_operations ) = @_;

  # Check perm on all objects
  foreach my $obj (@$objects) {

    # Not necessary to check if it's not an object
    next if ! ref($obj);

    # copy obj to not disturb objets
    my $obj2 = $obj;

    # build parent objects
    my @allobjs;
    while ( $obj2 ) {
        push(@allobjs, $obj2);
        my $typeobj = ref($obj2);
        $typeobj =~ s/.*:://;
        my $parent_field = $self->config->{typeobj}->{$typeobj}->{parent_field} || 'parent';
        if ( $obj2->can( $parent_field)) {
            $obj2 = $obj2->$parent_field;
        }
        else { $obj2 = 0 }

    }

    # check permission on each object
    my $ops;
    foreach my $obj2 ( reverse @allobjs ) {

        my $typeobj2 = ref($obj2);
        $typeobj2 =~ s/.*:://;
        $self->_log("> Search if we can access to ${typeobj2}_" . $obj2->id);

        if ( $obj2 eq $obj ) {
            $ops = $additional_operations;
        }
        else {
            $ops = [];
        }
        if ( ! $self->check_permission( $roles, $obj2, $ops )){
            $self->_log("return 0");
            return 0;
        }
    }
  }

  $self->_log("return 1");
  return 1;
}


# Is roles can an operation on object
sub check_permission {
  my ( $self, $roles, $obj, $additional_operations ) = @_;

  my $typeobj = ref($obj);
  $typeobj =~ s/.*:://;

  my @ops_to_access = $obj->ops_to_access;
  if ( $additional_operations ) {
      push(@ops_to_access, $self->get_operations($additional_operations));
  }

  $self->_log("  [OK] Object is not protected") if ( ! $ops_to_access[0] );

  # Looking operations protecting the object
  my %already_checked;
  foreach my $op ( @ops_to_access ) {

      next if ! $op;

      next if $already_checked{$op->name};
      $already_checked{$op->name} = 1;

      my $ret = 0;
      ROLES: foreach my $r ( @$roles ) {

            next if ! $r;
            $self->_log("- Search if role " . $r->name ." can '" . $op->name . "' '${typeobj}_" . $obj->id."'");

            # get permission from backend
            my ($result, $inheritable) = $self->get_permission($r, $op, $obj);

            if ( ! defined $result ) {
                next;
            }
            elsif ( ! $result ) {
                $self->_log( "  [KO] ".$r->name." cannot '" . $op->name . "' '${typeobj}_" . $obj->id."'" );
                $ret = 0;
            }
            elsif ( $result ) {
                $self->_log( "  [OK] ".$r->name." can '" . $op->name . "' '${typeobj}_" . $obj->id."'" );
                $ret = 1;
                last ROLES;
            }
        }
      return 0 if ! $ret;
  }

  return 1;
}



sub _log{
  my ($self, $msg ) = @_;

  return if ! $self->debug;

  say STDERR "[debug] $msg";
}

=encoding utf8

=head1 NAME

Authorization::RBAC - Role-Based Access Control system



=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Authorization::RBAC;

    my $conf = 't/conf/permsfromdbix.yml';
    my $rbac = Authorization::RBAC->new( conf => $conf ); # add schema => $schema if DBIx backend

    my $page  = $rbac->schema->resultset('Page')->search( name => 'add' , parent => 7 );
    my $roles = ... function that returns the roles ...

    if ( $rbac->can_access($roles, $page, [ 'create_Page' ]) ){
        # Role 'member' can access to Page /page/wiki/add
    }

=head1 DESCRIPTION

Role-based access control (RBAC) is an approach to restricting system access to authorized users.

User -> Role(s)

Role -> Permission -> Object (Typeobj, unique)
                   -> Operation


So you can apply a permission to an instance of a Object and not only on all the class of the Object.

La suite en Français ...

Pourquoi ce module: J'étais à la recherche d'un module pouvant assurer la protection des accès à des objets. J'ai bien trouvé des modules sur le CPAN qui semblait répondre au besoin mais il y avait toujours un détail, une approche qui ne me convenait pas. La plupart de ces modules répondent à la question 'Est-ce que ce rôle peut faire cette opération ?'. Par exemple 'Est-ce que le rôle 'anonyme' peut créer un commentaire ?' mais jamais à la question 'Est-ce que ce rôle peut faire cette opération sur cet objet ?', exemple : 'Est que le role anonyme peut créer un commentaire sur cette page ?'.  De plus je souhaitais que ce système de permissions soit récursif si l'objet à protéger comportait un champ 'parent'.


Comment ça marche :

Actuellement Authorization::RBAC comporte un seul backend : DBIx

Définition des acteurs du système :

- Un Type d'objet : Ce peut être une 'Page', un 'Commentaire', 'Une pièce jointe' ...

- Opération : Il s'agit d'un action sur un Type d'objet'. ( 'Add_Page', 'Del_Comment')

- Un Objet : c'est une instance du Type d'objet. 'Page login', 'Comment n°33', ...

- Une Permission : c'est une opération sur un Objet. Elle peut être récursive.

- Un Role : Il hérite de Permission(s)

Pour accéder à un Objet, le(s) role(s) doit posséder une Permission répondant à une Opération par défaut. Pour cela l'Objet doit avoir une méthode 'ops_to_access' qui retourne le ou les Operations qui le protège (en fait une référence à un tableau d'Opération). Par exemple la méthode ops_to_access de l'Objet 'Page /' retourne ['view_Page'], ce qui signifie "Pour accéder à la Page / le role doit avoir la Permission view_Page sur Page /".

La méthode 'can_access' permet d'interroger le système:

my $access = $rbac->can_access($roles, $objet, $additional_operations );


Un Objet peut avoir une méthode 'parent'. Si c'est le cas alors 2 mécanismes s'ajoute au système de permission :

- L'accès à un objet est obtenu si l'accès est permit à tous ses parents. Par exemple, pour accéder à la Page '/admin/user/add', le(s) role(s) devra successivement accéder à '/', 'admin', 'user' et enfin 'add'.

- En second lieu une Permission peut être rechercher récursivement sur les parents de l'Objet.

Par exemple si nous avons les relations suivantes :

Page:
  /:
    ops_to_access: view_Page
  admin:
    ops_to_access: view_Page
  add:
    ops_to_access: create_Page

Pour accéder à l'Objet 'Page /admin/user/add', le(s) role(s) devra posséder des Permissions répondant à 'view_Page sur Page /', 'view_Page sur Page admin' et 'create_Page sur Page add'.
Imaginons que le(s) role(s) ne peut accèder à l'Objet. Par exemple si le(s) role(s) ne possède pas la Permission 'create_Page sur Page add' alors la recherche de la Permission se fera aussi sur 'admin' puis sur '/'. Pour que cette règle s'applique il faut que la Permission ait une méthode 'inheritable' qui si elle retourne 1 rendra la Permission héritable par ses enfants. Si elle retourne 0 cela a l'effet inverse, ça signifie que le role n'a pas ou plus cette Permission.

Imaginons maintenant que les roles aient les Permissions suivantes :

Roles:
  administrateur:
    view_Page:
      Page_/: 1
       inheritable: 1
      Page_admin: 1
       inheritable: 1
    create_Page:
      Page_/: 1
       inheritable: 1
  anonymous:
    view_Page:
      Page_/; 1
       inheritable: 1
      Page_admin: 0
       inheritable: 1


Ainsi lorsque l'on recherche si le role 'administrateur' peut accéder à / admin / user / add, on ne trouvera pas de Permission 'create_Page sur Page add' mais on la retrouvera sur le parent racine et cette Permission est héritable.

Attention car nous avons donné la Permission 'view_Page sur Page / héritable' à 'anonymous' donc si rien n'est fait il a aussi accès à /admin. C'est pourquoi Nous lui avons aussi donné la Permission 'Ne peut view_Page sur Page_Admin héritable'. Ainsi l'accès à /admin est bloqué.



=head1 CONFIGURATION

See t/conf/permfromdb.yml

And also L<Authorization::RBAC::Backend::DBIx>

=head1 PROVIDED METHODS

=head2 can_access($roles, $objects, $additional_operations )

=head2 check_permission($roles, $objects, $additional_operations )

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authorization-rbac at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authorization-RBAC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authorization::RBAC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authorization-RBAC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authorization-RBAC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authorization-RBAC>

=item * Search CPAN

L<http://search.cpan.org/dist/Authorization-RBAC/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Authorization::RBAC
