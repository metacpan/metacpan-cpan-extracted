# Sine Wave

This program provides a function that cycles through a set of strings
printing them one per line forming a sine wave. The program assumes an
80-column terminal.

```
uses "http://www.dallycot.net/ns/loc/1.0#";
uses "http://www.dallycot.net/ns/core/1.0#";
uses "http://www.dallycot.net/ns/math/1.0#";
uses "http://www.dallycot.net/ns/streams/1.0#";
uses "http://www.dallycot.net/ns/strings/1.0#";
uses "http://www.dallycot.net/ns/cli/1.0#";

sine-wave(strings, terminal-width -> 80) :> (
  blank-line        := string-multiply(" ", terminal-width);
  max-string-length := last(max(string-lengths));
  middle            := ceil(terminal-width div 2 - max-string-length div 2);
  multiplier        := floor(middle - max-string-length div 2);
  number-of-strings := length(strings);
  string-lengths    := length @ strings;
  string-offsets    := { middle + ceil((max-string-length - #) div 2) } @ string-lengths;

  (line) :> (
    index  := ((line - 1) mod number-of-strings) + 1;
    string := strings[index];
    tab    := string-offsets[index]
              + multiplier * sin(line div 4, units -> "radians", accuracy -> 5);

    string-take(blank-line, tab) ::> string;
  );
);

lines(count) :>
  (
    print
    @ sine-wave(<<Digital Humanities>>)
    @ 1..
  )[count];

lines(1000)
```
