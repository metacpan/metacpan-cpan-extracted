use Test::More;

use Data::Classifier::NaiveBayes;

my $classifier = Data::Classifier::NaiveBayes->new;

isa_ok $classifier->tokenizer, 'Data::Classifier::NaiveBayes::Tokenizer';

$classifier->train('dog', "Dogs are awesome, cats too. I love my dog");
$classifier->train('cat', "Cats are more preferred by software developers. I never could stand cats. I have a dog");    
$classifier->train('dog', "My dog's name is Willy. He likes to play with my wife's cat all day long. I love dogs");
$classifier->train('cat', "Cats are difficult animals, unlike dogs, really annoying, I hate them all");
$classifier->train('dog', "So which one should you choose? A dog, definitely.");
$classifier->train('cat', "The favorite food for cats is bird meat, although mice are good, but birds are a delicacy");
$classifier->train('dog', "A dog will eat anything, including birds or whatever meat");
$classifier->train('cat', "My cat's favorite place to purr is on my keyboard");
$classifier->train('dog', "My dog's favorite place to take a leak is the tree in front of our house");

is $classifier->classify("This test is about cats."), 'cat';
is $classifier->classify("I hate ..."), 'cat';
is $classifier->classify("The most annoying animal on earth."), 'cat';
is $classifier->classify("The preferred company of software developers."), 'cat';
is $classifier->classify("My precious, my favorite!"), 'cat';
is $classifier->classify("Kill that bird!"), 'cat';

is $classifier->classify("This test is about dogs."), 'dog';
#is $classifier->classify("Cats or Dogs?"), 'dog'; 
is $classifier->classify("What pet will I love more?"), 'dog';    
is $classifier->classify("Willy, where the heck are you?"), 'dog';
is $classifier->classify("I like big buts and I cannot lie."), 'dog';
is $classifier->classify("Why is the front door of our house open?"), 'dog';
is $classifier->classify("Who ate my meat?"), 'dog';

done_testing;
