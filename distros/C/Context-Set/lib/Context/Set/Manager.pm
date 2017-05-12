package Context::Set::Manager;
use Moose;
use Moose::Util;

use Context::Set;
use Context::Set::Restriction;
use Context::Set::Union;

use Context::Set::Storage::BlackHole;

has '_localidx' => ( is => 'ro' , isa => 'HashRef[ArrayRef[Context::Set]]', default => sub{ {}; });
has '_fullidx' => ( is => 'ro' , isa => 'HashRef' , default => sub{ {}; } );

has 'universe' => ( is => 'ro' , isa => 'Context::Set' , required => 1 ,
                    lazy_build => 1 );

has 'storage' => ( is => 'ro', isa => 'Context::Set::Storage' , required => 1,
                   default => sub{ return Context::Set::Storage::BlackHole->new() } );
has 'autoreload' => ( is => 'ro', isa => 'Bool', default => 0 );

=head1 NAME

Context::Set::Manager - A manager for your Context::Sets

=head1 SYNOPSIS

  my $cm = Context::Set::Manager->new();

  my $users = $cm->restrict('users');
  $users->set_property('page.color' , 'blue');

  my $user1 = $cm->restrict('users' , 1 );

  ## OR

  $user1 = $users->restrict(1);

  $user1->set_property('page.color' , 'pink');

  $user1->get_property('page.color'); # pink.

  $cm->restrict('users' , 2)->get_property('page.color'); # blue

  ## OR

  $users->restrict(2)->get_property('page.color'); # blue

=head2 PERSISTENCE

Give your manager a L<Context::Set::Storage> subclass at build time. So all managed context persist using this storage.

For example:

 my $cm = Context::Set::Manager->new({ storage => an instance of Context::Set::Storage::DBIC });
 ...


=head2 CONCURRENCY

If your manager lives in a process and a stored value is changed by another process,
you can set this to autoreload the managed contexts on access. Use the option autoreload for that
(Note that it only makes sense with a Persistent storage (see PERSISTENCE):

 my $cm = Context::Set::Manager->new({ storage => an instance of Context::Set::Storage::DBIC,
                                       autoreload => 1 });

Note: Performance might be impacted. This will be solved in the future by implementing cachable
storages.

=cut

sub _build_universe{
  my ($self) = @_;

  my $universe = Context::Set->new();
  return $self->manage($universe);
}


=head2 manage

Adds the given Context::Set to this manager (in case it was built outside).

Note that if a context with an identical fullname is already there, it
will return it. This is to ensure the unicity of contexts within the manager.

Usage:

  $context = $cm->manage($context);

=cut

sub manage{
  my ($self , $context) = @_;

  if( my $there = $self->_fullidx()->{$context->fullname()} ){
    if( $self->autoreload() ){
      $self->storage->populate_context($there);
    }
    return $there;
  }

  if( my $localname = $context->name() ){
    $self->_localidx->{$localname} //= [];
    push @{$self->_localidx->{$localname}},  $context;
  }
  $self->_fullidx->{$context->fullname()} = $context;

  ## Let the storage fill up the full context.
  $self->storage()->populate_context($context);

  ## Apply the managed role to this new context so this manager is contagious.
  ## and it interact with the storage.
  Moose::Util::ensure_all_roles($context,
                                'Context::Set::Role::Managed',
                                'Context::Set::Role::Stored',
                               );
  ## Dont forget to inject myself.
  $context->manager($self);
  ## and the storage
  $context->storage($self->storage());
  return $context;
}

=head2 restrict

Builds a restriction of the universe or of the given context.

 Usage:

  my $users = $cm->restrict('users'); ## This restricts the UNIVERSE
  my $user1 = $cm->restrict($users, 1); ## This restricts the users.
  my $user1 = $cm->restrict('users' , 1); ## Same thing
  my $user1 = $cm->restruct('UNIVERSE/users' , 1); ## Same thing.

=cut

sub restrict{
  my ($self, $c1, $new_name) = @_;
  unless( $new_name ){
    unless( $c1 ){
      confess("Missing restriction name");
    }
    return $self->_restrict_context($self->universe(), $c1);
  }

  if( my $context = $self->find($c1) ){
    unless( $new_name ){
      confess("Missing restriction name");
    }
    return $self->_restrict_context($self->find($c1) , $new_name);
  }
  confess("Cannot find context '".( $c1 // 'UNDEFINED' )."' to restrict");
}

=head2 unite

Returns the union of the given Context::Sets. You need to give at least two contexts.

Context::Sets can be given by name or by references.

Usage:

  my $ctx = $this->unite('context1' , $context2);
  my $ctx = $this->unite($context1, 'context2', $context3);

=cut

sub unite{
  my ($self , @contexts ) = @_;
  unless( scalar(@contexts) >= 2 ){
    confess("You need to unite at least 2 Context::Sets");
  }

  @contexts = map{ $self->find($_) or die "Cannot find Context::Set to unite for '$_'" } @contexts;
  return $self->manage(Context::Set::Union->new({ contexts => \@contexts }));
}


sub _restrict_context{
  my ($self, $c1 , $new_name) = @_;
  return $self->manage(Context::Set::Restriction->new({ name => $new_name,
                                                   restricted => $c1 }));
}

=head2 find

Finds one context by the given name (local or full). Returns undef if nothing is found.

If the name only match a local name and there's more that one Context::Set with this name, the latest one will be returned.

Usage:

 if( my $context = $this->find('a_name') ){

 $this->find('UNIVERSE/name1/name2');

 if( $this->find($a_context) ){ ## Is this context in this manager

=cut

sub find{
  my ($self ,$name) = @_;

  ## Dereference if its a reference. Will not work with anything
  ## else but Context::Sets.
  if( ref($name) ){ return $self->find($name->fullname()); }

  ## Case of fullname match
  if( my $c = $self->_fullidx()->{$name} ){ return $c;}

  ## Case of local name match.
  return $self->_localidx()->{$name}->[-1];
}


__PACKAGE__->meta->make_immutable();
1;
