package Data::Rand;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.4');

use base 'Exporter';
our @EXPORT    = qw( rand_data );
our @EXPORT_OK = qw( rand_data_string rand_data_array );

sub seed_calc_with {
    require Time::HiRes;
    my ($sec, $mic) = Time::HiRes::gettimeofday();
    srand($sec ^ $mic ^ $$ ^ shift() || rand( 999_999_999_999_999 ));    
}

sub rand_data {
	my $options_hr = ref $_[-1] eq 'HASH' ? pop @_ : {}; # last item a hashref or not
	%{ $options_hr->{'details'} } = ();
	
    my ( $size, $items_ar ) = @_;

    $size = 32 if !defined $size || $size eq '0' || $size !~ m{ \A \d+ \z }xms;
    $options_hr->{'details'}{'size'} = $size;

    my @items = ( 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
    $options_hr->{'details'}{'using_default_list'} = 1;

    if ( ref $items_ar eq 'ARRAY' ) {
        if ( @{ $items_ar } ) {
	        @items = @{ $items_ar };
	        $options_hr->{'details'}{'using_default_list'} = 0;
        }	
    }
    $options_hr->{'details'}{'items'} = [ @items ];

    if ( $options_hr->{'use_unique_list'} && !$options_hr->{'details'}{'using_default_list'} ) {
        my %uniq;
	    @items = map { $uniq{$_}++ == 0 ? $_ : () } @items; # see List::MoreUtils::uniq() #left prec, reverse @_ right prec
    }

    $size = @items if $size > @items && $options_hr->{'do_not_repeat_index'};
    my $len = scalar @items;
    
    my $get_random_index = sub { rand shift() };
    
    $options_hr->{'details'}{'using_default_index_picker'} = 1;
    if ( ref $options_hr->{'get_random_index'} eq 'CODE' ) {
        $options_hr->{'details'}{'using_default_index_picker'} = 0; 
        $get_random_index = $options_hr->{'get_random_index'};
    }
    
    my @data;
    my %used;
    
    PART:
    for ( 1 .. $size ) {
	    my $index = int( $get_random_index->($len) ); # negatives ok so no abs()
        if( $options_hr->{'do_not_repeat_index'} ) {
            my $try = 0;
            TRY:
		    while ( exists $used{ $index } ) {
		        $try++;
			    $index = int( $get_random_index->($len) ); # negatives ok so no abs()
			    last TRY if $try > $size; # keep a custom index fetcher from causing infinite loop
		    }
		    $used{ $index }++;
        }

        push @data, $items[ $index ];
    }

    return wantarray ? @data : join('', @data);
}

sub rand_data_string {
    return scalar( rand_data(@_) );	
}

sub rand_data_array {
	my @rand = rand_data(@_);
	return wantarray ? @rand : \@rand;
}

1; 

__END__

=head1 NAME

Data::Rand - Random string and list utility

=head1 VERSION

This document describes Data::Rand version 0.0.4

=head1 SYNOPSIS

    use Data::Rand;

    my $rand_32_str = rand_data();
    my $rand_64_str = rand_data(64);
    my @contestants = rand_data( 2, \@studio_audience, { 'do_not_repeat_index' => 1 } ); 
    my $doubledigit = rand_data( 2, [0 .. 9] );
    my @rolled_dice = rand_data( 2, [1 .. 6] );
    my $pickanumber = rand_data( 1, [1 .. 1000] );

=head1 DESCRIPTION

Simple interface to easily get a string or array made of randomly chosen pieces of a set of data.

=head1 How Random is "Random"?

That depends much on you.

Data::Rand works by building a string or array of the given length from a list of items that are "randomly" chosen, by default, using perl's built in L<rand>().

You can affect L<rand>()'s effectiveness by calling L<srand>() or L</seed_calc_with>() as you need.

You can also override the use of L<rand>() internally altogether with something as mathmatically random as you like.

You can pass arguments as well which will affect how likley a not-so-random seeming pattern will emerge (for example: rand_data(1,['a']) will always return 'a', which is always predictable)

The tests for this module call rand_data() without calling L<srand>() explicitly, with no arguments (IE out of the box defaults) 100,000 times and fails if there are any duplicates.

There's an optional test that does it 1,000,000 times but its not done by default simply for the sake of time and memory (for the test's lookup hash). From version zero-zero-four on new releases of this module must pass that test before being published.

So if that's "random" enough for you, well, there you have it!

If not, you can always make it more "truly" random as per the POD below.

=head1 EXPORT

rand_data() is exported by default. rand_data_string() and rand_data_array() are exportable.

=head1 INTERFACE 

=head2 rand_data()

In scalar context returns a string made of a number of parts you want made up from an array of parts.

In array context it returns a list the length of number of parts you want where each item is from the array of parts.

Takes 0 to 3 arguments:

=over

=item 1) length or number of random parts (default if not given or invalid is 32)

=item 2) array ref of parts (default if not given or invalid is 0 .. 9 and upper and lower case a-z)

=item 3) hashref of behavioral options (this one can also be passed as the only argument or the second argument so long as its the *last* argument)

keys and values are described below, unless otherwise noted options are booleans which default to false

=over

=item * 'use_unique_list' 

Make sure array of parts is unique. If you're passing the same list more than once and you are doing this each time it'd be more efficient to uniq() the list once and pass that to the function instead of using this.

=item * 'do_not_repeat_index' 

Do not use any index of the array of parts more than once.

Caveat: if the length is longer than the list of items then the length is silently adjusted to the length of the list.

    my $length = 10;
    my @random = rand_data( $length, @deck_of_cards, { 'do_not_repeat_index' => 1 } );
    # @random has 10 items

    my $length = 53;
    my @random = rand_data( $length, @deck_of_cards, { 'do_not_repeat_index' => 1 } );
    # @random has 52 items

Caveat: This is not a uniq() functionality on the list of items, this is "no repeat" based on index. So:

    rand_data(3, [qw(dan dan dan)]);

is valid (if not very useful) because it won't use index 0, 1, or 2 more than once

This is probably what you'd want:

    rand_data($n, [ uniq @people ] ); # could still contain duplicates in results by using the same index more than once

or even:

    rand_data($n, \@people, { 'do_not_repeat_index' => 1, 'use_unique_list' => 1 } ); # definitely no duplicates since you uniq()ed the list *and* told it to only use each index at most once

Caveat: This also increases calculation time since it has to see if 
a randomly chosen index has already been used and if so try again. 

=item * 'get_random_index'

This should be a code ref that accepts one argument, the number of items we have to choose from, and returns an index chosen at random (however you choose to define "random")

    sub {
        my ($length) = @_;
        return Crypt::Random::makerandom_itv( 'Lower' => 0, 'Upper' => $length, ...); 
    }

Note: The above example (w/ Strong => 0 (IE read() is not being blocked on /dev/random)) benchmarked appx 570 times as slow as the default L<rand>() based solution but its much more truly random.

=back

=back

=head2 rand_data_string()

Same args as rand_data(). The difference is that it always returns a string regardless of context.

    my $rand_str = rand_data_string( @rand_args ); # $rand_str contains the random string.
    my @stuff    = rand_data_string( @rand_args ); # $stuff[0] contains the random string.

=head2 rand_data_array()

Same args as rand_data(). The difference is that it always returns an array regardless of context.

    my @rand_data = rand_data_array( @rand_args ); # @rand_data contains the random items
    my $rand_data = rand_data_array( @rand_args ); # $rand_data is an array ref to the list of random items

=head2 seed_calc_with()

This is a simple shortcut function you can use to call L<srand>() for you with a pre-done calculation as outlined below. If this does not do what you like use L<srand>() directly.

It brings in L<Time::HiRes> for you if needed and then calls L<srand>() like so:

    srand($hires_time, $hires_micro_seconds, $$, 'YOUR ARGUEMENT HERE' || rand( 999_999_999_999_999));

You don't have to call it of course but here are some examples if you choose to:

    seed_calc_with();                                  # same as seed_calc_with( rand( 999_999_999_999_999 ) );
    seed_calc_with( rand( 999_999_999_999_999 ) );     # same as seed_calc_with();
    seed_calc_with( unpack '%L*', `ps axww | gzip` );
    seed_calc_with( Math::TrulyRandom::truly_random_value() );
    seed_calc_with( Crypt::Random::makerandom(...) ); 

Its not exportable on purpose to discourage blindly using it since calling L<srand>() improperly can result in L<rand>()'s result being less random.

See L<srand> and L<rand> for more information.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT
  
Data::Rand requires no configuration files or environment variables.

=head1 DEPENDENCIES

L</seed_calc_with>() brings in L<Time::HiRes>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-rand@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Re-add tests I had worked up that went away with a failed HD

May add these behaviorial booleans to option hashref depending on feedback:

    'return_on_bad_args' # do not use defaults, just return;
    'carp_on_bad_args'   # carp() about what args are bad and why
    'croak_on_bad_args'  # same as carp but fatal

Gratefully apply helpful suggestions to make this module better

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.