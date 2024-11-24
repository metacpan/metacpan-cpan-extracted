# App::hopen::G::AssetOp - parent class for operations used by a
# generator to build an asset
package App::hopen::G::AssetOp;
use strict; use warnings;
use Data::Hopen::Base;
use Quote::Code;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::Cmd';
    # TODO why is this not directly a child of Data::Hopen::G::Op?
    # It uses input_assets, but could that be refactored out to a parent
    # of which this and AhG::Cmd were siblings?

# we use Class::Tiny below

use Class::Tiny::ConstrainedAccessor
    asset => [ sub { eval { $_[0]->DOES('App::hopen::Asset') } },
                sub { qc'{$_[0]//"<undef>"} is not an App::hopen::Asset or subclass' } ];

use Class::Tiny qw(asset), {
    how => undef,
};

use App::hopen::Asset;
use Data::Hopen::Util::Data qw(forward_opts);

# Docs

=head1 NAME

App::hopen::G::AssetOp - parent class for operations used by a generator to build an asset

=head1 SYNOPSIS

This is an abstract class.  Each generator implements its own subclass of
AssetOp for its own use.

=head1 ATTRIBUTES

=head2 asset

An L<App::hopen::Asset> instance.

=head2 how

If defined, a string suitable as input to C<sprinti> in L<String::Print>.

TODO or a different formatter?

TODO? require that format specifications call a specified modifier that
will quote file names for shell-specific command-line use.

=cut

sub _run { ... }

1;
__END__
# vi: set fdm=marker: #
