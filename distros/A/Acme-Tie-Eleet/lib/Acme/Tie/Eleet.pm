#
# This file is part of Acme::Tie::Eleet.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Acme::Tie::Eleet;

use strict;
use warnings;

use Carp;
use IO::Handle;

our $VERSION = '1.0.2';


# Our to allow user to hack/overwrite it.
our @beg = ( "hey man, ", "hey dude, ", "cool, ", '$#$!#!$ ', "sure, ", "hey, ",
	     "yeah, ", "yeah man, ", "yeah dude, ", "listen, ", "listen pal, " );
our @end = ( ", fear us.", ", d'ya think so?",  ' $#$!#!$!' );
our @sentences = ( "Fear us!", "All your base are belong to us!",
		   "Resistance is futile; you will be assimilated.",
		   "Resistance is futile.", "Whololo!" );
our %words  =
    ( apps      => "appz",
      are       => "r",
      awesome   => "awesum",
      because   => "cuz",
      capital   => "capitull",
      cool      => [ "kool", "kewl" ], # Anon arrays accepted.
      dude      => "dood",
      elite     => "eleet",
      every     => "evry",
      everybody => "evry budy",
      freak     => "phreak",
      games     => "gamez",
      hacker    => "haxor",
      hackers   => "haxors",
      letter    => "lettr",
      letters   => "lettrs",
      phone     => "fone",
      rule      => "rulez",
      see       => "c",
      the       => "da",
      wares     => "warez",
      you       => "u",
);


# Populate the hash.
my %letter =
    ( a => [ "4", "@" ],
      c => "(",
      e => "3",
      g => "6",
      h => [ "|-|", "]-[" ],
      k => [ "|<", "]{" ],
      i => "!",
      l => [ "1", "|" ],
      m => [ "|V|", "|\\/|" ],
      n => "|\\|",
      o => "0",
      s => [ "5", "Z" ],
      t => [ "7", "+"],
      u => "\\_/",
      v => "\\/",
      w => [ "vv", "\\/\\/" ],
      'y' => "j",
      z => "2",
      );


#--
# Constructor

sub _new {
    # Create object.
    my $self = {
	letters    => 25,    # transform o to 0, l to 1, etc.
	spacer     => "1/0", # %age 0=no extra spaces, 'm/n'=m extra+n noextra, 60=3/5 at random
	case_mixer => 50,    # %age 0=nothing, 'm/n'=m ucase+n lcase, 25=1/4 at random
	words      => 1,     # transform cool to kewl or kool, etc.
	add_before => 15,    # add comments before sentence.
	add_after  => 15,    # add comments after sentences.
	extra_sent => 10,    # extra sentences.
	@_,                  # overwrite with user values.
	# internals, do not modify.
	_space    => "m0",
	_case_mix => "m0"
    };

    # Check patterns.
    $self->{spacer} =~ m!^(((\d+)/(\d+))|(\d+))$!
	or  croak "spacer: wrong pattern $self->{spacer}";
    $self->{spacer} =~ m!^(\d+)/(\d+)$! && $1+$2 == 0
	and croak "spacer: illegal pattern $self->{spacer}";
    $self->{case_mixer} =~ m!^(((\d+)/(\d+))|(\d+))$!
	or  croak "case_mixer: wrong pattern $self->{case_mixer}";
    $self->{case_mixer} =~ m!^(\d+)/(\d+)$! && $1+$2 == 0
	and croak "case_mixer: illegal pattern $self->{case_mixer}";

    # Init internals.
    $self->{spacer}      =~ m!^(\d+)/(\d+)$! && $1 == 0
	and $self->{_space}    = "n0";
    $self->{case_mixer} =~ m!^(\d+)/(\d+)$! && $1 == 0
	and $self->{_case_mix} = "n0";

    # Return the hash ref.
    return $self;
}


sub TIEHANDLE {
    # Process args.
    my $pkg = shift;
    my $fh  = shift;
    ref $pkg and croak "Not an instance method";

    $fh or croak "Filehandle is not an optional paramater";
    $fh->autoflush(1);

    my $self  = &_new; # magic call.
    $self->{FH} = $fh;

    # Return it.
    return bless( $self, $pkg );
}


sub TIESCALAR {
    # Process args.
    my $pkg = shift;
    ref $pkg and croak "Not an instance method";

    my $self  = &_new; # magic call.
    $self->{value} = undef;

    # Return it.
    return bless( $self, $pkg );
}


#--
# Handlers.

# Catch scalar fetching.
sub FETCH {
    my $self = shift;
    return $self->_transform( $self->{value} );
}

# Catch calls to print.
sub PRINT {
    my $self = shift;
    my $fh = $self->{FH};
    $_[0] or return;
    print $fh $self->_transform(join "", @_);
}

# Catch scalar storing.
sub STORE {
    $_[0]{value} = $_[1];
}


#--
# Modification plugins.

#
# All plugins will get (not counting the object that will always be
# the first argument) a string to modify. Each string will contain one
# and only one sentence.
#

# Add preambles randomly.
sub _apply_add_before {
    my ($self, $target) = @_;
    if ( rand(100) < $self->{add_before} ) {
	my $before = $beg[ rand( int(@beg) ) ];
	$target = $before.$target;
    }
    return $target;
}

# Add end of sentences randomly.
sub _apply_add_after {
    my ($self, $target) = @_;
    if ( rand(100) < $self->{add_after} ) {
	my $after = $end[ rand( int(@end) ) ];
	$target  .= $after;
    }
    return $target;
}

# Mix case as wanted.
sub _apply_case_mixer {
    my ($self, $target) = @_;

    if ( $self->{case_mixer} =~ m!^(\d+)/(\d+)$! ) {
	# Fixed pattern.
	my $what = "";
	my ($m, $n) = ( $1, $2 );
	for my $c (split //, $target) {
	    $self->{_case_mix} =~ m/^([mn])(\d+)$/;
	    $what .= ($1 eq "m") ? uc($c) : $c;
	    my $new;
	    my $count = $2 + 1;
	    if ( $1 eq "m" ) {
		$2+1 != $m            and $new = "m$count";
		$2+1 == $m && $n == 0 and $new = "m0";
		$2+1 == $m && $n != 0 and $new = "n0";
	    } else {
		$2+1 != $n            and $new = "n$count";
		$2+1 == $n && $m == 0 and $new = "n0";
		$2+1 == $n && $m != 0 and $new = "m0";
	    }
	    $self->{_case_mix} = $new;
	}
	$target = $what;
    } else {
	# Put extra space at random.
	$target =~ s/(.)/rand(100)<$self->{case_mixer}?uc($1):$1/eg;
    }
    return $target;
}

# Add whole sentences randomly.
sub _apply_extra_sent {
    my $self = shift;
    if ( rand(100) < $self->{extra_sent} ) {
	return $sentences[rand( @sentences ) ];
    }
    return undef;
}

# Transform o to 0, l to 1, etc. That's 31337!
sub _apply_letters {
    my ($self, $target) = @_;

    return join "", map { rand(100) < $self->{letters} && exists $letter{$_} ?
			      ( ref($letter{$_}) eq ref([]) ) ?
				  $letter{$_}[rand( @{$letter{$_}} ) ] :
				      $letter{$_}
			  : $_ } split //, $target;
}

# Put extra space between chars.
sub _apply_spacer {
    my ($self, $target) = @_;

    if ( $self->{spacer} =~ m!^(\d+)/(\d+)$! ) {
	# Fixed pattern.
	my $what = "";
	my ($m, $n) = ( $1, $2 );
	for my $c (split //, $target) {
	    $self->{_space} =~ m/^([mn])(\d+)$/;
	    $what .= ($1 eq "m") ? "$c " : $c;
	    my $new;
	    my $count = $2 + 1;
	    if ( $1 eq "m" ) {
		$2+1 != $m            and $new = "m$count";
		$2+1 == $m && $n == 0 and $new = "m0";
		$2+1 == $m && $n != 0 and $new = "n0";
	    } else {
		$2+1 != $n            and $new = "n$count";
		$2+1 == $n && $m == 0 and $new = "n0";
		$2+1 == $n && $m != 0 and $new = "m0";
	    }
	    $self->{_space} = $new;
	}
	$target = $what;
    } else {
	# Put extra space at random.
	$target =~ s/(.)/rand(100)<$self->{spacer}?"$1 ":$1/eg;
    }
    return $target;
}

# Transform words according to %words.
sub _apply_words {
    my ($self, $target) = @_;
    my @what = ();
    for my $word ( split / /, $target ) {
	if ( exists( $words{$word} ) ) {
	    my $subst = $words{$word};
	    $word = ref($subst) eq ref([]) ?
		$subst->[ rand( int(@$subst) ) ]
	      : $subst;
	}
	push @what, $word;
    }
    return join " ", @what;
}

# Main entry point for string transformation.
sub _transform {
    my ($self, $line) = @_;

    $line or return; # Case undef.
    my $sentence;
    my @what = split "([.?!\n])", lc $line;
    while ( my ($what, $punc) = splice @what, 0, 2 ) {
	# Build the sentence.
	$self->{add_before} and $what = $self->_apply_add_before($what);
	$self->{add_after}  and $what = $self->_apply_add_after($what);

	defined($punc) and $what .= $punc;

	my $extra = $self->_apply_extra_sent();
	$extra and $what .= " $extra";

	# Transform chars.
	foreach my $plugin ( qw( words spacer letters case_mixer ) ) {
	    my $meth = "_apply_$plugin";
	    $self->{$plugin} and $what = $self->$meth($what);
	}
	$sentence .= $what;
    }
    return $sentence;
}

# By default, tie standard filedescriptors.
# tie *STDOUT, __PACKAGE__, *STDOUT;
# tie *STDERR, __PACKAGE__, *STDERR;


1;
__END__

=head1 NAME

Acme::Tie::Eleet - Perl extension to 5pE4k 1Ik3 4n 3l337!


=head1 SYNOPSIS

B<!!!See the BUGS section below!!!>

  use Acme::Tie::Eleet;
  print "This is eleet!\n";

  tie *OUT, 'Acme::Tie::Eleet', *OUT, case_mixer => "1/1";
  print OUT "This is eleet\n";

  Or, even, to translate instant sentences:
  perl -MAcme::Tie::Eleet -p -e ''

  tie $bar, 'Acme::Tie::Eleet', spacer => 0;
  $bar = "eleet";
  print $bar;


=head1 DESCRIPTION

Have you ever wanted to speak like an eleet? Do you feel like it's too
difficult to do your case mixin' manually? Tired of being laugh at by
your mates because your quotes don't make you look like an h4x0r?
Well, there's a solution, and you're reading the documentation of the
module specially made for u, Ye4h M4n!

This module basically allows you to perform a tie on filehandles,
converting text written to it; or a tie on scalars, converting text
they holds.

And since it's quite difficult to do urself a tie, the module will
also tie the 2 (no, not the letter 'S', the figure, u b4st4rd)
standard output file descriptors perl comes with (aka, STDOUT and
STDERR). A simple use of the module and you're ready to go! Fe4R u5!


=head2 Parameters supported by tie (both TIEHANDLE and TIESCALAR)

=over 4

=item o letters    => <percentage>

The parameter allow you to transform letters to corresponding number
(ie, transform l to 1, e to 3, etc.) with a given percentage. Default
is 25 (1 char out of 4 being translitterate - if possible). That's 31337!


=item o spacer     => <percentage>|<pattern>

Add extra spaces between chars. You can tell it to add random spaces
with a given percentage. Eg, 'spacer => 50' will add about 1 space
every two chars, whereas 'spacer => 0' will add no extra spaces. Or
you can provide a pattern of the form "m/n" which will be understood
as 'add an extra space after each of the m next chars, then do not add
extra space after the n next chars'. For example, 'spacer => "1/1"'
will add an extra space after one char out of two, whereas 'spacer =>
"1/0" will add extra spaces after each char. Default is 0 (no extra
space). T h a t   r o c k s !


=item o case_mixer => <percentage>|<pattern>

Put some chars into uppercase. You can tell it to convert random chars
with a given percentage. Eg, 'case_mixer => 50' will convert a mean of
1 char every two chars, whereas 'case_mixer => 100' will convert every
character. Or you can provide a pattern of the form "m/n" which will
be understood as 'uppercase m chars, then do not uppercase the n next
chars'. For example, 'case_mixer => "2/1"' will convert two chars,
then left one char unchanged; whereas 'case_mixer => "0/1"' won't
convert any chars. Default is 50 (random 1 out of 2). CaSE mIxIng
RUleZ!


=item o words      => <true>|<false>

Transform words given a dictionnary. For exampe, transform 'hacker' to
'haxor', and so on... Either true or false, default to false. Kewl stuff!


=item o add_before => <percentage>

Add some preamble randomly with a given percentage. For example, it
could transform "this is my sentence." to "Yeah man, this is my
sentence.". Default to 15.


=item o add_after  => <percentage>

Terminate a sentence randomly with an hacker expression according to a
given percentage. For example, it could transform "this is my
sentence." to "this is my sentence, fear us.". Default to 15.


=item o extra_sent => <percentage>

Add randomly whole sentences to the filehandle. If filehandle is read
from, it won't return the next chunk of text, but rather a leave it
where it stands and return a sentence of its own. Default to 10. All
your base are belong to us!


=back


=head1 BUGS

B</!\ WARNING>: as of Perl 5.8.0, TIEHANDLE seems to be B<broken>. So,
I decided to remove ties on STDOUT and STDERR, and commented the
relevant parts in the test suite.

Don't try to tie a filehandle if you're running a Perl version greater
or equal to 5.8.0, because you will start a I<deep recursion loop> as
says Perl... I'll try to fix it when I'll find some time.


=head1 TODO

=over 4

=item o

Find more h4x0R quotes to add.


=item o

Allow user to provide a dictionnary for words. Backward compatibility
would be ok since a ref to a hash evaluates to true.


=item o

Allow user to provide a hash of quotes for both add_before /
add_after. Backward compatibility would be ok since a ref to a hash
evaluates to true.


=item o

Allow user to provide an array of quotes to add. Backward
compatibility would be ok since a ref to a hash evaluates to true.


=item o

Allow tie-ing for input filehandle.

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-tie-eleet at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Tie-Eleet>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SEE ALSO

L<perl>, the L<news://alt.2600> newsgroup, L<http://www.google.com/intl/xx-hacker/>.


=head1 AUTHOR

Jerome Quelin, C<< <jquelin at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
