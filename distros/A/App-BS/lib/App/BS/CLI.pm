use Object::Pad ':experimental(:all)';

package App::BS::CLI;

class App::BS::CLI : isa(App::BS) : does(App::BS::Common)
  : does(BS::alpm);

use utf8;
use v5.40;

use Carp;
use Pod::Usage;
use Const::Fast;
use Data::Dumper;
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev permute bundling);

const our $S_MULTI_BAREARG => "Two bare argument handlers are defined. Please"
  . " remove either 'getopts->{\"<>\"}' or 'handle_bareargs' in 'new'.";

field $bareargs : param(argv) : mutator(argv);
field $handle_bareargs : param = undef;

ADJUSTPARAMS($params) {
    my @handle_bareargs_arr;
    my $has_bareargs_handler = 0;

    if ( $handle_bareargs && ref $handle_bareargs eq 'CODE' ) {
        push @handle_bareargs_arr, $handle_bareargs;
    }

    if ( $self->DOES('App::BS::CLI::Barearg') ) {
        push @handle_bareargs_arr, sub { $self->handle_barearg(@_) }
    }

    my @_getopts_processed = ();

    foreach my ( $name, $val ) ( $self->getopts_setup->@* ) {
        if ( $name eq '<>' && ref $val eq 'CODE' ) {
            push @handle_bareargs_arr, sub { $self->handle_barearg(@_) };
            last;
        }

        push @_getopts_processed, grep { $_ } $name, $val;
    }

    my $bareword_handler = sub ($arg) {
        foreach my $handler (@handle_bareargs_arr) {
            last if $handler->($arg);
        }
    };

    GetOptionsFromArray(
        $self->argv, $self->cliopts, @_getopts_processed,
        '<>', $bareword_handler,
        "debug+",
        "version" => sub { Getopt::Long::VersionMessage(@_) },
        "help"    => sub { Getopt::Long::HelpMessage(@_) }
    )
}
