# Libsass Math Plugin

Native libsass plugin adding trigonometric and mathematical functions.

## Building

You need to have [libsass] [1] already [compiled] [2] or [installed] [3] as a
shared library (inclusive header files). It is then compiled via `cmake`. See
this example to compile it on windows via [MinGW] [4] Compiler Suite:

```cmd
git clone https://github.com/sass/libsass.git
mingw32-make -C libsass BUILD=shared CC=gcc -j5
git clone https://github.com/mgreter/libsass-math.git
cd libsass-math && mkdir build && cd build
cmake -G "MinGW Makefiles" .. -DLIBSASS_DIR="..\..\libsass"
mingw32-make CC=gcc -j5 && dir math.dll
```

You may define `LIBSASS_INCLUDE_DIR` and `LIBSASS_LIBRARY_DIR` separately!

## API

The following globals are available when you import the math plugin.
- `$E` - Euler's number (used for the natural logarithm).
- `$PI` - The ratio of a circle's circumference to its diameter.
- `$TAU` - The double of pi, because [Pi is wrong] [5].

The following functions are available when you import the math plugin.

#### `math/numeric`
- `sign($x)` - Returns the sign of the number (`-1`,`0`,`1`)

#### `math/exponentiation`
- `exp($x)` - Returns the exponent of a number.
- `log($x)` - Returns the natural logarithm of a number.
- `log2($x)` - Returns the base 2 logarithm of a number.
- `log10($x)` - Returns the base 10 logarithm of a number.
- `cbrt($x)` - Returns the cube root of a number.
- `sqrt($x)` - Returns the square root of a number.
- `fact($x)` - Returns the factorial of a number.
- `pow($base, $exp)` - Returns base to the power of exp.

#### `math/trigonometry`
- `sin($x)` - Returns the sine of a number.
- `cos($x)` - Returns the cosine of a number.
- `tan($x)` - Returns the tangent of a number.
- `sec($x)` - Returns the secant of a number.
- `csc($x)` - Returns the cosecant of a number.
- `cot($x)` - Returns the cotangent of a number.

#### `math/hyperbolic`
- `sinh($x)` - Returns the hyperbolic sine of a number.
- `cosh($x)` - Returns the hyperbolic cosine of a number.
- `tanh($x)` - Returns the hyperbolic tangent of a number.
- `sech($x)` - Returns the hyperbolic secant of a number.
- `csch($x)` - Returns the hyperbolic cosecant of a number.
- `coth($x)` - Returns the hyperbolic cotangent of a number.

#### `math/inverse-trigonometry`
- `asin($x)` - Returns the arcsine of a number.
- `acos($x)` - Returns the arccosine of a number.
- `atan($x)` - Returns the arctangent of a number.
- `asec($x)` - Returns the arcsecant of a number.
- `acsc($x)` - Returns the arccosecant of a number.
- `acot($x)` - Returns the arccotangent of a number.

#### `math/inverse-hyperbolic`
- `asinh($x)` - Returns the hyperbolic arcsine of a number.
- `acosh($x)` - Returns the hyperbolic arccosine of a number.
- `atanh($x)` - Returns the hyperbolic arctangent of a number.
- `asech($x)` - Returns the hyperbolic arcsecant of a number.
- `acsch($x)` - Returns the hyperbolic arccosecant of a number.
- `acoth($x)` - Returns the hyperbolic arccotangent of a number.

## Copyright

© 2015 [Marcel Greter] [6]

[1]: https://github.com/sass/libsass
[2]: https://github.com/sass/libsass/wiki/Building-Libsass
[3]: http://libsass.ocbnet.ch/installer/
[4]: http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/
[5]: http://tauday.com/
[6]: https://github.com/mgreter

