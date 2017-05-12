package Acme::Remote::Strangulation::Protocol;
use strict;
use vars qw($VERSION);
$VERSION = '0.03';

my $glass = " \t"x8;
sub reflect { local $_ = unpack "b*", pop; tr/01/ \t/; s/(.{9})/$1\n/g; $glass.$_ }
sub deflect { local $_ = pop; s/^$glass|[^ \t]//g; tr/ \t/01/; pack "b*", $_ }
sub opaque  { $_[0] =~ /\S/ }
sub deep    { $_[0] =~ /^$glass/ }

open 0 or print "Can't open '$0'\n" and exit;
(my $thought = join "", <0>) =~ s/.*^\s*use\s+Acme::Remote::Strangulation::Protocol\s*;\n\n(?:.*?--\s+Larry\s+Wall.*?\n)?//sm;

local $SIG{__WARN__} = \&opaque;
do {eval deflect $thought; exit} unless opaque $thought and not deep $thought;

my $DeepThought = '';
{
    my $rand = int rand 5;
    while($rand > 0){
        $DeepThought = <DATA>;
        $rand--;
    }
    close DATA;
    chomp $DeepThought;
    $DeepThought =~ s/^\#\d+\s//;

    require Text::Wrap;
    local $Text::Wrap::columns = 72;

    my @lines = Text::Wrap::wrap('', '', $DeepThought);

    if(length $lines[-1] < 63 ){
        $lines[-1] .= "  --  Larry Wall";
    } else {
        push @lines, "        --  Larry Wall";
    }

    $DeepThought = join "\n",@lines;
}

open 0, ">$0" or print "Cannot ponder '$0'\n" and exit;
print {0} "use Acme::Remote::Strangulation::Protocol;\n\n$DeepThought\n", reflect $thought and exit;


=head1 NAME

Acme::Remote::Strangulation::Protocol - The wisdom of Larry Wall 

=head1 SYNOPSIS

  use Acme::Remote::Strangulation::Protocol;

=head1 DESCRIPTION

"The social dynamics of the net are a direct consequence of the fact that
 nobody has yet developed a Remote Strangulation Protocol."

=head2 EXPORT

None by default.

=head1 ACKNOWLEDGEMENTS

My thanks goes out to the following individuals:

	chromatic - For giving me the idea to do this
	crazyinsomniac - I lifted most of the code from his Acme::MJD module
	Larry Wall - For a great programming language and the quote that
		     started it all.
 
=head1 AUTHOR

Thomas Stanley  < Thomas_J_Stanley@msn.com >

=head1 SEE ALSO

perl(1).

=cut

__DATA__
#11901 "The social dynamics of the net are a direct consequence of the fact that nobody has yet developed a Remote Strangulation Protocol."
#11902 "The social dynamics of the net are a direct consequence of the fact that nobody has yet developed a Remote Strangulation Protocol."
#11903 "The social dynamics of the net are a direct consequence of the fact that nobody has yet developed a Remote Strangulation Protocol."
#11904 "The social dynamics of the net are a direct consequence of the fact that nobody has yet developed a Remote Strangulation Protocol."
#11905 "The social dynamics of the net are a direct consequence of the fact that nobody has yet developed a Remote Strangulation Protocol."

