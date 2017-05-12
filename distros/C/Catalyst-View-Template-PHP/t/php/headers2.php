<?php

// send headers with different replace values.
//
// expected response headers:
//   foo: baz
//   123: 456    |___________ could also be =>  123: 456, 789
//   123: 789    |
//   abc: jkl

header("foo: bar");
header("foo: baz", true);

header("123: 456");
header("123: 789", false);

header("abc: def", true);
header("abc: ghi", false);
header("abc: jkl");  // default $replace=true

?>