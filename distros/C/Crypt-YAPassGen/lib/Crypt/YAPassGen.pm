package Crypt::YAPassGen;

$Crypt::YAPassGen::VERSION = 0.02;

use 5.006;
use strict;
use locale;
use Carp;
use Storable qw(nstore retrieve);
use File::Spec;
use Config;
use base 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('DEFAULT_DICT');
__PACKAGE__->DEFAULT_DICT( File::Spec->catfile(
    $Config{installsitelib}, qw(Crypt YAPassGen american-english.dat)
) );

__PACKAGE__->mk_classdata('PRECOOKED_SUBS');
__PACKAGE__->PRECOOKED_SUBS( {
    haxor   =>  sub { tr/aAeEtTsSoOiIzZgG/4433775500112266/ },
    digits  =>  sub {  s/(.)/ rand() < 0.25 ? int(rand 10) . $1 : $1 /ge },
    caps    =>  sub {
        my $rand = rand;
        s/(.)/ rand() < $rand ? uc $1 : $1 /ge;
    },
} );


__PACKAGE__->mk_classdata('ALGORITHMS');
__PACKAGE__->ALGORITHMS( {
    linear  =>  sub { _weighted_rand( _weight_to_dist( &_getref ) ) },
    sqrt    =>  sub { _weighted_rand( _weight_to_dist_sqrt( &_getref ) ) },
    log     =>  sub { _weighted_rand( _weight_to_dist_log( &_getref ) ) },
    flat    =>  sub { _flat_rand( &_getref ) },
} );


sub new {
    my $class = shift;
    
    my %h = (
        length      =>  8,
        freq        =>  __PACKAGE__->DEFAULT_DICT,
        post_subs   =>  undef,
        algorithm   =>  'sqrt',
        ascii       =>  0,
        @_
    );

    my $self = bless {
        post_subs   =>  [],
        freq        =>  {},
    }, $class;
    
    $self->$_( $h{$_} ) for qw(length freq post_subs algorithm ascii);
    
    return $self;
}

sub algorithm {
    my $self = shift;
    my ($alg) = @_;
    if (defined $alg) {
        if (ref($alg) eq 'CODE') {
            $self->{algorithm} = $alg;
        } else {
            croak qq(No such algorithm "$alg") 
                unless __PACKAGE__->ALGORITHMS->{$alg};
            $self->{algorithm} = __PACKAGE__->ALGORITHMS->{$alg};
        }
    }
    return $self->{algorithm};
}

sub ascii {
    my $self = shift;
    my ($ascii) = @_;
    $self->{ascii} = $ascii if defined $ascii;
    return $self->{ascii};
}

sub freq {
    my $self = shift;
    my ($freq) = @_;
    if (defined $freq) {
        if ($freq eq '') {
            $self->{freq} = {};
            $self->{freq_file} = '';
        } elsif (-e $freq and -r _) {
            $self->{freq} = retrieve( $freq );
            $self->{freq_file} = $freq;
        } else {
            croak qq(Cannot find/read the frequency file "$freq");
        }
    }
    return $self->{freq_file};
}

sub post_subs {
    my $self = shift;
    my ($sub) = @_;
    
    if (defined $sub) {
        if ( ref($sub) eq 'ARRAY' ) {
            $self->reset_post_subs;
            $self->add_post_sub( $_ ) for @$sub;
        } else {
            croak "Not an ARRAY reference";
        }
    }
    
    return $self->{post_subs};
}

sub add_post_sub {
    my $self = shift;
    my ($sub) = @_;
    if (defined $sub) {
        if ( ref($sub) eq 'CODE' ) {
            push @{ $self->{post_subs} }, $sub;
        } elsif ( __PACKAGE__->PRECOOKED_SUBS->{$sub} ) {
            push @{ $self->{post_subs} }, __PACKAGE__->PRECOOKED_SUBS->{$sub};
        } else {
            carp qq(No such precooked sub "$sub");
            return;
        }
    }
    return $self->{post_subs};
}

sub reset_post_subs {
    my $self = shift;
    my $old_subs = $self->{post_subs};
    $self->{post_subs} = [];
    return $old_subs;
}

sub length {
    my $self = shift;
    my ($length) = @_;
    if (defined $length) {
        croak "Length must be an integer >= 1" unless $length >= 1;
        $self->{length} = $length;
    }
    return $self->{length};
}

sub generate {
    my $self = shift;
    my (@passwd, $passwd);
    while ( @passwd < $self->{length} ) {
        push @passwd, $self->{algorithm}->( $self, \@passwd );
    }
    $passwd = join('', @passwd);
    _striphigh( $passwd ) if $self->{ascii};
    for ($passwd) {
        for my $sub ( @{ $self->{post_subs} } ) {
            $sub->();
        }
    }
    
    #_striphigh or post_sub may lengthen $passwd, so we truncate it
    substr($passwd, $self->{length}) = '';  
    
    return $passwd;
}

sub make_freq {
    my $proto = shift;
    my ($input, $output, $ascii) = @_;
    my @files = ref($input) ? @$input : ($input);
    
    my (%prob, $self);

    if (ref $proto) {
        $self = $proto;
        %prob = %{ $self->{freq} };
        $ascii = $self->{ascii};
    }

    for my $file (@files) {
        local *IN;
        open(IN, "<", $file) or croak qq(Cannot open dict file "$file" : $!);
        while (<IN>) {
            while (/([[:alpha:]]{3,})/g) {
                my $word = lc $1;
                _striphigh( $word ) if $ascii;
                my @word = split //, $word;
                for (my ($i,$j) = (0,2); $j < @word; $i++,$j++) {
                    my $ref = \%prob;
                    for (@word[$i..$j]) {
                        $ref->{ $_ }[0]++;
                        $ref->{ $_ }[1] ||= {};
                        $ref = $ref->{ $_ }[1];
                    }
                }
            }
        }
        close(IN);
    }
    
    nstore(\%prob, $output) if defined $output;

    $self->{freq} = \%prob if $self;
    
    return \%prob;
}

sub save_freq {
    my $self = shift;
    my ($file) = @_;
    nstore($self->{freq}, $file);
}

### UTILITIES

sub _getref {
    my ($self, $passwd) = @_;
    my ($f, $s) = @$passwd[-2, -1];
    if ($f and $self->{freq}{ $f }           #ton of stuff
           and %{ $self->{freq}{ $f }[1] }       #to prevent
           and $self->{freq}{ $f }[1]{ $s }         #autovivification
           and %{ $self->{freq}{ $f }[1]{ $s }[1] }) {
        return $self->{freq}{ $f }[1]{ $s }[1];
    }
    if ($s and $self->{freq}{ $s }
           and %{ $self->{freq}{ $s }[1] }) {
        return $self->{freq}{ $s }[1];
    }
    return $self->{freq};
}

sub _weight_to_dist {
    my ($weights) = @_;
    my %dist    = ();
    my $total   = 0;
    my ($key, $weight);

    $total += $_->[0] for values %$weights;
    
    while ( ($key, $weight) = each %$weights ) {
        $dist{$key} = $weight->[0] / $total;
    }
   
    return \%dist;
}

sub _weight_to_dist_sqrt {
    my ($weights) = @_;
    my (%dist, %temp) = ();
    my $total   = 0;
    my ($key, $weight);

    $total += $temp{$_} = sqrt $weights->{$_}[0] for keys %$weights;
  
    while ( ($key, $weight) = each %temp ) {
        $dist{$key} = $weight / $total;
    }
   
    return \%dist;
}

sub _weight_to_dist_log {
    my ($weights) = @_;
    my (%dist, %temp) = ();
    my $total   = 0;
    my ($key, $weight);

    $total += $temp{$_} = log $weights->{$_}[0] for keys %$weights;
    
    return _weight_to_dist( $weights ) if $total == 0;
    
    while ( ($key, $weight) = each %temp ) {
        $dist{$key} = $weight / $total;
    }
   
    return \%dist;
}

sub _weighted_rand {
    my ($dist) = @_;
    my ($key, $weight);

    while (1) {  # to avoid floating point inaccuracies
        my $rand = rand;
        while ( ($key, $weight) = each %$dist ) {
            return $key if ($rand -= $weight) < 0;
        }
    }
}

sub _flat_rand {
    my ($weights) = @_;
    my @chars = grep {$weights->{$_}[0] > 0} keys %$weights;
    return $chars[int rand @chars];
}

sub _striphigh {
    $_[0] =~  tr{àáâãäåªèéêëìíîïòóôõöøºùúûüýÿçñþð}
                {aaaaaaaeeeeiiiiooooooouuuuyycntd};
    $_[0] =~ s/½/oe/g;      $_[0] =~ s/æ/ae/g;
    $_[0] =~ s/ß/ss/g;      $_[0] =~ s/µ/mu/g;
}

=head1 NAME

Crypt::YAPassGen - Yet Another (pronounceable) Password Generator

=head1 SYNOPSIS

 use Crypt::YAPassGen;

 my $passgen = Crypt::YAPassGen->new(
    freq        =>  '/usr/share/dict/mobydick.dat',
    length      =>  10,
    post_subs   =>  [sub { $_ = uc }, "digits"],
 );

 my $passwd = $passgen->generate();

=head1 DESCRIPTION

C<Crypt::YAPassGen> allows you to generate pronounceable passwords using a
frequency file extracted from a dictionary of words.
This module was inspired by C<Crypt::PassGen> written by Tim Jenness. I started
writing this module a couple of
years ago, because I wasn't able to make C<Crypt::PassGen> work with an Italian
frequency file.
This module also offers a different interface and a few more options than
Crypt::PassGen, that's why it exists. See L</"SEE ALSO"> for other similar
modules.
Please beware that passwords generated by this module are LESS secure than
truly random passwords, so use it at your own risk!

=head1 USAGE

=head2 CLASS METHODS

=over 4

=item my $passgen = Crypt::YAPassGen->new(%opts)

Returns a new password generator object. You can pass an hash of options: every
option will be treated as a call to the object method of the same name.
Allowed options are C<freq>, C<length>, C<algorithm>, C<ascii> and C<post_subs>.
If an option is not specified the newly generated object will use the 
following defaults:

 freq       =>  '/path_to_american-english_default_freq_file.dat',
 length     =>  8,
 algorithm  =>  'sqrt',
 ascii      =>  0,
 post_subs  =>  [],     #NONE

=item my $freq = Crypt::YAPassGen->make_freq($dict_file, $freq_file, $ascii)

This class method will generate a new frequency file reading from C<$dict_file>
and writing the result in C<$freq_file>. If C<$dict_file> is an ARRAY reference,
then we consider the elements of the array as filenames and we process all of
them.
The C<$ascii> flag is optional. This is useful if your locale allows for
alphabetic characters out of the 7 bit Latin ASCII alphabet (for example
accented characters or with umlaut). It is higly suggested to set this variable
to a true value unless your locale is US-ASCII or you're sure your dictionary
doesn't contain any accented character. This apporach works fine for most
european locales, but I'm not sure what would happen with different locales.

=back

=head2 OBJECT METHODS

=over 4

=item my $passwd = $passgen->generate()

Generate a password with previously defined options.

=item my $length = $passgen->length($integer)

Get/set the desired length for generated passwords.

=item my $freq_file = $passgen->freq($filename)

Get/set the frequency file to use.
If set to an empty string it will clear the internal frequency table and
you will have to call C<make_freq> on the object before trying to
C<generate> any new password.

=item my $ascii = $passgen->ascii($flag);

Get/set the ascii flag. If it's true then we are sure our passwords will be made
only of 7 bit ASCII characters as long as frequency file contains only 7 bit
ASCII alphabet characters and accented variants of the same.

=item my $algorithm = $passgen->algorithm($code_or_string)

Get/set the algorithm to calculate the sequence of letters to be addedd to the
password. The returned value will be a CODE reference. The method accept as
parameters either a CODE reference or a string. If it's a string it can be one
of the following: "linear", "sqrt", "log" and "flat".

The "linear" algorithm calculate the sequence of characters with a function
linear to the frequency of the characters. This generate really pronounceable
passwords, but may be too easy to crack.

The "sqrt" algorithm is the default as the password are still pronounceable but 
a bit harder to crack.

The "log" algorithm is similar to the "sqrt" but not as consistent.

The "flat" algorithm is really fast, but the generated passwords look more like
really random strings than pronounceable words.

If you are interested in personalizing the algorithm used you should take a
look at the code, brew your own algorithm and then pass it in as a CODE 
reference.

=item my $post_subs = $passgen->add_post_sub($code_ref)

Adds a sub to the stack of procedures that will be executed once the password
has been produced. The subs are supposed to modify C<$_> as in a C<for>
loop.
Here's an example to have all upper-case passwords:

 $passgen->add_post_sub(sub { tr/a-z/A-Z/ });

Please note that if the sub lengthen the password, then it will be later 
truncated
at the right length, but if it shorten the password then you will be left with
a mutilated one.

Instead of passing a code reference you may pass a string corresponding to one
of the pre-cooked subs available in this module. They are the following:

"haxor": change some of the characters into l33t version of the same

"caps": insert a random amount of upper-case characters

"digits": insert some digits with a 1 in 4 probability

=item my $post_subs = $passgen->post_subs([@code_refs])

Get/set the code refs to the subs that will be called after the production of
the password. See C<add_post_sub> for specification of the subs.
Returns a reference to the ARRAY of subs to be processed.
Example:

 $passgen->post_subs([sub { tr/t/+/ }, "caps", "haxor"]);

=item my $old_subs = $passgen->reset_post_subs()

Reset the ARRAY of subs.
Returns a reference to the ARRAY of subs that were there.

=item my $freq = $passgen->make_freq($dict_file, $freq_file)

This class method will generate a new frequency file reading from C<$dict_file>
and writing the result in C<$freq_file>. If C<$dict_file> is an ARRAY reference
then we consider the elements of the array as filenames and we process all of
them.
You may omit C<$freq_file> in which case the result won't be saved to disk, but
it will still be contained by C<$passgen> so that you may use it on the fly.
If you call this method when a frequency table is already loaded in the object,
the new frequency will be just added to the one already present in the object
so that you can mix different dictionaries.

=item $passgen->save_freq($filename)

Save the frequency table contained in the object to C<$filename>.

=back

=head1 TODO

-adding more post_subs?

-bit more l10n effort?

=head1 BUGS

Not really a bug in itself but this module is NOT secure! Use it at your own
risk!

=head1 SEE ALSO

This module was originally inspired by C<Crypt::PassGen> by Tim Jenness so you
may notice some similarities.
Modules similar to this one include C<Crypt::GeneratePassword>,
C<String::MkPasswd>, C<Crypt::RandPasswd> and C<randpass>.

=head1 COPYRIGHT

Copyright 2002-2004 Giulio Motta L<giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
