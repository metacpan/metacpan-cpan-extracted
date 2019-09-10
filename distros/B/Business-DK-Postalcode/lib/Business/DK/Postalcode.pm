package Business::DK::Postalcode;

use strict;
use warnings;
use Tree::Simple;
use base qw(Exporter);
use Params::Validate qw(validate_pos SCALAR ARRAYREF OBJECT);
use utf8;
use 5.010; #5.10.0

use constant TRUE                        => 1;
use constant FALSE                       => 0;
use constant NUM_OF_DATA_ELEMENTS        => 6;
use constant NUM_OF_DIGITS_IN_POSTALCODE => 4;

## no critic (Variables::ProhibitPackageVars)
our @postal_data = <DATA>;

no strict 'refs';

my $regex;

our $VERSION = '0.12';
our @EXPORT_OK
    = qw(get_all_postalcodes get_all_cities get_all_data create_regex validate_postalcode validate get_city_from_postalcode get_postalcode_from_city);

# TODO: we have to disable this policy here for some reason?
## no critic (Subroutines::RequireArgUnpacking)
sub validate_postalcode {
    my ($postalcode) = @_;

   #loose check since we are doing actual validation, so we just need a scalar
    validate_pos( @_, { type => SCALAR }, );

    if ( not $regex ) {
        $regex = ${ create_regex() };
    }

    if (my ($untainted_postalcode)
        = $postalcode =~ m{
        \A #beginning of string
        ($regex) #generated regular expression, capturing
        \z #end of string
        }xsm
        )
    {
        return $untainted_postalcode;
    } else {
        return FALSE;
    }
}

## no critic (Subroutines::RequireArgUnpacking)
sub validate {

    #validation happens in next step (see: validate_postalcode)
    return validate_postalcode( $_[0] );
}

sub get_all_data {
    return \@postal_data;
}

sub get_all_cities {
    my @cities = ();

    _retrieve_cities( \@cities );

    return \@cities;

}

sub get_city_from_postalcode {
    my ($parameter_data) = @_;
    my $city = '';

    validate( @_, {
        zipcode => { type => SCALAR }, });

    my $postaldata = get_all_data();

    foreach my $line (@{$postaldata}) {
        my @entries = split /\t/x, $line, NUM_OF_DATA_ELEMENTS;

        if ($entries[0] eq $parameter_data) {
            $city = $entries[1];
            last;
        }
    }

    return $city;
}

sub get_postalcode_from_city {
    my ($parameter_data) = @_;
    my @postalcodes;

    validate( @_, {
        city => { type => SCALAR }, });

    my $postaldata = get_all_data();

    foreach my $line (@{$postaldata}) {
        my @entries = split /\t/x, $line, NUM_OF_DATA_ELEMENTS;

        if ($entries[1] =~ m/$parameter_data$/i) {
            push @postalcodes, $entries[0];
        }
    }

    return @postalcodes;
}

sub get_all_postalcodes {
    my ($parameter_data) = @_;
    my @postalcodes = ();

    validate_pos( @_, { type => ARRAYREF, optional => TRUE }, );

    if ( not $parameter_data ) {
        @{$parameter_data} = @postal_data;
    }

    foreach my $zipcode ( @{$parameter_data} ) {
        _retrieve_postalcode( \@postalcodes, $zipcode );
    }

    return \@postalcodes;
}

sub _retrieve_cities {
    my ( $cities ) = @_;

    #this is used internally, but we stick it in here just to make sure we
    #get what we want
    validate_pos( @_, { type => ARRAYREF }, );

    foreach my $line (@postal_data) {
        my @entries = split /\t/x, $line, NUM_OF_DATA_ELEMENTS;

        push @{$cities}, $entries[1];
    }

    return;
}

sub _retrieve_postalcode {
    my ( $postalcodes, $string ) = @_;

    #this is used internally, but we stick it in here just to make sure we
    #get what we want
    validate_pos( @_, { type => ARRAYREF }, { type => SCALAR, regex => qr/[\w\t]+/, }, );

    ## no critic qw(RegularExpressions::RequireLineBoundaryMatching RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireDotMatchAnything)
    my @entries = split /\t/x, $string, NUM_OF_DATA_ELEMENTS;

    if ($entries[0] =~ m{
        ^ #beginning of string
        \d{${\NUM_OF_DIGITS_IN_POSTALCODE}} #digits in postalcode
        $ #end of string
        }xsm
        )
    {
        push @{$postalcodes}, $entries[0];
    }

    return 1;
}

sub create_regex {
    my ($postalcodes) = @_;

    validate_pos( @_, { type => ARRAYREF, optional => 1 } );

    if ( not $postalcodes ) {
        $postalcodes = get_all_postalcodes();
    }

    my $tree = Tree::Simple->new( 'ROOT', Tree::Simple->ROOT );

    foreach my $postalcode ( @{$postalcodes} ) {
        _build_tree( $tree, $postalcode );
    }

    my $generated_regex = [];

    my $no_of_children = $tree->getChildCount();

    foreach my $child ( $tree->getAllChildren() ) {
        if ( $child->getIndex() < ( $tree->getChildCount() - 1 ) ) {
            $child->insertSibling( $child->getIndex() + 1,
                Tree::Simple->new(q{|}) );
        }
    }
    $tree->insertChild( 0, Tree::Simple->new('(') );
    $tree->addChild( Tree::Simple->new(')') );

    $tree->traverse(
        sub {
            my ($_tree) = shift;

            #DEBUG section - outputs tree to STDERR
            # warn "\n";
            # $tree->traverse(
            #     sub {
            #         my ($traversal_tree) = @_;
            #         warn( "\t" x $traversal_tree->getDepth() )
            #             . $traversal_tree->getNodeValue() . "\n";
            #     }
            # );

            my $no_of_children = $_tree->getChildCount();

            if ( $no_of_children > 1 ) {

                foreach my $child ( $_tree->getAllChildren() ) {
                    if ($child->getIndex() < ( $_tree->getChildCount() - 1 ) )
                    {
                        $child->insertSibling( $child->getIndex() + 1,
                            Tree::Simple->new(q{|}) );
                    }
                }

                #first element
                $_tree->insertChild( 0, Tree::Simple->new('(') );

                #last element
                $_tree->addChild( Tree::Simple->new(')') );
            }
        }
    );

    #traverses the tree and creates a flat list of the tree
    $tree->traverse(
        sub {
            my ($traversal_tree) = shift;
            push @{$generated_regex}, $traversal_tree->getNodeValue();
        }
    );

    #stringifies the flat list so we have a string representation of the
    #generated regular expression
    my $result = join q{}, @{$generated_regex};

    return \$result;
}

sub _build_tree {
    my ( $tree, $postalcode ) = @_;

    ## no critic qw(RegularExpressions::RequireLineBoundaryMatching RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireDotMatchAnything)
    validate_pos(
        @_,
        { type => OBJECT, isa   => 'Tree::Simple' },
        { type => SCALAR, regex => qr/\d{${\NUM_OF_DIGITS_IN_POSTALCODE}}/, },
    );

    my $oldtree = $tree;

    my @digits = split //xsm, $postalcode, NUM_OF_DIGITS_IN_POSTALCODE;
    for ( my $i = 0; $i < scalar @digits; $i++ ) {

        if ( $i == 0 ) {
            $tree = $oldtree;
        }

        my $subtree = Tree::Simple->new( $digits[$i] );

        my @children = $tree->getAllChildren();
        my $child    = undef;
        foreach my $c (@children) {
            if ( $c->getNodeValue() == $subtree->getNodeValue() ) {
                $child = $c;
                last;
            }
        }

        if ($child) {
            $tree = $child;
        } else {
            $tree->addChild($subtree);
            $tree = $subtree;
        }
    }
    $tree = $oldtree;

    return 1;
}

1;

=encoding UTF-8

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Business-DK-Postalcode.svg)](http://badge.fury.io/pl/Business-DK-Postalcode)
[![Build Status](https://travis-ci.org/jonasbn/bdkpst.svg?branch=master)](https://travis-ci.org/jonasbn/bdkpst)
[![Coverage Status](https://coveralls.io/repos/jonasbn/bdkpst/badge.png?branch=master)](https://coveralls.io/r/jonasbn/bdkpst?branch=master)

=end markdown

=head1 NAME

Business::DK::Postalcode - Danish postal code validator and container

=head1 VERSION

This documentation describes version 0.08

=head1 SYNOPSIS

    # basic validation of string
    use Business::DK::Postalcode qw(validate);

    if (validate($postalcode)) {
        print "We have a valid Danish postalcode\n";
    } else {
        warn "Not a valid Danish postalcode\n";
    }


    # basic validation of string, using less intrusive subroutine
    use Business::DK::Postalcode qw(validate_postalcode);

    if (validate_postalcode($postalcode)) {
        print "We have a valid Danish postal code\n";
    } else {
        warn "Not a valid Danish postal code\n";
    }


    # using the untainted return value
    use Business::DK::Postalcode qw(validate_postalcode);

    if (my $untainted = validate_postalcode($postalcode)) {
        print "We have a valid Danish postal code: $untainted\n";
    } else {
        warn "Not a valid Danish postal code\n";
    }


    # extracting a regex for validation of Danish postal codes
    use Business::DK::Postalcode qw(create_regex);

    my $regex_ref = ${create_regex()};

    if ($postalcode =~ m/$regex/) {
        print "We have a valid Danish postal code\n";
    } else {
        warn "Not a valid Danish postal code\n";
    }


    # All postal codes for use outside this module
    use Business::DK::Postalcode qw(get_all_postalcodes);

    my @postalcodes = @{get_all_postalcodes()};


    # All postal codes and data for use outside this module
    use Business::DK::Postalcode qw(get_all_data);

    my $postalcodes = get_all_data();

    foreach (@{postalcodes}) {
        printf
            'postal code: %s city: %s street/desc: %s company: %s province: %d country: %d', split /\t/, $_, 6;
    }

=head1 FEATURES

=over

=item * Providing list of Danish postal codes and related area names

=item * Look up methods for Danish postal codes for web applications and the like

=back

=head1 DESCRIPTION

This distribution is not the original resource for the included data, but simply
acts as a simple distribution for Perl use. The central source is monitored so this
distribution can contain the newest data. The monitor script (F<postdanmark.pl>) is
included in the distribution.

The data are converted for inclusion in this module. You can use different extraction
subroutines depending on your needs:

=over

=item * L</get_all_data>, to retrieve all data, data description below in L</Data>.

=item * L</get_all_postalcodes>, to retrieve all postal codes

=item * L</get_all_cities>, to retieve all cities

=item * L</get_postalcode_from_city>, to retrieve one or more postal codes from a city name

=item * L</get_city_from_postalcode>, to retieve a city name from a postal code

=back

=head2 Data

Here follows a description of the included data, based on the description from
the original source and the authors interpretation of the data, including
details on the distribution of the data.

=head3 city name

A non-unique, case-sensitive representation of a city name in Danish.

=head3 street/description

This field is either a streetname or a description, is it only provided for
a few special records.

=head3 company name

This field is only provided for a few special records.

=head3 province

This field is a bit special and it's use is expected to be related to distribution
all entries inside Copenhagen are marked as 'False' in this column and 'True' for
all entries outside Copenhagen - and this of course with exceptions. The data are
included since they are a part of the original data.

=head3 country

Since the original source contains data on 3 different countries:

=over

=item * Denmark

=item * Greenland

=item * Faroe Islands

=back

Only the data representing Denmark has been included in this distribtion, so this
field is always containing a one.

For access to the data on Greenland or Faroe Islands please refer to: L<Business::GL::Postalcode>
and L<Business::FO::Postalcode> respectfully.

=head2 Encoding

The data distributed are in Danish for descriptions and names and these are encoded in UTF-8.

=head1 EXAMPLES

A web application example is included in the examples directory following this distribution
or available at L<https://metacpan.org/pod/Business::DK::Postalcode>.

=head1 SUBROUTINES AND METHODS

=head2 validate

A simple validator for Danish postal codes.

Takes a string representing a possible Danish postal code and returns either
B<1> or B<0> indicating either validity or invalidity.

    my $rv = validate(2665);

    if ($rv == 1) {
        print "We have a valid Danish postal code\n";
    } ($rv == 0) {
        print "Not a valid Danish postal code\n";
    }

=head2 validate_postalcode

A less intrusive subroutine for import. Acts as a wrapper of L</validate>.

    my $rv = validate_postalcode(2300);

    if ($rv) {
        print "We have a valid Danish postal code\n";
    } else {
        print "Not a valid Danish postal code\n";
    }

=head2 get_all_data

Returns a reference to a a list of strings, separated by tab characters. See
L</Data> for a description of the fields.

    use Business::DK::Postalcode qw(get_all_data);

    my $postalcodes = get_all_data();

    foreach (@{postalcodes}) {
        printf
            'postalcode: %s city: %s street/desc: %s company: %s province: %d country: %d', split /\t/, $_, 6;
    }

=head2 get_all_postalcodes

Takes no parameters.

Returns a reference to an array containing all valid Danish postal codes.

    use Business::DK::Postalcode qw(get_all_postalcodes);

    my $postalcodes = get_all_postalcodes;

    foreach my $postalcode (@{$postalcodes}) { ... }

=head2 get_all_cities

Takes no parameters.

Returns a reference to an array containing all Danish city names having a postal code.

    use Business::DK::Postalcode qw(get_all_cities);

    my $cities = get_all_cities;

    foreach my $city (@{$cities}) { ... }

Please note that this data source used in this distribution by no means is authorative
when it comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head2 get_city_from_postalcode

Takes a string representing a Danish postal code.

Returns a single string representing the related city name or an empty string indicating nothing was found.

    use Business::DK::Postalcode qw(get_city_from_postalcode);

    my $zipcode = '2300';

    my $city = get_city_from_postalcode($zipcode);

    if ($city) {
        print "We found a city for $zipcode\n";
    } else {
        warn "No city found for $zipcode";
    }

=head2 get_postalcode_from_city

Takes a string representing a Danish city name.

Returns a reference to an array containing zero or more postal codes related to that city name. Zero indicates nothing was found.

Please note that city names are not unique, hence the possibility of a list of postal codes.

    use Business::DK::Postalcode qw(get_postalcode_from_city);

    my $city = 'København K';

    my $postalcodes = get_postalcode_from_city($city);

    if (scalar @{$postalcodes} == 1) {
        print "$city is unique\n";
    } elsif (scalar @{$postalcodes} > 1) {
        warn "$city is NOT unique\n";
    } else {
        die "$city not found\n";
    }

=head2 create_regex

This method returns a generated regular expression for validation of a string
representing a possible Danish postal code.

    use Business::DK::Postalcode qw(create_regex);

    my $regex_ref = ${create_regex()};

    if ($postalcode =~ m/$regex/) {
        print "We have a valid Danish postalcode\n";
    } else {
        print "Not a valid Danish postalcode\n";
    }

=head1 PRIVATE SUBROUTINES AND METHODS

=head2 _retrieve_cities

Takes a reference to an array based on the DATA section and return a reference
to an array containing only city names.

=head3 _retrieve_postalcode

Takes a reference to an array based on the DATA section and return a reference
to an array containing only postal codes.

=head3 _build_tree

Internal method to assist L</create_regex> in generating the regular expression.

Takes a L<https://metacpan.org/pod/Tree::Simple> object and a reference to an array of data elements.

=head1 DIAGNOSTICS

There are not special diagnostics apart from the ones related to the different
subroutines.

=head1 CONFIGURATION AND ENVIRONMENT

This distribution requires no special configuration or environment.

=head1 DEPENDENCIES

=over

=item * L<https://metacpan.org/pod/Carp> (core)

=item * L<https://metacpan.org/pod/Exporter> (core)

=item * L<https://metacpan.org/pod/Tree::Simple>

=item * L<https://metacpan.org/pod/Params::Validate>

=back

=head2 TEST

Please note that the above list does not reflect requirements for:

=over

=item * Additional components in this distribution, see F<lib/>. Additional
components list own requirements

=item * Test and build system, please see: F<Build.PL> for details

=item * Requirements for scripts in the F<bin/> directory

=item * Requirements for examples in the F<examples/> directory

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs at this time.

The data source used in this distribution by no means is authorative when it
comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * Web (RT): L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Postalcode>

=item * Web (Github): L<https://github.com/jonasbn/bdkpst/issues>

=item * Email (RT): L<bug-Business-DK-Postalcode@rt.cpan.org>

=back

=head1 INCOMPATIBILITIES

There are no known incompatibilities at this time.

=head1 TEST AND QUALITY

=head2 Perl::Critic

This version of the code is complying with L<https://metacpan.org/pod/Perl::Critic> a severity: 1

The following policies have been disabled.

=over

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::Variables::ProhibitPackageVars>

Disabled locally using 'no critic' pragma.

The module  uses a package variable as a cache, this might not prove usefull in
the long term, so when this is adressed and this might address this policy.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::RequireArgUnpacking>

Disabled locally using 'no critic' pragma.

This policy is violated when using L<https://metacpan.org/pod/Params::Validate> at some point this will
be investigated further, this might be an issue due to referral to @_.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching>

Disabled locally using 'no critic' pragma.

This is disabled for some two basic regular expressions.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting>

Disabled locally using 'no critic' pragma.

This is disabled for some two basic regular expressions.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything>

Disabled locally using 'no critic' pragma.

This is disabled for some two basic regular expressions.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

Constants are good, - see the link below.

=item * L<https://logiclab.jira.com/wiki/display/OPEN/Perl-Critic-Policy-ValuesAndExpressions-ProhibitConstantPragma>

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::Documentation::RequirePodAtEnd>

This one interfers with our DATA section, perhaps DATA should go before POD,
well it is not important so I have disabled the policy.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops>

This would require a re-write of part of the code. Currently I rely on use of the iterator in the F<for> loop, so it would require significant
changes.

=item * L<https://metacpan.org/pod/Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>

Temporarily disabled, marked for follow-up

=back

Please see F<t/perlcriticrc> for details.

=head2 TEST COVERAGE

Test coverage report is generated using L<https://metacpan.org/pod/Devel::Cover> via L<https://metacpan.org/pod/Module::Build>,
for the version described in this documentation (See L<VERSION>).

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...Business/DK/Postalcode.pm  100.0  100.0    n/a  100.0  100.0   98.7  100.0
    ...Business/DK/Postalcode.pm  100.0  100.0    n/a  100.0  100.0    1.2  100.0
    Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

    $ ./Build testcover

=head1 SEE ALSO

=over

=item * Main data source: L<http://www.postdanmark.dk/da/Documents/Lister/postnummerfil-excel.xls>

=item * Information resource on data source: L<http://www.postdanmark.dk/cms/da-dk/eposthuset/postservices/aendringer_postnumre_1.htm>

=item * Alternative implementation: L<https://metacpan.org/pod/Geo::Postcodes::DK>

=item * Alternative validation: L<https://metacpan.org/module/Regexp::Common::zip#RE-zip-Denmark->

=item * Related complementary implementation: L<https://metacpan.org/pod/Business::GL::Postalcode>

=item * Related complementary implementation: L<https://metacpan.org/pod/Business::FO::Postalcode>

=item * Related implementation, same author: L<https://metacpan.org/pod/Business::DK::CVR>

=item * Related implementation, same author: L<https://metacpan.org/pod/Business::DK::CPR>

=item * Related implementation, same author: L<https://metacpan.org/pod/Business::DK::FI>

=item * Related implementation, same author: L<https://metacpan.org/pod/Business::DK::PO>

=back

=head1 RESOURCES

=over

=item * MetaCPAN: L<https://metacpan.org/pod/Business::DK::Postalcode>

=item * Website: L<http://logicLAB.jira.com/browse/BDKPST>

=item * Bugtracker: L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Postalcode>

=item * Git repository: L<https://github.com/jonasbn/bdkpst>

=back

=head1 TODO

Please see the project F<TODO> file, or the bugtracker (RT), website or issues resource at Github.

=head1 AUTHOR

=over

=item * Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * Mohammad S Anwar, POD corrections PR #6

=back

=head1 MOTIVATION

Back in 2006 I was working on a project where I needed to do some presentation
and validation of Danish postal codes. I looked at L<https://metacpan.org/pod/Regex::Common::Zip>

The implementation at the time of writing looked as follows:

    Denmark     =>  "(?k:(?k:[1-9])(?k:[0-9])(?k:[0-9]{2}))",
    # Postal codes of the form: 'DDDD', with the first
    # digit representing the distribution region, the
    # second digit the distribution district. Postal
    # codes do not start with a zero. Postal codes
    # starting with '39' are in Greenland.

This pattern holds some issues:

=over

=item * Doing some fast math you can see that you will allow 9000 valid postal
codes where the number should be about 1254

=item * 0 is actually allowed for a set of postal codes used by the postal service
in Denmark, in some situations these should perhaps be allowed as valid data

=item * Greenland specified as starting with '39' is not a part of Denmark, but
should be under Greenland and the ISO code 'GL', see also:

=over

=item * L<https://metacpan.org/pod/Business::GL::Postalcode>

=back

=back

So I decided to write a regular expression, which would be better than the one
above, but I did not want to maintain it I wanted to write a piece of software,
which could generate the pattern for me based on a finite data set.

=head1 COPYRIGHT

Business-DK-Postalcode is (C) by Jonas B. Nielsen, (jonasbn) 2006-2019

=head1 LICENSE

Business-DK-Postalcode and related is released under the Artistic License 2.0

=over

=item * L<http://www.opensource.org/licenses/Artistic-2.0>

=back

=cut

__DATA__
0555	Scanning		Data Scanning A/S	True	1
0800	Høje Taastrup	Girostrøget 1	BG-Bank A/S	True	1
0877	København C	Havneholmen 33	Aller Press (konkurrencer)	False	1
0892	Sjælland USF P	Ufrankerede svarforsendelser		False	1
0893	Sjælland USF B	Ufrankerede svarforsendelser		False	1
0894	Udbetaling		(Post til scanning)	False	1
0897	eBrevsprækken		(Post til scanning)	False	1
0899	Kommuneservice		(Post til scanning)	False	1
0900	København C		Københavns Postcenter + erhvervskunder	False	1
0910	København C	Ufrankerede svarforsendelser 		False	1
0917	Københavns Pakkecenter		(Returpakker)	False	1
0918	Københavns Pakke BRC		(Returpakker)	False	1
0919	Returprint BRC			False	1
0929	København C	Ufrankerede svarforsendelser		False	1
0960	Internationalt Postcenter		(Internt)	False	1
0999	København C		DR Byen	False	1
1000	København K	Købmagergade 33	Købmagergade Postkontor	False	1
1001	København K	Postboks		False	1
1002	København K	Postboks		False	1
1003	København K	Postboks		False	1
1004	København K	Postboks		False	1
1005	København K	Postboks		False	1
1006	København K	Postboks		False	1
1007	København K	Postboks		False	1
1008	København K	Postboks		False	1
1009	København K	Postboks		False	1
1010	København K	Postboks		False	1
1011	København K	Postboks		False	1
1012	København K	Postboks		False	1
1013	København K	Postboks		False	1
1014	København K	Postboks		False	1
1015	København K	Postboks		False	1
1016	København K	Postboks		False	1
1017	København K	Postboks		False	1
1018	København K	Postboks		False	1
1019	København K	Postboks		False	1
1020	København K	Postboks		False	1
1021	København K	Postboks		False	1
1022	København K	Postboks		False	1
1023	København K	Postboks		False	1
1024	København K	Postboks		False	1
1025	København K	Postboks		False	1
1026	København K	Postboks		False	1
1045	København K	Ufrankerede svarforsendelser		False	1
1050	København K	Kongens Nytorv		False	1
1051	København K	Nyhavn		False	1
1052	København K	Herluf Trolles Gade		False	1
1053	København K	Cort Adelers Gade		False	1
1054	København K	Peder Skrams Gade		False	1
1055	København K	Tordenskjoldsgade		False	1
1055	København K	August Bournonvilles Passage		False	1
1056	København K	Heibergsgade		False	1
1057	København K	Holbergsgade		False	1
1058	København K	Havnegade		False	1
1059	København K	Niels Juels Gade		False	1
1060	København K	Holmens Kanal		False	1
1061	København K	Ved Stranden		False	1
1062	København K	Boldhusgade		False	1
1063	København K	Laksegade		False	1
1064	København K	Asylgade		False	1
1065	København K	Fortunstræde		False	1
1066	København K	Admiralgade		False	1
1067	København K	Nikolaj Plads		False	1
1068	København K	Nikolajgade		False	1
1069	København K	Bremerholm		False	1
1070	København K	Vingårdstræde		False	1
1071	København K	Dybensgade		False	1
1072	København K	Lille Kirkestræde		False	1
1073	København K	Store Kirkestræde		False	1
1074	København K	Lille Kongensgade		False	1
1092	København K	Holmens Kanal 2-12	Danske Bank A/S	False	1
1093	København K	Havnegade 5	Danmarks Nationalbank	False	1
1095	København K	Kongens Nytorv 13	Magasin du Nord	False	1
1098	København K	Esplanaden 50	A.P. Møller	False	1
1100	København K	Østergade		False	1
1101	København K	Ny Østergade		False	1
1102	København K	Pistolstræde		False	1
1103	København K	Hovedvagtsgade		False	1
1104	København K	Ny Adelgade		False	1
1105	København K	Kristen Bernikows Gade		False	1
1106	København K	Antonigade		False	1
1107	København K	Grønnegade		False	1
1110	København K	Store Regnegade		False	1
1111	København K	Christian IX's Gade		False	1
1112	København K	Pilestræde		False	1
1113	København K	Silkegade		False	1
1114	København K	Kronprinsensgade		False	1
1115	København K	Klareboderne		False	1
1116	København K	Møntergade		False	1
1117	København K	Gammel Mønt		False	1
1118	København K	Sværtegade		False	1
1119	København K	Landemærket		False	1
1120	København K	Vognmagergade		False	1
1121	København K	Lønporten		False	1
1122	København K	Sjæleboderne		False	1
1123	København K	Gothersgade		False	1
1124	København K	Åbenrå		False	1
1125	København K	Suhmsgade		False	1
1126	København K	Pustervig		False	1
1127	København K	Hauser Plads		False	1
1128	København K	Hausergade		False	1
1129	København K	Sankt Gertruds Stræde		False	1
1130	København K	Rosenborggade		False	1
1131	København K	Tornebuskegade		False	1
1140	København K	Møntergade 19	Dagbladet Børsen	False	1
1147	København K	Pilestræde 34	Berlingske Tidende	False	1
1148	København K	Vognmagergade 11	Egmont	False	1
1150	København K	Købmagergade		False	1
1151	København K	Valkendorfsgade		False	1
1152	København K	Løvstræde		False	1
1153	København K	Niels Hemmingsens Gade		False	1
1154	København K	Gråbrødretorv		False	1
1155	København K	Kejsergade		False	1
1156	København K	Gråbrødrestræde		False	1
1157	København K	Klosterstræde		False	1
1158	København K	Skoubogade		False	1
1159	København K	Skindergade		False	1
1160	København K	Amagertorv		False	1
1161	København K	Vimmelskaftet		False	1
1162	København K	Jorcks Passage		False	1
1163	København K	Klostergården		False	1
1164	København K	Nygade		False	1
1165	København K	Nørregade		False	1
1165	København K	Sankt Petri Passage		False	1
1166	København K	Dyrkøb		False	1
1167	København K	Bispetorvet		False	1
1168	København K	Frue Plads		False	1
1169	København K	Store Kannikestræde		False	1
1170	København K	Lille Kannikestræde		False	1
1171	København K	Fiolstræde		False	1
1172	København K	Krystalgade		False	1
1173	København K	Peder Hvitfeldts Stræde		False	1
1174	København K	Rosengården		False	1
1175	København K	Kultorvet		False	1
1200	København K	Højbro Plads		False	1
1201	København K	Læderstræde		False	1
1202	København K	Gammel Strand		False	1
1203	København K	Nybrogade		False	1
1204	København K	Magstræde		False	1
1205	København K	Snaregade		False	1
1206	København K	Naboløs		False	1
1207	København K	Hyskenstræde		False	1
1208	København K	Kompagnistræde		False	1
1209	København K	Badstuestræde		False	1
1210	København K	Knabrostræde		False	1
1211	København K	Brolæggerstræde		False	1
1212	København K	Vindebrogade		False	1
1213	København K	Bertel Thorvaldsens Plads		False	1
1214	København K	Tøjhusgade		False	1
1215	København K	Børsgade		False	1
1216	København K	Slotsholmsgade		False	1
1217	København K	Børsen		False	1
1218	København K	Christiansborg		False	1
1218	København K	Christiansborg Ridebane		False	1
1218	København K	Christiansborg Slotsplads		False	1
1218	København K	Prins Jørgens Gård		False	1
1218	København K	Proviantpassagen		False	1
1218	København K	Rigsdagsgården		False	1
1219	København K	Christians Brygge 1-5 og 8		False	1
1220	København K	Frederiksholms Kanal		False	1
1221	København K	Søren Kierkegaards Plads		False	1
1240	København K	Christiansborg	Folketinget	False	1
1250	København K	Sankt Annæ Plads		False	1
1251	København K	Kvæsthusgade		False	1
1252	København K	Kvæsthusbroen		False	1
1253	København K	Toldbodgade		False	1
1254	København K	Lille Strandstræde		False	1
1255	København K	Store Strandstræde		False	1
1256	København K	Amaliegade		False	1
1257	København K	Amalienborg		False	1
1258	København K	Larsens Plads		False	1
1259	København K	Nordre Toldbod		False	1
1259	København K	Trekroner		False	1
1260	København K	Bredgade		False	1
1261	København K	Palægade		False	1
1263	København K	Churchillparken		False	1
1263	København K	Esplanaden		False	1
1264	København K	Store Kongensgade		False	1
1265	København K	Frederiksgade		False	1
1266	København K	Bornholmsgade		False	1
1267	København K	Hammerensgade		False	1
1268	København K	Jens Kofods Gade		False	1
1270	København K	Grønningen		False	1
1271	København K	Poul Ankers Gade		False	1
1291	København K	Sankt Annæ Plads 26-28	J. Lauritzen A/S	False	1
1300	København K	Borgergade		False	1
1301	København K	Landgreven		False	1
1302	København K	Dronningens Tværgade		False	1
1303	København K	Hindegade		False	1
1304	København K	Adelgade		False	1
1306	København K	Kronprinsessegade		False	1
1307	København K	Georg Brandes Plads		False	1
1307	København K	Sølvgade		False	1
1308	København K	Klerkegade		False	1
1309	København K	Rosengade		False	1
1310	København K	Fredericiagade		False	1
1311	København K	Olfert Fischers Gade		False	1
1312	København K	Gammelvagt		False	1
1313	København K	Sankt Pauls Gade		False	1
1314	København K	Sankt Pauls Plads		False	1
1315	København K	Rævegade		False	1
1316	København K	Rigensgade		False	1
1317	København K	Stokhusgade		False	1
1318	København K	Krusemyntegade		False	1
1319	København K	Gernersgade		False	1
1320	København K	Haregade		False	1
1321	København K	Tigergade		False	1
1322	København K	Suensonsgade		False	1
1323	København K	Hjertensfrydsgade		False	1
1324	København K	Elsdyrsgade		False	1
1325	København K	Delfingade		False	1
1326	København K	Krokodillegade		False	1
1327	København K	Vildandegade		False	1
1328	København K	Svanegade		False	1
1329	København K	Timiansgade		False	1
1349	København K	Sølvgade 40	DSB	False	1
1350	København K	Øster Voldgade		False	1
1352	København K	Rørholmsgade		False	1
1353	København K	Øster Farimagsgade 3-15 og 2		False	1
1354	København K	Ole Suhrs Gade		False	1
1355	København K	Gammeltoftsgade		False	1
1356	København K	Bartholinsgade		False	1
1357	København K	Øster Søgade 8-36		False	1
1358	København K	Nørre Voldgade		False	1
1359	København K	Ahlefeldtsgade		False	1
1359	København K	Charlotte Ammundsens Plads		False	1
1360	København K	Frederiksborggade		False	1
1361	København K	Israels Plads		False	1
1361	København K	Linnésgade		False	1
1362	København K	Rømersgade		False	1
1363	København K	Vendersgade		False	1
1364	København K	Nørre Farimagsgade		False	1
1365	København K	Schacksgade		False	1
1366	København K	Nansensgade		False	1
1367	København K	Kjeld Langes Gade		False	1
1368	København K	Turesensgade		False	1
1369	København K	Gyldenløvesgade lige nr.		False	1
1370	København K	Nørre Søgade		False	1
1371	København K	Søtorvet		False	1
1400	København K	Knippelsbro		False	1
1400	København K	Torvegade		False	1
1401	København K	Strandgade		False	1
1402	København K	Asiatisk Plads		False	1
1402	København K	David Balfours Gade		False	1
1402	København K	Hammershøi Kaj		False	1
1402	København K	Johan Semps Gade		False	1
1402	København K	Nicolai Eigtveds Gade		False	1
1403	København K	Wilders Plads		False	1
1404	København K	Krøyers Plads		False	1
1406	København K	Christianshavns Kanal		False	1
1407	København K	Bådsmandsstræde		False	1
1408	København K	Wildersgade		False	1
1409	København K	Knippelsbrogade		False	1
1410	København K	Christianshavns Torv		False	1
1411	København K	Langebrogade		False	1
1411	København K	Applebys Plads		False	1
1412	København K	Voldgården		False	1
1413	København K	Ved Kanalen		False	1
1414	København K	Overgaden Neden Vandet		False	1
1415	København K	Overgaden Oven Vandet		False	1
1416	København K	Sankt Annæ Gade		False	1
1417	København K	Mikkel Vibes Gade		False	1
1418	København K	Sofiegade		False	1
1419	København K	Store Søndervoldstræde		False	1
1420	København K	Dronningensgade		False	1
1421	København K	Lille Søndervoldstræde		False	1
1422	København K	Prinsessegade		False	1
1423	København K	Amagergade		False	1
1424	København K	Christianshavns Voldgade		False	1
1425	København K	Ved Volden		False	1
1426	København K	Voldboligerne		False	1
1427	København K	Brobergsgade		False	1
1428	København K	Andreas Bjørns Gade		False	1
1429	København K	Burmeistersgade		False	1
1430	København K	Bodenhoffs Plads		False	1
1431	København K	Islands Plads		False	1
1432	København K	Margretheholmsvej		False	1
1432	København K	Refshalevej		False	1
1432	København K	William Wains Gade		False	1
1433	København K	Christiansholms Ø		False	1
1433	København K	Flakfortet		False	1
1433	København K	Lynetten		False	1
1433	København K	Margretheholm		False	1
1433	København K	Middelgrundsfortet		False	1
1433	København K	Quintus		False	1
1433	København K	Refshaleøen		False	1
1434	København K	Danneskiold-Samsøes Allé		False	1
1435	København K	Philip De Langes Allé		False	1
1436	København K	Arsenalvej		False	1
1436	København K	Halvtolv		False	1
1436	København K	Kuglegården		False	1
1436	København K	Kuglegårdsvej		False	1
1436	København K	Søartillerivej		False	1
1436	København K	Trangravsvej		False	1
1436	København K	Værftsbroen		False	1
1437	København K	Bohlendachvej		False	1
1437	København K	Eik Skaløes Plads		False	1
1437	København K	Fabrikmestervej		False	1
1437	København K	Galionsvej		False	1
1437	København K	Kanonbådsvej		False	1
1437	København K	Leo Mathisens Vej		False	1
1437	København K	Masteskursvej		False	1
1437	København K	Per Knutzons Vej		False	1
1437	København K	Schifters Kvarter		False	1
1437	København K	Stibolts Kvarter		False	1
1437	København K	Takkelloftsvej		False	1
1437	København K	Theodor Christensens Plads		False	1
1438	København K	Benstrups Kvarter		False	1
1438	København K	Dokøvej		False	1
1438	København K	Ekvipagemestervej		False	1
1438	København K	Judichærs Plads		False	1
1438	København K	Orlogsværftvej		False	1
1439	København K	A.H. Vedels Plads		False	1
1439	København K	Bradbænken		False	1
1439	København K	Elefanten		False	1
1439	København K	Eskadrevej		False	1
1439	København K	H.C. Sneedorffs Allé		False	1
1439	København K	Henrik Gerners Plads		False	1
1439	København K	Henrik Spans Vej		False	1
1439	København K	Kongebrovej		False	1
1439	København K	Krudtløbsvej		False	1
1439	København K	Minørvej		False	1
1439	København K	P. Løvenørns Vej		False	1
1439	København K	Spanteloftvej		False	1
1439	København K	Takkeladsvej		False	1
1439	København K	Ved Sixtusbatteriet		False	1
1439	København K	Ved Søminegraven		False	1
1440	København K	Bjørnekloen		False	1
1440	København K	Blå Karamel		False	1
1440	København K	Fabriksområdet		False	1
1440	København K	Fredens Ark		False	1
1440	København K	Løvehuset		False	1
1440	København K	Mælkebøtten		False	1
1440	København K	Mælkevejen		False	1
1440	København K	Nordområdet		False	1
1440	København K	Psyak		False	1
1440	København K	Sydområdet		False	1
1440	København K	Tinghuset		False	1
1441	København K	Midtdyssen		False	1
1441	København K	Norddyssen		False	1
1441	København K	Syddyssen		False	1
1448	København K	Asiatisk Plads 2	Udenrigsministeriet	False	1
1450	København K	Nytorv		False	1
1451	København K	Larslejsstræde		False	1
1452	København K	Teglgårdstræde		False	1
1453	København K	Sankt Peders Stræde		False	1
1454	København K	Larsbjørnsstræde		False	1
1455	København K	Studiestræde 3-49 og 6-40		False	1
1456	København K	Vestergade		False	1
1457	København K	Gammeltorv		False	1
1458	København K	Kattesundet		False	1
1459	København K	Frederiksberggade		False	1
1460	København K	Mikkel Bryggers Gade		False	1
1461	København K	Slutterigade		False	1
1462	København K	Lavendelstræde		False	1
1463	København K	Farvergade		False	1
1464	København K	Hestemøllestræde		False	1
1465	København K	Gåsegade		False	1
1466	København K	Rådhusstræde		False	1
1467	København K	Vandkunsten		False	1
1468	København K	Løngangstræde		False	1
1470	København K	Stormgade 2-14		False	1
1471	København K	Ny Vestergade		False	1
1472	København K	Ny Kongensgade 1-15 og 4-14		False	1
1473	København K	Bryghusgade		False	1
1500	København V	Bernstorffsgade 40	Vesterbro Postkontor	False	1
1501	København V	Postboks		False	1
1502	København V	Postboks		False	1
1503	København V	Postboks		False	1
1504	København V	Postboks		False	1
1505	København V	Postboks		False	1
1506	København V	Postboks		False	1
1507	København V	Postboks		False	1
1508	København V	Postboks		False	1
1509	København V	Postboks		False	1
1510	København V	Postboks		False	1
1512	Returpost		(Internt)	False	1
1513	Centraltastning		(Internt)	False	1
1532	København V	Kystvejen 26, 2770 Kastrup	Internationalt Postcenter, returforsendelser + consignment	False	1
1533	København V	Kystvejen 26, 2770 Kastrup	Internationalt Postcenter	False	1
1550	København V	Bag Rådhuset		False	1
1550	København V	Rådhuspladsen		False	1
1551	København V	Jarmers Plads		False	1
1552	København V	Vester Voldgade		False	1
1553	København V	H.C. Andersens Boulevard		False	1
1553	København V	Langebro		False	1
1554	København V	Studiestræde 57-69 og 50-54		False	1
1555	København V	Stormgade 20 og 35		False	1
1556	København V	Dantes Plads		False	1
1557	København V	Ny Kongensgade 19-21 og 18-20		False	1
1558	København V	Christiansborggade		False	1
1559	København V	Christians Brygge 24-30		False	1
1560	København V	Kalvebod Brygge		False	1
1561	København V	Fisketorvet		False	1
1561	København V	Kalvebod Pladsvej		False	1
1562	København V	Hambrosgade		False	1
1563	København V	Otto Mønsteds Plads		False	1
1564	København V	Rysensteensgade		False	1
1566	København V	Tietgensgade 37	Post Danmark A/S	False	1
1567	København V	Polititorvet		False	1
1568	København V	Mitchellsgade		False	1
1569	København V	Edvard Falcks Gade		False	1
1570	København V	Banegårdspladsen		False	1
1570	København V	Københavns Hovedbanegård		False	1
1571	København V	Otto Mønsteds Gade		False	1
1572	København V	Anker Heegaards Gade		False	1
1573	København V	Puggaardsgade		False	1
1574	København V	Niels Brocks Gade		False	1
1575	København V	Ved Glyptoteket		False	1
1576	København V	Stoltenbergsgade		False	1
1577	København V	Arni Magnussons Gade		False	1
1577	København V	Carsten Niebuhrs Gade		False	1
1577	København V	Bernstorffsgade		False	1
1592	København V	Bernstorffsgade 17-19	Københavns Socialdirektorat	False	1
1599	København V	Rådhuspladsen 1 	Københavns Rådhus	False	1
1600	København V	Gyldenløvesgade ulige nr.		False	1
1601	København V	Vester Søgade		False	1
1602	København V	Nyropsgade		False	1
1603	København V	Dahlerupsgade		False	1
1604	København V	Kampmannsgade		False	1
1605	København V	Herholdtsgade		False	1
1606	København V	Vester Farimagsgade		False	1
1607	København V	Staunings Plads		False	1
1608	København V	Jernbanegade		False	1
1609	København V	Axeltorv		False	1
1610	København V	Gammel Kongevej 1-55 og 10		False	1
1611	København V	Hammerichsgade		False	1
1612	København V	Ved Vesterport		False	1
1613	København V	Meldahlsgade		False	1
1614	København V	Trommesalen		False	1
1615	København V	Sankt Jørgens Allé		False	1
1616	København V	Stenosgade		False	1
1617	København V	Bagerstræde		False	1
1618	København V	Tullinsgade		False	1
1619	København V	Værnedamsvej lige nr.		False	1
1620	København V	Vesterbrogade 1-149 og 2-150		False	1
1620	København V	Vesterbros Torv		False	1
1621	København V	Frederiksberg Alle 1 - 13B		False	1
1622	København V	Boyesgade ulige nr		False	1
1623	København V	Kingosgade 1-9		False	1
1624	København V	Brorsonsgade		False	1
1630	København V	Vesterbrogade 3	Tivoli A/S	False	1
1631	København V	Herman Triers Plads		False	1
1632	København V	Julius Thomsens Gade lige nr		False	1
1633	København V	Kleinsgade		False	1
1634	København V	Rosenørns Allé 2-18		False	1
1635	København V	Åboulevard 1-13		False	1
1640	København V	Dahlerupsgade 6	Københavns Folkeregister	False	1
1650	København V	Istedgade		False	1
1651	København V	Reventlowsgade		False	1
1652	København V	Colbjørnsensgade		False	1
1653	København V	Helgolandsgade		False	1
1654	København V	Abel Cathrines Gade		False	1
1655	København V	Viktoriagade		False	1
1656	København V	Gasværksvej		False	1
1657	København V	Eskildsgade		False	1
1658	København V	Absalonsgade		False	1
1659	København V	Svendsgade		False	1
1660	København V	Dannebrogsgade		False	1
1660	København V	Otto Krabbes Plads		False	1
1661	København V	Westend		False	1
1662	København V	Saxogade		False	1
1663	København V	Oehlenschlægersgade		False	1
1664	København V	Kaalundsgade		False	1
1665	København V	Valdemarsgade		False	1
1666	København V	Matthæusgade		False	1
1667	København V	Frederiksstadsgade		False	1
1668	København V	Mysundegade		False	1
1669	København V	Flensborggade		False	1
1670	København V	Enghave Plads		False	1
1671	København V	Haderslevgade		False	1
1671	København V	Tove Ditlevsens Plads		False	1
1672	København V	Broagergade		False	1
1673	København V	Ullerupgade		False	1
1674	København V	Enghavevej 1-77 og 2-78		False	1
1675	København V	Kongshøjgade		False	1
1676	København V	Sankelmarksgade		False	1
1677	København V	Gråstensgade		False	1
1699	København V	Staldgade		False	1
1700	København V	Halmtorvet		False	1
1701	København V	Reverdilsgade		False	1
1702	København V	Stampesgade		False	1
1703	København V	Lille Colbjørnsensgade		False	1
1704	København V	Tietgensgade		False	1
1705	København V	Ingerslevsgade		False	1
1706	København V	Lille Istedgade		False	1
1707	København V	Maria Kirkeplads		False	1
1708	København V	Eriksgade		False	1
1709	København V	Skydebanegade		False	1
1710	København V	Kvægtorvsgade		False	1
1711	København V	Flæsketorvet		False	1
1711	København V	Onkel Dannys Plads		False	1
1712	København V	Høkerboderne		False	1
1713	København V	Kvægtorvet		False	1
1714	København V	Kødboderne		False	1
1715	København V	Slagtehusgade		False	1
1716	København V	Slagterboderne		False	1
1717	København V	Skelbækgade		False	1
1718	København V	Sommerstedgade		False	1
1719	København V	Krusågade		False	1
1720	København V	Sønder Boulevard		False	1
1721	København V	Dybbølsgade		False	1
1722	København V	Godsbanegade		False	1
1723	København V	Letlandsgade		False	1
1724	København V	Estlandsgade		False	1
1725	København V	Esbern Snares Gade		False	1
1726	København V	Arkonagade		False	1
1727	København V	Asger Rygs Gade		False	1
1728	København V	Skjalm Hvides Gade		False	1
1729	København V	Sigerstedgade		False	1
1730	København V	Knud Lavards Gade		False	1
1731	København V	Erik Ejegods Gade		False	1
1732	København V	Bodilsgade		False	1
1733	København V	Palnatokesgade		False	1
1734	København V	Heilsgade		False	1
1735	København V	Røddinggade		False	1
1736	København V	Bevtoftgade		False	1
1737	København V	Bustrupgade		False	1
1738	København V	Stenderupgade		False	1
1739	København V	Enghave Passage		False	1
1749	København V	Rahbeks Allé 3-11		False	1
1750	København V	Vesterfælledvej 1-9 og 2-56		False	1
1751	København V	Sundevedsgade		False	1
1752	København V	Tøndergade		False	1
1753	København V	Ballumgade		False	1
1754	København V	Hedebygade		False	1
1755	København V	Møgeltøndergade		False	1
1756	København V	Amerikavej		False	1
1757	København V	Trøjborggade		False	1
1758	København V	Lyrskovgade		False	1
1759	København V	Rejsbygade		False	1
1760	København V	Ny Carlsberg Vej 1-37 og 2-66		False	1
1761	København V	Ejderstedgade		False	1
1762	København V	Slesvigsgade		False	1
1763	København V	Dannevirkegade		False	1
1764	København V	Alsgade		False	1
1765	København V	Angelgade		False	1
1766	København V	Slien		False	1
1770	København V	Carstensgade		False	1
1771	København V	Lundbyesgade		False	1
1772	København V	Ernst Meyers Gade		False	1
1773	København V	Bissensgade		False	1
1774	København V	Küchlersgade		False	1
1775	København V	Freundsgade		False	1
1777	København V	Jerichausgade		False	1
1780	København V		Erhvervskunder	False	1
1782	København V	Ufrankerede svarforsendelser		False	1
1785	København V	Rådhuspladsen 33 og 37	Politiken og Ekstrabladet	False	1
1786	København V	Vesterbrogade 8	Nordea	False	1
1787	København V	H.C. Andersens Boulevard 18	Dansk Industri	False	1
1790	København V		Erhvervskunder	False	1
1799	København V	Bag Elefanterne		False	1
1799	København V	Banevolden 2		False	1
1799	København V	Bjerregårdsvej 5 og 7		False	1
1799	København V	Bryggernes Plads		False	1
1799	København V	Gamle Carlsberg Vej		False	1
1799	København V	Kammasvej 2, 4 og 6		False	1
1799	København V	Ny Carlsberg Vej fra 39 og fra 68		False	1
1799	København V	Ottilia Jacobsens Plads		False	1
1799	København V	Pasteursvej		False	1
1799	København V	Rahbeks Allé 13-15		False	1
1799	København V	Valby Langgade 1		False	1
1799	København V	Vesterfælledvej 58-110		False	1
1800	Frederiksberg C	Vesterbrogade 161-191 og 162-208		False	1
1801	Frederiksberg C	Rahbeks Alle 2-36		False	1
1802	Frederiksberg C	Halls Alle		False	1
1803	Frederiksberg C	Brøndsteds Alle		False	1
1804	Frederiksberg C	Bakkegårds Alle		False	1
1805	Frederiksberg C	Kammasvej 3		False	1
1806	Frederiksberg C	Jacobys Alle		False	1
1807	Frederiksberg C	Schlegels Alle		False	1
1808	Frederiksberg C	Asmussens Alle		False	1
1809	Frederiksberg C	Frydendalsvej		False	1
1810	Frederiksberg C	Platanvej		False	1
1811	Frederiksberg C	Asgårdsvej		False	1
1812	Frederiksberg C	Kochsvej		False	1
1813	Frederiksberg C	Henrik Ibsens Vej		False	1
1814	Frederiksberg C	Carit Etlars Vej		False	1
1815	Frederiksberg C	Paludan Müllers Vej		False	1
1816	Frederiksberg C	Engtoftevej		False	1
1817	Frederiksberg C	Carl Bernhards Vej		False	1
1818	Frederiksberg C	Kingosgade 11-17 og 8-10		False	1
1819	Frederiksberg C	Værnedamsvej ulige nr.		False	1
1820	Frederiksberg C	Frederiksberg Alle 15-63 og 2-104		False	1
1822	Frederiksberg C	Boyesgade lige nr.		False	1
1823	Frederiksberg C	Haveselskabetsvej		False	1
1824	Frederiksberg C	Sankt Thomas Alle		False	1
1825	Frederiksberg C	Hauchsvej		False	1
1826	Frederiksberg C	Alhambravej		False	1
1827	Frederiksberg C	Mynstersvej		False	1
1828	Frederiksberg C	Martensens Alle		False	1
1829	Frederiksberg C	Madvigs Alle		False	1
1835	Frederiksberg C	Postboks		False	1
1850	Frederiksberg C	Gammel Kongevej 85-179 og 60-178		False	1
1851	Frederiksberg C	Nyvej		False	1
1852	Frederiksberg C	Amicisvej		False	1
1853	Frederiksberg C	Maglekildevej		False	1
1854	Frederiksberg C	Dr. Priemes Vej		False	1
1855	Frederiksberg C	Hollændervej		False	1
1856	Frederiksberg C	Edisonsvej		False	1
1857	Frederiksberg C	Hortensiavej		False	1
1860	Frederiksberg C	Christian Winthers Vej		False	1
1861	Frederiksberg C	Sagasvej		False	1
1862	Frederiksberg C	Rathsacksvej		False	1
1863	Frederiksberg C	Ceresvej		False	1
1864	Frederiksberg C	Grundtvigsvej		False	1
1865	Frederiksberg C	Grundtvigs Sidevej		False	1
1866	Frederiksberg C	Henrik Steffens Vej		False	1
1867	Frederiksberg C	Acaciavej		False	1
1868	Frederiksberg C	Bianco Lunos Alle		False	1
1870	Frederiksberg C	Bülowsvej		False	1
1871	Frederiksberg C	Thorvaldsensvej		False	1
1872	Frederiksberg C	Bomhoffs Have		False	1
1873	Frederiksberg C	Helenevej		False	1
1874	Frederiksberg C	Harsdorffsvej		False	1
1875	Frederiksberg C	Amalievej		False	1
1876	Frederiksberg C	Kastanievej		False	1
1877	Frederiksberg C	Lindevej		False	1
1878	Frederiksberg C	Uraniavej		False	1
1879	Frederiksberg C	H.C. Ørsteds Vej		False	1
1900	Frederiksberg C	Vodroffsvej		False	1
1901	Frederiksberg C	Tårnborgvej		False	1
1902	Frederiksberg C	Lykkesholms Alle		False	1
1903	Frederiksberg C	Sankt Knuds Vej		False	1
1904	Frederiksberg C	Forhåbningsholms Alle		False	1
1905	Frederiksberg C	Svanholmsvej		False	1
1906	Frederiksberg C	Schønbergsgade		False	1
1908	Frederiksberg C	Prinsesse Maries Alle		False	1
1909	Frederiksberg C	Vodroffs Tværgade		False	1
1910	Frederiksberg C	Danasvej		False	1
1911	Frederiksberg C	Niels Ebbesens Vej		False	1
1912	Frederiksberg C	Svend Trøsts Vej		False	1
1913	Frederiksberg C	Carl Plougs Vej		False	1
1914	Frederiksberg C	Vodroffslund		False	1
1915	Frederiksberg C	Danas Plads		False	1
1916	Frederiksberg C	Norsvej		False	1
1917	Frederiksberg C	Sveasvej		False	1
1920	Frederiksberg C	Forchhammersvej		False	1
1921	Frederiksberg C	Sankt Markus Plads		False	1
1922	Frederiksberg C	Sankt Markus Alle		False	1
1923	Frederiksberg C	Johnstrups Alle		False	1
1924	Frederiksberg C	Steenstrups Alle		False	1
1925	Frederiksberg C	Julius Thomsens Plads		False	1
1926	Frederiksberg C	Martinsvej		False	1
1927	Frederiksberg C	Suomisvej		False	1
1928	Frederiksberg C	Filippavej		False	1
1931	Frederiksberg C	Ufrankerede svarforsendelser 		False	1
1950	Frederiksberg C	Hostrupsvej		False	1
1951	Frederiksberg C	Christian Richardts Vej		False	1
1952	Frederiksberg C	Falkonervænget		False	1
1953	Frederiksberg C	Sankt Nikolaj Vej		False	1
1954	Frederiksberg C	Hostrups Have		False	1
1955	Frederiksberg C	Dr. Abildgaards Alle		False	1
1956	Frederiksberg C	L.I. Brandes Alle		False	1
1957	Frederiksberg C	N.J. Fjords Alle		False	1
1958	Frederiksberg C	Rolighedsvej		False	1
1959	Frederiksberg C	Falkonergårdsvej		False	1
1960	Frederiksberg C	Åboulevard 15-55		False	1
1961	Frederiksberg C	J.M. Thieles Vej		False	1
1962	Frederiksberg C	Fuglevangsvej		False	1
1963	Frederiksberg C	Bille Brahes Vej		False	1
1964	Frederiksberg C	Ingemannsvej		False	1
1965	Frederiksberg C	Erik Menveds Vej		False	1
1966	Frederiksberg C	Steenwinkelsvej		False	1
1967	Frederiksberg C	Svanemosegårdsvej		False	1
1970	Frederiksberg C	Rosenørns Alle 1-67 og 22-70		False	1
1971	Frederiksberg C	Adolph Steens Alle		False	1
1972	Frederiksberg C	Worsaaesvej		False	1
1973	Frederiksberg C	Jakob Dannefærds Vej		False	1
1974	Frederiksberg C	Julius Thomsens Gade ulige nr.		False	1
2000	Frederiksberg			False	1
2100	København Ø			False	1
2150	Nordhavn			False	1
2200	København N			False	1
2300	København S			False	1
2400	København NV			False	1
2450	København SV			False	1
2500	Valby			False	1
2600	Glostrup			True	1
2605	Brøndby			True	1
2610	Rødovre			True	1
2620	Albertslund			True	1
2625	Vallensbæk			True	1
2630	Taastrup			True	1
2635	Ishøj			True	1
2640	Hedehusene			True	1
2650	Hvidovre			True	1
2660	Brøndby Strand			True	1
2665	Vallensbæk Strand			True	1
2670	Greve			True	1
2680	Solrød Strand			True	1
2690	Karlslunde			True	1
2700	Brønshøj			False	1
2720	Vanløse			False	1
2730	Herlev			True	1
2740	Skovlunde			True	1
2750	Ballerup			True	1
2760	Måløv			True	1
2765	Smørum			True	1
2770	Kastrup			True	1
2791	Dragør			True	1
2800	Kongens Lyngby			True	1
2820	Gentofte			True	1
2830	Virum			True	1
2840	Holte			True	1
2850	Nærum			True	1
2860	Søborg			True	1
2870	Dyssegård			True	1
2880	Bagsværd			True	1
2900	Hellerup			True	1
2920	Charlottenlund			True	1
2930	Klampenborg			True	1
2942	Skodsborg			True	1
2950	Vedbæk			True	1
2960	Rungsted Kyst			True	1
2970	Hørsholm			True	1
2980	Kokkedal			True	1
2990	Nivå			True	1
3000	Helsingør			True	1
3050	Humlebæk			True	1
3060	Espergærde			True	1
3070	Snekkersten			True	1
3080	Tikøb			True	1
3100	Hornbæk			True	1
3120	Dronningmølle			True	1
3140	Ålsgårde			True	1
3150	Hellebæk			True	1
3200	Helsinge			True	1
3210	Vejby			True	1
3220	Tisvildeleje			True	1
3230	Græsted			True	1
3250	Gilleleje			True	1
3300	Frederiksværk			True	1
3310	Ølsted			True	1
3320	Skævinge			True	1
3330	Gørløse			True	1
3360	Liseleje			True	1
3370	Melby			True	1
3390	Hundested			True	1
3400	Hillerød			True	1
3450	Allerød			True	1
3460	Birkerød			True	1
3480	Fredensborg			True	1
3490	Kvistgård			True	1
3500	Værløse			True	1
3520	Farum			True	1
3540	Lynge			True	1
3550	Slangerup			True	1
3600	Frederikssund			True	1
3630	Jægerspris			True	1
3650	Ølstykke			True	1
3660	Stenløse			True	1
3670	Veksø Sjælland			True	1
3700	Rønne			True	1
3720	Aakirkeby			True	1
3730	Nexø			True	1
3740	Svaneke			True	1
3751	Østermarie			True	1
3760	Gudhjem			True	1
3770	Allinge			True	1
3782	Klemensker			True	1
3790	Hasle			True	1
4000	Roskilde			True	1
4030	Tune			True	1
4040	Jyllinge			True	1
4050	Skibby			True	1
4060	Kirke Såby			True	1
4070	Kirke Hyllinge			True	1
4100	Ringsted			True	1
4129	Ringsted	Ufrankerede svarforsendelser		True	1
4130	Viby Sjælland			True	1
4140	Borup			True	1
4160	Herlufmagle			True	1
4171	Glumsø			True	1
4173	Fjenneslev			True	1
4174	Jystrup Midtsj			True	1
4180	Sorø			True	1
4190	Munke Bjergby			True	1
4200	Slagelse			True	1
4220	Korsør			True	1
4230	Skælskør			True	1
4241	Vemmelev			True	1
4242	Boeslunde			True	1
4243	Rude			True	1
4250	Fuglebjerg			True	1
4261	Dalmose			True	1
4262	Sandved			True	1
4270	Høng			True	1
4281	Gørlev			True	1
4291	Ruds Vedby			True	1
4293	Dianalund			True	1
4295	Stenlille			True	1
4296	Nyrup			True	1
4300	Holbæk			True	1
4320	Lejre			True	1
4330	Hvalsø			True	1
4340	Tølløse			True	1
4350	Ugerløse			True	1
4360	Kirke Eskilstrup			True	1
4370	Store Merløse			True	1
4390	Vipperød			True	1
4400	Kalundborg			True	1
4420	Regstrup			True	1
4440	Mørkøv			True	1
4450	Jyderup			True	1
4460	Snertinge			True	1
4470	Svebølle			True	1
4480	Store Fuglede			True	1
4490	Jerslev Sjælland			True	1
4500	Nykøbing Sj			True	1
4520	Svinninge			True	1
4532	Gislinge			True	1
4534	Hørve			True	1
4540	Fårevejle			True	1
4550	Asnæs			True	1
4560	Vig			True	1
4571	Grevinge			True	1
4572	Nørre Asmindrup			True	1
4573	Højby			True	1
4581	Rørvig			True	1
4583	Sjællands Odde			True	1
4591	Føllenslev			True	1
4592	Sejerø			True	1
4593	Eskebjerg			True	1
4600	Køge			True	1
4621	Gadstrup			True	1
4622	Havdrup			True	1
4623	Lille Skensved			True	1
4632	Bjæverskov			True	1
4640	Faxe			True	1
4652	Hårlev			True	1
4653	Karise			True	1
4654	Faxe Ladeplads			True	1
4660	Store Heddinge			True	1
4671	Strøby			True	1
4672	Klippinge			True	1
4673	Rødvig Stevns			True	1
4681	Herfølge			True	1
4682	Tureby			True	1
4683	Rønnede			True	1
4684	Holmegaard			True	1
4690	Haslev			True	1
4700	Næstved			True	1
4720	Præstø			True	1
4733	Tappernøje			True	1
4735	Mern			True	1
4736	Karrebæksminde			True	1
4750	Lundby			True	1
4760	Vordingborg			True	1
4771	Kalvehave			True	1
4772	Langebæk			True	1
4773	Stensved			True	1
4780	Stege			True	1
4791	Borre			True	1
4792	Askeby			True	1
4793	Bogø By			True	1
4800	Nykøbing F			True	1
4840	Nørre Alslev			True	1
4850	Stubbekøbing			True	1
4862	Guldborg			True	1
4863	Eskilstrup			True	1
4871	Horbelev			True	1
4872	Idestrup			True	1
4873	Væggerløse			True	1
4874	Gedser			True	1
4880	Nysted			True	1
4891	Toreby L			True	1
4892	Kettinge			True	1
4894	Øster Ulslev			True	1
4895	Errindlev			True	1
4900	Nakskov			True	1
4912	Harpelunde			True	1
4913	Horslunde			True	1
4920	Søllested			True	1
4930	Maribo			True	1
4941	Bandholm			True	1
4943	Torrig L			True	1
4944	Fejø			True	1
4951	Nørreballe			True	1
4952	Stokkemarke			True	1
4953	Vesterborg			True	1
4960	Holeby			True	1
4970	Rødby			True	1
4983	Dannemare			True	1
4990	Sakskøbing			True	1
4992	Midtsjælland USF P	Ufrankerede svarforsendelser		True	1
5000	Odense C			True	1
5029	Odense C	Ufrankerede svarforsendelser		True	1
5100	Odense C	Postboks		True	1
5200	Odense V			True	1
5210	Odense NV			True	1
5220	Odense SØ			True	1
5230	Odense M			True	1
5240	Odense NØ			True	1
5250	Odense SV			True	1
5260	Odense S			True	1
5270	Odense N			True	1
5290	Marslev			True	1
5300	Kerteminde			True	1
5320	Agedrup			True	1
5330	Munkebo			True	1
5350	Rynkeby			True	1
5370	Mesinge			True	1
5380	Dalby			True	1
5390	Martofte			True	1
5400	Bogense			True	1
5450	Otterup			True	1
5462	Morud			True	1
5463	Harndrup			True	1
5464	Brenderup Fyn			True	1
5466	Asperup			True	1
5471	Søndersø			True	1
5474	Veflinge			True	1
5485	Skamby			True	1
5491	Blommenslyst			True	1
5492	Vissenbjerg			True	1
5500	Middelfart			True	1
5540	Ullerslev			True	1
5550	Langeskov			True	1
5560	Aarup			True	1
5580	Nørre Aaby			True	1
5591	Gelsted			True	1
5592	Ejby			True	1
5600	Faaborg			True	1
5610	Assens			True	1
5620	Glamsbjerg			True	1
5631	Ebberup			True	1
5642	Millinge			True	1
5672	Broby			True	1
5683	Haarby			True	1
5690	Tommerup			True	1
5700	Svendborg			True	1
5750	Ringe			True	1
5762	Vester Skerninge			True	1
5771	Stenstrup			True	1
5772	Kværndrup			True	1
5792	Årslev			True	1
5800	Nyborg			True	1
5853	Ørbæk			True	1
5854	Gislev			True	1
5856	Ryslinge			True	1
5863	Ferritslev Fyn			True	1
5871	Frørup			True	1
5874	Hesselager			True	1
5881	Skårup Fyn			True	1
5882	Vejstrup			True	1
5883	Oure			True	1
5884	Gudme			True	1
5892	Gudbjerg Sydfyn			True	1
5900	Rudkøbing			True	1
5932	Humble			True	1
5935	Bagenkop			True	1
5953	Tranekær			True	1
5960	Marstal			True	1
5970	Ærøskøbing			True	1
5985	Søby Ærø			True	1
6000	Kolding			True	1
6040	Egtved			True	1
6051	Almind			True	1
6052	Viuf			True	1
6064	Jordrup			True	1
6070	Christiansfeld			True	1
6091	Bjert			True	1
6092	Sønder Stenderup			True	1
6093	Sjølund			True	1
6094	Hejls			True	1
6100	Haderslev			True	1
6200	Aabenraa			True	1
6230	Rødekro			True	1
6240	Løgumkloster			True	1
6261	Bredebro			True	1
6270	Tønder			True	1
6280	Højer			True	1
6300	Gråsten			True	1
6310	Broager			True	1
6320	Egernsund			True	1
6330	Padborg			True	1
6340	Kruså			True	1
6360	Tinglev			True	1
6372	Bylderup-Bov			True	1
6392	Bolderslev			True	1
6400	Sønderborg			True	1
6430	Nordborg			True	1
6440	Augustenborg			True	1
6470	Sydals			True	1
6500	Vojens			True	1
6510	Gram			True	1
6520	Toftlund			True	1
6534	Agerskov			True	1
6535	Branderup J			True	1
6541	Bevtoft			True	1
6560	Sommersted			True	1
6580	Vamdrup			True	1
6600	Vejen			True	1
6621	Gesten			True	1
6622	Bække			True	1
6623	Vorbasse			True	1
6630	Rødding			True	1
6640	Lunderskov			True	1
6650	Brørup			True	1
6660	Lintrup			True	1
6670	Holsted			True	1
6682	Hovborg			True	1
6683	Føvling			True	1
6690	Gørding			True	1
6700	Esbjerg			True	1
6701	Esbjerg	Postboks		True	1
6705	Esbjerg Ø			True	1
6710	Esbjerg V			True	1
6715	Esbjerg N			True	1
6720	Fanø			True	1
6731	Tjæreborg			True	1
6740	Bramming			True	1
6752	Glejbjerg			True	1
6753	Agerbæk			True	1
6760	Ribe			True	1
6771	Gredstedbro			True	1
6780	Skærbæk			True	1
6792	Rømø			True	1
6800	Varde			True	1
6818	Årre			True	1
6823	Ansager			True	1
6830	Nørre Nebel			True	1
6840	Oksbøl			True	1
6851	Janderup Vestj			True	1
6852	Billum			True	1
6853	Vejers Strand			True	1
6854	Henne			True	1
6855	Outrup			True	1
6857	Blåvand			True	1
6862	Tistrup			True	1
6870	Ølgod			True	1
6880	Tarm			True	1
6893	Hemmet			True	1
6900	Skjern			True	1
6920	Videbæk			True	1
6933	Kibæk			True	1
6940	Lem St			True	1
6950	Ringkøbing			True	1
6960	Hvide Sande			True	1
6971	Spjald			True	1
6973	Ørnhøj			True	1
6980	Tim			True	1
6990	Ulfborg			True	1
7000	Fredericia			True	1
7007	Fredericia		Sydjyllands Postcenter + erhvervskunder	True	1
7017	Taulov Pakkecenter		(Returpakker)	True	1
7018	Pakker TLP		(Returpakker)	True	1
7029	Fredericia	Ufrankerede svarforsendelser		True	1
7080	Børkop			True	1
7100	Vejle			True	1
7120	Vejle Øst			True	1
7130	Juelsminde			True	1
7140	Stouby			True	1
7150	Barrit			True	1
7160	Tørring			True	1
7171	Uldum			True	1
7173	Vonge			True	1
7182	Bredsten			True	1
7183	Randbøl			True	1
7184	Vandel			True	1
7190	Billund			True	1
7200	Grindsted			True	1
7250	Hejnsvig			True	1
7260	Sønder Omme			True	1
7270	Stakroge			True	1
7280	Sønder Felding			True	1
7300	Jelling			True	1
7321	Gadbjerg			True	1
7323	Give			True	1
7330	Brande			True	1
7361	Ejstrupholm			True	1
7362	Hampen			True	1
7400	Herning			True	1
7429	Herning	Ufrankerede svarforsendelser		True	1
7430	Ikast			True	1
7441	Bording			True	1
7442	Engesvang			True	1
7451	Sunds			True	1
7470	Karup J			True	1
7480	Vildbjerg			True	1
7490	Aulum			True	1
7500	Holstebro			True	1
7540	Haderup			True	1
7550	Sørvad			True	1
7560	Hjerm			True	1
7570	Vemb			True	1
7600	Struer			True	1
7620	Lemvig			True	1
7650	Bøvlingbjerg			True	1
7660	Bækmarksbro			True	1
7673	Harboøre			True	1
7680	Thyborøn			True	1
7700	Thisted			True	1
7730	Hanstholm			True	1
7741	Frøstrup			True	1
7742	Vesløs			True	1
7752	Snedsted			True	1
7755	Bedsted Thy			True	1
7760	Hurup Thy			True	1
7770	Vestervig			True	1
7790	Thyholm			True	1
7800	Skive			True	1
7830	Vinderup			True	1
7840	Højslev			True	1
7850	Stoholm Jyll			True	1
7860	Spøttrup			True	1
7870	Roslev			True	1
7884	Fur			True	1
7900	Nykøbing M			True	1
7950	Erslev			True	1
7960	Karby			True	1
7970	Redsted M			True	1
7980	Vils			True	1
7990	Øster Assels			True	1
7992	Sydjylland/Fyn USF P	Ufrankerede svarforsendelser		True	1
7993	Sydjylland/Fyn USF B	Ufrankerede svarforsendelser		True	1
7996	Fakturaservice		(Post til scanning)	True	1
7997	Fakturascanning		(Post til scanning)	True	1
7998	Statsservice		(Post til scanning)	True	1
7999	Kommunepost		(Post til scanning)	True	1
8000	Aarhus C			True	1
8100	Aarhus C	Postboks		True	1
8200	Aarhus N			True	1
8210	Aarhus V			True	1
8220	Brabrand			True	1
8229	Risskov Ø	Ufrankerede svarforsendelser		True	1
8230	Åbyhøj			True	1
8240	Risskov			True	1
8245	Risskov Ø		Østjyllands Postcenter + erhvervskunder	True	1
8250	Egå			True	1
8260	Viby J			True	1
8270	Højbjerg			True	1
8300	Odder			True	1
8305	Samsø			True	1
8310	Tranbjerg J			True	1
8320	Mårslet			True	1
8330	Beder			True	1
8340	Malling			True	1
8350	Hundslund			True	1
8355	Solbjerg			True	1
8361	Hasselager			True	1
8362	Hørning			True	1
8370	Hadsten			True	1
8380	Trige			True	1
8381	Tilst			True	1
8382	Hinnerup			True	1
8400	Ebeltoft			True	1
8410	Rønde			True	1
8420	Knebel			True	1
8444	Balle			True	1
8450	Hammel			True	1
8462	Harlev J			True	1
8464	Galten			True	1
8471	Sabro			True	1
8472	Sporup			True	1
8500	Grenaa			True	1
8520	Lystrup			True	1
8530	Hjortshøj			True	1
8541	Skødstrup			True	1
8543	Hornslet			True	1
8544	Mørke			True	1
8550	Ryomgård			True	1
8560	Kolind			True	1
8570	Trustrup			True	1
8581	Nimtofte			True	1
8585	Glesborg			True	1
8586	Ørum Djurs			True	1
8592	Anholt			True	1
8600	Silkeborg			True	1
8620	Kjellerup			True	1
8632	Lemming			True	1
8641	Sorring			True	1
8643	Ans By			True	1
8653	Them			True	1
8654	Bryrup			True	1
8660	Skanderborg			True	1
8670	Låsby			True	1
8680	Ry			True	1
8700	Horsens			True	1
8721	Daugård			True	1
8722	Hedensted			True	1
8723	Løsning			True	1
8732	Hovedgård			True	1
8740	Brædstrup			True	1
8751	Gedved			True	1
8752	Østbirk			True	1
8762	Flemming			True	1
8763	Rask Mølle			True	1
8765	Klovborg			True	1
8766	Nørre Snede			True	1
8781	Stenderup			True	1
8783	Hornsyld			True	1
8800	Viborg			True	1
8830	Tjele			True	1
8831	Løgstrup			True	1
8832	Skals			True	1
8840	Rødkærsbro			True	1
8850	Bjerringbro			True	1
8860	Ulstrup			True	1
8870	Langå			True	1
8881	Thorsø			True	1
8882	Fårvang			True	1
8883	Gjern			True	1
8900	Randers C			True	1
8920	Randers NV			True	1
8930	Randers NØ			True	1
8940	Randers SV			True	1
8950	Ørsted			True	1
8960	Randers SØ			True	1
8961	Allingåbro			True	1
8963	Auning			True	1
8970	Havndal			True	1
8981	Spentrup			True	1
8983	Gjerlev J			True	1
8990	Fårup			True	1
9000	Aalborg			True	1
9029	Aalborg	Ufrankerede svarforsendelser		True	1
9100	Aalborg	Postboks		True	1
9200	Aalborg SV			True	1
9210	Aalborg SØ			True	1
9220	Aalborg Øst			True	1
9230	Svenstrup J			True	1
9240	Nibe			True	1
9260	Gistrup			True	1
9270	Klarup			True	1
9280	Storvorde			True	1
9293	Kongerslev			True	1
9300	Sæby			True	1
9310	Vodskov			True	1
9320	Hjallerup			True	1
9330	Dronninglund			True	1
9340	Asaa			True	1
9352	Dybvad			True	1
9362	Gandrup			True	1
9370	Hals			True	1
9380	Vestbjerg			True	1
9381	Sulsted			True	1
9382	Tylstrup			True	1
9400	Nørresundby			True	1
9430	Vadum			True	1
9440	Aabybro			True	1
9460	Brovst			True	1
9480	Løkken			True	1
9490	Pandrup			True	1
9492	Blokhus			True	1
9493	Saltum			True	1
9500	Hobro			True	1
9510	Arden			True	1
9520	Skørping			True	1
9530	Støvring			True	1
9541	Suldrup			True	1
9550	Mariager			True	1
9560	Hadsund			True	1
9574	Bælum			True	1
9575	Terndrup			True	1
9600	Aars			True	1
9610	Nørager			True	1
9620	Aalestrup			True	1
9631	Gedsted			True	1
9632	Møldrup			True	1
9640	Farsø			True	1
9670	Løgstør			True	1
9681	Ranum			True	1
9690	Fjerritslev			True	1
9700	Brønderslev			True	1
9740	Jerslev J			True	1
9750	Østervrå			True	1
9760	Vrå			True	1
9800	Hjørring			True	1
9830	Tårs			True	1
9850	Hirtshals			True	1
9870	Sindal			True	1
9881	Bindslev			True	1
9900	Frederikshavn			True	1
9940	Læsø			True	1
9970	Strandby			True	1
9981	Jerup			True	1
9982	Ålbæk			True	1
9990	Skagen			True	1
9992	Jylland USF P	Ufrankerede svarforsendelser		True	1
9993	Jylland USF B	Ufrankerede svarforsendelser		True	1
9996	Fakturaservice		(Post til scanning)	True	1
9997	Fakturascanning		(Post til scanning)	True	1
9998	Borgerservice		(Post til scanning)	True	1
