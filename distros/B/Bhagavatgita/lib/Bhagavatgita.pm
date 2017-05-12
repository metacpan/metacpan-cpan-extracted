package Bhagavatgita;

### "LET KNOWLEDGE COME FROM ALL DIRECTIONS" : RIGVEDA ###

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(gita gita_chapter gita_random gita_glossary);
our $VERSION = '2.05';

use strict;
use warnings;
use Carp;

my @ok;
my @glossary;
my @data;
my @got;
my @great;
my @good;
my %parm;

#for getting individual lines
sub gita {
&data;
my $this=[];
shift @_;
%parm = @_;
if( $parm{'-last'} and $parm{'-last'}=~/[a-zA-Z]/ and  $parm{'-last'} eq 'last'){$parm{'-last'}='700'}

#checking initial errors
if($parm{'-first'} and $parm{'-first'} > 700){
  carp "Error:maximum value allowed is 700" and exit;
}elsif($parm{'-last'} and $parm{'-last'} > 700){
  carp "Error:maximum value allowed is 700" and exit;
}elsif($parm{'-first'}==0){
  carp "Error:numbers should be greater than zero" and exit;
}

if( $parm{'-last'} ){
$parm{'-last'}=$parm{'-last'}-1;
$parm{'-first'}=$parm{'-first'}-1;
while ($parm{'-last'} >= $parm{'-first'}){
if("$data[$parm{'-first'}]" eq "$data[$parm{'-first'}-1]"){
  $parm{'-first'}=$parm{'-first'}+1;
}else{
  push (@got,"$data[$parm{'-first'}]\n");
  $parm{'-first'}=$parm{'-first'}+1;
}
}
}else{
push (@got,"$data[$parm{'-first'}-1]\n");
}

bless $this;
return @got;
}

#for getting content of a chapter
sub gita_chapter{
&data;
#checking for initial errors
if($_[0] and ($_[0] > 18)){
  carp "Error:chapter should be from 1 to 18" and exit;
}
if($_[0] and ($_[0] < 1)){
  carp "Error:chapter should be from 1 to 18" and exit;
}
my $chapt=[];
my $b;
my $e;
SWITCH:{
$_[0]==1 && do {push(@great,"Arjun-Vishad or The Book of the Distress of Arjuna\n\n");
$b=1;$e=46;
		     while($b<=$e){if("$data[$b]" eq "$data[$b-1]"){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==2 && do {push(@great,"Sankhya-Yog or The Book of Doctrines\n\n");
$b=47;$e=118;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==3 && do {push(@great,"Karma-Yog or The Book of Virtue in Work\n\n");
$b=119;$e=161;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==4 && do {push(@great,"Jnana Yog or The Book of the Religion of Knowledge\n\n");
$b=162;$e=203;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==5 && do {push(@great,"Karmasanyasayog or The Book of Religion by Renouncing Fruits of Works\n\n");
$b=204;$e=232;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==6 && do {push(@great,"Atmasanyamayog or The Book of Religion of Self-Restraint\n\n");
$b=233;$e=279;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==7 && do {push(@great,"Vijnanayog or The Book of Religion by Discernment\n\n");
$b=280;$e=309;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==8 && do {push(@great,"Aksharaparabrahmayog or The Book of Religion by Devotion to the One Supreme God\n\n");
$b=310;$e=337;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==9 && do {push(@great,"Rajavidyarajaguhyayog or The Book of Religion by the Kingly Knowledge and the Kingly Mystery\n\n");
$b=338;$e=371;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==10 && do {push(@great,"Vibhuti Yog or The Book of Religion by the Heavenly Perfections\n\n");
$b=372;$e=413;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==11 && do {push(@great,"Viswarupadarsanam or The Book of the Manifesting of the One and Manifold\n\n");
$b=414;$e=468;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==12 && do {push(@great,"Bhaktiyog or The Book of the Religion of Faith\n\n");
$b=469;$e=488;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==13 && do {push(@great,"Kshetrakshetrajnavibhagayog or The Book of Religion by Separation of Matter and Spirit\n\n");
$b=489;$e=523;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==14 && do {push(@great,"Gunatrayavibhagayog or The Book of Religion by Separation from the Qualities\n\n");
$b=524;$e=550;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==15 && do {push(@great,"Purushottamapraptiyog or The Book of Religion by Attaining the Supreme\n\n");
$b=551;$e=570;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==16 && do {push(@great,"Daivasarasaupadwibhagayog or The Book of the Separateness of the Divine and Undivine\n\n");
$b=571;$e=593;
		 while($b<=$e){if("$data[$b]" eq "$data[$b-1]"){$b=$b+1}else{push(@great,"$data[$b]\n");$b=$b+1}}
};
$_[0]==17 && do {push(@great,"Sraddhatrayavibhagayog or The Book of Religion by the Threefold Kinds of Faith\n\n");
$b=594;$e=622;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
$_[0]==18 && do {push(@great,"Mokshasanyasayog or The Book of Religion by Deliverance and Renunciation\n\n");
$b=606;$e=700;
		     while($b<=$e){if($data[$b] eq $data[$b-1]){$b=$b+1}else{push(@great,"$data[$b-1]\n");$b=$b+1}}
};
}
bless $chapt;
return @great;
}

#getting random consecutive verses
sub gita_random{
#checking for initial errors
  if($_[0] > 700 or $_[0] < 1){
carp "error:value should be from 1 to 700" and exit;
}

&data;
my $that=[];
my $lines=1;
my $range=700-$_[0];
my $number=int(rand($range));
  while($lines<=$_[0]){
    if($data[$number] eq $data[$number+1]){
    $number=$number+1;
}else{
push(@good,"$data[$number]\n");
    $number=$number+1;
    $lines=$lines+1;
}
  }
bless $that;
return @good;
}

#getting glossary
sub gita_glossary{
&glossary;
my $ok;
#adding new line
foreach $ok(@ok){
push(@glossary,"$ok\n");
}
my $them=[];
return @glossary;
bless $them;
}

#BHAGAVATGITA
sub data{
 @data=split / *\n */,
         qq/Dhṛtarāṣṭra said: O Sañjaya, after my sons and the sons of Pāṇḍu assembled in the place of pilgrimage at Kurukṣetra, desiring to fight, what did they do?
Sañjaya said: O King, after looking over the army arranged in military formation by the sons of Pāṇḍu, King Duryodhana went to his teacher and spoke the following words.
O my teacher, behold the great army of the sons of Pāṇḍu, so expertly arranged by your intelligent disciple the son of Drupada.
Here in this army are many heroic bowmen equal in fighting to Bhīma and Arjuna: great fighters like Yuyudhāna, Virāṭa and Drupada.
There are also great, heroic, powerful fighters like Dhṛṣṭaketu, Cekitāna, Kāśirāja, Purujit, Kuntibhoja and Śaibya.
There are the mighty Yudhāmanyu, the very powerful Uttamaujā, the son of Subhadrā and the sons of Draupadī. All these warriors are great chariot fighters.
But for your information, O best of the brāhmaṇas, let me tell you about the captains who are especially qualified to lead my military force.
There are personalities like you, Bhīṣma, Karṇa, Kṛpa, Aśvatthāmā, Vikarṇa and the son of Somadatta called Bhūriśravā, who are always victorious in battle.
There are many other heroes who are prepared to lay down their lives for my sake. All of them are well equipped with different kinds of weapons, and all are experienced in military science.
Our strength is immeasurable, and we are perfectly protected by Grandfather Bhīṣma, whereas the strength of the Pāṇḍavas, carefully protected by Bhīma, is limited.
All of you must now give full support to Grandfather Bhīṣma, as you stand at your respective strategic points of entrance into the phalanx of the army.
Then Bhīṣma, the great valiant grandsire of the Kuru dynasty, the grandfather of the fighters, blew his conchshell very loudly, making a sound like the roar of a lion, giving Duryodhana joy.
After that, the conchshells, drums, bugles, trumpets and horns were all suddenly sounded, and the combined sound was tumultuous.
On the other side, both Lord Kṛṣṇa and Arjuna, stationed on a great chariot drawn by white horses, sounded their transcendental conchshells.
Lord Kṛṣṇa blew His conchshell, called Pāñcajanya; Arjuna blew his, the Devadatta; and Bhīma, the voracious eater and performer of herculean tasks, blew his terrific conchshell, called Pauṇḍra.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
The blowing of these different conchshells became uproarious. Vibrating both in the sky and on the earth, it shattered the hearts of the sons of Dhṛtarāṣṭra.
At that time Arjuna, the son of Pāṇḍu, seated in the chariot bearing the flag marked with Hanumān, took up his bow and prepared to shoot his arrows. O King, after looking at the sons of Dhṛtarāṣṭra drawn in military array, Arjuna then spoke to Lord Kṛṣṇa these words.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Let me see those who have come here to fight, wishing to please the evil-minded son of Dhṛtarāṣṭra.
Sañjaya said: O descendant of Bharata, having thus been addressed by Arjuna, Lord Kṛṣṇa drew up the fine chariot in the midst of the armies of both parties.
In the presence of Bhīṣma, Droṇa and all the other chieftains of the world, the Lord said, Just behold, Pārtha, all the Kurus assembled here.
There Arjuna could see, within the midst of the armies of both parties, his fathers, grandfathers, teachers, maternal uncles, brothers, sons, grandsons, friends, and also his fathers-in-law and well-wishers.
When the son of Kuntī, Arjuna, saw all these different grades of friends and relatives, he became overwhelmed with compassion and spoke thus.
Arjuna said: My dear Kṛṣṇa, seeing my friends and relatives present before me in such a fighting spirit, I feel the limbs of my body quivering and my mouth drying up.
My whole body is trembling, my hair is standing on end, my bow Gāṇḍīva is slipping from my hand, and my skin is burning.
I am now unable to stand here any longer. I am forgetting myself, and my mind is reeling. I see only causes of misfortune, O Kṛṣṇa, killer of the Keśī demon.
I do not see how any good can come from killing my own kinsmen in this battle, nor can I, my dear Kṛṣṇa, desire any subsequent victory, kingdom, or happiness.
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
Sin will overcome us if we slay such aggressors. Therefore it is not proper for us to kill the sons of Dhṛtarāṣṭra and our friends. What should we gain, O Kṛṣṇa, husband of the goddess of fortune, and how could we be happy by killing our own kinsmen?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
With the destruction of dynasty, the eternal family tradition is vanquished, and thus the rest of the family becomes involved in irreligion.
When irreligion is prominent in the family, O Kṛṣṇa, the women of the family become polluted, and from the degradation of womanhood, O descendant of Vṛṣṇi, comes unwanted progeny.
An increase of unwanted population certainly causes hellish life both for the family and for those who destroy the family tradition. The ancestors of such corrupt families fall down, because the performances for offering them food and water are entirely stopped.
By the evil deeds of those who destroy the family tradition and thus give rise to unwanted children, all kinds of community projects and family welfare activities are devastated.
O Kṛṣṇa, maintainer of the people, I have heard by disciplic succession that those who destroy family traditions dwell always in hell.
Alas, how strange it is that we are preparing to commit greatly sinful acts. Driven by the desire to enjoy royal happiness, we are intent on killing our own kinsmen.
Better for me if the sons of Dhṛtarāṣṭra, weapons in hand, were to kill me unarmed and unresisting on the battlefield.
Sañjaya said: Arjuna, having thus spoken on the battlefield, cast aside his bow and arrows and sat down on the chariot, his mind overwhelmed with grief.
Sañjaya said: Seeing Arjuna full of compassion, his mind depressed, his eyes full of tears, Madhusūdana, Kṛṣṇa, spoke the following words.
The Supreme Personality of Godhead said: My dear Arjuna, how have these impurities come upon you? They are not at all befitting a man who knows the value of life. They lead not to higher planets but to infamy.
O son of Pṛthā, do not yield to this degrading impotence. It does not become you. Give up such petty weakness of heart and arise, O chastiser of the enemy.
Arjuna said: O killer of enemies, O killer of Madhu, how can I counterattack with arrows in battle men like Bhīṣma and Droṇa, who are worthy of my worship?
It would be better to live in this world by begging than to live at the cost of the lives of great souls who are my teachers. Even though desiring worldly gain, they are superiors. If they are killed, everything we enjoy will be tainted with blood.
Nor do we know which is better — conquering them or being conquered by them. If we killed the sons of Dhṛtarāṣṭra, we should not care to live. Yet they are now standing before us on the battlefield.
Now I am confused about my duty and have lost all composure because of miserly weakness. In this condition I am asking You to tell me for certain what is best for me. Now I am Your disciple, and a soul surrendered unto You. Please instruct me.
I can find no means to drive away this grief which is drying up my senses. I will not be able to dispel it even if I win a prosperous, unrivaled kingdom on earth with sovereignty like the demigods in heaven.
Sañjaya said: Having spoken thus, Arjuna, chastiser of enemies, told Kṛṣṇa, "Govinda, I shall not fight," and fell silent.
O descendant of Bharata, at that time Kṛṣṇa, smiling, in the midst of both the armies, spoke the following words to the grief-stricken Arjuna.
The Supreme Personality of Godhead said: While speaking learned words, you are mourning for what is not worthy of grief. Those who are wise lament neither for the living nor for the dead.
Never was there a time when I did not exist, nor you, nor all these kings; nor in the future shall any of us cease to be.
As the embodied soul continuously passes, in this body, from boyhood to youth to old age, the soul similarly passes into another body at death. A sober person is not bewildered by such a change.
O son of Kuntī, the nonpermanent appearance of happiness and distress, and their disappearance in due course, are like the appearance and disappearance of winter and summer seasons. They arise from sense perception, O scion of Bharata, and one must learn to tolerate them without being disturbed.
O best among men [Arjuna], the person who is not disturbed by happiness and distress and is steady in both is certainly eligible for liberation.
Those who are seers of the truth have concluded that of the nonexistent [the material body] there is no endurance and of the eternal [the soul] there is no change. This they have concluded by studying the nature of both.
That which pervades the entire body you should know to be indestructible. No one is able to destroy that imperishable soul.
The material body of the indestructible, immeasurable and eternal living entity is sure to come to an end; therefore, fight, O descendant of Bharata.
Neither he who thinks the living entity the slayer nor he who thinks it slain is in knowledge, for the self slays not nor is slain.
For the soul there is neither birth nor death at any time. He has not come into being, does not come into being, and will not come into being. He is unborn, eternal, ever-existing and primeval. He is not slain when the body is slain.
O Pārtha, how can a person who knows that the soul is indestructible, eternal, unborn and immutable kill anyone or cause anyone to kill?
As a person puts on new garments, giving up old ones, the soul similarly accepts new material bodies, giving up the old and useless ones.
The soul can never be cut to pieces by any weapon, nor burned by fire, nor moistened by water, nor withered by the wind.
This individual soul is unbreakable and insoluble, and can be neither burned nor dried. He is everlasting, present everywhere, unchangeable, immovable and eternally the same.
It is said that the soul is invisible, inconceivable and immutable. Knowing this, you should not grieve for the body.
If, however, you think that the soul [or the symptoms of life] is always born and dies forever, you still have no reason to lament, O mighty-armed.
One who has taken his birth is sure to die, and after death one is sure to take birth again. Therefore, in the unavoidable discharge of your duty, you should not lament.
All created beings are unmanifest in their beginning, manifest in their interim state, and unmanifest again when annihilated. So what need is there for lamentation?
Some look on the soul as amazing, some describe him as amazing, and some hear of him as amazing, while others, even after hearing about him, cannot understand him at all.
O descendant of Bharata, he who dwells in the body can never be slain. Therefore you need not grieve for any living being.
Considering your specific duty as a kṣatriya, you should know that there is no better engagement for you than fighting on religious principles; and so there is no need for hesitation.
O Pārtha, happy are the kṣatriyas to whom such fighting opportunities come unsought, opening for them the doors of the heavenly planets.
If, however, you do not perform your religious duty of fighting, then you will certainly incur sins for neglecting your duties and thus lose your reputation as a fighter.
People will always speak of your infamy, and for a respectable person, dishonor is worse than death.
The great generals who have highly esteemed your name and fame will think that you have left the battlefield out of fear only, and thus they will consider you insignificant.
Your enemies will describe you in many unkind words and scorn your ability. What could be more painful for you?
O son of Kuntī, either you will be killed on the battlefield and attain the heavenly planets, or you will conquer and enjoy the earthly kingdom. Therefore, get up with determination and fight.
Do thou fight for the sake of fighting, without considering happiness or distress, loss or gain, victory or defeat — and by so doing you shall never incur sin.
Thus far I have described this knowledge to you through analytical study. Now listen as I explain it in terms of working without fruitive results. O son of Pṛthā, when you act in such knowledge you can free yourself from the bondage of works.
In this endeavor there is no loss or diminution, and a little advancement on this path can protect one from the most dangerous type of fear.
Those who are on this path are resolute in purpose, and their aim is one. O beloved child of the Kurus, the intelligence of those who are irresolute is many-branched.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
In the minds of those who are too attached to sense enjoyment and material opulence, and who are bewildered by such things, the resolute determination for devotional service to the Supreme Lord does not take place.
The Vedas deal mainly with the subject of the three modes of material nature. O Arjuna, become transcendental to these three modes. Be free from all dualities and from all anxieties for gain and safety, and be established in the self.
All purposes served by a small well can at once be served by a great reservoir of water. Similarly, all the purposes of the Vedas can be served to one who knows the purpose behind them.
You have a right to perform your prescribed duty, but you are not entitled to the fruits of action. Never consider yourself the cause of the results of your activities, and never be attached to not doing your duty.
Perform your duty equipoised, O Arjuna, abandoning all attachment to success or failure. Such equanimity is called yoga.
O Dhanañjaya, keep all abominable activities far distant by devotional service, and in that consciousness surrender unto the Lord. Those who want to enjoy the fruits of their work are misers.
A man engaged in devotional service rids himself of both good and bad actions even in this life. Therefore strive for yoga, which is the art of all work.
By thus engaging in devotional service to the Lord, great sages or devotees free themselves from the results of work in the material world. In this way they become free from the cycle of birth and death and attain the state beyond all miseries [by going back to Godhead].
When your intelligence has passed out of the dense forest of delusion, you shall become indifferent to all that has been heard and all that is to be heard.
When your mind is no longer disturbed by the flowery language of the Vedas, and when it remains fixed in the trance of self-realization, then you will have attained the divine consciousness.
Arjuna said: O Kṛṣṇa, what are the symptoms of one whose consciousness is thus merged in transcendence? How does he speak, and what is his language? How does he sit, and how does he walk?
The Supreme Personality of Godhead said: O Pārtha, when a man gives up all varieties of desire for sense gratification, which arise from mental concoction, and when his mind, thus purified, finds satisfaction in the self alone, then he is said to be in pure transcendental consciousness.
One who is not disturbed in mind even amidst the threefold miseries or elated when there is happiness, and who is free from attachment, fear and anger, is called a sage of steady mind.
In the material world, one who is unaffected by whatever good or evil he may obtain, neither praising it nor despising it, is firmly fixed in perfect knowledge.
One who is able to withdraw his senses from sense objects, as the tortoise draws its limbs within the shell, is firmly fixed in perfect consciousness.
The embodied soul may be restricted from sense enjoyment, though the taste for sense objects remains. But, ceasing such engagements by experiencing a higher taste, he is fixed in consciousness.
The senses are so strong and impetuous, O Arjuna, that they forcibly carry away the mind even of a man of discrimination who is endeavoring to control them.
One who restrains his senses, keeping them under full control, and fixes his consciousness upon Me, is known as a man of steady intelligence.
While contemplating the objects of the senses, a person develops attachment for them, and from such attachment lust develops, and from lust anger arises.
From anger, complete delusion arises, and from delusion bewilderment of memory. When memory is bewildered, intelligence is lost, and when intelligence is lost one falls down again into the material pool.
But a person free from all attachment and aversion and able to control his senses through regulative principles of freedom can obtain the complete mercy of the Lord.
For one thus satisfied [in Kṛṣṇa consciousness], the threefold miseries of material existence exist no longer; in such satisfied consciousness, one's intelligence is soon well established.
One who is not connected with the Supreme [in Kṛṣṇa consciousness] can have neither transcendental intelligence nor a steady mind, without which there is no possibility of peace. And how can there be any happiness without peace?
As a strong wind sweeps away a boat on the water, even one of the roaming senses on which the mind focuses can carry away a man's intelligence.
Therefore, O mighty-armed, one whose senses are restrained from their objects is certainly of steady intelligence.
What is night for all beings is the time of awakening for the self-controlled; and the time of awakening for all beings is night for the introspective sage.
A person who is not disturbed by the incessant flow of desires — that enter like rivers into the ocean, which is ever being filled but is always still — can alone achieve peace, and not the man who strives to satisfy such desires.
A person who has given up all desires for sense gratification, who lives free from desires, who has given up all sense of proprietorship and is devoid of false ego — he alone can attain real peace.
That is the way of the spiritual and godly life, after attaining which a man is not bewildered. If one is thus situated even at the hour of death, one can enter into the kingdom of God.
Arjuna said: O Janārdana, O Keśava, why do You want to engage me in this ghastly warfare, if You think that intelligence is better than fruitive work?
My intelligence is bewildered by Your equivocal instructions. Therefore, please tell me decisively which will be most beneficial for me.
The Supreme Personality of Godhead said: O sinless Arjuna, I have already explained that there are two classes of men who try to realize the self. Some are inclined to understand it by empirical, philosophical speculation, and others by devotional service.
Not by merely abstaining from work can one achieve freedom from reaction, nor by renunciation alone can one attain perfection.
Everyone is forced to act helplessly according to the qualities he has acquired from the modes of material nature; therefore no one can refrain from doing something, not even for a moment.
One who restrains the senses of action but whose mind dwells on sense objects certainly deludes himself and is called a pretender.
On the other hand, if a sincere person tries to control the active senses by the mind and begins karma-yoga [in Kṛṣṇa consciousness] without attachment, he is by far superior.
Perform your prescribed duty, for doing so is better than not working. One cannot even maintain one's physical body without work.
Work done as a sacrifice for Viṣṇu has to be performed, otherwise work causes bondage in this material world. Therefore, O son of Kuntī, perform your prescribed duties for His satisfaction, and in that way you will always remain free from bondage.
In the beginning of creation, the Lord of all creatures sent forth generations of men and demigods, along with sacrifices for Viṣṇu, and blessed them by saying, "Be thou happy by this yajña [sacrifice] because its performance will bestow upon you everything desirable for living happily and achieving liberation."
The demigods, being pleased by sacrifices, will also please you, and thus, by cooperation between men and demigods, prosperity will reign for all.
In charge of the various necessities of life, the demigods, being satisfied by the performance of yajña [sacrifice], will supply all necessities to you. But he who enjoys such gifts without offering them to the demigods in return is certainly a thief.
The devotees of the Lord are released from all kinds of sins because they eat food which is offered first for sacrifice. Others, who prepare food for personal sense enjoyment, verily eat only sin.
All living bodies subsist on food grains, which are produced from rains. Rains are produced by performance of yajña [sacrifice], and yajña is born of prescribed duties.
Regulated activities are prescribed in the Vedas, and the Vedas are directly manifested from the Supreme Personality of Godhead. Consequently the all-pervading Transcendence is eternally situated in acts of sacrifice.
My dear Arjuna, one who does not follow in human life the cycle of sacrifice thus established by the Vedas certainly leads a life full of sin. Living only for the satisfaction of the senses, such a person lives in vain.
But for one who takes pleasure in the self, whose human life is one of self-realization, and who is satisfied in the self only, fully satiated — for him there is no duty.
A self-realized man has no purpose to fulfill in the discharge of his prescribed duties, nor has he any reason not to perform such work. Nor has he any need to depend on any other living being.
Therefore, without being attached to the fruits of activities, one should act as a matter of duty, for by working without attachment one attains the Supreme.
Kings such as Janaka attained perfection solely by performance of prescribed duties. Therefore, just for the sake of educating the people in general, you should perform your work.
Whatever action a great man performs, common men follow. And whatever standards he sets by exemplary acts, all the world pursues.
O son of Pṛthā, there is no work prescribed for Me within all the three planetary systems. Nor am I in want of anything, nor have I a need to obtain anything — and yet I am engaged in prescribed duties.
For if I ever failed to engage in carefully performing prescribed duties, O Pārtha, certainly all men would follow My path.
If I did not perform prescribed duties, all these worlds would be put to ruination. I would be the cause of creating unwanted population, and I would thereby destroy the peace of all living beings.
As the ignorant perform their duties with attachment to results, the learned may similarly act, but without attachment, for the sake of leading people on the right path.
So as not to disrupt the minds of ignorant men attached to the fruitive results of prescribed duties, a learned person should not induce them to stop work. Rather, by working in the spirit of devotion, he should engage them in all sorts of activities [for the gradual development of Kṛṣṇa consciousness].
The spirit soul bewildered by the influence of false ego thinks himself the doer of activities that are in actuality carried out by the three modes of material nature.
One who is in knowledge of the Absolute Truth, O mighty-armed, does not engage himself in the senses and sense gratification, knowing well the differences between work in devotion and work for fruitive results.
Bewildered by the modes of material nature, the ignorant fully engage themselves in material activities and become attached. But the wise should not unsettle them, although these duties are inferior due to the performers' lack of knowledge.
Therefore, O Arjuna, surrendering all your works unto Me, with full knowledge of Me, without desires for profit, with no claims to proprietorship, and free from lethargy, fight.
Those persons who execute their duties according to My injunctions and who follow this teaching faithfully, without envy, become free from the bondage of fruitive actions.
But those who, out of envy, disregard these teachings and do not follow them are to be considered bereft of all knowledge, befooled, and ruined in their endeavors for perfection.
Even a man of knowledge acts according to his own nature, for everyone follows the nature he has acquired from the three modes. What can repression accomplish?
There are principles to regulate attachment and aversion pertaining to the senses and their objects. One should not come under the control of such attachment and aversion, because they are stumbling blocks on the path of self-realization.
It is far better to discharge one's prescribed duties, even though faultily, than another's duties perfectly. Destruction in the course of performing one's own duty is better than engaging in another's duties, for to follow another's path is dangerous.
Arjuna said: O descendant of Vṛṣṇi, by what is one impelled to sinful acts, even unwillingly, as if engaged by force?
The Supreme Personality of Godhead said: It is lust only, Arjuna, which is born of contact with the material mode of passion and later transformed into wrath, and which is the all-devouring sinful enemy of this world.
As fire is covered by smoke, as a mirror is covered by dust, or as the embryo is covered by the womb, the living entity is similarly covered by different degrees of this lust.
Thus the wise living entity's pure consciousness becomes covered by his eternal enemy in the form of lust, which is never satisfied and which burns like fire.
The senses, the mind and the intelligence are the sitting places of this lust. Through them lust covers the real knowledge of the living entity and bewilders him.
Therefore, O Arjuna, best of the Bhāratas, in the very beginning curb this great symbol of sin [lust] by regulating the senses, and slay this destroyer of knowledge and self-realization.
The working senses are superior to dull matter; mind is higher than the senses; intelligence is still higher than the mind; and he [the soul] is even higher than the intelligence.
Thus knowing oneself to be transcendental to the material senses, mind and intelligence, O mighty-armed Arjuna, one should steady the mind by deliberate spiritual intelligence [Kṛṣṇa consciousness] and thus — by spiritual strength — conquer this insatiable enemy known as lust.
The Personality of Godhead, Lord Śrī Kṛṣṇa, said: I instructed this imperishable science of yoga to the sun-god, Vivasvān, and Vivasvān instructed it to Manu, the father of mankind, and Manu in turn instructed it to Ikṣvāku.
This supreme science was thus received through the chain of disciplic succession, and the saintly kings understood it in that way. But in course of time the succession was broken, and therefore the science as it is appears to be lost.
That very ancient science of the relationship with the Supreme is today told by Me to you because you are My devotee as well as My friend and can therefore understand the transcendental mystery of this science.
Arjuna said: The sun-god Vivasvān is senior by birth to You. How am I to understand that in the beginning You instructed this science to him?
The Personality of Godhead said: Many, many births both you and I have passed. I can remember all of them, but you cannot, O subduer of the enemy!
Although I am unborn and My transcendental body never deteriorates, and although I am the Lord of all living entities, I still appear in every millennium in My original transcendental form.
Whenever and wherever there is a decline in religious practice, O descendant of Bharata, and a predominant rise of irreligion — at that time I descend Myself.
To deliver the pious and to annihilate the miscreants, as well as to reestablish the principles of religion, I Myself appear, millennium after millennium.
One who knows the transcendental nature of My appearance and activities does not, upon leaving the body, take his birth again in this material world, but attains My eternal abode, O Arjuna.
Being freed from attachment, fear and anger, being fully absorbed in Me and taking refuge in Me, many, many persons in the past became purified by knowledge of Me — and thus they all attained transcendental love for Me.
As all surrender unto Me, I reward them accordingly. Everyone follows My path in all respects, O son of Pṛthā.
Men in this world desire success in fruitive activities, and therefore they worship the demigods. Quickly, of course, men get results from fruitive work in this world.
According to the three modes of material nature and the work associated with them, the four divisions of human society are created by Me. And although I am the creator of this system, you should know that I am yet the nondoer, being unchangeable.
There is no work that affects Me; nor do I aspire for the fruits of action. One who understands this truth about Me also does not become entangled in the fruitive reactions of work.
All the liberated souls in ancient times acted with this understanding of My transcendental nature. Therefore you should perform your duty, following in their footsteps.
Even the intelligent are bewildered in determining what is action and what is inaction. Now I shall explain to you what action is, knowing which you shall be liberated from all misfortune.
The intricacies of action are very hard to understand. Therefore one should know properly what action is, what forbidden action is, and what inaction is.
One who sees inaction in action, and action in inaction, is intelligent among men, and he is in the transcendental position, although engaged in all sorts of activities.
One is understood to be in full knowledge whose every endeavor is devoid of desire for sense gratification. He is said by sages to be a worker for whom the reactions of work have been burned up by the fire of perfect knowledge.
Abandoning all attachment to the results of his activities, ever satisfied and independent, he performs no fruitive action, although engaged in all kinds of undertakings.
Such a man of understanding acts with mind and intelligence perfectly controlled, gives up all sense of proprietorship over his possessions, and acts only for the bare necessities of life. Thus working, he is not affected by sinful reactions.
He who is satisfied with gain which comes of its own accord, who is free from duality and does not envy, who is steady in both success and failure, is never entangled, although performing actions.
The work of a man who is unattached to the modes of material nature and who is fully situated in transcendental knowledge merges entirely into transcendence.
A person who is fully absorbed in Kṛṣṇa consciousness is sure to attain the spiritual kingdom because of his full contribution to spiritual activities, in which the consummation is absolute and that which is offered is of the same spiritual nature.
Some yogīs perfectly worship the demigods by offering different sacrifices to them, and some of them offer sacrifices in the fire of the Supreme Brahman.
Some [the unadulterated brahmacārīs] sacrifice the hearing process and the senses in the fire of mental control, and others [the regulated householders] sacrifice the objects of the senses in the fire of the senses.
Others, who are interested in achieving self-realization through control of the mind and senses, offer the functions of all the senses, and of the life breath, as oblations into the fire of the controlled mind.
Having accepted strict vows, some become enlightened by sacrificing their possessions, and others by performing severe austerities, by practicing the yoga of eightfold mysticism, or by studying the Vedas to advance in transcendental knowledge.
Still others, who are inclined to the process of breath restraint to remain in trance, practice by offering the movement of the outgoing breath into the incoming, and the incoming breath into the outgoing, and thus at last remain in trance, stopping all breathing. Others, curtailing the eating process, offer the outgoing breath into itself as a sacrifice.
All these performers who know the meaning of sacrifice become cleansed of sinful reactions, and, having tasted the nectar of the results of sacrifices, they advance toward the supreme eternal atmosphere.
O best of the Kuru dynasty, without sacrifice one can never live happily on this planet or in this life: what then of the next?
All these different types of sacrifice are approved by the Vedas, and all of them are born of different types of work. Knowing them as such, you will become liberated.
O chastiser of the enemy, the sacrifice performed in knowledge is better than the mere sacrifice of material possessions. After all, O son of Pṛthā, all sacrifices of work culminate in transcendental knowledge.
Just try to learn the truth by approaching a spiritual master. Inquire from him submissively and render service unto him. The self-realized souls can impart knowledge unto you because they have seen the truth.
Having obtained real knowledge from a self-realized soul, you will never fall again into such illusion, for by this knowledge you will see that all living beings are but part of the Supreme, or, in other words, that they are Mine.
Even if you are considered to be the most sinful of all sinners, when you are situated in the boat of transcendental knowledge you will be able to cross over the ocean of miseries.
As a blazing fire turns firewood to ashes, O Arjuna, so does the fire of knowledge burn to ashes all reactions to material activities.
In this world, there is nothing so sublime and pure as transcendental knowledge. Such knowledge is the mature fruit of all mysticism. And one who has become accomplished in the practice of devotional service enjoys this knowledge within himself in due course of time.
A faithful man who is dedicated to transcendental knowledge and who subdues his senses is eligible to achieve such knowledge, and having achieved it he quickly attains the supreme spiritual peace.
But ignorant and faithless persons who doubt the revealed scriptures do not attain God consciousness; they fall down. For the doubting soul there is happiness neither in this world nor in the next.
One who acts in devotional service, renouncing the fruits of his actions, and whose doubts have been destroyed by transcendental knowledge, is situated factually in the self. Thus he is not bound by the reactions of work, O conqueror of riches.
Therefore the doubts which have arisen in your heart out of ignorance should be slashed by the weapon of knowledge. Armed with yoga, O Bhārata, stand and fight.
Arjuna said: O Kṛṣṇa, first of all You ask me to renounce work, and then again You recommend work with devotion. Now will You kindly tell me definitely which of the two is more beneficial?
The Personality of Godhead replied: The renunciation of work and work in devotion are both good for liberation. But, of the two, work in devotional service is better than renunciation of work.
One who neither hates nor desires the fruits of his activities is known to be always renounced. Such a person, free from all dualities, easily overcomes material bondage and is completely liberated, O mighty-armed Arjuna.
Only the ignorant speak of devotional service [karma-yoga] as being different from the analytical study of the material world [Sāńkhya]. Those who are actually learned say that he who applies himself well to one of these paths achieves the results of both.
One who knows that the position reached by means of analytical study can also be attained by devotional service, and who therefore sees analytical study and devotional service to be on the same level, sees things as they are.
Merely renouncing all activities yet not engaging in the devotional service of the Lord cannot make one happy. But a thoughtful person engaged in devotional service can achieve the Supreme without delay.
One who works in devotion, who is a pure soul, and who controls his mind and senses is dear to everyone, and everyone is dear to him. Though always working, such a man is never entangled.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
One who performs his duty without attachment, surrendering the results unto the Supreme Lord, is unaffected by sinful action, as the lotus leaf is untouched by water.
The yogīs, abandoning attachment, act with body, mind, intelligence and even with the senses, only for the purpose of purification.
The steadily devoted soul attains unadulterated peace because he offers the result of all activities to Me; whereas a person who is not in union with the Divine, who is greedy for the fruits of his labor, becomes entangled.
When the embodied living being controls his nature and mentally renounces all actions, he resides happily in the city of nine gates [the material body], neither working nor causing work to be done.
The embodied spirit, master of the city of his body, does not create activities, nor does he induce people to act, nor does he create the fruits of action. All this is enacted by the modes of material nature.
Nor does the Supreme Lord assume anyone's sinful or pious activities. Embodied beings, however, are bewildered because of the ignorance which covers their real knowledge.
When, however, one is enlightened with the knowledge by which nescience is destroyed, then his knowledge reveals everything, as the sun lights up everything in the daytime.
When one's intelligence, mind, faith and refuge are all fixed in the Supreme, then one becomes fully cleansed of misgivings through complete knowledge and thus proceeds straight on the path of liberation.
The humble sages, by virtue of true knowledge, see with equal vision a learned and gentle brāhmaṇa, a cow, an elephant, a dog and a dog-eater [outcaste].
Those whose minds are established in sameness and equanimity have already conquered the conditions of birth and death. They are flawless like Brahman, and thus they are already situated in Brahman.
A person who neither rejoices upon achieving something pleasant nor laments upon obtaining something unpleasant, who is self-intelligent, who is unbewildered, and who knows the science of God, is already situated in transcendence.
Such a liberated person is not attracted to material sense pleasure but is always in trance, enjoying the pleasure within. In this way the self-realized person enjoys unlimited happiness, for he concentrates on the Supreme.
An intelligent person does not take part in the sources of misery, which are due to contact with the material senses. O son of Kuntī, such pleasures have a beginning and an end, and so the wise man does not delight in them.
Before giving up this present body, if one is able to tolerate the urges of the material senses and check the force of desire and anger, he is well situated and is happy in this world.
One whose happiness is within, who is active and rejoices within, and whose aim is inward is actually the perfect mystic. He is liberated in the Supreme, and ultimately he attains the Supreme.
Those who are beyond the dualities that arise from doubts, whose minds are engaged within, who are always busy working for the welfare of all living beings, and who are free from all sins achieve liberation in the Supreme.
Those who are free from anger and all material desires, who are self-realized, self-disciplined and constantly endeavoring for perfection, are assured of liberation in the Supreme in the very near future.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
A person in full consciousness of Me, knowing Me to be the ultimate beneficiary of all sacrifices and austerities, the Supreme Lord of all planets and demigods, and the benefactor and well-wisher of all living entities, attains peace from the pangs of material miseries.
The Supreme Personality of Godhead said: One who is unattached to the fruits of his work and who works as he is obligated is in the renounced order of life, and he is the true mystic, not he who lights no fire and performs no duty.
What is called renunciation you should know to be the same as yoga, or linking oneself with the Supreme, O son of Pāṇḍu, for one can never become a yogī unless he renounces the desire for sense gratification.
For one who is a neophyte in the eightfold yoga system, work is said to be the means; and for one who is already elevated in yoga, cessation of all material activities is said to be the means.
A person is said to be elevated in yoga when, having renounced all material desires, he neither acts for sense gratification nor engages in fruitive activities.
One must deliver himself with the help of his mind, and not degrade himself. The mind is the friend of the conditioned soul, and his enemy as well.
For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his mind will remain the greatest enemy.
For one who has conquered the mind, the Supersoul is already reached, for he has attained tranquillity. To such a man happiness and distress, heat and cold, honor and dishonor are all the same.
A person is said to be established in self-realization and is called a yogī [or mystic] when he is fully satisfied by virtue of acquired knowledge and realization. Such a person is situated in transcendence and is self-controlled. He sees everything — whether it be pebbles, stones or gold — as the same.
A person is considered still further advanced when he regards honest well-wishers, affectionate benefactors, the neutral, mediators, the envious, friends and enemies, the pious and the sinners all with an equal mind.
A transcendentalist should always engage his body, mind and self in relationship with the Supreme; he should live alone in a secluded place and should always carefully control his mind. He should be free from desires and feelings of possessiveness.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
Thus practicing constant control of the body, mind and activities, the mystic transcendentalist, his mind regulated, attains to the kingdom of God [or the abode of Kṛṣṇa] by cessation of material existence.
There is no possibility of one's becoming a yogī, O Arjuna, if one eats too much or eats too little, sleeps too much or does not sleep enough.
He who is regulated in his habits of eating, sleeping, recreation and work can mitigate all material pains by practicing the yoga system.
When the yogī, by practice of yoga, disciplines his mental activities and becomes situated in transcendence — devoid of all material desires — he is said to be well established in yoga.
As a lamp in a windless place does not waver, so the transcendentalist, whose mind is controlled, remains always steady in his meditation on the transcendent self.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
One should engage oneself in the practice of yoga with determination and faith and not be deviated from the path. One should abandon, without exception, all material desires born of mental speculation and thus control all the senses on all sides by the mind.
Gradually, step by step, one should become situated in trance by means of intelligence sustained by full conviction, and thus the mind should be fixed on the self alone and should think of nothing else.
From wherever the mind wanders due to its flickering and unsteady nature, one must certainly withdraw it and bring it back under the control of the self.
The yogī whose mind is fixed on Me verily attains the highest perfection of transcendental happiness. He is beyond the mode of passion, he realizes his qualitative identity with the Supreme, and thus he is freed from all reactions to past deeds.
Thus the self-controlled yogī, constantly engaged in yoga practice, becomes free from all material contamination and achieves the highest stage of perfect happiness in transcendental loving service to the Lord.
A true yogī observes Me in all beings and also sees every being in Me. Indeed, the self-realized person sees Me, the same Supreme Lord, everywhere.
For one who sees Me everywhere and sees everything in Me, I am never lost, nor is he ever lost to Me.
Such a yogī, who engages in the worshipful service of the Supersoul, knowing that I and the Supersoul are one, remains always in Me in all circumstances.
He is a perfect yogī who, by comparison to his own self, sees the true equality of all beings, in both their happiness and their distress, O Arjuna!
Arjuna said: O Madhusūdana, the system of yoga which You have summarized appears impractical and unendurable to me, for the mind is restless and unsteady.
For the mind is restless, turbulent, obstinate and very strong, O Kṛṣṇa, and to subdue it, I think, is more difficult than controlling the wind.
Lord Śrī Kṛṣṇa said: O mighty-armed son of Kuntī, it is undoubtedly very difficult to curb the restless mind, but it is possible by suitable practice and by detachment.
For one whose mind is unbridled, self-realization is difficult work. But he whose mind is controlled and who strives by appropriate means is assured of success. That is My opinion.
Arjuna said: O Kṛṣṇa, what is the destination of the unsuccessful transcendentalist, who in the beginning takes to the process of self-realization with faith but who later desists due to worldly-mindedness and thus does not attain perfection in mysticism?
O mighty-armed Kṛṣṇa, does not such a man, who is bewildered from the path of transcendence, fall away from both spiritual and material success and perish like a riven cloud, with no position in any sphere?
This is my doubt, O Kṛṣṇa, and I ask You to dispel it completely. But for You, no one is to be found who can destroy this doubt.
The Supreme Personality of Godhead said: Son of Pṛthā, a transcendentalist engaged in auspicious activities does not meet with destruction either in this world or in the spiritual world; one who does good, My friend, is never overcome by evil.
The unsuccessful yogī, after many, many years of enjoyment on the planets of the pious living entities, is born into a family of righteous people, or into a family of rich aristocracy.
Or [if unsuccessful after long practice of yoga] he takes his birth in a family of transcendentalists who are surely great in wisdom. Certainly, such a birth is rare in this world.
On taking such a birth, he revives the divine consciousness of his previous life, and he again tries to make further progress in order to achieve complete success, O son of Kuru.
By virtue of the divine consciousness of his previous life, he automatically becomes attracted to the yogic principles — even without seeking them. Such an inquisitive transcendentalist stands always above the ritualistic principles of the scriptures.
And when the yogī engages himself with sincere endeavor in making further progress, being washed of all contaminations, then ultimately, achieving perfection after many, many births of practice, he attains the supreme goal.
A yogī is greater than the ascetic, greater than the empiricist and greater than the fruitive worker. Therefore, O Arjuna, in all circumstances, be a yogī.
And of all yogīs, the one with great faith who always abides in Me, thinks of Me within himself, and renders transcendental loving service to Me — he is the most intimately united with Me in yoga and is the highest of all. That is My opinion.
The Supreme Personality of Godhead said: Now hear, O son of Pṛthā, how by practicing yoga in full consciousness of Me, with mind attached to Me, you can know Me in full, free from doubt.
I shall now declare unto you in full this knowledge, both phenomenal and numinous. This being known, nothing further shall remain for you to know.
Out of many thousands among men, one may endeavor for perfection, and of those who have achieved perfection, hardly one knows Me in truth.
Earth, water, fire, air, ether, mind, intelligence and false ego — all together these eight constitute My separated material energies.
Besides these, O mighty-armed Arjuna, there is another, superior energy of Mine, which comprises the living entities who are exploiting the resources of this material, inferior nature.
All created beings have their source in these two natures. Of all that is material and all that is spiritual in this world, know for certain that I am both the origin and the dissolution.
O conqueror of wealth, there is no truth superior to Me. Everything rests upon Me, as pearls are strung on a thread.
O son of Kuntī, I am the taste of water, the light of the sun and the moon, the syllable oḿ in the Vedic mantras; I am the sound in ether and ability in man.
I am the original fragrance of the earth, and I am the heat in fire. I am the life of all that lives, and I am the penances of all ascetics.
O son of Pṛthā, know that I am the original seed of all existences, the intelligence of the intelligent, and the prowess of all powerful men.
I am the strength of the strong, devoid of passion and desire. I am sex life which is not contrary to religious principles, O lord of the Bhāratas [Arjuna].
Know that all states of being — be they of goodness, passion or ignorance — are manifested by My energy. I am, in one sense, everything, but I am independent. I am not under the modes of material nature, for they, on the contrary, are within Me.
Deluded by the three modes [goodness, passion and ignorance], the whole world does not know Me, who am above the modes and inexhaustible.
This divine energy of Mine, consisting of the three modes of material nature, is difficult to overcome. But those who have surrendered unto Me can easily cross beyond it.
Those miscreants who are grossly foolish, who are lowest among mankind, whose knowledge is stolen by illusion, and who partake of the atheistic nature of demons do not surrender unto Me.
O best among the Bhāratas, four kinds of pious men begin to render devotional service unto Me — the distressed, the desirer of wealth, the inquisitive, and he who is searching for knowledge of the Absolute.
Of these, the one who is in full knowledge and who is always engaged in pure devotional service is the best. For I am very dear to him, and he is dear to Me.
All these devotees are undoubtedly magnanimous souls, but he who is situated in knowledge of Me I consider to be just like My own self. Being engaged in My transcendental service, he is sure to attain Me, the highest and most perfect goal.
After many births and deaths, he who is actually in knowledge surrenders unto Me, knowing Me to be the cause of all causes and all that is. Such a great soul is very rare.
Those whose intelligence has been stolen by material desires surrender unto demigods and follow the particular rules and regulations of worship according to their own natures.
I am in everyone's heart as the Supersoul. As soon as one desires to worship some demigod, I make his faith steady so that he can devote himself to that particular deity.
Endowed with such a faith, he endeavors to worship a particular demigod and obtains his desires. But in actuality these benefits are bestowed by Me alone.
Men of small intelligence worship the demigods, and their fruits are limited and temporary. Those who worship the demigods go to the planets of the demigods, but My devotees ultimately reach My supreme planet.
Unintelligent men, who do not know Me perfectly, think that I, the Supreme Personality of Godhead, Kṛṣṇa, was impersonal before and have now assumed this personality. Due to their small knowledge, they do not know My higher nature, which is imperishable and supreme.
I am never manifest to the foolish and unintelligent. For them I am covered by My internal potency, and therefore they do not know that I am unborn and infallible.
O Arjuna, as the Supreme Personality of Godhead, I know everything that has happened in the past, all that is happening in the present, and all things that are yet to come. I also know all living entities; but Me no one knows.
O scion of Bharata, O conqueror of the foe, all living entities are born into delusion, bewildered by dualities arisen from desire and hate.
Persons who have acted piously in previous lives and in this life and whose sinful actions are completely eradicated are freed from the dualities of delusion, and they engage themselves in My service with determination.
Intelligent persons who are endeavoring for liberation from old age and death take refuge in Me in devotional service. They are actually Brahman because they entirely know everything about transcendental activities.
Those in full consciousness of Me, who know Me, the Supreme Lord, to be the governing principle of the material manifestation, of the demigods, and of all methods of sacrifice, can understand and know Me, the Supreme Personality of Godhead, even at the time of death.
Arjuna inquired: O my Lord, O Supreme Person, what is Brahman? What is the self? What are fruitive activities? What is this material manifestation? And what are the demigods? Please explain this to me.
Who is the Lord of sacrifice, and how does He live in the body, O Madhusūdana? And how can those engaged in devotional service know You at the time of death?
The Supreme Personality of Godhead said: The indestructible, transcendental living entity is called Brahman, and his eternal nature is called adhyātma, the self. Action pertaining to the development of the material bodies of the living entities is called karma, or fruitive activities.
O best of the embodied beings, the physical nature, which is constantly changing, is called adhibhūta [the material manifestation]. The universal form of the Lord, which includes all the demigods, like those of the sun and moon, is called adhidaiva. And I, the Supreme Lord, represented as the Supersoul in the heart of every embodied being, am called adhiyajña [the Lord of sacrifice].
And whoever, at the end of his life, quits his body, remembering Me alone, at once attains My nature. Of this there is no doubt.
Whatever state of being one remembers when he quits his body, O son of Kuntī, that state he will attain without fail.
Therefore, Arjuna, you should always think of Me in the form of Kṛṣṇa and at the same time carry out your prescribed duty of fighting. With your activities dedicated to Me and your mind and intelligence fixed on Me, you will attain Me without doubt.
He who meditates on Me as the Supreme Personality of Godhead, his mind constantly engaged in remembering Me, undeviated from the path, he, O Pārtha, is sure to reach Me.
One should meditate upon the Supreme Person as the one who knows everything, as He who is the oldest, who is the controller, who is smaller than the smallest, who is the maintainer of everything, who is beyond all material conception, who is inconceivable, and who is always a person. He is luminous like the sun, and He is transcendental, beyond this material nature.
One who, at the time of death, fixes his life air between the eyebrows and, by the strength of yoga, with an undeviating mind, engages himself in remembering the Supreme Lord in full devotion, will certainly attain to the Supreme Personality of Godhead.
Persons who are learned in the Vedas, who utter oḿkāra and who are great sages in the renounced order enter into Brahman. Desiring such perfection, one practices celibacy. I shall now briefly explain to you this process by which one may attain salvation.
The yogic situation is that of detachment from all sensual engagements. Closing all the doors of the senses and fixing the mind on the heart and the life air at the top of the head, one establishes himself in yoga.
After being situated in this yoga practice and vibrating the sacred syllable oḿ, the supreme combination of letters, if one thinks of the Supreme Personality of Godhead and quits his body, he will certainly reach the spiritual planets.
For one who always remembers Me without deviation, I am easy to obtain, O son of Pṛthā, because of his constant engagement in devotional service.
After attaining Me, the great souls, who are yogīs in devotion, never return to this temporary world, which is full of miseries, because they have attained the highest perfection.
From the highest planet in the material world down to the lowest, all are places of misery wherein repeated birth and death take place. But one who attains to My abode, O son of Kuntī, never takes birth again.
By human calculation, a thousand ages taken together form the duration of Brahmā's one day. And such also is the duration of his night.
At the beginning of Brahmā's day, all living entities become manifest from the unmanifest state, and thereafter, when the night falls, they are merged into the unmanifest again.
Again and again, when Brahmā's day arrives, all living entities come into being, and with the arrival of Brahmā's night they are helplessly annihilated.
Yet there is another unmanifest nature, which is eternal and is transcendental to this manifested and unmanifested matter. It is supreme and is never annihilated. When all in this world is annihilated, that part remains as it is.
That which the Vedāntists describe as unmanifest and infallible, that which is known as the supreme destination, that place from which, having attained it, one never returns — that is My supreme abode.
The Supreme Personality of Godhead, who is greater than all, is attainable by unalloyed devotion. Although He is present in His abode, He is all-pervading, and everything is situated within Him.
O best of the Bhāratas, I shall now explain to you the different times at which, passing away from this world, the yogī does or does not come back.
Those who know the Supreme Brahman attain that Supreme by passing away from the world during the influence of the fiery god, in the light, at an auspicious moment of the day, during the fortnight of the waxing moon, or during the six months when the sun travels in the north.
The mystic who passes away from this world during the smoke, the night, the fortnight of the waning moon, or the six months when the sun passes to the south reaches the moon planet but again comes back.
According to Vedic opinion, there are two ways of passing from this world — one in light and one in darkness. When one passes in light, he does not come back; but when one passes in darkness, he returns.
Although the devotees know these two paths, O Arjuna, they are never bewildered. Therefore be always fixed in devotion.
A person who accepts the path of devotional service is not bereft of the results derived from studying the Vedas, performing austere sacrifices, giving charity or pursuing philosophical and fruitive activities. Simply by performing devotional service, he attains all these, and at the end he reaches the supreme eternal abode.
The Supreme Personality of Godhead said: My dear Arjuna, because you are never envious of Me, I shall impart to you this most confidential knowledge and realization, knowing which you shall be relieved of the miseries of material existence.
This knowledge is the king of education, the most secret of all secrets. It is the purest knowledge, and because it gives direct perception of the self by realization, it is the perfection of religion. It is everlasting, and it is joyfully performed.
Those who are not faithful in this devotional service cannot attain Me, O conqueror of enemies. Therefore they return to the path of birth and death in this material world.
By Me, in My unmanifested form, this entire universe is pervaded. All beings are in Me, but I am not in them.
And yet everything that is created does not rest in Me. Behold My mystic opulence! Although I am the maintainer of all living entities and although I am everywhere, I am not a part of this cosmic manifestation, for My Self is the very source of creation.
Understand that as the mighty wind, blowing everywhere, rests always in the sky, all created beings rest in Me.
O son of Kuntī, at the end of the millennium all material manifestations enter into My nature, and at the beginning of another millennium, by My potency, I create them again.
The whole cosmic order is under Me. Under My will it is automatically manifested again and again, and under My will it is annihilated at the end.
O Dhanañjaya, all this work cannot bind Me. I am ever detached from all these material activities, seated as though neutral.
This material nature, which is one of My energies, is working under My direction, O son of Kuntī, producing all moving and nonmoving beings. Under its rule this manifestation is created and annihilated again and again.
Fools deride Me when I descend in the human form. They do not know My transcendental nature as the Supreme Lord of all that be.
Those who are thus bewildered are attracted by demonic and atheistic views. In that deluded condition, their hopes for liberation, their fruitive activities, and their culture of knowledge are all defeated.
O son of Pṛthā, those who are not deluded, the great souls, are under the protection of the divine nature. They are fully engaged in devotional service because they know Me as the Supreme Personality of Godhead, original and inexhaustible.
Always chanting My glories, endeavoring with great determination, bowing down before Me, these great souls perpetually worship Me with devotion.
Others, who engage in sacrifice by the cultivation of knowledge, worship the Supreme Lord as the one without a second, as diverse in many, and in the universal form.
But it is I who am the ritual, I the sacrifice, the offering to the ancestors, the healing herb, the transcendental chant. I am the butter and the fire and the offering.
I am the father of this universe, the mother, the support and the grandsire. I am the object of knowledge, the purifier and the syllable oḿ. I am also the Ṛg, the Sāma and the Yajur Vedas.
I am the goal, the sustainer, the master, the witness, the abode, the refuge, and the most dear friend. I am the creation and the annihilation, the basis of everything, the resting place and the eternal seed.
O Arjuna, I give heat, and I withhold and send forth the rain. I am immortality, and I am also death personified. Both spirit and matter are in Me.
Those who study the Vedas and drink the soma juice, seeking the heavenly planets, worship Me indirectly. Purified of sinful reactions, they take birth on the pious, heavenly planet of Indra, where they enjoy godly delights.
When they have thus enjoyed vast heavenly sense pleasure and the results of their pious activities are exhausted, they return to this mortal planet again. Thus those who seek sense enjoyment by adhering to the principles of the three Vedas achieve only repeated birth and death.
But those who always worship Me with exclusive devotion, meditating on My transcendental form — to them I carry what they lack, and I preserve what they have.
Those who are devotees of other gods and who worship them with faith actually worship only Me, O son of Kuntī, but they do so in a wrong way.
I am the only enjoyer and master of all sacrifices. Therefore, those who do not recognize My true transcendental nature fall down.
Those who worship the demigods will take birth among the demigods; those who worship the ancestors go to the ancestors; those who worship ghosts and spirits will take birth among such beings; and those who worship Me will live with Me.
If one offers Me with love and devotion a leaf, a flower, fruit or water, I will accept it.
Whatever you do, whatever you eat, whatever you offer or give away, and whatever austerities you perform — do that, O son of Kuntī, as an offering to Me.
In this way you will be freed from bondage to work and its auspicious and inauspicious results. With your mind fixed on Me in this principle of renunciation, you will be liberated and come to Me.
I envy no one, nor am I partial to anyone. I am equal to all. But whoever renders service unto Me in devotion is a friend, is in Me, and I am also a friend to him.
Even if one commits the most abominable action, if he is engaged in devotional service he is to be considered saintly because he is properly situated in his determination.
He quickly becomes righteous and attains lasting peace. O son of Kuntī, declare it boldly that My devotee never perishes.
O son of Pṛthā, those who take shelter in Me, though they be of lower birth — women, vaiśyas [merchants] and śūdras [workers] — can attain the supreme destination.
How much more this is so of the righteous brāhmaṇas, the devotees and the saintly kings. Therefore, having come to this temporary, miserable world, engage in loving service unto Me.
Engage your mind always in thinking of Me, become My devotee, offer obeisances to Me and worship Me. Being completely absorbed in Me, surely you will come to Me.
The Supreme Personality of Godhead said: Listen again, O mighty-armed Arjuna. Because you are My dear friend, for your benefit I shall speak to you further, giving knowledge that is better than what I have already explained.
Neither the hosts of demigods nor the great sages know My origin or opulences, for, in every respect, I am the source of the demigods and sages.
He who knows Me as the unborn, as the beginningless, as the Supreme Lord of all the worlds — he only, undeluded among men, is freed from all sins.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
The seven great sages and before them the four other great sages and the Manus [progenitors of mankind] come from Me, born from My mind, and all the living beings populating the various planets descend from them.
One who is factually convinced of this opulence and mystic power of Mine engages in unalloyed devotional service; of this there is no doubt.
I am the source of all spiritual and material worlds. Everything emanates from Me. The wise who perfectly know this engage in My devotional service and worship Me with all their hearts.
The thoughts of My pure devotees dwell in Me, their lives are fully devoted to My service, and they derive great satisfaction and bliss from always enlightening one another and conversing about Me.
To those who are constantly devoted to serving Me with love, I give the understanding by which they can come to Me.
To show them special mercy, I, dwelling in their hearts, destroy with the shining lamp of knowledge the darkness born of ignorance.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
O Kṛṣṇa, I totally accept as truth all that You have told me. Neither the demigods nor the demons, O Lord, can understand Your personality.
Indeed, You alone know Yourself by Your own internal potency, O Supreme Person, origin of all, Lord of all beings, God of gods, Lord of the universe!
Please tell me in detail of Your divine opulences by which You pervade all these worlds.
O Kṛṣṇa, O supreme mystic, how shall I constantly think of You, and how shall I know You? In what various forms are You to be remembered, O Supreme Personality of Godhead?
O Janārdana, again please describe in detail the mystic power of Your opulences. I am never satiated in hearing about You, for the more I hear the more I want to taste the nectar of Your words.
The Supreme Personality of Godhead said: Yes, I will tell you of My splendorous manifestations, but only of those which are prominent, O Arjuna, for My opulence is limitless.
I am the Supersoul, O Arjuna, seated in the hearts of all living entities. I am the beginning, the middle and the end of all beings.
Of the Ādityas I am Viṣṇu, of lights I am the radiant sun, of the Maruts I am Marīci, and among the stars I am the moon.
Of the Vedas I am the Sāma Veda; of the demigods I am Indra, the king of heaven; of the senses I am the mind; and in living beings I am the living force [consciousness].
Of all the Rudras I am Lord Śiva, of the Yakṣas and Rākṣasas I am the Lord of wealth [Kuvera], of the Vasus I am fire [Agni], and of mountains I am Meru.
Of priests, O Arjuna, know Me to be the chief, Bṛhaspati. Of generals I am Kārtikeya, and of bodies of water I am the ocean.
Of the great sages I am Bhṛgu; of vibrations I am the transcendental oḿ. Of sacrifices I am the chanting of the holy names [japa], and of immovable things I am the Himālayas.
Of all trees I am the banyan tree, and of the sages among the demigods I am Nārada. Of the Gandharvas I am Citraratha, and among perfected beings I am the sage Kapila.
Of horses know Me to be Uccaiḥśravā, produced during the churning of the ocean for nectar. Of lordly elephants I am Airāvata, and among men I am the monarch.
Of weapons I am the thunderbolt; among cows I am the surabhi. Of causes for procreation I am Kandarpa, the god of love, and of serpents I am Vāsuki.
Of the many-hooded Nāgas I am Ananta, and among the aquatics I am the demigod Varuṇa. Of departed ancestors I am Aryamā, and among the dispensers of law I am Yama, the lord of death.
Among the Daitya demons I am the devoted Prahlāda, among subduers I am time, among beasts I am the lion, and among birds I am Garuḍa.
Of purifiers I am the wind, of the wielders of weapons I am Rāma, of fishes I am the shark, and of flowing rivers I am the Ganges.
Of all creations I am the beginning and the end and also the middle, O Arjuna. Of all sciences I am the spiritual science of the self, and among logicians I am the conclusive truth.
Of letters I am the letter A, and among compound words I am the dual compound. I am also inexhaustible time, and of creators I am Brahmā.
I am all-devouring death, and I am the generating principle of all that is yet to be. Among women I am fame, fortune, fine speech, memory, intelligence, steadfastness and patience.
Of the hymns in the Sāma Veda I am the Bṛhat-sāma, and of poetry I am the Gāyatrī. Of months I am Mārgaśīrṣa [November-December], and of seasons I am flower-bearing spring.
I am also the gambling of cheats, and of the splendid I am the splendor. I am victory, I am adventure, and I am the strength of the strong.
Of the descendants of Vṛṣṇi I am Vāsudeva, and of the Pāṇḍavas I am Arjuna. Of the sages I am Vyāsa, and among great thinkers I am Uśanā.
Among all means of suppressing lawlessness I am punishment, and of those who seek victory I am morality. Of secret things I am silence, and of the wise I am the wisdom.
Furthermore, O Arjuna, I am the generating seed of all existences. There is no being — moving or nonmoving — that can exist without Me.
O mighty conqueror of enemies, there is no end to My divine manifestations. What I have spoken to you is but a mere indication of My infinite opulences.
Know that all opulent, beautiful and glorious creations spring from but a spark of My splendor.
But what need is there, Arjuna, for all this detailed knowledge? With a single fragment of Myself I pervade and support this entire universe.
Arjuna said: By my hearing the instructions You have kindly given me about these most confidential spiritual subjects, my illusion has now been dispelled.
O lotus-eyed one, I have heard from You in detail about the appearance and disappearance of every living entity and have realized Your inexhaustible glories.
O greatest of all personalities, O supreme form, though I see You here before me in Your actual position, as You have described Yourself, I wish to see how You have entered into this cosmic manifestation. I want to see that form of Yours.
If You think that I am able to behold Your cosmic form, O my Lord, O master of all mystic power, then kindly show me that unlimited universal Self.
The Supreme Personality of Godhead said: My dear Arjuna, O son of Pṛthā, see now My opulences, hundreds of thousands of varied divine and multicolored forms.
O best of the Bhāratas, see here the different manifestations of Ādityas, Vasus, Rudras, Aśvinī-kumāras and all the other demigods. Behold the many wonderful things which no one has ever seen or heard of before.
O Arjuna, whatever you wish to see, behold at once in this body of Mine! This universal form can show you whatever you now desire to see and whatever you may want to see in the future. Everything — moving and nonmoving — is here completely, in one place.
But you cannot see Me with your present eyes. Therefore I give you divine eyes. Behold My mystic opulence!
Sañjaya said: O King, having spoken thus, the Supreme Lord of all mystic power, the Personality of Godhead, displayed His universal form to Arjuna.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
If hundreds of thousands of suns were to rise at once into the sky, their radiance might resemble the effulgence of the Supreme Person in that universal form.
At that time Arjuna could see in the universal form of the Lord the unlimited expansions of the universe situated in one place although divided into many, many thousands.
Then, bewildered and astonished, his hair standing on end, Arjuna bowed his head to offer obeisances and with folded hands began to pray to the Supreme Lord.
Arjuna said: My dear Lord Kṛṣṇa, I see assembled in Your body all the demigods and various other living entities. I see Brahmā sitting on the lotus flower, as well as Lord Śiva and all the sages and divine serpents.
O Lord of the universe, O universal form, I see in Your body many, many arms, bellies, mouths and eyes, expanded everywhere, without limit. I see in You no end, no middle and no beginning.
Your form is difficult to see because of its glaring effulgence, spreading on all sides, like blazing fire or the immeasurable radiance of the sun. Yet I see this glowing form everywhere, adorned with various crowns, clubs and discs.
You are the supreme primal objective. You are the ultimate resting place of all this universe. You are inexhaustible, and You are the oldest. You are the maintainer of the eternal religion, the Personality of Godhead. This is my opinion.
You are without origin, middle or end. Your glory is unlimited. You have numberless arms, and the sun and moon are Your eyes. I see You with blazing fire coming forth from Your mouth, burning this entire universe by Your own radiance.
Although You are one, You spread throughout the sky and the planets and all space between. O great one, seeing this wondrous and terrible form, all the planetary systems are perturbed.
All the hosts of demigods are surrendering before You and entering into You. Some of them, very much afraid, are offering prayers with folded hands. Hosts of great sages and perfected beings, crying "All peace!" are praying to You by singing the Vedic hymns.
All the various manifestations of Lord Śiva, the Ādityas, the Vasus, the Sādhyas, the Viśvedevas, the two Aśvīs, the Maruts, the forefathers, the Gandharvas, the Yakṣas, the Asuras and the perfected demigods are beholding You in wonder.
O mighty-armed one, all the planets with their demigods are disturbed at seeing Your great form, with its many faces, eyes, arms, thighs, legs, and bellies and Your many terrible teeth; and as they are disturbed, so am I.
O all-pervading Viṣṇu, seeing You with Your many radiant colors touching the sky, Your gaping mouths, and Your great glowing eyes, my mind is perturbed by fear. I can no longer maintain my steadiness or equilibrium of mind.
O Lord of lords, O refuge of the worlds, please be gracious to me. I cannot keep my balance seeing thus Your blazing deathlike faces and awful teeth. In all directions I am bewildered.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
As the many waves of the rivers flow into the ocean, so do all these great warriors enter blazing into Your mouths.
I see all people rushing full speed into Your mouths, as moths dash to destruction in a blazing fire.
O Viṣṇu, I see You devouring all people from all sides with Your flaming mouths. Covering all the universe with Your effulgence, You are manifest with terrible, scorching rays.
O Lord of lords, so fierce of form, please tell me who You are. I offer my obeisances unto You; please be gracious to me. You are the primal Lord. I want to know about You, for I do not know what Your mission is.
The Supreme Personality of Godhead said: Time I am, the great destroyer of the worlds, and I have come here to destroy all people. With the exception of you [the Pāṇḍavas], all the soldiers here on both sides will be slain.
Therefore get up. Prepare to fight and win glory. Conquer your enemies and enjoy a flourishing kingdom. They are already put to death by My arrangement, and you, O Savyasācī, can be but an instrument in the fight.
Droṇa, Bhīṣma, Jayadratha, Karṇa and the other great warriors have already been destroyed by Me. Therefore, kill them and do not be disturbed. Simply fight, and you will vanquish your enemies in battle.
Sañjaya said to Dhṛtarāṣṭra: O King, after hearing these words from the Supreme Personality of Godhead, the trembling Arjuna offered obeisances with folded hands again and again. He fearfully spoke to Lord Kṛṣṇa in a faltering voice, as follows.
Arjuna said: O master of the senses, the world becomes joyful upon hearing Your name, and thus everyone becomes attached to You. Although the perfected beings offer You their respectful homage, the demons are afraid, and they flee here and there. All this is rightly done.
O great one, greater even than Brahmā, You are the original creator. Why then should they not offer their respectful obeisances unto You? O limitless one, God of gods, refuge of the universe! You are the invincible source, the cause of all causes, transcendental to this material manifestation.
You are the original Personality of Godhead, the oldest, the ultimate sanctuary of this manifested cosmic world. You are the knower of everything, and You are all that is knowable. You are the supreme refuge, above the material modes. O limitless form! This whole cosmic manifestation is pervaded by You!
You are air, and You are the supreme controller! You are fire, You are water, and You are the moon! You are Brahmā, the first living creature, and You are the great-grandfather. I therefore offer my respectful obeisances unto You a thousand times, and again and yet again!
Obeisances to You from the front, from behind and from all sides! O unbounded power, You are the master of limitless might! You are all-pervading, and thus You are everything!
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
You are the father of this complete cosmic manifestation, of the moving and the nonmoving. You are its worshipable chief, the supreme spiritual master. No one is equal to You, nor can anyone be one with You. How then could there be anyone greater than You within the three worlds, O Lord of immeasurable power?
You are the Supreme Lord, to be worshiped by every living being. Thus I fall down to offer You my respectful obeisances and ask Your mercy. As a father tolerates the impudence of his son, or a friend tolerates the impertinence of a friend, or a wife tolerates the familiarity of her partner, please tolerate the wrongs I may have done You.
After seeing this universal form, which I have never seen before, I am gladdened, but at the same time my mind is disturbed with fear. Therefore please bestow Your grace upon me and reveal again Your form as the Personality of Godhead, O Lord of lords, O abode of the universe.
O universal form, O thousand-armed Lord, I wish to see You in Your four-armed form, with helmeted head and with club, wheel, conch and lotus flower in Your hands. I long to see You in that form.
The Supreme Personality of Godhead said: My dear Arjuna, happily have I shown you, by My internal potency, this supreme universal form within the material world. No one before you has ever seen this primal form, unlimited and full of glaring effulgence.
O best of the Kuru warriors, no one before you has ever seen this universal form of Mine, for neither by studying the Vedas, nor by performing sacrifices, nor by charity, nor by pious activities, nor by severe penances can I be seen in this form in the material world.
You have been perturbed and bewildered by seeing this horrible feature of Mine. Now let it be finished. My devotee, be free again from all disturbances. With a peaceful mind you can now see the form you desire.
Sañjaya said to Dhṛtarāṣṭra: The Supreme Personality of Godhead, Kṛṣṇa, having spoken thus to Arjuna, displayed His real four-armed form and at last showed His two-armed form, thus encouraging the fearful Arjuna.
When Arjuna thus saw Kṛṣṇa in His original form, he said: O Janārdana, seeing this humanlike form, so very beautiful, I am now composed in mind, and I am restored to my original nature.
The Supreme Personality of Godhead said: My dear Arjuna, this form of Mine you are now seeing is very difficult to behold. Even the demigods are ever seeking the opportunity to see this form, which is so dear.
The form you are seeing with your transcendental eyes cannot be understood simply by studying the Vedas, nor by undergoing serious penances, nor by charity, nor by worship. It is not by these means that one can see Me as I am.
My dear Arjuna, only by undivided devotional service can I be understood as I am, standing before you, and can thus be seen directly. Only in this way can you enter into the mysteries of My understanding.
My dear Arjuna, he who engages in My pure devotional service, free from the contaminations of fruitive activities and mental speculation, he who works for Me, who makes Me the supreme goal of his life, and who is friendly to every living being — he certainly comes to Me.
Arjuna inquired: Which are considered to be more perfect, those who are always properly engaged in Your devotional service or those who worship the impersonal Brahman, the unmanifested? 
The Supreme Personality of Godhead said: Those who fix their minds on My personal form and are always engaged in worshiping Me with great and transcendental faith are considered by Me to be most perfect. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
For those whose minds are attached to the unmanifested, impersonal feature of the Supreme, advancement is very troublesome. To make progress in that discipline is always difficult for those who are embodied. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
Just fix your mind upon Me, the Supreme Personality of Godhead, and engage all your intelligence in Me. Thus you will live in Me always, without a doubt. 
My dear Arjuna, O winner of wealth, if you cannot fix your mind upon Me without deviation, then follow the regulative principles of bhakti-yoga. In this way develop a desire to attain Me. 
If you cannot practice the regulations of bhakti-yoga, then just try to work for Me, because by working for Me you will come to the perfect stage. 
If, however, you are unable to work in this consciousness of Me, then try to act giving up all results of your work and try to be self- situated. 
If you cannot take to this practice, then engage yourself in the cultivation of knowledge. Better than knowledge, however, is meditation, and better than meditation is renunciation of the fruits of action, for by such renunciation one can attain peace of mind. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
He for whom no one is put into difficulty and who is not disturbed by anyone, who is equipoised in happiness and distress, fear and anxiety, is very dear to Me. 
My devotee who is not dependent on the ordinary course of activities, who is pure, expert, without cares, free from all pains, and not striving for some result, is very dear to Me. 
One who neither rejoices nor grieves, who neither laments nor desires, and who renounces both auspicious and inauspicious things — such a devotee is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
Those who follow this imperishable path of devotional service and who completely engage themselves with faith, making Me the supreme goal, are very, very dear to Me.
Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
O scion of Bharata, you should understand that I am also the knower in all bodies, and to understand this body and its knower is called knowledge. That is My opinion.
Now please hear My brief description of this field of activity and how it is constituted, what its changes are, whence it is produced, who that knower of the field of activities is, and what his influences are.
That knowledge of the field of activities and of the knower of activities is described by various sages in various Vedic writings. It is especially presented in Vedānta-sūtra with all reasoning as to cause and effect.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
I shall now explain the knowable, knowing which you will taste the eternal. Brahman, the spirit, beginningless and subordinate to Me, lies beyond the cause and effect of this material world.
Everywhere are His hands and legs, His eyes, heads and faces, and He has ears everywhere. In this way the Supersoul exists, pervading everything.
The Supersoul is the original source of all senses, yet He is without senses. He is unattached, although He is the maintainer of all living beings. He transcends the modes of nature, and at the same time He is the master of all the modes of material nature.
The Supreme Truth exists outside and inside of all living beings, the moving and the nonmoving. Because He is subtle, He is beyond the power of the material senses to see or to know. Although far, far away, He is also near to all.
Although the Supersoul appears to be divided among all beings, He is never divided. He is situated as one. Although He is the maintainer of every living entity, it is to be understood that He devours and develops all.
He is the source of light in all luminous objects. He is beyond the darkness of matter and is unmanifested. He is knowledge, He is the object of knowledge, and He is the goal of knowledge. He is situated in everyone's heart.
Thus the field of activities [the body], knowledge and the knowable have been summarily described by Me. Only My devotees can understand this thoroughly and thus attain to My nature.
Material nature and the living entities should be understood to be beginningless. Their transformations and the modes of matter are products of material nature.
Nature is said to be the cause of all material causes and effects, whereas the living entity is the cause of the various sufferings and enjoyments in this world.
The living entity in material nature thus follows the ways of life, enjoying the three modes of nature. This is due to his association with that material nature. Thus he meets with good and evil among various species.
Yet in this body there is another, a transcendental enjoyer, who is the Lord, the supreme proprietor, who exists as the overseer and permitter, and who is known as the Supersoul.
One who understands this philosophy concerning material nature, the living entity and the interaction of the modes of nature is sure to attain liberation. He will not take birth here again, regardless of his present position.
Some perceive the Supersoul within themselves through meditation, others through the cultivation of knowledge, and still others through working without fruitive desires.
Again there are those who, although not conversant in spiritual knowledge, begin to worship the Supreme Person upon hearing about Him from others. Because of their tendency to hear from authorities, they also transcend the path of birth and death.
O chief of the Bhāratas, know that whatever you see in existence, both the moving and the nonmoving, is only a combination of the field of activities and the knower of the field.
One who sees the Supersoul accompanying the individual soul in all bodies, and who understands that neither the soul nor the Supersoul within the destructible body is ever destroyed, actually sees.
One who sees the Supersoul equally present everywhere, in every living being, does not degrade himself by his mind. Thus he approaches the transcendental destination.
One who can see that all activities are performed by the body, which is created of material nature, and sees that the self does nothing, actually sees.
When a sensible man ceases to see different identities due to different material bodies and he sees how beings are expanded everywhere, he attains to the Brahman conception.
Those with the vision of eternity can see that the imperishable soul is transcendental, eternal, and beyond the modes of nature. Despite contact with the material body, O Arjuna, the soul neither does anything nor is entangled.
The sky, due to its subtle nature, does not mix with anything, although it is all-pervading. Similarly, the soul situated in Brahman vision does not mix with the body, though situated in that body.
O son of Bharata, as the sun alone illuminates all this universe, so does the living entity, one within the body, illuminate the entire body by consciousness.
Those who see with eyes of knowledge the difference between the body and the knower of the body, and can also understand the process of liberation from bondage in material nature, attain to the supreme goal.
The Supreme Personality of Godhead said: Again I shall declare to you this supreme wisdom, the best of all knowledge, knowing which all the sages have attained the supreme perfection.
By becoming fixed in this knowledge, one can attain to the transcendental nature like My own. Thus established, one is not born at the time of creation or disturbed at the time of dissolution.
The total material substance, called Brahman, is the source of birth, and it is that Brahman that I impregnate, making possible the births of all living beings, O son of Bharata.
It should be understood that all species of life, O son of Kuntī, are made possible by birth in this material nature, and that I am the seed-giving father.
Material nature consists of three modes — goodness, passion and ignorance. When the eternal living entity comes in contact with nature, O mighty-armed Arjuna, he becomes conditioned by these modes.
O sinless one, the mode of goodness, being purer than the others, is illuminating, and it frees one from all sinful reactions. Those situated in that mode become conditioned by a sense of happiness and knowledge.
The mode of passion is born of unlimited desires and longings, O son of Kuntī, and because of this the embodied living entity is bound to material fruitive actions.
O son of Bharata, know that the mode of darkness, born of ignorance, is the delusion of all embodied living entities. The results of this mode are madness, indolence and sleep, which bind the conditioned soul.
O son of Bharata, the mode of goodness conditions one to happiness; passion conditions one to fruitive action; and ignorance, covering one's knowledge, binds one to madness.
Sometimes the mode of goodness becomes prominent, defeating the modes of passion and ignorance, O son of Bharata. Sometimes the mode of passion defeats goodness and ignorance, and at other times ignorance defeats goodness and passion. In this way there is always competition for supremacy.
The manifestations of the mode of goodness can be experienced when all the gates of the body are illuminated by knowledge.
O chief of the Bhāratas, when there is an increase in the mode of passion the symptoms of great attachment, fruitive activity, intense endeavor, and uncontrollable desire and hankering develop.
When there is an increase in the mode of ignorance, O son of Kuru, darkness, inertia, madness and illusion are manifested.
When one dies in the mode of goodness, he attains to the pure higher planets of the great sages.
When one dies in the mode of passion, he takes birth among those engaged in fruitive activities; and when one dies in the mode of ignorance, he takes birth in the animal kingdom.
The result of pious action is pure and is said to be in the mode of goodness. But action done in the mode of passion results in misery, and action performed in the mode of ignorance results in foolishness.
From the mode of goodness, real knowledge develops; from the mode of passion, greed develops; and from the mode of ignorance develop foolishness, madness and illusion.
Those situated in the mode of goodness gradually go upward to the higher planets; those in the mode of passion live on the earthly planets; and those in the abominable mode of ignorance go down to the hellish worlds.
When one properly sees that in all activities no other performer is at work than these modes of nature and he knows the Supreme Lord, who is transcendental to all these modes, he attains My spiritual nature.
When the embodied being is able to transcend these three modes associated with the material body, he can become free from birth, death, old age and their distresses and can enjoy nectar even in this life.
Arjuna inquired: O my dear Lord, by which symptoms is one known who is transcendental to these three modes? What is his behavior? And how does he transcend the modes of nature?
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
One who engages in full devotional service, unfailing in all circumstances, at once transcends the modes of material nature and thus comes to the level of Brahman.
And I am the basis of the impersonal Brahman, which is immortal, imperishable and eternal and is the constitutional position of ultimate happiness.
The Supreme Personality of Godhead said: It is said that there is an imperishable banyan tree that has its roots upward and its branches down and whose leaves are the Vedic hymns. One who knows this tree is the knower of the Vedas.
The branches of this tree extend downward and upward, nourished by the three modes of material nature. The twigs are the objects of the senses. This tree also has roots going down, and these are bound to the fruitive actions of human society.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
Those who are free from false prestige, illusion and false association, who understand the eternal, who are done with material lust, who are freed from the dualities of happiness and distress, and who, unbewildered, know how to surrender unto the Supreme Person attain to that eternal kingdom.
That supreme abode of Mine is not illumined by the sun or moon, nor by fire or electricity. Those who reach it never return to this material world.
The living entities in this conditioned world are My eternal fragmental parts. Due to conditioned life, they are struggling very hard with the six senses, which include the mind.
The living entity in the material world carries his different conceptions of life from one body to another as the air carries aromas. Thus he takes one kind of body and again quits it to take another.
The living entity, thus taking another gross body, obtains a certain type of ear, eye, tongue, nose and sense of touch, which are grouped about the mind. He thus enjoys a particular set of sense objects.
The foolish cannot understand how a living entity can quit his body, nor can they understand what sort of body he enjoys under the spell of the modes of nature. But one whose eyes are trained in knowledge can see all this.
The endeavoring transcendentalists, who are situated in self-realization, can see all this clearly. But those whose minds are not developed and who are not situated in self-realization cannot see what is taking place, though they may try to.
The splendor of the sun, which dissipates the darkness of this whole world, comes from Me. And the splendor of the moon and the splendor of fire are also from Me.
I enter into each planet, and by My energy they stay in orbit. I become the moon and thereby supply the juice of life to all vegetables.
I am the fire of digestion in the bodies of all living entities, and I join with the air of life, outgoing and incoming, to digest the four kinds of foodstuff.
I am seated in everyone's heart, and from Me come remembrance, knowledge and forgetfulness. By all the Vedas, I am to be known. Indeed, I am the compiler of Vedānta, and I am the knower of the Vedas.
There are two classes of beings, the fallible and the infallible. In the material world every living entity is fallible, and in the spiritual world every living entity is called infallible.
Besides these two, there is the greatest living personality, the Supreme Soul, the imperishable Lord Himself, who has entered the three worlds and is maintaining them.
Because I am transcendental, beyond both the fallible and the infallible, and because I am the greatest, I am celebrated both in the world and in the Vedas as that Supreme Person.
Whoever knows Me as the Supreme Personality of Godhead, without doubting, is the knower of everything. He therefore engages himself in full devotional service to Me, O son of Bharata.
This is the most confidential part of the Vedic scriptures, O sinless one, and it is disclosed now by Me. Whoever understands this will become wise, and his endeavors will know perfection.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
Pride, arrogance, conceit, anger, harshness and ignorance — these qualities belong to those of demoniac nature, O son of Pṛthā.
The transcendental qualities are conducive to liberation, whereas the demoniac qualities make for bondage. Do not worry, O son of Pāṇḍu, for you are born with the divine qualities.
O son of Pṛthā, in this world there are two kinds of created beings. One is called the divine and the other demoniac. I have already explained to you at length the divine qualities. Now hear from Me of the demoniac.
Those who are demoniac do not know what is to be done and what is not to be done. Neither cleanliness nor proper behavior nor truth is found in them.
They say that this world is unreal, with no foundation, no God in control. They say it is produced of sex desire and has no cause other than lust.
Following such conclusions, the demoniac, who are lost to themselves and who have no intelligence, engage in unbeneficial, horrible works meant to destroy the world.
Taking shelter of insatiable lust and absorbed in the conceit of pride and false prestige, the demoniac, thus illusioned, are always sworn to unclean work, attracted by the impermanent.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
Thus perplexed by various anxieties and bound by a network of illusions, they become too strongly attached to sense enjoyment and fall down into hell.
Self-complacent and always impudent, deluded by wealth and false prestige, they sometimes proudly perform sacrifices in name only, without following any rules or regulations.
Bewildered by false ego, strength, pride, lust and anger, the demons become envious of the Supreme Personality of Godhead, who is situated in their own bodies and in the bodies of others, and blaspheme against the real religion.
Those who are envious and mischievous, who are the lowest among men, I perpetually cast into the ocean of material existence, into various demoniac species of life.
Attaining repeated birth amongst the species of demoniac life, O son of Kuntī, such persons can never approach Me. Gradually they sink down to the most abominable type of existence.
There are three gates leading to this hell — lust, anger and greed. Every sane man should give these up, for they lead to the degradation of the soul.
The man who has escaped these three gates of hell, O son of Kuntī, performs acts conducive to self-realization and thus gradually attains the supreme destination.
He who discards scriptural injunctions and acts according to his own whims attains neither perfection, nor happiness, nor the supreme destination.
One should therefore understand what is duty and what is not duty by the regulations of the scriptures. Knowing such rules and regulations, one should act so that he may gradually be elevated.
Arjuna inquired: O Kṛṣṇa, what is the situation of those who do not follow the principles of scripture but worship according to their own imagination? Are they in goodness, in passion or in ignorance?
The Supreme Personality of Godhead said: According to the modes of nature acquired by the embodied soul, one's faith can be of three kinds — in goodness, in passion or in ignorance. Now hear about this.
O son of Bharata, according to one's existence under the various modes of nature, one evolves a particular kind of faith. The living being is said to be of a particular faith according to the modes he has acquired.
Men in the mode of goodness worship the demigods; those in the mode of passion worship the demons; and those in the mode of ignorance worship ghosts and spirits.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Even the food each person prefers is of three kinds, according to the three modes of material nature. The same is true of sacrifices, austerities and charity. Now hear of the distinctions between them.
Foods dear to those in the mode of goodness increase the duration of life, purify one's existence and give strength, health, happiness and satisfaction. Such foods are juicy, fatty, wholesome, and pleasing to the heart.
Foods that are too bitter, too sour, salty, hot, pungent, dry and burning are dear to those in the mode of passion. Such foods cause distress, misery and disease.
Food prepared more than three hours before being eaten, food that is tasteless, decomposed and putrid, and food consisting of remnants and untouchable things is dear to those in the mode of darkness.
Of sacrifices, the sacrifice performed according to the directions of scripture, as a matter of duty, by those who desire no reward, is of the nature of goodness.
But the sacrifice performed for some material benefit, or for the sake of pride, O chief of the Bhāratas, you should know to be in the mode of passion.
Any sacrifice performed without regard for the directions of scripture, without distribution of prasādam [spiritual food], without chanting of Vedic hymns and remunerations to the priests, and without faith is considered to be in the mode of ignorance.
Austerity of the body consists in worship of the Supreme Lord, the brāhmaṇas, the spiritual master, and superiors like the father and mother, and in cleanliness, simplicity, celibacy and nonviolence.
Austerity of speech consists in speaking words that are truthful, pleasing, beneficial, and not agitating to others, and also in regularly reciting Vedic literature.
And satisfaction, simplicity, gravity, self-control and purification of one's existence are the austerities of the mind.
This threefold austerity, performed with transcendental faith by men not expecting material benefits but engaged only for the sake of the Supreme, is called austerity in goodness.
Penance performed out of pride and for the sake of gaining respect, honor and worship is said to be in the mode of passion. It is neither stable nor permanent.
Penance performed out of foolishness, with self-torture or to destroy or injure others, is said to be in the mode of ignorance.
Charity given out of duty, without expectation of return, at the proper time and place, and to a worthy person is considered to be in the mode of goodness.
But charity performed with the expectation of some return, or with a desire for fruitive results, or in a grudging mood, is said to be charity in the mode of passion.
And charity performed at an impure place, at an improper time, to unworthy persons, or without proper attention and respect is said to be in the mode of ignorance.
From the beginning of creation, the three words oḿ tat sat were used to indicate the Supreme Absolute Truth. These three symbolic representations were used by brāhmaṇas while chanting the hymns of the Vedas and during sacrifices for the satisfaction of the Supreme.
Therefore, transcendentalists undertaking performances of sacrifice, charity and penance in accordance with scriptural regulations begin always with oḿ, to attain the Supreme.
Without desiring fruitive results, one should perform various kinds of sacrifice, penance and charity with the word tat. The purpose of such transcendental activities is to get free from material entanglement.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
Anything done as sacrifice, charity or penance without faith in the Supreme, O son of Pṛthā, is impermanent. It is called asat and is useless both in this life and the next.
Arjuna said: O mighty-armed one, I wish to understand the purpose of renunciation [tyāga] and of the renounced order of life [sannyāsa], O killer of the Keśī demon, master of the senses.
The Supreme Personality of Godhead said: The giving up of activities that are based on material desire is what great learned men call the renounced order of life [sannyāsa]. And giving up the results of all activities is what the wise call renunciation [tyāga].
Some learned men declare that all kinds of fruitive activities should be given up as faulty, yet other sages maintain that acts of sacrifice, charity and penance should never be abandoned.
O best of the Bhāratas, now hear My judgment about renunciation. O tiger among men, renunciation is declared in the scriptures to be of three kinds.
Acts of sacrifice, charity and penance are not to be given up; they must be performed. Indeed, sacrifice, charity and penance purify even the great souls.
All these activities should be performed without attachment or any expectation of result. They should be performed as a matter of duty, O son of Pṛthā. That is My final opinion.
Prescribed duties should never be renounced. If one gives up his prescribed duties because of illusion, such renunciation is said to be in the mode of ignorance.
Anyone who gives up prescribed duties as troublesome or out of fear of bodily discomfort is said to have renounced in the mode of passion. Such action never leads to the elevation of renunciation.
O Arjuna, when one performs his prescribed duty only because it ought to be done, and renounces all material association and all attachment to the fruit, his renunciation is said to be in the mode of goodness.
The intelligent renouncer situated in the mode of goodness, neither hateful of inauspicious work nor attached to auspicious work, has no doubts about work.
It is indeed impossible for an embodied being to give up all activities. But he who renounces the fruits of action is called one who has truly renounced.
For one who is not renounced, the threefold fruits of action — desirable, undesirable and mixed — accrue after death. But those who are in the renounced order of life have no such result to suffer or enjoy.
O mighty-armed Arjuna, according to the Vedānta there are five causes for the accomplishment of all action. Now learn of these from Me.
The place of action [the body], the performer, the various senses, the many different kinds of endeavor, and ultimately the Supersoul — these are the five factors of action.
Whatever right or wrong action a man performs by body, mind or speech is caused by these five factors.
Therefore one who thinks himself the only doer, not considering the five factors, is certainly not very intelligent and cannot see things as they are.
One who is not motivated by false ego, whose intelligence is not entangled, though he kills men in this world, does not kill. Nor is he bound by his actions.
Knowledge, the object of knowledge, and the knower are the three factors that motivate action; the senses, the work and the doer are the three constituents of action.
According to the three different modes of material nature, there are three kinds of knowledge, action and performer of action. Now hear of them from Me.
That knowledge by which one undivided spiritual nature is seen in all living entities, though they are divided into innumerable forms, you should understand to be in the mode of goodness.
That knowledge by which one sees that in every different body there is a different type of living entity you should understand to be in the mode of passion.
And that knowledge by which one is attached to one kind of work as the all in all, without knowledge of the truth, and which is very meager, is said to be in the mode of darkness.
That action which is regulated and which is performed without attachment, without love or hatred, and without desire for fruitive results is said to be in the mode of goodness.
But action performed with great effort by one seeking to gratify his desires, and enacted from a sense of false ego, is called action in the mode of passion.
That action performed in illusion, in disregard of scriptural injunctions, and without concern for future bondage or for violence or distress caused to others is said to be in the mode of ignorance.
One who performs his duty without association with the modes of material nature, without false ego, with great determination and enthusiasm, and without wavering in success or failure is said to be a worker in the mode of goodness.
The worker who is attached to work and the fruits of work, desiring to enjoy those fruits, and who is greedy, always envious, impure, and moved by joy and sorrow, is said to be in the mode of passion.
The worker who is always engaged in work against the injunctions of the scripture, who is materialistic, obstinate, cheating and expert in insulting others, and who is lazy, always morose and procrastinating is said to be a worker in the mode of ignorance.
O winner of wealth, now please listen as I tell you in detail of the different kinds of understanding and determination, according to the three modes of material nature.
O son of Pṛthā, that understanding by which one knows what ought to be done and what ought not to be done, what is to be feared and what is not to be feared, what is binding and what is liberating, is in the mode of goodness.
O son of Pṛthā, that understanding which cannot distinguish between religion and irreligion, between action that should be done and action that should not be done, is in the mode of passion.
That understanding which considers irreligion to be religion and religion to be irreligion, under the spell of illusion and darkness, and strives always in the wrong direction, O Pārtha, is in the mode of ignorance.
O son of Pṛthā, that determination which is unbreakable, which is sustained with steadfastness by yoga practice, and which thus controls the activities of the mind, life and senses is determination in the mode of goodness.
But that determination by which one holds fast to fruitive results in religion, economic development and sense gratification is of the nature of passion, O Arjuna.
And that determination which cannot go beyond dreaming, fearfulness, lamentation, moroseness and illusion — such unintelligent determination, O son of Pṛthā, is in the mode of darkness.
O best of the Bhāratas, now please hear from Me about the three kinds of happiness by which the conditioned soul enjoys, and by which he sometimes comes to the end of all distress.
That which in the beginning may be just like poison but at the end is just like nectar and which awakens one to self-realization is said to be happiness in the mode of goodness.
That happiness which is derived from contact of the senses with their objects and which appears like nectar at first but poison at the end is said to be of the nature of passion.
And that happiness which is blind to self-realization, which is delusion from beginning to end and which arises from sleep, laziness and illusion is said to be of the nature of ignorance.
There is no being existing, either here or among the demigods in the higher planetary systems, which is freed from these three modes born of material nature.
Brāhmaṇas, kṣatriyas, vaiśyas and śūdras are distinguished by the qualities born of their own natures in accordance with the material modes, O chastiser of the enemy.
Peacefulness, self-control, austerity, purity, tolerance, honesty, knowledge, wisdom and religiousness — these are the natural qualities by which the brāhmaṇas work.
Heroism, power, determination, resourcefulness, courage in battle, generosity and leadership are the natural qualities of work for the kṣatriyas.
Farming, cow protection and business are the natural work for the vaiśyas, and for the śūdras there is labor and service to others.
By following his qualities of work, every man can become perfect. Now please hear from Me how this can be done.
By worship of the Lord, who is the source of all beings and who is all-pervading, a man can attain perfection through performing his own work.
It is better to engage in one's own occupation, even though one may perform it imperfectly, than to accept another's occupation and perform it perfectly. Duties prescribed according to one's nature are never affected by sinful reactions.
Every endeavor is covered by some fault, just as fire is covered by smoke. Therefore one should not give up the work born of his nature, O son of Kuntī, even if such work is full of fault.
One who is self-controlled and unattached and who disregards all material enjoyments can obtain, by practice of renunciation, the highest perfect stage of freedom from reaction.
O son of Kuntī, learn from Me how one who has achieved this perfection can attain to the supreme perfectional stage, Brahman, the stage of highest knowledge, by acting in the way I shall now summarize.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
One who is thus transcendentally situated at once realizes the Supreme Brahman and becomes fully joyful. He never laments or desires to have anything. He is equally disposed toward every living entity. In that state he attains pure devotional service unto Me.
One can understand Me as I am, as the Supreme Personality of Godhead, only by devotional service. And when one is in full consciousness of Me by such devotion, he can enter into the kingdom of God.
Though engaged in all kinds of activities, My pure devotee, under My protection, reaches the eternal and imperishable abode by My grace.
In all activities just depend upon Me and work always under My protection. In such devotional service, be fully conscious of Me.
If you become conscious of Me, you will pass over all the obstacles of conditioned life by My grace. If, however, you do not work in such consciousness but act through false ego, not hearing Me, you will be lost.
If you do not act according to My direction and do not fight, then you will be falsely directed. By your nature, you will have to be engaged in warfare.
Under illusion you are now declining to act according to My direction. But, compelled by the work born of your own nature, you will act all the same, O son of Kuntī.
The Supreme Lord is situated in everyone's heart, O Arjuna, and is directing the wanderings of all living entities, who are seated as on a machine, made of the material energy.
O scion of Bharata, surrender unto Him utterly. By His grace you will attain transcendental peace and the supreme and eternal abode.
Thus I have explained to you knowledge still more confidential. Deliberate on this fully, and then do what you wish to do.
Because you are My very dear friend, I am speaking to you My supreme instruction, the most confidential knowledge of all. Hear this from Me, for it is for your benefit.
Always think of Me, become My devotee, worship Me and offer your homage unto Me. Thus you will come to Me without fail. I promise you this because you are My very dear friend.
Abandon all varieties of religion and just surrender unto Me. I shall deliver you from all sinful reactions. Do not fear.
This confidential knowledge may never be explained to those who are not austere, or devoted, or engaged in devotional service, nor to one who is envious of Me.
For one who explains this supreme secret to the devotees, pure devotional service is guaranteed, and at the end he will come back to Me.
There is no servant in this world more dear to Me than he, nor will there ever be one more dear.
And I declare that he who studies this sacred conversation of ours worships Me by his intelligence.
And one who listens with faith and without envy becomes free from sinful reactions and attains to the auspicious planets where the pious dwell.
O son of Pṛthā, O conqueror of wealth, have you heard this with an attentive mind? And are your ignorance and illusions now dispelled?
Arjuna said: My dear Kṛṣṇa, O infallible one, my illusion is now gone. I have regained my memory by Your mercy. I am now firm and free from doubt and am prepared to act according to Your instructions.
Sañjaya said: Thus have I heard the conversation of two great souls, Kṛṣṇa and Arjuna. And so wonderful is that message that my hair is standing on end.
By the mercy of Vyāsa, I have heard these most confidential talks directly from the master of all mysticism, Kṛṣṇa, who was speaking personally to Arjuna.
O King, as I repeatedly recall this wondrous and holy dialogue between Kṛṣṇa and Arjuna, I take pleasure, being thrilled at every moment.
O King, as I remember the wonderful form of Lord Kṛṣṇa, I am struck with wonder more and more, and I rejoice again and again.
Wherever there is Kṛṣṇa, the master of all mystics, and wherever there is Arjuna, the supreme archer, there will also certainly be opulence, victory, extraordinary power, and morality. That is my opinion.Dhṛtarāṣṭra said: O Sañjaya, after my sons and the sons of Pāṇḍu assembled in the place of pilgrimage at Kurukṣetra, desiring to fight, what did they do?
Sañjaya said: O King, after looking over the army arranged in military formation by the sons of Pāṇḍu, King Duryodhana went to his teacher and spoke the following words.
O my teacher, behold the great army of the sons of Pāṇḍu, so expertly arranged by your intelligent disciple the son of Drupada.
Here in this army are many heroic bowmen equal in fighting to Bhīma and Arjuna: great fighters like Yuyudhāna, Virāṭa and Drupada.
There are also great, heroic, powerful fighters like Dhṛṣṭaketu, Cekitāna, Kāśirāja, Purujit, Kuntibhoja and Śaibya.
There are the mighty Yudhāmanyu, the very powerful Uttamaujā, the son of Subhadrā and the sons of Draupadī. All these warriors are great chariot fighters.
But for your information, O best of the brāhmaṇas, let me tell you about the captains who are especially qualified to lead my military force.
There are personalities like you, Bhīṣma, Karṇa, Kṛpa, Aśvatthāmā, Vikarṇa and the son of Somadatta called Bhūriśravā, who are always victorious in battle.
There are many other heroes who are prepared to lay down their lives for my sake. All of them are well equipped with different kinds of weapons, and all are experienced in military science.
Our strength is immeasurable, and we are perfectly protected by Grandfather Bhīṣma, whereas the strength of the Pāṇḍavas, carefully protected by Bhīma, is limited.
All of you must now give full support to Grandfather Bhīṣma, as you stand at your respective strategic points of entrance into the phalanx of the army.
Then Bhīṣma, the great valiant grandsire of the Kuru dynasty, the grandfather of the fighters, blew his conchshell very loudly, making a sound like the roar of a lion, giving Duryodhana joy.
After that, the conchshells, drums, bugles, trumpets and horns were all suddenly sounded, and the combined sound was tumultuous.
On the other side, both Lord Kṛṣṇa and Arjuna, stationed on a great chariot drawn by white horses, sounded their transcendental conchshells.
Lord Kṛṣṇa blew His conchshell, called Pāñcajanya; Arjuna blew his, the Devadatta; and Bhīma, the voracious eater and performer of herculean tasks, blew his terrific conchshell, called Pauṇḍra.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
The blowing of these different conchshells became uproarious. Vibrating both in the sky and on the earth, it shattered the hearts of the sons of Dhṛtarāṣṭra.
At that time Arjuna, the son of Pāṇḍu, seated in the chariot bearing the flag marked with Hanumān, took up his bow and prepared to shoot his arrows. O King, after looking at the sons of Dhṛtarāṣṭra drawn in military array, Arjuna then spoke to Lord Kṛṣṇa these words.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Let me see those who have come here to fight, wishing to please the evil-minded son of Dhṛtarāṣṭra.
Sañjaya said: O descendant of Bharata, having thus been addressed by Arjuna, Lord Kṛṣṇa drew up the fine chariot in the midst of the armies of both parties.
In the presence of Bhīṣma, Droṇa and all the other chieftains of the world, the Lord said, Just behold, Pārtha, all the Kurus assembled here.
There Arjuna could see, within the midst of the armies of both parties, his fathers, grandfathers, teachers, maternal uncles, brothers, sons, grandsons, friends, and also his fathers-in-law and well-wishers.
When the son of Kuntī, Arjuna, saw all these different grades of friends and relatives, he became overwhelmed with compassion and spoke thus.
Arjuna said: My dear Kṛṣṇa, seeing my friends and relatives present before me in such a fighting spirit, I feel the limbs of my body quivering and my mouth drying up.
My whole body is trembling, my hair is standing on end, my bow Gāṇḍīva is slipping from my hand, and my skin is burning.
I am now unable to stand here any longer. I am forgetting myself, and my mind is reeling. I see only causes of misfortune, O Kṛṣṇa, killer of the Keśī demon.
I do not see how any good can come from killing my own kinsmen in this battle, nor can I, my dear Kṛṣṇa, desire any subsequent victory, kingdom, or happiness.
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
Sin will overcome us if we slay such aggressors. Therefore it is not proper for us to kill the sons of Dhṛtarāṣṭra and our friends. What should we gain, O Kṛṣṇa, husband of the goddess of fortune, and how could we be happy by killing our own kinsmen?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
With the destruction of dynasty, the eternal family tradition is vanquished, and thus the rest of the family becomes involved in irreligion.
When irreligion is prominent in the family, O Kṛṣṇa, the women of the family become polluted, and from the degradation of womanhood, O descendant of Vṛṣṇi, comes unwanted progeny.
An increase of unwanted population certainly causes hellish life both for the family and for those who destroy the family tradition. The ancestors of such corrupt families fall down, because the performances for offering them food and water are entirely stopped.
By the evil deeds of those who destroy the family tradition and thus give rise to unwanted children, all kinds of community projects and family welfare activities are devastated.
O Kṛṣṇa, maintainer of the people, I have heard by disciplic succession that those who destroy family traditions dwell always in hell.
Alas, how strange it is that we are preparing to commit greatly sinful acts. Driven by the desire to enjoy royal happiness, we are intent on killing our own kinsmen.
Better for me if the sons of Dhṛtarāṣṭra, weapons in hand, were to kill me unarmed and unresisting on the battlefield.
Sañjaya said: Arjuna, having thus spoken on the battlefield, cast aside his bow and arrows and sat down on the chariot, his mind overwhelmed with grief.Sañjaya said: Seeing Arjuna full of compassion, his mind depressed, his eyes full of tears, Madhusūdana, Kṛṣṇa, spoke the following words.
The Supreme Personality of Godhead said: My dear Arjuna, how have these impurities come upon you? They are not at all befitting a man who knows the value of life. They lead not to higher planets but to infamy.
O son of Pṛthā, do not yield to this degrading impotence. It does not become you. Give up such petty weakness of heart and arise, O chastiser of the enemy.
Arjuna said: O killer of enemies, O killer of Madhu, how can I counterattack with arrows in battle men like Bhīṣma and Droṇa, who are worthy of my worship?
It would be better to live in this world by begging than to live at the cost of the lives of great souls who are my teachers. Even though desiring worldly gain, they are superiors. If they are killed, everything we enjoy will be tainted with blood.
Nor do we know which is better — conquering them or being conquered by them. If we killed the sons of Dhṛtarāṣṭra, we should not care to live. Yet they are now standing before us on the battlefield.
Now I am confused about my duty and have lost all composure because of miserly weakness. In this condition I am asking You to tell me for certain what is best for me. Now I am Your disciple, and a soul surrendered unto You. Please instruct me.
I can find no means to drive away this grief which is drying up my senses. I will not be able to dispel it even if I win a prosperous, unrivaled kingdom on earth with sovereignty like the demigods in heaven.
Sañjaya said: Having spoken thus, Arjuna, chastiser of enemies, told Kṛṣṇa, "Govinda, I shall not fight," and fell silent.
O descendant of Bharata, at that time Kṛṣṇa, smiling, in the midst of both the armies, spoke the following words to the grief-stricken Arjuna.
The Supreme Personality of Godhead said: While speaking learned words, you are mourning for what is not worthy of grief. Those who are wise lament neither for the living nor for the dead.
Never was there a time when I did not exist, nor you, nor all these kings; nor in the future shall any of us cease to be.
As the embodied soul continuously passes, in this body, from boyhood to youth to old age, the soul similarly passes into another body at death. A sober person is not bewildered by such a change.
O son of Kuntī, the nonpermanent appearance of happiness and distress, and their disappearance in due course, are like the appearance and disappearance of winter and summer seasons. They arise from sense perception, O scion of Bharata, and one must learn to tolerate them without being disturbed.
O best among men [Arjuna], the person who is not disturbed by happiness and distress and is steady in both is certainly eligible for liberation.
Those who are seers of the truth have concluded that of the nonexistent [the material body] there is no endurance and of the eternal [the soul] there is no change. This they have concluded by studying the nature of both.
That which pervades the entire body you should know to be indestructible. No one is able to destroy that imperishable soul.
The material body of the indestructible, immeasurable and eternal living entity is sure to come to an end; therefore, fight, O descendant of Bharata.
Neither he who thinks the living entity the slayer nor he who thinks it slain is in knowledge, for the self slays not nor is slain.
For the soul there is neither birth nor death at any time. He has not come into being, does not come into being, and will not come into being. He is unborn, eternal, ever-existing and primeval. He is not slain when the body is slain.
O Pārtha, how can a person who knows that the soul is indestructible, eternal, unborn and immutable kill anyone or cause anyone to kill?
As a person puts on new garments, giving up old ones, the soul similarly accepts new material bodies, giving up the old and useless ones.
The soul can never be cut to pieces by any weapon, nor burned by fire, nor moistened by water, nor withered by the wind.
This individual soul is unbreakable and insoluble, and can be neither burned nor dried. He is everlasting, present everywhere, unchangeable, immovable and eternally the same.
It is said that the soul is invisible, inconceivable and immutable. Knowing this, you should not grieve for the body.
If, however, you think that the soul [or the symptoms of life] is always born and dies forever, you still have no reason to lament, O mighty-armed.
One who has taken his birth is sure to die, and after death one is sure to take birth again. Therefore, in the unavoidable discharge of your duty, you should not lament.
All created beings are unmanifest in their beginning, manifest in their interim state, and unmanifest again when annihilated. So what need is there for lamentation?
Some look on the soul as amazing, some describe him as amazing, and some hear of him as amazing, while others, even after hearing about him, cannot understand him at all.
O descendant of Bharata, he who dwells in the body can never be slain. Therefore you need not grieve for any living being.
Considering your specific duty as a kṣatriya, you should know that there is no better engagement for you than fighting on religious principles; and so there is no need for hesitation.
O Pārtha, happy are the kṣatriyas to whom such fighting opportunities come unsought, opening for them the doors of the heavenly planets.
If, however, you do not perform your religious duty of fighting, then you will certainly incur sins for neglecting your duties and thus lose your reputation as a fighter.
People will always speak of your infamy, and for a respectable person, dishonor is worse than death.
The great generals who have highly esteemed your name and fame will think that you have left the battlefield out of fear only, and thus they will consider you insignificant.
Your enemies will describe you in many unkind words and scorn your ability. What could be more painful for you?
O son of Kuntī, either you will be killed on the battlefield and attain the heavenly planets, or you will conquer and enjoy the earthly kingdom. Therefore, get up with determination and fight.
Do thou fight for the sake of fighting, without considering happiness or distress, loss or gain, victory or defeat — and by so doing you shall never incur sin.
Thus far I have described this knowledge to you through analytical study. Now listen as I explain it in terms of working without fruitive results. O son of Pṛthā, when you act in such knowledge you can free yourself from the bondage of works.
In this endeavor there is no loss or diminution, and a little advancement on this path can protect one from the most dangerous type of fear.
Those who are on this path are resolute in purpose, and their aim is one. O beloved child of the Kurus, the intelligence of those who are irresolute is many-branched.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
In the minds of those who are too attached to sense enjoyment and material opulence, and who are bewildered by such things, the resolute determination for devotional service to the Supreme Lord does not take place.
The Vedas deal mainly with the subject of the three modes of material nature. O Arjuna, become transcendental to these three modes. Be free from all dualities and from all anxieties for gain and safety, and be established in the self.
All purposes served by a small well can at once be served by a great reservoir of water. Similarly, all the purposes of the Vedas can be served to one who knows the purpose behind them.
You have a right to perform your prescribed duty, but you are not entitled to the fruits of action. Never consider yourself the cause of the results of your activities, and never be attached to not doing your duty.
Perform your duty equipoised, O Arjuna, abandoning all attachment to success or failure. Such equanimity is called yoga.
O Dhanañjaya, keep all abominable activities far distant by devotional service, and in that consciousness surrender unto the Lord. Those who want to enjoy the fruits of their work are misers.
A man engaged in devotional service rids himself of both good and bad actions even in this life. Therefore strive for yoga, which is the art of all work.
By thus engaging in devotional service to the Lord, great sages or devotees free themselves from the results of work in the material world. In this way they become free from the cycle of birth and death and attain the state beyond all miseries [by going back to Godhead].
When your intelligence has passed out of the dense forest of delusion, you shall become indifferent to all that has been heard and all that is to be heard.
When your mind is no longer disturbed by the flowery language of the Vedas, and when it remains fixed in the trance of self-realization, then you will have attained the divine consciousness.
Arjuna said: O Kṛṣṇa, what are the symptoms of one whose consciousness is thus merged in transcendence? How does he speak, and what is his language? How does he sit, and how does he walk?
The Supreme Personality of Godhead said: O Pārtha, when a man gives up all varieties of desire for sense gratification, which arise from mental concoction, and when his mind, thus purified, finds satisfaction in the self alone, then he is said to be in pure transcendental consciousness.
One who is not disturbed in mind even amidst the threefold miseries or elated when there is happiness, and who is free from attachment, fear and anger, is called a sage of steady mind.
In the material world, one who is unaffected by whatever good or evil he may obtain, neither praising it nor despising it, is firmly fixed in perfect knowledge.
One who is able to withdraw his senses from sense objects, as the tortoise draws its limbs within the shell, is firmly fixed in perfect consciousness.
The embodied soul may be restricted from sense enjoyment, though the taste for sense objects remains. But, ceasing such engagements by experiencing a higher taste, he is fixed in consciousness.
The senses are so strong and impetuous, O Arjuna, that they forcibly carry away the mind even of a man of discrimination who is endeavoring to control them.
One who restrains his senses, keeping them under full control, and fixes his consciousness upon Me, is known as a man of steady intelligence.
While contemplating the objects of the senses, a person develops attachment for them, and from such attachment lust develops, and from lust anger arises.
From anger, complete delusion arises, and from delusion bewilderment of memory. When memory is bewildered, intelligence is lost, and when intelligence is lost one falls down again into the material pool.
But a person free from all attachment and aversion and able to control his senses through regulative principles of freedom can obtain the complete mercy of the Lord.
For one thus satisfied [in Kṛṣṇa consciousness], the threefold miseries of material existence exist no longer; in such satisfied consciousness, one's intelligence is soon well established.
One who is not connected with the Supreme [in Kṛṣṇa consciousness] can have neither transcendental intelligence nor a steady mind, without which there is no possibility of peace. And how can there be any happiness without peace?
As a strong wind sweeps away a boat on the water, even one of the roaming senses on which the mind focuses can carry away a man's intelligence.
Therefore, O mighty-armed, one whose senses are restrained from their objects is certainly of steady intelligence.
What is night for all beings is the time of awakening for the self-controlled; and the time of awakening for all beings is night for the introspective sage.
A person who is not disturbed by the incessant flow of desires — that enter like rivers into the ocean, which is ever being filled but is always still — can alone achieve peace, and not the man who strives to satisfy such desires.
A person who has given up all desires for sense gratification, who lives free from desires, who has given up all sense of proprietorship and is devoid of false ego — he alone can attain real peace.
That is the way of the spiritual and godly life, after attaining which a man is not bewildered. If one is thus situated even at the hour of death, one can enter into the kingdom of God.Arjuna said: O Janārdana, O Keśava, why do You want to engage me in this ghastly warfare, if You think that intelligence is better than fruitive work?
My intelligence is bewildered by Your equivocal instructions. Therefore, please tell me decisively which will be most beneficial for me.
The Supreme Personality of Godhead said: O sinless Arjuna, I have already explained that there are two classes of men who try to realize the self. Some are inclined to understand it by empirical, philosophical speculation, and others by devotional service.
Not by merely abstaining from work can one achieve freedom from reaction, nor by renunciation alone can one attain perfection.
Everyone is forced to act helplessly according to the qualities he has acquired from the modes of material nature; therefore no one can refrain from doing something, not even for a moment.
One who restrains the senses of action but whose mind dwells on sense objects certainly deludes himself and is called a pretender.
On the other hand, if a sincere person tries to control the active senses by the mind and begins karma-yoga [in Kṛṣṇa consciousness] without attachment, he is by far superior.
Perform your prescribed duty, for doing so is better than not working. One cannot even maintain one's physical body without work.
Work done as a sacrifice for Viṣṇu has to be performed, otherwise work causes bondage in this material world. Therefore, O son of Kuntī, perform your prescribed duties for His satisfaction, and in that way you will always remain free from bondage.
In the beginning of creation, the Lord of all creatures sent forth generations of men and demigods, along with sacrifices for Viṣṇu, and blessed them by saying, "Be thou happy by this yajña [sacrifice] because its performance will bestow upon you everything desirable for living happily and achieving liberation."
The demigods, being pleased by sacrifices, will also please you, and thus, by cooperation between men and demigods, prosperity will reign for all.
In charge of the various necessities of life, the demigods, being satisfied by the performance of yajña [sacrifice], will supply all necessities to you. But he who enjoys such gifts without offering them to the demigods in return is certainly a thief.
The devotees of the Lord are released from all kinds of sins because they eat food which is offered first for sacrifice. Others, who prepare food for personal sense enjoyment, verily eat only sin.
All living bodies subsist on food grains, which are produced from rains. Rains are produced by performance of yajña [sacrifice], and yajña is born of prescribed duties.
Regulated activities are prescribed in the Vedas, and the Vedas are directly manifested from the Supreme Personality of Godhead. Consequently the all-pervading Transcendence is eternally situated in acts of sacrifice.
My dear Arjuna, one who does not follow in human life the cycle of sacrifice thus established by the Vedas certainly leads a life full of sin. Living only for the satisfaction of the senses, such a person lives in vain.
But for one who takes pleasure in the self, whose human life is one of self-realization, and who is satisfied in the self only, fully satiated — for him there is no duty.
A self-realized man has no purpose to fulfill in the discharge of his prescribed duties, nor has he any reason not to perform such work. Nor has he any need to depend on any other living being.
Therefore, without being attached to the fruits of activities, one should act as a matter of duty, for by working without attachment one attains the Supreme.
Kings such as Janaka attained perfection solely by performance of prescribed duties. Therefore, just for the sake of educating the people in general, you should perform your work.
Whatever action a great man performs, common men follow. And whatever standards he sets by exemplary acts, all the world pursues.
O son of Pṛthā, there is no work prescribed for Me within all the three planetary systems. Nor am I in want of anything, nor have I a need to obtain anything — and yet I am engaged in prescribed duties.
For if I ever failed to engage in carefully performing prescribed duties, O Pārtha, certainly all men would follow My path.
If I did not perform prescribed duties, all these worlds would be put to ruination. I would be the cause of creating unwanted population, and I would thereby destroy the peace of all living beings.
As the ignorant perform their duties with attachment to results, the learned may similarly act, but without attachment, for the sake of leading people on the right path.
So as not to disrupt the minds of ignorant men attached to the fruitive results of prescribed duties, a learned person should not induce them to stop work. Rather, by working in the spirit of devotion, he should engage them in all sorts of activities [for the gradual development of Kṛṣṇa consciousness].
The spirit soul bewildered by the influence of false ego thinks himself the doer of activities that are in actuality carried out by the three modes of material nature.
One who is in knowledge of the Absolute Truth, O mighty-armed, does not engage himself in the senses and sense gratification, knowing well the differences between work in devotion and work for fruitive results.
Bewildered by the modes of material nature, the ignorant fully engage themselves in material activities and become attached. But the wise should not unsettle them, although these duties are inferior due to the performers' lack of knowledge.
Therefore, O Arjuna, surrendering all your works unto Me, with full knowledge of Me, without desires for profit, with no claims to proprietorship, and free from lethargy, fight.
Those persons who execute their duties according to My injunctions and who follow this teaching faithfully, without envy, become free from the bondage of fruitive actions.
But those who, out of envy, disregard these teachings and do not follow them are to be considered bereft of all knowledge, befooled, and ruined in their endeavors for perfection.
Even a man of knowledge acts according to his own nature, for everyone follows the nature he has acquired from the three modes. What can repression accomplish?
There are principles to regulate attachment and aversion pertaining to the senses and their objects. One should not come under the control of such attachment and aversion, because they are stumbling blocks on the path of self-realization.
It is far better to discharge one's prescribed duties, even though faultily, than another's duties perfectly. Destruction in the course of performing one's own duty is better than engaging in another's duties, for to follow another's path is dangerous.
Arjuna said: O descendant of Vṛṣṇi, by what is one impelled to sinful acts, even unwillingly, as if engaged by force?
The Supreme Personality of Godhead said: It is lust only, Arjuna, which is born of contact with the material mode of passion and later transformed into wrath, and which is the all-devouring sinful enemy of this world.
As fire is covered by smoke, as a mirror is covered by dust, or as the embryo is covered by the womb, the living entity is similarly covered by different degrees of this lust.
Thus the wise living entity's pure consciousness becomes covered by his eternal enemy in the form of lust, which is never satisfied and which burns like fire.
The senses, the mind and the intelligence are the sitting places of this lust. Through them lust covers the real knowledge of the living entity and bewilders him.
Therefore, O Arjuna, best of the Bhāratas, in the very beginning curb this great symbol of sin [lust] by regulating the senses, and slay this destroyer of knowledge and self-realization.
The working senses are superior to dull matter; mind is higher than the senses; intelligence is still higher than the mind; and he [the soul] is even higher than the intelligence.
Thus knowing oneself to be transcendental to the material senses, mind and intelligence, O mighty-armed Arjuna, one should steady the mind by deliberate spiritual intelligence [Kṛṣṇa consciousness] and thus — by spiritual strength — conquer this insatiable enemy known as lust.The Personality of Godhead, Lord Śrī Kṛṣṇa, said: I instructed this imperishable science of yoga to the sun-god, Vivasvān, and Vivasvān instructed it to Manu, the father of mankind, and Manu in turn instructed it to Ikṣvāku.
This supreme science was thus received through the chain of disciplic succession, and the saintly kings understood it in that way. But in course of time the succession was broken, and therefore the science as it is appears to be lost.
That very ancient science of the relationship with the Supreme is today told by Me to you because you are My devotee as well as My friend and can therefore understand the transcendental mystery of this science.
Arjuna said: The sun-god Vivasvān is senior by birth to You. How am I to understand that in the beginning You instructed this science to him?
The Personality of Godhead said: Many, many births both you and I have passed. I can remember all of them, but you cannot, O subduer of the enemy!
Although I am unborn and My transcendental body never deteriorates, and although I am the Lord of all living entities, I still appear in every millennium in My original transcendental form.
Whenever and wherever there is a decline in religious practice, O descendant of Bharata, and a predominant rise of irreligion — at that time I descend Myself.
To deliver the pious and to annihilate the miscreants, as well as to reestablish the principles of religion, I Myself appear, millennium after millennium.
One who knows the transcendental nature of My appearance and activities does not, upon leaving the body, take his birth again in this material world, but attains My eternal abode, O Arjuna.
Being freed from attachment, fear and anger, being fully absorbed in Me and taking refuge in Me, many, many persons in the past became purified by knowledge of Me — and thus they all attained transcendental love for Me.
As all surrender unto Me, I reward them accordingly. Everyone follows My path in all respects, O son of Pṛthā.
Men in this world desire success in fruitive activities, and therefore they worship the demigods. Quickly, of course, men get results from fruitive work in this world.
According to the three modes of material nature and the work associated with them, the four divisions of human society are created by Me. And although I am the creator of this system, you should know that I am yet the nondoer, being unchangeable.
There is no work that affects Me; nor do I aspire for the fruits of action. One who understands this truth about Me also does not become entangled in the fruitive reactions of work.
All the liberated souls in ancient times acted with this understanding of My transcendental nature. Therefore you should perform your duty, following in their footsteps.
Even the intelligent are bewildered in determining what is action and what is inaction. Now I shall explain to you what action is, knowing which you shall be liberated from all misfortune.
The intricacies of action are very hard to understand. Therefore one should know properly what action is, what forbidden action is, and what inaction is.
One who sees inaction in action, and action in inaction, is intelligent among men, and he is in the transcendental position, although engaged in all sorts of activities.
One is understood to be in full knowledge whose every endeavor is devoid of desire for sense gratification. He is said by sages to be a worker for whom the reactions of work have been burned up by the fire of perfect knowledge.
Abandoning all attachment to the results of his activities, ever satisfied and independent, he performs no fruitive action, although engaged in all kinds of undertakings.
Such a man of understanding acts with mind and intelligence perfectly controlled, gives up all sense of proprietorship over his possessions, and acts only for the bare necessities of life. Thus working, he is not affected by sinful reactions.
He who is satisfied with gain which comes of its own accord, who is free from duality and does not envy, who is steady in both success and failure, is never entangled, although performing actions.
The work of a man who is unattached to the modes of material nature and who is fully situated in transcendental knowledge merges entirely into transcendence.
A person who is fully absorbed in Kṛṣṇa consciousness is sure to attain the spiritual kingdom because of his full contribution to spiritual activities, in which the consummation is absolute and that which is offered is of the same spiritual nature.
Some yogīs perfectly worship the demigods by offering different sacrifices to them, and some of them offer sacrifices in the fire of the Supreme Brahman.
Some [the unadulterated brahmacārīs] sacrifice the hearing process and the senses in the fire of mental control, and others [the regulated householders] sacrifice the objects of the senses in the fire of the senses.
Others, who are interested in achieving self-realization through control of the mind and senses, offer the functions of all the senses, and of the life breath, as oblations into the fire of the controlled mind.
Having accepted strict vows, some become enlightened by sacrificing their possessions, and others by performing severe austerities, by practicing the yoga of eightfold mysticism, or by studying the Vedas to advance in transcendental knowledge.
Still others, who are inclined to the process of breath restraint to remain in trance, practice by offering the movement of the outgoing breath into the incoming, and the incoming breath into the outgoing, and thus at last remain in trance, stopping all breathing. Others, curtailing the eating process, offer the outgoing breath into itself as a sacrifice.
All these performers who know the meaning of sacrifice become cleansed of sinful reactions, and, having tasted the nectar of the results of sacrifices, they advance toward the supreme eternal atmosphere.
O best of the Kuru dynasty, without sacrifice one can never live happily on this planet or in this life: what then of the next?
All these different types of sacrifice are approved by the Vedas, and all of them are born of different types of work. Knowing them as such, you will become liberated.
O chastiser of the enemy, the sacrifice performed in knowledge is better than the mere sacrifice of material possessions. After all, O son of Pṛthā, all sacrifices of work culminate in transcendental knowledge.
Just try to learn the truth by approaching a spiritual master. Inquire from him submissively and render service unto him. The self-realized souls can impart knowledge unto you because they have seen the truth.
Having obtained real knowledge from a self-realized soul, you will never fall again into such illusion, for by this knowledge you will see that all living beings are but part of the Supreme, or, in other words, that they are Mine.
Even if you are considered to be the most sinful of all sinners, when you are situated in the boat of transcendental knowledge you will be able to cross over the ocean of miseries.
As a blazing fire turns firewood to ashes, O Arjuna, so does the fire of knowledge burn to ashes all reactions to material activities.
In this world, there is nothing so sublime and pure as transcendental knowledge. Such knowledge is the mature fruit of all mysticism. And one who has become accomplished in the practice of devotional service enjoys this knowledge within himself in due course of time.
A faithful man who is dedicated to transcendental knowledge and who subdues his senses is eligible to achieve such knowledge, and having achieved it he quickly attains the supreme spiritual peace.
But ignorant and faithless persons who doubt the revealed scriptures do not attain God consciousness; they fall down. For the doubting soul there is happiness neither in this world nor in the next.
One who acts in devotional service, renouncing the fruits of his actions, and whose doubts have been destroyed by transcendental knowledge, is situated factually in the self. Thus he is not bound by the reactions of work, O conqueror of riches.
Therefore the doubts which have arisen in your heart out of ignorance should be slashed by the weapon of knowledge. Armed with yoga, O Bhārata, stand and fight.Arjuna said: O Kṛṣṇa, first of all You ask me to renounce work, and then again You recommend work with devotion. Now will You kindly tell me definitely which of the two is more beneficial?
The Personality of Godhead replied: The renunciation of work and work in devotion are both good for liberation. But, of the two, work in devotional service is better than renunciation of work.
One who neither hates nor desires the fruits of his activities is known to be always renounced. Such a person, free from all dualities, easily overcomes material bondage and is completely liberated, O mighty-armed Arjuna.
Only the ignorant speak of devotional service [karma-yoga] as being different from the analytical study of the material world [Sāńkhya]. Those who are actually learned say that he who applies himself well to one of these paths achieves the results of both.
One who knows that the position reached by means of analytical study can also be attained by devotional service, and who therefore sees analytical study and devotional service to be on the same level, sees things as they are.
Merely renouncing all activities yet not engaging in the devotional service of the Lord cannot make one happy. But a thoughtful person engaged in devotional service can achieve the Supreme without delay.
One who works in devotion, who is a pure soul, and who controls his mind and senses is dear to everyone, and everyone is dear to him. Though always working, such a man is never entangled.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
One who performs his duty without attachment, surrendering the results unto the Supreme Lord, is unaffected by sinful action, as the lotus leaf is untouched by water.
The yogīs, abandoning attachment, act with body, mind, intelligence and even with the senses, only for the purpose of purification.
The steadily devoted soul attains unadulterated peace because he offers the result of all activities to Me; whereas a person who is not in union with the Divine, who is greedy for the fruits of his labor, becomes entangled.
When the embodied living being controls his nature and mentally renounces all actions, he resides happily in the city of nine gates [the material body], neither working nor causing work to be done.
The embodied spirit, master of the city of his body, does not create activities, nor does he induce people to act, nor does he create the fruits of action. All this is enacted by the modes of material nature.
Nor does the Supreme Lord assume anyone's sinful or pious activities. Embodied beings, however, are bewildered because of the ignorance which covers their real knowledge.
When, however, one is enlightened with the knowledge by which nescience is destroyed, then his knowledge reveals everything, as the sun lights up everything in the daytime.
When one's intelligence, mind, faith and refuge are all fixed in the Supreme, then one becomes fully cleansed of misgivings through complete knowledge and thus proceeds straight on the path of liberation.
The humble sages, by virtue of true knowledge, see with equal vision a learned and gentle brāhmaṇa, a cow, an elephant, a dog and a dog-eater [outcaste].
Those whose minds are established in sameness and equanimity have already conquered the conditions of birth and death. They are flawless like Brahman, and thus they are already situated in Brahman.
A person who neither rejoices upon achieving something pleasant nor laments upon obtaining something unpleasant, who is self-intelligent, who is unbewildered, and who knows the science of God, is already situated in transcendence.
Such a liberated person is not attracted to material sense pleasure but is always in trance, enjoying the pleasure within. In this way the self-realized person enjoys unlimited happiness, for he concentrates on the Supreme.
An intelligent person does not take part in the sources of misery, which are due to contact with the material senses. O son of Kuntī, such pleasures have a beginning and an end, and so the wise man does not delight in them.
Before giving up this present body, if one is able to tolerate the urges of the material senses and check the force of desire and anger, he is well situated and is happy in this world.
One whose happiness is within, who is active and rejoices within, and whose aim is inward is actually the perfect mystic. He is liberated in the Supreme, and ultimately he attains the Supreme.
Those who are beyond the dualities that arise from doubts, whose minds are engaged within, who are always busy working for the welfare of all living beings, and who are free from all sins achieve liberation in the Supreme.
Those who are free from anger and all material desires, who are self-realized, self-disciplined and constantly endeavoring for perfection, are assured of liberation in the Supreme in the very near future.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
A person in full consciousness of Me, knowing Me to be the ultimate beneficiary of all sacrifices and austerities, the Supreme Lord of all planets and demigods, and the benefactor and well-wisher of all living entities, attains peace from the pangs of material miseries.The Supreme Personality of Godhead said: One who is unattached to the fruits of his work and who works as he is obligated is in the renounced order of life, and he is the true mystic, not he who lights no fire and performs no duty.
What is called renunciation you should know to be the same as yoga, or linking oneself with the Supreme, O son of Pāṇḍu, for one can never become a yogī unless he renounces the desire for sense gratification.
For one who is a neophyte in the eightfold yoga system, work is said to be the means; and for one who is already elevated in yoga, cessation of all material activities is said to be the means.
A person is said to be elevated in yoga when, having renounced all material desires, he neither acts for sense gratification nor engages in fruitive activities.
One must deliver himself with the help of his mind, and not degrade himself. The mind is the friend of the conditioned soul, and his enemy as well.
For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his mind will remain the greatest enemy.
For one who has conquered the mind, the Supersoul is already reached, for he has attained tranquillity. To such a man happiness and distress, heat and cold, honor and dishonor are all the same.
A person is said to be established in self-realization and is called a yogī [or mystic] when he is fully satisfied by virtue of acquired knowledge and realization. Such a person is situated in transcendence and is self-controlled. He sees everything — whether it be pebbles, stones or gold — as the same.
A person is considered still further advanced when he regards honest well-wishers, affectionate benefactors, the neutral, mediators, the envious, friends and enemies, the pious and the sinners all with an equal mind.
A transcendentalist should always engage his body, mind and self in relationship with the Supreme; he should live alone in a secluded place and should always carefully control his mind. He should be free from desires and feelings of possessiveness.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
Thus practicing constant control of the body, mind and activities, the mystic transcendentalist, his mind regulated, attains to the kingdom of God [or the abode of Kṛṣṇa] by cessation of material existence.
There is no possibility of one's becoming a yogī, O Arjuna, if one eats too much or eats too little, sleeps too much or does not sleep enough.
He who is regulated in his habits of eating, sleeping, recreation and work can mitigate all material pains by practicing the yoga system.
When the yogī, by practice of yoga, disciplines his mental activities and becomes situated in transcendence — devoid of all material desires — he is said to be well established in yoga.
As a lamp in a windless place does not waver, so the transcendentalist, whose mind is controlled, remains always steady in his meditation on the transcendent self.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
One should engage oneself in the practice of yoga with determination and faith and not be deviated from the path. One should abandon, without exception, all material desires born of mental speculation and thus control all the senses on all sides by the mind.
Gradually, step by step, one should become situated in trance by means of intelligence sustained by full conviction, and thus the mind should be fixed on the self alone and should think of nothing else.
From wherever the mind wanders due to its flickering and unsteady nature, one must certainly withdraw it and bring it back under the control of the self.
The yogī whose mind is fixed on Me verily attains the highest perfection of transcendental happiness. He is beyond the mode of passion, he realizes his qualitative identity with the Supreme, and thus he is freed from all reactions to past deeds.
Thus the self-controlled yogī, constantly engaged in yoga practice, becomes free from all material contamination and achieves the highest stage of perfect happiness in transcendental loving service to the Lord.
A true yogī observes Me in all beings and also sees every being in Me. Indeed, the self-realized person sees Me, the same Supreme Lord, everywhere.
For one who sees Me everywhere and sees everything in Me, I am never lost, nor is he ever lost to Me.
Such a yogī, who engages in the worshipful service of the Supersoul, knowing that I and the Supersoul are one, remains always in Me in all circumstances.
He is a perfect yogī who, by comparison to his own self, sees the true equality of all beings, in both their happiness and their distress, O Arjuna!
Arjuna said: O Madhusūdana, the system of yoga which You have summarized appears impractical and unendurable to me, for the mind is restless and unsteady.
For the mind is restless, turbulent, obstinate and very strong, O Kṛṣṇa, and to subdue it, I think, is more difficult than controlling the wind.
Lord Śrī Kṛṣṇa said: O mighty-armed son of Kuntī, it is undoubtedly very difficult to curb the restless mind, but it is possible by suitable practice and by detachment.
For one whose mind is unbridled, self-realization is difficult work. But he whose mind is controlled and who strives by appropriate means is assured of success. That is My opinion.
Arjuna said: O Kṛṣṇa, what is the destination of the unsuccessful transcendentalist, who in the beginning takes to the process of self-realization with faith but who later desists due to worldly-mindedness and thus does not attain perfection in mysticism?
O mighty-armed Kṛṣṇa, does not such a man, who is bewildered from the path of transcendence, fall away from both spiritual and material success and perish like a riven cloud, with no position in any sphere?
This is my doubt, O Kṛṣṇa, and I ask You to dispel it completely. But for You, no one is to be found who can destroy this doubt.
The Supreme Personality of Godhead said: Son of Pṛthā, a transcendentalist engaged in auspicious activities does not meet with destruction either in this world or in the spiritual world; one who does good, My friend, is never overcome by evil.
The unsuccessful yogī, after many, many years of enjoyment on the planets of the pious living entities, is born into a family of righteous people, or into a family of rich aristocracy.
Or [if unsuccessful after long practice of yoga] he takes his birth in a family of transcendentalists who are surely great in wisdom. Certainly, such a birth is rare in this world.
On taking such a birth, he revives the divine consciousness of his previous life, and he again tries to make further progress in order to achieve complete success, O son of Kuru.
By virtue of the divine consciousness of his previous life, he automatically becomes attracted to the yogic principles — even without seeking them. Such an inquisitive transcendentalist stands always above the ritualistic principles of the scriptures.
And when the yogī engages himself with sincere endeavor in making further progress, being washed of all contaminations, then ultimately, achieving perfection after many, many births of practice, he attains the supreme goal.
A yogī is greater than the ascetic, greater than the empiricist and greater than the fruitive worker. Therefore, O Arjuna, in all circumstances, be a yogī.
And of all yogīs, the one with great faith who always abides in Me, thinks of Me within himself, and renders transcendental loving service to Me — he is the most intimately united with Me in yoga and is the highest of all. That is My opinion.The Supreme Personality of Godhead said: Now hear, O son of Pṛthā, how by practicing yoga in full consciousness of Me, with mind attached to Me, you can know Me in full, free from doubt.
I shall now declare unto you in full this knowledge, both phenomenal and numinous. This being known, nothing further shall remain for you to know.
Out of many thousands among men, one may endeavor for perfection, and of those who have achieved perfection, hardly one knows Me in truth.
Earth, water, fire, air, ether, mind, intelligence and false ego — all together these eight constitute My separated material energies.
Besides these, O mighty-armed Arjuna, there is another, superior energy of Mine, which comprises the living entities who are exploiting the resources of this material, inferior nature.
All created beings have their source in these two natures. Of all that is material and all that is spiritual in this world, know for certain that I am both the origin and the dissolution.
O conqueror of wealth, there is no truth superior to Me. Everything rests upon Me, as pearls are strung on a thread.
O son of Kuntī, I am the taste of water, the light of the sun and the moon, the syllable oḿ in the Vedic mantras; I am the sound in ether and ability in man.
I am the original fragrance of the earth, and I am the heat in fire. I am the life of all that lives, and I am the penances of all ascetics.
O son of Pṛthā, know that I am the original seed of all existences, the intelligence of the intelligent, and the prowess of all powerful men.
I am the strength of the strong, devoid of passion and desire. I am sex life which is not contrary to religious principles, O lord of the Bhāratas [Arjuna].
Know that all states of being — be they of goodness, passion or ignorance — are manifested by My energy. I am, in one sense, everything, but I am independent. I am not under the modes of material nature, for they, on the contrary, are within Me.
Deluded by the three modes [goodness, passion and ignorance], the whole world does not know Me, who am above the modes and inexhaustible.
This divine energy of Mine, consisting of the three modes of material nature, is difficult to overcome. But those who have surrendered unto Me can easily cross beyond it.
Those miscreants who are grossly foolish, who are lowest among mankind, whose knowledge is stolen by illusion, and who partake of the atheistic nature of demons do not surrender unto Me.
O best among the Bhāratas, four kinds of pious men begin to render devotional service unto Me — the distressed, the desirer of wealth, the inquisitive, and he who is searching for knowledge of the Absolute.
Of these, the one who is in full knowledge and who is always engaged in pure devotional service is the best. For I am very dear to him, and he is dear to Me.
All these devotees are undoubtedly magnanimous souls, but he who is situated in knowledge of Me I consider to be just like My own self. Being engaged in My transcendental service, he is sure to attain Me, the highest and most perfect goal.
After many births and deaths, he who is actually in knowledge surrenders unto Me, knowing Me to be the cause of all causes and all that is. Such a great soul is very rare.
Those whose intelligence has been stolen by material desires surrender unto demigods and follow the particular rules and regulations of worship according to their own natures.
I am in everyone's heart as the Supersoul. As soon as one desires to worship some demigod, I make his faith steady so that he can devote himself to that particular deity.
Endowed with such a faith, he endeavors to worship a particular demigod and obtains his desires. But in actuality these benefits are bestowed by Me alone.
Men of small intelligence worship the demigods, and their fruits are limited and temporary. Those who worship the demigods go to the planets of the demigods, but My devotees ultimately reach My supreme planet.
Unintelligent men, who do not know Me perfectly, think that I, the Supreme Personality of Godhead, Kṛṣṇa, was impersonal before and have now assumed this personality. Due to their small knowledge, they do not know My higher nature, which is imperishable and supreme.
I am never manifest to the foolish and unintelligent. For them I am covered by My internal potency, and therefore they do not know that I am unborn and infallible.
O Arjuna, as the Supreme Personality of Godhead, I know everything that has happened in the past, all that is happening in the present, and all things that are yet to come. I also know all living entities; but Me no one knows.
O scion of Bharata, O conqueror of the foe, all living entities are born into delusion, bewildered by dualities arisen from desire and hate.
Persons who have acted piously in previous lives and in this life and whose sinful actions are completely eradicated are freed from the dualities of delusion, and they engage themselves in My service with determination.
Intelligent persons who are endeavoring for liberation from old age and death take refuge in Me in devotional service. They are actually Brahman because they entirely know everything about transcendental activities.
Those in full consciousness of Me, who know Me, the Supreme Lord, to be the governing principle of the material manifestation, of the demigods, and of all methods of sacrifice, can understand and know Me, the Supreme Personality of Godhead, even at the time of death.Arjuna inquired: O my Lord, O Supreme Person, what is Brahman? What is the self? What are fruitive activities? What is this material manifestation? And what are the demigods? Please explain this to me.
Who is the Lord of sacrifice, and how does He live in the body, O Madhusūdana? And how can those engaged in devotional service know You at the time of death?
The Supreme Personality of Godhead said: The indestructible, transcendental living entity is called Brahman, and his eternal nature is called adhyātma, the self. Action pertaining to the development of the material bodies of the living entities is called karma, or fruitive activities.
O best of the embodied beings, the physical nature, which is constantly changing, is called adhibhūta [the material manifestation]. The universal form of the Lord, which includes all the demigods, like those of the sun and moon, is called adhidaiva. And I, the Supreme Lord, represented as the Supersoul in the heart of every embodied being, am called adhiyajña [the Lord of sacrifice].
And whoever, at the end of his life, quits his body, remembering Me alone, at once attains My nature. Of this there is no doubt.
Whatever state of being one remembers when he quits his body, O son of Kuntī, that state he will attain without fail.
Therefore, Arjuna, you should always think of Me in the form of Kṛṣṇa and at the same time carry out your prescribed duty of fighting. With your activities dedicated to Me and your mind and intelligence fixed on Me, you will attain Me without doubt.
He who meditates on Me as the Supreme Personality of Godhead, his mind constantly engaged in remembering Me, undeviated from the path, he, O Pārtha, is sure to reach Me.
One should meditate upon the Supreme Person as the one who knows everything, as He who is the oldest, who is the controller, who is smaller than the smallest, who is the maintainer of everything, who is beyond all material conception, who is inconceivable, and who is always a person. He is luminous like the sun, and He is transcendental, beyond this material nature.
One who, at the time of death, fixes his life air between the eyebrows and, by the strength of yoga, with an undeviating mind, engages himself in remembering the Supreme Lord in full devotion, will certainly attain to the Supreme Personality of Godhead.
Persons who are learned in the Vedas, who utter oḿkāra and who are great sages in the renounced order enter into Brahman. Desiring such perfection, one practices celibacy. I shall now briefly explain to you this process by which one may attain salvation.
The yogic situation is that of detachment from all sensual engagements. Closing all the doors of the senses and fixing the mind on the heart and the life air at the top of the head, one establishes himself in yoga.
After being situated in this yoga practice and vibrating the sacred syllable oḿ, the supreme combination of letters, if one thinks of the Supreme Personality of Godhead and quits his body, he will certainly reach the spiritual planets.
For one who always remembers Me without deviation, I am easy to obtain, O son of Pṛthā, because of his constant engagement in devotional service.
After attaining Me, the great souls, who are yogīs in devotion, never return to this temporary world, which is full of miseries, because they have attained the highest perfection.
From the highest planet in the material world down to the lowest, all are places of misery wherein repeated birth and death take place. But one who attains to My abode, O son of Kuntī, never takes birth again.
By human calculation, a thousand ages taken together form the duration of Brahmā's one day. And such also is the duration of his night.
At the beginning of Brahmā's day, all living entities become manifest from the unmanifest state, and thereafter, when the night falls, they are merged into the unmanifest again.
Again and again, when Brahmā's day arrives, all living entities come into being, and with the arrival of Brahmā's night they are helplessly annihilated.
Yet there is another unmanifest nature, which is eternal and is transcendental to this manifested and unmanifested matter. It is supreme and is never annihilated. When all in this world is annihilated, that part remains as it is.
That which the Vedāntists describe as unmanifest and infallible, that which is known as the supreme destination, that place from which, having attained it, one never returns — that is My supreme abode.
The Supreme Personality of Godhead, who is greater than all, is attainable by unalloyed devotion. Although He is present in His abode, He is all-pervading, and everything is situated within Him.
O best of the Bhāratas, I shall now explain to you the different times at which, passing away from this world, the yogī does or does not come back.
Those who know the Supreme Brahman attain that Supreme by passing away from the world during the influence of the fiery god, in the light, at an auspicious moment of the day, during the fortnight of the waxing moon, or during the six months when the sun travels in the north.
The mystic who passes away from this world during the smoke, the night, the fortnight of the waning moon, or the six months when the sun passes to the south reaches the moon planet but again comes back.
According to Vedic opinion, there are two ways of passing from this world — one in light and one in darkness. When one passes in light, he does not come back; but when one passes in darkness, he returns.
Although the devotees know these two paths, O Arjuna, they are never bewildered. Therefore be always fixed in devotion.
A person who accepts the path of devotional service is not bereft of the results derived from studying the Vedas, performing austere sacrifices, giving charity or pursuing philosophical and fruitive activities. Simply by performing devotional service, he attains all these, and at the end he reaches the supreme eternal abode.The Supreme Personality of Godhead said: My dear Arjuna, because you are never envious of Me, I shall impart to you this most confidential knowledge and realization, knowing which you shall be relieved of the miseries of material existence.
This knowledge is the king of education, the most secret of all secrets. It is the purest knowledge, and because it gives direct perception of the self by realization, it is the perfection of religion. It is everlasting, and it is joyfully performed.
Those who are not faithful in this devotional service cannot attain Me, O conqueror of enemies. Therefore they return to the path of birth and death in this material world.
By Me, in My unmanifested form, this entire universe is pervaded. All beings are in Me, but I am not in them.
And yet everything that is created does not rest in Me. Behold My mystic opulence! Although I am the maintainer of all living entities and although I am everywhere, I am not a part of this cosmic manifestation, for My Self is the very source of creation.
Understand that as the mighty wind, blowing everywhere, rests always in the sky, all created beings rest in Me.
O son of Kuntī, at the end of the millennium all material manifestations enter into My nature, and at the beginning of another millennium, by My potency, I create them again.
The whole cosmic order is under Me. Under My will it is automatically manifested again and again, and under My will it is annihilated at the end.
O Dhanañjaya, all this work cannot bind Me. I am ever detached from all these material activities, seated as though neutral.
This material nature, which is one of My energies, is working under My direction, O son of Kuntī, producing all moving and nonmoving beings. Under its rule this manifestation is created and annihilated again and again.
Fools deride Me when I descend in the human form. They do not know My transcendental nature as the Supreme Lord of all that be.
Those who are thus bewildered are attracted by demonic and atheistic views. In that deluded condition, their hopes for liberation, their fruitive activities, and their culture of knowledge are all defeated.
O son of Pṛthā, those who are not deluded, the great souls, are under the protection of the divine nature. They are fully engaged in devotional service because they know Me as the Supreme Personality of Godhead, original and inexhaustible.
Always chanting My glories, endeavoring with great determination, bowing down before Me, these great souls perpetually worship Me with devotion.
Others, who engage in sacrifice by the cultivation of knowledge, worship the Supreme Lord as the one without a second, as diverse in many, and in the universal form.
But it is I who am the ritual, I the sacrifice, the offering to the ancestors, the healing herb, the transcendental chant. I am the butter and the fire and the offering.
I am the father of this universe, the mother, the support and the grandsire. I am the object of knowledge, the purifier and the syllable oḿ. I am also the Ṛg, the Sāma and the Yajur Vedas.
I am the goal, the sustainer, the master, the witness, the abode, the refuge, and the most dear friend. I am the creation and the annihilation, the basis of everything, the resting place and the eternal seed.
O Arjuna, I give heat, and I withhold and send forth the rain. I am immortality, and I am also death personified. Both spirit and matter are in Me.
Those who study the Vedas and drink the soma juice, seeking the heavenly planets, worship Me indirectly. Purified of sinful reactions, they take birth on the pious, heavenly planet of Indra, where they enjoy godly delights.
When they have thus enjoyed vast heavenly sense pleasure and the results of their pious activities are exhausted, they return to this mortal planet again. Thus those who seek sense enjoyment by adhering to the principles of the three Vedas achieve only repeated birth and death.
But those who always worship Me with exclusive devotion, meditating on My transcendental form — to them I carry what they lack, and I preserve what they have.
Those who are devotees of other gods and who worship them with faith actually worship only Me, O son of Kuntī, but they do so in a wrong way.
I am the only enjoyer and master of all sacrifices. Therefore, those who do not recognize My true transcendental nature fall down.
Those who worship the demigods will take birth among the demigods; those who worship the ancestors go to the ancestors; those who worship ghosts and spirits will take birth among such beings; and those who worship Me will live with Me.
If one offers Me with love and devotion a leaf, a flower, fruit or water, I will accept it.
Whatever you do, whatever you eat, whatever you offer or give away, and whatever austerities you perform — do that, O son of Kuntī, as an offering to Me.
In this way you will be freed from bondage to work and its auspicious and inauspicious results. With your mind fixed on Me in this principle of renunciation, you will be liberated and come to Me.
I envy no one, nor am I partial to anyone. I am equal to all. But whoever renders service unto Me in devotion is a friend, is in Me, and I am also a friend to him.
Even if one commits the most abominable action, if he is engaged in devotional service he is to be considered saintly because he is properly situated in his determination.
He quickly becomes righteous and attains lasting peace. O son of Kuntī, declare it boldly that My devotee never perishes.
O son of Pṛthā, those who take shelter in Me, though they be of lower birth — women, vaiśyas [merchants] and śūdras [workers] — can attain the supreme destination.
How much more this is so of the righteous brāhmaṇas, the devotees and the saintly kings. Therefore, having come to this temporary, miserable world, engage in loving service unto Me.
Engage your mind always in thinking of Me, become My devotee, offer obeisances to Me and worship Me. Being completely absorbed in Me, surely you will come to Me.The Supreme Personality of Godhead said: Listen again, O mighty-armed Arjuna. Because you are My dear friend, for your benefit I shall speak to you further, giving knowledge that is better than what I have already explained.
Neither the hosts of demigods nor the great sages know My origin or opulences, for, in every respect, I am the source of the demigods and sages.
He who knows Me as the unborn, as the beginningless, as the Supreme Lord of all the worlds — he only, undeluded among men, is freed from all sins.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
The seven great sages and before them the four other great sages and the Manus [progenitors of mankind] come from Me, born from My mind, and all the living beings populating the various planets descend from them.
One who is factually convinced of this opulence and mystic power of Mine engages in unalloyed devotional service; of this there is no doubt.
I am the source of all spiritual and material worlds. Everything emanates from Me. The wise who perfectly know this engage in My devotional service and worship Me with all their hearts.
The thoughts of My pure devotees dwell in Me, their lives are fully devoted to My service, and they derive great satisfaction and bliss from always enlightening one another and conversing about Me.
To those who are constantly devoted to serving Me with love, I give the understanding by which they can come to Me.
To show them special mercy, I, dwelling in their hearts, destroy with the shining lamp of knowledge the darkness born of ignorance.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
O Kṛṣṇa, I totally accept as truth all that You have told me. Neither the demigods nor the demons, O Lord, can understand Your personality.
Indeed, You alone know Yourself by Your own internal potency, O Supreme Person, origin of all, Lord of all beings, God of gods, Lord of the universe!
Please tell me in detail of Your divine opulences by which You pervade all these worlds.
O Kṛṣṇa, O supreme mystic, how shall I constantly think of You, and how shall I know You? In what various forms are You to be remembered, O Supreme Personality of Godhead?
O Janārdana, again please describe in detail the mystic power of Your opulences. I am never satiated in hearing about You, for the more I hear the more I want to taste the nectar of Your words.
The Supreme Personality of Godhead said: Yes, I will tell you of My splendorous manifestations, but only of those which are prominent, O Arjuna, for My opulence is limitless.
I am the Supersoul, O Arjuna, seated in the hearts of all living entities. I am the beginning, the middle and the end of all beings.
Of the Ādityas I am Viṣṇu, of lights I am the radiant sun, of the Maruts I am Marīci, and among the stars I am the moon.
Of the Vedas I am the Sāma Veda; of the demigods I am Indra, the king of heaven; of the senses I am the mind; and in living beings I am the living force [consciousness].
Of all the Rudras I am Lord Śiva, of the Yakṣas and Rākṣasas I am the Lord of wealth [Kuvera], of the Vasus I am fire [Agni], and of mountains I am Meru.
Of priests, O Arjuna, know Me to be the chief, Bṛhaspati. Of generals I am Kārtikeya, and of bodies of water I am the ocean.
Of the great sages I am Bhṛgu; of vibrations I am the transcendental oḿ. Of sacrifices I am the chanting of the holy names [japa], and of immovable things I am the Himālayas.
Of all trees I am the banyan tree, and of the sages among the demigods I am Nārada. Of the Gandharvas I am Citraratha, and among perfected beings I am the sage Kapila.
Of horses know Me to be Uccaiḥśravā, produced during the churning of the ocean for nectar. Of lordly elephants I am Airāvata, and among men I am the monarch.
Of weapons I am the thunderbolt; among cows I am the surabhi. Of causes for procreation I am Kandarpa, the god of love, and of serpents I am Vāsuki.
Of the many-hooded Nāgas I am Ananta, and among the aquatics I am the demigod Varuṇa. Of departed ancestors I am Aryamā, and among the dispensers of law I am Yama, the lord of death.
Among the Daitya demons I am the devoted Prahlāda, among subduers I am time, among beasts I am the lion, and among birds I am Garuḍa.
Of purifiers I am the wind, of the wielders of weapons I am Rāma, of fishes I am the shark, and of flowing rivers I am the Ganges.
Of all creations I am the beginning and the end and also the middle, O Arjuna. Of all sciences I am the spiritual science of the self, and among logicians I am the conclusive truth.
Of letters I am the letter A, and among compound words I am the dual compound. I am also inexhaustible time, and of creators I am Brahmā.
I am all-devouring death, and I am the generating principle of all that is yet to be. Among women I am fame, fortune, fine speech, memory, intelligence, steadfastness and patience.
Of the hymns in the Sāma Veda I am the Bṛhat-sāma, and of poetry I am the Gāyatrī. Of months I am Mārgaśīrṣa [November-December], and of seasons I am flower-bearing spring.
I am also the gambling of cheats, and of the splendid I am the splendor. I am victory, I am adventure, and I am the strength of the strong.
Of the descendants of Vṛṣṇi I am Vāsudeva, and of the Pāṇḍavas I am Arjuna. Of the sages I am Vyāsa, and among great thinkers I am Uśanā.
Among all means of suppressing lawlessness I am punishment, and of those who seek victory I am morality. Of secret things I am silence, and of the wise I am the wisdom.
Furthermore, O Arjuna, I am the generating seed of all existences. There is no being — moving or nonmoving — that can exist without Me.
O mighty conqueror of enemies, there is no end to My divine manifestations. What I have spoken to you is but a mere indication of My infinite opulences.
Know that all opulent, beautiful and glorious creations spring from but a spark of My splendor.
But what need is there, Arjuna, for all this detailed knowledge? With a single fragment of Myself I pervade and support this entire universe.Arjuna said: By my hearing the instructions You have kindly given me about these most confidential spiritual subjects, my illusion has now been dispelled.
O lotus-eyed one, I have heard from You in detail about the appearance and disappearance of every living entity and have realized Your inexhaustible glories.
O greatest of all personalities, O supreme form, though I see You here before me in Your actual position, as You have described Yourself, I wish to see how You have entered into this cosmic manifestation. I want to see that form of Yours.
If You think that I am able to behold Your cosmic form, O my Lord, O master of all mystic power, then kindly show me that unlimited universal Self.
The Supreme Personality of Godhead said: My dear Arjuna, O son of Pṛthā, see now My opulences, hundreds of thousands of varied divine and multicolored forms.
O best of the Bhāratas, see here the different manifestations of Ādityas, Vasus, Rudras, Aśvinī-kumāras and all the other demigods. Behold the many wonderful things which no one has ever seen or heard of before.
O Arjuna, whatever you wish to see, behold at once in this body of Mine! This universal form can show you whatever you now desire to see and whatever you may want to see in the future. Everything — moving and nonmoving — is here completely, in one place.
But you cannot see Me with your present eyes. Therefore I give you divine eyes. Behold My mystic opulence!
Sañjaya said: O King, having spoken thus, the Supreme Lord of all mystic power, the Personality of Godhead, displayed His universal form to Arjuna.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
If hundreds of thousands of suns were to rise at once into the sky, their radiance might resemble the effulgence of the Supreme Person in that universal form.
At that time Arjuna could see in the universal form of the Lord the unlimited expansions of the universe situated in one place although divided into many, many thousands.
Then, bewildered and astonished, his hair standing on end, Arjuna bowed his head to offer obeisances and with folded hands began to pray to the Supreme Lord.
Arjuna said: My dear Lord Kṛṣṇa, I see assembled in Your body all the demigods and various other living entities. I see Brahmā sitting on the lotus flower, as well as Lord Śiva and all the sages and divine serpents.
O Lord of the universe, O universal form, I see in Your body many, many arms, bellies, mouths and eyes, expanded everywhere, without limit. I see in You no end, no middle and no beginning.
Your form is difficult to see because of its glaring effulgence, spreading on all sides, like blazing fire or the immeasurable radiance of the sun. Yet I see this glowing form everywhere, adorned with various crowns, clubs and discs.
You are the supreme primal objective. You are the ultimate resting place of all this universe. You are inexhaustible, and You are the oldest. You are the maintainer of the eternal religion, the Personality of Godhead. This is my opinion.
You are without origin, middle or end. Your glory is unlimited. You have numberless arms, and the sun and moon are Your eyes. I see You with blazing fire coming forth from Your mouth, burning this entire universe by Your own radiance.
Although You are one, You spread throughout the sky and the planets and all space between. O great one, seeing this wondrous and terrible form, all the planetary systems are perturbed.
All the hosts of demigods are surrendering before You and entering into You. Some of them, very much afraid, are offering prayers with folded hands. Hosts of great sages and perfected beings, crying "All peace!" are praying to You by singing the Vedic hymns.
All the various manifestations of Lord Śiva, the Ādityas, the Vasus, the Sādhyas, the Viśvedevas, the two Aśvīs, the Maruts, the forefathers, the Gandharvas, the Yakṣas, the Asuras and the perfected demigods are beholding You in wonder.
O mighty-armed one, all the planets with their demigods are disturbed at seeing Your great form, with its many faces, eyes, arms, thighs, legs, and bellies and Your many terrible teeth; and as they are disturbed, so am I.
O all-pervading Viṣṇu, seeing You with Your many radiant colors touching the sky, Your gaping mouths, and Your great glowing eyes, my mind is perturbed by fear. I can no longer maintain my steadiness or equilibrium of mind.
O Lord of lords, O refuge of the worlds, please be gracious to me. I cannot keep my balance seeing thus Your blazing deathlike faces and awful teeth. In all directions I am bewildered.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
As the many waves of the rivers flow into the ocean, so do all these great warriors enter blazing into Your mouths.
I see all people rushing full speed into Your mouths, as moths dash to destruction in a blazing fire.
O Viṣṇu, I see You devouring all people from all sides with Your flaming mouths. Covering all the universe with Your effulgence, You are manifest with terrible, scorching rays.
O Lord of lords, so fierce of form, please tell me who You are. I offer my obeisances unto You; please be gracious to me. You are the primal Lord. I want to know about You, for I do not know what Your mission is.
The Supreme Personality of Godhead said: Time I am, the great destroyer of the worlds, and I have come here to destroy all people. With the exception of you [the Pāṇḍavas], all the soldiers here on both sides will be slain.
Therefore get up. Prepare to fight and win glory. Conquer your enemies and enjoy a flourishing kingdom. They are already put to death by My arrangement, and you, O Savyasācī, can be but an instrument in the fight.
Droṇa, Bhīṣma, Jayadratha, Karṇa and the other great warriors have already been destroyed by Me. Therefore, kill them and do not be disturbed. Simply fight, and you will vanquish your enemies in battle.
Sañjaya said to Dhṛtarāṣṭra: O King, after hearing these words from the Supreme Personality of Godhead, the trembling Arjuna offered obeisances with folded hands again and again. He fearfully spoke to Lord Kṛṣṇa in a faltering voice, as follows.
Arjuna said: O master of the senses, the world becomes joyful upon hearing Your name, and thus everyone becomes attached to You. Although the perfected beings offer You their respectful homage, the demons are afraid, and they flee here and there. All this is rightly done.
O great one, greater even than Brahmā, You are the original creator. Why then should they not offer their respectful obeisances unto You? O limitless one, God of gods, refuge of the universe! You are the invincible source, the cause of all causes, transcendental to this material manifestation.
You are the original Personality of Godhead, the oldest, the ultimate sanctuary of this manifested cosmic world. You are the knower of everything, and You are all that is knowable. You are the supreme refuge, above the material modes. O limitless form! This whole cosmic manifestation is pervaded by You!
You are air, and You are the supreme controller! You are fire, You are water, and You are the moon! You are Brahmā, the first living creature, and You are the great-grandfather. I therefore offer my respectful obeisances unto You a thousand times, and again and yet again!
Obeisances to You from the front, from behind and from all sides! O unbounded power, You are the master of limitless might! You are all-pervading, and thus You are everything!
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
You are the father of this complete cosmic manifestation, of the moving and the nonmoving. You are its worshipable chief, the supreme spiritual master. No one is equal to You, nor can anyone be one with You. How then could there be anyone greater than You within the three worlds, O Lord of immeasurable power?
You are the Supreme Lord, to be worshiped by every living being. Thus I fall down to offer You my respectful obeisances and ask Your mercy. As a father tolerates the impudence of his son, or a friend tolerates the impertinence of a friend, or a wife tolerates the familiarity of her partner, please tolerate the wrongs I may have done You.
After seeing this universal form, which I have never seen before, I am gladdened, but at the same time my mind is disturbed with fear. Therefore please bestow Your grace upon me and reveal again Your form as the Personality of Godhead, O Lord of lords, O abode of the universe.
O universal form, O thousand-armed Lord, I wish to see You in Your four-armed form, with helmeted head and with club, wheel, conch and lotus flower in Your hands. I long to see You in that form.
The Supreme Personality of Godhead said: My dear Arjuna, happily have I shown you, by My internal potency, this supreme universal form within the material world. No one before you has ever seen this primal form, unlimited and full of glaring effulgence.
O best of the Kuru warriors, no one before you has ever seen this universal form of Mine, for neither by studying the Vedas, nor by performing sacrifices, nor by charity, nor by pious activities, nor by severe penances can I be seen in this form in the material world.
You have been perturbed and bewildered by seeing this horrible feature of Mine. Now let it be finished. My devotee, be free again from all disturbances. With a peaceful mind you can now see the form you desire.
Sañjaya said to Dhṛtarāṣṭra: The Supreme Personality of Godhead, Kṛṣṇa, having spoken thus to Arjuna, displayed His real four-armed form and at last showed His two-armed form, thus encouraging the fearful Arjuna.
When Arjuna thus saw Kṛṣṇa in His original form, he said: O Janārdana, seeing this humanlike form, so very beautiful, I am now composed in mind, and I am restored to my original nature.
The Supreme Personality of Godhead said: My dear Arjuna, this form of Mine you are now seeing is very difficult to behold. Even the demigods are ever seeking the opportunity to see this form, which is so dear.
The form you are seeing with your transcendental eyes cannot be understood simply by studying the Vedas, nor by undergoing serious penances, nor by charity, nor by worship. It is not by these means that one can see Me as I am.
My dear Arjuna, only by undivided devotional service can I be understood as I am, standing before you, and can thus be seen directly. Only in this way can you enter into the mysteries of My understanding.
My dear Arjuna, he who engages in My pure devotional service, free from the contaminations of fruitive activities and mental speculation, he who works for Me, who makes Me the supreme goal of his life, and who is friendly to every living being — he certainly comes to Me.Arjuna inquired: Which are considered to be more perfect, those who are always properly engaged in Your devotional service or those who worship the impersonal Brahman, the unmanifested? 
The Supreme Personality of Godhead said: Those who fix their minds on My personal form and are always engaged in worshiping Me with great and transcendental faith are considered by Me to be most perfect. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
For those whose minds are attached to the unmanifested, impersonal feature of the Supreme, advancement is very troublesome. To make progress in that discipline is always difficult for those who are embodied. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
Just fix your mind upon Me, the Supreme Personality of Godhead, and engage all your intelligence in Me. Thus you will live in Me always, without a doubt. 
My dear Arjuna, O winner of wealth, if you cannot fix your mind upon Me without deviation, then follow the regulative principles of bhakti-yoga. In this way develop a desire to attain Me. 
If you cannot practice the regulations of bhakti-yoga, then just try to work for Me, because by working for Me you will come to the perfect stage. 
If, however, you are unable to work in this consciousness of Me, then try to act giving up all results of your work and try to be self- situated. 
If you cannot take to this practice, then engage yourself in the cultivation of knowledge. Better than knowledge, however, is meditation, and better than meditation is renunciation of the fruits of action, for by such renunciation one can attain peace of mind. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
He for whom no one is put into difficulty and who is not disturbed by anyone, who is equipoised in happiness and distress, fear and anxiety, is very dear to Me. 
My devotee who is not dependent on the ordinary course of activities, who is pure, expert, without cares, free from all pains, and not striving for some result, is very dear to Me. 
One who neither rejoices nor grieves, who neither laments nor desires, and who renounces both auspicious and inauspicious things — such a devotee is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
Those who follow this imperishable path of devotional service and who completely engage themselves with faith, making Me the supreme goal, are very, very dear to Me.Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
O scion of Bharata, you should understand that I am also the knower in all bodies, and to understand this body and its knower is called knowledge. That is My opinion.
Now please hear My brief description of this field of activity and how it is constituted, what its changes are, whence it is produced, who that knower of the field of activities is, and what his influences are.
That knowledge of the field of activities and of the knower of activities is described by various sages in various Vedic writings. It is especially presented in Vedānta-sūtra with all reasoning as to cause and effect.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
I shall now explain the knowable, knowing which you will taste the eternal. Brahman, the spirit, beginningless and subordinate to Me, lies beyond the cause and effect of this material world.
Everywhere are His hands and legs, His eyes, heads and faces, and He has ears everywhere. In this way the Supersoul exists, pervading everything.
The Supersoul is the original source of all senses, yet He is without senses. He is unattached, although He is the maintainer of all living beings. He transcends the modes of nature, and at the same time He is the master of all the modes of material nature.
The Supreme Truth exists outside and inside of all living beings, the moving and the nonmoving. Because He is subtle, He is beyond the power of the material senses to see or to know. Although far, far away, He is also near to all.
Although the Supersoul appears to be divided among all beings, He is never divided. He is situated as one. Although He is the maintainer of every living entity, it is to be understood that He devours and develops all.
He is the source of light in all luminous objects. He is beyond the darkness of matter and is unmanifested. He is knowledge, He is the object of knowledge, and He is the goal of knowledge. He is situated in everyone's heart.
Thus the field of activities [the body], knowledge and the knowable have been summarily described by Me. Only My devotees can understand this thoroughly and thus attain to My nature.
Material nature and the living entities should be understood to be beginningless. Their transformations and the modes of matter are products of material nature.
Nature is said to be the cause of all material causes and effects, whereas the living entity is the cause of the various sufferings and enjoyments in this world.
The living entity in material nature thus follows the ways of life, enjoying the three modes of nature. This is due to his association with that material nature. Thus he meets with good and evil among various species.
Yet in this body there is another, a transcendental enjoyer, who is the Lord, the supreme proprietor, who exists as the overseer and permitter, and who is known as the Supersoul.
One who understands this philosophy concerning material nature, the living entity and the interaction of the modes of nature is sure to attain liberation. He will not take birth here again, regardless of his present position.
Some perceive the Supersoul within themselves through meditation, others through the cultivation of knowledge, and still others through working without fruitive desires.
Again there are those who, although not conversant in spiritual knowledge, begin to worship the Supreme Person upon hearing about Him from others. Because of their tendency to hear from authorities, they also transcend the path of birth and death.
O chief of the Bhāratas, know that whatever you see in existence, both the moving and the nonmoving, is only a combination of the field of activities and the knower of the field.
One who sees the Supersoul accompanying the individual soul in all bodies, and who understands that neither the soul nor the Supersoul within the destructible body is ever destroyed, actually sees.
One who sees the Supersoul equally present everywhere, in every living being, does not degrade himself by his mind. Thus he approaches the transcendental destination.
One who can see that all activities are performed by the body, which is created of material nature, and sees that the self does nothing, actually sees.
When a sensible man ceases to see different identities due to different material bodies and he sees how beings are expanded everywhere, he attains to the Brahman conception.
Those with the vision of eternity can see that the imperishable soul is transcendental, eternal, and beyond the modes of nature. Despite contact with the material body, O Arjuna, the soul neither does anything nor is entangled.
The sky, due to its subtle nature, does not mix with anything, although it is all-pervading. Similarly, the soul situated in Brahman vision does not mix with the body, though situated in that body.
O son of Bharata, as the sun alone illuminates all this universe, so does the living entity, one within the body, illuminate the entire body by consciousness.
Those who see with eyes of knowledge the difference between the body and the knower of the body, and can also understand the process of liberation from bondage in material nature, attain to the supreme goal.The Supreme Personality of Godhead said: Again I shall declare to you this supreme wisdom, the best of all knowledge, knowing which all the sages have attained the supreme perfection.
By becoming fixed in this knowledge, one can attain to the transcendental nature like My own. Thus established, one is not born at the time of creation or disturbed at the time of dissolution.
The total material substance, called Brahman, is the source of birth, and it is that Brahman that I impregnate, making possible the births of all living beings, O son of Bharata.
It should be understood that all species of life, O son of Kuntī, are made possible by birth in this material nature, and that I am the seed-giving father.
Material nature consists of three modes — goodness, passion and ignorance. When the eternal living entity comes in contact with nature, O mighty-armed Arjuna, he becomes conditioned by these modes.
O sinless one, the mode of goodness, being purer than the others, is illuminating, and it frees one from all sinful reactions. Those situated in that mode become conditioned by a sense of happiness and knowledge.
The mode of passion is born of unlimited desires and longings, O son of Kuntī, and because of this the embodied living entity is bound to material fruitive actions.
O son of Bharata, know that the mode of darkness, born of ignorance, is the delusion of all embodied living entities. The results of this mode are madness, indolence and sleep, which bind the conditioned soul.
O son of Bharata, the mode of goodness conditions one to happiness; passion conditions one to fruitive action; and ignorance, covering one's knowledge, binds one to madness.
Sometimes the mode of goodness becomes prominent, defeating the modes of passion and ignorance, O son of Bharata. Sometimes the mode of passion defeats goodness and ignorance, and at other times ignorance defeats goodness and passion. In this way there is always competition for supremacy.
The manifestations of the mode of goodness can be experienced when all the gates of the body are illuminated by knowledge.
O chief of the Bhāratas, when there is an increase in the mode of passion the symptoms of great attachment, fruitive activity, intense endeavor, and uncontrollable desire and hankering develop.
When there is an increase in the mode of ignorance, O son of Kuru, darkness, inertia, madness and illusion are manifested.
When one dies in the mode of goodness, he attains to the pure higher planets of the great sages.
When one dies in the mode of passion, he takes birth among those engaged in fruitive activities; and when one dies in the mode of ignorance, he takes birth in the animal kingdom.
The result of pious action is pure and is said to be in the mode of goodness. But action done in the mode of passion results in misery, and action performed in the mode of ignorance results in foolishness.
From the mode of goodness, real knowledge develops; from the mode of passion, greed develops; and from the mode of ignorance develop foolishness, madness and illusion.
Those situated in the mode of goodness gradually go upward to the higher planets; those in the mode of passion live on the earthly planets; and those in the abominable mode of ignorance go down to the hellish worlds.
When one properly sees that in all activities no other performer is at work than these modes of nature and he knows the Supreme Lord, who is transcendental to all these modes, he attains My spiritual nature.
When the embodied being is able to transcend these three modes associated with the material body, he can become free from birth, death, old age and their distresses and can enjoy nectar even in this life.
Arjuna inquired: O my dear Lord, by which symptoms is one known who is transcendental to these three modes? What is his behavior? And how does he transcend the modes of nature?
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
One who engages in full devotional service, unfailing in all circumstances, at once transcends the modes of material nature and thus comes to the level of Brahman.
And I am the basis of the impersonal Brahman, which is immortal, imperishable and eternal and is the constitutional position of ultimate happiness.The Supreme Personality of Godhead said: It is said that there is an imperishable banyan tree that has its roots upward and its branches down and whose leaves are the Vedic hymns. One who knows this tree is the knower of the Vedas.
The branches of this tree extend downward and upward, nourished by the three modes of material nature. The twigs are the objects of the senses. This tree also has roots going down, and these are bound to the fruitive actions of human society.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
Those who are free from false prestige, illusion and false association, who understand the eternal, who are done with material lust, who are freed from the dualities of happiness and distress, and who, unbewildered, know how to surrender unto the Supreme Person attain to that eternal kingdom.
That supreme abode of Mine is not illumined by the sun or moon, nor by fire or electricity. Those who reach it never return to this material world.
The living entities in this conditioned world are My eternal fragmental parts. Due to conditioned life, they are struggling very hard with the six senses, which include the mind.
The living entity in the material world carries his different conceptions of life from one body to another as the air carries aromas. Thus he takes one kind of body and again quits it to take another.
The living entity, thus taking another gross body, obtains a certain type of ear, eye, tongue, nose and sense of touch, which are grouped about the mind. He thus enjoys a particular set of sense objects.
The foolish cannot understand how a living entity can quit his body, nor can they understand what sort of body he enjoys under the spell of the modes of nature. But one whose eyes are trained in knowledge can see all this.
The endeavoring transcendentalists, who are situated in self-realization, can see all this clearly. But those whose minds are not developed and who are not situated in self-realization cannot see what is taking place, though they may try to.
The splendor of the sun, which dissipates the darkness of this whole world, comes from Me. And the splendor of the moon and the splendor of fire are also from Me.
I enter into each planet, and by My energy they stay in orbit. I become the moon and thereby supply the juice of life to all vegetables.
I am the fire of digestion in the bodies of all living entities, and I join with the air of life, outgoing and incoming, to digest the four kinds of foodstuff.
I am seated in everyone's heart, and from Me come remembrance, knowledge and forgetfulness. By all the Vedas, I am to be known. Indeed, I am the compiler of Vedānta, and I am the knower of the Vedas.
There are two classes of beings, the fallible and the infallible. In the material world every living entity is fallible, and in the spiritual world every living entity is called infallible.
Besides these two, there is the greatest living personality, the Supreme Soul, the imperishable Lord Himself, who has entered the three worlds and is maintaining them.
Because I am transcendental, beyond both the fallible and the infallible, and because I am the greatest, I am celebrated both in the world and in the Vedas as that Supreme Person.
Whoever knows Me as the Supreme Personality of Godhead, without doubting, is the knower of everything. He therefore engages himself in full devotional service to Me, O son of Bharata.
This is the most confidential part of the Vedic scriptures, O sinless one, and it is disclosed now by Me. Whoever understands this will become wise, and his endeavors will know perfection.The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
Pride, arrogance, conceit, anger, harshness and ignorance — these qualities belong to those of demoniac nature, O son of Pṛthā.
The transcendental qualities are conducive to liberation, whereas the demoniac qualities make for bondage. Do not worry, O son of Pāṇḍu, for you are born with the divine qualities.
O son of Pṛthā, in this world there are two kinds of created beings. One is called the divine and the other demoniac. I have already explained to you at length the divine qualities. Now hear from Me of the demoniac.
Those who are demoniac do not know what is to be done and what is not to be done. Neither cleanliness nor proper behavior nor truth is found in them.
They say that this world is unreal, with no foundation, no God in control. They say it is produced of sex desire and has no cause other than lust.
Following such conclusions, the demoniac, who are lost to themselves and who have no intelligence, engage in unbeneficial, horrible works meant to destroy the world.
Taking shelter of insatiable lust and absorbed in the conceit of pride and false prestige, the demoniac, thus illusioned, are always sworn to unclean work, attracted by the impermanent.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
Thus perplexed by various anxieties and bound by a network of illusions, they become too strongly attached to sense enjoyment and fall down into hell.
Self-complacent and always impudent, deluded by wealth and false prestige, they sometimes proudly perform sacrifices in name only, without following any rules or regulations.
Bewildered by false ego, strength, pride, lust and anger, the demons become envious of the Supreme Personality of Godhead, who is situated in their own bodies and in the bodies of others, and blaspheme against the real religion.
Those who are envious and mischievous, who are the lowest among men, I perpetually cast into the ocean of material existence, into various demoniac species of life.
Attaining repeated birth amongst the species of demoniac life, O son of Kuntī, such persons can never approach Me. Gradually they sink down to the most abominable type of existence.
There are three gates leading to this hell — lust, anger and greed. Every sane man should give these up, for they lead to the degradation of the soul.
The man who has escaped these three gates of hell, O son of Kuntī, performs acts conducive to self-realization and thus gradually attains the supreme destination.
He who discards scriptural injunctions and acts according to his own whims attains neither perfection, nor happiness, nor the supreme destination.
One should therefore understand what is duty and what is not duty by the regulations of the scriptures. Knowing such rules and regulations, one should act so that he may gradually be elevated.Arjuna inquired: O Kṛṣṇa, what is the situation of those who do not follow the principles of scripture but worship according to their own imagination? Are they in goodness, in passion or in ignorance?
The Supreme Personality of Godhead said: According to the modes of nature acquired by the embodied soul, one's faith can be of three kinds — in goodness, in passion or in ignorance. Now hear about this.
O son of Bharata, according to one's existence under the various modes of nature, one evolves a particular kind of faith. The living being is said to be of a particular faith according to the modes he has acquired.
Men in the mode of goodness worship the demigods; those in the mode of passion worship the demons; and those in the mode of ignorance worship ghosts and spirits.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Even the food each person prefers is of three kinds, according to the three modes of material nature. The same is true of sacrifices, austerities and charity. Now hear of the distinctions between them.
Foods dear to those in the mode of goodness increase the duration of life, purify one's existence and give strength, health, happiness and satisfaction. Such foods are juicy, fatty, wholesome, and pleasing to the heart.
Foods that are too bitter, too sour, salty, hot, pungent, dry and burning are dear to those in the mode of passion. Such foods cause distress, misery and disease.
Food prepared more than three hours before being eaten, food that is tasteless, decomposed and putrid, and food consisting of remnants and untouchable things is dear to those in the mode of darkness.
Of sacrifices, the sacrifice performed according to the directions of scripture, as a matter of duty, by those who desire no reward, is of the nature of goodness.
But the sacrifice performed for some material benefit, or for the sake of pride, O chief of the Bhāratas, you should know to be in the mode of passion.
Any sacrifice performed without regard for the directions of scripture, without distribution of prasādam [spiritual food], without chanting of Vedic hymns and remunerations to the priests, and without faith is considered to be in the mode of ignorance.
Austerity of the body consists in worship of the Supreme Lord, the brāhmaṇas, the spiritual master, and superiors like the father and mother, and in cleanliness, simplicity, celibacy and nonviolence.
Austerity of speech consists in speaking words that are truthful, pleasing, beneficial, and not agitating to others, and also in regularly reciting Vedic literature.
And satisfaction, simplicity, gravity, self-control and purification of one's existence are the austerities of the mind.
This threefold austerity, performed with transcendental faith by men not expecting material benefits but engaged only for the sake of the Supreme, is called austerity in goodness.
Penance performed out of pride and for the sake of gaining respect, honor and worship is said to be in the mode of passion. It is neither stable nor permanent.
Penance performed out of foolishness, with self-torture or to destroy or injure others, is said to be in the mode of ignorance.
Charity given out of duty, without expectation of return, at the proper time and place, and to a worthy person is considered to be in the mode of goodness.
But charity performed with the expectation of some return, or with a desire for fruitive results, or in a grudging mood, is said to be charity in the mode of passion.
And charity performed at an impure place, at an improper time, to unworthy persons, or without proper attention and respect is said to be in the mode of ignorance.
From the beginning of creation, the three words oḿ tat sat were used to indicate the Supreme Absolute Truth. These three symbolic representations were used by brāhmaṇas while chanting the hymns of the Vedas and during sacrifices for the satisfaction of the Supreme.
Therefore, transcendentalists undertaking performances of sacrifice, charity and penance in accordance with scriptural regulations begin always with oḿ, to attain the Supreme.
Without desiring fruitive results, one should perform various kinds of sacrifice, penance and charity with the word tat. The purpose of such transcendental activities is to get free from material entanglement.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
Anything done as sacrifice, charity or penance without faith in the Supreme, O son of Pṛthā, is impermanent. It is called asat and is useless both in this life and the next.Arjuna said: O mighty-armed one, I wish to understand the purpose of renunciation [tyāga] and of the renounced order of life [sannyāsa], O killer of the Keśī demon, master of the senses.
The Supreme Personality of Godhead said: The giving up of activities that are based on material desire is what great learned men call the renounced order of life [sannyāsa]. And giving up the results of all activities is what the wise call renunciation [tyāga].
Some learned men declare that all kinds of fruitive activities should be given up as faulty, yet other sages maintain that acts of sacrifice, charity and penance should never be abandoned.
O best of the Bhāratas, now hear My judgment about renunciation. O tiger among men, renunciation is declared in the scriptures to be of three kinds.
Acts of sacrifice, charity and penance are not to be given up; they must be performed. Indeed, sacrifice, charity and penance purify even the great souls.
All these activities should be performed without attachment or any expectation of result. They should be performed as a matter of duty, O son of Pṛthā. That is My final opinion.
Prescribed duties should never be renounced. If one gives up his prescribed duties because of illusion, such renunciation is said to be in the mode of ignorance.
Anyone who gives up prescribed duties as troublesome or out of fear of bodily discomfort is said to have renounced in the mode of passion. Such action never leads to the elevation of renunciation.
O Arjuna, when one performs his prescribed duty only because it ought to be done, and renounces all material association and all attachment to the fruit, his renunciation is said to be in the mode of goodness.
The intelligent renouncer situated in the mode of goodness, neither hateful of inauspicious work nor attached to auspicious work, has no doubts about work.
It is indeed impossible for an embodied being to give up all activities. But he who renounces the fruits of action is called one who has truly renounced.
For one who is not renounced, the threefold fruits of action — desirable, undesirable and mixed — accrue after death. But those who are in the renounced order of life have no such result to suffer or enjoy.
O mighty-armed Arjuna, according to the Vedānta there are five causes for the accomplishment of all action. Now learn of these from Me.
The place of action [the body], the performer, the various senses, the many different kinds of endeavor, and ultimately the Supersoul — these are the five factors of action.
Whatever right or wrong action a man performs by body, mind or speech is caused by these five factors.
Therefore one who thinks himself the only doer, not considering the five factors, is certainly not very intelligent and cannot see things as they are.
One who is not motivated by false ego, whose intelligence is not entangled, though he kills men in this world, does not kill. Nor is he bound by his actions.
Knowledge, the object of knowledge, and the knower are the three factors that motivate action; the senses, the work and the doer are the three constituents of action.
According to the three different modes of material nature, there are three kinds of knowledge, action and performer of action. Now hear of them from Me.
That knowledge by which one undivided spiritual nature is seen in all living entities, though they are divided into innumerable forms, you should understand to be in the mode of goodness.
That knowledge by which one sees that in every different body there is a different type of living entity you should understand to be in the mode of passion.
And that knowledge by which one is attached to one kind of work as the all in all, without knowledge of the truth, and which is very meager, is said to be in the mode of darkness.
That action which is regulated and which is performed without attachment, without love or hatred, and without desire for fruitive results is said to be in the mode of goodness.
But action performed with great effort by one seeking to gratify his desires, and enacted from a sense of false ego, is called action in the mode of passion.
That action performed in illusion, in disregard of scriptural injunctions, and without concern for future bondage or for violence or distress caused to others is said to be in the mode of ignorance.
One who performs his duty without association with the modes of material nature, without false ego, with great determination and enthusiasm, and without wavering in success or failure is said to be a worker in the mode of goodness.
The worker who is attached to work and the fruits of work, desiring to enjoy those fruits, and who is greedy, always envious, impure, and moved by joy and sorrow, is said to be in the mode of passion.
The worker who is always engaged in work against the injunctions of the scripture, who is materialistic, obstinate, cheating and expert in insulting others, and who is lazy, always morose and procrastinating is said to be a worker in the mode of ignorance.
O winner of wealth, now please listen as I tell you in detail of the different kinds of understanding and determination, according to the three modes of material nature.
O son of Pṛthā, that understanding by which one knows what ought to be done and what ought not to be done, what is to be feared and what is not to be feared, what is binding and what is liberating, is in the mode of goodness.
O son of Pṛthā, that understanding which cannot distinguish between religion and irreligion, between action that should be done and action that should not be done, is in the mode of passion.
That understanding which considers irreligion to be religion and religion to be irreligion, under the spell of illusion and darkness, and strives always in the wrong direction, O Pārtha, is in the mode of ignorance.
O son of Pṛthā, that determination which is unbreakable, which is sustained with steadfastness by yoga practice, and which thus controls the activities of the mind, life and senses is determination in the mode of goodness.
But that determination by which one holds fast to fruitive results in religion, economic development and sense gratification is of the nature of passion, O Arjuna.
And that determination which cannot go beyond dreaming, fearfulness, lamentation, moroseness and illusion — such unintelligent determination, O son of Pṛthā, is in the mode of darkness.
O best of the Bhāratas, now please hear from Me about the three kinds of happiness by which the conditioned soul enjoys, and by which he sometimes comes to the end of all distress.
That which in the beginning may be just like poison but at the end is just like nectar and which awakens one to self-realization is said to be happiness in the mode of goodness.
That happiness which is derived from contact of the senses with their objects and which appears like nectar at first but poison at the end is said to be of the nature of passion.
And that happiness which is blind to self-realization, which is delusion from beginning to end and which arises from sleep, laziness and illusion is said to be of the nature of ignorance.
There is no being existing, either here or among the demigods in the higher planetary systems, which is freed from these three modes born of material nature.
Brāhmaṇas, kṣatriyas, vaiśyas and śūdras are distinguished by the qualities born of their own natures in accordance with the material modes, O chastiser of the enemy.
Peacefulness, self-control, austerity, purity, tolerance, honesty, knowledge, wisdom and religiousness — these are the natural qualities by which the brāhmaṇas work.
Heroism, power, determination, resourcefulness, courage in battle, generosity and leadership are the natural qualities of work for the kṣatriyas.
Farming, cow protection and business are the natural work for the vaiśyas, and for the śūdras there is labor and service to others.
By following his qualities of work, every man can become perfect. Now please hear from Me how this can be done.
By worship of the Lord, who is the source of all beings and who is all-pervading, a man can attain perfection through performing his own work.
It is better to engage in one's own occupation, even though one may perform it imperfectly, than to accept another's occupation and perform it perfectly. Duties prescribed according to one's nature are never affected by sinful reactions.
Every endeavor is covered by some fault, just as fire is covered by smoke. Therefore one should not give up the work born of his nature, O son of Kuntī, even if such work is full of fault.
One who is self-controlled and unattached and who disregards all material enjoyments can obtain, by practice of renunciation, the highest perfect stage of freedom from reaction.
O son of Kuntī, learn from Me how one who has achieved this perfection can attain to the supreme perfectional stage, Brahman, the stage of highest knowledge, by acting in the way I shall now summarize.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
One who is thus transcendentally situated at once realizes the Supreme Brahman and becomes fully joyful. He never laments or desires to have anything. He is equally disposed toward every living entity. In that state he attains pure devotional service unto Me.
One can understand Me as I am, as the Supreme Personality of Godhead, only by devotional service. And when one is in full consciousness of Me by such devotion, he can enter into the kingdom of God.
Though engaged in all kinds of activities, My pure devotee, under My protection, reaches the eternal and imperishable abode by My grace.
In all activities just depend upon Me and work always under My protection. In such devotional service, be fully conscious of Me.
If you become conscious of Me, you will pass over all the obstacles of conditioned life by My grace. If, however, you do not work in such consciousness but act through false ego, not hearing Me, you will be lost.
If you do not act according to My direction and do not fight, then you will be falsely directed. By your nature, you will have to be engaged in warfare.
Under illusion you are now declining to act according to My direction. But, compelled by the work born of your own nature, you will act all the same, O son of Kuntī.
The Supreme Lord is situated in everyone's heart, O Arjuna, and is directing the wanderings of all living entities, who are seated as on a machine, made of the material energy.
O scion of Bharata, surrender unto Him utterly. By His grace you will attain transcendental peace and the supreme and eternal abode.
Thus I have explained to you knowledge still more confidential. Deliberate on this fully, and then do what you wish to do.
Because you are My very dear friend, I am speaking to you My supreme instruction, the most confidential knowledge of all. Hear this from Me, for it is for your benefit.
Always think of Me, become My devotee, worship Me and offer your homage unto Me. Thus you will come to Me without fail. I promise you this because you are My very dear friend.
Abandon all varieties of religion and just surrender unto Me. I shall deliver you from all sinful reactions. Do not fear.
This confidential knowledge may never be explained to those who are not austere, or devoted, or engaged in devotional service, nor to one who is envious of Me.
For one who explains this supreme secret to the devotees, pure devotional service is guaranteed, and at the end he will come back to Me.
There is no servant in this world more dear to Me than he, nor will there ever be one more dear.
And I declare that he who studies this sacred conversation of ours worships Me by his intelligence.
And one who listens with faith and without envy becomes free from sinful reactions and attains to the auspicious planets where the pious dwell.
O son of Pṛthā, O conqueror of wealth, have you heard this with an attentive mind? And are your ignorance and illusions now dispelled?
Arjuna said: My dear Kṛṣṇa, O infallible one, my illusion is now gone. I have regained my memory by Your mercy. I am now firm and free from doubt and am prepared to act according to Your instructions.
Sañjaya said: Thus have I heard the conversation of two great souls, Kṛṣṇa and Arjuna. And so wonderful is that message that my hair is standing on end.
By the mercy of Vyāsa, I have heard these most confidential talks directly from the master of all mysticism, Kṛṣṇa, who was speaking personally to Arjuna.
O King, as I repeatedly recall this wondrous and holy dialogue between Kṛṣṇa and Arjuna, I take pleasure, being thrilled at every moment.
O King, as I remember the wonderful form of Lord Kṛṣṇa, I am struck with wonder more and more, and I rejoice again and again.
Wherever there is Kṛṣṇa, the master of all mystics, and wherever there is Arjuna, the supreme archer, there will also certainly be opulence, victory, extraordinary power, and morality. That is my opinion.Dhṛtarāṣṭra said: O Sañjaya, after my sons and the sons of Pāṇḍu assembled in the place of pilgrimage at Kurukṣetra, desiring to fight, what did they do?
Sañjaya said: O King, after looking over the army arranged in military formation by the sons of Pāṇḍu, King Duryodhana went to his teacher and spoke the following words.
O my teacher, behold the great army of the sons of Pāṇḍu, so expertly arranged by your intelligent disciple the son of Drupada.
Here in this army are many heroic bowmen equal in fighting to Bhīma and Arjuna: great fighters like Yuyudhāna, Virāṭa and Drupada.
There are also great, heroic, powerful fighters like Dhṛṣṭaketu, Cekitāna, Kāśirāja, Purujit, Kuntibhoja and Śaibya.
There are the mighty Yudhāmanyu, the very powerful Uttamaujā, the son of Subhadrā and the sons of Draupadī. All these warriors are great chariot fighters.
But for your information, O best of the brāhmaṇas, let me tell you about the captains who are especially qualified to lead my military force.
There are personalities like you, Bhīṣma, Karṇa, Kṛpa, Aśvatthāmā, Vikarṇa and the son of Somadatta called Bhūriśravā, who are always victorious in battle.
There are many other heroes who are prepared to lay down their lives for my sake. All of them are well equipped with different kinds of weapons, and all are experienced in military science.
Our strength is immeasurable, and we are perfectly protected by Grandfather Bhīṣma, whereas the strength of the Pāṇḍavas, carefully protected by Bhīma, is limited.
All of you must now give full support to Grandfather Bhīṣma, as you stand at your respective strategic points of entrance into the phalanx of the army.
Then Bhīṣma, the great valiant grandsire of the Kuru dynasty, the grandfather of the fighters, blew his conchshell very loudly, making a sound like the roar of a lion, giving Duryodhana joy.
After that, the conchshells, drums, bugles, trumpets and horns were all suddenly sounded, and the combined sound was tumultuous.
On the other side, both Lord Kṛṣṇa and Arjuna, stationed on a great chariot drawn by white horses, sounded their transcendental conchshells.
Lord Kṛṣṇa blew His conchshell, called Pāñcajanya; Arjuna blew his, the Devadatta; and Bhīma, the voracious eater and performer of herculean tasks, blew his terrific conchshell, called Pauṇḍra.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
King Yudhiṣṭhira, the son of Kuntī, blew his conchshell, the Ananta-vijaya, and Nakula and Sahadeva blew the Sughoṣa and Maṇipuṣpaka. That great archer the King of Kāśī, the great fighter Śikhaṇḍī, Dhṛṣṭadyumna, Virāṭa, the unconquerable Sātyaki, Drupada, the sons of Draupadī, and the others, O King, such as the mighty-armed son of Subhadrā, all blew their respective conchshells.
The blowing of these different conchshells became uproarious. Vibrating both in the sky and on the earth, it shattered the hearts of the sons of Dhṛtarāṣṭra.
At that time Arjuna, the son of Pāṇḍu, seated in the chariot bearing the flag marked with Hanumān, took up his bow and prepared to shoot his arrows. O King, after looking at the sons of Dhṛtarāṣṭra drawn in military array, Arjuna then spoke to Lord Kṛṣṇa these words.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Arjuna said: O infallible one, please draw my chariot between the two armies so that I may see those present here, who desire to fight, and with whom I must contend in this great trial of arms.
Let me see those who have come here to fight, wishing to please the evil-minded son of Dhṛtarāṣṭra.
Sañjaya said: O descendant of Bharata, having thus been addressed by Arjuna, Lord Kṛṣṇa drew up the fine chariot in the midst of the armies of both parties.
In the presence of Bhīṣma, Droṇa and all the other chieftains of the world, the Lord said, Just behold, Pārtha, all the Kurus assembled here.
There Arjuna could see, within the midst of the armies of both parties, his fathers, grandfathers, teachers, maternal uncles, brothers, sons, grandsons, friends, and also his fathers-in-law and well-wishers.
When the son of Kuntī, Arjuna, saw all these different grades of friends and relatives, he became overwhelmed with compassion and spoke thus.
Arjuna said: My dear Kṛṣṇa, seeing my friends and relatives present before me in such a fighting spirit, I feel the limbs of my body quivering and my mouth drying up.
My whole body is trembling, my hair is standing on end, my bow Gāṇḍīva is slipping from my hand, and my skin is burning.
I am now unable to stand here any longer. I am forgetting myself, and my mind is reeling. I see only causes of misfortune, O Kṛṣṇa, killer of the Keśī demon.
I do not see how any good can come from killing my own kinsmen in this battle, nor can I, my dear Kṛṣṇa, desire any subsequent victory, kingdom, or happiness.
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
O Govinda, of what avail to us are a kingdom, happiness or even life itself when all those for whom we may desire them are now arrayed on this battlefield? O Madhusūdana, when teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law and other relatives are ready to give up their lives and properties and are standing before me, why should I wish to kill them, even though they might otherwise kill me? O maintainer of all living entities, I am not prepared to fight with them even in exchange for the three worlds, let alone this earth. What pleasure will we derive from killing the sons of Dhṛtarāṣṭra?
Sin will overcome us if we slay such aggressors. Therefore it is not proper for us to kill the sons of Dhṛtarāṣṭra and our friends. What should we gain, O Kṛṣṇa, husband of the goddess of fortune, and how could we be happy by killing our own kinsmen?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
O Janārdana, although these men, their hearts overtaken by greed, see no fault in killing one's family or quarreling with friends, why should we, who can see the crime in destroying a family, engage in these acts of sin?
With the destruction of dynasty, the eternal family tradition is vanquished, and thus the rest of the family becomes involved in irreligion.
When irreligion is prominent in the family, O Kṛṣṇa, the women of the family become polluted, and from the degradation of womanhood, O descendant of Vṛṣṇi, comes unwanted progeny.
An increase of unwanted population certainly causes hellish life both for the family and for those who destroy the family tradition. The ancestors of such corrupt families fall down, because the performances for offering them food and water are entirely stopped.
By the evil deeds of those who destroy the family tradition and thus give rise to unwanted children, all kinds of community projects and family welfare activities are devastated.
O Kṛṣṇa, maintainer of the people, I have heard by disciplic succession that those who destroy family traditions dwell always in hell.
Alas, how strange it is that we are preparing to commit greatly sinful acts. Driven by the desire to enjoy royal happiness, we are intent on killing our own kinsmen.
Better for me if the sons of Dhṛtarāṣṭra, weapons in hand, were to kill me unarmed and unresisting on the battlefield.
Sañjaya said: Arjuna, having thus spoken on the battlefield, cast aside his bow and arrows and sat down on the chariot, his mind overwhelmed with grief.

Sañjaya said: Seeing Arjuna full of compassion, his mind depressed, his eyes full of tears, Madhusūdana, Kṛṣṇa, spoke the following words.
The Supreme Personality of Godhead said: My dear Arjuna, how have these impurities come upon you? They are not at all befitting a man who knows the value of life. They lead not to higher planets but to infamy.
O son of Pṛthā, do not yield to this degrading impotence. It does not become you. Give up such petty weakness of heart and arise, O chastiser of the enemy.
Arjuna said: O killer of enemies, O killer of Madhu, how can I counterattack with arrows in battle men like Bhīṣma and Droṇa, who are worthy of my worship?
It would be better to live in this world by begging than to live at the cost of the lives of great souls who are my teachers. Even though desiring worldly gain, they are superiors. If they are killed, everything we enjoy will be tainted with blood.
Nor do we know which is better — conquering them or being conquered by them. If we killed the sons of Dhṛtarāṣṭra, we should not care to live. Yet they are now standing before us on the battlefield.
Now I am confused about my duty and have lost all composure because of miserly weakness. In this condition I am asking You to tell me for certain what is best for me. Now I am Your disciple, and a soul surrendered unto You. Please instruct me.
I can find no means to drive away this grief which is drying up my senses. I will not be able to dispel it even if I win a prosperous, unrivaled kingdom on earth with sovereignty like the demigods in heaven.
Sañjaya said: Having spoken thus, Arjuna, chastiser of enemies, told Kṛṣṇa, "Govinda, I shall not fight," and fell silent.
O descendant of Bharata, at that time Kṛṣṇa, smiling, in the midst of both the armies, spoke the following words to the grief-stricken Arjuna.
The Supreme Personality of Godhead said: While speaking learned words, you are mourning for what is not worthy of grief. Those who are wise lament neither for the living nor for the dead.
Never was there a time when I did not exist, nor you, nor all these kings; nor in the future shall any of us cease to be.
As the embodied soul continuously passes, in this body, from boyhood to youth to old age, the soul similarly passes into another body at death. A sober person is not bewildered by such a change.
O son of Kuntī, the nonpermanent appearance of happiness and distress, and their disappearance in due course, are like the appearance and disappearance of winter and summer seasons. They arise from sense perception, O scion of Bharata, and one must learn to tolerate them without being disturbed.
O best among men [Arjuna], the person who is not disturbed by happiness and distress and is steady in both is certainly eligible for liberation.
Those who are seers of the truth have concluded that of the nonexistent [the material body] there is no endurance and of the eternal [the soul] there is no change. This they have concluded by studying the nature of both.
That which pervades the entire body you should know to be indestructible. No one is able to destroy that imperishable soul.
The material body of the indestructible, immeasurable and eternal living entity is sure to come to an end; therefore, fight, O descendant of Bharata.
Neither he who thinks the living entity the slayer nor he who thinks it slain is in knowledge, for the self slays not nor is slain.
For the soul there is neither birth nor death at any time. He has not come into being, does not come into being, and will not come into being. He is unborn, eternal, ever-existing and primeval. He is not slain when the body is slain.
O Pārtha, how can a person who knows that the soul is indestructible, eternal, unborn and immutable kill anyone or cause anyone to kill?
As a person puts on new garments, giving up old ones, the soul similarly accepts new material bodies, giving up the old and useless ones.
The soul can never be cut to pieces by any weapon, nor burned by fire, nor moistened by water, nor withered by the wind.
This individual soul is unbreakable and insoluble, and can be neither burned nor dried. He is everlasting, present everywhere, unchangeable, immovable and eternally the same.
It is said that the soul is invisible, inconceivable and immutable. Knowing this, you should not grieve for the body.
If, however, you think that the soul [or the symptoms of life] is always born and dies forever, you still have no reason to lament, O mighty-armed.
One who has taken his birth is sure to die, and after death one is sure to take birth again. Therefore, in the unavoidable discharge of your duty, you should not lament.
All created beings are unmanifest in their beginning, manifest in their interim state, and unmanifest again when annihilated. So what need is there for lamentation?
Some look on the soul as amazing, some describe him as amazing, and some hear of him as amazing, while others, even after hearing about him, cannot understand him at all.
O descendant of Bharata, he who dwells in the body can never be slain. Therefore you need not grieve for any living being.
Considering your specific duty as a kṣatriya, you should know that there is no better engagement for you than fighting on religious principles; and so there is no need for hesitation.
O Pārtha, happy are the kṣatriyas to whom such fighting opportunities come unsought, opening for them the doors of the heavenly planets.
If, however, you do not perform your religious duty of fighting, then you will certainly incur sins for neglecting your duties and thus lose your reputation as a fighter.
People will always speak of your infamy, and for a respectable person, dishonor is worse than death.
The great generals who have highly esteemed your name and fame will think that you have left the battlefield out of fear only, and thus they will consider you insignificant.
Your enemies will describe you in many unkind words and scorn your ability. What could be more painful for you?
O son of Kuntī, either you will be killed on the battlefield and attain the heavenly planets, or you will conquer and enjoy the earthly kingdom. Therefore, get up with determination and fight.
Do thou fight for the sake of fighting, without considering happiness or distress, loss or gain, victory or defeat — and by so doing you shall never incur sin.
Thus far I have described this knowledge to you through analytical study. Now listen as I explain it in terms of working without fruitive results. O son of Pṛthā, when you act in such knowledge you can free yourself from the bondage of works.
In this endeavor there is no loss or diminution, and a little advancement on this path can protect one from the most dangerous type of fear.
Those who are on this path are resolute in purpose, and their aim is one. O beloved child of the Kurus, the intelligence of those who are irresolute is many-branched.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
Men of small knowledge are very much attached to the flowery words of the Vedas, which recommend various fruitive activities for elevation to heavenly planets, resultant good birth, power, and so forth. Being desirous of sense gratification and opulent life, they say that there is nothing more than this.
In the minds of those who are too attached to sense enjoyment and material opulence, and who are bewildered by such things, the resolute determination for devotional service to the Supreme Lord does not take place.
The Vedas deal mainly with the subject of the three modes of material nature. O Arjuna, become transcendental to these three modes. Be free from all dualities and from all anxieties for gain and safety, and be established in the self.
All purposes served by a small well can at once be served by a great reservoir of water. Similarly, all the purposes of the Vedas can be served to one who knows the purpose behind them.
You have a right to perform your prescribed duty, but you are not entitled to the fruits of action. Never consider yourself the cause of the results of your activities, and never be attached to not doing your duty.
Perform your duty equipoised, O Arjuna, abandoning all attachment to success or failure. Such equanimity is called yoga.
O Dhanañjaya, keep all abominable activities far distant by devotional service, and in that consciousness surrender unto the Lord. Those who want to enjoy the fruits of their work are misers.
A man engaged in devotional service rids himself of both good and bad actions even in this life. Therefore strive for yoga, which is the art of all work.
By thus engaging in devotional service to the Lord, great sages or devotees free themselves from the results of work in the material world. In this way they become free from the cycle of birth and death and attain the state beyond all miseries [by going back to Godhead].
When your intelligence has passed out of the dense forest of delusion, you shall become indifferent to all that has been heard and all that is to be heard.
When your mind is no longer disturbed by the flowery language of the Vedas, and when it remains fixed in the trance of self-realization, then you will have attained the divine consciousness.
Arjuna said: O Kṛṣṇa, what are the symptoms of one whose consciousness is thus merged in transcendence? How does he speak, and what is his language? How does he sit, and how does he walk?
The Supreme Personality of Godhead said: O Pārtha, when a man gives up all varieties of desire for sense gratification, which arise from mental concoction, and when his mind, thus purified, finds satisfaction in the self alone, then he is said to be in pure transcendental consciousness.
One who is not disturbed in mind even amidst the threefold miseries or elated when there is happiness, and who is free from attachment, fear and anger, is called a sage of steady mind.
In the material world, one who is unaffected by whatever good or evil he may obtain, neither praising it nor despising it, is firmly fixed in perfect knowledge.
One who is able to withdraw his senses from sense objects, as the tortoise draws its limbs within the shell, is firmly fixed in perfect consciousness.
The embodied soul may be restricted from sense enjoyment, though the taste for sense objects remains. But, ceasing such engagements by experiencing a higher taste, he is fixed in consciousness.
The senses are so strong and impetuous, O Arjuna, that they forcibly carry away the mind even of a man of discrimination who is endeavoring to control them.
One who restrains his senses, keeping them under full control, and fixes his consciousness upon Me, is known as a man of steady intelligence.
While contemplating the objects of the senses, a person develops attachment for them, and from such attachment lust develops, and from lust anger arises.
From anger, complete delusion arises, and from delusion bewilderment of memory. When memory is bewildered, intelligence is lost, and when intelligence is lost one falls down again into the material pool.
But a person free from all attachment and aversion and able to control his senses through regulative principles of freedom can obtain the complete mercy of the Lord.
For one thus satisfied [in Kṛṣṇa consciousness], the threefold miseries of material existence exist no longer; in such satisfied consciousness, one's intelligence is soon well established.
One who is not connected with the Supreme [in Kṛṣṇa consciousness] can have neither transcendental intelligence nor a steady mind, without which there is no possibility of peace. And how can there be any happiness without peace?
As a strong wind sweeps away a boat on the water, even one of the roaming senses on which the mind focuses can carry away a man's intelligence.
Therefore, O mighty-armed, one whose senses are restrained from their objects is certainly of steady intelligence.
What is night for all beings is the time of awakening for the self-controlled; and the time of awakening for all beings is night for the introspective sage.
A person who is not disturbed by the incessant flow of desires — that enter like rivers into the ocean, which is ever being filled but is always still — can alone achieve peace, and not the man who strives to satisfy such desires.
A person who has given up all desires for sense gratification, who lives free from desires, who has given up all sense of proprietorship and is devoid of false ego — he alone can attain real peace.
That is the way of the spiritual and godly life, after attaining which a man is not bewildered. If one is thus situated even at the hour of death, one can enter into the kingdom of God.

Arjuna said: O Janārdana, O Keśava, why do You want to engage me in this ghastly warfare, if You think that intelligence is better than fruitive work?
My intelligence is bewildered by Your equivocal instructions. Therefore, please tell me decisively which will be most beneficial for me.
The Supreme Personality of Godhead said: O sinless Arjuna, I have already explained that there are two classes of men who try to realize the self. Some are inclined to understand it by empirical, philosophical speculation, and others by devotional service.
Not by merely abstaining from work can one achieve freedom from reaction, nor by renunciation alone can one attain perfection.
Everyone is forced to act helplessly according to the qualities he has acquired from the modes of material nature; therefore no one can refrain from doing something, not even for a moment.
One who restrains the senses of action but whose mind dwells on sense objects certainly deludes himself and is called a pretender.
On the other hand, if a sincere person tries to control the active senses by the mind and begins karma-yoga [in Kṛṣṇa consciousness] without attachment, he is by far superior.
Perform your prescribed duty, for doing so is better than not working. One cannot even maintain one's physical body without work.
Work done as a sacrifice for Viṣṇu has to be performed, otherwise work causes bondage in this material world. Therefore, O son of Kuntī, perform your prescribed duties for His satisfaction, and in that way you will always remain free from bondage.
In the beginning of creation, the Lord of all creatures sent forth generations of men and demigods, along with sacrifices for Viṣṇu, and blessed them by saying, "Be thou happy by this yajña [sacrifice] because its performance will bestow upon you everything desirable for living happily and achieving liberation."
The demigods, being pleased by sacrifices, will also please you, and thus, by cooperation between men and demigods, prosperity will reign for all.
In charge of the various necessities of life, the demigods, being satisfied by the performance of yajña [sacrifice], will supply all necessities to you. But he who enjoys such gifts without offering them to the demigods in return is certainly a thief.
The devotees of the Lord are released from all kinds of sins because they eat food which is offered first for sacrifice. Others, who prepare food for personal sense enjoyment, verily eat only sin.
All living bodies subsist on food grains, which are produced from rains. Rains are produced by performance of yajña [sacrifice], and yajña is born of prescribed duties.
Regulated activities are prescribed in the Vedas, and the Vedas are directly manifested from the Supreme Personality of Godhead. Consequently the all-pervading Transcendence is eternally situated in acts of sacrifice.
My dear Arjuna, one who does not follow in human life the cycle of sacrifice thus established by the Vedas certainly leads a life full of sin. Living only for the satisfaction of the senses, such a person lives in vain.
But for one who takes pleasure in the self, whose human life is one of self-realization, and who is satisfied in the self only, fully satiated — for him there is no duty.
A self-realized man has no purpose to fulfill in the discharge of his prescribed duties, nor has he any reason not to perform such work. Nor has he any need to depend on any other living being.
Therefore, without being attached to the fruits of activities, one should act as a matter of duty, for by working without attachment one attains the Supreme.
Kings such as Janaka attained perfection solely by performance of prescribed duties. Therefore, just for the sake of educating the people in general, you should perform your work.
Whatever action a great man performs, common men follow. And whatever standards he sets by exemplary acts, all the world pursues.
O son of Pṛthā, there is no work prescribed for Me within all the three planetary systems. Nor am I in want of anything, nor have I a need to obtain anything — and yet I am engaged in prescribed duties.
For if I ever failed to engage in carefully performing prescribed duties, O Pārtha, certainly all men would follow My path.
If I did not perform prescribed duties, all these worlds would be put to ruination. I would be the cause of creating unwanted population, and I would thereby destroy the peace of all living beings.
As the ignorant perform their duties with attachment to results, the learned may similarly act, but without attachment, for the sake of leading people on the right path.
So as not to disrupt the minds of ignorant men attached to the fruitive results of prescribed duties, a learned person should not induce them to stop work. Rather, by working in the spirit of devotion, he should engage them in all sorts of activities [for the gradual development of Kṛṣṇa consciousness].
The spirit soul bewildered by the influence of false ego thinks himself the doer of activities that are in actuality carried out by the three modes of material nature.
One who is in knowledge of the Absolute Truth, O mighty-armed, does not engage himself in the senses and sense gratification, knowing well the differences between work in devotion and work for fruitive results.
Bewildered by the modes of material nature, the ignorant fully engage themselves in material activities and become attached. But the wise should not unsettle them, although these duties are inferior due to the performers' lack of knowledge.
Therefore, O Arjuna, surrendering all your works unto Me, with full knowledge of Me, without desires for profit, with no claims to proprietorship, and free from lethargy, fight.
Those persons who execute their duties according to My injunctions and who follow this teaching faithfully, without envy, become free from the bondage of fruitive actions.
But those who, out of envy, disregard these teachings and do not follow them are to be considered bereft of all knowledge, befooled, and ruined in their endeavors for perfection.
Even a man of knowledge acts according to his own nature, for everyone follows the nature he has acquired from the three modes. What can repression accomplish?
There are principles to regulate attachment and aversion pertaining to the senses and their objects. One should not come under the control of such attachment and aversion, because they are stumbling blocks on the path of self-realization.
It is far better to discharge one's prescribed duties, even though faultily, than another's duties perfectly. Destruction in the course of performing one's own duty is better than engaging in another's duties, for to follow another's path is dangerous.
Arjuna said: O descendant of Vṛṣṇi, by what is one impelled to sinful acts, even unwillingly, as if engaged by force?
The Supreme Personality of Godhead said: It is lust only, Arjuna, which is born of contact with the material mode of passion and later transformed into wrath, and which is the all-devouring sinful enemy of this world.
As fire is covered by smoke, as a mirror is covered by dust, or as the embryo is covered by the womb, the living entity is similarly covered by different degrees of this lust.
Thus the wise living entity's pure consciousness becomes covered by his eternal enemy in the form of lust, which is never satisfied and which burns like fire.
The senses, the mind and the intelligence are the sitting places of this lust. Through them lust covers the real knowledge of the living entity and bewilders him.
Therefore, O Arjuna, best of the Bhāratas, in the very beginning curb this great symbol of sin [lust] by regulating the senses, and slay this destroyer of knowledge and self-realization.
The working senses are superior to dull matter; mind is higher than the senses; intelligence is still higher than the mind; and he [the soul] is even higher than the intelligence.
Thus knowing oneself to be transcendental to the material senses, mind and intelligence, O mighty-armed Arjuna, one should steady the mind by deliberate spiritual intelligence [Kṛṣṇa consciousness] and thus — by spiritual strength — conquer this insatiable enemy known as lust.

The Personality of Godhead, Lord Śrī Kṛṣṇa, said: I instructed this imperishable science of yoga to the sun-god, Vivasvān, and Vivasvān instructed it to Manu, the father of mankind, and Manu in turn instructed it to Ikṣvāku.
This supreme science was thus received through the chain of disciplic succession, and the saintly kings understood it in that way. But in course of time the succession was broken, and therefore the science as it is appears to be lost.
That very ancient science of the relationship with the Supreme is today told by Me to you because you are My devotee as well as My friend and can therefore understand the transcendental mystery of this science.
Arjuna said: The sun-god Vivasvān is senior by birth to You. How am I to understand that in the beginning You instructed this science to him?
The Personality of Godhead said: Many, many births both you and I have passed. I can remember all of them, but you cannot, O subduer of the enemy!
Although I am unborn and My transcendental body never deteriorates, and although I am the Lord of all living entities, I still appear in every millennium in My original transcendental form.
Whenever and wherever there is a decline in religious practice, O descendant of Bharata, and a predominant rise of irreligion — at that time I descend Myself.
To deliver the pious and to annihilate the miscreants, as well as to reestablish the principles of religion, I Myself appear, millennium after millennium.
One who knows the transcendental nature of My appearance and activities does not, upon leaving the body, take his birth again in this material world, but attains My eternal abode, O Arjuna.
Being freed from attachment, fear and anger, being fully absorbed in Me and taking refuge in Me, many, many persons in the past became purified by knowledge of Me — and thus they all attained transcendental love for Me.
As all surrender unto Me, I reward them accordingly. Everyone follows My path in all respects, O son of Pṛthā.
Men in this world desire success in fruitive activities, and therefore they worship the demigods. Quickly, of course, men get results from fruitive work in this world.
According to the three modes of material nature and the work associated with them, the four divisions of human society are created by Me. And although I am the creator of this system, you should know that I am yet the nondoer, being unchangeable.
There is no work that affects Me; nor do I aspire for the fruits of action. One who understands this truth about Me also does not become entangled in the fruitive reactions of work.
All the liberated souls in ancient times acted with this understanding of My transcendental nature. Therefore you should perform your duty, following in their footsteps.
Even the intelligent are bewildered in determining what is action and what is inaction. Now I shall explain to you what action is, knowing which you shall be liberated from all misfortune.
The intricacies of action are very hard to understand. Therefore one should know properly what action is, what forbidden action is, and what inaction is.
One who sees inaction in action, and action in inaction, is intelligent among men, and he is in the transcendental position, although engaged in all sorts of activities.
One is understood to be in full knowledge whose every endeavor is devoid of desire for sense gratification. He is said by sages to be a worker for whom the reactions of work have been burned up by the fire of perfect knowledge.
Abandoning all attachment to the results of his activities, ever satisfied and independent, he performs no fruitive action, although engaged in all kinds of undertakings.
Such a man of understanding acts with mind and intelligence perfectly controlled, gives up all sense of proprietorship over his possessions, and acts only for the bare necessities of life. Thus working, he is not affected by sinful reactions.
He who is satisfied with gain which comes of its own accord, who is free from duality and does not envy, who is steady in both success and failure, is never entangled, although performing actions.
The work of a man who is unattached to the modes of material nature and who is fully situated in transcendental knowledge merges entirely into transcendence.
A person who is fully absorbed in Kṛṣṇa consciousness is sure to attain the spiritual kingdom because of his full contribution to spiritual activities, in which the consummation is absolute and that which is offered is of the same spiritual nature.
Some yogīs perfectly worship the demigods by offering different sacrifices to them, and some of them offer sacrifices in the fire of the Supreme Brahman.
Some [the unadulterated brahmacārīs] sacrifice the hearing process and the senses in the fire of mental control, and others [the regulated householders] sacrifice the objects of the senses in the fire of the senses.
Others, who are interested in achieving self-realization through control of the mind and senses, offer the functions of all the senses, and of the life breath, as oblations into the fire of the controlled mind.
Having accepted strict vows, some become enlightened by sacrificing their possessions, and others by performing severe austerities, by practicing the yoga of eightfold mysticism, or by studying the Vedas to advance in transcendental knowledge.
Still others, who are inclined to the process of breath restraint to remain in trance, practice by offering the movement of the outgoing breath into the incoming, and the incoming breath into the outgoing, and thus at last remain in trance, stopping all breathing. Others, curtailing the eating process, offer the outgoing breath into itself as a sacrifice.
All these performers who know the meaning of sacrifice become cleansed of sinful reactions, and, having tasted the nectar of the results of sacrifices, they advance toward the supreme eternal atmosphere.
O best of the Kuru dynasty, without sacrifice one can never live happily on this planet or in this life: what then of the next?
All these different types of sacrifice are approved by the Vedas, and all of them are born of different types of work. Knowing them as such, you will become liberated.
O chastiser of the enemy, the sacrifice performed in knowledge is better than the mere sacrifice of material possessions. After all, O son of Pṛthā, all sacrifices of work culminate in transcendental knowledge.
Just try to learn the truth by approaching a spiritual master. Inquire from him submissively and render service unto him. The self-realized souls can impart knowledge unto you because they have seen the truth.
Having obtained real knowledge from a self-realized soul, you will never fall again into such illusion, for by this knowledge you will see that all living beings are but part of the Supreme, or, in other words, that they are Mine.
Even if you are considered to be the most sinful of all sinners, when you are situated in the boat of transcendental knowledge you will be able to cross over the ocean of miseries.
As a blazing fire turns firewood to ashes, O Arjuna, so does the fire of knowledge burn to ashes all reactions to material activities.
In this world, there is nothing so sublime and pure as transcendental knowledge. Such knowledge is the mature fruit of all mysticism. And one who has become accomplished in the practice of devotional service enjoys this knowledge within himself in due course of time.
A faithful man who is dedicated to transcendental knowledge and who subdues his senses is eligible to achieve such knowledge, and having achieved it he quickly attains the supreme spiritual peace.
But ignorant and faithless persons who doubt the revealed scriptures do not attain God consciousness; they fall down. For the doubting soul there is happiness neither in this world nor in the next.
One who acts in devotional service, renouncing the fruits of his actions, and whose doubts have been destroyed by transcendental knowledge, is situated factually in the self. Thus he is not bound by the reactions of work, O conqueror of riches.
Therefore the doubts which have arisen in your heart out of ignorance should be slashed by the weapon of knowledge. Armed with yoga, O Bhārata, stand and fight.

Arjuna said: O Kṛṣṇa, first of all You ask me to renounce work, and then again You recommend work with devotion. Now will You kindly tell me definitely which of the two is more beneficial?
The Personality of Godhead replied: The renunciation of work and work in devotion are both good for liberation. But, of the two, work in devotional service is better than renunciation of work.
One who neither hates nor desires the fruits of his activities is known to be always renounced. Such a person, free from all dualities, easily overcomes material bondage and is completely liberated, O mighty-armed Arjuna.
Only the ignorant speak of devotional service [karma-yoga] as being different from the analytical study of the material world [Sāńkhya]. Those who are actually learned say that he who applies himself well to one of these paths achieves the results of both.
One who knows that the position reached by means of analytical study can also be attained by devotional service, and who therefore sees analytical study and devotional service to be on the same level, sees things as they are.
Merely renouncing all activities yet not engaging in the devotional service of the Lord cannot make one happy. But a thoughtful person engaged in devotional service can achieve the Supreme without delay.
One who works in devotion, who is a pure soul, and who controls his mind and senses is dear to everyone, and everyone is dear to him. Though always working, such a man is never entangled.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
A person in the divine consciousness, although engaged in seeing, hearing, touching, smelling, eating, moving about, sleeping and breathing, always knows within himself that he actually does nothing at all. Because while speaking, evacuating, receiving, or opening or closing his eyes, he always knows that only the material senses are engaged with their objects and that he is aloof from them.
One who performs his duty without attachment, surrendering the results unto the Supreme Lord, is unaffected by sinful action, as the lotus leaf is untouched by water.
The yogīs, abandoning attachment, act with body, mind, intelligence and even with the senses, only for the purpose of purification.
The steadily devoted soul attains unadulterated peace because he offers the result of all activities to Me; whereas a person who is not in union with the Divine, who is greedy for the fruits of his labor, becomes entangled.
When the embodied living being controls his nature and mentally renounces all actions, he resides happily in the city of nine gates [the material body], neither working nor causing work to be done.
The embodied spirit, master of the city of his body, does not create activities, nor does he induce people to act, nor does he create the fruits of action. All this is enacted by the modes of material nature.
Nor does the Supreme Lord assume anyone's sinful or pious activities. Embodied beings, however, are bewildered because of the ignorance which covers their real knowledge.
When, however, one is enlightened with the knowledge by which nescience is destroyed, then his knowledge reveals everything, as the sun lights up everything in the daytime.
When one's intelligence, mind, faith and refuge are all fixed in the Supreme, then one becomes fully cleansed of misgivings through complete knowledge and thus proceeds straight on the path of liberation.
The humble sages, by virtue of true knowledge, see with equal vision a learned and gentle brāhmaṇa, a cow, an elephant, a dog and a dog-eater [outcaste].
Those whose minds are established in sameness and equanimity have already conquered the conditions of birth and death. They are flawless like Brahman, and thus they are already situated in Brahman.
A person who neither rejoices upon achieving something pleasant nor laments upon obtaining something unpleasant, who is self-intelligent, who is unbewildered, and who knows the science of God, is already situated in transcendence.
Such a liberated person is not attracted to material sense pleasure but is always in trance, enjoying the pleasure within. In this way the self-realized person enjoys unlimited happiness, for he concentrates on the Supreme.
An intelligent person does not take part in the sources of misery, which are due to contact with the material senses. O son of Kuntī, such pleasures have a beginning and an end, and so the wise man does not delight in them.
Before giving up this present body, if one is able to tolerate the urges of the material senses and check the force of desire and anger, he is well situated and is happy in this world.
One whose happiness is within, who is active and rejoices within, and whose aim is inward is actually the perfect mystic. He is liberated in the Supreme, and ultimately he attains the Supreme.
Those who are beyond the dualities that arise from doubts, whose minds are engaged within, who are always busy working for the welfare of all living beings, and who are free from all sins achieve liberation in the Supreme.
Those who are free from anger and all material desires, who are self-realized, self-disciplined and constantly endeavoring for perfection, are assured of liberation in the Supreme in the very near future.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
Shutting out all external sense objects, keeping the eyes and vision concentrated between the two eyebrows, suspending the inward and outward breaths within the nostrils, and thus controlling the mind, senses and intelligence, the transcendentalist aiming at liberation becomes free from desire, fear and anger. One who is always in this state is certainly liberated.
A person in full consciousness of Me, knowing Me to be the ultimate beneficiary of all sacrifices and austerities, the Supreme Lord of all planets and demigods, and the benefactor and well-wisher of all living entities, attains peace from the pangs of material miseries.

The Supreme Personality of Godhead said: One who is unattached to the fruits of his work and who works as he is obligated is in the renounced order of life, and he is the true mystic, not he who lights no fire and performs no duty.
What is called renunciation you should know to be the same as yoga, or linking oneself with the Supreme, O son of Pāṇḍu, for one can never become a yogī unless he renounces the desire for sense gratification.
For one who is a neophyte in the eightfold yoga system, work is said to be the means; and for one who is already elevated in yoga, cessation of all material activities is said to be the means.
A person is said to be elevated in yoga when, having renounced all material desires, he neither acts for sense gratification nor engages in fruitive activities.
One must deliver himself with the help of his mind, and not degrade himself. The mind is the friend of the conditioned soul, and his enemy as well.
For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his mind will remain the greatest enemy.
For one who has conquered the mind, the Supersoul is already reached, for he has attained tranquillity. To such a man happiness and distress, heat and cold, honor and dishonor are all the same.
A person is said to be established in self-realization and is called a yogī [or mystic] when he is fully satisfied by virtue of acquired knowledge and realization. Such a person is situated in transcendence and is self-controlled. He sees everything — whether it be pebbles, stones or gold — as the same.
A person is considered still further advanced when he regards honest well-wishers, affectionate benefactors, the neutral, mediators, the envious, friends and enemies, the pious and the sinners all with an equal mind.
A transcendentalist should always engage his body, mind and self in relationship with the Supreme; he should live alone in a secluded place and should always carefully control his mind. He should be free from desires and feelings of possessiveness.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
To practice yoga, one should go to a secluded place and should lay kuśa grass on the ground and then cover it with a deerskin and a soft cloth. The seat should be neither too high nor too low and should be situated in a sacred place. The yogī should then sit on it very firmly and practice yoga to purify the heart by controlling his mind, senses and activities and fixing the mind on one point.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
One should hold one's body, neck and head erect in a straight line and stare steadily at the tip of the nose. Thus, with an unagitated, subdued mind, devoid of fear, completely free from sex life, one should meditate upon Me within the heart and make Me the ultimate goal of life.
Thus practicing constant control of the body, mind and activities, the mystic transcendentalist, his mind regulated, attains to the kingdom of God [or the abode of Kṛṣṇa] by cessation of material existence.
There is no possibility of one's becoming a yogī, O Arjuna, if one eats too much or eats too little, sleeps too much or does not sleep enough.
He who is regulated in his habits of eating, sleeping, recreation and work can mitigate all material pains by practicing the yoga system.
When the yogī, by practice of yoga, disciplines his mental activities and becomes situated in transcendence — devoid of all material desires — he is said to be well established in yoga.
As a lamp in a windless place does not waver, so the transcendentalist, whose mind is controlled, remains always steady in his meditation on the transcendent self.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
In the stage of perfection called trance, or samādhi, one's mind is completely restrained from material mental activities by practice of yoga. This perfection is characterized by one's ability to see the self by the pure mind and to relish and rejoice in the self. In that joyous state, one is situated in boundless transcendental happiness, realized through transcendental senses. Established thus, one never departs from the truth, and upon gaining this he thinks there is no greater gain. Being situated in such a position, one is never shaken, even in the midst of greatest difficulty. This indeed is actual freedom from all miseries arising from material contact.
One should engage oneself in the practice of yoga with determination and faith and not be deviated from the path. One should abandon, without exception, all material desires born of mental speculation and thus control all the senses on all sides by the mind.
Gradually, step by step, one should become situated in trance by means of intelligence sustained by full conviction, and thus the mind should be fixed on the self alone and should think of nothing else.
From wherever the mind wanders due to its flickering and unsteady nature, one must certainly withdraw it and bring it back under the control of the self.
The yogī whose mind is fixed on Me verily attains the highest perfection of transcendental happiness. He is beyond the mode of passion, he realizes his qualitative identity with the Supreme, and thus he is freed from all reactions to past deeds.
Thus the self-controlled yogī, constantly engaged in yoga practice, becomes free from all material contamination and achieves the highest stage of perfect happiness in transcendental loving service to the Lord.
A true yogī observes Me in all beings and also sees every being in Me. Indeed, the self-realized person sees Me, the same Supreme Lord, everywhere.
For one who sees Me everywhere and sees everything in Me, I am never lost, nor is he ever lost to Me.
Such a yogī, who engages in the worshipful service of the Supersoul, knowing that I and the Supersoul are one, remains always in Me in all circumstances.
He is a perfect yogī who, by comparison to his own self, sees the true equality of all beings, in both their happiness and their distress, O Arjuna!
Arjuna said: O Madhusūdana, the system of yoga which You have summarized appears impractical and unendurable to me, for the mind is restless and unsteady.
For the mind is restless, turbulent, obstinate and very strong, O Kṛṣṇa, and to subdue it, I think, is more difficult than controlling the wind.
Lord Śrī Kṛṣṇa said: O mighty-armed son of Kuntī, it is undoubtedly very difficult to curb the restless mind, but it is possible by suitable practice and by detachment.
For one whose mind is unbridled, self-realization is difficult work. But he whose mind is controlled and who strives by appropriate means is assured of success. That is My opinion.
Arjuna said: O Kṛṣṇa, what is the destination of the unsuccessful transcendentalist, who in the beginning takes to the process of self-realization with faith but who later desists due to worldly-mindedness and thus does not attain perfection in mysticism?
O mighty-armed Kṛṣṇa, does not such a man, who is bewildered from the path of transcendence, fall away from both spiritual and material success and perish like a riven cloud, with no position in any sphere?
This is my doubt, O Kṛṣṇa, and I ask You to dispel it completely. But for You, no one is to be found who can destroy this doubt.
The Supreme Personality of Godhead said: Son of Pṛthā, a transcendentalist engaged in auspicious activities does not meet with destruction either in this world or in the spiritual world; one who does good, My friend, is never overcome by evil.
The unsuccessful yogī, after many, many years of enjoyment on the planets of the pious living entities, is born into a family of righteous people, or into a family of rich aristocracy.
Or [if unsuccessful after long practice of yoga] he takes his birth in a family of transcendentalists who are surely great in wisdom. Certainly, such a birth is rare in this world.
On taking such a birth, he revives the divine consciousness of his previous life, and he again tries to make further progress in order to achieve complete success, O son of Kuru.
By virtue of the divine consciousness of his previous life, he automatically becomes attracted to the yogic principles — even without seeking them. Such an inquisitive transcendentalist stands always above the ritualistic principles of the scriptures.
And when the yogī engages himself with sincere endeavor in making further progress, being washed of all contaminations, then ultimately, achieving perfection after many, many births of practice, he attains the supreme goal.
A yogī is greater than the ascetic, greater than the empiricist and greater than the fruitive worker. Therefore, O Arjuna, in all circumstances, be a yogī.
And of all yogīs, the one with great faith who always abides in Me, thinks of Me within himself, and renders transcendental loving service to Me — he is the most intimately united with Me in yoga and is the highest of all. That is My opinion.

The Supreme Personality of Godhead said: Now hear, O son of Pṛthā, how by practicing yoga in full consciousness of Me, with mind attached to Me, you can know Me in full, free from doubt.
I shall now declare unto you in full this knowledge, both phenomenal and numinous. This being known, nothing further shall remain for you to know.
Out of many thousands among men, one may endeavor for perfection, and of those who have achieved perfection, hardly one knows Me in truth.
Earth, water, fire, air, ether, mind, intelligence and false ego — all together these eight constitute My separated material energies.
Besides these, O mighty-armed Arjuna, there is another, superior energy of Mine, which comprises the living entities who are exploiting the resources of this material, inferior nature.
All created beings have their source in these two natures. Of all that is material and all that is spiritual in this world, know for certain that I am both the origin and the dissolution.
O conqueror of wealth, there is no truth superior to Me. Everything rests upon Me, as pearls are strung on a thread.
O son of Kuntī, I am the taste of water, the light of the sun and the moon, the syllable oḿ in the Vedic mantras; I am the sound in ether and ability in man.
I am the original fragrance of the earth, and I am the heat in fire. I am the life of all that lives, and I am the penances of all ascetics.
O son of Pṛthā, know that I am the original seed of all existences, the intelligence of the intelligent, and the prowess of all powerful men.
I am the strength of the strong, devoid of passion and desire. I am sex life which is not contrary to religious principles, O lord of the Bhāratas [Arjuna].
Know that all states of being — be they of goodness, passion or ignorance — are manifested by My energy. I am, in one sense, everything, but I am independent. I am not under the modes of material nature, for they, on the contrary, are within Me.
Deluded by the three modes [goodness, passion and ignorance], the whole world does not know Me, who am above the modes and inexhaustible.
This divine energy of Mine, consisting of the three modes of material nature, is difficult to overcome. But those who have surrendered unto Me can easily cross beyond it.
Those miscreants who are grossly foolish, who are lowest among mankind, whose knowledge is stolen by illusion, and who partake of the atheistic nature of demons do not surrender unto Me.
O best among the Bhāratas, four kinds of pious men begin to render devotional service unto Me — the distressed, the desirer of wealth, the inquisitive, and he who is searching for knowledge of the Absolute.
Of these, the one who is in full knowledge and who is always engaged in pure devotional service is the best. For I am very dear to him, and he is dear to Me.
All these devotees are undoubtedly magnanimous souls, but he who is situated in knowledge of Me I consider to be just like My own self. Being engaged in My transcendental service, he is sure to attain Me, the highest and most perfect goal.
After many births and deaths, he who is actually in knowledge surrenders unto Me, knowing Me to be the cause of all causes and all that is. Such a great soul is very rare.
Those whose intelligence has been stolen by material desires surrender unto demigods and follow the particular rules and regulations of worship according to their own natures.
I am in everyone's heart as the Supersoul. As soon as one desires to worship some demigod, I make his faith steady so that he can devote himself to that particular deity.
Endowed with such a faith, he endeavors to worship a particular demigod and obtains his desires. But in actuality these benefits are bestowed by Me alone.
Men of small intelligence worship the demigods, and their fruits are limited and temporary. Those who worship the demigods go to the planets of the demigods, but My devotees ultimately reach My supreme planet.
Unintelligent men, who do not know Me perfectly, think that I, the Supreme Personality of Godhead, Kṛṣṇa, was impersonal before and have now assumed this personality. Due to their small knowledge, they do not know My higher nature, which is imperishable and supreme.
I am never manifest to the foolish and unintelligent. For them I am covered by My internal potency, and therefore they do not know that I am unborn and infallible.
O Arjuna, as the Supreme Personality of Godhead, I know everything that has happened in the past, all that is happening in the present, and all things that are yet to come. I also know all living entities; but Me no one knows.
O scion of Bharata, O conqueror of the foe, all living entities are born into delusion, bewildered by dualities arisen from desire and hate.
Persons who have acted piously in previous lives and in this life and whose sinful actions are completely eradicated are freed from the dualities of delusion, and they engage themselves in My service with determination.
Intelligent persons who are endeavoring for liberation from old age and death take refuge in Me in devotional service. They are actually Brahman because they entirely know everything about transcendental activities.
Those in full consciousness of Me, who know Me, the Supreme Lord, to be the governing principle of the material manifestation, of the demigods, and of all methods of sacrifice, can understand and know Me, the Supreme Personality of Godhead, even at the time of death.

Arjuna inquired: O my Lord, O Supreme Person, what is Brahman? What is the self? What are fruitive activities? What is this material manifestation? And what are the demigods? Please explain this to me.
Who is the Lord of sacrifice, and how does He live in the body, O Madhusūdana? And how can those engaged in devotional service know You at the time of death?
The Supreme Personality of Godhead said: The indestructible, transcendental living entity is called Brahman, and his eternal nature is called adhyātma, the self. Action pertaining to the development of the material bodies of the living entities is called karma, or fruitive activities.
O best of the embodied beings, the physical nature, which is constantly changing, is called adhibhūta [the material manifestation]. The universal form of the Lord, which includes all the demigods, like those of the sun and moon, is called adhidaiva. And I, the Supreme Lord, represented as the Supersoul in the heart of every embodied being, am called adhiyajña [the Lord of sacrifice].
And whoever, at the end of his life, quits his body, remembering Me alone, at once attains My nature. Of this there is no doubt.
Whatever state of being one remembers when he quits his body, O son of Kuntī, that state he will attain without fail.
Therefore, Arjuna, you should always think of Me in the form of Kṛṣṇa and at the same time carry out your prescribed duty of fighting. With your activities dedicated to Me and your mind and intelligence fixed on Me, you will attain Me without doubt.
He who meditates on Me as the Supreme Personality of Godhead, his mind constantly engaged in remembering Me, undeviated from the path, he, O Pārtha, is sure to reach Me.
One should meditate upon the Supreme Person as the one who knows everything, as He who is the oldest, who is the controller, who is smaller than the smallest, who is the maintainer of everything, who is beyond all material conception, who is inconceivable, and who is always a person. He is luminous like the sun, and He is transcendental, beyond this material nature.
One who, at the time of death, fixes his life air between the eyebrows and, by the strength of yoga, with an undeviating mind, engages himself in remembering the Supreme Lord in full devotion, will certainly attain to the Supreme Personality of Godhead.
Persons who are learned in the Vedas, who utter oḿkāra and who are great sages in the renounced order enter into Brahman. Desiring such perfection, one practices celibacy. I shall now briefly explain to you this process by which one may attain salvation.
The yogic situation is that of detachment from all sensual engagements. Closing all the doors of the senses and fixing the mind on the heart and the life air at the top of the head, one establishes himself in yoga.
After being situated in this yoga practice and vibrating the sacred syllable oḿ, the supreme combination of letters, if one thinks of the Supreme Personality of Godhead and quits his body, he will certainly reach the spiritual planets.
For one who always remembers Me without deviation, I am easy to obtain, O son of Pṛthā, because of his constant engagement in devotional service.
After attaining Me, the great souls, who are yogīs in devotion, never return to this temporary world, which is full of miseries, because they have attained the highest perfection.
From the highest planet in the material world down to the lowest, all are places of misery wherein repeated birth and death take place. But one who attains to My abode, O son of Kuntī, never takes birth again.
By human calculation, a thousand ages taken together form the duration of Brahmā's one day. And such also is the duration of his night.
At the beginning of Brahmā's day, all living entities become manifest from the unmanifest state, and thereafter, when the night falls, they are merged into the unmanifest again.
Again and again, when Brahmā's day arrives, all living entities come into being, and with the arrival of Brahmā's night they are helplessly annihilated.
Yet there is another unmanifest nature, which is eternal and is transcendental to this manifested and unmanifested matter. It is supreme and is never annihilated. When all in this world is annihilated, that part remains as it is.
That which the Vedāntists describe as unmanifest and infallible, that which is known as the supreme destination, that place from which, having attained it, one never returns — that is My supreme abode.
The Supreme Personality of Godhead, who is greater than all, is attainable by unalloyed devotion. Although He is present in His abode, He is all-pervading, and everything is situated within Him.
O best of the Bhāratas, I shall now explain to you the different times at which, passing away from this world, the yogī does or does not come back.
Those who know the Supreme Brahman attain that Supreme by passing away from the world during the influence of the fiery god, in the light, at an auspicious moment of the day, during the fortnight of the waxing moon, or during the six months when the sun travels in the north.
The mystic who passes away from this world during the smoke, the night, the fortnight of the waning moon, or the six months when the sun passes to the south reaches the moon planet but again comes back.
According to Vedic opinion, there are two ways of passing from this world — one in light and one in darkness. When one passes in light, he does not come back; but when one passes in darkness, he returns.
Although the devotees know these two paths, O Arjuna, they are never bewildered. Therefore be always fixed in devotion.
A person who accepts the path of devotional service is not bereft of the results derived from studying the Vedas, performing austere sacrifices, giving charity or pursuing philosophical and fruitive activities. Simply by performing devotional service, he attains all these, and at the end he reaches the supreme eternal abode.

The Supreme Personality of Godhead said: My dear Arjuna, because you are never envious of Me, I shall impart to you this most confidential knowledge and realization, knowing which you shall be relieved of the miseries of material existence.
This knowledge is the king of education, the most secret of all secrets. It is the purest knowledge, and because it gives direct perception of the self by realization, it is the perfection of religion. It is everlasting, and it is joyfully performed.
Those who are not faithful in this devotional service cannot attain Me, O conqueror of enemies. Therefore they return to the path of birth and death in this material world.
By Me, in My unmanifested form, this entire universe is pervaded. All beings are in Me, but I am not in them.
And yet everything that is created does not rest in Me. Behold My mystic opulence! Although I am the maintainer of all living entities and although I am everywhere, I am not a part of this cosmic manifestation, for My Self is the very source of creation.
Understand that as the mighty wind, blowing everywhere, rests always in the sky, all created beings rest in Me.
O son of Kuntī, at the end of the millennium all material manifestations enter into My nature, and at the beginning of another millennium, by My potency, I create them again.
The whole cosmic order is under Me. Under My will it is automatically manifested again and again, and under My will it is annihilated at the end.
O Dhanañjaya, all this work cannot bind Me. I am ever detached from all these material activities, seated as though neutral.
This material nature, which is one of My energies, is working under My direction, O son of Kuntī, producing all moving and nonmoving beings. Under its rule this manifestation is created and annihilated again and again.
Fools deride Me when I descend in the human form. They do not know My transcendental nature as the Supreme Lord of all that be.
Those who are thus bewildered are attracted by demonic and atheistic views. In that deluded condition, their hopes for liberation, their fruitive activities, and their culture of knowledge are all defeated.
O son of Pṛthā, those who are not deluded, the great souls, are under the protection of the divine nature. They are fully engaged in devotional service because they know Me as the Supreme Personality of Godhead, original and inexhaustible.
Always chanting My glories, endeavoring with great determination, bowing down before Me, these great souls perpetually worship Me with devotion.
Others, who engage in sacrifice by the cultivation of knowledge, worship the Supreme Lord as the one without a second, as diverse in many, and in the universal form.
But it is I who am the ritual, I the sacrifice, the offering to the ancestors, the healing herb, the transcendental chant. I am the butter and the fire and the offering.
I am the father of this universe, the mother, the support and the grandsire. I am the object of knowledge, the purifier and the syllable oḿ. I am also the Ṛg, the Sāma and the Yajur Vedas.
I am the goal, the sustainer, the master, the witness, the abode, the refuge, and the most dear friend. I am the creation and the annihilation, the basis of everything, the resting place and the eternal seed.
O Arjuna, I give heat, and I withhold and send forth the rain. I am immortality, and I am also death personified. Both spirit and matter are in Me.
Those who study the Vedas and drink the soma juice, seeking the heavenly planets, worship Me indirectly. Purified of sinful reactions, they take birth on the pious, heavenly planet of Indra, where they enjoy godly delights.
When they have thus enjoyed vast heavenly sense pleasure and the results of their pious activities are exhausted, they return to this mortal planet again. Thus those who seek sense enjoyment by adhering to the principles of the three Vedas achieve only repeated birth and death.
But those who always worship Me with exclusive devotion, meditating on My transcendental form — to them I carry what they lack, and I preserve what they have.
Those who are devotees of other gods and who worship them with faith actually worship only Me, O son of Kuntī, but they do so in a wrong way.
I am the only enjoyer and master of all sacrifices. Therefore, those who do not recognize My true transcendental nature fall down.
Those who worship the demigods will take birth among the demigods; those who worship the ancestors go to the ancestors; those who worship ghosts and spirits will take birth among such beings; and those who worship Me will live with Me.
If one offers Me with love and devotion a leaf, a flower, fruit or water, I will accept it.
Whatever you do, whatever you eat, whatever you offer or give away, and whatever austerities you perform — do that, O son of Kuntī, as an offering to Me.
In this way you will be freed from bondage to work and its auspicious and inauspicious results. With your mind fixed on Me in this principle of renunciation, you will be liberated and come to Me.
I envy no one, nor am I partial to anyone. I am equal to all. But whoever renders service unto Me in devotion is a friend, is in Me, and I am also a friend to him.
Even if one commits the most abominable action, if he is engaged in devotional service he is to be considered saintly because he is properly situated in his determination.
He quickly becomes righteous and attains lasting peace. O son of Kuntī, declare it boldly that My devotee never perishes.
O son of Pṛthā, those who take shelter in Me, though they be of lower birth — women, vaiśyas [merchants] and śūdras [workers] — can attain the supreme destination.
How much more this is so of the righteous brāhmaṇas, the devotees and the saintly kings. Therefore, having come to this temporary, miserable world, engage in loving service unto Me.
Engage your mind always in thinking of Me, become My devotee, offer obeisances to Me and worship Me. Being completely absorbed in Me, surely you will come to Me.

The Supreme Personality of Godhead said: Listen again, O mighty-armed Arjuna. Because you are My dear friend, for your benefit I shall speak to you further, giving knowledge that is better than what I have already explained.
Neither the hosts of demigods nor the great sages know My origin or opulences, for, in every respect, I am the source of the demigods and sages.
He who knows Me as the unborn, as the beginningless, as the Supreme Lord of all the worlds — he only, undeluded among men, is freed from all sins.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
Intelligence, knowledge, freedom from doubt and delusion, forgiveness, truthfulness, control of the senses, control of the mind, happiness and distress, birth, death, fear, fearlessness, nonviolence, equanimity, satisfaction, austerity, charity, fame and infamy — all these various qualities of living beings are created by Me alone.
The seven great sages and before them the four other great sages and the Manus [progenitors of mankind] come from Me, born from My mind, and all the living beings populating the various planets descend from them.
One who is factually convinced of this opulence and mystic power of Mine engages in unalloyed devotional service; of this there is no doubt.
I am the source of all spiritual and material worlds. Everything emanates from Me. The wise who perfectly know this engage in My devotional service and worship Me with all their hearts.
The thoughts of My pure devotees dwell in Me, their lives are fully devoted to My service, and they derive great satisfaction and bliss from always enlightening one another and conversing about Me.
To those who are constantly devoted to serving Me with love, I give the understanding by which they can come to Me.
To show them special mercy, I, dwelling in their hearts, destroy with the shining lamp of knowledge the darkness born of ignorance.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
Arjuna said: You are the Supreme Personality of Godhead, the ultimate abode, the purest, the Absolute Truth. You are the eternal, transcendental, original person, the unborn, the greatest. All the great sages such as Nārada, Asita, Devala and Vyāsa confirm this truth about You, and now You Yourself are declaring it to me.
O Kṛṣṇa, I totally accept as truth all that You have told me. Neither the demigods nor the demons, O Lord, can understand Your personality.
Indeed, You alone know Yourself by Your own internal potency, O Supreme Person, origin of all, Lord of all beings, God of gods, Lord of the universe!
Please tell me in detail of Your divine opulences by which You pervade all these worlds.
O Kṛṣṇa, O supreme mystic, how shall I constantly think of You, and how shall I know You? In what various forms are You to be remembered, O Supreme Personality of Godhead?
O Janārdana, again please describe in detail the mystic power of Your opulences. I am never satiated in hearing about You, for the more I hear the more I want to taste the nectar of Your words.
The Supreme Personality of Godhead said: Yes, I will tell you of My splendorous manifestations, but only of those which are prominent, O Arjuna, for My opulence is limitless.
I am the Supersoul, O Arjuna, seated in the hearts of all living entities. I am the beginning, the middle and the end of all beings.
Of the Ādityas I am Viṣṇu, of lights I am the radiant sun, of the Maruts I am Marīci, and among the stars I am the moon.
Of the Vedas I am the Sāma Veda; of the demigods I am Indra, the king of heaven; of the senses I am the mind; and in living beings I am the living force [consciousness].
Of all the Rudras I am Lord Śiva, of the Yakṣas and Rākṣasas I am the Lord of wealth [Kuvera], of the Vasus I am fire [Agni], and of mountains I am Meru.
Of priests, O Arjuna, know Me to be the chief, Bṛhaspati. Of generals I am Kārtikeya, and of bodies of water I am the ocean.
Of the great sages I am Bhṛgu; of vibrations I am the transcendental oḿ. Of sacrifices I am the chanting of the holy names [japa], and of immovable things I am the Himālayas.
Of all trees I am the banyan tree, and of the sages among the demigods I am Nārada. Of the Gandharvas I am Citraratha, and among perfected beings I am the sage Kapila.
Of horses know Me to be Uccaiḥśravā, produced during the churning of the ocean for nectar. Of lordly elephants I am Airāvata, and among men I am the monarch.
Of weapons I am the thunderbolt; among cows I am the surabhi. Of causes for procreation I am Kandarpa, the god of love, and of serpents I am Vāsuki.
Of the many-hooded Nāgas I am Ananta, and among the aquatics I am the demigod Varuṇa. Of departed ancestors I am Aryamā, and among the dispensers of law I am Yama, the lord of death.
Among the Daitya demons I am the devoted Prahlāda, among subduers I am time, among beasts I am the lion, and among birds I am Garuḍa.
Of purifiers I am the wind, of the wielders of weapons I am Rāma, of fishes I am the shark, and of flowing rivers I am the Ganges.
Of all creations I am the beginning and the end and also the middle, O Arjuna. Of all sciences I am the spiritual science of the self, and among logicians I am the conclusive truth.
Of letters I am the letter A, and among compound words I am the dual compound. I am also inexhaustible time, and of creators I am Brahmā.
I am all-devouring death, and I am the generating principle of all that is yet to be. Among women I am fame, fortune, fine speech, memory, intelligence, steadfastness and patience.
Of the hymns in the Sāma Veda I am the Bṛhat-sāma, and of poetry I am the Gāyatrī. Of months I am Mārgaśīrṣa [November-December], and of seasons I am flower-bearing spring.
I am also the gambling of cheats, and of the splendid I am the splendor. I am victory, I am adventure, and I am the strength of the strong.
Of the descendants of Vṛṣṇi I am Vāsudeva, and of the Pāṇḍavas I am Arjuna. Of the sages I am Vyāsa, and among great thinkers I am Uśanā.
Among all means of suppressing lawlessness I am punishment, and of those who seek victory I am morality. Of secret things I am silence, and of the wise I am the wisdom.
Furthermore, O Arjuna, I am the generating seed of all existences. There is no being — moving or nonmoving — that can exist without Me.
O mighty conqueror of enemies, there is no end to My divine manifestations. What I have spoken to you is but a mere indication of My infinite opulences.
Know that all opulent, beautiful and glorious creations spring from but a spark of My splendor.
But what need is there, Arjuna, for all this detailed knowledge? With a single fragment of Myself I pervade and support this entire universe.

Arjuna said: By my hearing the instructions You have kindly given me about these most confidential spiritual subjects, my illusion has now been dispelled.
O lotus-eyed one, I have heard from You in detail about the appearance and disappearance of every living entity and have realized Your inexhaustible glories.
O greatest of all personalities, O supreme form, though I see You here before me in Your actual position, as You have described Yourself, I wish to see how You have entered into this cosmic manifestation. I want to see that form of Yours.
If You think that I am able to behold Your cosmic form, O my Lord, O master of all mystic power, then kindly show me that unlimited universal Self.
The Supreme Personality of Godhead said: My dear Arjuna, O son of Pṛthā, see now My opulences, hundreds of thousands of varied divine and multicolored forms.
O best of the Bhāratas, see here the different manifestations of Ādityas, Vasus, Rudras, Aśvinī-kumāras and all the other demigods. Behold the many wonderful things which no one has ever seen or heard of before.
O Arjuna, whatever you wish to see, behold at once in this body of Mine! This universal form can show you whatever you now desire to see and whatever you may want to see in the future. Everything — moving and nonmoving — is here completely, in one place.
But you cannot see Me with your present eyes. Therefore I give you divine eyes. Behold My mystic opulence!
Sañjaya said: O King, having spoken thus, the Supreme Lord of all mystic power, the Personality of Godhead, displayed His universal form to Arjuna.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
Arjuna saw in that universal form unlimited mouths, unlimited eyes, unlimited wonderful visions. The form was decorated with many celestial ornaments and bore many divine upraised weapons. He wore celestial garlands and garments, and many divine scents were smeared over His body. All was wondrous, brilliant, unlimited, all-expanding.
If hundreds of thousands of suns were to rise at once into the sky, their radiance might resemble the effulgence of the Supreme Person in that universal form.
At that time Arjuna could see in the universal form of the Lord the unlimited expansions of the universe situated in one place although divided into many, many thousands.
Then, bewildered and astonished, his hair standing on end, Arjuna bowed his head to offer obeisances and with folded hands began to pray to the Supreme Lord.
Arjuna said: My dear Lord Kṛṣṇa, I see assembled in Your body all the demigods and various other living entities. I see Brahmā sitting on the lotus flower, as well as Lord Śiva and all the sages and divine serpents.
O Lord of the universe, O universal form, I see in Your body many, many arms, bellies, mouths and eyes, expanded everywhere, without limit. I see in You no end, no middle and no beginning.
Your form is difficult to see because of its glaring effulgence, spreading on all sides, like blazing fire or the immeasurable radiance of the sun. Yet I see this glowing form everywhere, adorned with various crowns, clubs and discs.
You are the supreme primal objective. You are the ultimate resting place of all this universe. You are inexhaustible, and You are the oldest. You are the maintainer of the eternal religion, the Personality of Godhead. This is my opinion.
You are without origin, middle or end. Your glory is unlimited. You have numberless arms, and the sun and moon are Your eyes. I see You with blazing fire coming forth from Your mouth, burning this entire universe by Your own radiance.
Although You are one, You spread throughout the sky and the planets and all space between. O great one, seeing this wondrous and terrible form, all the planetary systems are perturbed.
All the hosts of demigods are surrendering before You and entering into You. Some of them, very much afraid, are offering prayers with folded hands. Hosts of great sages and perfected beings, crying "All peace!" are praying to You by singing the Vedic hymns.
All the various manifestations of Lord Śiva, the Ādityas, the Vasus, the Sādhyas, the Viśvedevas, the two Aśvīs, the Maruts, the forefathers, the Gandharvas, the Yakṣas, the Asuras and the perfected demigods are beholding You in wonder.
O mighty-armed one, all the planets with their demigods are disturbed at seeing Your great form, with its many faces, eyes, arms, thighs, legs, and bellies and Your many terrible teeth; and as they are disturbed, so am I.
O all-pervading Viṣṇu, seeing You with Your many radiant colors touching the sky, Your gaping mouths, and Your great glowing eyes, my mind is perturbed by fear. I can no longer maintain my steadiness or equilibrium of mind.
O Lord of lords, O refuge of the worlds, please be gracious to me. I cannot keep my balance seeing thus Your blazing deathlike faces and awful teeth. In all directions I am bewildered.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
All the sons of Dhṛtarāṣṭra, along with their allied kings, and Bhīṣma, Droṇa, Karṇa — and our chief soldiers also — are rushing into Your fearful mouths. And some I see trapped with heads smashed between Your teeth.
As the many waves of the rivers flow into the ocean, so do all these great warriors enter blazing into Your mouths.
I see all people rushing full speed into Your mouths, as moths dash to destruction in a blazing fire.
O Viṣṇu, I see You devouring all people from all sides with Your flaming mouths. Covering all the universe with Your effulgence, You are manifest with terrible, scorching rays.
O Lord of lords, so fierce of form, please tell me who You are. I offer my obeisances unto You; please be gracious to me. You are the primal Lord. I want to know about You, for I do not know what Your mission is.
The Supreme Personality of Godhead said: Time I am, the great destroyer of the worlds, and I have come here to destroy all people. With the exception of you [the Pāṇḍavas], all the soldiers here on both sides will be slain.
Therefore get up. Prepare to fight and win glory. Conquer your enemies and enjoy a flourishing kingdom. They are already put to death by My arrangement, and you, O Savyasācī, can be but an instrument in the fight.
Droṇa, Bhīṣma, Jayadratha, Karṇa and the other great warriors have already been destroyed by Me. Therefore, kill them and do not be disturbed. Simply fight, and you will vanquish your enemies in battle.
Sañjaya said to Dhṛtarāṣṭra: O King, after hearing these words from the Supreme Personality of Godhead, the trembling Arjuna offered obeisances with folded hands again and again. He fearfully spoke to Lord Kṛṣṇa in a faltering voice, as follows.
Arjuna said: O master of the senses, the world becomes joyful upon hearing Your name, and thus everyone becomes attached to You. Although the perfected beings offer You their respectful homage, the demons are afraid, and they flee here and there. All this is rightly done.
O great one, greater even than Brahmā, You are the original creator. Why then should they not offer their respectful obeisances unto You? O limitless one, God of gods, refuge of the universe! You are the invincible source, the cause of all causes, transcendental to this material manifestation.
You are the original Personality of Godhead, the oldest, the ultimate sanctuary of this manifested cosmic world. You are the knower of everything, and You are all that is knowable. You are the supreme refuge, above the material modes. O limitless form! This whole cosmic manifestation is pervaded by You!
You are air, and You are the supreme controller! You are fire, You are water, and You are the moon! You are Brahmā, the first living creature, and You are the great-grandfather. I therefore offer my respectful obeisances unto You a thousand times, and again and yet again!
Obeisances to You from the front, from behind and from all sides! O unbounded power, You are the master of limitless might! You are all-pervading, and thus You are everything!
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
Thinking of You as my friend, I have rashly addressed You "O Kṛṣṇa," "O Yādava," "O my friend," not knowing Your glories. Please forgive whatever I may have done in madness or in love. I have dishonored You many times, jesting as we relaxed, lay on the same bed, or sat or ate together, sometimes alone and sometimes in front of many friends. O infallible one, please excuse me for all those offenses.
You are the father of this complete cosmic manifestation, of the moving and the nonmoving. You are its worshipable chief, the supreme spiritual master. No one is equal to You, nor can anyone be one with You. How then could there be anyone greater than You within the three worlds, O Lord of immeasurable power?
You are the Supreme Lord, to be worshiped by every living being. Thus I fall down to offer You my respectful obeisances and ask Your mercy. As a father tolerates the impudence of his son, or a friend tolerates the impertinence of a friend, or a wife tolerates the familiarity of her partner, please tolerate the wrongs I may have done You.
After seeing this universal form, which I have never seen before, I am gladdened, but at the same time my mind is disturbed with fear. Therefore please bestow Your grace upon me and reveal again Your form as the Personality of Godhead, O Lord of lords, O abode of the universe.
O universal form, O thousand-armed Lord, I wish to see You in Your four-armed form, with helmeted head and with club, wheel, conch and lotus flower in Your hands. I long to see You in that form.
The Supreme Personality of Godhead said: My dear Arjuna, happily have I shown you, by My internal potency, this supreme universal form within the material world. No one before you has ever seen this primal form, unlimited and full of glaring effulgence.
O best of the Kuru warriors, no one before you has ever seen this universal form of Mine, for neither by studying the Vedas, nor by performing sacrifices, nor by charity, nor by pious activities, nor by severe penances can I be seen in this form in the material world.
You have been perturbed and bewildered by seeing this horrible feature of Mine. Now let it be finished. My devotee, be free again from all disturbances. With a peaceful mind you can now see the form you desire.
Sañjaya said to Dhṛtarāṣṭra: The Supreme Personality of Godhead, Kṛṣṇa, having spoken thus to Arjuna, displayed His real four-armed form and at last showed His two-armed form, thus encouraging the fearful Arjuna.
When Arjuna thus saw Kṛṣṇa in His original form, he said: O Janārdana, seeing this humanlike form, so very beautiful, I am now composed in mind, and I am restored to my original nature.
The Supreme Personality of Godhead said: My dear Arjuna, this form of Mine you are now seeing is very difficult to behold. Even the demigods are ever seeking the opportunity to see this form, which is so dear.
The form you are seeing with your transcendental eyes cannot be understood simply by studying the Vedas, nor by undergoing serious penances, nor by charity, nor by worship. It is not by these means that one can see Me as I am.
My dear Arjuna, only by undivided devotional service can I be understood as I am, standing before you, and can thus be seen directly. Only in this way can you enter into the mysteries of My understanding.
My dear Arjuna, he who engages in My pure devotional service, free from the contaminations of fruitive activities and mental speculation, he who works for Me, who makes Me the supreme goal of his life, and who is friendly to every living being — he certainly comes to Me.

Arjuna inquired: Which are considered to be more perfect, those who are always properly engaged in Your devotional service or those who worship the impersonal Brahman, the unmanifested? 
The Supreme Personality of Godhead said: Those who fix their minds on My personal form and are always engaged in worshiping Me with great and transcendental faith are considered by Me to be most perfect. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
But those who fully worship the unmanifested, that which lies beyond the perception of the senses, the all-pervading, inconceivable, unchanging, fixed and immovable — the impersonal conception of the Absolute Truth — by controlling the various senses and being equally disposed to everyone, such persons, engaged in the welfare of all, at last achieve Me. 
For those whose minds are attached to the unmanifested, impersonal feature of the Supreme, advancement is very troublesome. To make progress in that discipline is always difficult for those who are embodied. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
But those who worship Me, giving up all their activities unto Me and being devoted to Me without deviation, engaged in devotional service and always meditating upon Me, having fixed their minds upon Me, O son of Prthā — for them I am the swift deliverer from the ocean of birth and death. 
Just fix your mind upon Me, the Supreme Personality of Godhead, and engage all your intelligence in Me. Thus you will live in Me always, without a doubt. 
My dear Arjuna, O winner of wealth, if you cannot fix your mind upon Me without deviation, then follow the regulative principles of bhakti-yoga. In this way develop a desire to attain Me. 
If you cannot practice the regulations of bhakti-yoga, then just try to work for Me, because by working for Me you will come to the perfect stage. 
If, however, you are unable to work in this consciousness of Me, then try to act giving up all results of your work and try to be self- situated. 
If you cannot take to this practice, then engage yourself in the cultivation of knowledge. Better than knowledge, however, is meditation, and better than meditation is renunciation of the fruits of action, for by such renunciation one can attain peace of mind. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
One who is not envious but is a kind friend to all living entities, who does not think himself a proprietor and is free from false ego, who is equal in both happiness and distress, who is tolerant, always satisfied, self-controlled, and engaged in devotional service with determination, his mind and intelligence fixed on Me — such a devotee of Mine is very dear to Me. 
He for whom no one is put into difficulty and who is not disturbed by anyone, who is equipoised in happiness and distress, fear and anxiety, is very dear to Me. 
My devotee who is not dependent on the ordinary course of activities, who is pure, expert, without cares, free from all pains, and not striving for some result, is very dear to Me. 
One who neither rejoices nor grieves, who neither laments nor desires, and who renounces both auspicious and inauspicious things — such a devotee is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
One who is equal to friends and enemies, who is equipoised in honor and dishonor, heat and cold, happiness and distress, fame and infamy, who is always free from contaminating association, always silent and satisfied with anything, who doesn't care for any residence, who is fixed in knowledge and who is engaged in devotional service — such a person is very dear to Me. 
Those who follow this imperishable path of devotional service and who completely engage themselves with faith, making Me the supreme goal, are very, very dear to Me.

Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
Arjuna said: O my dear Kṛṣṇa, I wish to know about prakṛti [nature], puruṣa [the enjoyer], and the field and the knower of the field, and of knowledge and the object of knowledge.The Supreme Personality of Godhead said : This body, O son of Kunti, is called the field, and one who knows this body is called the knower of the field.
O scion of Bharata, you should understand that I am also the knower in all bodies, and to understand this body and its knower is called knowledge. That is My opinion.
Now please hear My brief description of this field of activity and how it is constituted, what its changes are, whence it is produced, who that knower of the field of activities is, and what his influences are.
That knowledge of the field of activities and of the knower of activities is described by various sages in various Vedic writings. It is especially presented in Vedānta-sūtra with all reasoning as to cause and effect.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
The five great elements, false ego, intelligence, the unmanifested, the ten senses and the mind, the five sense objects, desire, hatred, happiness, distress, the aggregate, the life symptoms, and convictions — all these are considered, in summary, to be the field of activities and its interactions.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
Humility; pridelessness; nonviolence; tolerance; simplicity; approaching a bona fide spiritual master; cleanliness; steadiness; self-control; renunciation of the objects of sense gratification; absence of false ego; the perception of the evil of birth, death, old age and disease; detachment; freedom from entanglement with children, wife, home and the rest; even-mindedness amid pleasant and unpleasant events; constant and unalloyed devotion to Me; aspiring to live in a solitary place; detachment from the general mass of people; accepting the importance of self-realization; and philosophical search for the Absolute Truth — all these I declare to be knowledge, and besides this whatever there may be is ignorance.
I shall now explain the knowable, knowing which you will taste the eternal. Brahman, the spirit, beginningless and subordinate to Me, lies beyond the cause and effect of this material world.
Everywhere are His hands and legs, His eyes, heads and faces, and He has ears everywhere. In this way the Supersoul exists, pervading everything.
The Supersoul is the original source of all senses, yet He is without senses. He is unattached, although He is the maintainer of all living beings. He transcends the modes of nature, and at the same time He is the master of all the modes of material nature.
The Supreme Truth exists outside and inside of all living beings, the moving and the nonmoving. Because He is subtle, He is beyond the power of the material senses to see or to know. Although far, far away, He is also near to all.
Although the Supersoul appears to be divided among all beings, He is never divided. He is situated as one. Although He is the maintainer of every living entity, it is to be understood that He devours and develops all.
He is the source of light in all luminous objects. He is beyond the darkness of matter and is unmanifested. He is knowledge, He is the object of knowledge, and He is the goal of knowledge. He is situated in everyone's heart.
Thus the field of activities [the body], knowledge and the knowable have been summarily described by Me. Only My devotees can understand this thoroughly and thus attain to My nature.
Material nature and the living entities should be understood to be beginningless. Their transformations and the modes of matter are products of material nature.
Nature is said to be the cause of all material causes and effects, whereas the living entity is the cause of the various sufferings and enjoyments in this world.
The living entity in material nature thus follows the ways of life, enjoying the three modes of nature. This is due to his association with that material nature. Thus he meets with good and evil among various species.
Yet in this body there is another, a transcendental enjoyer, who is the Lord, the supreme proprietor, who exists as the overseer and permitter, and who is known as the Supersoul.
One who understands this philosophy concerning material nature, the living entity and the interaction of the modes of nature is sure to attain liberation. He will not take birth here again, regardless of his present position.
Some perceive the Supersoul within themselves through meditation, others through the cultivation of knowledge, and still others through working without fruitive desires.
Again there are those who, although not conversant in spiritual knowledge, begin to worship the Supreme Person upon hearing about Him from others. Because of their tendency to hear from authorities, they also transcend the path of birth and death.
O chief of the Bhāratas, know that whatever you see in existence, both the moving and the nonmoving, is only a combination of the field of activities and the knower of the field.
One who sees the Supersoul accompanying the individual soul in all bodies, and who understands that neither the soul nor the Supersoul within the destructible body is ever destroyed, actually sees.
One who sees the Supersoul equally present everywhere, in every living being, does not degrade himself by his mind. Thus he approaches the transcendental destination.
One who can see that all activities are performed by the body, which is created of material nature, and sees that the self does nothing, actually sees.
When a sensible man ceases to see different identities due to different material bodies and he sees how beings are expanded everywhere, he attains to the Brahman conception.
Those with the vision of eternity can see that the imperishable soul is transcendental, eternal, and beyond the modes of nature. Despite contact with the material body, O Arjuna, the soul neither does anything nor is entangled.
The sky, due to its subtle nature, does not mix with anything, although it is all-pervading. Similarly, the soul situated in Brahman vision does not mix with the body, though situated in that body.
O son of Bharata, as the sun alone illuminates all this universe, so does the living entity, one within the body, illuminate the entire body by consciousness.
Those who see with eyes of knowledge the difference between the body and the knower of the body, and can also understand the process of liberation from bondage in material nature, attain to the supreme goal.

The Supreme Personality of Godhead said: Again I shall declare to you this supreme wisdom, the best of all knowledge, knowing which all the sages have attained the supreme perfection.
By becoming fixed in this knowledge, one can attain to the transcendental nature like My own. Thus established, one is not born at the time of creation or disturbed at the time of dissolution.
The total material substance, called Brahman, is the source of birth, and it is that Brahman that I impregnate, making possible the births of all living beings, O son of Bharata.
It should be understood that all species of life, O son of Kuntī, are made possible by birth in this material nature, and that I am the seed-giving father.
Material nature consists of three modes — goodness, passion and ignorance. When the eternal living entity comes in contact with nature, O mighty-armed Arjuna, he becomes conditioned by these modes.
O sinless one, the mode of goodness, being purer than the others, is illuminating, and it frees one from all sinful reactions. Those situated in that mode become conditioned by a sense of happiness and knowledge.
The mode of passion is born of unlimited desires and longings, O son of Kuntī, and because of this the embodied living entity is bound to material fruitive actions.
O son of Bharata, know that the mode of darkness, born of ignorance, is the delusion of all embodied living entities. The results of this mode are madness, indolence and sleep, which bind the conditioned soul.
O son of Bharata, the mode of goodness conditions one to happiness; passion conditions one to fruitive action; and ignorance, covering one's knowledge, binds one to madness.
Sometimes the mode of goodness becomes prominent, defeating the modes of passion and ignorance, O son of Bharata. Sometimes the mode of passion defeats goodness and ignorance, and at other times ignorance defeats goodness and passion. In this way there is always competition for supremacy.
The manifestations of the mode of goodness can be experienced when all the gates of the body are illuminated by knowledge.
O chief of the Bhāratas, when there is an increase in the mode of passion the symptoms of great attachment, fruitive activity, intense endeavor, and uncontrollable desire and hankering develop.
When there is an increase in the mode of ignorance, O son of Kuru, darkness, inertia, madness and illusion are manifested.
When one dies in the mode of goodness, he attains to the pure higher planets of the great sages.
When one dies in the mode of passion, he takes birth among those engaged in fruitive activities; and when one dies in the mode of ignorance, he takes birth in the animal kingdom.
The result of pious action is pure and is said to be in the mode of goodness. But action done in the mode of passion results in misery, and action performed in the mode of ignorance results in foolishness.
From the mode of goodness, real knowledge develops; from the mode of passion, greed develops; and from the mode of ignorance develop foolishness, madness and illusion.
Those situated in the mode of goodness gradually go upward to the higher planets; those in the mode of passion live on the earthly planets; and those in the abominable mode of ignorance go down to the hellish worlds.
When one properly sees that in all activities no other performer is at work than these modes of nature and he knows the Supreme Lord, who is transcendental to all these modes, he attains My spiritual nature.
When the embodied being is able to transcend these three modes associated with the material body, he can become free from birth, death, old age and their distresses and can enjoy nectar even in this life.
Arjuna inquired: O my dear Lord, by which symptoms is one known who is transcendental to these three modes? What is his behavior? And how does he transcend the modes of nature?
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
The Supreme Personality of Godhead said: O son of Pāṇḍu, he who does not hate illumination, attachment and delusion when they are present or long for them when they disappear; who is unwavering and undisturbed through all these reactions of the material qualities, remaining neutral and transcendental, knowing that the modes alone are active; who is situated in the self and regards alike happiness and distress; who looks upon a lump of earth, a stone and a piece of gold with an equal eye; who is equal toward the desirable and the undesirable; who is steady, situated equally well in praise and blame, honor and dishonor; who treats alike both friend and enemy; and who has renounced all material activities — such a person is said to have transcended the modes of nature.
One who engages in full devotional service, unfailing in all circumstances, at once transcends the modes of material nature and thus comes to the level of Brahman.
And I am the basis of the impersonal Brahman, which is immortal, imperishable and eternal and is the constitutional position of ultimate happiness.

The Supreme Personality of Godhead said: It is said that there is an imperishable banyan tree that has its roots upward and its branches down and whose leaves are the Vedic hymns. One who knows this tree is the knower of the Vedas.
The branches of this tree extend downward and upward, nourished by the three modes of material nature. The twigs are the objects of the senses. This tree also has roots going down, and these are bound to the fruitive actions of human society.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
The real form of this tree cannot be perceived in this world. No one can understand where it ends, where it begins, or where its foundation is. But with determination one must cut down this strongly rooted tree with the weapon of detachment. Thereafter, one must seek that place from which, having gone, one never returns, and there surrender to that Supreme Personality of Godhead from whom everything began and from whom everything has extended since time immemorial.
Those who are free from false prestige, illusion and false association, who understand the eternal, who are done with material lust, who are freed from the dualities of happiness and distress, and who, unbewildered, know how to surrender unto the Supreme Person attain to that eternal kingdom.
That supreme abode of Mine is not illumined by the sun or moon, nor by fire or electricity. Those who reach it never return to this material world.
The living entities in this conditioned world are My eternal fragmental parts. Due to conditioned life, they are struggling very hard with the six senses, which include the mind.
The living entity in the material world carries his different conceptions of life from one body to another as the air carries aromas. Thus he takes one kind of body and again quits it to take another.
The living entity, thus taking another gross body, obtains a certain type of ear, eye, tongue, nose and sense of touch, which are grouped about the mind. He thus enjoys a particular set of sense objects.
The foolish cannot understand how a living entity can quit his body, nor can they understand what sort of body he enjoys under the spell of the modes of nature. But one whose eyes are trained in knowledge can see all this.
The endeavoring transcendentalists, who are situated in self-realization, can see all this clearly. But those whose minds are not developed and who are not situated in self-realization cannot see what is taking place, though they may try to.
The splendor of the sun, which dissipates the darkness of this whole world, comes from Me. And the splendor of the moon and the splendor of fire are also from Me.
I enter into each planet, and by My energy they stay in orbit. I become the moon and thereby supply the juice of life to all vegetables.
I am the fire of digestion in the bodies of all living entities, and I join with the air of life, outgoing and incoming, to digest the four kinds of foodstuff.
I am seated in everyone's heart, and from Me come remembrance, knowledge and forgetfulness. By all the Vedas, I am to be known. Indeed, I am the compiler of Vedānta, and I am the knower of the Vedas.
There are two classes of beings, the fallible and the infallible. In the material world every living entity is fallible, and in the spiritual world every living entity is called infallible.
Besides these two, there is the greatest living personality, the Supreme Soul, the imperishable Lord Himself, who has entered the three worlds and is maintaining them.
Because I am transcendental, beyond both the fallible and the infallible, and because I am the greatest, I am celebrated both in the world and in the Vedas as that Supreme Person.
Whoever knows Me as the Supreme Personality of Godhead, without doubting, is the knower of everything. He therefore engages himself in full devotional service to Me, O son of Bharata.
This is the most confidential part of the Vedic scriptures, O sinless one, and it is disclosed now by Me. Whoever understands this will become wise, and his endeavors will know perfection.

The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
The Supreme Personality of Godhead said: Fearlessness; purification of one's existence; cultivation of spiritual knowledge; charity; self-control; performance of sacrifice; study of the Vedas; austerity; simplicity; nonviolence; truthfulness; freedom from anger; renunciation; tranquillity; aversion to faultfinding; compassion for all living entities; freedom from covetousness; gentleness; modesty; steady determination; vigor; forgiveness; fortitude; cleanliness; and freedom from envy and from the passion for honor — these transcendental qualities, O son of Bharata, belong to godly men endowed with divine nature.
Pride, arrogance, conceit, anger, harshness and ignorance — these qualities belong to those of demoniac nature, O son of Pṛthā.
The transcendental qualities are conducive to liberation, whereas the demoniac qualities make for bondage. Do not worry, O son of Pāṇḍu, for you are born with the divine qualities.
O son of Pṛthā, in this world there are two kinds of created beings. One is called the divine and the other demoniac. I have already explained to you at length the divine qualities. Now hear from Me of the demoniac.
Those who are demoniac do not know what is to be done and what is not to be done. Neither cleanliness nor proper behavior nor truth is found in them.
They say that this world is unreal, with no foundation, no God in control. They say it is produced of sex desire and has no cause other than lust.
Following such conclusions, the demoniac, who are lost to themselves and who have no intelligence, engage in unbeneficial, horrible works meant to destroy the world.
Taking shelter of insatiable lust and absorbed in the conceit of pride and false prestige, the demoniac, thus illusioned, are always sworn to unclean work, attracted by the impermanent.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
They believe that to gratify the senses is the prime necessity of human civilization. Thus until the end of life their anxiety is immeasurable. Bound by a network of hundreds of thousands of desires and absorbed in lust and anger, they secure money by illegal means for sense gratification.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
The demoniac person thinks: "So much wealth do I have today, and I will gain more according to my schemes. So much is mine now, and it will increase in the future, more and more. He is my enemy, and I have killed him, and my other enemies will also be killed. I am the lord of everything. I am the enjoyer. I am perfect, powerful and happy. I am the richest man, surrounded by aristocratic relatives. There is none so powerful and happy as I am. I shall perform sacrifices, I shall give some charity, and thus I shall rejoice." In this way, such persons are deluded by ignorance.
Thus perplexed by various anxieties and bound by a network of illusions, they become too strongly attached to sense enjoyment and fall down into hell.
Self-complacent and always impudent, deluded by wealth and false prestige, they sometimes proudly perform sacrifices in name only, without following any rules or regulations.
Bewildered by false ego, strength, pride, lust and anger, the demons become envious of the Supreme Personality of Godhead, who is situated in their own bodies and in the bodies of others, and blaspheme against the real religion.
Those who are envious and mischievous, who are the lowest among men, I perpetually cast into the ocean of material existence, into various demoniac species of life.
Attaining repeated birth amongst the species of demoniac life, O son of Kuntī, such persons can never approach Me. Gradually they sink down to the most abominable type of existence.
There are three gates leading to this hell — lust, anger and greed. Every sane man should give these up, for they lead to the degradation of the soul.
The man who has escaped these three gates of hell, O son of Kuntī, performs acts conducive to self-realization and thus gradually attains the supreme destination.
He who discards scriptural injunctions and acts according to his own whims attains neither perfection, nor happiness, nor the supreme destination.
One should therefore understand what is duty and what is not duty by the regulations of the scriptures. Knowing such rules and regulations, one should act so that he may gradually be elevated.

Arjuna inquired: O Kṛṣṇa, what is the situation of those who do not follow the principles of scripture but worship according to their own imagination? Are they in goodness, in passion or in ignorance?
The Supreme Personality of Godhead said: According to the modes of nature acquired by the embodied soul, one's faith can be of three kinds — in goodness, in passion or in ignorance. Now hear about this.
O son of Bharata, according to one's existence under the various modes of nature, one evolves a particular kind of faith. The living being is said to be of a particular faith according to the modes he has acquired.
Men in the mode of goodness worship the demigods; those in the mode of passion worship the demons; and those in the mode of ignorance worship ghosts and spirits.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Those who undergo severe austerities and penances not recommended in the scriptures, performing them out of pride and egoism, who are impelled by lust and attachment, who are foolish and who torture the material elements of the body as well as the Supersoul dwelling within, are to be known as demons.
Even the food each person prefers is of three kinds, according to the three modes of material nature. The same is true of sacrifices, austerities and charity. Now hear of the distinctions between them.
Foods dear to those in the mode of goodness increase the duration of life, purify one's existence and give strength, health, happiness and satisfaction. Such foods are juicy, fatty, wholesome, and pleasing to the heart.
Foods that are too bitter, too sour, salty, hot, pungent, dry and burning are dear to those in the mode of passion. Such foods cause distress, misery and disease.
Food prepared more than three hours before being eaten, food that is tasteless, decomposed and putrid, and food consisting of remnants and untouchable things is dear to those in the mode of darkness.
Of sacrifices, the sacrifice performed according to the directions of scripture, as a matter of duty, by those who desire no reward, is of the nature of goodness.
But the sacrifice performed for some material benefit, or for the sake of pride, O chief of the Bhāratas, you should know to be in the mode of passion.
Any sacrifice performed without regard for the directions of scripture, without distribution of prasādam [spiritual food], without chanting of Vedic hymns and remunerations to the priests, and without faith is considered to be in the mode of ignorance.
Austerity of the body consists in worship of the Supreme Lord, the brāhmaṇas, the spiritual master, and superiors like the father and mother, and in cleanliness, simplicity, celibacy and nonviolence.
Austerity of speech consists in speaking words that are truthful, pleasing, beneficial, and not agitating to others, and also in regularly reciting Vedic literature.
And satisfaction, simplicity, gravity, self-control and purification of one's existence are the austerities of the mind.
This threefold austerity, performed with transcendental faith by men not expecting material benefits but engaged only for the sake of the Supreme, is called austerity in goodness.
Penance performed out of pride and for the sake of gaining respect, honor and worship is said to be in the mode of passion. It is neither stable nor permanent.
Penance performed out of foolishness, with self-torture or to destroy or injure others, is said to be in the mode of ignorance.
Charity given out of duty, without expectation of return, at the proper time and place, and to a worthy person is considered to be in the mode of goodness.
But charity performed with the expectation of some return, or with a desire for fruitive results, or in a grudging mood, is said to be charity in the mode of passion.
And charity performed at an impure place, at an improper time, to unworthy persons, or without proper attention and respect is said to be in the mode of ignorance.
From the beginning of creation, the three words oḿ tat sat were used to indicate the Supreme Absolute Truth. These three symbolic representations were used by brāhmaṇas while chanting the hymns of the Vedas and during sacrifices for the satisfaction of the Supreme.
Therefore, transcendentalists undertaking performances of sacrifice, charity and penance in accordance with scriptural regulations begin always with oḿ, to attain the Supreme.
Without desiring fruitive results, one should perform various kinds of sacrifice, penance and charity with the word tat. The purpose of such transcendental activities is to get free from material entanglement.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
The Absolute Truth is the objective of devotional sacrifice, and it is indicated by the word sat. The performer of such sacrifice is also called sat, as are all works of sacrifice, penance and charity which, true to the absolute nature, are performed to please the Supreme Person, O son of Pṛthā.
Anything done as sacrifice, charity or penance without faith in the Supreme, O son of Pṛthā, is impermanent. It is called asat and is useless both in this life and the next.

Arjuna said: O mighty-armed one, I wish to understand the purpose of renunciation [tyāga] and of the renounced order of life [sannyāsa], O killer of the Keśī demon, master of the senses.
The Supreme Personality of Godhead said: The giving up of activities that are based on material desire is what great learned men call the renounced order of life [sannyāsa]. And giving up the results of all activities is what the wise call renunciation [tyāga].
Some learned men declare that all kinds of fruitive activities should be given up as faulty, yet other sages maintain that acts of sacrifice, charity and penance should never be abandoned.
O best of the Bhāratas, now hear My judgment about renunciation. O tiger among men, renunciation is declared in the scriptures to be of three kinds.
Acts of sacrifice, charity and penance are not to be given up; they must be performed. Indeed, sacrifice, charity and penance purify even the great souls.
All these activities should be performed without attachment or any expectation of result. They should be performed as a matter of duty, O son of Pṛthā. That is My final opinion.
Prescribed duties should never be renounced. If one gives up his prescribed duties because of illusion, such renunciation is said to be in the mode of ignorance.
Anyone who gives up prescribed duties as troublesome or out of fear of bodily discomfort is said to have renounced in the mode of passion. Such action never leads to the elevation of renunciation.
O Arjuna, when one performs his prescribed duty only because it ought to be done, and renounces all material association and all attachment to the fruit, his renunciation is said to be in the mode of goodness.
The intelligent renouncer situated in the mode of goodness, neither hateful of inauspicious work nor attached to auspicious work, has no doubts about work.
It is indeed impossible for an embodied being to give up all activities. But he who renounces the fruits of action is called one who has truly renounced.
For one who is not renounced, the threefold fruits of action — desirable, undesirable and mixed — accrue after death. But those who are in the renounced order of life have no such result to suffer or enjoy.
O mighty-armed Arjuna, according to the Vedānta there are five causes for the accomplishment of all action. Now learn of these from Me.
The place of action [the body], the performer, the various senses, the many different kinds of endeavor, and ultimately the Supersoul — these are the five factors of action.
Whatever right or wrong action a man performs by body, mind or speech is caused by these five factors.
Therefore one who thinks himself the only doer, not considering the five factors, is certainly not very intelligent and cannot see things as they are.
One who is not motivated by false ego, whose intelligence is not entangled, though he kills men in this world, does not kill. Nor is he bound by his actions.
Knowledge, the object of knowledge, and the knower are the three factors that motivate action; the senses, the work and the doer are the three constituents of action.
According to the three different modes of material nature, there are three kinds of knowledge, action and performer of action. Now hear of them from Me.
That knowledge by which one undivided spiritual nature is seen in all living entities, though they are divided into innumerable forms, you should understand to be in the mode of goodness.
That knowledge by which one sees that in every different body there is a different type of living entity you should understand to be in the mode of passion.
And that knowledge by which one is attached to one kind of work as the all in all, without knowledge of the truth, and which is very meager, is said to be in the mode of darkness.
That action which is regulated and which is performed without attachment, without love or hatred, and without desire for fruitive results is said to be in the mode of goodness.
But action performed with great effort by one seeking to gratify his desires, and enacted from a sense of false ego, is called action in the mode of passion.
That action performed in illusion, in disregard of scriptural injunctions, and without concern for future bondage or for violence or distress caused to others is said to be in the mode of ignorance.
One who performs his duty without association with the modes of material nature, without false ego, with great determination and enthusiasm, and without wavering in success or failure is said to be a worker in the mode of goodness.
The worker who is attached to work and the fruits of work, desiring to enjoy those fruits, and who is greedy, always envious, impure, and moved by joy and sorrow, is said to be in the mode of passion.
The worker who is always engaged in work against the injunctions of the scripture, who is materialistic, obstinate, cheating and expert in insulting others, and who is lazy, always morose and procrastinating is said to be a worker in the mode of ignorance.
O winner of wealth, now please listen as I tell you in detail of the different kinds of understanding and determination, according to the three modes of material nature.
O son of Pṛthā, that understanding by which one knows what ought to be done and what ought not to be done, what is to be feared and what is not to be feared, what is binding and what is liberating, is in the mode of goodness.
O son of Pṛthā, that understanding which cannot distinguish between religion and irreligion, between action that should be done and action that should not be done, is in the mode of passion.
That understanding which considers irreligion to be religion and religion to be irreligion, under the spell of illusion and darkness, and strives always in the wrong direction, O Pārtha, is in the mode of ignorance.
O son of Pṛthā, that determination which is unbreakable, which is sustained with steadfastness by yoga practice, and which thus controls the activities of the mind, life and senses is determination in the mode of goodness.
But that determination by which one holds fast to fruitive results in religion, economic development and sense gratification is of the nature of passion, O Arjuna.
And that determination which cannot go beyond dreaming, fearfulness, lamentation, moroseness and illusion — such unintelligent determination, O son of Pṛthā, is in the mode of darkness.
O best of the Bhāratas, now please hear from Me about the three kinds of happiness by which the conditioned soul enjoys, and by which he sometimes comes to the end of all distress.
That which in the beginning may be just like poison but at the end is just like nectar and which awakens one to self-realization is said to be happiness in the mode of goodness.
That happiness which is derived from contact of the senses with their objects and which appears like nectar at first but poison at the end is said to be of the nature of passion.
And that happiness which is blind to self-realization, which is delusion from beginning to end and which arises from sleep, laziness and illusion is said to be of the nature of ignorance.
There is no being existing, either here or among the demigods in the higher planetary systems, which is freed from these three modes born of material nature.
Brāhmaṇas, kṣatriyas, vaiśyas and śūdras are distinguished by the qualities born of their own natures in accordance with the material modes, O chastiser of the enemy.
Peacefulness, self-control, austerity, purity, tolerance, honesty, knowledge, wisdom and religiousness — these are the natural qualities by which the brāhmaṇas work.
Heroism, power, determination, resourcefulness, courage in battle, generosity and leadership are the natural qualities of work for the kṣatriyas.
Farming, cow protection and business are the natural work for the vaiśyas, and for the śūdras there is labor and service to others.
By following his qualities of work, every man can become perfect. Now please hear from Me how this can be done.
By worship of the Lord, who is the source of all beings and who is all-pervading, a man can attain perfection through performing his own work.
It is better to engage in one's own occupation, even though one may perform it imperfectly, than to accept another's occupation and perform it perfectly. Duties prescribed according to one's nature are never affected by sinful reactions.
Every endeavor is covered by some fault, just as fire is covered by smoke. Therefore one should not give up the work born of his nature, O son of Kuntī, even if such work is full of fault.
One who is self-controlled and unattached and who disregards all material enjoyments can obtain, by practice of renunciation, the highest perfect stage of freedom from reaction.
O son of Kuntī, learn from Me how one who has achieved this perfection can attain to the supreme perfectional stage, Brahman, the stage of highest knowledge, by acting in the way I shall now summarize.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
Being purified by his intelligence and controlling the mind with determination, giving up the objects of sense gratification, being freed from attachment and hatred, one who lives in a secluded place, who eats little, who controls his body, mind and power of speech, who is always in trance and who is detached, free from false ego, false strength, false pride, lust, anger, and acceptance of material things, free from false proprietorship, and peaceful — such a person is certainly elevated to the position of self-realization.
One who is thus transcendentally situated at once realizes the Supreme Brahman and becomes fully joyful. He never laments or desires to have anything. He is equally disposed toward every living entity. In that state he attains pure devotional service unto Me.
One can understand Me as I am, as the Supreme Personality of Godhead, only by devotional service. And when one is in full consciousness of Me by such devotion, he can enter into the kingdom of God.
Though engaged in all kinds of activities, My pure devotee, under My protection, reaches the eternal and imperishable abode by My grace.
In all activities just depend upon Me and work always under My protection. In such devotional service, be fully conscious of Me.
If you become conscious of Me, you will pass over all the obstacles of conditioned life by My grace. If, however, you do not work in such consciousness but act through false ego, not hearing Me, you will be lost.
If you do not act according to My direction and do not fight, then you will be falsely directed. By your nature, you will have to be engaged in warfare.
Under illusion you are now declining to act according to My direction. But, compelled by the work born of your own nature, you will act all the same, O son of Kuntī.
The Supreme Lord is situated in everyone's heart, O Arjuna, and is directing the wanderings of all living entities, who are seated as on a machine, made of the material energy.
O scion of Bharata, surrender unto Him utterly. By His grace you will attain transcendental peace and the supreme and eternal abode.
Thus I have explained to you knowledge still more confidential. Deliberate on this fully, and then do what you wish to do.
Because you are My very dear friend, I am speaking to you My supreme instruction, the most confidential knowledge of all. Hear this from Me, for it is for your benefit.
Always think of Me, become My devotee, worship Me and offer your homage unto Me. Thus you will come to Me without fail. I promise you this because you are My very dear friend.
Abandon all varieties of religion and just surrender unto Me. I shall deliver you from all sinful reactions. Do not fear.
This confidential knowledge may never be explained to those who are not austere, or devoted, or engaged in devotional service, nor to one who is envious of Me.
For one who explains this supreme secret to the devotees, pure devotional service is guaranteed, and at the end he will come back to Me.
There is no servant in this world more dear to Me than he, nor will there ever be one more dear.
And I declare that he who studies this sacred conversation of ours worships Me by his intelligence.
And one who listens with faith and without envy becomes free from sinful reactions and attains to the auspicious planets where the pious dwell.
O son of Pṛthā, O conqueror of wealth, have you heard this with an attentive mind? And are your ignorance and illusions now dispelled?
Arjuna said: My dear Kṛṣṇa, O infallible one, my illusion is now gone. I have regained my memory by Your mercy. I am now firm and free from doubt and am prepared to act according to Your instructions.
Sañjaya said: Thus have I heard the conversation of two great souls, Kṛṣṇa and Arjuna. And so wonderful is that message that my hair is standing on end.
By the mercy of Vyāsa, I have heard these most confidential talks directly from the master of all mysticism, Kṛṣṇa, who was speaking personally to Arjuna.
O King, as I repeatedly recall this wondrous and holy dialogue between Kṛṣṇa and Arjuna, I take pleasure, being thrilled at every moment.
O King, as I remember the wonderful form of Lord Kṛṣṇa, I am struck with wonder more and more, and I rejoice again and again.
Wherever there is Kṛṣṇa, the master of all mystics, and wherever there is Arjuna, the supreme archer, there will also certainly be opulence, victory, extraordinary power, and morality. That is my opinion/;

#solving issue with the last variable in the array
$data[699]=~s/Dhṛtarāṣṭra said: O Sañjaya, after my sons and the sons of Pāṇḍu assembled in the place of pilgrimage at Kurukṣetra, desiring to fight, what did they do\?//;
}

#GLOSSARY
sub glossary{
@ok=split / *\n */,
         qq/Abhimanyu : the son of Arjuna  whose name means 'imperishable'
Achyuta : immortal
Adharma : unrighteousness
Adhibhuta : physical region
Adhyatma : Individual Self - the soul
Adityas : Demi gods meaning 'sons of the light'
Agni : Demi god Lord of Fire
Ahankara : False ego
Akasa : sky or ether
Akshara : imperishable
Arjuna : one of the Pandavas,  mighty archer and one of the two main characters (the other is Krishna) in the Bhagavad Gita. The  name means 'clarity of pure devotion'
Asita : Ancient sage
Asvattha : a sacred Banyan tree
Asvatthaman : one fighting on the Kauravas side whose name means 'who has the obstinacy of a horse'
Asvins : Twin demi-gods meaning 'lords of pure desire'
Atma : soul
Aushadha : plants in general, including rice and barley, eaten by all living beings or it can also mean medicine
Bharata : refers to the dynasty that ruled ancient India for many generations. The name means 'descendant of the light of wisdom' Sometimes, it refers to Arjuna or to the first ruler in the dynasty, Bharata or to Dhritarashtra. Another name of India 'Bharat' has originated from this term.
Bhima : one of the 5 Pandavas,with a huge physique and an appetite. The name means 'who knows no fear'
Bhishma : The grandfather of the Pandavas and the Kauravas fighting on the Kauravas side.the name means 'who rules fear'
Bhrigu : ancient sage
Brahma : The God of creation belonging to the trinity (3 Gods) of creation, preservation and destruction in Hinduism
Brihaspati : chief of priests
Brihat-Saman : a hymn
Buddhi : mind, intellect or reason
Buddhi yoga : Yoga of intelligence
Chekitana : a king allied with the Pandavas
Chitraratha : King of the Gandharvas in Hindu mythology along with Tumburu and Visvavasu. Gandharvas are Centaur-like creatures with the upper-half of a human and the lower-half of a horse. They are in charge of the celestial soma of the gods. Chitra-Ratha was a magician and musician at the banquets of gods.
Devala : Sage
Dhananjaya : Arjuna meaning'conqueror of wealth'
Dharma : righteousness, one's correct duty
Dhrishtadyumna : a king allied to the Pandavas whose name means 'who attacks impurity'
Dhristaketu : a king allied with the Pandavas whose name means 'continuity of light'
Dhritarashtra : father of the Kauravas whose name means 'blind ambition'
Dhrti : constancy
Draupadi : the common wife of the Pandavas whose name means 'enemy of offenders'
Drona or Dronacharya : the teacher of warfare to the Pandavas and the Kauravas. His name means 'who injures his foes with weapons'
Drupada : a king allied with the Pandavas whose name means 'he who stands like a wooden pillar'
Duryodhana : the eldest of the Kauravas and the chief enemy of the Pandavas. His name means 'defender of evil'
Dvandva : a word
Ekitana : one tone of chanting
Gandharvas : celestial singers
Anantavijaya : the name of Yudhisthira's conch meaning 'endless victory'
Asuras : Demons
Daityas : are a clan or race or Asura as are the Danavas. Daityas were the children of Diti and the sage Kashyapa.
Devadhatta : the name of Arjuna's conch meaning 'ambassador of the Gods'
Devatas or Devas : Demi gods
Brahman, Brahmana : God in general or a or Brahmin i.e God realised soul or the specific caste (sub-division) in Hindu society whose duty is to learn, teach sacred texts and look after the temples.
Gandiva : the bow of Arjuna meaning 'whose song causes terror'
Ganges : a very special holy river
Garuda : celestial bird
Govinda : Sri Krsna meaning 'who is one-pointed light'
Gudakesa : another name of Arjuna meaning 'who as conquered sleep'
Guna : Modes of Material Nature
Hari : name of Lord Krishna meaning 'remover of duality'
Himalaya : a mountain range in India
Hrishikesa : Sri Krsna meaning 'ruler of the senses' 'beholding witness' Son of the Sungod
Indra : The King of Heaven
Isvara : God, supreme ruler
Janaka : the Janakas were a race of kings who ruled Videha Kingdom from their capital Mithila. The father of Sita (the wife of Rama) was named Seeradwaja Janaka. 
Janardana : Sri Krsna meaning 'who is worshipped by the people'
Jayadratha : a king allied to the Kauravas
Japa : silent repetition of the maha mantra
Jivatma : soul
Kalpa : period of time
Kamadhenu or Kamadhuk : The cow who ever produces milk
Kapila : Incarnation of God
Karma : work that produces reaction
Karna : the close friend of Duryodhana, the archer competing in skill with Arjuna and the brother of the Pandavas born to Kunti through Sun God. His name means 'who thinks himself the doer'
Kasi : place, it is were Bhishma wins three maidens, daughters of king of Kasi for Vichithraveerya. 
Kasiraja : King of Kasi. It also means 'king of manifested light'
Kauravas : the 100 brothers and sons of Dhritarashtra
Kesava : Sri Krsna meaning 'embodiment of the functions of creation, preservation and transformation'
Keshi : a horse demon
Kirti : fame
Kratu : a class or type of Vedic sacrifices
Kripa or Kripacharya or Krpa : the teacher of spirituality to the Pandavas and the Kauravas and fighting on the Kauravas side. His name means 'who  does and gets'
Krishna or Krsna or Sri Krsna : God as a friend and war advisor to the Pandavas, a cousin of the Pandavas and the Kauravas, peace maker, charioteer to Arjuna and is the one of the two main characters (the other is Arjuna) in the Bhagavad Gita. The name means 'doer of all'
Ksama : forgiveness
Kshetra : field or body
Kshetrajna : Soul
Kunti : the mother of the  Pandavas whose name means 'who removes the  deficiency of others'
Kuntibhoja : a king allied with the Pandavas. His name means 'who enjoys removing the deficiency of others'
Kurunandhana : Arjuna meaning 'delight of action'
Kurus : the dynasty of the Bharatha
Kurukshetra : the name of the Battle-field
Kusa : a type of grass
Kusumakara : a season
Kutastha : the indivisible
Madhava : Sri Krsna meaning 'whose sweetness is intoxicating'
Madhu : A demon
Madhusudhana : Sri Krsna meaning 'slayer of too much' pr Madhusahana
Maharishis : Great sages
Maheshvara : God
Makara : shark
Manas : mind, thought or heart depending on the context
Manipushpaka : the name of Sahadeva's conch meaning 'ornament of jewels'
Mantra : chant
Manu : ancient man who had written a treatise on righteousness. His name means 'protector of mind'
Margasirsha : a month roughly corresponding to November
Mariciaruts : a kind of Devatas meaning 'those who purify'
Maya : illusion
Medha : loving intellect
Moksha : enlightenment,liberation, nirvana, temporary release from suffering
Maharatha : A maha-ratha is a warrior so perfected in the science of weaponry that he can fight alone against 11,000 bowmen all at the same time and not be defeated.
Muni : A sage
Nakula : of the Pandavas. His name means 'who is free from pain
Narada Muni : Celestial sage who wanders throughout the Universes
Narayana : Lord of Vaikuntha and one of the three chief Gods
Nirvana : enlightenment liberation, moksha, release from suffering and attainment of some sort of happiness
Om : sacred hymn or syllable
Panchajanya : the name of Krishna's conch meaning 'of the five elements'
Pandavas : the 5 brothers and sons of Pandu
Pandu : the father of the Pandavas. The name means 'he who is without prejudice'
Parabrahman : God
Paramatma : God as the indwelling advisor
Partha : Arjuna meaning 'son of she who excels'
Paundra : the name of Bhima's conch
Pitris : ancestors
Prahlada : great devotee
Prajapati : Prajapati refers to Brahma, a duly authorised Guna avatar of the Supreme Lord who while reflecting on them out of His infinite mercy and for the sake of their ultimate redemption, inspired Brahma to project them into the material manifestation.
Prakriti : material nature
Pritha : Another name for  Queen Kunti, mother of Arjuna
Punya : pious deeds or merit
Purujit : a king allied with the Pandavas. His name means 'who has complete victory'
Purushottama : The Supreme Personality of Godhead
Rajarshis : Great sages
Rakshasas : demons
Rama : another incarnation of Sri Krsna, the chief character in the epic,Ramayana
Rig veda : one of the 4 Vedas
Rishis : sages
Rudra : refers to Shiva, the demi god who is the destroyer. The name means 'reliever of suffering'
Sahadeva : one of the Pandavas. His name means 'equal to the Gods'
Saibya : a king allied with the Pandavas. His name means 'son of unselfishness'
Sama veda : one of the four Vedas
Samsara : material world
Sanjaya or Samnjaya : the person narrating the Bhagavad Gita with the help of divine insight given to him by the mercy of his spiritual master. His name means 'he who is victorious over all'
Sankara : Shiva, the God of destruction
Sankhya : the spiritual route through knowledge
Sannyasa : the renunciation of materialistic life
Sattva or Sattvika : Mode of Goodness one of the 3 modes of material nature discussed in chapter 17
Rajas or Rajasika : Mode of Passion. one of the 3 modes of material nature discussed in chapter 17.
Satyaki : a king allied to the Pandavas. His name means 'whose nature is truth'
Savyasachin : ambidextrous - Arjuna meaning 'he who can use both of his hands skillfully'
Sikhandi : a king allied to the Pandavas. His name means 'who dwells at the summit'
Smrti : recollection
Somadatta : His name means 'ambassodor of the nectar of devotion'
Subhadra : seperate wife of Arjuna. Her name means 'excellent of excellence'
Sudras : those whose duty is to do labour
Sughosa : the name of Nakula's conch meaning 'excellent battle-cry'
Svarga : heaven
Tamas or Tamasika : Mode of Ignorance. one of the 3 modes of material nature discussed in chapter 17
Uchchaisaravas : kingly horse born in the ocean when it was churned for nectar
Vaisyas : duty is to do business
Varuna : Demi god of water
Vayu : Demi god of wind
Vedanta : Conclusion of the Vedas
Vedas : the ancient holy texts
Vasuki : Demi god of serpents
Vikarna : a king allied to the Kauravas. His name means 'who is deaf to evil'
Virata : a king allied with the Pandavas. His name means 'brilliantly shining'
Vrkodara : refers to Bhima meaning 'who has a voracious appetite'
Vyasa : sage and author of Mahabharatha (and hence Bhagavad Gita) and other major religious works like Brahma sutras
Yajur veda : one of the 4 Vedas
Yama or Yamarahaja : the demi god of death
Yudhamanyu : a king allied with the Pandavas. His name means 'who conquers the mind'
Yudhisthira : the eldest of the Pandavas known for his truthfulness. His name means 'who remains committed to the ideal'
Yuyudhana : a king allied with the Pandavas. His name means 'defender of wealth'
Yuga : a measurement of time
Preceptor : A teacher; an instructor. An expert or specialist. Refers to Drona, the teacher of the Pandavas and the Kauravas
Bhutas : spirits, ghosts o demons
Nagas : celestial serpents
Ksatriya : duty is to fight
Mahatma : high souled
Adhiyajna : the aspect of the Supreme Personality of Godhead concerned with Sacrifice
Brahmachari : person practising celebacy
Gayatri : a sacred hymn sung three times a day by brahmins
Jivas : living beings
Bhagavan : The Supreme Personality of Godhead containing the other two aspects Parabrahman and Paramatma
Tapasya : austerities performed as a sacrifice/;
}

1;
__END__

=head1 NAME

Bhagavatgita - display/obtain Gita verses.

=head1 SYNOPSIS

  #for displaying random Bhagavatgita verse in terminal
  gita

  use Bhagavatgita;
  @verse=Bhagavatgita->gita(-first='20');
  print "@verse"; #prints verse 20

  @verse=Bhagavatgita->gita(-first='20',-last='100');
  print "@verse"; #prints verses from 20 to 100

  note: maximum value of -last is 700

  @verse=Bhagavatgita->gita(-first='20',-last='last');
  print "@verse"; #prints verse 20 to last verse of Bhagavatgita

  @chapter=gita_chapter(10);
  print "@chapter"; #prints entire Chapter 10 with title

  note:maximum number of chapter is 18

  @random=gita_random(15);
  print "@random"; #prints random 15 consecutive verses

  @glossary=gita_glossary();
  print "@glossary";

=head1 DESCRIPTION

Module for accessing contents of Bhagavatgita.
Bhagavatgita meaning The Song of the Bhagavan(God), also called Gita, is a 700-verse scripture that is part of the Hindu epic Mahabharata. This scripture contains a conversation between Pandava prince Arjuna and his guide Lord Krishna on a variety of theological and philosophical issues.The material used is a transulation by A.C. Bhaktivedanta Swami Prabhupada

Please note that certain verses has been transulated into a single combined english verse e.g verses 16,17 and 18 are transulated into a single english verse.Check this site to make clarity on that, "http://vedabase.net/bg/1/en". Hence displaying verses 1-16 is same as displaying verses 1-17 or 1-18.

Glossary is obtained from "https://sites.google.com/site/iskconcapechat/home/books-group/lexicon-dictionary-concordance/glossary-of-bhagavad-gita"

=head2 EXPORT

=over

=item gita
=item gita_chapter
=item gita_random
=item gita_glossary

=back

=head1 AUTHOR

Dileep Mani <dileepmani@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Dileep Mani

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.
