package # Hide from PAUSE
  TestApp::DBIC::ResultSet::User;

use strict;
use warnings;

use base 'TestApp::DBIC::ResultSet';

sub find {
    my $self = shift @_;
    my $result = $self->next::method(@_);
    if($result) {
        if(
          $result->user_id == 104 || 
          $result->user_id eq '104'
        ) {
            die 'BOO!';
        }
    }
    return $result;
}


1;
