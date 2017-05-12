=pod

=head1 NAME

Acme::24 - Your favourite TV-show Acme module

=head1 SYNOPSIS

   use Acme::24;

   # Tell me some random quote about Jack Bauer
   print Acme::24->random_jackbauer_fact();
   # 'Jack Bauer went out to the desert, and was bitten by a rattlesnake.
   #  The snake died.'

   # Returns an arrayref with 24 random facts
   my $facts = Acme::24->random_jackbauer_facts();

   # Every call collects 24 random facts in a text file
   # called `/tmp/superhero.txt' in fortune text format
   Acme::24->collect_facts('/tmp/superhero.txt');

=head1 DESCRIPTION

This module was written because I'm somewhat crazy, and I'm also
passionate about the 24 tv-show, but in particular of the
B<KingOfTheAssKickers(tm)>, Jack Bauer, a mythical super-hero,
something between Duke Nukem and Chuck Norris.

=head1 BUGS

One probably: this module should not really be on CPAN, it takes space,
although fortunately only a little.

=head1 AUTHOR

Cosimo Streppone, L<cosimo@cpan.org>

=head1 LICENSE

Artistic License, same as Perl itself.

=cut

package Acme::24;

$VERSION = '0.04';

use strict;
use warnings;
use LWP::Simple  ();
use XML::RSSLite ();

use constant URL => 'http://www.notrly.com/jackbauer';

# Returns one random fact
sub random_jackbauer_fact
{
    my $url  = URL;
    my $page = LWP::Simple::get($url);
    my $fact = '';

    if($page =~ m(<p class="fact">([^<]+)</p>))
    {
        $fact = $1;
        $fact =~ s/^\s+//;
        $fact =~ s/\s+$//;

        if(eval('use HTML::Entities'))
        {
            HTML::Entities::decode_entities($fact);
        }

        $fact .= "\n";
    }

    return($fact);

}

# Returns an array of 24 random facts
sub random_jackbauer_facts
{
    my @facts = ();
    my $url = URL . '/rss.php';
    my $tries = 5;
    my %seen;

    while ($tries-- > 0 && @facts < 24) {
        my %result;
        my $feed = LWP::Simple::get($url);
        XML::RSSLite::parseRSS(\%result, \$feed);
        if (exists $result{item} && UNIVERSAL::isa($result{item}, 'ARRAY'))
        {
	    for my $fact (@{ $result{item} }) {
		next if exists $seen{$fact->{title}};
		push @facts, $fact->{title};
		$seen{$fact->{title}} = undef;
	    }
        }
        sleep 1;
    }

    if (@facts && scalar(@facts) > 24) {
        splice(@facts, 24);
    }

    return(\@facts);
}

# Build a database of Jack Bauer facts
sub collect_facts
{
    my($self, $file) = @_;
    $file ||= './jackbauer.txt';
    my $new_facts = $self->random_jackbauer_facts();
    return unless $new_facts;
    open(my $fh, '>>' . $file) or return;
    for(@$new_facts)
    {
        print $fh $_, "\n%\n";
    }
    close($fh);
}


unless (caller) {

	print random_jackbauer_fact();

	# Collect random Jack Bauer facts
	#$| = 1;
	#while(1)
	#{
    # 	Acme::24->collect_facts() and print '.';
    #}

}

1;

