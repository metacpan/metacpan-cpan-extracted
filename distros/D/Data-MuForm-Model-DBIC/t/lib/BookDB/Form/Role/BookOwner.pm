package BookDB::Form::BookOwner;

use Moo::Role;
use Data::MuForm::Meta;

has_field 'user_name';
has_field 'fav_cat' => ( label => 'Favorite Book Category' );
has_field 'fav_book' => ( label => 'Favorite Book' );
has_field 'occupation';
has_field 'country' => ( type => 'Select' );

sub validate_occupation
{
   my ( $self, $field ) = @_;
   if ( $field->value eq 'layabout' )
   {
      $field->add_error('No layabouts allowed');
   }
}

1;
