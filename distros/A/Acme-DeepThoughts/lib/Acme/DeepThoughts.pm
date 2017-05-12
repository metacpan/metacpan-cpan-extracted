package Acme::DeepThoughts;
$VERSION = '0.01';

my $glass = " \t"x8;
sub reflect { local $_ = unpack "b*", pop; tr/01/ \t/; s/(.{9})/$1\n/g; $glass.$_ }
sub deflect { local $_ = pop; s/^$glass|[^ \t]//g; tr/ \t/01/; pack "b*", $_ }
sub opaque  { $_[0] =~ /\S/ }
sub deep    { $_[0] =~ /^$glass/ }

open 0 or print "Can't open '$0'\n" and exit;
(my $thought = join "", <0>) =~ s/.*^\s*use\s+Acme::DeepThoughts\s*;\n\n(?:.*?--\s+Jack\s+Handey.*?\n)?//sm;

local $SIG{__WARN__} = \&opaque;
do {eval deflect $thought; exit} unless opaque $thought and not deep $thought;

my $DeepThought = '';
{
    my $rand = int rand 152;
    while($rand > 0){
        $DeepThought = <DATA>;
        $rand--;
    }
    close DATA;
    chomp $DeepThought;

    require Text::Wrap;
    local $Text::Wrap::columns = 72;

    my @lines = Text::Wrap::wrap('', '', $DeepThought);

    if(length $lines[-1] < 63 ){
        $lines[-1] .= "  --  Jack Handey";
    } else {
        push @lines, "        --  Jack Handey";
    }

    $DeepThought = join "\n",@lines;
}

open 0, ">$0" or print "Cannot ponder '$0'\n" and exit;
print {0} "use Acme::DeepThoughts;\n\n$DeepThought\n", reflect $thought and exit;

=head1 NAME

Acme::DeepThoughts - Jack Handey does perl


=head1 SYNOPSIS

    use Acme::DeepThoughts
    print "Hello world";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::DeepThoughts>, the module
removes all the unsightly printable characters from 
your source file. The code continues to work exactly as it did before, 
but now it contains a I<Deep Thought>.

These deep thoughts were collected from E<lt>L<http://deepthoughts.330.ca/>E<gt>,
which is a site "I<dedicated to the quotes that used to appear on the hit TV show, Saturday Night Live (SNL)>."

=head1 BUGS

Please don't report bugs ;)
But if you really really need to, go to 
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-DeepThoughtsE<gt>
or send mail to E<lt>bug-Acme-DeepThoughts#rt.cpan.orgE<gt>


=head1 AUTHOR

	D. H. (PODMASTER)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Acme::Bushisms|Acme::Bushisms>, L<Acme::Bleach|Acme::Bleach>,.

=cut

__DATA__
If I could be a bird, I'd be a Flying Purple People Eater because then people would sing about me and I could fly down and eat them because I hate that song.
When I die, I would like to go peacefully, in my sleep, like my Grandfather did.  Not screaming and yelling like the passenger in his car.
I think one way the cops could make extra money would be to hold a used murder weapons sale. Many people could really use cheap a ice pick.
If you ever reach total enlightenment while drinking beer, I bet beer would shoot out of you nose.
I believe in making the world safe for our children, but not our children's children, because I don't think children should be having sex.
Even though I was their captive, the Indians allowed me quite a bit of freedom. I could walk freely, make my own meals, and even hurl large rocks at their heads. It was only later that I discovered that they were not Indians at all but only dirty-clothes hampers.
I wish outer space guys would conquer the Earth and make people their pets, because I'd like to have one of those little beds with my name on it.
It's true that every time you hear a bell, an angel gets its wings. But what they don't tell you is that every time you hear a mouse trap snap, and Angel gets set on fire.
If you're in a war, instead of throwing a hand grenade at the enemy, throw one of those small pumpkins. Maybe it'll make everyone think how stupid war is, and while they are thinking, you can throw a real grenade at them.
I hope life isn't a big joke, because I don't get it.
The next time I have meat and mashed potatoes, I think I'll put a very large blob of potatoes on my plate with just a little piece of meat. And if someone asks me why I didn't get more meat, I'll just say, "Oh, you mean this?" and pull out a big piece of meat from inside the blob of potatoes, where I've hidden it. Good magic trick, huh? 
Life, to me, is like a quiet forest pool, one that needs a direct hit from a big rock half-buried in the ground. You pull and you pull, but you can't get the rock out of the ground. So you give it a good kick, but you lose your balance and go skidding down the hill toward the pool. Then out comes a big Hawaiian man who was screwing his wife beside the pool because they thought it was real pretty. He tells you to get out of there, but you start faking it, like you're talking Hawaiian, and then he gets mad and chases you...
Instead of studying for finals, what about just going to the Bahamas and catching some rays?  Maybe you'll flunk, but you might have flunked anyway; that's my point.
Sometimes, when I drive across the desert in the middle of the night, with no other cars around, I start imagining: What if there were no civilization out there? No cities, no factories, no people? And then I think: No people or factories? Then who made this car? And this highway? And I get so confused I have to stick my head out the window into the driving rain---unless there's lightning, because I could get struck on the head by a bolt. 
The whole town laughed at my great-grandfather, just because he worked hard and saved his money. True, working at the hardware store didn't pay much, but he felt it was better than what everybody else did, which was go up to the volcano and collect the gold nuggets it shot out every day. It turned out he was right. After forty years, the volcano petered out. Everybody left town, and the hardware store went broke. Finally he decided to collect gold nuggets too, but there weren't many left by then. Plus, he broke his leg and the doctor's bills were real high. 
Too bad when I was a kid there wasn't a guy in our class that everybody called the "Cricket Boy", because I would have liked to stand up in class and tell everybody, "You can make fun of the Cricket Boy if you want to, but to me he's just like everybody else." Then everybody would leave the Cricket Boy alone, and I'd invite him over to spend the night at my house, but after about five minutes of that loud chirping I'd have to kick him out. Maybe later we could get up a petition to get the Cricket Family run out of town. Bye, Cricket Boy. 
I think a good product would be "Baby Duck Hat". It's a fake baby duck, which you strap on top of your head. Then you go swimming underwater until you find a mommy duck and her babies, and you join them. Then, all of a sudden, you stand up out of the water and roar like Godzilla. Man, those ducks really take off! Also, Baby Duck Hat is good for parties. 
I wish I lived back in the old west days, because I'd save up my money for about twenty years so I could buy a solid-gold pick. Then I'd go out West and start digging for gold. When someone came up and asked what I was doing, I'd say, "Looking for gold, ya durn fool." He'd say, "Your pick is gold," and I'd say, "Well, that was easy." Good joke, huh. 
A funny thing to do is, if you're out hiking and your friend gets bitten by a poisonous snake, tell him you're going to go for help, then go about ten feet and pretend that you got bit by a snake. Then start an argument with him about whose going to go get help. A lot of guys will start crying. That's why it makes you feel good when you tell them it was just a joke. 
I guess I kinda lost control, because in the middle of the play I ran up and lit the evil puppet villain on fire. No, I didn't. Just kidding. I just said that to help illustrate one of the human emotions, which is freaking out. Another emotion is greed, as when you kill someone for money, or something like that. Another emotion is generosity, as when you pay someone double what he paid for his stupid puppet. 
Many people think that history is a dull subject. Dull? Is it "dull" that Jesse James once got bitten on the forehead by an ant, and at first it didn't seem like anything, but then the bite got worse and worse, so he went to a doctor in town, and the secretary told him to wait, so he sat down and waited, and waited, and waited, and waited, and then finally he got to see the doctor, and the doctor put some salve on it? You call that dull? 
I scrambled to the top of the precipice where Nick was waiting. "That was fun," I said. "You bet it was," said Nick. "Let's climb higher." "No," I said. "I think we should be heading back now." "We have time," Nick insisted. I said we didn't, and Nick said we did. We argued back and forth like that for about 20 minutes, then finally decided to head back. I didn't say it was an interesting story. 
If you're a Thanksgiving dinner, but you don't like the stuffing or the cranberry sauce or anything else, just pretend like you're eating it, but instead, put it all in your lap and form it into a big mushy ball. Then, later, when you're out back having cigars with the boys, let out a big fake cough and throw the ball to the ground. Then say, "Boy, these are good cigars!" 
When I was in the 3rd grade, a bully in school started beating me up every day.  At first I didn't say anything, but then I told dad.  He got a real scared look on his face and asked if the bully had a big dad.  I said I didn't know. But he still seemed scared.  And just a few days later we moved to a new town. Dad told me that if anyone picked on me, not to fight back. Unless I knew the kid didn't have a dad or the dad was real small.  Otherwise just curl up in a ball.
I remember that one fateful day when Coach took me aside. I knew what was coming. "You don't have to tell me," I said. "I'm off the team, aren't I?" "Well," said Coach, "you never were really ON the team. You made that uniform you're wearing out of rags and towels, and your helmet is a toy space helmet. You show up at practice and then either steal the ball and make us chase you to get it back, or you try to tackle people at inappropriate times." It was all true what he was saying. And yet, I thought something is brewing inside the head of this Coach. He sees something in me, some kind of raw talent that he can mold. But that's when I felt the handcuffs go on. 
If I ever opened a trampoline store, I don't think I'd call it Trampo-Land, because you might think it was a store for tramps, which is not the impression we are trying to convey with our store. On the other hand, we would not prohibit tramps from browsing, or testing the trampolines, unless a tramp's gyrations seemed to be getting out of control. 
I can still recall old Mister Barnslow getting out every morning and nailing a fresh load of tadpoles to the old board of his. Then he'd spin it round and round, like a wheel of fortune, and no matter where it stopped he'd yell out, "Tadpoles! Tadpoles is a winner!" We all thought he was crazy. But then we had some growing up to do. 
Once when I was in Hawaii, on the island of Kauai, I met a mysterious old stranger. He said he was about to die and wanted to tell someone about the treasure. I said, "Okay, as long as it's not a long story. Some of us have a plane to catch, you know." He started telling his story, about the treasure and his life and all, and I thought: "This story isn't too long." But then, he kept going, and I started thinking, "Uh-oh, this story is getting long." But then the story was over, and I said to myself: "You know, that story wasn't too long after all." I forget what the story was about, but there was a good movie on the plane. It was a little long, though. 
I bet a fun thing would be to go way back in time to where there was going to be an eclipse and tell the cave men, "If I have come to destroy you, may the sun be blotted out from the sky." Just then the eclipse would start, and they'd probably try to kill you or something, but then you could explain about the rotation of the moon and all, and everyone would get a good laugh. 
I wouldn't be surprised if someday some fishermen caught a big shark and cut it open, and there inside was a whole person. Then they cut the person open, and in him is a little baby shark. And in the baby shark there isn't a person, because it would be too small. But there's a little doll or something, like a Johnny Combat little toy guy---something like that.
Whenever anyone says "I can't," it makes me wish he'd get stung to death by about ten thousand bees. When he says "I'll try," five thousand bees. ("I can," one bee.)
A wise man would pick up a grain of sand and envision the entire universe, a stupid man would role in seaweed, stand up, and say, "Look, I'm vine man."
Instead of crucifying people on crosses, why not on windmills?  That way, they get the pain, and the dizziness.
When I found the skull in the woods, the first thing I did was call the police.  But then I got curious about it.  I picked it up, and started wondering who this person was, and why he had deer horns.
If you work on a lobster boat, sneaking up behind people and pinching them is probably a joke that gets old real fast.
If i was being executed by lethal injection, I'd clean up my cell real neat.  Then when they came to get me, I'd say, "Injection?  I thought you said inspection."  Then maybe they might end up feeling real bad, and maybe i could get out of it.
I remember one day I was at Grandpa's farm and I asked him about sex. He sort of smiled and said, "Maybe instead of telling you what sex is, why don't we go out to the horse pasture and I'll show you." So we did, and there on the ground were my parents having sex.
You know what would be the most terrifying thing that could ever happen to a flea? Getting caught inside a watch somehow. You don't even care, do you.
I remember when I was in the army, we had the toughest drill sergeant in the world. He'd get right up next to your face and yell, and if you didn't have the right answers, mister, you'd be peeling potatoes or changing the latrine. Hey, wait. I wasn't in the army. Then who WAS that guy?!
Instead of a trap door, what about a trap window? The guy looks out it, and if he leans too far, he falls out. Wait. I guess that's like a regular window.
The old pool shooter had won many a game in his life. But now it was time to hang up the cue. When he did, all the other cues came crashing to the floor. "Sorry," he said with a smile.
A man doesn't automatically get my respect. He has to get down in the dirt and beg for it.
I bet a funny thing about driving a car off a cliff is, while you're in midair, you still hit those brakes! Hey, better try the emergency brake!
Even though he was an enemy of mine, I had to admit that what he had accomplished was a brilliant piece of strategy. First, he punched me, then he kicked me, then he punched me again.
To us, it might look like just a rag. But to the brave, embattled men of the fort, it was more than that. It was a flag of surrender. And after that, it was torn up and used for shoe-shine rags, so the men would look nice for the surrender.
If you go to a party, and you want to be the popular one at the party, do this: Wait until no one is looking, then kick a burning log out of the fireplace onto the carpet. Then jump on top of it with your body and yell, "Log o' fire! Log o' fire!" I've never done this, but I think it'd work.
You know what's probably a good thing to hang on your porch in the summertime, to keep mosquitoes away from you and your guests? Just a big bag of blood.
If you're traveling in a time machine, and you're eating corn on the cob, I don't think it's going to affect things one way or the other. But here's the point I'm trying to make: Corn on the cob is good, isn't it.
When I was a child, there were times when we had to entertain ourselves. And usually the best way to do that was to turn on the TV.
It's easy to sit there and say you'd like to have more money. And I guess that's what I like about it. It's easy. Just sitting there, rocking back and forth, wanting that money.
If I ever become a mummy, I'm going to have it so when somebody opens my lid, a boxing glove on a spring shoots out.
Broken promises don't upset me. I just think, why did they believe me?
What is it about a beautiful sunny afternoon, with the birds singing and the wind rustling through the leaves, that makes you want to get drunk? And after you're real drunk, maybe go down to the public park and stagger around and ask people for money, and then lie down and go to sleep.
If you ever go temporarily insane, don't shoot somebody, like a lot of people do. Instead, try to get some weeding done, because you'd really be surprised.
It's really sad when a family can be torn apart by something as simple as wild dogs.
Sometimes you have to be careful when selecting a new nickname for yourself. For instance, let's say you have chosen the nickname "Fly Head."  Normally, you would think that "Fly Head" would mean a person who had beautiful swept-back features, as if flying though the air.  But think again.  Couldn't it also mean "having a head like a fly?"  I'm afraid some people might actually think that.
I think college administrators should encourage students to urinate on walls and bushes, because then when students from another college come sniffing around, they'll know this is someone else's territory.
I think somebody should come up with a way to breed a very large shrimp.  That way, you could ride him, then after you camped at night, you could eat him. How about it, science?
If your friend is already dead, and being eaten by vultures, I think it's okay to feed some bits of your friend to one of the vultures, to teach him to do some tricks.  But ONLY if you're serious about adopting the vulture.
At first I thought, if I were Superman, a perfect secret identity would be "Clark Kent, Dentist," because you could save money on tooth X-rays. But then I thought, if a patient said, "How's my back tooth?" and you just looked at it with your X-ray vision and said, "Oh it's okay," then the patient would probably say, "Aren't you going to take an X-ray, stupid?" and you'd say, "Aw f*ck you, get outta here," and then he probably wouldn't even pay his bill
Marta says the interesting thing about fly-fishing is that it's two lives connected by a thin strand. Come on, Marta. Grow up.
Love can sweep you off your feet and carry you along in a way you've never known before. But the ride always ends, and you end up feeling lonely and bitter. Wait. It's not love I'm describing. I'm thinking of a monorail.
When this girl at the art museum asked me whom I liked better, Monet or Manet, I said, "I like mayonnaise." She just stared at me, so I said it again, louder. Then she left. I guess she went to try to find some mayonnaise for me.
It's fascinating to think that all around us there's an invisible world we can't even see. I'm speaking, of course, of the World of the Invisible Scary Skeletons.
Once while walking through the mall a guy came up to me and said "Hey, how's it going?". So I grabbed his arm and twisted it up behind his head and said "Now whose asking the questions?"
Sometimes life seems like a dream, especially when I look down and see that I forgot to put on my pants.
Marta was watching the football game with me when she said, "You know, most of these sports are based on the idea of one group protecting its territory from invasion by another group." "Yeah," I said, trying not to laugh. Girls are funny.
It's amazing to me that one of the world's most feared diseases would be carried by one of the world's smallest animals: the real tiny dog.
I hate it when people say somebody has a "speech impediment", even if he does, because it could hurt his feelings. So instead, I call it a "speech improvement", and I go up to the guy and say, "Hey, Bob, I like your speech improvement." I think this makes him feel better.
I think my new thing will be to try to be a real happy guy. I'll just walk around being real happy until some jerk says something stupid to me.
Instead of mousetraps, what about baby traps?  Not to harm the babies, but just to hold them down until they can be removed?
Sometimes I think I would like to be named The Prince of Weasels.  As the Prince of Weasels, I could sneak up behind  people and bite them.  Then they would turn around and say, "what the...oh, it's just you the Prince of Weasels."
If you ever drop your keys into a river of molten lava, forget em', cause, man, they're gone.
If you lived in the Dark Ages, and you were a catapult operator, I bet the most common question people would ask is, "Can't you make it shoot any farther?"  No. I'm sorry. That's as far as it shoots.
Is there anything more beautiful than a beautiful, beautiful flamingo, flying across in front of a beautiful sunset? And he's carrying a beautiful rose in his beak, and also he's carrying a very beautiful painting with his feet. And also, you're drunk.
I think a pillow should be the peace symbol, not the dove. The pillow has more feathers than the dove, and it doesn't have a beak to peck you with.
To me, it's a good idea to always carry two sacks of something when you walk around. That way, if anybody says, "Hey, can you give me a hand?" you can say, "Sorry, got these sacks."
If they ever come up with a swashbuckling school, I think one of the courses should be laughing, then jumping off something.
When you're riding in a time machine way far into the future, don't stick your elbow out the window, or it'll turn into a fossil.
It takes a big man to cry, but it takes a bigger man to laugh at that man.
One thing kids like is to be tricked. For instance, I was going to take my little nephew to Disneyland, but instead I drove him to an old burned-out warehouse. "Oh, no," I said. "Disneyland burned down." He cried and cried, but I think that deep down, he thought it was a pretty good joke. I started to drive over to the real Disneyland, but it was getting pretty late.
A good way to threaten somebody is to light a stick of dynamite. Then you call the guy and hold the burning fuse up to the phone. "Hear that?" you say. "That's dynamite, baby."
Why do people in ship mutinies always ask for "better treatment"? I'd ask for a pinball machine, because with all that rocking back and forth you'd probably be able to get a lot of free games.
I'd like to be buried Indian-style, where they put you up on a high rack, above the ground. That way, you could get hit by meteorites and not even feel it.
If I lived back in the Wild West days, instead of carrying a six-gun in my holster, I'd carry a soldering iron. That way, if some smart-aleck cowboy said something like "Hey, look. He's carrying a soldering iron!" and started laughing, and everybody else started laughing, I could just say, "That's right, it's a soldering iron. The soldering iron of justice." Then everybody would get real quiet and ashamed, because they had made fun of the soldering iron of justice, and I could probably hit them up for a free drink.
I bet when the Neanderthal kids would make a snowman, someone would always end up saying, "Don't forget the thick, heavy brows." Then they would all get embarrassed because they remembered they had the big hunky brows too, and they'd get mad and eat the snowman.
There should be a detective show called 'Johnny Monkey'. That way every week a criminal could say, "I ain't gonna get caught by no monkey," but then he would, and I don't think I'd ever get tired of that.
Fear can sometimes be a useful emotion. For instance, let's say you're an astronaught on the moon and you fear that your partner has been turned into Dracula. The next time he goes out for the moon pieces, wham! You just slam the door behind him and blast off. He might call you on the radio and say he's not Dracula, but you just say, "Think again, bat man."
Too bad you can't buy a voodoo globe so that you could make the earth spin real fast and freak everybody out.
The people in the village were real poor, so none of the children had any toys. But this one little boy had gotten an old enema bag and filled it with rocks, and he would go around and whap the other children across the face with it. Man, I think my heart almost broke. Later the boy came up and offered to give me the toy. This was too much! I reached out my hand, but then he ran away. I chased him down and took the enema bag. He cried a little, but that's the way of these people.
I wish I had a Kryptonite cross, because then you could keep both Dracula AND Superman away.
I don't think I'm alone when I say I'd like to see more and more planets fall under the ruthless domination of our solar system.
Dad always thought laughter was the best medicine, which I guess is why several of us died of tuberculosis.
Maybe in order to understand mankind, we have to look at the word itself: "Mankind". Basically, it's made up of two separate words - "mank" and "ind". What do these words mean? It's a mystery, and that's why so is mankind.
I hope if dogs ever take over the world, and they chose a king, they don't just go by size, because I bet there are some Chihuahuas with some good ideas.
I guess we were all guilty, in a way. We all shot him, we all skinned him, and we all got a complimentary bumper sticker that said, "I helped skin Bob."
I bet the main reason the police keep people away from a plane crash is they don't want anybody walking in and lying down in the crash stuff, then, when somebody comes up, act like they just woke up and go, "What was THAT?!"
One thing vampire children are taught is, never run with a wooden stake.
The face of a child can say it all, especially the mouth part of the face.
Ambition is like a frog sitting on a Venus Flytrap. The flytrap can bite and bite, but it won't bother the frog because it only has little tiny plant teeth. But some other stuff could happen and it could be like ambition.
I'd rather be rich than stupid.
If you were a poor Indian with no weapons, and a bunch of conquistadors came up to you and asked where the gold was, I don't think it would be a good idea to say, "I swallowed it. So sue me."
If you define cowardice as running away at the first sign of danger, screaming and tripping and begging for mercy, then yes, Mr. Brave man, I guess I'm a coward.
I bet one legend that keeps recurring throughout history, in every culture, is the story of Popeye.
When you go in for a job interview, I think a good thing to ask is if they ever press charges.
To me, boxing is like a ballet, except there's no music, no choreography, and the dancers hit each other.
What is it that makes a complete stranger dive into an icy river to save a solid gold baby? Maybe we'll never know.
We tend to scoff at the beliefs of the ancients. But we can't scoff at them personally, to their faces, and this is what annoys me.
If you want to be the most popular person in your class, whenever the professor pauses in his lecture, just let out a big snort and say "How do you figger that!" real loud.  Then lean back and sort of smirk.
Probably the earliest flyswatters were nothing more than some sort of striking surface attached to the end of a long stick.
I think someone should have had the decency to tell me the luncheon was free. To make someone run out with potato salad in his hand, pretending he's throwing up, is not what I call hospitality.
To me, clowns aren't funny. In fact, they're kind of scary. I've wondered where this started and I think it goes back to the time I went to the circus, and a clown killed my dad.
As I bit into the nectarine, it had a crisp juiciness about it that was very pleasurable - until I realized it wasn't a nectarine at all, but A HUMAN HEAD!!
Most people don't realize that large pieces of coral, which have been painted brown and attached to the skull by common wood screws, can make a child look like a deer.
If trees could scream, would we be so cavalier about cutting them down? We might, if they screamed all the time, for no good reason.
Better not take a dog on the space shuttle, because if he sticks his head out when you're coming home his face might burn up.
You know what would make a good story? Something about a clown who makes people happy, but inside he's real sad. Also, he has severe diarrhea.
Sometimes when I feel like killing someone, I do a little trick to calm myself down. I'll go over to the person's house and ring the doorbell. When the person comes to the door, I'm gone, but you know what I've left on the porch? A jack-o-lantern with a knife stuck in the side of its head with a note that says "You." After that I usually feel a lot better, and no harm done.
If you're a horse, and someone gets on you, and falls off, and then gets right back on you, I think you should buck him off right away.
Too bad Lassie didn't know how to ice skate, because then if she was in Holland on vacation in winter and someone said "Lassie, go skate for help," she could do it.
If you ever teach a yodeling class, probably the hardest thing is to keep the students from just trying to yodel right off. You see, we build to that.
If you ever fall off the Sears Tower, just go real limp, because maybe you'll look like a dummy and people will try to catch you because, hey, free dummy.
I'd like to see a nude opera, because when they hit those high notes, I bet you can really see it in those genitals.
Anytime I see something screech across a room and latch onto someone's neck, and the guy screams and tries to get it off, I have to laugh, because what is that thing.
He was a cowboy, mister, and he loved the land. He loved it so much he made a woman out of dirt and married her. But when he kissed her, she disintegrated. Later, at the funeral, when the preacher said, "Dust to dust," some people laughed, and the cowboy shot them. At his hanging, he told the others, "I'll be waiting for you in heaven--with a gun."
The memories of my family outings are still a source of strength to me. I remember we'd all pile into the car - I forget what kind it was - and drive and drive. I'm not sure where we'd go, but I think there were some trees there. The smell of something was strong in the air as we played whatever sport we played. I remember a bigger, older guy we called "Dad." We'd eat some stuff, or not, and then I think we went home. I guess some things never leave you.
If a kid asks where rain comes from, I think a cute thing to tell him is "God is crying." And if he asks why God is crying, another cute thing to tell him is "Probably because of something you did."
Contrary to what most people say, the most dangerous animal in the world is not the lion or the tiger or even the elephant. It's a shark riding on an elephant's back, just trampling and eating everything they see.
As we were driving, we saw a sign that said "Watch for Rocks." Marta said it should read "Watch for Pretty Rocks." I told her she should write in her suggestion to the highway department, but she started saying it was a joke - just to get out of writing a simple letter! And I thought I was lazy!
If you saw two guys named Hambone and Flippy, which one would you think liked dolphins the most? I'd say Flippy, wouldn't you? You'd be wrong, though. It's Hambone.
If you're ever shipwrecked on a tropical island and you don't know how to speak the natives' language, just say "Poppy-oomy."  I bet it means something.
Laurie got offended that I used the word "puke." But to me, that's what her dinner tasted like.
We used to laugh at Grandpa when he'd head off and go fishing. But we wouldn't be laughing that evening when he'd come back with some whore he picked up in town.
I wish a robot would get elected president. That way, when he came to town, we could all take a shot at him and not feel too bad.
As the evening sky faded from a salmon color to a sort of flint gray, I thought back to the salmon I caught that morning, and how gray he was, and how I named him Flint.
If you're a young Mafia gangster out on your first date, I bet it's real embarrassing if someone tries to kill you.
Whenever I see an old lady slip and fall on a wet sidewalk, my first instinct is to laugh. But then I think, what is I was an ant, and she fell on me. Then it wouldn't seem quite so funny.
If you go parachuting, and your parachute doesn't open, and you friends are all watching you fall, I think a funny gag would be to pretend you were swimming.
When I was a kid my favorite relative was Uncle Caveman. After school we'd all go play in his cave, and every once in a while he would eat one of us. It wasn't until later that I found out that Uncle Caveman was a bear.
Children need encouragement. If a kid gets an answer right, tell him it was a lucky guess. That way he develops a good, lucky feeling.
The crows seemed to be calling his name, thought Caw.
I have to laugh when I think of the first cigar, because it was probably just a bunch of rolled-up tobacco leaves.
When you die, if you get a choice between going to regular heaven or pie heaven, choose pie heaven. It might be a trick, but if it's not, mmmmmmm, boy.
Whether they find a life there or not, I think Jupiter should be called an enemy planet.
Instead of trying to build newer and bigger weapons of destruction, we should be thinking about getting more use out of the ones we already have.
I think a good gift for the President would be a chocolate revolver. and since he is so busy, you'd probably have to run up to him real quick and give it to him.
Just because swans mate for life, I don't think it's that big a deal. First of all, if you're a swan, you're probably not going to find a swan that looks much better than the one you've got, so why not mate for life?
If you're robbing a bank and you're pants fall down, I think it's okay to laugh and to let the hostages laugh too, because, come on, life is funny.
If you ever catch on fire, try to avoid looking in a mirror, because I bet that will really throw you into a panic.
Sometimes I think I'd be better off dead. No, wait, not me, you.
I can't stand cheap people. It makes me real mad when someone says something like, "Hey, when are you going to pay me that $100 you owe me?" or "Do you have that $50 you borrowed?" Man, quit being so cheap!
I think the mistake a lot of us make is thinking the state-appointed psychiatrist is our friend.