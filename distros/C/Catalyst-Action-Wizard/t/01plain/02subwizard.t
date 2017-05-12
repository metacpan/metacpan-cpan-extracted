#
#===============================================================================
#
#         FILE:  01subwizard.t
#
#  DESCRIPTION:  Catalyst::Wizard subwizard test
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  07.07.2008 19:06
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use lib qw(t/01plain/lib);

use Test::More tests => 7;

use Catalyst::Wizard;
use Data::Dumper;

use Digest::MD5 qw(md5_hex);

use Wizard::Test qw/nolabel/;

Wizard::Test::_get_label_lines($INC{'Catalyst/Wizard.pm'});

# skip ->add_steps in doc
@$Wizard::Test::label_lines = @$Wizard::Test::label_lines[0,1];

sub get_caller {
    'Catalyst::Wizard:'.$INC{'Catalyst/Wizard.pm'}.':'.
	(pop @$Wizard::Test::label_lines);
}

my $load_wizard = md5_hex(time);
our $wizards = { $load_wizard => bless { wizard_id => $load_wizard }, 'Catalyst::Wizard', };
our $current_wizard;
our $stash = {};

$Data::Dumper::Indent = 1;

my $c = TestApp->new;

add_expected('TestApp::wizard_storage', 'noargs');
Catalyst::Wizard->new($c, $load_wizard);

$wizards = {};

my $new_wizard = Catalyst::Wizard->new( $c );

$new_wizard->add_steps('-sub' => [ '/testme' ], -redirect => '/pleasetestme' );

add_expected('TestApp::wizard_storage', 
    $c, $new_wizard->{wizard_id}, $new_wizard); # in save of current wizard in _make_sub_wizard
add_expected('TestApp::wizard_storage', 'noargs'); # in _current_wizard
add_expected('PseudoCatalyst::Response::redirect', 'noargs');
add_expected('TestApp::wizard_storage', 'noargs'); # save in _make_sub_wizard after ->perform_step
eval { $new_wizard->goto_next };
$new_wizard->perform_step( $c );

my ($sub_wizard_id) = grep $_ ne $new_wizard->{wizard_id}, keys %$wizards;

is_deeply( $wizards->{$sub_wizard_id},
    {
	'steps' => [
	    {
		'append_wizard_id' => 1,
		'step_type' => '-redirect',
		'caller' => get_caller,
		'path' => '/testme'
	    },
	    {
		'append_wizard_id' => '',
		'step_type' => '-redirect',
		'caller' => get_caller,
		'last'	=> 1,
		'path' => '/pleasetestme?wid='.
		$new_wizard->{wizard_id}.'_2'
	    }
	],
	'no_add_step' => 0,
	'no_step_back'=> 0,
	'stash' => {},
	'step_number' => 0,
	'steps_already_in_wizard' => 
	    $wizards->{$sub_wizard_id}{steps_already_in_wizard},
	'wizard_id' => $sub_wizard_id,
	'have_last_step' => 1,
    }
    , "total subwizard's step check"
);
