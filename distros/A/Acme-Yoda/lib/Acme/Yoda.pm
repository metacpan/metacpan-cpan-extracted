
package Acme::Yoda;
use strict;
use Lingua::LinkParser;

BEGIN {
        use vars qw ($VERSION);
	$VERSION     = 0.02;
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

Acme::Yoda - 

=head1 SYNOPSIS

    use Acme::Yoda;


=head1 DESCRIPTION

  Acme::Yoda translates back and forth from yoda speak.


=head1 USAGE
 
    use Acme::Yoda;  

    my $y = Acme::Yoda->new();
    my $translated = $y->yoda('I am your father');
    my $back_again = $y->deyoda($translated)

 
=head1 BUGS
    Right now Acme::Yoda does not handle contractions nor does it have a 
    comprehensive list of verbs.

    You can only deyoda sentences you have yoda'ed, since I have no 
    reliable way to discern the subject of the sentence.

    Both issues need to be fixed.


=head1 SUPPORT

    email me if you need help.



=head1 AUTHOR

	Christian Brink
        GREP
	cbrink@flylines.org
	http://www.yoda-speak.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 new()

 Usage     : new( sentence => 'I am a sentence') or just new();
 Purpose   : constructor
 Returns   : Acme::Yoda object
 Argument  : can take a sentence 

=cut

my $_link = Lingua::LinkParser->new(verbosity => 0,
				    display_walls => 0);

sub new {
	my $class = shift;
	my %args = @_;
	$args{_link_parser} = $_link;
	
	my $self = bless \%args, ref($class) || $class ;

	return $self;
}



=head2 yoda()

 Usage     : yoda('sentence')
 Purpose   : Translates your sentenece into yoda speak
 Returns   : string
 Argument  : string 
 Comments  : You can sent the sentence in new() or send it here

=cut
sub yoda {
    my $self = shift;
    my $sentence = shift() || '';
    $sentence =  $sentence || $self->{sentence};

    return if (!$sentence);
    $self->{sentence} = $sentence;

    my $ending;
    if ($sentence =~ /([.?!])$/) {
	chomp($sentence);
	$ending = chop($sentence);
    }

    if (!$self->{_no_contractions}) {
	my %contractions = ( "I'll"    => "I will",
			     "I'm"     => "I am",
			     "he'll"   => "he will",
			     "you'll"  => "you will",
			     "doesn't" => "does not",
			     "can't"   => "can not",
			     "aren't"  => "are not",
			     "I've"    => "I have",
			     "we've"   => "we have",
			     "they've" => "they have",
			     "he's"    => "he is",
			     "she's"   => "she is",
			     "isn't"   => "is not",
			     "you're"  => "you are",
			     "where's" => "where is",
			     "we'll"   => "we will",
			     "they'll" => "they will",
			     "didn't"  => "did not",
			     "I'd"     => "i would",
			     "he'd"    => "he would",
			     "she'd"   => "she would",
			     "its"     => "it is"
			     );
	
	foreach (keys %contractions) {
	    if ($sentence =~ /\b\Q$_\E\b/ig) {
		$sentence =~ s/\b\Q$_\E\b/$contractions{$_}/ige;
	    }
	}
    }

    # Find out if I have a pivot word and grab the one with the lowest index
    my $pivot = $self->_get_pivot();

    return $sentence if (!$pivot);
    if (index(lc($sentence),$pivot) == 0) {
	$sentence = substr($sentence,,length($pivot)+1);
	$ending = '?';
    } else {
	return $sentence unless ($sentence=~/\b$pivot\b/);
	$sentence="$' $`$&";
    }
    # Clear leading spaces
    $sentence =~ s/^\s+//;

    # Sentence case
    $sentence = ucfirst(lc($sentence));
    $sentence =~ s/\bi\b/I/g;
    $sentence .= $ending if ($ending);
    return $sentence;
}

=head2 deyoda()

 Usage     : deyoda('sentence')
 Purpose   : Translates your sentenece out of yoda speak
 Returns   : string
 Argument  : string
 Comments  :  

=cut
sub deyoda {
    my $self = shift;
    return $self->{sentence};


};




################################################## subroutine header end ##


sub _get_pivot {
    my $self = shift();
 
    my $parser = $self->{_link_parser};
    my $s = $parser->create_sentence($self->{sentence});
    my $pivot;

    my @linkages = $s->linkages;
  LINK:
    foreach my $linkage ($linkages[0]) {
	return if (!$linkage);
        my @words = $linkage->get_words();
        foreach (@words) {
	    if (/^(\w+)\.v$/) {
                $pivot = $1;
                last LINK;
            }
        }
    }
    return $pivot;
}

sub _get_last_pivot {
    my $self = shift();
 
    my $parser = $self->{_link_parser};
    my $s = $parser->create_sentence($self->{sentence});
    my $pivot;

    my @linkages = $s->linkages;
  LINK:
    foreach my $linkage ($linkages[0]) {
        my @words = $linkage->get_words();
        foreach (@words) {
	    if (/^(\w+)\.v$/) {
                $pivot = $1;
            }
        }
    }

    return $pivot;




}

1; #this line is important and will help the module return a true value
__END__

