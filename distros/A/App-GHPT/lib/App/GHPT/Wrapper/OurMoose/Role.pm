package App::GHPT::Wrapper::OurMoose::Role;

use App::GHPT::Wrapper::Ourperl;

our $VERSION = '1.000008';

use Import::Into;
use Moose::Exporter;
use Moose::Role                    ();
use MooseX::SemiAffordanceAccessor ();
use namespace::autoclean           ();

my ($import) = Moose::Exporter->setup_import_methods(
    install => [ 'unimport', 'init_meta' ],
    also    => ['Moose::Role'],
);

sub import {
    my $for_role = caller();

    $import->( undef, { into => $for_role } );
    MooseX::SemiAffordanceAccessor->import( { into => $for_role } );

    my $caller_level = 1;
    App::GHPT::Wrapper::Ourperl->import::into($caller_level);
    namespace::autoclean->import::into($caller_level);
}

1;
