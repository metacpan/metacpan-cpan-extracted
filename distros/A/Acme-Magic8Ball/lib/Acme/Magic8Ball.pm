package Acme::Magic8Ball;

use strict;

require Exporter;
use vars qw($VERSION $CONSISTENT @EXPORT_OK @ISA);



# are we ever going to need enhancements? Apparently yes :(
$VERSION    = "1.3"; 
$CONSISTENT = 0;
@ISA        = qw(Exporter);
@EXPORT_OK  = qw(ask);

use Data::Dumper;

sub import {
    $CONSISTENT = grep { /^:consistent$/ } @_;
    @_ = grep { !/^:consistent$/ } @_;
    goto &Exporter::import;
}

=head1 NAME

Acme::Magic8Ball - ask the Magic 8 Ball a question

=head1 SYNOPSIS

    use Acme::Magic8Ball qw(ask);
    my $reply = ask("Is this module any use whatsoever?");
    
... you can also pass in your own list of answers ...

    my $reply = ask("What should the next bit be?", 0, 1); # reply will always be 0 or 1

... or make answers consistent ...

    use Acme::Magic8Ball qw(ask :consistent);
    for (0..1000) {
        my $reply = ask("Is this module any use whatsoever?"); # reply will always be the same
    }
    
=head1 DESCRIPTION

This is an almost utterly pointless module. But I needed it. So there.

=head1 METHODS

=head2 ask <question> [answers]

Ask and ye shall receive!

If you don't pass in an array of answers it will use the traditional ones.

=cut
    
sub ask {
    my $question = shift || return "You must ask a question!";
    my @answers  = @_;

    unless (@answers) {
        my $pos = tell DATA;
        @answers = map { chomp; $_ } <DATA>;
        seek DATA, $pos,0;
    }
    return $answers[rand @answers] unless $CONSISTENT;

    my $hashcode = 0;                                                                                                                                       
    $hashcode   += ord($_) foreach split(//, $question);                                                                                                        
    return $answers[$hashcode % scalar(@answers) - 1];
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYING

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 DEVELOPMENT

You can get the latest version from 

https://github.com/simonwistow/Acme-Magic8Ball

=head1 SEE ALSO

The 8 Ball FAQ              - http://8ball.ofb.net/faq.html

Mattel (who own the 8 Ball) - http://www.mattel.com         

=cut




__DATA__
Signs point to yes.
Yes.
Reply hazy, try again.
Without a doubt.
My sources say no.
As I see it, yes.
You may rely on it.
Concentrate and ask again.
Outlook not so good.
It is decidedly so.
Better not tell you now.
Very doubtful.
Yes - definitely.
It is certain.
Cannot predict now.
Most likely.
Ask again later.
My reply is no.
Outlook good.
Don't count on it.
