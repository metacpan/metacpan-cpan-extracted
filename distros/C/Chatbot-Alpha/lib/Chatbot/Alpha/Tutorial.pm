package Chatbot::Alpha::Tutorial;

our $VERSION = '0.2';

1;

__END__;

=head1 NAME

Chatbot::Alpha::Tutorial - Beginners' guide to Chatbot::Alpha 2.x

=head1 RIVESCRIPT

B<This module is obsolete!> Alpha was superceded by a more powerful language, rewritten from scratch,
called L<RiveScript>. Chatbot::Alpha was allowed (and will be allowed) to remain here only because there are
a few incompatibilities in the reply files. If you haven't used Alpha yet, I urge you to use RiveScript instead.
If you've already invested time in writing reply files for Alpha, know that this module isn't going anywhere.
However, this module is no longer actively maintained (and hasn't been in a number of years).

See L<RiveScript>.

=head1 INTRODUCTION

=head2 What is Chatbot::Alpha?

L<Chatbot::Alpha> is a Perl module for reading and processing B<Alpha> code. Alpha code is
a command-driven response language, primarily used for chatterbots.

The language format is quite simple: it's a line-by-line language. The first character is
the B<command>, followed by the command's B<data>. The simplest of all Alpha replies is the
standard one-way question and answer:

  + hello bot
  - Hello human.

=head2 Alpha Commands Overview

Here are all the commands supported by Chatbot::Alpha:

B<+ (Plus)>

The + symbol is the basis of all your replies. It's the trigger--that is, what the user says
to activate that reply. In most cases this command comes first in a reply, followed by supporting
commands that tell the bot what to do next.

B<- (Minus)>

The - command has many purposes. In the example above, a single +TRIGGER and a single -REPLY will
give you a one-way question-answer case. If you use multiple -REPLY's under one +TRIGGER, then they
will become random responses. On *CONDITION'S, the -REPLY's will be called when no condition returns
true. On &HOLDERS, the -REPLY is the first thing the bot sends. And the list goes on... we'll get
into the many uses for -REPLY later.

B<% (Percent)>

The % command is for "that" emulation. If you've worked with AIML you'll know what that refers to.
It's there to help take the A.D.D. syndrome out of your bots. You can make specific replies based
on what the bot last said. Like if the bot asks "Do you have any pets?" and the user says "yes", the
bot can ask "What kind of pets?" instead of a generic reply to "yes". You'll learn all about this in
the tutorial later.

B<^ (Carat)>

The ^ command is to continue from your last -REPLY. For example, if your reply is very long and you
want to break it down a few lines in the reply file (as not to have a horizontal scrollbar and be
hard to read), this is the command to use. The ^CONTINUE command will adds its data to the last
-REPLY you used under the +TRIGGER.

B<@ (At)>

The @ command is for a redirection. Alpha triggers are "dead-on", meaning "hello|hey" is literally
"hello|hey", not "hello OR hey". So when you want one to point to the other, use the @REDIRECT command.

B<* (Star)>

The * is for conditionals. You'll learn about these later as well.

B<& (Amperstand)>

This is for simple conversation holders. Emphasis is on the word "simple." They don't always work,
so you'd use %THAT if it was really important. The &HOLDER command is slowly becoming deprecated.

B<# (Pound)>

The # command is for executing Perl codes within your reply set. Sometimes Alpha just can't handle
the complex tasks you have in mind, and this can fill in all the blanks (assuming you're fluent with
Perl anyway).

B</ (Slash)>

This is comment data, not processed within Chatbot::Alpha.

B<LessThan and GreaterThan>

The > and < are labels. Right now they're used only for topics.

=head1 SIMPLE REPLIES

=head2 One-Way Question/Answers

As shown in the first example code, a single +TRIGGER with a single -REPLY will get a one-way question/
answer. Here are some examples:

  + hello bot
  - Hello human.

  + are you a bot
  - How did you know I am a machine?

  + what is your favorite color
  - Blue.

=head2 Random Responses

If you use two or more -REPLY commands with one +TRIGGER, you can set up multiple responses. Examples:

  + hello
  - Hello there.
  - Hey.
  - Hi.
  - Hello! How are you?

  + name a band for me
  - Relient K.
  - Linkin Park.
  - Newsboys.
  - Green Day.
  - Evanescence.

=head2 Wildcards

Sometimes it's important to have some open-ended triggers. This can be done with wildcards. You can have any
number of wildcards in a trigger, but only the first nine (9) can be repeated in the reply.

Examples of in-general open-ended replies:

  + are you *
  - Yes.
  - No.
  - Do you want me to be?

  + * told me to *
  - Do you always do as you're told?

You can capture what's in the wildcards using <star1> through <star9>.

  + my name is *
  - I've talked to a <star1> before.

  + * told me to *
  - Why would <star1> tell you to do that?

  + my * is * years old
  - Your <star1> is <star2> years old?

=head2 Redirections

You'd find it quite tiresome if you had to copy/paste that "hello" trigger for all the possible forms of
"hello", wouldn't you? Luckily there's an @ command for redirections. Here's the example I just mentioned:

  + hello
  - Hello there.
  - Hey.
  - How are you?

  + hi
  @ hello

  + hey
  @ hello

  + hola
  @ hello

So if they say "hi", "hey", or "hola", Chatbot::Alpha pretends as if they said "hello" and redirects them
to the appropriate reply. Here's another example:

  + what is your favorite color
  - I'm quite fond of the color "blue".

  + do you have a favorite color
  @ what is your favorite color

  + what color do you like
  @ what is your favorite color

Redirections can also be used "mid-stream" in a reply using the {@} tag. Examples:

  + * or something
  - Or something. {@<star1>}

  + because *
  - Oh, good reason. {@<star1>}

  + people around here call me *
  - Where does "here" refer to? {@my name is <star1>}

=head1 ADVANCED REPLIES

With the basic replies out of the way, there are many more things that Chatbot::Alpha is capable of with its
other commands.

=head2 Really Long Replies

The carat command ^ can be used to continue replies for the really long ones. Examples:

  + tell me about turing
  - Alan Mathison Turing was born on 23 June 1912, the
  ^ second and last child (after his brother John) of
  ^ Julius Mathison and Ethel Sara Turning. The unusual
  ^ name of Turing placed him in a distinctive family tree
  ^ of English gentry, .....

  + tell me a poem
  - Little Miss Muffet\n
  ^ sat on her tuffet\n
  ^ in a nonchalant sort of way.\n
  ^ With her forcefield around her,\n
  ^ the spider, the bounder,\n
  ^ is not in the picture today.

=head2 Conditionals

Conditionals are useful for checking things about a user. You can compare variables to their values.

To modify variables, that's done in your Perl code. You make calls such as these to your Chatbot::Alpha object:

  # Set variables.
  $alpha->setVariable ("name", "Bob");
  $alpha->setVariable ("gender", "male");

  # Remove variables.
  $alpha->removeVariable ("gender");

  # Clear all variables.
  $alpha->clearVariables;

You can check variables' values in your replies with the *CONDITION command. Its basic format is:

  * VARIABLE=VALUE::Say This

Conditionals always need at least one -REPLY in the end to fall back on, in case none of the conditions
return true!

Examples:

  + am i a boy or a girl
  * gender=male::You're a boy.
  * gender=female::You're a girl.
  - I don't know what you are.

  + am i your master
  * master=1::Yes, you are my master.
  - No, you're not.

=head2 Simple Conversation Holders

These are relatively deprecated. They're for holding conversations quite simply. For example a "knock knock"
joke, or for the bot to go on rambling about stuff.

These aren't perfect, and sometimes you'll break out of the conversation by matching a better reply.

Examples:

  // Knock-Knock
  + knock knock
  - Who's there?
  & <msg> who?
  & Ha! <msg>! That's a good one!

  // Rambling
  + are you crazy
  - I was crazy once.
  & They locked me away...
  & In a room with padded walls...
  & There were rats there...
  & I don't like rats.
  & Rats make me crazy!
  & Did I mention I was crazy once?

=head2 "That's"

As I mentioned above, the &HOLDER command is buggy. You can use what we call "that", which is an emulation
of AIML's <that> functionality. It's to give your bot a cure of its A.D.D.

The %THAT command B<must> come directly after the +TRIGGER, before any other command. Here are some examples...

  + ask me a question
  - Do you have any pets?

  + yes
  % do you have any pets
  - What are their names?

  + *
  % what are their names
  - Those are cool names.

  ////////////////////////

  + i am *
  - Are you really?

  + yes
  % are you really
  - How long have you been?

The data of the %THAT command would be the bot's last response, lowercase and with no puncuation. This is a much
better method of holding onto conversations than the &HOLDER command is.

If their next message doesn't have a "that" attached to it (i.e. if the bot asks if they have any pets and they
don't say yes), it will get another reply as normal. However if they do say "yes", it will ask them what their names
are, rather than give a generic reply to "yes".

=head2 Topics

Sometimes, that's just don't do it for you. Topics are groups of replies. The default topic is "B<random>". When
in a topic, you can ONLY match triggers within that topic.

To open a topic, you use the <LABEL and >LABEL commands. To set the user's topic, you use the {topic} tag. See
the below example for how this is all formatted.

Set {topic=random} to return to the default topic.

A practical application for a topic is to force somebody to apologize for being mean.

  + i hate you
  - You're very mean! I'm not going to talk with you until you apologize.{topic=apology}

  > topic apology
    + *
    - Not until you apologize.
    - Say you're sorry.

    + sorry
    - See--that wasn't too bad. I'll forgive you.{topic=random}
  < topic

=head2 Perl Code Evaluator

B<DISCLAIMER>: Executing Perl codes in your replies is potentially dangerous. I'd recommend you do more than a simple
*CONDITION check to see if one can use any replies that execute Perl code. I cannot be held liable for any damages a
malicious hacker might perform as a result of using the #CODE command.

The # command can be used to execute Perl within your replies. Sometimes Chatbot::Alpha just isn't powerful enough
to do what you want, and this can fill in the gaps.

Below are some *safe* examples:

  + what is 2 plus 2
  - Internal Error (Perl evaluation failed).
  # $reply = "2 + 2 = 4";

  + How long have you been running
  - Internal Error...
  # $reply = "I've been running for ", (time() - $^T), " seconds.";

=head1 END OF TUTORIAL

This tutorial has gone over all of Alpha's functions and how to properly use them. You can combine these functions
to make more complex replies than the ones shown here. Be creative!

=head1 AUTHOR

Casey Kirsle, http://www.cuvou.com/

=cut
