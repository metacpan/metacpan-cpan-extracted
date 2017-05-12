# Fizz Buzz

This program is one solution to the [Fizz Buzz exercise](http://en.wikipedia.org/wiki/Fizz_buzz).

```
uses "http://www.dallycot.net/ns/math/1.0#";
uses "http://www.dallycot.net/ns/cli/1.0#";
uses "http://www.dallycot.net/ns/strings/1.0#";

fizz-buzz(x) :> (
  by-five  := divisible-by?(x, 5);
  by-three := divisible-by?(x, 3);
  (
    (by-three and by-five) : ("fizz-buzz")
    (by-three            ) : ("fizz"     )
    (             by-five) : (     "buzz")
    (                    ) : (number-string(x))
  )
);

print-results(xs) :> print(
  string-join(" ", xs)
);
```

Then, run it over a sequence of numbers.

```
print-results(

  fizz-buzz @ 1..100

);
```
