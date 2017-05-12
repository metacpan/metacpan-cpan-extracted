#-------------------------------------------------------------------------#
# Acme::Playwright
#       Date Written:   21-Mar-2002 04:15:52 PM
#       Last Modified:  26-Mar-2002 09:32:37 AM
#       Author:    Kurt Kincaid
#       Copyright (c) 2002, Kurt Kincaid
#           All Rights Reserved
#
# NOTICE: This is free software and may be modified and/or redistributed
#         under the same terms as Perl itself.
#-------------------------------------------------------------------------#

package Acme::Playwright;

use 5.006;
use strict;
use warnings;
use vars qw/ $name $val %Names %Phrases %rNames %rPhrases
             @Names @Actions @nSpace @pSpace @nA @pA @nE @pE
             @nN @pN @nO @pO @nR @pR @nS @pS @nT @pT %Delimiter
             $AUTOLOAD /;

our $VERSION = '0.02';

%Delimiter = (
    'left' => '[ ',
    'right' => ' ]'
);

%Names = (
    'Edward'     => 'A', 'Michael'    => 'B', 'Doug'       => 'C', 'Bill'       => 'D',
    'Matt'       => 'E', 'Kyle'       => 'F', 'Dawn'       => 'G', 'Kurt'       => 'H',
    'Courtney'   => 'I', 'Amanda'     => 'J', 'Taylor'     => 'K', 'Shelby'     => 'L',
    'Carol'      => 'M', 'Kathy'      => 'N', 'Keith'      => 'O', 'Carrie'     => 'P',
    'Corey'      => 'Q', 'Kelly'      => 'R', 'Erik'       => 'S', 'John'       => 'T',
    'Nick'       => 'U', 'Eva'        => 'V', 'Karen'      => 'W', 'Barb'       => 'X',
    'Ivan'       => 'Y', 'Michelle'   => 'Z', 'Shelly'     => 'a', 'Guyla'      => 'b',
    'Gary'       => 'c', 'Dan'        => 'd', 'Bianca'     => 'e', 'Hamlet'     => 'f',
    'Othello'    => 'g', 'Iago'       => 'h', 'Brabantio'  => 'i', 'Berenice'   => 'j',
    'Beatrice'   => 'k', 'Emilia'     => 'l', 'Amy'        => 'm', 'Angela'     => 'n',
    'Sheri'      => 'o', 'Ginger'     => 'p', 'Chloe'      => 'q', 'Amber'      => 'r',
    'Kristi'     => 's', 'Jasmine'    => 't', 'Pierre'     => 'u', 'Francois'   => 'v',
    'Louis'      => 'w', 'Pietro'     => 'x', 'Reed'       => 'y', 'Peter'      => 'z',
    'Ned'        => '`', 'Homer'      => '1', 'Bart'       => '2', 'Lisa'       => '3',
    'Marge'      => '4', 'Margaret'   => '5', 'Mo'         => '6', 'Barney'     => '7',
    'Sherlock'   => '8', 'Pennywise'  => '9', 'Harry'      => '0', 'Stephen'    => '-',
    'Lenore'     => '=', 'Edgar'      => '~', 'Howard'     => '!', 'Phillip'    => '@',
    'Hrothgar'   => '#', 'Gunther'    => '$', 'Beowulf'    => '%', 'Unferth'    => '^',
    'Arthur'     => '&', 'Lancelot'   => '*', 'Percival'   => '(', 'Bors'       => ')',
    'Elaine'     => '_', 'Igraine'    => '+', 'Uther'      => ';', 'Merlin'     => ':',
    'Leo'        => '"', 'Brett'      => "'", 'Shane'      => '[', 'George'     => '{',
    'Alfred'     => ']', 'Alex'       => '}', 'Ron'        => '\\','Henry'      => '|',
    'Mitchell'   => ',', 'Spenser'    => '<', 'Ray'        => '.', 'Donald'     => '>',
    'Robin'      => '/', 'Robert'     => '?', 'Kevin'      => ' ', 'Terry'      => ' ',
    'Franklin'   => ' ', 'Rodney'     => ' ', 'Willow'     => ' ', 'Buffy'      => ' ',
    'Brenda'     => ' ', 'Mark'       => ' ', 'Luke'       => ' ', 'Elizabeth'  => ' ',
    'Tucker'     => ' ', 'Hal'        => ' ', 'Monica'     => 'a', 'Allen'      => 'a',
    'Cliff'      => 'a', 'Nina'       => 'a', 'Palmer'     => 'a', 'Joseph'     => 'a',
    'Leslie'     => 'a', 'Randall'    => 'a', 'Kent'       => 'a', 'Gronk'      => 'a',
    'Remick'     => 'e', 'Ronald'     => 'e', 'Dougal'     => 'e', 'Angus'      => 'e',
    'Flip'       => 'e', 'Jay'        => 'e', 'Reese'      => 'e', 'Dwight'     => 'e',
    'Rocky'      => 'e', 'Bjorn'      => 'e', 'Helga'      => 'n', 'Loki'       => 'n',
    'Brunhilda'  => 'n', 'Hansel'     => 'n', 'Gretel'     => 'n', 'Grendel'    => 'n',
    'Bertilak'   => 'n', 'Bernie'     => 'n', 'Basil'      => 'n', 'Erol'       => 'n',
    'Malcom'     => 'o', 'Marie'      => 'o', 'Jane'       => 'o', 'Clark'      => 'o',
    'Buster'     => 'o', 'Franco'     => 'o', 'Earl'       => 'o', 'Laertes'    => 'o',
    'Odysseus'   => 'o', 'Telemachus' => 'o', 'Zeus'       => 'r', 'Heracles'   => 'r',
    'Ophelia'    => 'r', 'Hera'       => 'r', 'Aphrodite'  => 'r', 'Venus'      => 'r',
    'Ares'       => 'r', 'Apollo'     => 'r', 'Amphitryon' => 'r', 'Agamemnon'  => 'r',
    'Menelaus'   => 's', 'Paulo'      => 's', 'Ivano'      => 's', 'Junior'     => 's',
    'Jughead'    => 's', 'Jared'      => 's', 'Jimmy'      => 's', 'Perry'      => 's',
    'Taliesin'   => 's', 'Devon'      => 's', 'Red'        => 't', 'Bonzo'      => 't',
    'Sparky'     => 't', 'Tex'        => 't', 'Surachai'   => 't', 'Samaransak' => 't',
    'Nai'        => 't', 'Jackie'     => 't', 'Bruce'      => 't', 'Lennox'     => 't'
);

@nSpace = ( 'Kevin',    'Terry',    'Franklin',  'Rodney', 'Willow',    'Buffy',      'Brenda',   'Mark',    'Luke',       'Elizabeth', 'Tucker', 'Hal' );
@nA =     ( 'Monica',   'Allen',    'Cliff',     'Nina',   'Palmer',    'Joseph',     'Leslie',   'Randall', 'Kent',       'Gronk' );
@nE =     ( 'Remick',   'Ronald',   'Dougal',    'Angus',  'Flip',      'Jay',        'Reese',    'Dwight',  'Rocky',      'Bjorn' );
@nN =     ( 'Helga',    'Loki',     'Brunhilda', 'Hansel', 'Gretel',    'Grendel',    'Bertilak', 'Bernie',  'Basil',      'Erol' );
@nO =     ( 'Malcom',   'Marie',    'Jane',      'Clark',  'Buster',    'Franco',     'Earl',     'Laertes', 'Odysseus',   'Telemachus' );
@nR =     ( 'Zeus',     'Heracles', 'Ophelia',   'Hera',   'Aphrodite', 'Venus',      'Ares',     'Apollo',  'Amphitryon', 'Agamemnon' );
@nS =     ( 'Menelaus', 'Paulo',    'Ivano',     'Junior', 'Jughead',   'Jared',      'Jimmy',    'Perry',   'Taliesin',   'Devon' );
@nT =     ( 'Red',      'Bonzo',    'Sparky',    'Tex',    'Surachai',  'Samaransak', 'Nai',      'Jackie',  'Bruce',      'Lennox' );

%Phrases = (
    'That was funny!'                                        => 'A', 'How long have you been here?'                           => 'B',
    'How long have you been waiting?'                        => 'C', 'When did you say you had your appointment?'             => 'D',
    'That is a lovely shade of blue.'                        => 'E', 'That weighs a bit more than I expected.'                => 'F',
    'Where did you say you want me to put that?'             => 'G', "I won't put that there."                                => 'H',
    "Are you sure I'm supposed to put that there?"           => 'I', 'I need to sharpen my sword.'                            => 'J',
    'I like to paint.'                                       => 'K', 'Wow, you have a lot of books.'                          => 'L',
    'I finally got my network setup.'                        => 'M', 'I need more RAM.'                                       => 'N',
    'Where did I put my pen?'                                => 'O', 'That looks like a nasty cut.'                           => 'P',
    'Have you got some aspirin?'                             => 'Q', 'Got any gum?'                                           => 'R',
    'My subscription to Sys Admin is about to expire.'       => 'S', "She's pretty"                                           => 'T',
    'I wish it would stop raining.'                          => 'U', 'It is waaaaay too hot in here.'                         => 'V',
    'Could you turn that fan off?'                           => 'W', 'Do you know much about TCP/IP?'                         => 'X',
    'I finally got my certificate.'                          => 'Y', 'That picture frame is a little crooked.'                => 'Z',
    'Did you hear that noise?'                               => 'a', 'Hey, the Inspector General is coming.'                  => 'b',
    'Lucky for me.'                                          => 'c', "You don't say?"                                         => 'd',
    'Could that possibly smell any worse?'                   => 'e', 'Probably not.'                                          => 'f',
    'How long should I cook this?'                           => 'g', "You'll want to cook that very slowly."                  => 'h',
    'Me want beer.'                                          => 'i', 'I could really use a nap.'                              => 'j',
    'I have to pick up my daughter after work.'              => 'k', 'Do you think anyone will notice?'                       => 'l',
    "Not if you expect to go out in public."                 => 'm', 'Hey, I like this song.'                                 => 'n',
    'That is too expensive for me.'                          => 'o', 'Says who?'                                              => 'p',
    "I don't like it when you touch me there."               => 'q', 'I know, but I never liked it.'                          => 'r',
    'Hot enough for you?'                                    => 's', 'I had spaghetti for dinner three times last week.'      => 't',
    'I could have sworn I locked the door.'                  => 'u', 'Have you seen my keys?'                                 => 'v',
    'I saw it over there.'                                   => 'w', 'Do these pants make my butt look big?'                  => 'x',
    'Putting on a little weight, I see.'                     => 'y', "Say that again and I'll smack you."                     => 'z',
    'I am an excellent driver.'                              => '`', 'You drive too fast.'                                    => '1',
    'I love pizza.'                                          => '2', 'Not nearly as much as you do.'                          => '3',
    'Come over here and sit on my lap.'                      => '4', 'Not a chance in hell.'                                  => '5',
    'You know you want to.'                                  => '6', 'Sure I do.'                                             => '7',
    'You are weak and lack skill.'                           => '8', 'How about a nice bottle of wine with dinner?'           => '9',
    'I could use a shower.'                                  => '0', 'How many fish did you catch?'                           => '-',
    'That is quite a collection you have there.'             => '=', 'Please stop hitting me with that pickle.'               => '~',
    'Why would I want to do that?'                           => '!', 'I asked nicely.'                                        => '@',
    'Look at all those chickens!'                            => '#', 'This is taking too long.'                               => '$',
    "I've been trying to learn that for ages."               => '%', 'How many times?'                                        => '^',
    'Eight or nine, I think.'                                => '&', 'Not unless you want me to cry.'                         => '*',
    'I hope she likes it.'                                   => '(', 'She will, especially if you throw it at her.'           => ')',
    'He never stops complaining!'                            => '_', "Sure, just wait until he isn't looking."                => '+',
    'Why does that smell like cheese?'                       => '[', "I'm not sure I've ever seen anything that ugly."        => '{',
    'How may of those do you have?'                          => ']', 'Lots more than you do.'                                 => '}',
    'I would love to.'                                       => '\\','I can think of nothing I would like better.'            => '|',
    'No, it is too soon for that.'                           => ';', 'She thinks I dance funny.'                              => ':',
    'Nice socks. Did you get dressed in the dark?'           => "'", 'Why must you say things like that?'                     => '"',
    'Because I think it is funny.'                           => ',', 'Hey, you asked.'                                        => '<',
    "That's the last time I ask for your opinion."           => '.', 'I never did care for that.'                             => '>',
    "That's what you think."                                 => '/', 'Wonderful, my nose is bleeding again.'                  => '?',
    'Why would I do that?'                                   => ' ', 'I need more paint.'                                     => ' ',
    'The water is warm.'                                     => ' ', 'Have you ever seen so many worms?'                      => ' ',
    'Three, maybe four times. And you?'                      => ' ', 'My shoe is untied again.'                               => ' ',
    'I finally got around to doing that.'                    => ' ', 'Could you please pass the coleslaw?'                    => ' ',
    'Have you ever seen one of these?'                       => ' ', "I've never seen one so close up before."                => ' ',
    'It looks sort of squashed.'                             => ' ', 'Whatever you say.'                                      => ' ',
    'Not if you paid me.'                                    => 'a', "Please don't poke me with that."                        => 'a',
    'Have you looked under the table?'                       => 'a', 'It has water in it.'                                    => 'a',
    'Hey, nice foot.'                                        => 'a', "I'm not sure I should put that there."                  => 'a',
    'I beg your pardon?'                                     => 'a', 'Not at the moment.'                                     => 'a',
    "I don't think so."                                      => 'a', 'Who?'                                                   => 'a',
    'I never did learn how to do that very well.'            => 'e', 'It is much heavier than it looks.'                      => 'e',
    'No, you have too many already.'                         => 'e', 'Done!',                                                 => 'e',
    'I win, you lose.'                                       => 'e', 'Get bent.'                                              => 'e',
    'When would be a good time for you?'                     => 'e', 'Pfah!'                                                  => 'e',
    'In your shoe, I think.'                                 => 'e', 'I did that yesterday.'                                  => 'e',
    'Ok, but it will cost you.'                              => 'n', 'I like it when you touch me there.'                     => 'n',
    'Have I ever told you that you look like Ted Koppel?'    => 'n', "Shhhh. I'm trying to listen to this."                   => 'n',
    'Will you never stop crying?'                            => 'n', 'Because I said so.'                                     => 'n',
    'As soon as the train stops.'                            => 'n', 'That is a very large apple.'                            => 'n',
    "I'm not sure what that is."                             => 'n', 'No thanks.'                                             => 'n',
    'Could you repeat that?'                                 => 'o', 'I have never been so bored.'                            => 'o',
    'So what are your thoughts on Tolstoy?'                  => 'o', "I'm still trying to find the plot."                     => 'o',
    "He's rather fond of himself, isn't he?"                 => 'o', "Well it looks like...I don't know what it looks like."  => 'o',
    'Your point being?'                                      => 'o', 'And...?'                                                => 'o',
    'I have a picture of that on my mousepad.'               => 'o', 'That stain will never come out.'                        => 'o',
    'I tried that once, but it felt really weird.'           => 'r', 'That door sure is hard to open.'                        => 'r',
    'That really hurt.'                                      => 'r', 'I have to delete that.'                                 => 'r',
    'It is just too big.'                                    => 'r', 'Only when I cross my eyes.'                             => 'r',
    'Do you really think so?'                                => 'r', 'I took an educated guess.'                              => 'r',
    'Your theory is fundamentally flawed.'                   => 'r', "You probably shouldn't put your finger there."          => 'r',
    'I think you broke it.'                                  => 's', 'It just needs new batteries.'                           => 's',
    'How long have you known?'                               => 's', "You think I'm dumb, don't you?"                         => 's',
    "I've never been so insulted."                           => 's', 'Sure is windy out there.'                               => 's',
    'I wish I could fly.'                                    => 's', 'At night the ice weasles come.'                         => 's',
    'The penguins are tearing at my flesh.'                  => 's', 'Do you smell smoke?'                                    => 's',
    'You should try it sometime.'                            => 't', "I don't think I'd like that."                           => 't',
    'Kiss me.'                                               => 't', 'Do you need a tissue?'                                  => 't',
    'Good question.'                                         => 't', 'What an ugly cat!'                                      => 't',
    'Want to hear a joke?'                                   => 't', 'Not if you are the one doing it.'                       => 't',
    'It sure is a long way down.'                            => 't', 'How long did it take to make that?'                     => 't'
);

@pSpace = (
    'Why would I do that?',                    'I need more paint.',                  'The water is warm.',
    'Have you ever seen so many worms?',       'Three, maybe four times. And you?',   'My shoe is untied again.',
    'I finally got around to doing that.',     'Could you please pass the coleslaw?', 'Have you ever seen one of these?',
    "I've never seen one so close up before.", 'It looks sort of squashed.',          'Whatever you say.'
);

@pA = (
    'Not if you paid me.',              "Please don't poke me with that.",
    'Have you looked under the table?', 'It has water in it.',
    'Hey, nice foot.',                  "I'm not sure I should put that there.",
    'I beg your pardon?',               'Not at the moment.',
    "I don't think so.",                'Who?'
);

@pE = (
    "I never did learn how to do that very well.", "It is much heavier than it looks.",
    "No, you have too many already.",              "Done!",
    "I win, you lose.",                            "Get bent.",
    "When would be a good time for you?",          "Pfah!",
    "In your shoe, I think.",                      "I did that yesterday."
);

@pN = (
    'Ok, but it will cost you.',                           'I like it when you touch me there.',
    'Have I ever told you that you look like Ted Koppel?', "Shhhh. I'm trying to listen to this.",
    'Will you never stop crying?',                         'Because I said so.',
    'As soon as the train stops.',                         'That is a very large apple.',
    "I'm not sure what that is.",                          'No thanks.'
);

@pO = (
    'Could you repeat that?',                   'I have never been so bored.',
    'So what are your thoughts on Tolstoy?',    "I'm still trying to find the plot.",
    "He's rather fond of himself, isn't he?",   "Well it looks like...I don't know what it looks like.",
    "Your point being?",                        'And...?',
    'I have a picture of that on my mousepad.', 'That stain will never come out.'
);

@pR = (
    'I tried it once, but it felt really weird.', 'That door sure is hard to open.',
    'That really hurt.',                          'I have to delete that.',
    'It is just too big.',                        'Only when I cross my eyes.',
    'Do you really think so?',                    'I took an educated guess.',
    'Your theory is fundamentally flawed.',       "You probably shouldn't put your finger there."
);

@pS = (
    'I think you broke it.',          'It just needs new batteries.',
    'How long have you known?',       'I wish I could fly.',
    'At night the ice weasles come.', 'The penguins are tearing at my flesh.',
    "You think I'm dumb, don't you?", "I've never been so insulted.",
    'Sure is windy out there.',       'Do you smell smoke?'
);

@pT = (
    'You should try it sometime.', "I don't think I'd like that.",
    'Kiss me.',                    'Do you need a tissue?',
    'Good question.',              'What an ugly cat!',
    'Want to hear a joke?',        'Not if you are the one doing it.',
    'It sure is a long way down.', 'How long did it take to make that?'
);

while ( ( $name, $val ) = each %Names ) {
    $rNames{ $val } = $name;
}

while ( ( $name, $val ) = each %Phrases ) {
    $rPhrases{ $val } = $name;
}

@Names = keys %Names;

@Actions = (
    'writes a poem',                            'enters from stage left',
    "peers over Michael's shoulder",            'laughs',
    'screams in pain',                          'opens a book',
    'sits at the table',                        'crosses stage right',
    'looks under the chair',                    'straightens the table cloth',
    'opens the window',                         'looks around in confusion',
    'starts singing quietly',                   'closes the window',
    'cries',                                    'enters from stage right',
    'crosses stage left',                       'picks up the book',
    'breaks the mirror',                        'kicks the table',
    'gazes longingly at Pietro',                'dances a merry jig',
    'thinks happy thoughts',                    'falls to the floor',
    'tries to think of something funny to say', 'yearns for the good old days',
    'turns on the radio',                       'turns off the radio',
    'turns on the television',                  'turns off the television',
    'selects a book from the bookshelf',        'concentrates',
    'burps',                                    'clucks like a chicken',
    'motions toward the door',                  'plops down on the sofa',
    'looks around suspiciously',                'beings folding laundry',
    'takes a pan of brownies from the oven',    'thinks of the color blue',
    "pours vinegar in Karen's shoes",           'eats a pickle',
    'disrobes',                                 'dances about like a loon',
    'flits about like a fawn in springtime',    'does an impression of Charlie Chaplin',
    'takes a ham from the oven',                'begins plucking a chicken',
    'tries to hide under the rug',              'removes the cushions from the sofa',
    'opens the pantry',                         'climbs in the pantry',
    'crawls under the sink',                    'closes the pantry',
    'fixes a turkey sandwich',                  'starts making pancakes'
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub RandomElement {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    $arrayref->[ rand @{ $arrayref } ];
}

sub StageDirections {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    return $Delimiter{ 'left' } . RandomElement( \@Names ) . " " . RandomElement( \@Actions ) . $Delimiter{ 'right' } . "\n";
}

sub Make {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $string = shift;
    my @chars = split ( //, $string );
    my ( $out, $i, $temp );
    for ( $i = 0 ; $i <= $#chars ; $i += 2 ) {
        if ( $chars[ $i ] eq "\n" ) {
            $out .= StageDirections();
            $i--;
            next;
        } elsif ( $chars[ $i ] eq " " ) {
            $temp = RandomElement( \@nSpace ) . ":";
        } elsif ( $chars[ $i ] eq "a" ) {
            $temp = RandomElement( \@nA ) . ":";
        } elsif ( $chars[ $i ] eq "e" ) {
            $temp = RandomElement( \@nE ) . ":";
        } elsif ( $chars[ $i ] eq "n" ) {
            $temp = RandomElement( \@nN ) . ":";
        } elsif ( $chars[ $i ] eq "o" ) {
            $temp = RandomElement( \@nO ) . ":";
        } elsif ( $chars[ $i ] eq "r" ) {
            $temp = RandomElement( \@nR ) . ":";
        } elsif ( $chars[ $i ] eq "s" ) {
            $temp = RandomElement( \@nS ) . ":";
        } elsif ( $chars[ $i ] eq "t" ) {
            $temp = RandomElement( \@nT ) . ":";
        } else {
            $temp = "$rNames{ $chars[ $i ] }:";
        }
        if ( ( $i + 1 ) > $#chars || $chars[ $i + 1 ] eq "\n" ) {
            $out .= $temp . " " . RandomElement( \@pSpace ) . "\n" . StageDirections();
            next;
        } elsif ( $chars[ $i + 1 ] eq " " ) {
            $temp .= " " . RandomElement( \@pSpace );
        } elsif ( $chars[ $i + 1 ] eq "a" ) {
            $temp .= " " . RandomElement( \@pA );
        } elsif ( $chars[ $i + 1 ] eq "e" ) {
            $temp .= " " . RandomElement( \@pE );
        } elsif ( $chars[ $i + 1 ] eq "n" ) {
            $temp .= " " . RandomElement( \@pN );
        } elsif ( $chars[ $i + 1 ] eq "o" ) {
            $temp .= " " . RandomElement( \@pO );
        } elsif ( $chars[ $i + 1 ] eq "r" ) {
            $temp .= " " . RandomElement( \@pR );
        } elsif ( $chars[ $i + 1 ] eq "s" ) {
            $temp .= " " . RandomElement( \@pS );
        } elsif ( $chars[ $i + 1 ] eq "t" ) {
            $temp .= " " . RandomElement( \@pT );
        } else {
            $temp .= " " . $rPhrases{ $chars[ $i + 1 ] };
        }
        $out .= $temp . "\n";
    }
    return $out;
}

sub UnMake {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $string = shift;
    my $out    = "";
    my @lines  = split ( /\n/, $string );
    foreach my $line ( @lines ) {
        ( $name, $val ) = split ( /: /, $line );
        if ( $name =~ /^\[/ && ! $val ) {
            $out .= "\n";
            next;
        }
        if ( defined $Names{ $name } ) {
            $out .= $Names{ $name };
        }
        if ( defined $Phrases{ $val } ) {
            $out .= $Phrases{ $val };
        }
    }
    return $out;
}

1;
__END__

=head1 NAME

Acme::Playwright - Simple text obfuscation in the form of a play.

=head1 SYNOPSIS

  use Acme::Playwright;
  $play = Acme::Playwright::Make( $string );
  $plaintext = Acme::Playwright::UnMake( $play );
  
  # OR
  
  use Acme::Playwright;
  $ref = Acme::Playwright->new();
  $play = $ref->Make( $string );
  $plaintext = $ref->UnMake( $play );

=head1 DESCRIPTION

To be honest, I did this mostly for the comedy value. I was toying with the idea of making a real steganography module, and the next thing I knew, I was writing Playwright instead. It does offer a degree of security (albeit not a terribly high degree), especially if you replace some of the default names and/or phrases with your own.

=head1 AUTHOR

Kurt Kincaid <sifukurt@yahoo.com>

=head1 SEE ALSO

L<perl>.

=cut

