#! /usr/bin/env perl

use 5.022;
use warnings;
use experimental 'signatures';

use DWIM::Block;

sub character_intro (%arg) {
    DWIM {
        Imagine you are a famous writer of novels in the following genre:

            $arg{genre}

        Make up a suitable name, and an accompanying paragraph of description,
        written the past tense, for the following character in a novel:

            $arg{character}

        Please return the information in a JSON object with no additional
        text or commentary.
    }
}


# And then later...
say character_intro(
    genre     => 'Hard-boiled detective novels of the 1940s',
    character => 'The female protagonist, of whose motives we are yet unsure'
);

# And still later...
say character_intro(
    genre     => 'Humorous and absurdist SF parodies',
    character => 'The female protagonist, of whose motives we are yet unsure'
);

# And yet later...
say character_intro(
    genre     => 'Witty, keenly observed, Regency romances in the style of Georgette Heyer',
    character => 'The female protagonist, of whose motives we are yet unsure'
);


__END__

Sample output:

{
    "name": "Vivian Blackwood",
    "description": "Vivian Blackwood entered the dimly lit speakeasy, her heels
                    clicking sharply against the worn wooden floor. The eyes of
                    the regulars turned toward her, a sultry silhouette in a
                    black satin dress, but it was the glint of steel in her gaze
                    that made them look away just as quickly. An enigma wrapped
                    in shadows, Blackwood had a reputation that traveled faster
                    than whisper but left details as murky as the bottom of a
                    bottle of bourbon. She moved with an air of purpose, yet
                    kept her secrets close, like a deck of marked cards played
                    only in dire need. Whether she was a damsel in distress or
                    the spider at the center of a web, no one could say for
                    sure—but the wise knew to keep their distance until her
                    hand was shown."
}

{
    "name": "Celestia Quirkfinder",
    "description": "Celestia Quirkfinder had once been the chief librarian of
                    the Intergalactic Repository of Really Useless Information,
                    a position she left under mysterious circumstances involving
                    a rogue hyper-intelligent marmalade. Now, she mysteriously
                    wandered the galaxy, often with a duct-taped ray gun and a
                    pocketful of improbable gadgets, surfacing in the oddest of
                    places to foil evil plans or perhaps inadvertently sip on
                    someone else's space tea. Her motives were as inscrutable as
                    her penchant for wearing only one sock at a time, leaving us
                    all to wonder whether her actions were driven by a
                    deep-seated cosmic mission, or merely a profound lack of
                    anything better to do."
}

{
    "name":        "Lady Vivienne Ashford",
    "description": "Lady Vivienne Ashford had ever been a creature of mystery,
                    her alabaster skin and raven hair a stark contrast to the
                    soft hues of the ton. She possessed a wit as sharp as her
                    jawline and eyes that gleamed with a knowing spark, yet
                    revealed nothing of the tempestuous thoughts that lingered
                    behind them. The whispered conjectures of her motives danced
                    like shadows in the candlelight of many a grand ballroom,
                    leaving the curious to ponder whether she was a schemer, a
                    savior, or simply a soul adrift in a world that never quite
                    matched her depth."
}
