package CLI::Popt;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

CLI::Popt - Parse CLI parameters via L<popt(3)>

=head1 SYNOPSIS

    my $popt = CLI::Popt->new(
        [

            # A simple boolean:
            {
                long_name => 'verbose',
            },

            # Customize the boolean’s truthy value:
            {
                long_name => 'gotta-be-me',
                type => 'val',
                val => 42,
            },
        ],
        name => $0,     # default; shown just for demonstration
    );

    my ($opts_hr, @leftovers) = $popt->parse(@ARGV);

=head1 DESCRIPTION

L<Getopt::Long> is nice, but its inability to auto-generate help & usage
text requires you to duplicate data between your code and your script’s
documentation.

L<popt(3)> remedies that problem. This module makes that solution available
to Perl.

=head1 CHARACTER ENCODING

All strings into & out of this library are byte strings. Please
decode/encode according to your application’s needs.

=cut

#----------------------------------------------------------------------

use Carp ();
use XSLoader;

use CLI::Popt::X ();

our $VERSION = '0.01';

XSLoader::load( __PACKAGE__, $VERSION );

my %type2num = (
    none     => POPT_ARG_NONE(),
    string   => POPT_ARG_STRING(),
    argv     => POPT_ARG_ARGV(),
    short    => POPT_ARG_SHORT(),
    int      => POPT_ARG_INT(),
    long     => POPT_ARG_LONG(),
    longlong => POPT_ARG_LONGLONG(),
    val      => POPT_ARG_VAL(),
    float    => POPT_ARG_FLOAT(),
    double   => POPT_ARG_DOUBLE(),
);

my %flag2num = (
    onedash    => POPT_ARGFLAG_ONEDASH(),
    doc_hidden => POPT_ARGFLAG_DOC_HIDDEN(),
    optional   => POPT_ARGFLAG_OPTIONAL(),
    default    => POPT_ARGFLAG_SHOW_DEFAULT(),
    random     => POPT_ARGFLAG_RANDOM(),
    toggle     => POPT_ARGFLAG_TOGGLE(),
    or         => POPT_ARGFLAG_OR(),
    and        => POPT_ARGFLAG_AND(),
    xor        => POPT_ARGFLAG_XOR(),
    not        => POPT_ARGFLAG_NOT(),
);

use constant _DEFAULT_TYPE => 'none';

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( \@OPTIONS, %EXTRA )

Instantiates I<CLASS>.

Each @OPTIONS member is a reference to a hash that describes an option
that the returned $obj will C<parse()> out:

=over

=item * C<long_name> (required)

=item * C<type> - optional; one of: C<none> (default), C<string>,
C<argv> (i.e., an array of strings), C<short>, C<int>, C<long>, C<longlong>,
C<float>, or C<double>

=item * C<short_name> - optional

=item * C<flags> - optional arrayref of C<onedash>, C<doc_hidden>,
C<optional>, C<show_default>, C<random>, and/or C<toggle>.

Numeric options may also include C<or>, C<and>, or C<xor>, and optionally
C<not>.

NB: not all flags make sense together; e.g., C<or> conflicts with C<xor>.

See L<popt(3)> for more information.

=item * C<descrip>, and C<arg_descrip> - optional, as described in
L<popt(3)>.

=back

%EXTRA is:

=over

=item * C<name> - defaults to Perl’s C<$0>. Give empty string
to leave this unset.

=back

=cut

sub new {
    my ( $class, $opts_ar, %extra ) = @_;

    if ( !defined $extra{'name'} ) {
        $extra{'name'} = $0;
    }

    my @opts;

    my %seen;

    for my $opt_hr ( @$opts_ar ) {
        my %copy = %$opt_hr;

        my $type = $copy{'type'} || _DEFAULT_TYPE;

        my $arginfo = $type2num{$type};
        if ( !defined $arginfo ) {
            Carp::croak("Bad type: $copy{'type'}");
        }

        if ( my $flags_ar = $copy{'flags'} ) {
            for my $flag (@$flags_ar) {
                my $num = $flag2num{$flag} || do {
                    Carp::croak("Bad flag: $flag");
                };

                $arginfo |= $num;
            }
        }

        $copy{'arginfo'} = $arginfo;

        push @opts, \%copy;
    }

    return $class->_new_xs( $extra{'name'}, \@opts );
}

#----------------------------------------------------------------------

=head2 ($opts_hr, @leftovers) = I<OBJ>->parse(@ARGV)

Parses a list of strings understood to be parameters to script
invocation. Returns a hash reference of the parsed options (keyed
on each option’s C<long_name>) as well as a list of “leftover” @ARGV members
that didn’t go into one of the parsed options.

If @ARGV doesn’t match I<OBJ>’s stored options specification (e.g.,
L<popt(3)> fails the parse), an appropriate exception of type
L<CLI::Popt::X::Base> is thrown.

=head2 $str = I<OBJ>->get_help()

Returns the help text.

=head2 $str = I<OBJ>->get_usage()

Returns the usage text.

=cut

#----------------------------------------------------------------------

=head1 LICENSE & COPYRIGHT

Copyright 2022 by Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See L<perlartistic>.

=cut

1;
