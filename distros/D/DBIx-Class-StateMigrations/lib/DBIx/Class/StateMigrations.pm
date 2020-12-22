package DBIx::Class::StateMigrations;

use strict;
use warnings;

# ABSTRACT: Schema migrations via checksums instead of versions

our $VERSION = '0.002';

use Moo;
use Types::Standard qw(:all);
use Scalar::Util 'blessed';
use Try::Tiny;
use Class::Unload;
use Class::Inspector;

use Path::Class qw/file dir/;
use DBIx::Class::Schema::Diff 1.11;

use DBIx::Class::Schema::Diff::State;
use DBIx::Class::StateMigrations::SchemaState;
use DBIx::Class::StateMigrations::Migration;

sub BUILD {
  my $self = shift;
  try{$self->connected_schema->storage->connected} or die join('',
    'Supplied connected_schema "', $self->connected_schema, '" is not connected'
  );
}

sub load_migrations {
  my $self = shift;
  $self->_validate_Migrations
}

sub load_current_state {
  my $self = shift;
 $self->current_SchemaState
}

sub has_matched_migration { 
  my $self = shift;
  $self->matched_Migration ? 1 : 0
}

sub num_migrations { scalar(@{ (shift)->Migrations }) }
sub all_migrations { @{ (shift)->Migrations } }


sub execute_matched_Migration_routines {
  my $self = shift;
  my $callback = shift;
  
  my $Migration = $self->matched_Migration or die join('',
    'execute_matched_Migration(): no migration matched'
  );
  
  $Migration->execute_routines( $self->connected_schema, $callback )
}

has '__loaded_vagrant_classes', is => 'ro', isa => HashRef, default => sub {{}};


has 'migrations_dir', is => 'ro', default => sub { undef };
has 'connected_schema', is => 'ro', required => 1, isa => InstanceOf['DBIx::Class::Schema'];

has 'DBI_Driver_Name', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->connected_schema->storage->dbh->{Driver}{Name}
}, isa => Str;

has 'schema_class', is => 'ro', lazy => 1, init_arg => 1, default => sub {
  my $self = shift;
  blessed $self->connected_schema ? blessed $self->connected_schema : $self->connected_schema
};

has 'loader_options', is => 'ro', default => sub {{
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  use_moose => 0,
  debug => 0,
  qualify_objects => 1
}}, isa => HashRef;


has 'diff_filters', is => 'ro', default => sub {[
  filter_out => 'isa'
]}, isa => ArrayRef;


has 'Migrations', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  if(my $dir = $self->migrations_dir) {
    my $Dir = dir( $dir )->absolute;
    -d $Dir or die "migrations dir '$dir' not found or is not a directory";
    
    my @migrations = ();
    
    local $DBIx::Class::StateMigrations::Migration::LOADED_MIGRATION_SUBCLASSES = $self->__loaded_vagrant_classes;
    
    for my $m_dir ($Dir->children) {
      next unless $m_dir->is_dir;
      my $Migration = DBIx::Class::StateMigrations::Migration
        ->new_from_migration_dir($m_dir->absolute->stringify,$self->DBI_Driver_Name);
      push @migrations, $Migration if ($Migration);
    }
    return \@migrations;
  }
  else {
    return []
  }
}, isa => ArrayRef[InstanceOf[
  'DBIx::Class::StateMigrations::Migration',
  'DBIx::Class::StateMigrations::Migration::Invalid'
]];

sub _validate_Migrations {
  my $self = shift;
  
  my (@good,@warns,@dies);
  my @all = $self->all_migrations;

  for (@all) {
    ! $_->invalid ? push(@good, $_) :
    ! $_->fatal   ? push(@warns,$_) : 
                    push(@dies, $_)
  }
  
  my %num = (
    all   => scalar(@all),
    good  => scalar(@good),
    warns => scalar(@warns),
    dies  => scalar(@dies)
  );
   
  die join("\n",'',
    "   *** Attempted to load $num{all} Migrations:",
    "       - $num{good} loaded.",
    "       - $num{warns} not loaded but ignored" . ($num{warns} ? ':'.join("\n",'',
                map { "          * ".$_->reason } @warns) : ()),
    "       - $num{dies} not loaded due to fatal errors:",
                 ( map { "          * ".$_->reason } @dies ),'','',''
  ) if ($num{dies});
  
  if ($num{warns}) {
    warn join("\n",
      "    *** Ignoring $num{warns} of the $num{all} total identified Migrations:",
       (map { "        - ".$_->reason } @warns),'',
    );
    @{$self->Migrations} = @good;
  }
  
  return 1;
}


sub matched_and_executed {
  my $self = shift;
  $self->matched_Migration and $self->matched_Migration->routines_executed
}


has 'matched_Migration', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  $self->_validate_Migrations;
  
  my @matches = ();
  
  for my $Migration (@{ $self->Migrations }) {
    push @matches, $Migration if (
      $Migration->matches_SchemaState( $self->current_SchemaState )
    );
  }
  
  my $match_count = scalar(@matches);
  
  die join('',
    "ERROR: $match_count loaded Migrations ",
    "(",join(',',map { $_->migration_name } @matches),") ",
    "matched the current_SchemaState. This is a bug - only one Migration should match"
  ) if ($match_count > 1);
  
  return $match_count == 1 ? $matches[0] : undef

}, isa => Maybe[InstanceOf['DBIx::Class::StateMigrations::Migration']];


has 'connect_info_args', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->connected_schema->storage->connect_info
}, isa => Ref;

has 'loaded_schema_class', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $schema_class = $self->schema_class || 'ScannedSchmeaForMigration';
  
  my $ref_class = join('_',$schema_class,'RefSchema',String::Random->new->randregex('[a-z0-9A-Z]{5}'));
  
  DBIx::Class::Schema::Loader::make_schema_at(
    $ref_class => $self->loader_options, $self->connect_info_args  
  ) or die "Loading schema failed";
  
  $self->__loaded_vagrant_classes->{$ref_class}++;

  $ref_class
}, isa => Str;



has 'current_SchemaState', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $State = DBIx::Class::Schema::Diff->state(
    schema => $self->loaded_schema_class
  );
  
  DBIx::Class::StateMigrations::SchemaState->new(
    DiffState    => $State,
    diff_filters => $self->diff_filters
  )
}, isa => InstanceOf['DBIx::Class::StateMigrations::SchemaState'];


sub create_dump_blank_Migration {
  my $self = shift;
  
  die join('',
    "create_dump_blank_Migration(): ERROR! An existing Migration already ",
    "matched for the current SchemaState. This option is only avaialable when ",
    "there are no matches to make it easy to start a new Migration"
  ) if ($self->matched_Migration);
  
  die join('',
    "create_dump_blank_Migration(): Only available when using 'migrations_dir'"
  ) unless ($self->migrations_dir);
  
  my $Dir = dir( $self->migrations_dir )->absolute;
  
  
  die join('',
    "create_dump_blank_Migration(): 'migrations_dir' is set to '$Dir' but does not exist. ",
    "Please run: mkdir -p $Dir and try again"
  ) unless (-e $Dir);
  
  die join('',
    "create_dump_blank_Migration(): 'migrations_dir' '$Dir' exists but is not a directory" 
  ) unless (-d $Dir);
  
  my $new_name = 'auto_' . $self->current_SchemaState->fingerprint;
  
  my $BlankMigration = DBIx::Class::StateMigrations::Migration->new(
    migration_name => $new_name,
    trigger_SchemaStates => [$self->current_SchemaState],
    DBI_Driver_Name => $self->DBI_Driver_Name
  );
  
  my $new_dir = dir( $Dir, $new_name )->absolute;
  
  die join('',
    "create_dump_blank_Migration(): New dir '$new_dir' already exists!"
  ) if (-e $new_dir);
  
  $new_dir->mkpath(1);
  
  $BlankMigration->write_subclass_pm_file( "$new_dir" );
  
  my $rDir = dir( $new_dir, 'routines' );
  
  $rDir->mkpath(1);
  
  my $README = q~## This file was auto-generated by ~ . __PACKAGE__ . " v$VERSION ##\n" . q~
Put the "routines" in this directory (routines/) for this migration. Routines are simple
SQL (*.sql) or Perl (*.pl) scripts which will be executed in sort-order. SQL scripts are
simple, raw SQL files to run on the db, while Perl scripts should eval to return a CodeRef
which will be called with the first argument containing the connected DBIx::Class::Schema
object instance. Files which do not end with *.sql or *.pl are ignored.

For more information, see the online documentation for StateMigrations:

  * https://metacpan.org/pod/DBIx::Class::StateMigrations
  
  ~;
  
  file( $rDir, 'README.txt' )->spew( $README );
}



sub DEMOLISH {
  my ($self, $gd) = @_;
  
  # "global destruction" meaning the program is terminating and in that case we
  # don't need to do any of this, and worse, it could cause problems (thanks mst)
  return if $gd; 

  # Clean up after ourselves. We have to handle additional things beyond normal
  # object instances which clean themselves up automatically because we have 
  # created/loaded new classes and packages dynamically during the course of
  # our normal function of operation, and these have no validity beyond our
  # scope, and some of them could be quite large, so we want to get rid of them
  
  # Throughout our lifecycle we've been tracking all the dynamically generated 
  # packages/classes in this hashref:
  my @classes = keys %{ $self->__loaded_vagrant_classes };
  
  # This is very agressive but I can't think of any downsides - blow away
  # the entire object leaveing it as a blessed empty HashRef. This is so
  # all the objects, such as Migration class object instances, will get 
  # garbage collected now, so we can then safely and cleanly unload the 
  # actual classes and not have to worry about any instances existing
  %$self = (); 
  
  # and now unload the dynamic/migration classes by hand as our final act:
  
  for (@classes) {
    if (Class::Inspector->loaded( $_ )) {
      #warn " >>> Vagrant class $_ is loaded\n";
      Class::Unload->unload( $_ ) 
        #? warn "  >> unloaded $_ \n"
        #: warn "  >> FAILED to unload $_ \n";
    }
    else {
      #warn " >>> Vagrant class $_ is not loaded\n";
    }
  }
}


1;

__END__

=head1 NAME

DBIx::Class::Schema::StateMigrations - Schema migrations via checksums instead of versions

=head1 SYNOPSIS

 use DBIx::Class::Schema::StateMigrations;
 
 ...
 

=head1 DESCRIPTION

EXPERIMENTAL - not ready for production use yet

This is module serves essentially the same purpose as L<DBIx::Class::DeploymentHandler> except it
uses checksums generated from the actual current state of the schema to identify the current 
"version" and what migration scripts should be ran for that version, rather than relying on a
declared version number value which is subject to human error.

=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIx::Class>

=item *

L<DBIx::Class::DeploymentHandler>

=item * 

L<DBIx::Class::Migrations>

=item * 

L<DBIx::Class::Schema::Versioned>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


