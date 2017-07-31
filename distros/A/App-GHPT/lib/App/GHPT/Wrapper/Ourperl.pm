## no critic (NamingConventions::Capitalization)
package App::GHPT::Wrapper::Ourperl;
## use critic (NamingConventions::Capitalization)

use strict;
use warnings;

our $VERSION = '1.000008';

use Import::Into;

# XXX - it'd be nice to include bareword::filehandles but this conflicts with
# autodie - see https://rt.cpan.org/Ticket/Display.html?id=93591
use autodie 2.25 ();
use IPC::System::Simple;    # to fatalize system
use experimental     ();
use feature          ();
use indirect         ();
use mro              ();
use multidimensional ();

# This adds the UTF-8 layer on STDIN, STDOUT, STDERR for _everyone_
use open qw( :encoding(UTF-8) :std );
use utf8 ();

sub import {
    my $caller_level = 1;

    strict->import::into($caller_level);
    warnings->import::into($caller_level);

    my @experiments = qw(
        lexical_subs
        postderef
        signatures
    );
    experimental->import::into( $caller_level, @experiments );

    my ($version) = $^V =~ /^v(5\.\d+)/;
    feature->import::into( $caller_level, ':' . $version );
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    mro::set_mro( scalar caller(), 'c3' );
    ## use critic
    utf8->import::into($caller_level);

    indirect->unimport::out_of( $caller_level, ':fatal' );
    multidimensional->unimport::out_of($caller_level);
    'open'->import::into( $caller_level, ':encoding(UTF-8)' );
    autodie->import::into( $caller_level, ':all' );
}

1;

=pod

=head1 NAME

App::GHPT::Wrapper::Ourperl - Loads strict, warnings, and several other pragmas

=head1 DESCRIPTION

Using this wrapper is equivalent to the following:

    use strict;
    use warnings;
    use feature vX.XX; # where the version is equal to the perl binary's version

    use autodie ':all';
    use mro 'c3';
    use open ':encoding(UTF-8)', ':std';
    use utf8;

    no indirect ':fatal';
    no multidimensional;

=cut
