package Amethyst::Brain::Infobot::Module::Zappa;

use strict;
use vars qw(@ISA);
use Amethyst::Message;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Zappa',
					Regex		=> qr/^(be zappa)$/i,
					Usage		=> 'be zappa',
					Description	=> "gives you a random quote from " .
									"Frank Zappa",
					@_
						);

	return bless $self, $class;
}

sub action {
    my ($self, $message) = @_;

	my $reply = $self->reply_to($message, $self->quote());
	$reply->send;

	return 1;
}

sub quote { 
	my $self = shift;

	unless ($self->{quotes}) {
		while (<DATA>) {
			chomp;
			push @{$self->{quotes}}, $_; 
		}
	}

	my $y = $self->{quotes}->[rand(@{$self->{quotes}})];

	return $y;
}

1;

__DATA__
Don't eat yellow snow!
Remember there's a big difference between kneeling down and bending over.
You have just destroyed one model XQJ-37 nuclear powered pansexual roto-plooker....and you're gonna have to pay for it.
He was in a quandary...being devoured by the swirling cesspool of his own steaming desires... uh.. the guy was a wreck
All people have the right to be stupid, some people just abuse it!
And now....you are going to dance...like you've never danced before!
Bring the band on down behind me, boys.
Not a speck of cereal.
Nothing but the best for my dog.
You drank beer, you played golf, you watched football - WE EVOLVED!
It looks just like a Telefunken U-47!
Don't mind your make-up, you'd better make your mind up.
They're serving burgers in the back!
Jazz is not dead...it just smells funny. -- Beebop tango introduction
I have a message to deliver to the cute people of the world...if you're cute, or maybe you're beautiful...there's MORE OF US UGLY MOTHERFUCKERS OUT THERE THAN YOU ARE!! So watch out.
Is that a real poncho or a Sears poncho?
You're an asshole! You're an asshole! That's right! You're an asshole! You're an asshole! Yes yes!
Number one ain't you... You ain't even number two.
Who are the brain police?
A prune isn't really a vegetable... CABBAGE is a vegetable...
Here's one for mother
Only thirteen, and she knows how to NASTY
ARE YOU HUNG UP?
Don't it ever get lonesome?
Eddie, are you kidding?
I'll do the stupid thing first and then you shy people follow...
Stupidity is the basic building block of the universe.
Never try to get your peter sucked in France.
Kill Ugly Radio
I'm not black, but there's a whole lot of times I wish I could say I'm not white.
Help!  I'm a rock!
Another day, another sausage...
Some Scientists claim that hydrogen, because it is so plentiful, is the basic building block of the universe. I dispute that. I say there is more stupidity than hydrogen, and that is the basic building block of the universe.
I want a garden!
On a personal level, Freaking Out is a process whereby an individual casts off outmoded and restricting standars of thinking, dress, and social etiquette in order to express CREATIVELY his relationship to his immediate environment and the social structure as a whole. --Freak Out liner notes
Great googly-moogly - you're gonna do it too!
Information is not knowledge, Knowledge is not wisdom, Wisdom is not truth, Truth is not beauty, Beauty is not love, Love is not music Music is THE BEST
Gee, it's so hard to find a place to park around here.
There are more love songs than anything else. If songs could make you do something we'd all love one another.
If classical music is the state of the art, then the arts are in a sad state.
Beauty is a French phonetic corruption of a short, cloth neck ornament, currently in resurgence.
Modern music is a sick puppy.
Some Scientists claim that hydrogen, because it is so plentiful, is the basic building block of the universe. I dispute that. I say there is more stupidity than hydrogen, and that is the basic building block of the universe.
Most people wouldn't know good music if it came up and bit them in the äss. -- Whole Grains
I figure the odds be fifty-fifty I just might have some thing to say.
The person who stands up and says, `This is stupid,' either is asked to behave  or, worse, is greeted with a cheerful `Yes, we know! Isn't it terrific!'
The more BORING a child is, the more the parents, when showing off the child, receive adulation for being GOOD PARENTS -- because they have a TAME CHILD-CREATURE in their house.
The worst aspect of `typical familyism' (as media-merchandised) is that it glorifies _involuntary_homogenization_.
Gail has said in interviews that one of the things that makes our relationship work is the fact that we hardly ever get to talk to each other.
The language and concepts contained herein are guaranteed not to cause eternal torment in the place where the guy with the horns and pointed stick conducts his business.
My best advice to anyone who wants to raise a happy, mentally healthy child is: Keep him or her as far away from a church as you can.
I like having the capitol of the United States in Washington, D.C., in spite of recent efforts to move it to Lynchburg, Virginia.
He [Barney Frank] is one of the most impressive guys in Congress.  He is a great model for young gay men.
Children are naive -- they trust everyone. School is bad enough, but, if you put a child anywhere in the vicinity of a church, you're asking for trouble.
It would be easier to pay off the national debt overnight than to neutralize the long-range effects of OUR NATIONAL STUPIDITY.
Nuclear explosions under the Nevada desert? What the fück are we testing for? We already know the shit blows up.
Politics is the entertainment branch of industry.
Star Wars won't work.  Star Wars won't work. The gas still gets through; it could get right on you.  And what about those germs, now? Star Wars won't work.
Washington, D.C.: a city infested with statues -- and Congressional Blow-Boys who WISH they were statues.
Thanks to our schools and political leadership, the U.S. has acquired an international reputation as the home of 250 million people dumb enough to buy 'The Wacky Wall-Walker.'
Stupidity has a certain charm -- ignorance does not.
The real question is: Is it possible to laugh while fucking?
The single-child yuppo-family that uses the child as a status object: `A perfect child? Of course! We have one here -- he's under the coffee table. Ralph, stand up! Play the violin!'
Americans like to talk about (or be told about) Democracy but, when put to the test, usually find it to be an 'inconvenience.'  We have opted instead for an authoritarian system disguised as a Democracy.  We pay through the nose for an enormous joke-of-a-government, let it push us around, and then wonder how all those ässholes got in there.
In every language, the first word after 'Mama!' that every kid learns to say is 'Mine!'  A system that doesn't allow ownership, that doesn't allow you to say 'Mine!' when you grow up, has -- to put it mildly -- a fatal design flaw.
From the time Mr. Developing Nation was forced to read _The Little Red Book_ in exchange for a blob of rice, till the time he figured out that waiting in line for a loaf of pumpernickel was boring as fuck, took about three generations. ...
Decades of indoctrination, manipulation, censorship and KGB excursions haven't altered this fact: People want a piece of their own little Something-or-Other, and, if they don't get it, have a tendency to initiate counterrevolution.
If it sounds GOOD to YOU, it's bitchen; and if it sounds BAD to YOU, it's shitty.
The computer can't tell you the emotional story.  It can give you the exact mathematical design, but what's missing is the eyebrows.
In the fight between you and the world, back the world.
Let's not be too tough on our own ignorance.  It's the thing that makes America great.  If America weren't incomparably ignorant, how could we have tolerated the last eight years?
Lord have mercy on the people in England for the terrible food these people must eat.  And Lord have mercy on the fate of this movie and God bless the mind of the man in the street.
Interviewer:  So Frank, you have long hair.  Does that make you a woman? FZ:           You have a wooden leg.  Does that make you a table?
If your children ever find out how lame you really are, they'll gonna murder you in your sleep....-- Whole Grains
I'm not a man for all seasons but I'm doing something right. -- Frank Zappa during the Senate PMRC hearings.
Ugly as I mights be, I is your futum!
There is no hell. There is only France.
`Conducting' is when you draw `designs' in the nowhere -- with your stick, or with your hands -- which are interpreted as `instructional messages' by guys wearing bow ties who wish they were fishing.
Without music to decorate it, time is just a bunch of boring production  deadlines or dates by which bills must be paid.
The bassoon is one of my favorite instruments.  It has the medieval aroma -- like the days when everything used to sound like that.
Some people crave baseball -- I find this unfathomable --  but I can easily understand why a person could get excited about playing a bassoon.
Whatever you have to do to have a good time, let's get on with it, so long as it doesn't cause a murder.
Politics is the showbiz of industry.
Let's just admit that public education is mediocre at best.
Without deviation from the norm, 'progress' is not possible.
The last election just laid the foundation of the next 500 years of Dark Ages -- 1981
Look, just because you have got that fuckin' thing between  your legs it doesn't make any diference. If a girl does  something stupid I am going to call her just as I would a guy.
A world of sexual incompetents, encountering each other, under disco circumstances... Now can't you do songs about that?
A composer is a guy who goes around forcing his will on unsuspecting air molecules,often with the assistence of  unsuspecting musicians.
There is no such thing as a dirty word. Nor is there a word so powerful, that it's going to send the listener to the lake of fire upon hearing it.
Why do you necessarily have to be wrong just because a few million people  think you are?
Life is like highschool with money.
Information doesn't kill you...  -- PMRC Hearings during an exchange with a Born Again Christian.
Where ever you're going, don't walk there first.  If you do, people will think you know where you're going.
A drug is not bad. A drug is a chemical compound. The problem comes  in when people who take drugs treat them like a licence to behave like an asshole.
Flatulence can be cruel!
Speed: It will turn you into your parents. -- 1970 public service announcement regarding drug (namely, speed) use
Winos don't march.
Reporter: This is a personal thing, I think that if you wanted to make  top ten hits and sell millions of records, you could. FZ: Yeah, but who wants to go through life with a tiny nose and one glove on?
It is always advisable to be a loser if you cannot become a winner.
I knew  Jimi (Hendrix) and I think that the best thing you could say about Jimi was: there was a person who shouldn't use drugs.
The emotion of every player is the most important thing, what stands behind this chord or tone. If you leave that out, the  music does not touch you. -- Interview from Keyboard June 1980.
It's better to have something to remember than nothing to reget...
Why do people continue to compose music, and even pretend to teach  others how to do it, when they already know the answer?  Nobody gives a fuck.
If you wind up with a boring, miserable life because you listened to your  mom, your dad, your teacher, your priest or some guy on TV telling you how to  do your shit, then YOU DESERVE IT. -- The Real Frank Zappa Book
A mind is like a parachute. It doesn't work if it not open.
You've got to be digging it while it's happening 'cause it just might be a one shot deal -- Waka/Jawaka
There will never be a nuclear war; there's too much real estate involved. -- Tonight Show, C.A. 1988
Heaven would be a place where bullshit existed only on television. (Hallelujah! We's halfway there!) -- The Real Frank Zappa Book
Don't expect anything,don't expect fun, don't expect friends.. if you get something...it's a BONUS
Golly, do I ever have alot of soul!!
Shoot low, they're riding Shetlands
Everyone in this room is wearing a uniform, and don't kid yourself -- after being notified there were 'cops in uniform' in the audience.
Children are naive-they trust everyone.  School is bad enough, but, if you  put a child anywhere in the vicinity of a church, you're asking for trouble.
The ONLY thing that seems to band all nations together, is that their  governments are universally bad.. -- German television interview
If we can't be free at least we can be cheap.
Nobody looks good bent over. Especially to pick up a cheque. -- Guitar Magazine 1984
The essence of Christianity is told us in the Garden of Eden history. The fruit that was forbidden was on the tree of knowledge. The subtext is, All the suffering you have is because you wanted to find out what was going on. You could be in the Garden of Eden if you had just keep your fucking mouth shut and hadn't asked any questions. --Playboy Interview, April 1993
When we talk about artistic freedom in this country We sometime lose sight of the fact that freedom is often dependent on adequate financing.
If you want to get laid, go to college, but if you want an education,  go to the library.
Outdoors for me is walking from the car to the ticket desk at the airport -- Regarding secondhand smoke in The Real FZ Book
My music is like a movie for your ear
Here I stand hoping against hope that it's a chick with a low voice -- After a guy in the audience yelled out, 'Eat me Zappa'
Don't clap for destroying America. This place is as good as you want to make it.
The whole Universe is a large joke. Everything in the Universe is just  subdivisions of this joke. So why take anything too serious. -- September 1992 during an interview about the Yellow Shark.
Kid's heads are filled with so many nonfacts that when they get out of  school they're totally unprepared to do anything.  They can't read, they  can't write, they can't think.  Talk about child abuse.  The U.S. school  system as a whole qualifies. -- Playboy magazine, April 1993.
Drop out of school, before your mind rots from exposure to our mediocre  educational system.  Go to the library and educate yourself if you've got any  guts...--SLUG Magazine June 1995
Never stop until your good becomes better, and your better becomes the best.
The people of your century no longer require the service of composers. A composer is as useful to a person in a jogging suit as a dinsoaur turd in the middle of his runway.--from the Them Or Us The Book
THE  VERY  BIG  STUPID is a thing which  breeds  by  eating  The Future.  Have  you seen it? It sometimes disguises  itself  as  a good-looking  quarterly bottom line, derived by closing  the  R&D Department. -- The Real Frank Zappa Book.
Most rock journalism is people who can not write interviewing people who can not talk.
The typical rock fan is not smart enough to know when he is being dumped on.
It's not pretty, also you can't dance to it.
It's all one big note.
Ladies and gentleman, watch Ruth.  All through the show, Ruth has been thinking...Ruth has been thinking?  ALL THROUGH THE SHOW???
You can tell what they think of our music by the places we are forced to play it in.  This looks like a good spot for a livestock show. -- April 1968, Chicago, Mothers of Invention open for Cream
I'm not going to be Bill Clinton and say I never inhaled.  I did inhale.  I liked tobacco a lot better.
Consider for a moment any beauty in the name Ralph. -- FZ on why he gave his children such odd names
I write the music I like. If other people like it, fine, they can go buy the albums. And if they don't like it, there's always Michael Jackson for them to listen to. -- about his music from the Yellow Shark.
I never set out to be weird. It was always the other people who called me weird.
Government is the Entertainment Division of the military-industrial complex.
Why doncha come on over to the house and I'll show 'em to ya? -- PMRC Hearings to Sen. Hawkins in reply to her comment: 'I'd like to see what kind of toys your children play with.'
You get nothing with your college degree -- from Roxy & Elsewhere
With the power of soul you can do anything you wanna do.
Playing guitar with this band is like trying to grow WATERMELON IN EASTER HAY.
Always get a second opinion. -- His personal physician did not diagnose prostate cancer  before it was too advanced to treat with any success.
The crux of the biscuit is: If it entertains you, fine.  Enjoy it. If it  doesn't, then blow it out your ass. I do it to amuse myself. If I like it,  I release it. If somebody else likes it, that's a bonus.  -- Playboy Interview May 2, 1993
I never took a shït on stage, and the closest I ever came to eating shït anywhere was at a Holiday Inn buffet in Fayetteville, North Carolina, in 1973. -- The Real Frank Zappa Book
You can't be a Real Country unless you have a BEER and an airline - it helps if you have some kind of a football team or some nuclear weapons, but at the very least you need a BEER.
Nobody looks good in brown lipstick
Whenever your down, just think about how you got there.
To me, cigarettes are food -- Response to an assertion that his nicotine habit  conflicted with his anti-drug stance
May you'll never hear a vloerbedekking again.
Seeing a psychotherapist is not a crazy idea, its just wanting a second opinion of ones life.
You can't always write a chord ugly enough to say what you  want to say, so sometimes you have to rely on a giraffe filled with whipped cream.
Bad facts make bad laws -- Said during the PMRC hearings
Well, you know people, I'd rather have my own game show than enough votes  to become president.
Anything can be music -- Answer to critics accusing him of not doing actual music on Uncle Meat
Scientology, how about that?  You hold on to the tin cans and then this guy  asks you a bunch of questions, and if you pay enough money you get to join  the master race. How's that for a religion? -- Concert at the Rockpile, Toronto, May 1969
Yeah, I tell them to change the channel if they see  some guy in a brown suit with a telephone number at the bottom of the screen asking for money. -- response to Tipper Gore when asked if there was anything on the TV he _didn't_ allow his kids to watch
I wrote a song about dental floss but did anyone's teeth get cleaner? --response to Tipper Gore's allegation that music incites people towards  deviant behavior, or influences their behavior in general.
People who think of videos as an art form are probably the same people who think Cabbage Patch Dolls are a  revolutionary form of soft sculpture. -- Viva Zappa - Biography
People make a lot of fuss about my kids having such supposedly 'strange names', but the fact is that no matter what first names I might have given them, it is the last name that is going to get them in trouble. -- The Real Frank Zappa Book
I think you should leave it up to the parent, because not all parents want to keep their children totally ignorant. -- response to a question from Senator Hollings.
The concept of the rock-guitar solo in the eightees has pretty much been reduced to: Weedly-weedly-wee, make a face,  hold your guitar like it's your weenie, point it heavenward, and look like you're really doing something. Then, you get a big ovation while the the smoke bombs go off, and the  motorized lights in your truss twirl around! -- The Real Frank Zappa Book
Art is making something out of nothing and selling it.
The typical rock fan is not smart enough to know when he is being dumped on.
Most rock journalism is people who can not write interviewing people who can not talk.
