package Data::Random::Flexible;

use strict;
use warnings;

use Try::Tiny;
use Module::Runtime qw(require_module);

my $engines;

BEGIN {
    my @optional = qw(
        Math::Random::Secure
        Math::Random::MTwist
        Math::Random::Xorshift
        Math::Random::MT
        Math::Random::ISAAC
        Crypt::PRNG
    );

    foreach my $module (@optional) {
        try {
            require_module $module;
            $engines->{$module} = 1;
        };
    }

    # Add Core::rand back
    $engines->{'CORE'} = 1;
}

=head1 NAME

Data::Random::Flexible - Flexible fast-to-write profilable randoms

=head1 VERSION

Version 1.06

=cut

our $VERSION = '1.06';


=head1 SYNOPSIS

A more flexible set of randoms for when you want to be random FAST

    use Data::Random::Flexible;

    use feature "say";

    my $random = Data::Random::Flexible->new();

    say "32 Characters of random numbers?, sure: ".$random->int(32);

    say "16 Characters of random letters?, sure: ".$random->char(16);

    say "16 Of a mixture of numbers and letters?, sure: ".$random->mix(16);

    say "Random mixture of 16 your own characters?, sure: ".$random->profile('irc',16, [qw(I r C 1 2 3)]);
    
    say "Random mixture of 16 your own characters from a saved profile?, sure: ".$random->profile('irc',16);

The module can also use alternative providers for rand(), for more detail look at the engine() function,
the currently supported providers of random are:

        Math::Random::Secure
        Math::Random::MTwist
        Math::Random::Xorshift
        Math::Random::MT
        Math::Random::ISAAC
        Math::Random::ISAAC::XS (Not selectable will be used AUTO if availible by Math::Random::ISAAC)
        Crypt::PRNG
        Your own code reference.


=head1 new()

Create a new Math::Random::Flexible object, accepts 1 optional argument, a hashref of profiles

=cut

sub new {
    my ($class,$profiles) = @_;
    $profiles = {} if (!$profiles);
   
    my $return = bless { profiles=>$profiles }, $class;
    $return->engine('CORE');

    return $return;
}

=head1 engine()

Return a list of availible engines for rand(), by default the module will always use
CORE::rand, that being perls inbuilt rand. If you want to change it simply provide
your choice as the first argument.

If you pass in a reference to your own random function it will attempt a test against it
if successful it will use that!

An example of passing your own: 

    sub mycode { return int(rand(9)) }

    $random->engine(\&mycode);

If you pass something weird that is not a known engine or a reference, it will not switch
engines but will raise a warning.

NOTE Normal every day users just wanting a nice way to get random numbers and such
of a set length need not pay attention to it!

=cut

sub engine {
    my ($self,$select) = @_;
    
    if ($select) {
        my $newengine;

        # Check if its a custom engine
        if ( ref $select eq 'CODE' ) {
            # It is, we can assume its all ready to test
            my $testresult = 1;
            try {
                my $value = CORE::int( &{$select}(9) );
                if ( $value >= 0 && $value <9 ) {
                    $testresult = 0;
                } 
            };
            if ($testresult) { 
                warn "Engine passed in via coderef does not return a sane value! (ignored)";
                return;
            }
            $self->{engine}->{selected} = 'USER';
            $self->{engine}->{USER} = sub { &{ $select }(@_) };
            return;
        }

        # As its not a reference it must be one of ours...
        foreach (keys %$engines) {
            if ( m#^\Q$select\E$#i ) {
                $self->{engine}->{last} = $self->{engine}->{selected}; 
                $self->{engine}->{selected} = $_;
                $newengine = 1;
                last;
            }
        }

        # Different engines require different initilization, lets handle that here
        if (! $newengine ) { 
            warn "The engine you chose, '$select' could not be selected, you sure its known to us?";
            return 
        }
        elsif (! $self->{engine}->{$self->{engine}->{selected}} ) {
            # Initilize the engine
            my $engine = $self->{engine}->{selected};
            my @seed = map join('',map int(rand(9)),@{[1..10]}),@{[1..4]};

            if ( $engine eq 'Math::Random::Secure' ) {
                # Do not really need to do anything for this one, does not even have an object method
                $self->{engine}->{$engine} = sub { Math::Random::Secure::rand(shift) };
            }
            elsif ( $engine eq 'Math::Random::MTwist' ) {
                # Seeds from dev/random no need to
                $self->{engine}->{obj}->{$engine} = Math::Random::MTwist->new();
                $self->{engine}->{$engine} = sub { $self->{engine}->{obj}->{$engine}->rand(shift) };
            }
            elsif ( $engine eq 'Math::Random::Xorshift' ) {
                $self->{engine}->{obj}->{$engine} = Math::Random::Xorshift->new( @seed ); 
                $self->{engine}->{$engine} = sub { $self->{engine}->{obj}->{$engine}->rand(shift) };
            }
            elsif ( $engine eq 'Math::Random::MT' ) {
                $self->{engine}->{obj}->{$engine} = Math::Random::MT->new( @seed );
                $self->{engine}->{$engine} = sub { $self->{engine}->{obj}->{$engine}->rand(shift) };
            }
            elsif ( $engine eq 'Math::Random::ISAAC' ) {
                $self->{engine}->{obj}->{$engine} = Math::Random::ISAAC->new( @seed );
                $self->{engine}->{$engine} = sub { $self->{engine}->{obj}->{$engine}->rand(shift) };
            }
            elsif ( $engine eq 'Crypt::PRNG' ) {
                # Seeds from dev/random no need to
                $self->{engine}->{obj}->{$engine} = Crypt::PRNG->new( );
                $self->{engine}->{$engine} = sub { $self->{engine}->{obj}->{$engine}->double(shift) };
            }
            elsif ( $engine eq 'CORE' ) {
                $self->{engine}->{$engine} = sub { CORE::rand(shift) };
            }
        }
        return;
    }

    return keys %$engines;
}

=head1 store()

Set and/or return the stored profiles, will always return the currently used profiles,
unless you pass it something it did not expect as a first argument, where it will return
a blank hashref. 

=cut 

sub store {
    my ($self,$new_profiles) = @_;

    if (!$new_profiles) {
        return $self->{profiles};
    }
    elsif (ref $new_profiles ne 'HASH') {
        warn "First argument for profiles() must be a hashref!";
        return {};
    }
    else {
        $self->{profiles} = $new_profiles;
    }

    return $self->{profiles};
}

sub _rand {
    my ($self,$option) = @_;
    return $self->{engine}->{$self->{engine}->{selected}}->($option);
}

=head1 alpha()

Return a random alpha character uppercase or lowercase, accepts 1 argument 'length',
if length is ommited return a single alpha-char;

=head2 char()

Though technically wrong, it is a shorthand to alpha()

=cut

sub char { 
    return alpha(@_)
}

sub alpha {
    my ($self,$length) = @_;

    if ( !defined $length || $length !~ m#^\d+$# ) {
        $length = 1;
    }
    elsif (!$length) {
        # If we got 0 passed as a length
        return;
    }

    my $randAlpha = "";

    for ( 1..$length ) {
        my $key = 'a';
        for ( 1..CORE::int($self->_rand(26)) ) { $key++ }
        if ( CORE::int($self->_rand(2)) ) { $key = uc($key) }
        $randAlpha .= $key;
    }

    return $randAlpha;
}

=head1 numeric()

Return a random whole number, accepts 1 argument 'length', if length is ommited 
return a single number.

=head2 int()

A shorthand for numeric()

=cut

sub int {
    return numeric(@_);
}

sub numeric {
    my ($self,$length) = @_;

    if ( !defined $length || $length !~ m#^\d+$# ) {
        $length = 1; 
    }
    elsif (!$length) {
        # If we got 0 passed as a length
        return;
    }

    # Never allow the first number to be a 0 as it does not
    # really exist as a prefixed number.
    my $randInt = 1+CORE::int($self->_rand(9));
    $length--;

    for (1..$length) {
        $randInt .= CORE::int($self->_rand(10));
    }

    return $randInt;
}

=head1 alphanumeric()

Return a random alphanumeric string, accepts 1 argument 'length', if length is ommited
return a single random alpha or number.

=head2 mix()

A shorthand for alphanumeric()

=cut

sub mix {
    return alphanumeric(@_);
}

sub alphanumeric {
    my ($self,$length) = @_;

    if ( !defined $length || $length !~ m#^\d+$# ) {
        $length = 1;
    }
    elsif (!$length) {
        # If we got 0 passed as a length
        return;
    }

    my $randAN = "";

    for ( 1..$length) {
        if ( CORE::int($self->_rand(2)) ) { $randAN .= $self->numeric() }
        else                { $randAN .= $self->alpha() }
    }

    return $randAN;
}

=head1 profile()

Set or adjust a profile of characters to be used for randoms, accepts 3 arguments in
the following usages:

Create or edit a profile named some_name and return a 16 long string from it

$random->profile('some_name',16,[qw(1 2 3)]);


Return 16 chars from the pre-saved profile 'some_name'

$random->profile('some_name',16);


Delete a stored profile

$random->profile('some_name',0,[]);

=cut

sub profile {
    my ($self,$profile_name,$length,$charset) = @_;

    if ( !defined $length || $length !~ m#^\d+$# ) {
        $length = 1;
    }
    elsif (!$length) {
        # If we got 0 passed as a length
        return;
    }

    # Maybe we are adding or overwriting a profile
    if ( $charset ) {
        if ( ref $charset ne 'ARRAY' ) {
            warn "Charset MUST be an arrayref!";
            return;
        }
        elsif ( scalar @{ $charset } == 0 ) {
            return delete $self->{profiles}->{$profile_name};
        }

        $self->{profiles}->{$profile_name} = $charset;

        return $self->profile( $profile_name, $length );
    }

    # Ok lets check we have the profile, if not return nothing
    if (! $self->{profiles}->{$profile_name} ) {
        return " "x$length;
    }

    # All looks good..
    my $randProf = "";
    my $key_max = scalar @{ $self->{profiles}->{$profile_name} };

    for ( 1..$length ) {
        $randProf .= $self->{profiles}->{$profile_name}->[ CORE::int( $self->_rand( $key_max ) ) ];
    }

    return $randProf;
}


=head1 AUTHOR

Paul G Webster, C<< <daemon at cpan.org> >>

=head1 BUGS

Please report any bugs to: L<https://github.com/PaulGWebster/p5-Data-Random-Flexible>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc p5::Data::Random::Flexible


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/p5-Data-Random-Flexible>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/p5-Data-Random-Flexible>

=item * Search CPAN

L<http://search.metacpan.org/dist/p5-Data-Random-Flexible/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Paul G Webster.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Paul G Webster's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of p5::Data::Random::Flexible
