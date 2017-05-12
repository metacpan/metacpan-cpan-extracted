# Gunner

Translated from the original BASIC version on page 77 of: Creative Computing. _Basic Computer Games_, Microcomputer Edition, Edited by David H. Ahl. Workman Publishing, NY, 1978.

This Markdown file can be run as-is by the Dallycot command line interface:

```shell
$ ./bin/dallycot ./examples/gunner.md
```

This particular Markdown file doesn't reorganize any of the code. The Dallycot code is presented in the order it is given to the parser and executed.

Only code sections that have no associated language or are tagged as `dallycot` will be included in the source. For example:
<code><pre>
&#96;&#96;&#96;
(\* a section of code \*)
&#96;&#96;&#96;
</pre></code>
or
<code><pre>
&#96;&#96;&#96;dallycot
(\* a section of code \*)
&#96;&#96;&#96;
</pre></code>
will be included in the source, but
<code><pre>
&#96;&#96;&#96;json
{ ... }
&#96;&#96;&#96;
</pre></code>
will not be included.

## External Libraries

The Gunner game uses the command line library to narrate the game and request player input. The math and strings libraries are used to calculate the trajectory of the shell and report on the results.

```
ns:cli     := "http://www.dallycot.net/ns/cli/1.0#";
ns:math    := "http://www.dallycot.net/ns/math/1.0#";
ns:strings := "http://www.dallycot.net/ns/strings/1.0#";
```

We make the function routines available without a namespace just to make some of the code easier to write, namely the use of `Y`.

```
uses "http://www.dallycot.net/ns/core/1.0#";
```

All of these libraries are part of the Dallycot distribution.

The difference between declaring a namespace prefix mapping and using a namespace is that the former allows you to use functions with the same name from different namespaces without confusing them. The latter adds the namespace to your symbol resolution search path, so the value you get for a symbol depends on the order of your `uses` statements.

When in doubt, use a namespace prefix.

## Utility Functions

Just to make our life easier when we have a lot to print, we define a function that will take a stream or vector of strings and print them out, one at a time, using the command line output routine.

```
print-lines(stream) :> (
  (?stream) : (
    cli:print(stream');
    print-lines(stream...);
  )
  (       ) : ( )
);
```

It's not important that we pass a stream to `print-lines`. The critical thing is that what we pass responds to the head (`'`) and tail (`...`) operations and return `false` for the `?` operator when empty. Both streams and vectors satisfy this. In the rest of this program, we'll use vectors of strings since they are marginally faster and more memory efficient.

## Setup

We go a bit overboard here and define functions to "make" a gun and a target. We're not really doing object oriented programming, but this is one way we could enable it: the "make" function would return a graph that represents the object. For example, something like the following RDF:

```json
{
  "@context": "http://www.example.com/ns/gunner.json",
  "@type": "Gun",
  "range": 23500
}
```

Then, the `gun-range` function would extract the range from the graph. Instead, we just return the value passed in since the range is the gun.

```
make-gun() :> math:random(<20000,60000>);
gun-range(gun) :> gun;

make-target(gun) :> math:random(<gun div 10, 9 * gun div 10>);
target-distance(target) :> target;
```

### Aside: Object Oriented Gun

One idea I'm tossing around is being able to write code something like the following:

```dallycot-ignore
ns:gunner := "http://www.example.com/ns/gunner/";
prop:range := <gunner:range>

gunner:Gun() :> {
    :@type -> "gunner:Gun",
    :range -> math:random(<20000,60000>)
};

gunner:Gun#range(gun) :> gun -> :range;

cli:print("range: " ::> number-string(gun#range));
```

This would create a function with the url `<http://www.example.com/ns/gunner/Gun#range>`. At run time, the processor would inspect the object stored in `gun` and see that it was a `<http://www.example.com/ns/gunner/Gun>`. Then, it would look for the `range` method at the URL created by concatenating the method name onto the end separated by a hash (`#`).

The beauty of linked code is that the reference to the `range` method doesn't have to be in the code that defines the method. The definition could be out on the web somewhere and the processor would know where to go to find it.

## Player Input

We need to get information from the player at two different points in the game:

1. When we need to know how to aim the gun,
2. and when we finish the round and need to know if we should go another round or not.

### Getting the Elevation

We need to know the elevation of the gun in degrees between 1 and 89 inclusive. Zero degrees will fall immediately to the ground, and 90 degrees will hit us on the head.

```
get-elevation() :> (
  elevation := cli:input("\nElevation: ");

  (
    (elevation > 89) : (
      print-lines(["Maximum elevation is 89 degrees",""]);
      get-elevation();
    )
    (elevation < 1) : (
      print-lines(["Minimum elevation is one degree",""]);
      get-elevation();
    )
    ( ) : elevation
  )
);
```

### Continue the Game?

After the player has either hit the target or gotten hit by the enemy, the round is over and we need to know if they would like to go another round. The response has to be either `y` or `n`. Anything else repeats the prompt.

```
try-again?() :> (
  input := cli:input-string("Try again (y or n)? ");
  (
    (input = "Y" or input = "y") : true
    (input = "N" or input = "n") : false
    ( ) : (
      cli:print("I didn't catch that.");
      try-again?()
    )
  )
);
```

## Attack Results

After the player enters the gun elevation and fires the gun, we choose one of four different outcomes.

### We Go Boom!

If the player runs out of shells, they get hit by the enemy. We display a nice, friendly BOOM and then prompt them to see if they want to go for another round.

```
go-boom(tries) :> (
  print-lines(<
    "",
    "",
    "BOOM !!!!   You have just been destroyed",
    "by the enemy.",
    "",
    "",
    "",
    "Better go back to Fort Sill for refresher training!",
    ""
  >);
  < tries', try-again?() >
);
```

### They Go Boom!

If the player fires and the shell lands within a hundred yards of the target, we consider the target destroyed. This is a victory for the player. After printing out the victory message, we prompt them to see if they want to go for another round.

```
destroy-target(tries) :> (
  print-lines(<
    "*** TARGET DESTROYED ***  " ::>
    strings:number-string(tries') ::>
    " rounds of ammunition expended"
  >);
  < tries', try-again?() >
);
```

### Shell Lands Short

If the player fires and the shell lands short of the target, we let the player know how short they were and give them another attack.

```
under-shoot(gun, target, distance, tries) :> (
  print-lines(<
    "Short of target by " ::> strings:number-string(distance) ::> " yards."
  >);

  attack-target(gun, target, tries...)
);
```

### Shell Lands Long

If the player fires and the shell lands beyond the target, we let the player know how far they were and give them another attack.

```
over-shoot(gun, target, distance, tries) :> (
  print-lines(<
    "Over target by " ::> strings:number-string(distance) ::> " yards."
  >);
  attack-target(gun, target, tries...)
);
```

## Attack

An attack consists of getting an elevation from the player and then firing the gun, if they aren't out of tries.

### Fire Gun

Given a gun, a target, and an elevation, we see how close the player gets to the target with a shell. This function passes `tries` through to the result functions since that determines how many shells are left or were used to hit the target.

```
fire-gun(gun, target, elevation, tries) :> (
  distance := math:ceil(target-distance(target) - hit-at);
  hit-at := gun-range(gun) * math:sin(elevation);

  (
    (math:abs(distance) < 100) : destroy-target(tries)
    (         distance  < 100) : under-shoot(gun, target, -distance, tries)
    (                        ) :  over-shoot(gun, target,  distance, tries)
  )
);
```

### Manage Attack

Here, we simply manage the prompt and response cycle of the main part of the game. We prompt for the elevation and then either fire the gun or have the player be hit by the target if they're out of tries.

We track the number of tries with a range of integers. If we can move another position in the chain of integers, we fire the gun. Otherwise, we're done. This is a natural way to build loops in Dallycot that mimic for-loops in other languages.

```
attack-target(gun, target, tries) :> (
  elevation := get-elevation();

  (
    (?(tries...))  : fire-gun(gun, target, elevation, tries)
    (           )  : go-boom(tries)
  )
);
```

## Game Round

A round of the game consists of a number of attacks against the same target. For each round, we create a new gun and a new target. This keeps players on their toes.

```
game-round(round, total-shells) :> (
  gun    := make-gun();
  target := make-target(gun);

  update-stats() :> (
    stats := attack-target(gun, target, 1..6);
    < (stats[1] + total-shells), stats[2] >
  );

  print-lines(<
    "Maximum range of your gun is " ::> strings:number-string(gun-range(gun)) ::> " yards.",
    ""
  >);

  print-lines(<
    "   Distance to the target is " ::>
    strings:number-string(target-distance(target)) ::>
    " yards.",
    "",
    ""
  >);

  update-stats();
);
```

## Running the Game

Once the banner is printed, we start running the game, which consists of a number of rounds until the player decides to stop.

We use `stats` as a kind of game status indicator. It's a vector with the form `<total-shells, continue?>`. We don't get here until the end of the first round, so it's acting as a `do ... while(...)` loop construct.

```
run-game(stats) :> (
  (stats[1] < 18 and stats[2]) : run-game(game-round(0, stats[1]))
  (stats[1] >= 18) : (
    print-lines([
      "Total rounds expended were: " ::> strings:number-string(stats[1]),
      "Better go back to Fort Sill for refresher training!",
      ""
    ])
  )
  (     ) : (
    print-lines([
      "Total rounds expended were: " ::> strings:number-string(stats[1]),
      "",
      "Return to base camp."
    ]);
  )
);
```

## Start the Game

Now that everything is defined, we can show the player the welcoming banner and start the game.

```
print-lines(<
  "                              Gunner",
  "              (Creative Computing  Morristown, New Jersey)",
  "",
  "",
  "",
  "You are the office-in-charge, giving orders to a gun",
  "crew, telling them the degrees of elevation you estimate",
  "will place a projectile on target.  A hit within 100 yards",
  "of the target will destroy it.",
  ""
>);

run-game(game-round(0, 0));
```
