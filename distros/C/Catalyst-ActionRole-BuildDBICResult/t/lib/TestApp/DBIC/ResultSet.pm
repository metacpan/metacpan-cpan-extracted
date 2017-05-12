package # Hide from PAUSE
  TestApp::DBIC::ResultSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub hri_dump {
    my $self = shift @_;
    $self->search ({}, {
		result_class => 'DBIx::Class::ResultClass::HashRefInflator'
	});
}

1;
