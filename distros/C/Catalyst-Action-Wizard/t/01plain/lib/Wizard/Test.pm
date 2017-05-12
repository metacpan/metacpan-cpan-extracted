#
#===============================================================================
#
#         FILE:  TestApp.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  03.07.2008 05:12:27 MSD
#     REVISION:  ---
#===============================================================================

package Wizard::Test;

use strict;
use warnings;

use Test::More;

use Carp qw/cluck/;
use Data::Dumper;
our $label_lines = [];

sub _get_label_lines {
    my $filename = shift;

    open my $fh, '<', $filename or die;
    my @strings = <$fh>;
    close $fh;

    my $i = 1;
    foreach (@strings) {
	unshift @$label_lines, $i if /->(?:add|append)_step/;
	$i++;
    }
}

sub import {
    my @caller = caller;

    shift;

    _get_label_lines( $caller[1] ) if ! $_[0] || $_[0] ne 'nolabel';

    my $package = $caller[0];

    {
	no strict 'refs';

	*{$package.'::get_caller'} = 
	    sub {
		'main:'.$caller[1].':'.pop @$label_lines;
	    } if ! $_[0] || $_[0] ne 'nolabel';

	*{$package.'::add_expected'} = \&add_expected;

	*{$package.'::check_expected'} = \&check_expected;
    }

};

my @expected;

sub add_expected {
    push @expected, {
	function => shift,
	(!$_[0] || $_[0] ne 'noargs') ? (args => [ @_ ]) : (),
    };
}

sub check_expected {
    my $function = (caller(1))[3];

    my $expect = shift @expected;

    Carp::cluck if $ENV{CHECK_EXPECTED_DEBUG};

    no warnings 'redefine';
    local $Test::Builder::Level = $Test::Builder::Level + 3;

    Test::More::is( $function, $expect->{function}, "$function call expected" );
    Test::More::is_deeply( \@_, $expect->{args}, "$function call args") 
	if $expect->{args};
}

package TestApp;

use Wizard::Test qw/nolabel/;
use Data::Dumper;

our ($response, $request);

sub wizard_storage {
    check_expected(@_);
    #warn Dumper(\@_);
    my $c	  = shift;
    my $wizard_id = shift;

    if ($wizard_id eq 'current') {
	$main::current_wizard = shift if @_;

	return $main::current_wizard;
    }

    return $main::wizards->{ $wizard_id } unless @_;

    my $wizard = shift;
    delete $c->stash->{wizard};
    return $wizard if $wizard->{loaded_from_storage};

    $main::wizards->{ $wizard_id } = $wizard;
}

sub new {
    return bless {}, __PACKAGE__;
}

sub request {
    $request ||= PseudoCatalyst::Request->new;
}

sub req {
    shift->request;
}

sub response {
    $response ||= PseudoCatalyst::Response->new;
}

sub stash {
    $main::stash;
}

sub detach {
    shift;
    check_expected( @_ );
}

sub action {
    +{}
}


package PseudoController;

use Wizard::Test qw/nolabel/;

sub new {
    return bless {}, __PACKAGE__;
}

package PseudoCatalyst::Response;

use Wizard::Test qw/nolabel/;

sub redirect {
    shift;
    check_expected(@_);
}

sub new {
    return bless {}, __PACKAGE__;
}

package PseudoCatalyst::Request;

use Wizard::Test qw/nolabel/;

sub new {
    return bless {}, __PACKAGE__;
}

sub params {
    +{};
}

1;
