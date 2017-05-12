package MyCMS::Controller::Foo;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( CatalystX::CMS::Controller );

__PACKAGE__->config(
    cms => { use_editor => 0 },    # ignored. just to test config merge
    action_class_per_action => 1,
);

sub bar : Local ActionClass('CMS') {
    my ( $self, $c, @arg ) = @_;
}
