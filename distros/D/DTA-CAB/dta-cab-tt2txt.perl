#!/usr/bin/perl -w

while (defined($_=<>)) {
  s/\t/\n\t/sg;
  s/^\t\[/\t+\[/mg;
  print;
}
