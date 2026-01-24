use 5.008003;
use strict;
use warnings;

package B::Hooks::AtRuntime::OnlyCoreDependencies;

use Sub::Util 'set_subname'; # not Sub::Name
use XSLoader;

our @EXPORT     = qw/ at_runtime /;
our @EXPORT_OK  = qw/ at_runtime after_runtime lex_stuff /;

# Don't depend on Exporter::Tiny; try to handle exporting
# internally. If @_ seems too complex, load Exporter or
# Exporter::Tiny, whichever seems to be necessary.
sub import {
    if ( @_ == 1 ) {
        my $caller = caller;
        no strict 'refs';
        *{"$caller\::at_runtime"} = \&at_runtime;
        return;
    }
    elsif ( grep ref||/^-/, @_ ) {
        require Exporter::Tiny;
        our @ISA = qw/ Exporter::Tiny /;
        no warnings 'redefine';
        *import = \&Exporter::Tiny::import;
        *unimport = \&Exporter::Tiny::unimport;
        goto \&Exporter::Tiny::import;
    }
    require Exporter;
    goto \&Exporter::import;
}

# Delay loading Carp too.
sub croak { require Carp; goto \&Carp::croak; }
sub carp  { require Carp; goto \&Carp::carp;  }

BEGIN {
    our $AUTHORITY = 'cpan:TOBYINK';
    our $VERSION   = '8.000001';
    __PACKAGE__->XSLoader::load( $VERSION );
}

# Also let's not load constant.pm.
BEGIN {
    my $USE_FILTER =
        defined $ENV{PERL_B_HOOKS_ATRUNTIME} 
            ? $ENV{PERL_B_HOOKS_ATRUNTIME} eq "filter"
            : not defined &lex_stuff;
    *USE_FILTER = $USE_FILTER ? sub(){!!1} : sub(){!!0};
};

if (USE_FILTER) {
    require Filter::Util::Call;

    no warnings "redefine";
    *lex_stuff = set_subname "lex_stuff", sub {
        my ($str) = @_;

        compiling_string_eval() and croak 
            "Can't stuff into a string eval";

        if (defined(my $extra = remaining_text())) {
            $extra =~ s/\n+\z//;
            carp "Extra text '$extra' after call to lex_stuff";
        }

        Filter::Util::Call::filter_add(sub {
            $_ = $str;
            Filter::Util::Call::filter_del();
            return 1;
        });
    };
}

my @Hooks;

sub replace_hooks {
    my ($new) = @_;

    delete $B::Hooks::AtRuntime::OnlyCoreDependencies::{hooks};

    no strict "refs";
    $new and *{"hooks"} = $new;
}

sub clear {
    my ($depth) = @_;
    $Hooks[$depth] = undef;
    replace_hooks $Hooks[$depth - 1];
}

sub find_hooks {
    my $func = shift || 'at_runtime';

    USE_FILTER and compiling_string_eval()
        and croak "Can't use $func from a string eval";

    my $depth = count_BEGINs()
        or croak "You must call $func at compile time";

    my $hk;
    unless ($hk = $Hooks[$depth]) {
        my @hooks;
        $hk = $Hooks[$depth] = \@hooks;
        replace_hooks $hk;
        my $pkg = __PACKAGE__;
        lex_stuff("${pkg}::run(\@${pkg}::hooks);BEGIN{${pkg}::clear($depth)}");
    }

    return $hk;
}

sub at_runtime (&) {
    my ($cv) = @_;
    my $hk = find_hooks('at_runtime');
    push @$hk, set_subname scalar(caller) . "::(at_runtime)", $cv;
}

sub after_runtime (&) {
    my ($cv) = @_;
    my $hk = find_hooks('after_runtime');
    push @$hk, \set_subname scalar(caller) . "::(after_runtime)", $cv;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

B::Hooks::AtRuntime::OnlyCoreDependencies - it is just B::Hooks::AtRuntime but with only core dependencies

=head1 DESCRIPTION

You probably want L<B::Hooks::AtRuntime>.

I just created this version because I didn't want dependencies on
L<Sub::Name>, L<Module::Build>, and L<Test::Exports>.

=head1 SEE ALSO

L<B::Hooks::AtRuntime>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>, though almost all the
code is directly taken from L<B::Hooks::AtRuntime> by
Ben Morrow E<lt>ben@morrow.me.ukE<gt>.

=head1 COPYRIGHT AND LICENCE

This distribution is available under the same terms as the
original L<B::Hooks::AtRuntime>.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

