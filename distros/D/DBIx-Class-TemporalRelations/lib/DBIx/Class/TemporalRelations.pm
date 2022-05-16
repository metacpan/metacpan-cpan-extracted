package DBIx::Class::TemporalRelations;
use Modern::Perl;
our $VERSION = '0.9000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Establish and introspect time-based relationships between tables.
use Carp qw(carp croak);

use parent 'DBIx::Class::Relationship::Base';
use DBIx::Class::Candy::Exports;
use Lingua::EN::Inflexion;
use Sub::Quote qw(quote_sub);

# Exports for DBIx::Class::Candy
export_methods [qw/make_temporal_relationship make_temporal_relationships/];

sub make_temporal_relationships {
   my ( $self, %relationships ) = @_;
   foreach my $verb ( keys %relationships ) {
      my $params = $relationships{$verb};
      $params = [$params] if ( ref $params->[0] ne 'ARRAY' );
      foreach my $temporal_ar (@$params) {
         $self->make_temporal_relationship( $verb, $temporal_ar );
      }
   }
}

sub make_temporal_relationship {
   my ( $self, $verb, @args ) = @_;
   @args = @{ $args[0] } if ref $args[0] eq 'ARRAY';
   my $info  = $self->source_info();
   my $table = $args[0];
   $info->{temporal_relationships} //= {};
   $info->{temporal_relationships}->{$table} //= [];
   push @{ $info->{temporal_relationships}->{$table} },
       {
      temporal_column => $args[1],
      verb            => $verb,
      singular        => $args[2],
      plural          => $args[3],
       };

   $self->source_info($info);
}

sub new {
   my ( $class, $attrs ) = @_;
   my $new = $class->next::method($attrs);
   $new->_register_temporal_methods();
   return $new;
}

sub _inflect_nouns {
   my ( $class, $noun, $verb ) = @_;
   ($noun) = split /_/, $noun;
   if ( noun($noun)->is_plural ) {
      return ( noun($noun)->singular, $noun );
   }
   return ( $noun, noun($noun)->plural );
}

sub _register_temporal_methods {
   my $class         = shift;
   my $relationships = $class->source_info->{temporal_relationships};

   my $classname = ref $class;
   foreach my $rel ( keys %$relationships ) {
      foreach my $temporal ( @{ $relationships->{$rel} } ) {
         my $verb   = $temporal->{verb};
         my $column = $temporal->{temporal_column};

         my ( $singular, $plural ) = $class->_inflect_nouns( $rel, $verb );
         my $singular_term = $temporal->{singular} // $singular;
         my $plural_term   = $temporal->{plural}   // $plural;

         # NV:@things = $user->things_created;
         quote_sub "$classname\:\:$plural_term" . "_$verb", qq/
            my \$class=shift;
            return \$class->$rel->search({$column => {'!=' => undef }},
            { order_by => "$column"});
         /, { '$rel' => \$rel, '$column' => \$column };
         # NVB:@things = $user->things_created_before($ts);
         quote_sub "$classname\:\:$plural_term" . "_$verb".'_before', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '<', \$ts }},
             { order_by => "$column"});
         /, { '$rel' => \$rel, '$column' => \$column };
         # NVA:@things = $user->things_created_after($ts);
         quote_sub "$classname\:\:$plural_term" . "_$verb".'_after', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '>', \$ts }},
             { order_by => "$column"});
         /, { '$rel' => \$rel, '$column' => \$column };
         # NVX:@things = $user->things_created_between($ts1, $ts2);
         quote_sub "$classname\:\:$plural_term" . "_$verb".'_between', qq/
            my (\$class, \$start_ts, \$end_ts) = \@_;
            return \$class->$rel->search(
               {$column => {'!=', undef, '>', \$start_ts, '<', \$end_ts}},
               { order_by => "$column"});
         /, { '$rel' => \$rel, '$column' => \$column };
         # RNV:@things = $user->most_recent_things_created;
         quote_sub "$classname\:\:most_recent_$plural_term" . "_$verb", qq/
            my \$class=shift;
            return \$class->$rel->search({$column => {'!=' => undef }},
            { order_by => { -desc => "$column"}});
         /, { '$rel' => \$rel, '$column' => \$column };
         # RNVB:@things = $user->most_recent_things_created_before($ts);
         quote_sub "$classname\:\:most_recent_$plural_term" . "_$verb".'_before', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '<', \$ts }},
             { order_by => { -desc => "$column"}});
         /, { '$rel' => \$rel, '$column' => \$column };         
         # RNVA:@things = $user->most_recent_things_created_after($ts);
         quote_sub "$classname\:\:most_recent_$plural_term" . "_$verb".'_after', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '>', \$ts }},
             { order_by => { -desc => "$column"}});
         /, { '$rel' => \$rel, '$column' => \$column };
         # RNVX:@things = $user->most_recent_things_created_between($ts1, $ts2);
         quote_sub "$classname\:\:most_recent_$plural_term" . "_$verb".'_between', qq/
            my (\$class, \$start_ts, \$end_ts) = \@_;
            return \$class->$rel->search(
               {$column => {'!=', undef, '>', \$start_ts, '<', \$end_ts}},
               { order_by => { -desc => "$column"}});
         /, { '$rel' => \$rel, '$column' => \$column };
         # FNV:$thing = $user->first_thing_created;
         quote_sub "$classname\:\:first_$singular_term" . "_$verb", qq/
            my \$class=shift;
            return \$class->$rel->search({$column => {'!=' => undef }},
            { order_by => "$column"})->first();
         /, { '$rel' => \$rel, '$column' => \$column };
         # LNV:$thing = $user->last_thing_created;
         quote_sub "$classname\:\:last_$singular_term" . "_$verb", qq/
            my \$class=shift;
            return \$class->$rel->search({$column => {'!=' => undef }},
            { order_by => { -desc => "$column"}})->first();
         /, { '$rel' => \$rel, '$column' => \$column };
         # FNVA:$thing = $user->first_thing_created_after($ts);
         quote_sub "$classname\:\:first_$singular_term" . "_$verb".'_after', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '>', \$ts }},
             { order_by => "$column"})->first();
         /, { '$rel' => \$rel, '$column' => \$column };
         # LNVB:$thing = $user->last_thing_created_before($ts);
         quote_sub "$classname\:\:last_$singular_term" . "_$verb".'_before', qq/
            my (\$class, \$ts) = \@_;
            return \$class->$rel->search({$column => {'!=', undef, '<', \$ts }},
             { order_by => { -desc => "$column"}})->first();
         /, { '$rel' => \$rel, '$column' => \$column };         
      }
   }
   return;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::TemporalRelations - Establish and introspect time-based relationships between tables.

=head1 VERSION

version 0.9000

=head1 SYNOPSIS

   package My::Schema::Result::Person;
   
   use parent qw(DBIx::Class::Core);
   __PACKAGE__->load_components('TemporalRelations');
   
   # or, if you're a Candy user:
   use DBIx::Class::Candy -components => [qw/TemporalRelations/];
   
   
   # Normally, you would choose one way of doing this, for the entire table.
   # But we're doing this to show that you can do it any way you like.
   
   # Direct injection into source_info
   __PACKAGE__->source_info(
      {
         temporal_relationships => {
            'contraptions' => [
               { verb => 'purchased', temporal_column => 'purchase_dt' }
            ]
         }
      }
   );
   
   # Direct single relationship method
   __PACKAGE__->make_temporal_relationship( 'created', 'doodads', 'created_dt' );

   # Make a whole bunch at once!
   __PACKAGE__->make_temporal_relationships(
      'modified'  => [
          [ 'doodads', 'modified_dt' ],
          [ 'doohickies_modified', 'modified_dt' ], ],
      'purchased' => [ 'doohickies_purchased', 'purchased_dt' ],
   );
   
   # Later code:
   use My::Schema;

   ...

   # There can be only one!
   my $person = $schema->resultset('Person')->find({ name => 'D Ruth Holloway'});
   my @doodads_she_modified = $person->doodads_modified;  # Doodad rows
   my $first_doodad = $person->first_doodad_created;  # Doodad row or undef
   my @doohickies = $person->doohickies_modified;  # Doohickey rows

=head1 DESCRIPTION

This module sets up some convenience methods describing temporal relationships between
data elements. A fairly-common construct would be to have a table of users, who are
creating things, and we want to see lists of the things that they created, in a time
order. In SQL, this might be:

   SELECT id, serial_number, created_dt 
   FROM thing 
   WHERE creator = (SELECT id FROM user WHERE username = 'geekruthie')
   ORDER BY created_dt;

And in conventional L<DBIx::Class> parlance:

   $schema->resultset('User')->find({ username => 'geekruthie'} )->things
      ->search({},{ order_by => 'created_dt'});

Easy enough, but with this module, you can do some more things that would require a bit more yak-shaving:

   my $user = $schema->resultset('User')->find({username => 'geekruthie'});
   @things = $user->things_created;
   @things = $user->things_created_before($ts);
   @things = $user->things_created_after($ts);

These methods let you order things in reverse-date order:

   @things = $user->most_recent_things_created;
   @things = $user->most_recent_things_created_before($ts);
   @things = $user->most_recent_things_created_after($ts);

...and let's pick a specific thing, shall we?

   $thing = $user->first_thing_created;
   $thing = $user->last_thing_created;
   $thing = $user->first_thing_created_after($ts);
   $thing = $user->last_thing_created_before($ts);

And if you could also B<modify> things, and stashed the last time the thing was modified, and by whom, in the
C<thing> table:

   @thing = $user->things_modified;
   $thing = $user->last_thing_modified;

(...but see L</BUGS AND LIMITATIONS> for an important limitation on this behavior!)

=head1 CONFIGURATION

In your Result class, once you've loaded this component, you have three ways to 
add temporal relationships:

=head2 Direct injection into C<source_info>

   __PACKAGE__->source_info(
      {
         temporal_relationships =>
            { 'contraptions' => [ { verb => 'purchased', temporal_column => 'purchase_dt' } ] }
      }
   );

The C<temporal_relationships> sub-hash of C<source_info> can be manually populated. It is a
hashref, defined thusly:

   {  '<relationship accessor>' => [
         { verb => '<desired_verb>',                               # mandatory
           temporal_column => '<column_name_to_use_for_ordering>', # mandatory
           singular => '<singular_noun>',                          # optional
           plural => '<plural_noun>'                               # optional 
         },
      ...],
   ...}

If you do not specify the C<singular> or C<plural> terms, they will be inflected from
the C<relationship_accessor>.

=head2 Single method call

   __PACKAGE__->make_temporal_relationship(
      '<desired_verb>',                    # mandatory
      '<relationship_accessor>',           # mandatory
      '<column_name_to_use_for_ordering>', # mandatory
      '<singular_noun>'                    # optional
      '<plural_noun>'                      # optional
   );

=head2 Multiple-relationship method call

   __PACKAGE__->make_temporal_relationships(
     '<desired_verb>'  => [
         [ '<relationship_accessor>',          # mandatory
           '<column_name_to_use_for_ordering>' # mandatory
           '<singular_noun>'                   # optional
           '<plural_noun>'                     # optional
         ], [...]
      ],
      ...
   );

=head1 DEPENDENCIES

=over 4

=item L<DBIx::Class>

=item Optionally, L<DBIx::Class::Candy>

=item L<Lingua::EN::Inflexion>

=item L<Sub::Quote>

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item Overwriteable fields

If you set a temporal relationship on a field that can be overwritten, for example C<modified_by>, realize
that the temporal relationship will disappear. This isn't a full activity log! For that, you probably want
something like L<DBIx::Class::AuditAny> or other similar journaling module.

=back

=head1 ACKNOWLEDGEMENTS

Thanks goes out to my employer, Clearbuilt, for letting me spend some work time on this module.

Blame goes to L<Jason Crome|https://metacpan.org/author/CROMEDOME> for encouraging me in this sort of madness.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
