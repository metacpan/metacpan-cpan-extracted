# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
# more testing will be added later

use Test::More tests => 2;
use Wx qw(:everything);

BEGIN { use_ok( 'AAC::Pvoice' ); }

package MyApp;
use base 'Wx::App';

sub OnInit
{
    my $frame = MyFrame->new();
    return 1;
}

package MyFrame;
use base 'Wx::Frame';
sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(undef, -1, 'Test');
    my $panel = AAC::Pvoice::Panel->new ($self, -1);
    main::isa_ok ($panel, 'AAC::Pvoice::Panel');
    return $self;
}


package main;
my $obj = MyApp->new();
