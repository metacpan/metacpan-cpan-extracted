# Operator Precedences for parenthesis.

A high number means means we are likely to add parenthesis


| Number | Property | Symbols | Notes |
|--:|--|--|--|
| 26 |         | inside interpolation context ("") | _TODO_  |
| 25 | left    | terms and list operators (leftward)|
| 24 | left       | `->`      | |
| 23 | nonassoc   | `++`, `--`   | |
| 22 | right      | `**` |
| 21 | right      | `!`, `~`, `\`, unary `+` and `-` | |
| 20 | left       | `=~`, `!~` | |
| 19 | left       | `*`, `/`, `%`, `x` | |
| 18 | left       | `+`, `-`, `.` | |
| 17 | left       | `<<`,  `>>` | |
| 16 | nonassoc   | named unary operators | |
| 15 | nonassoc   | `<`, `>`, `<=`, `>=`, `lt`, `gt`, `le`, `ge` | |
| 14 | nonassoc   | `==`, `!=`, `<=>`, `eq`, `ne`, `cmp` | |
| 13 | left       | `&` | |
| 12 | left       | `^` | |
| 11 | left       | `&&` | |
| 10 | left       | `\\` | |
|  9 | nonassoc   | `..`  `...` | |
|  8 | right      | `?:` | |
|  7 | right      | `=`, `+=`, `-=`, `*=`,  etc. | |
|  6 | left       | `,`, `=>` | |
|  5 | nonassoc   | list operators (rightward) | |
|  4 | right      | `not` | |
|  3 | left       | `and` | |
|  2 | left       | `or`, `xor` | |
|  1 |            | statement modifiers | |
|  0.5 |          | statements | but still print scopes as `do { ... }` | |
|  0   |          | statement level | |
| -1   |          | format body | |
