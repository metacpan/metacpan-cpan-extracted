package DBIx::Class::Schema::Journal::DB::ChangeSet;

use base 'DBIx::Class::Core';

sub journal_define_table {
    my ( $class, $schema_class, $prefix ) = @_;

    $class->load_components(qw/InflateColumn::DateTime/);
    $class->table($prefix . 'changeset');

    $class->add_columns(
      ID => {
         data_type => 'integer',
         is_auto_increment => 1,
         is_primary_key => 1,
         is_nullable => 0,
      },
      user_id => {
         data_type => 'integer',
         is_nullable => 1,
         is_foreign_key => 1,
      },
      set_date => {
         data_type => 'timestamp',
         is_nullable => 0,
      },
      session_id => {
         data_type => 'varchar',
         size => 255,
         is_nullable => 1,
      },
    );

    $class->set_primary_key('ID');
}

sub new {
    my $self = shift->next::method(@_);
    # I think we should not do the following and
    # instead use DBIx::Class::TimeStamp.  If I
    # can think of a good way (passing a version on
    # import?) to do it and retain backcompat I will.
    #
    # --fREW, 01-27-2010
    $self->set_date(scalar gmtime);
    return $self;
}

1;
