package App::GHPT::Wrapper::OurTest::Class::Moose;

use Moose::Exporter;
use MooseX::SemiAffordanceAccessor ();
use MooseX::StrictConstructor      ();

use App::GHPT::Wrapper::Ourperl;

use Import::Into;
use Test::Class::Moose 0.82 ();
use Test::Class::Moose::AttributeRegistry ();
use Test::More;
use namespace::autoclean ();

sub import {
    my $for_class = caller();

    my $caller_level = 1;
    Test::Class::Moose->import::into($caller_level);

    MooseX::SemiAffordanceAccessor->import( { into => $for_class } );
    MooseX::StrictConstructor->import( { into => $for_class } );

    App::GHPT::Wrapper::Ourperl->import::into($caller_level);
    namespace::autoclean->import::into($caller_level);
}

1;
