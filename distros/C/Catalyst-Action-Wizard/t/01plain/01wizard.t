#
#===============================================================================
#
#         FILE:  01wizard.t
#
#  DESCRIPTION:  Catalyst::Wizard test
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  22.06.2008 14:15:34 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use lib qw(t/01plain/lib);

use Test::More tests => 18;

use Catalyst::Wizard;
use Data::Dumper;

use Digest::MD5 qw(md5_hex);

use Wizard::Test;

our $label_lines;


my $load_wizard = md5_hex(time);
our $wizards = { $load_wizard => bless { wizard_id => $load_wizard }, 'Catalyst::Wizard', };
our $current_wizard;
our $stash = {};

$Data::Dumper::Indent = 1;

my $c = TestApp->new;

add_expected('TestApp::wizard_storage', 'noargs');
Catalyst::Wizard->new($c, $load_wizard);



my $new_wizard = Catalyst::Wizard->new($c, 'new');

my $i = 0;

$new_wizard->add_steps( -detach => '/testmeplease' ) while($i++ < 10);

is( scalar @{$new_wizard->{steps}}, 1, 'Doest not append duplicate actions');

is_deeply( $new_wizard->{steps},
    [
	{
	    step_type	=> '-detach',
	    path	=> '/testmeplease',
	    caller	=> get_caller,
	}
    ],
    'steps ok'
);

is_deeply( $new_wizard->_step,
    $new_wizard->{steps}[0],
    'step ok'
);

$new_wizard->next_step;
$new_wizard->add_steps( -redirect => '/testmeanothertime' );

is_deeply( $new_wizard->{steps}[1],
    {
	step_type	    => '-redirect',
	path		    => '/testmeanothertime',
	caller	=> get_caller,
	append_wizard_id    => '',
    },
    'step ok'
);

is_deeply( $new_wizard->_step,
    $new_wizard->{steps}[1],
    'redirect step ok'
);


$new_wizard->next_step;
$new_wizard->add_steps( '/teeeest?testmeplease=ifeelmyself' );

add_expected(
    'PseudoCatalyst::Response::redirect', 
    '/teeeest?testmeplease=ifeelmyself&wid='.$new_wizard->{wizard_id}.'_3'
);

eval { $new_wizard->goto_next };
$new_wizard->perform_step( $c );

add_expected('TestApp::wizard_storage', 'noargs');
$new_wizard->save( $c );


$new_wizard = Catalyst::Wizard->new( $c, 'new' );
$new_wizard->load( $c );

$i = 0;
$new_wizard->add_steps( -force => -detach => '/testmeplease' ) while($i++ < 2);

is( @{ $new_wizard->{steps} }, 2, 'adding duplicate actions on force' );

is( ref $stash, 'HASH', 'wizard stash ok' );

$c->stash->{wizard}{testme} = 10;

add_expected('TestApp::wizard_storage', 'noargs');
$new_wizard->save($c);

is_deeply( { testme => 10 }, 
    $wizards->{ $new_wizard->{wizard_id} }{stash}, 'stash is ok');

add_expected('TestApp::wizard_storage', 'noargs');
$new_wizard = Catalyst::Wizard->new( $c, $new_wizard->{wizard_id} );

$c->stash->{wizard}{testme} = 20;
add_expected('TestApp::wizard_storage', 'noargs');
$new_wizard->save($c);
is( $new_wizard->{stash}{testme}, 20, 'stashed value for loaded from storage ok');


my $detach_to = [ '/detachtest', { login => 'vasya', password => 'pupkin' } ];
$new_wizard->add_steps( -detach => [ @$detach_to ] );

add_expected( 'TestApp::detach', $detach_to->[0], [ $detach_to->[1] ]);
eval { $new_wizard->goto_next };
$new_wizard->perform_step( $c );

#$self->info Dumper($stash);
