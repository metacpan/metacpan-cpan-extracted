# NAME

Class::Debug - Add Runtime Debugging to a Class

# VERSION

0.02

# SYNOPSIS

The `Class::Debug` module is a lightweight utility designed to inject runtime debugging capabilities into other classes,
primarily by layering configuration and logging support.

Add this to your constructor:

    use Class::Debug;
    use Params::Get;

    sub new {
         my $class = shift;
         my $params = Params::Get(undef, \@_);

         $params = Class::Debug::setup($class, $params);

         return bless $params, $class;
     }

# SUBROUTINES/METHODS

## setup

Configure your class for runtime debugging.

Takes two arguments:

- `class`
- `params`

    A hashref containing default parameters to be used in the constructor.

Returns the new values for the constructor.

Now you can set up a configuration file and environment variables to debug your module.

# SEE ALSO

- [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-class-debug at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Debug](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Debug).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Class::Debug

You can also look for information at:
