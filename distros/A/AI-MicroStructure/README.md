AI-MicroStructure
=================

A concept is a mental representation for a word or any form of inputs!

Concepts allows us to draw appropriate inferences about the type of entities we encounter in our everyday lives!

The use of concepts is necessary to cognitive processes such as categorization, memory, decision making, learning and inference.

AI-MicroStructure is a package to build concepts for words.

Anybody whisching to do categorization, memory, decision making, learning and inference.

requires as much concepts for a specific (word,idea,sensor input) as possible to base any further knowledge or decission on

to be able to fly you require only to types

```
micro new extraterrestrial_life


               .--'"""""--.>_
            .-'  o\\b.\o._o.`-.
         .-'.- )  \d888888888888b.
        /.'   b  Y8888888888888888b.
      .-'. 8888888888888888888888888b
     / o888 Y Y8888888888888888888888b
     / d888P/ /| Y"Y8888888888888888888b
   J d8888/| Y .o._. "Y8888888888888Y" \
   |d Y888b|obd88888bo. """Y88888Y' .od8
   Fdd 8888888888888888888bo._'|| d88888|
   Fd d 88\ Y8888Y "Y888888888b, d888888P
   d-b 8888b Y88P'     """""Y888b8888P"|
  J  8\88888888P    `m.        """""   |
  || `8888888P'       "Ymm._          _J
  |\\  Y8888P  '     .mmm.YM)     .mMF"'
  | \\  Y888J     ' < (@)>.- `   /MFm. |
  J   \  `YY           ""'   ::  MM @)>F
   L  /)  88                  :  |  ""\|
   | ( (   Yb .            '  .  |     L
   \   bo  8b    .            .  J     |        The word extraterrestrial
    \      "' .      .    .    .  L   F         has 1 concept's
     o._.:.    .        .  \mm,__J/  /          we need to find out the which one
     Y8::'|.            /     `Y8P  J           to use for our new,
     `|'  J:   . .     '   .  .   | F           micro-structure,
      |    L          ' .    _:    |            
      |    `:        . .:oood8bdb. |            (1): a form of life assumed to exist outside the earth or its atmosphere extraterrestrial
      F     `:.          "-._   `" F            
     /       `::.           """'  /             
    /         `::.          ""   /              
_.-d(          `:::.            F               
-888b.          `::::.     .  J                 
Y888888b.          `::::::::::'                 
Y88888888bo.        `::::::d                    
`"Y8888888888boo.._   `"dd88b.                  





"""""""""""""""""""""""""""""""""""""""""""""""


  Type: the number you choose 1..1
  1
extraterrestrialbeing
extraterrestrial
alien
hypothetical_creature
imaginary_being
imaginary_creature
imagination
imaginativeness
vision
creativity
creativeness
creative_thinking
ability
power
cognition
knowledge
noesis
psychological_feature
abstraction
abstract_entity
entity
extraterrestrialbeing
extraterrestrial
alien
hypothetical_creature

``` 




  ☞ [sample](http://quantup.com)

  ☞ [PDF info](https://github.com/santex/active-memory/raw/master/start-here.pdf)



#### Dependencies

* cpan
* couchdb
* wordnet
* tesseract
* xpdf-utils (poppler-utils)

#### Copyright

  Copyright (C) 2009-2012 Hagen "santex" Geissler


# Usage sample use 

```


#try something like this

  $ micro new ufo;      # creates a structure called ufo

  $ micro drop ufo;     # deletes the structure called ufo

  $ micro structures;   # shows all structure's you currently have

  #after creation of a structure you can access it in lots of ways



  $ micro;             # one word of a random structure

  $ micro ufo;         # one word of the ufo structure

  $ micro ufo all;     # all words of the ufo structure

  $ micro ufo 5;       # 5 random words of the ufo structure

  $ micro any 10;      # 10 random words of any structure you have created


  $ micro --init        # initializes active memory

  $ micro --export      # export relations from couchdb into git repo and tag data


  # oneliners i like to use

  $  for i in `micro structures`; do echo $i; done;       # echos all the structures

  $  for i in `micro ufo all`;   do echo $i; done;       # echos all words in ufo

  $  for i in `micro structures`; do micro all $i; done;  # echos all stuctures all words

  $  for i in `micro ufo all`;   do micro new $i; done;  # new structure for all words in ufo

  $  for i in `micro ufo all`;   do micro-wiki $i; done; # push all words against the wiki plugin dont forget setting user & password in /usr/local/bin/micro-wiki

  ###################################################################################
  # try to follow the logic combine
  # your-word=micro new ? ->concept->concepts->relations->node


  $ micro new biology
  $ micro new biological_process

  $ for i in `micro structures`; do
  $ for y in `micro all $i `; do
  $ echo "$i=$y";
  $ micro new $y;
  $ done
  $ done

  #!!!!!###Hard cpu to expect ### make sure couch is on   ######  or disable the store methode in micro-wiki and print $doc or consume otherweise
  # test as single before you loope 
  
  $ micro-wiki ufo
  
  # proceed

  $ for i in `micro structures`; do
  $ for y in `micro all $i `; do
  $ echo "$i=$y";
  $ micro-wiki $y;
  $ done
  $ done




```
# compounding knowledge


```
  
               .--'"""""--.>_
            .-'  o\\b.\o._o.`-.
         .-'.- )  \d888888888888b.
        /.'   b  Y8888888888888888b.
      .-'. 8888888888888888888888888b
     / o888 Y Y8888888888888888888888b
     / d888P/ /| Y"Y8888888888888888888b
   J d8888/| Y .o._. "Y8888888888888Y" \
   |d Y888b|obd88888bo. """Y88888Y' .od8
   Fdd 8888888888888888888bo._'|| d88888|
   Fd d 88\ Y8888Y "Y888888888b, d888888P
   d-b 8888b Y88P'     """""Y888b8888P"|
  J  8\88888888P    `m.        """""   |
  || `8888888P'       "Ymm._          _J
  |\\  Y8888P  '     .mmm.YM)     .mMF"'
  | \\  Y888J     ' < (@)>.- `   /MFm. |
  J   \  `YY           ""'   ::  MM @)>F
   L  /)  88                  :  |  ""\|
   | ( (   Yb .            '  .  |     L
   \   bo  8b    .            .  J     |        
    \      "' .      .    .    .  L   F         
     o._.:.    .        .  \mm,__J/  /          
     Y8::'|.            /     `Y8P  J           
     `|'  J:   . .     '   .  .   | F           
      |    L          ' .    _:    |            
      |    `:        . .:oood8bdb. |            
      F     `:.          "-._   `" F            
     /       `::.           """'  /             
    /         `::.          ""   /              
_.-d(          `:::.            F               
-888b.          `::::.     .  J                 
Y888888b.          `::::::::::'                 
Y88888888bo.        `::::::d                    
`"Y8888888888boo.._   `"dd88b.                  
```





one way more easy would be to steam a large amount knowledge over complete discipline structure and categorize it on the smallest node .
then we sort density and lower the scope to compute compounding
by the factor the density map is large.

as more detailed the steaming becomes minimum for compounding (math formulas , corresponding arithmetic)
the Categorizer has to adapt but we will have him well trained with the initial steam.
all left to compounding is the hypothesis and experiment compatible with harvested formulas and arithmetic
on a very small scope or adjustable by density.

:)

